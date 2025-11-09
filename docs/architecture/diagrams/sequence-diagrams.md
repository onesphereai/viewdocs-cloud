# Sequence Diagrams - Key Application Flows

**Document Version:** 1.0
**Last Updated:** 2025-11-09

This document contains detailed sequence diagrams for critical user flows in the Viewdocs Cloud system.

---

## 1. Authentication Flow (SAML 2.0)

### 1.1 User Login with SAML

```mermaid
sequenceDiagram
    actor User
    participant Browser
    participant CloudFront
    participant S3 as S3 (Angular App)
    participant Cognito
    participant IdP as IDM/Customer IdP
    participant APIGW as API Gateway
    participant Lambda

    User->>Browser: Navigate to acme.viewdocs.example.com
    Browser->>CloudFront: GET /
    CloudFront->>S3: Fetch index.html
    S3->>CloudFront: Return Angular SPA
    CloudFront->>Browser: Serve Angular app

    Browser->>Browser: App loads, checks localStorage for JWT
    Browser->>Browser: No JWT found

    Browser->>Cognito: Redirect to Cognito Hosted UI<br/>/oauth2/authorize
    Note over Cognito: Extract subdomain "acme"<br/>Identify IdP from tenant config

    Cognito->>IdP: SAML AuthnRequest<br/>(SP-initiated flow)
    IdP->>User: Display login page
    User->>IdP: Enter username + password
    IdP->>IdP: Validate credentials

    alt MFA Enabled
        IdP->>User: Request MFA code
        User->>IdP: Enter MFA code
        IdP->>IdP: Validate MFA
    end

    IdP->>IdP: Generate SAML Assertion<br/>(signed with IdP private key)
    IdP->>Cognito: POST SAML Assertion<br/>(NameID, attributes, signature)

    Cognito->>Cognito: Validate SAML signature<br/>using IdP public cert
    Cognito->>Cognito: Extract user attributes<br/>(email, roles, tenant_id)
    Cognito->>Cognito: Issue JWT tokens<br/>(access, ID, refresh)

    Cognito->>Browser: Redirect with authorization code<br/>/oauth2/callback?code=xyz
    Browser->>Cognito: Exchange code for tokens<br/>POST /oauth2/token
    Cognito->>Browser: Return JWT tokens

    Browser->>Browser: Store tokens in localStorage<br/>accessToken, idToken, refreshToken

    Browser->>APIGW: API request<br/>Authorization: Bearer {accessToken}
    APIGW->>Cognito: Validate JWT signature
    Cognito->>APIGW: Token valid, return claims
    APIGW->>Lambda: Invoke with user context
    Lambda->>APIGW: Return response
    APIGW->>Browser: JSON response

    Browser->>User: Display dashboard
```

**Key Points**:
- SP-initiated flow (user starts at Viewdocs, not IdP)
- Cognito validates SAML assertion signature
- JWT tokens stored in browser localStorage
- Access token expires in 30 minutes (configurable)

---

## 2. Document View Flow

### 2.1 User Views Document from Archive

```mermaid
sequenceDiagram
    actor User
    participant Angular
    participant APIGW as API Gateway
    participant Authorizer as Cognito Authorizer
    participant Lambda as Document Service
    participant DDB as DynamoDB
    participant Secrets as Secrets Manager
    participant Archive as IESC/IES/CMOD
    participant EB as EventBridge
    participant EventLambda as Event Service
    participant FRS as FRS Proxy

    User->>Angular: Click document in search results
    Angular->>APIGW: GET /documents/{docId}/content<br/>Authorization: Bearer {token}

    APIGW->>Authorizer: Validate JWT
    Authorizer->>Authorizer: Verify signature, check expiry
    Authorizer->>APIGW: Token valid<br/>Claims: {sub, tenant_id, role}

    APIGW->>Lambda: Invoke with event<br/>{tenantId, userId, docId, role}

    Lambda->>DDB: Get archive config<br/>PK: TENANT#{tenantId}<br/>SK: CONFIG#archive
    DDB->>Lambda: {archiveType: IESC, endpoint, credentialsSecretId}

    Lambda->>DDB: Get document folder<br/>(query archive metadata cache or fetch from archive)
    Note over Lambda: Assume folder: /invoices/2024

    Lambda->>DDB: Get folder ACLs<br/>PK: TENANT#{tenantId}<br/>SK: FOLDER#/invoices/2024#ACL
    DDB->>Lambda: {rolePermissions: {admin: [view, download], user: [view]}}

    Lambda->>Lambda: Check authorization<br/>userRole=user, permissions=[view]<br/>Result: AUTHORIZED

    alt Unauthorized
        Lambda->>DDB: Log unauthorized attempt<br/>PK: TENANT#{tenantId}<br/>SK: AUDIT#{timestamp}#{eventId}
        Lambda->>APIGW: Return 403 Forbidden
        APIGW->>Angular: HTTP 403
        Angular->>User: Show "Access Denied" error
    end

    Lambda->>Secrets: Get archive credentials<br/>SecretId: viewdocs/{tenantId}/archive-creds
    Secrets->>Lambda: {username, password, apiKey}

    Lambda->>Archive: Fetch document<br/>GET /documents/{docId}<br/>Auth: Basic {credentials}
    Archive->>Lambda: Return document binary (PDF)

    Lambda->>DDB: Log view event<br/>PK: TENANT#{tenantId}<br/>SK: AUDIT#{timestamp}#{eventId}<br/>Data: {userId, docId, action: view, result: SUCCESS}

    Lambda->>EB: Publish event<br/>{eventType: DocumentViewed, tenantId, userId, docId}
    EB->>EventLambda: Trigger Event Service
    EventLambda->>EventLambda: Transform to HUB format
    EventLambda->>FRS: Send SOAP message<br/>via Direct Connect
    FRS->>FRS: Forward to HUB via IBM MQ

    Lambda->>APIGW: Stream document<br/>Content-Type: application/pdf
    APIGW->>Angular: HTTP 200<br/>Binary PDF stream
    Angular->>Angular: Render PDF in viewer
    Angular->>User: Display document
```

**Key Points**:
- Authorization checked before fetching document
- Archive credentials fetched from Secrets Manager
- All actions logged to DynamoDB audit table
- Events published to EventBridge for HUB integration

---

## 3. Bulk Download Flow

### 3.1 Async Bulk Download with Email Notification

```mermaid
sequenceDiagram
    actor User
    participant Angular
    participant APIGW as API Gateway
    participant DownloadLambda as Download Service
    participant SF as Step Functions
    participant DDB as DynamoDB
    participant SQS
    participant WorkerLambda as Document Worker
    participant Archive as IESC/IES/CMOD
    participant S3
    participant Email as Email Service

    User->>Angular: Select 100 documents<br/>Click "Bulk Download"
    Angular->>APIGW: POST /documents/bulk-download<br/>{documentIds: [DOC1, DOC2, ..., DOC100]}

    APIGW->>DownloadLambda: Invoke

    DownloadLambda->>DownloadLambda: Validate total size<br/>Estimated: 2.5GB < 5GB limit

    DownloadLambda->>DDB: Create job record<br/>PK: TENANT#{tenantId}<br/>SK: DOWNLOAD#JOB-{jobId}<br/>Data: {status: PENDING, documentIds: [...], userId}

    DownloadLambda->>SF: Start workflow<br/>Input: {jobId, documentIds, tenantId, userId}
    SF->>SF: State: ValidateRequest<br/>(check ACLs for all docs)

    SF->>SQS: Fan-out messages<br/>(one message per document)
    Note over SQS: 100 messages in queue

    DownloadLambda->>DDB: Update job status<br/>status: PROCESSING
    DownloadLambda->>APIGW: Return 202 Accepted<br/>{jobId, status: PROCESSING}
    APIGW->>Angular: HTTP 202
    Angular->>User: Show "Processing..." message

    loop For each document (concurrency=1)
        SQS->>WorkerLambda: Trigger with {docId, jobId}
        WorkerLambda->>Archive: Fetch document
        Archive->>WorkerLambda: Return binary
        WorkerLambda->>S3: Upload to temp folder<br/>s3://bulk-downloads/{tenantId}/{jobId}/{docId}
        WorkerLambda->>DDB: Update job progress<br/>completedDocuments++
    end

    SF->>SF: State: WaitForCompletion<br/>(all documents fetched)

    SF->>WorkerLambda: Invoke aggregator<br/>Input: {jobId, tenantId}
    WorkerLambda->>S3: List all documents<br/>Prefix: {tenantId}/{jobId}/
    S3->>WorkerLambda: Return file list
    WorkerLambda->>WorkerLambda: Create zip archive<br/>(stream from S3, write to zip)
    WorkerLambda->>S3: Upload final zip<br/>s3://bulk-downloads/{tenantId}/{jobId}.zip

    WorkerLambda->>S3: Generate CloudFront signed URL<br/>Expiry: 72 hours
    S3->>WorkerLambda: Return download URL

    WorkerLambda->>DDB: Update job<br/>status: COMPLETED<br/>downloadUrl: {url}<br/>expiresAt: {timestamp}

    WorkerLambda->>Email: Send notification<br/>POST /email<br/>{to: {userId}, subject: "Bulk Download Ready", body: {downloadUrl}}
    Email->>User: Email: "Your download is ready"

    User->>Angular: Click link in email
    Angular->>APIGW: GET /documents/bulk-download/{jobId}/url
    APIGW->>DownloadLambda: Invoke
    DownloadLambda->>DDB: Get job<br/>PK: TENANT#{tenantId}<br/>SK: DOWNLOAD#JOB-{jobId}
    DDB->>DownloadLambda: {downloadUrl, expiresAt, status}

    DownloadLambda->>DownloadLambda: Validate expiry<br/>expiresAt > now

    DownloadLambda->>APIGW: Return {downloadUrl}
    APIGW->>Angular: HTTP 200
    Angular->>S3: Download zip<br/>GET {cloudFrontUrl}
    S3->>User: Stream 2.5GB zip file
```

**Key Points**:
- Async processing with Step Functions orchestration
- One Lambda per document (concurrency=1 to avoid overwhelming archive)
- Documents stored temporarily in S3
- Email notification sent when ready
- Download URL expires after 72 hours (lifecycle policy deletes files)

---

## 4. Search Flow

### 4.1 Index-Based Search with ACL Filtering

```mermaid
sequenceDiagram
    actor User
    participant Angular
    participant APIGW as API Gateway
    participant SearchLambda as Search Service
    participant DDB as DynamoDB
    participant Secrets as Secrets Manager
    participant Archive as IESC/IES/CMOD
    participant CloudFront

    User->>Angular: Enter search criteria<br/>{customerId: "CUST-123", dateRange: "2024-Q1"}
    Angular->>APIGW: POST /search/index<br/>{criteria, pagination: {page: 1, pageSize: 50}}

    APIGW->>SearchLambda: Invoke

    SearchLambda->>DDB: Get user's accessible folders<br/>PK: TENANT#{tenantId}<br/>SK begins_with FOLDER#
    DDB->>SearchLambda: Return folder ACLs<br/>{/invoices/2024: [view], /reports/2024: [view]}

    SearchLambda->>SearchLambda: Build folder filter<br/>folders: [/invoices/2024, /reports/2024]

    SearchLambda->>DDB: Get archive config
    DDB->>SearchLambda: {archiveType: IESC, endpoint, credentialsSecretId}

    SearchLambda->>Secrets: Get credentials
    Secrets->>SearchLambda: {username, password}

    SearchLambda->>Archive: Search request<br/>POST /search<br/>{query: {customerId, dateRange}, folders: [...]}<br/>Auth: Basic {credentials}
    Archive->>SearchLambda: Return results<br/>{documents: [...], totalCount: 247}

    SearchLambda->>SearchLambda: Double-check ACLs<br/>(verify all results in allowed folders)

    SearchLambda->>SearchLambda: Paginate results<br/>Page 1: docs 1-50

    SearchLambda->>APIGW: Return page 1<br/>{documents: [50 docs], pagination: {page: 1, totalPages: 5}}
    APIGW->>CloudFront: Cache response (TTL: 5 min)
    APIGW->>Angular: HTTP 200
    Angular->>User: Display search results

    User->>Angular: Click "Next Page"
    Angular->>APIGW: POST /search/index?page=2
    APIGW->>CloudFront: Check cache
    CloudFront->>APIGW: Cache hit (return page 2)
    APIGW->>Angular: HTTP 200 (from cache)
    Angular->>User: Display page 2 results
```

**Key Points**:
- Folder ACLs fetched from DynamoDB before search
- Search filtered by user's accessible folders
- Results double-checked for ACL compliance
- CloudFront caches search results (5 min TTL)

---

## 5. Admin Tenant Onboarding Flow

### 5.1 ECM Admin Creates New Tenant

```mermaid
sequenceDiagram
    actor ECM_Admin as ECM Admin
    participant Angular
    participant APIGW as API Gateway
    participant AdminLambda as Admin Service
    participant DDB as DynamoDB
    participant Secrets as Secrets Manager
    participant Cognito
    participant R53 as Route 53
    participant Archive as IESC
    participant Email as Email Service

    ECM_Admin->>Angular: Navigate to Admin Portal<br/>Click "Add New Tenant"
    Angular->>ECM_Admin: Show tenant form

    ECM_Admin->>Angular: Submit form<br/>{name: "ACME Corp", subdomain: "acme", archive: {...}, idp: {...}}
    Angular->>APIGW: POST /admin/tenants<br/>{tenantConfig}

    APIGW->>AdminLambda: Invoke

    AdminLambda->>DDB: Check subdomain uniqueness<br/>Query for PK: TENANT#acme
    DDB->>AdminLambda: No existing tenant found

    AdminLambda->>Archive: Test connection<br/>GET /health<br/>Auth: Basic {credentials}
    Archive->>AdminLambda: HTTP 200 (connection successful)

    AdminLambda->>Secrets: Store archive credentials<br/>SecretId: viewdocs/acme/archive-creds<br/>SecretString: {username, password}
    Secrets->>AdminLambda: Secret created

    AdminLambda->>DDB: Create tenant config<br/>PK: TENANT#acme<br/>SK: CONFIG#archive<br/>Data: {name, subdomain, archive, idp, branding}

    AdminLambda->>DDB: Create default role ACLs<br/>PK: TENANT#acme<br/>SK: ROLE#admin#ACL<br/>SK: ROLE#user#ACL

    AdminLambda->>Cognito: Add SAML IdP connection<br/>POST /identityprovider<br/>{metadataUrl, providerName: "acme-idp"}
    Cognito->>AdminLambda: IdP created

    AdminLambda->>R53: Create DNS record<br/>acme.viewdocs.example.com → CloudFront
    R53->>AdminLambda: DNS record created

    AdminLambda->>DDB: Log tenant creation<br/>PK: TENANT#acme<br/>SK: AUDIT#{timestamp}#{eventId}

    AdminLambda->>Email: Send welcome email to Client Admin<br/>{to: clientAdmin@acme.com, loginUrl: acme.viewdocs.example.com}
    Email->>ECM_Admin: Email sent confirmation

    AdminLambda->>APIGW: Return 201 Created<br/>{tenantId: acme, status: active}
    APIGW->>Angular: HTTP 201
    Angular->>ECM_Admin: Show success message<br/>"Tenant 'ACME Corp' created"
```

**Key Points**:
- Subdomain uniqueness validated
- Archive connection tested before creation
- Credentials stored in Secrets Manager (never in DynamoDB)
- SAML IdP connection configured in Cognito
- DNS record created for tenant subdomain
- Welcome email sent to Client Admin

---

## 6. Comment Workflow

### 6.1 Add Comment with Version History

```mermaid
sequenceDiagram
    actor User
    participant Angular
    participant APIGW as API Gateway
    participant CommentLambda as Comment Service
    participant DDB as DynamoDB
    participant EB as EventBridge

    User->>Angular: View document<br/>Click "Add Comment"
    Angular->>User: Show comment input
    User->>Angular: Enter text<br/>"This invoice has been approved."

    Angular->>APIGW: POST /documents/{docId}/comments<br/>{text: "..."}
    APIGW->>CommentLambda: Invoke

    CommentLambda->>CommentLambda: Generate commentId<br/>CMT-{timestamp}-{uuid}

    CommentLambda->>DDB: Create comment<br/>PK: DOC#{docId}<br/>SK: COMMENT#{timestamp}#{commentId}<br/>Data: {userId, userName, text, version: 1}

    CommentLambda->>EB: Publish event<br/>{eventType: CommentAdded, docId, userId, commentId}

    CommentLambda->>APIGW: Return 201 Created<br/>{commentId, createdAt, canEdit: true}
    APIGW->>Angular: HTTP 201
    Angular->>User: Display comment

    Note over User,Angular: 10 minutes later...

    User->>Angular: Click "Edit Comment"
    User->>Angular: Update text<br/>"This invoice has been approved by finance team."

    Angular->>APIGW: PUT /comments/{commentId}<br/>{text: "..."}
    APIGW->>CommentLambda: Invoke

    CommentLambda->>DDB: Get comment<br/>PK: DOC#{docId}<br/>SK: COMMENT#{timestamp}#{commentId}
    DDB->>CommentLambda: Return comment

    CommentLambda->>CommentLambda: Check edit window<br/>createdAt: 10min ago < 24hr limit<br/>userId matches: YES

    CommentLambda->>DDB: Update comment<br/>Data.previousVersions.push({version: 1, text: "...", updatedAt})<br/>Data.version = 2<br/>Data.text = "..." (new text)<br/>UpdatedAt = now

    CommentLambda->>EB: Publish event<br/>{eventType: CommentEdited, commentId}

    CommentLambda->>APIGW: Return 200 OK<br/>{version: 2, updatedAt, canEdit: true}
    APIGW->>Angular: HTTP 200
    Angular->>User: Display updated comment
```

**Key Points**:
- Comments stored in DynamoDB (not in archive)
- Edit window: 24 hours from creation
- Version history tracked in `previousVersions` array
- Only comment owner can edit
- All comment actions logged to EventBridge

---

## Next Steps

1. Use these diagrams for developer onboarding
2. Update sequence diagrams when flows change
3. Create draw.io versions with AWS icons for presentations
4. Add error scenario sequences (archive timeout, ACL denial, etc.)

---

**Document Control**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-09 | Architecture Team | Initial sequence diagrams |
