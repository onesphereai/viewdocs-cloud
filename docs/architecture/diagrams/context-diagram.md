# C4 Model - Level 1: System Context Diagram

**Viewdocs Cloud - System Context**

This diagram shows how Viewdocs Cloud fits into the broader ecosystem of users and external systems.

---

## Mermaid Diagram

```mermaid
C4Context
    title System Context Diagram for Viewdocs Cloud

    Person(clientUser, "Client User", "End user accessing documents")
    Person(clientAdmin, "Client Admin", "Manages users and permissions for their organization")
    Person(helpDesk, "HelpDesk User", "Provides L1/L2 support to clients")
    Person(ecmAdmin, "ECM Admin", "Configures tenants and archives")

    System(viewdocs, "Viewdocs Cloud", "Multi-tenant document management system providing search, view, download, and collaboration capabilities")

    System_Ext(idm, "IDM (Identity Provider)", "SAML 2.0 authentication for users")
    System_Ext(externalIdP, "Customer IdP", "External SAML 2.0 identity providers (bring your own IdP)")
    System_Ext(iesc, "IESC", "Cloud-based Enterprise Content Management (AWS)")
    System_Ext(ies, "IES", "On-premise Enterprise Content Management (SOAP API)")
    System_Ext(cmod, "CMOD", "IBM on-premise document archive (SOAP API)")
    System_Ext(frs, "FRS Proxy", "File Receipt Service proxy for IBM MQ messaging to HUB")
    System_Ext(hub, "HUB", "On-premise event aggregation system")
    System_Ext(emailSvc, "Email Service", "IDM Email Service for sending notifications")

    Rel(clientUser, viewdocs, "Searches, views, downloads documents", "HTTPS")
    Rel(clientAdmin, viewdocs, "Manages users, assigns folder access", "HTTPS")
    Rel(helpDesk, viewdocs, "Supports clients, monitors system health", "HTTPS")
    Rel(ecmAdmin, viewdocs, "Onboards tenants, configures archives", "HTTPS")

    Rel(viewdocs, idm, "Authenticates users", "SAML 2.0")
    Rel(viewdocs, externalIdP, "Authenticates users (customer IdP)", "SAML 2.0")
    Rel(viewdocs, iesc, "Searches, fetches documents", "REST API / HTTPS")
    Rel(viewdocs, ies, "Searches, fetches documents", "SOAP / Direct Connect")
    Rel(viewdocs, cmod, "Searches, fetches documents", "SOAP / Direct Connect")
    Rel(viewdocs, frs, "Publishes document events", "SOAP / Direct Connect")
    Rel(frs, hub, "Forwards events", "IBM MQ")
    Rel(viewdocs, emailSvc, "Sends bulk download notifications", "REST API")

    UpdateLayoutConfig($c4ShapeInRow="3", $c4BoundaryInRow="1")
```

---

## System Responsibilities

### Viewdocs Cloud
- **Authentication**: Integrates with IDM and external SAML IdPs via AWS Cognito
- **Authorization**: Enforces role-based access control (RBAC) with folder-level ACLs
- **Document Access**: Proxies document retrieval from IESC, IES, or CMOD archives
- **Search**: Executes index-based, full-text, and conversational search across archives
- **Collaboration**: Manages document comments with version history
- **Bulk Downloads**: Orchestrates async download of up to 5GB, sends email notifications
- **Audit**: Logs all document operations for compliance (6-month retention in prod)
- **Event Publishing**: Publishes document events to HUB via FRS Proxy

---

## External Systems

| System | Type | Interface | Purpose |
|--------|------|-----------|---------|
| **IDM** | SAML 2.0 IdP | SAML | Authenticate FBDMS users and clients using IDM |
| **Customer IdP** | SAML 2.0 IdP | SAML | Authenticate users via customer's own identity provider |
| **IESC** | Cloud ECM | REST API | Store and retrieve documents in AWS-hosted archive |
| **IES** | On-Prem ECM | SOAP API | Store and retrieve documents in on-premise archive |
| **CMOD** | On-Prem Archive | SOAP API | Store and retrieve documents in IBM on-premise archive |
| **FRS Proxy** | Message Proxy | SOAP API | Forward events to HUB via IBM MQ |
| **HUB** | Event Aggregator | IBM MQ | Centralize document events from Viewdocs |
| **Email Service** | Email Platform | REST API | Send bulk download completion emails |

---

## User Personas

### Client User
- **Goal**: Find and access documents quickly and securely
- **Actions**: Search documents, view in browser, download single/bulk, add comments, send via email
- **Authorization**: Folder-level ACLs based on assigned roles

### Client Admin
- **Goal**: Manage users and control access within their organization
- **Actions**: Invite users, assign roles, configure folder ACLs
- **Authorization**: Admin role within their tenant only

### HelpDesk User
- **Goal**: Support clients and troubleshoot issues
- **Actions**: View logs, monitor system health, access documents on behalf of clients (with audit)
- **Authorization**: Cross-tenant read-only access

### ECM Admin
- **Goal**: Onboard new tenants and configure archive integrations
- **Actions**: Create tenants, configure IESC/IES/CMOD endpoints, manage branding
- **Authorization**: Full admin access across all tenants

---

## Key Interactions

### Authentication Flow
1. User navigates to `tenant.viewdocs.example.com`
2. Viewdocs redirects to AWS Cognito
3. Cognito identifies tenant from subdomain
4. Cognito redirects to appropriate IdP (IDM or customer IdP)
5. User authenticates with IdP (credentials + MFA)
6. IdP returns SAML assertion to Cognito
7. Cognito issues JWT tokens (access + refresh)
8. User accesses Viewdocs with JWT Bearer token

### Document Access Flow
1. User searches for documents (Viewdocs → IESC/IES/CMOD)
2. User clicks document to view
3. Viewdocs checks folder ACLs in DynamoDB
4. If authorized, Viewdocs fetches document from archive
5. Viewdocs streams document to user's browser
6. Viewdocs logs view event to DynamoDB
7. Viewdocs publishes event to EventBridge → FRS → HUB

### Bulk Download Flow
1. User selects multiple documents, clicks "Bulk Download"
2. Viewdocs initiates Step Functions workflow
3. Step Functions fetches documents from archive (one Lambda per document)
4. Documents aggregated into zip file in S3
5. Viewdocs sends email notification with download link
6. User downloads zip from S3 via CloudFront

---

## Data Flow Summary

```mermaid
flowchart LR
    User[Users]
    VD[Viewdocs Cloud]
    Auth[IDM / Customer IdP]
    Archives[IESC / IES / CMOD]
    Events[HUB via FRS]
    Email[Email Service]

    User -->|1. Login| VD
    VD -->|2. SAML Auth| Auth
    Auth -->|3. JWT Token| VD
    User -->|4. Search/View| VD
    VD -->|5. Fetch Docs| Archives
    Archives -->|6. Documents| VD
    VD -->|7. Publish Events| Events
    VD -->|8. Send Emails| Email
```

---

## Compliance & Security

- **Data Residency**: All Viewdocs data stored in Australia (ap-southeast-2, ap-southeast-4)
- **Encryption**: TLS 1.2+ for all external communications (SAML, REST, SOAP)
- **Authentication**: SAML 2.0 with MFA (managed by IdP)
- **Authorization**: Role-based access control (RBAC) enforced at API layer
- **Audit**: All document operations logged with 6-month retention (prod)

---

## draw.io Reference

For creating a professional diagram with AWS icons:
1. Use [draw.io](https://app.diagrams.net/)
2. Import AWS Architecture Icons: File → Open Library → Search "AWS 19"
3. Components:
   - Viewdocs Cloud: AWS Lambda, API Gateway, DynamoDB
   - IDM: Generic SAML IdP icon
   - IESC/IES/CMOD: Storage icon with labels
   - FRS/HUB: On-premise server icon
4. Export as PNG/SVG and save in `/docs/architecture/diagrams/context-diagram.png`

---

**Document Control**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-01-09 | Architecture Team | Initial C4 Level 1 context diagram |
