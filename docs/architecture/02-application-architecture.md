# Application Architecture

**Document Version:** 1.0
**Last Updated:** 2025-11-09
**Status:** Draft

---

## 1. Application Components Overview

### 1.1 Logical Architecture (AWS Components with Security)

```mermaid
graph TB
    subgraph "User Layer"
        User["👤 End Users<br/>Browser/Mobile"]
    end

    subgraph "Security & CDN Layer"
        R53["🌐 Route 53<br/>DNS + Health Checks<br/>Failover Routing"]
        WAF["🛡️ WAF<br/>Web Application Firewall<br/>Rate Limiting | IP Filtering"]
        CloudFront["☁️ CloudFront CDN<br/>Edge Locations<br/>TLS 1.2+ | HTTPS Only"]
        Shield["🛡️ Shield Standard<br/>DDoS Protection<br/>Always On"]
    end

    subgraph "Presentation Layer"
        S3Static["🪣 S3 Bucket<br/>Static Website Hosting<br/>Angular SPA | Versioned"]
    end

    subgraph "API & Auth Layer"
        APIGW["🔌 API Gateway<br/>REST API<br/>Throttling: 10K RPS"]
        CogAuth["🔐 Cognito<br/>User Pool<br/>SAML 2.0 | MFA"]
    end

    subgraph "Application Services - Lambda Functions"
        DocSvc["λ Document Service<br/>Node.js 20.x<br/>512MB | 29s | Concurrency: 100"]
        SearchSvc["λ Search Service<br/>Node.js 20.x<br/>512MB | 29s | Concurrency: 100"]
        DownloadSvc["λ Download Service<br/>Node.js 20.x<br/>256MB | 15s | Concurrency: 50"]
        CommentSvc["λ Comment Service<br/>Node.js 20.x<br/>256MB | 10s | Concurrency: 50"]
        AdminSvc["λ Admin Service<br/>Node.js 20.x<br/>512MB | 15s | Concurrency: 10"]
        AuthSvc["λ Auth Service<br/>Node.js 20.x<br/>256MB | 10s | Concurrency: 50"]
        EventSvc["λ Event Service<br/>Node.js 20.x<br/>256MB | 5s | Concurrency: 50"]
        MailRoomSvc["λ MailRoom Wrapper<br/>Node.js 20.x<br/>512MB | 29s | Concurrency: 50"]
    end

    subgraph "Orchestration & Events"
        SF["⚙️ Step Functions<br/>Bulk Download Workflow<br/>Max Duration: 15min"]
        EB["📮 EventBridge<br/>Event Bus<br/>Schema Registry"]
        SQS["📬 SQS Queue<br/>Download Jobs<br/>FIFO | DLQ Enabled"]
    end

    subgraph "Data & Storage Layer"
        DDB["🗄️ DynamoDB<br/>Global Tables<br/>Config | ACLs | Audit<br/>Encrypted at Rest KMS"]
        S3["🪣 S3 Buckets<br/>Bulk Downloads<br/>72h Lifecycle | Encrypted"]
        Secrets["🔑 Secrets Manager<br/>Archive Credentials<br/>Auto-rotation 90d | KMS"]
    end

    subgraph "Monitoring & Security"
        CW["📊 CloudWatch<br/>Logs + Metrics<br/>Alarms"]
        XRay["🔍 X-Ray<br/>Distributed Tracing<br/>Performance Analysis"]
        GuardDuty["🛡️ GuardDuty<br/>Threat Detection<br/>Continuous Monitoring"]
        KMS["🔐 KMS<br/>Encryption Keys<br/>Auto-rotation"]
    end

    subgraph "External Systems"
        IESC["☁️ IESC<br/>REST API<br/>TLS 1.2+"]
        IES["🏢 IES<br/>SOAP API<br/>Direct Connect + IPsec"]
        CMOD["🏢 CMOD<br/>SOAP API<br/>Direct Connect + IPsec"]
        FRS["🏢 FRS Proxy<br/>SOAP API<br/>Direct Connect + IPsec"]
        MRBackend["☁️ MailRoom Backend<br/>REST API<br/>Independent Platform"]
    end

    %% User to CDN/Security
    User -->|1. DNS Query| R53
    R53 -->|2. Resolve to CloudFront| CloudFront
    User -->|3. HTTPS Request| WAF
    WAF -->|4. Filter Threats| Shield
    Shield -->|5. Allow Traffic| CloudFront

    %% CloudFront to Static & API
    CloudFront -->|6. Serve Static Assets| S3Static
    CloudFront -->|7. Proxy API Requests<br/>HTTPS + JWT Bearer| APIGW

    %% API Gateway to Auth & Services
    APIGW -->|8. Validate JWT| CogAuth
    CogAuth -.->|9. Token Valid<br/>Return User Claims| APIGW
    APIGW -->|10a. Invoke Lambda<br/>Sync| DocSvc
    APIGW -->|10b. Invoke Lambda<br/>Sync| SearchSvc
    APIGW -->|10c. Invoke Lambda<br/>Sync| DownloadSvc
    APIGW -->|10d. Invoke Lambda<br/>Sync| CommentSvc
    APIGW -->|10e. Invoke Lambda<br/>Sync| AdminSvc
    APIGW -->|10f. Invoke Lambda<br/>Sync| AuthSvc
    APIGW -->|10g. Invoke Lambda<br/>Sync| MailRoomSvc

    %% Document Service flows
    DocSvc -->|11a. Query ACLs<br/>Write Audit Logs| DDB
    DocSvc -->|11b. Fetch Document<br/>REST HTTPS| IESC
    DocSvc -->|11c. Fetch Document<br/>SOAP over IPsec| IES
    DocSvc -->|11d. Fetch Document<br/>SOAP over IPsec| CMOD
    DocSvc -->|11e. Publish Event<br/>DocumentViewed| EB
    DocSvc -->|11f. Get Archive Credentials<br/>Encrypted| Secrets

    %% Search Service flows
    SearchSvc -->|12a. Query User ACLs<br/>Filter Folders| DDB
    SearchSvc -->|12b. Search Index<br/>REST HTTPS| IESC
    SearchSvc -->|12c. Search Index<br/>SOAP over IPsec| IES
    SearchSvc -->|12d. Search Index<br/>SOAP over IPsec| CMOD
    SearchSvc -->|12e. Get Credentials<br/>Decrypt| Secrets

    %% Download Service flows
    DownloadSvc -->|13a. Start Execution<br/>Async Workflow| SF
    DownloadSvc -->|13b. Query Job Status| DDB
    SF -->|13c. Enqueue Jobs<br/>Fan-out per Doc| SQS
    SQS -->|13d. Trigger Worker<br/>Event Source Mapping| DocSvc
    DocSvc -->|13e. Upload Zip File<br/>Server-side Encryption| S3

    %% Comment & Admin Services
    CommentSvc -->|14a. CRUD Comments<br/>Versioned| DDB
    AdminSvc -->|14b. Manage Tenants<br/>Create/Update ACLs| DDB
    AdminSvc -->|14c. Store Credentials<br/>Encrypt with KMS| Secrets

    %% Auth Service
    AuthSvc -->|15a. Token Refresh<br/>SAML Callback| CogAuth
    AuthSvc -->|15b. Store Session Metadata| DDB

    %% Event Service
    EB -->|16a. Rule Trigger<br/>Event Pattern Match| EventSvc
    EventSvc -->|16b. Forward to HUB<br/>SOAP over IPsec| FRS

    %% MailRoom Wrapper Service
    MailRoomSvc -->|17a. Check ACLs<br/>Write Audit Logs| DDB
    MailRoomSvc -->|17b. Forward Request<br/>REST HTTPS + tenant_id| MRBackend

    %% Security & Monitoring connections
    DocSvc -.->|Logs| CW
    SearchSvc -.->|Logs| CW
    DownloadSvc -.->|Logs| CW
    CommentSvc -.->|Logs| CW
    AdminSvc -.->|Logs| CW
    AuthSvc -.->|Logs| CW
    EventSvc -.->|Logs| CW
    MailRoomSvc -.->|Logs| CW

    DocSvc -.->|Traces| XRay
    SearchSvc -.->|Traces| XRay
    APIGW -.->|Traces| XRay

    DDB -.->|Encrypt/Decrypt| KMS
    S3 -.->|Encrypt/Decrypt| KMS
    Secrets -.->|Encrypt/Decrypt| KMS

    GuardDuty -.->|Monitor Threats<br/>VPC Flow Logs| CW

    %% Styling
    classDef awsCompute fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#232F3E
    classDef awsData fill:#3F8624,stroke:#232F3E,stroke-width:2px,color:#fff
    classDef awsIntegration fill:#527FFF,stroke:#232F3E,stroke-width:2px,color:#fff
    classDef awsSecurity fill:#DD344C,stroke:#232F3E,stroke-width:2px,color:#fff
    classDef awsMonitoring fill:#759C3E,stroke:#232F3E,stroke-width:2px,color:#fff
    classDef external fill:#879196,stroke:#232F3E,stroke-width:2px,color:#fff
    classDef mailroom fill:#FF6B6B,stroke:#232F3E,stroke-width:2px,color:#fff
    classDef user fill:#232F3E,stroke:#FF9900,stroke-width:3px,color:#fff

    class User user
    class DocSvc,SearchSvc,DownloadSvc,CommentSvc,AdminSvc,AuthSvc,EventSvc awsCompute
    class MailRoomSvc mailroom
    class DDB,S3,S3Static awsData
    class APIGW,SF,EB,SQS,CloudFront,R53 awsIntegration
    class CogAuth,Secrets,WAF,Shield,KMS,GuardDuty awsSecurity
    class CW,XRay awsMonitoring
    class IESC,IES,CMOD,FRS,MRBackend external
```

---

## 2. Service Definitions

### 2.1 Document Service

**Responsibility:** Manage document retrieval, viewing, and downloading from archives

**Key Operations:**
- `getDocument(tenantId, docId)` - Fetch document from archive
- `getDocumentMetadata(tenantId, docId)` - Get metadata only
- `downloadDocument(tenantId, docId)` - Stream document to user
- `validateAccess(tenantId, userId, docId)` - Check ACLs

**Dependencies:**
- DynamoDB (ACLs, audit logs)
- Archive Adapter (fetch from IESC/IES/CMOD)
- Event Service (publish view/download events)
- Secrets Manager (archive credentials)

**Implementation:** TypeScript Lambda function
**Timeout:** 29 seconds
**Memory:** 512MB
**Concurrency:** 100 (reserved)

### 2.2 Search Service

**Responsibility:** Execute searches across archive systems

**Key Operations:**
- `indexSearch(tenantId, userId, criteria, pagination)` - Search by metadata
- `fullTextSearch(tenantId, userId, query, pagination)` - Full-text search (IESC only)
- `conversationalSearch(tenantId, userId, query)` - AI search (future, IESC + Bedrock)
- `getSavedSearches(tenantId, userId)` - Retrieve saved searches

**Dependencies:**
- DynamoDB (ACLs, saved searches)
- Archive Adapter (execute search APIs)
- Secrets Manager (archive credentials)

**Implementation:** TypeScript Lambda function
**Timeout:** 29 seconds
**Memory:** 512MB
**Concurrency:** 100 (reserved)

### 2.3 Download Service

**Responsibility:** Orchestrate bulk downloads via Step Functions

**Key Operations:**
- `initiateB ulkDownload(tenantId, userId, docIds[])` - Start workflow
- `getJobStatus(tenantId, userId, jobId)` - Check progress
- `generateDownloadUrl(tenantId, userId, jobId)` - Create S3 URL

**Dependencies:**
- Step Functions (workflow orchestration)
- SQS (document fetch queue)
- S3 (zip file storage)
- Email Client (notification)
- DynamoDB (job status)

**Implementation:**
- Initiator: TypeScript Lambda
- Orchestration: Step Functions
- Worker: TypeScript Lambda (concurrency=1 per document)

**Workflow Timeout:** 15 minutes
**Max File Size:** 5GB

### 2.4 Comment Service

**Responsibility:** Manage document comments with versioning

**Key Operations:**
- `addComment(tenantId, userId, docId, text)` - Create comment
- `editComment(tenantId, userId, commentId, text)` - Update comment (within 24h)
- `getComments(tenantId, userId, docId, pagination)` - List comments
- `getCommentHistory(tenantId, userId, commentId)` - View edit history

**Dependencies:**
- DynamoDB (comments, history)
- Event Service (publish comment events)

**Implementation:** TypeScript Lambda function
**Timeout:** 10 seconds
**Memory:** 256MB

### 2.5 Admin Service

**Responsibility:** Tenant and user management

**Key Operations:**
- `createTenant(adminId, tenantConfig)` - Onboard new tenant (ECM Admin only)
- `updateTenant(adminId, tenantId, config)` - Modify tenant config
- `createUser(adminId, tenantId, userInfo)` - Invite user (Client Admin)
- `assignRole(adminId, tenantId, userId, roleId)` - Assign role
- `manageACLs(adminId, tenantId, folderId, roleId, permissions)` - Define folder ACLs

**Dependencies:**
- DynamoDB (tenant config, ACLs)
- Cognito (create users, assign to groups)
- Secrets Manager (store archive credentials)

**Implementation:** TypeScript Lambda function
**Timeout:** 15 seconds
**Memory:** 512MB

### 2.6 Auth Service

**Responsibility:** Handle authentication callbacks, token refresh

**Key Operations:**
- `handleSAMLCallback(samlAssertion)` - Process SAML response
- `refreshToken(refreshToken)` - Get new access token
- `validateToken(accessToken)` - Verify JWT

**Dependencies:**
- Cognito (token issuance, validation)
- DynamoDB (user session metadata)

**Implementation:** TypeScript Lambda function
**Timeout:** 10 seconds
**Memory:** 256MB

### 2.7 Event Service

**Responsibility:** Publish events to EventBridge and route to HUB

**Key Operations:**
- `publishEvent(tenantId, eventType, payload)` - Send to EventBridge
- `transformToHubFormat(event)` - Convert to HUB schema
- `sendToFRS(event)` - Call FRS Proxy SOAP endpoint

**Dependencies:**
- EventBridge (event bus)
- FRS Proxy Client (SOAP)
- DynamoDB (event log)

**Implementation:** TypeScript Lambda function (triggered by EventBridge rule)
**Timeout:** 5 seconds
**Memory:** 256MB

### 2.8 MailRoom Wrapper Service

**Responsibility:** Backend for Frontend (BFF) facade for MailRoom document routing and assignment system

**Key Operations:**
- `getMailItems(tenantId, userId, filters, pagination)` - List mail items for user
- `searchMailItems(tenantId, userId, query, pagination)` - Search mail items
- `getMailItem(tenantId, userId, itemId)` - Get mail item details
- `archiveMailItem(tenantId, userId, itemId)` - Archive mail item
- `forwardMailItem(tenantId, userId, itemId, recipientId)` - Forward to another user
- `annotateMailItem(tenantId, userId, itemId, annotation)` - Add annotation
- `initiateBulkOperation(tenantId, userId, itemIds[], operation)` - Bulk operations
- `getBulkOperationStatus(tenantId, userId, jobId)` - Check bulk operation status

**Dependencies:**
- MailRoom Backend Client (REST API)
- DynamoDB (Viewdocs ACLs, audit logs)
- Cognito (JWT validation - inherited from API Gateway)

**Wrapper Responsibilities:**
1. **Authentication**: Inherit JWT validation from API Gateway
2. **Authorization**: Enforce Viewdocs ACLs (check tenant_id + user roles)
3. **Tenant Isolation**: Inject tenant_id into every MailRoom API call
4. **Request Translation**: Map Viewdocs API format → MailRoom API format
5. **Response Translation**: Map MailRoom response → Viewdocs UI format
6. **Error Handling**: Translate MailRoom errors to Viewdocs error codes
7. **Audit Logging**: Log mail operations to Viewdocs audit table
8. **Circuit Breaker**: Handle MailRoom downtime gracefully

**Implementation:** TypeScript Lambda function
**Timeout:** 29 seconds
**Memory:** 512MB
**Concurrency:** 50

**Integration Pattern:** Anti-Corruption Layer + BFF Pattern
- MailRoom Backend remains independent with own API contracts
- Wrapper shields Viewdocs from MailRoom API changes
- Both platforms evolve independently

---

## 3. API Specifications

### 3.1 REST API Endpoints

**Base URL:** `https://api.viewdocs.example.com/{tenantId}/v1`

**Authentication:** JWT Bearer token in `Authorization` header

#### 3.1.1 Document Endpoints

| Method | Endpoint | Description | Request | Response |
|--------|----------|-------------|---------|----------|
| GET | `/documents/{docId}` | Get document metadata | - | `DocumentMetadata` |
| GET | `/documents/{docId}/content` | Download document | - | Binary stream |
| POST | `/documents/bulk-download` | Initiate bulk download | `BulkDownloadRequest` | `JobResponse` |
| GET | `/documents/bulk-download/{jobId}` | Get bulk download status | - | `JobStatus` |
| GET | `/documents/bulk-download/{jobId}/url` | Get download URL | - | `DownloadUrlResponse` |

**Example Request: Download Document**
```http
GET /acme/v1/documents/DOC123456/content HTTP/1.1
Host: api.viewdocs.example.com
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Example Response:**
```http
HTTP/1.1 200 OK
Content-Type: application/pdf
Content-Disposition: attachment; filename="invoice-2024-001.pdf"
Content-Length: 245678

[Binary PDF data]
```

**Example Request: Bulk Download**
```json
POST /acme/v1/documents/bulk-download
{
  "documentIds": ["DOC123456", "DOC123457", "DOC123458"],
  "format": "zip",
  "notifyEmail": "user@example.com"
}
```

**Example Response:**
```json
{
  "jobId": "JOB-20250109-ABC123",
  "status": "PROCESSING",
  "createdAt": "2025-01-09T10:30:00Z",
  "estimatedCompletionTime": "2025-01-09T10:35:00Z"
}
```

#### 3.1.2 Search Endpoints

| Method | Endpoint | Description | Request | Response |
|--------|----------|-------------|---------|----------|
| POST | `/search/index` | Index-based search | `IndexSearchRequest` | `SearchResponse` |
| POST | `/search/fulltext` | Full-text search | `FullTextSearchRequest` | `SearchResponse` |
| POST | `/search/conversational` | AI search (future) | `ConversationalSearchRequest` | `SearchResponse` |
| GET | `/search/saved` | List saved searches | - | `SavedSearch[]` |

**Example Request: Index Search**
```json
POST /acme/v1/search/index
{
  "archive": "IESC",
  "criteria": {
    "customerIdId": "CUST-12345",
    "dateRange": {
      "from": "2024-01-01",
      "to": "2024-12-31"
    },
    "documentType": "INVOICE"
  },
  "pagination": {
    "page": 1,
    "pageSize": 50
  },
  "sort": {
    "field": "createdDate",
    "order": "DESC"
  }
}
```

**Example Response:**
```json
{
  "results": [
    {
      "documentId": "DOC123456",
      "title": "Invoice 2024-001",
      "createdDate": "2024-01-15T00:00:00Z",
      "documentType": "INVOICE",
      "size": 245678,
      "archive": "IESC",
      "folder": "/invoices/2024/Q1"
    }
  ],
  "pagination": {
    "page": 1,
    "pageSize": 50,
    "totalResults": 247,
    "totalPages": 5
  }
}
```

#### 3.1.3 Comment Endpoints

| Method | Endpoint | Description | Request | Response |
|--------|----------|-------------|---------|----------|
| POST | `/documents/{docId}/comments` | Add comment | `CommentRequest` | `Comment` |
| PUT | `/comments/{commentId}` | Edit comment | `CommentRequest` | `Comment` |
| GET | `/documents/{docId}/comments` | List comments | - | `Comment[]` |
| GET | `/comments/{commentId}/history` | Comment history | - | `CommentVersion[]` |

**Example Request: Add Comment**
```json
POST /acme/v1/documents/DOC123456/comments
{
  "text": "This invoice has been approved by finance team."
}
```

**Example Response:**
```json
{
  "commentId": "CMT-20250109-XYZ789",
  "documentId": "DOC123456",
  "userId": "user@acme.com",
  "userName": "John Doe",
  "text": "This invoice has been approved by finance team.",
  "createdAt": "2025-01-09T10:45:00Z",
  "updatedAt": "2025-01-09T10:45:00Z",
  "canEdit": true
}
```

#### 3.1.4 Admin Endpoints

| Method | Endpoint | Description | Request | Response |
|--------|----------|-------------|---------|----------|
| POST | `/admin/tenants` | Create tenant (ECM Admin) | `TenantRequest` | `Tenant` |
| PUT | `/admin/tenants/{tenantId}` | Update tenant config | `TenantRequest` | `Tenant` |
| POST | `/admin/users` | Create user (Client Admin) | `UserRequest` | `User` |
| POST | `/admin/acls` | Manage folder ACLs | `ACLRequest` | `ACL` |
| GET | `/admin/audit` | Get audit logs | Query params | `AuditLog[]` |

#### 3.1.5 MailRoom Endpoints

| Method | Endpoint | Description | Request | Response |
|--------|----------|-------------|---------|----------|
| GET | `/mailroom/items` | List mail items | Query params (filters, pagination) | `MailItemList` |
| POST | `/mailroom/items/search` | Search mail items | `MailSearchRequest` | `MailItemList` |
| GET | `/mailroom/items/{itemId}` | Get mail item details | - | `MailItem` |
| POST | `/mailroom/items/{itemId}/actions/archive` | Archive mail item | - | `ActionResult` |
| POST | `/mailroom/items/{itemId}/actions/forward` | Forward to user | `ForwardRequest` | `ActionResult` |
| POST | `/mailroom/items/{itemId}/actions/annotate` | Add annotation | `AnnotateRequest` | `ActionResult` |
| POST | `/mailroom/bulk-operations` | Initiate bulk operation | `BulkOperationRequest` | `JobResponse` |
| GET | `/mailroom/bulk-operations/{jobId}/status` | Check bulk operation status | - | `JobStatus` |

**Example Request: Forward Mail Item**
```json
POST /acme/v1/mailroom/items/MAIL-123456/actions/forward
{
  "recipientUserId": "user2@acme.com",
  "note": "Please review this document and take action"
}
```

**Example Response:**
```json
{
  "success": true,
  "itemId": "MAIL-123456",
  "action": "forward",
  "recipient": "user2@acme.com",
  "timestamp": "2025-01-09T11:00:00Z"
}
```

**Example Request: Create Tenant**
```json
POST /admin/tenants
{
  "name": "ACME Corporation",
  "subdomain": "acme",
  "archive": {
    "type": "IESC",
    "endpoint": "https://iesc-acme.archive.example.com",
    "credentials": {
      "username": "viewdocs-user",
      "password": "<stored in Secrets Manager>"
    }
  },
  "idp": {
    "type": "SAML",
    "metadataUrl": "https://idp.acme.com/saml/metadata"
  },
  "branding": {
    "logoUrl": "https://cdn.acme.com/logo.png",
    "primaryColor": "#003366"
  }
}
```

---

## 4. Application Flows

### 4.1 User Authentication Flow

```mermaid
sequenceDiagram
    actor User
    participant Browser
    participant CloudFront
    participant Cognito
    participant IdP
    participant API
    participant Lambda

    User->>Browser: Navigate to acme.viewdocs.example.com
    Browser->>CloudFront: GET /
    CloudFront->>Browser: Return Angular app
    Browser->>Browser: Detect no JWT token
    Browser->>Cognito: Redirect to Cognito Hosted UI
    Cognito->>Cognito: Identify tenant from subdomain
    Cognito->>IdP: SAML AuthnRequest
    IdP->>User: Show login page
    User->>IdP: Enter credentials + MFA
    IdP->>Cognito: SAML Assertion
    Cognito->>Cognito: Validate assertion, issue JWT
    Cognito->>Browser: Redirect with code
    Browser->>Cognito: Exchange code for tokens
    Cognito->>Browser: Return JWT (access + refresh tokens)
    Browser->>API: API call with Bearer token
    API->>Cognito: Validate JWT
    Cognito->>API: JWT valid, return user claims
    API->>Lambda: Invoke with tenantId, userId
    Lambda->>Lambda: Process request
    Lambda->>API: Return response
    API->>Browser: JSON response
```

### 4.2 Document View Flow

```mermaid
sequenceDiagram
    actor User
    participant Angular
    participant APIGW as API Gateway
    participant DocLambda as Document Service
    participant DDB as DynamoDB
    participant Archive as IESC/IES/CMOD
    participant EventBridge
    participant EventLambda as Event Service
    participant FRS

    User->>Angular: Click document in search results
    Angular->>APIGW: GET /documents/{docId}/content
    APIGW->>APIGW: Validate JWT (Cognito Authorizer)
    APIGW->>DocLambda: Invoke with tenantId, userId, docId
    DocLambda->>DDB: Get folder ACLs for tenantId
    DDB->>DocLambda: Return ACLs
    DocLambda->>DocLambda: Check if user's role has access
    alt Access Granted
        DocLambda->>DDB: Get archive config for tenantId
        DDB->>DocLambda: Return archive endpoint, type
        DocLambda->>Archive: Fetch document (REST/SOAP)
        Archive->>DocLambda: Return document binary
        DocLambda->>DDB: Log view event (audit)
        DocLambda->>EventBridge: Publish DocumentViewed event
        EventBridge->>EventLambda: Trigger event handler
        EventLambda->>FRS: Send SOAP message to FRS Proxy
        FRS->>FRS: Forward to HUB via IBM MQ
        DocLambda->>APIGW: Stream document binary
        APIGW->>Angular: HTTP 200 with PDF stream
        Angular->>User: Render in viewer
    else Access Denied
        DocLambda->>DDB: Log unauthorized access attempt
        DocLambda->>APIGW: Return 403 Forbidden
        APIGW->>Angular: HTTP 403
        Angular->>User: Show "Access Denied" message
    end
```

### 4.3 Bulk Download Flow

```mermaid
sequenceDiagram
    actor User
    participant Angular
    participant APIGW as API Gateway
    participant DownloadLambda as Download Service
    participant SF as Step Functions
    participant SQS
    participant WorkerLambda as Document Worker
    participant Archive as IESC/IES/CMOD
    participant S3
    participant Email

    User->>Angular: Select docs, click "Bulk Download"
    Angular->>APIGW: POST /documents/bulk-download
    APIGW->>DownloadLambda: Invoke with docIds[]
    DownloadLambda->>DownloadLambda: Validate total size < 5GB
    DownloadLambda->>SF: Start workflow (execution ID = jobId)
    SF->>SQS: Send messages (one per docId)
    DownloadLambda->>APIGW: Return jobId, status=PROCESSING
    APIGW->>Angular: HTTP 202 Accepted
    Angular->>User: Show "Processing..." with jobId

    loop For each document
        SQS->>WorkerLambda: Trigger with docId
        WorkerLambda->>Archive: Fetch document
        Archive->>WorkerLambda: Return binary
        WorkerLambda->>S3: Upload to temp folder
    end

    SF->>SF: Wait for all fetches complete
    SF->>WorkerLambda: Invoke aggregator
    WorkerLambda->>S3: Zip all documents
    WorkerLambda->>S3: Upload final zip
    WorkerLambda->>Email: Send email with download link
    Email->>User: Email: "Your download is ready"

    User->>Angular: Click link in email
    Angular->>APIGW: GET /documents/bulk-download/{jobId}/url
    APIGW->>DownloadLambda: Get download URL
    DownloadLambda->>DownloadLambda: Validate session
    DownloadLambda->>S3: Generate CloudFront signed URL (expires 72h)
    DownloadLambda->>APIGW: Return URL
    APIGW->>Angular: HTTP 200 with URL
    Angular->>S3: Download zip
    S3->>User: Stream zip file
```

### 4.4 Search Flow

```mermaid
sequenceDiagram
    actor User
    participant Angular
    participant APIGW as API Gateway
    participant SearchLambda as Search Service
    participant DDB as DynamoDB
    participant Archive as IESC/IES/CMOD
    participant CloudFront

    User->>Angular: Enter search criteria
    Angular->>APIGW: POST /search/index
    APIGW->>SearchLambda: Invoke with criteria
    SearchLambda->>DDB: Get user's accessible folders (ACLs)
    DDB->>SearchLambda: Return folder list
    SearchLambda->>DDB: Get archive config
    DDB->>SearchLambda: Return archive endpoint
    SearchLambda->>Archive: Execute search with criteria + folder filter
    Archive->>SearchLambda: Return results (up to 1000 docs)
    SearchLambda->>SearchLambda: Filter by ACLs (double-check)
    SearchLambda->>SearchLambda: Paginate (50 per page)
    SearchLambda->>APIGW: Return page 1 results
    APIGW->>CloudFront: Cache results (5 min TTL)
    APIGW->>Angular: HTTP 200 with results
    Angular->>User: Display search results

    User->>Angular: Click "Next Page"
    Angular->>APIGW: POST /search/index?page=2
    APIGW->>CloudFront: Check cache
    CloudFront->>Angular: Return cached results (if available)
```

---

## 5. Archive Adapter Design

### 5.1 Archive Interface

```typescript
interface ArchiveClient {
  /**
   * Search documents by index criteria
   */
  indexSearch(criteria: IndexSearchCriteria): Promise<SearchResult>;

  /**
   * Full-text search (IESC only)
   */
  fullTextSearch(query: string): Promise<SearchResult>;

  /**
   * Get document metadata
   */
  getMetadata(documentId: string): Promise<DocumentMetadata>;

  /**
   * Fetch document content
   */
  getDocument(documentId: string): Promise<Buffer>;

  /**
   * Test connection
   */
  healthCheck(): Promise<boolean>;
}

interface IndexSearchCriteria {
  fields: Record<string, string>; // e.g., { customerId: "CUST-123" }
  dateRange?: { from: Date; to: Date };
  pagination: { page: number; pageSize: number };
  sort?: { field: string; order: 'ASC' | 'DESC' };
}

interface SearchResult {
  documents: DocumentMetadata[];
  totalCount: number;
  page: number;
  pageSize: number;
}

interface DocumentMetadata {
  documentId: string;
  title: string;
  createdDate: Date;
  documentType: string;
  size: number;
  folder: string;
  customFields: Record<string, any>;
}
```

### 5.2 Concrete Implementations

#### 5.2.1 IESC Client (REST)

```typescript
class IESCClient implements ArchiveClient {
  constructor(
    private endpoint: string,
    private credentials: { username: string; password: string }
  ) {}

  async indexSearch(criteria: IndexSearchCriteria): Promise<SearchResult> {
    const response = await axios.post(`${this.endpoint}/api/v1/search`, {
      query: criteria.fields,
      dateRange: criteria.dateRange,
      pagination: criteria.pagination,
    }, {
      auth: this.credentials,
      timeout: 25000, // 25s (< Lambda 29s timeout)
    });

    return this.mapToSearchResult(response.data);
  }

  async fullTextSearch(query: string): Promise<SearchResult> {
    const response = await axios.post(`${this.endpoint}/api/v1/fulltext`, {
      query,
    }, {
      auth: this.credentials,
      timeout: 25000,
    });

    return this.mapToSearchResult(response.data);
  }

  async getDocument(documentId: string): Promise<Buffer> {
    const response = await axios.get(`${this.endpoint}/api/v1/documents/${documentId}`, {
      auth: this.credentials,
      responseType: 'arraybuffer',
      timeout: 25000,
    });

    return Buffer.from(response.data);
  }

  // ... other methods
}
```

#### 5.2.2 IES Client (SOAP)

```typescript
import soap from 'soap';

class IESClient implements ArchiveClient {
  private soapClient: soap.Client;

  constructor(
    private wsdlUrl: string,
    private credentials: { username: string; password: string }
  ) {}

  async initialize() {
    this.soapClient = await soap.createClientAsync(this.wsdlUrl, {
      wsdl_options: { timeout: 10000 },
    });
    this.soapClient.setSecurity(new soap.BasicAuthSecurity(
      this.credentials.username,
      this.credentials.password
    ));
  }

  async indexSearch(criteria: IndexSearchCriteria): Promise<SearchResult> {
    const soapRequest = {
      searchCriteria: criteria.fields,
      maxResults: criteria.pagination.pageSize,
      offset: (criteria.pagination.page - 1) * criteria.pagination.pageSize,
    };

    const [result] = await this.soapClient.SearchDocumentsAsync(soapRequest);
    return this.mapToSearchResult(result);
  }

  async getDocument(documentId: string): Promise<Buffer> {
    const [result] = await this.soapClient.GetDocumentAsync({ documentId });
    return Buffer.from(result.content, 'base64');
  }

  // ... other methods
}
```

#### 5.2.3 CMOD Client (SOAP)

```typescript
class CMODClient implements ArchiveClient {
  // Similar to IESClient with CMOD-specific SOAP schema
  // ... implementation
}
```

### 5.3 Archive Adapter Factory

```typescript
class ArchiveAdapterFactory {
  static async createClient(
    archiveType: 'IESC' | 'IES' | 'CMOD',
    config: ArchiveConfig
  ): Promise<ArchiveClient> {
    const credentials = await this.getCredentials(config.credentialsSecretId);

    switch (archiveType) {
      case 'IESC':
        return new IESCClient(config.endpoint, credentials);

      case 'IES':
        const iesClient = new IESClient(config.wsdlUrl, credentials);
        await iesClient.initialize();
        return iesClient;

      case 'CMOD':
        const cmodClient = new CMODClient(config.wsdlUrl, credentials);
        await cmodClient.initialize();
        return cmodClient;

      default:
        throw new Error(`Unsupported archive type: ${archiveType}`);
    }
  }

  private static async getCredentials(secretId: string): Promise<any> {
    const secretsManager = new AWS.SecretsManager();
    const secret = await secretsManager.getSecretValue({ SecretId: secretId }).promise();
    return JSON.parse(secret.SecretString);
  }
}
```

---

## 6. Error Handling Strategy

### 6.1 Error Categories

| Error Type | HTTP Code | User Message | Action |
|------------|-----------|--------------|--------|
| **Authentication Error** | 401 | "Session expired, please login again" | Redirect to Cognito login |
| **Authorization Error** | 403 | "You don't have permission to access this resource" | Show error, log attempt |
| **Validation Error** | 400 | "Invalid request: {field} is required" | Show field-level errors |
| **Archive Unavailable** | 503 | "Archive system temporarily unavailable, please try again" | Retry after 1 min, show error |
| **Timeout** | 504 | "Request timed out, please try again" | Retry with exponential backoff |
| **Internal Error** | 500 | "An unexpected error occurred" | Log error, show generic message |

### 6.2 Retry Logic

```typescript
async function withRetry<T>(
  fn: () => Promise<T>,
  options: { maxRetries: number; backoffMs: number }
): Promise<T> {
  let lastError: Error;

  for (let i = 0; i < options.maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;

      // Don't retry on 4xx errors (except 429)
      if (error.response?.status >= 400 && error.response?.status < 500 && error.response?.status !== 429) {
        throw error;
      }

      const delay = options.backoffMs * Math.pow(2, i);
      await sleep(delay);
    }
  }

  throw lastError;
}

// Usage
const document = await withRetry(
  () => archiveClient.getDocument(docId),
  { maxRetries: 3, backoffMs: 1000 }
);
```

---

## 7. Caching Strategy

### 7.1 CloudFront Caching

| Content Type | Cache TTL | Cache Key |
|-------------|-----------|-----------|
| **Static Assets** (JS, CSS, images) | 1 year | File path + version hash |
| **API Responses** (search results) | 5 minutes | tenant_id + endpoint + query params |
| **Documents** | No cache | N/A (streamed through) |

### 7.2 DynamoDB Caching Patterns

- **Tenant Config**: Cached in Lambda memory for 10 minutes
- **ACLs**: Cached in Lambda memory for 5 minutes
- **Archive Credentials**: Fetched from Secrets Manager, cached in Lambda memory for 15 minutes

---

## 8. Performance Optimization

### 8.1 Lambda Optimization

- **Cold Start Reduction**: Provisioned concurrency for Document Service (10 instances)
- **Bundle Size**: Use esbuild to tree-shake dependencies, target <5MB
- **Lazy Loading**: Initialize SOAP clients only when needed
- **Connection Reuse**: Reuse HTTP connections to archives (keep-alive)

### 8.2 DynamoDB Optimization

- **Single-Table Design**: Reduce number of queries
- **Batch Operations**: Use BatchGetItem for fetching ACLs for multiple folders
- **Projection Expressions**: Fetch only required attributes

---

## Next Steps

1. Review API contracts with frontend team
2. Build POC for IESC integration
3. Proceed to [03-data-architecture.md](03-data-architecture.md) for DynamoDB schema design

---

**Document Control**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-09 | Architecture Team | Initial application architecture draft |
