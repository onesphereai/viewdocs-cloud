# Data Architecture

**Document Version:** 1.0
**Last Updated:** 2025-11-09
**Status:** Draft

---

## 1. Data Architecture Overview

### 1.1 Data Storage Strategy

| Data Type | Storage | Rationale |
|-----------|---------|-----------|
| **Tenant Configuration** | DynamoDB Global Tables | Low latency, multi-region replication, schema flexibility |
| **User Roles & ACLs** | DynamoDB Global Tables | Fast authorization checks, tenant-partitioned |
| **Audit Logs** | DynamoDB Global Tables | Query by tenant+time, TTL for auto-deletion |
| **Comments** | DynamoDB Global Tables | Real-time collaboration, version history |
| **Bulk Download Jobs** | DynamoDB Global Tables | Job status tracking, polling support |
| **Document Binaries** | S3 (temporary) | Large files, presigned URLs, lifecycle policies |
| **Archive Credentials** | Secrets Manager | Encrypted, auto-rotation, audit trail |
| **Static Assets (Angular)** | S3 + CloudFront | CDN distribution, version control |

### 1.2 Data Sovereignty

- **Primary Region**: ap-southeast-2 (Sydney, Australia)
- **DR Region**: ap-southeast-4 (Melbourne, Australia)
- **Compliance**: All data remains in Australia (no cross-border transfers)

---

## 2. DynamoDB Table Design

### 2.1 Single-Table Design Philosophy

**Table Name**: `viewdocs-data` (Global Table replicated to ap-southeast-4)

**Why Single Table?**
- Reduce number of cross-table joins
- Simplify IAM permissions
- Lower cost (no per-table overhead)
- Enable transactions across entities

**Partition Strategy**: `tenant_id` prefix for all partition keys to ensure tenant isolation

### 2.2 Primary Key Schema

```
PK (Partition Key): String (tenant_id + entity_type)
SK (Sort Key): String (entity_id + metadata)
```

**Attributes**:
- `PK`: Partition Key (e.g., `TENANT#acme`)
- `SK`: Sort Key (e.g., `CONFIG#archive`)
- `EntityType`: String (for querying by type)
- `CreatedAt`: String (ISO 8601)
- `UpdatedAt`: String (ISO 8601)
- `TTL`: Number (Unix timestamp for auto-deletion, audit logs only)
- `Data`: Map (entity-specific attributes)

### 2.3 Global Secondary Indexes (GSIs)

#### GSI1: EntityType-CreatedAt-Index

**Purpose**: Query all entities of a type across tenants (e.g., all bulk download jobs)

```
GSI1PK (Partition Key): EntityType
GSI1SK (Sort Key): CreatedAt
```

**Use Cases**:
- ECM Admin queries all tenants
- Analytics queries across all documents/events

#### GSI2: UserId-CreatedAt-Index

**Purpose**: Query user activity across documents

```
GSI2PK (Partition Key): UserId
GSI2SK (Sort Key): CreatedAt
```

**Use Cases**:
- User activity audit reports
- "My Downloads" page

---

## 3. Entity Schemas

### 3.1 Tenant Configuration

**Access Pattern**: Get archive config for a tenant

| Attribute | Type | Example | Description |
|-----------|------|---------|-------------|
| PK | String | `TENANT#acme` | Partition key |
| SK | String | `CONFIG#archive` | Sort key |
| EntityType | String | `TenantConfig` | |
| Data.name | String | `ACME Corporation` | Tenant display name |
| Data.subdomain | String | `acme` | Subdomain |
| Data.archive.type | String | `IESC` | IESC/IES/CMOD |
| Data.archive.endpoint | String | `https://iesc-acme.example.com` | Archive API endpoint |
| Data.archive.credentialsSecretId | String | `viewdocs/acme/archive-creds` | Secrets Manager ARN |
| Data.idp.type | String | `SAML` | IDM or External |
| Data.idp.metadataUrl | String | `https://idp.acme.com/saml/metadata` | SAML metadata |
| Data.branding.logoUrl | String | `https://cdn.acme.com/logo.png` | |
| Data.branding.primaryColor | String | `#003366` | |
| CreatedAt | String | `2025-01-09T10:00:00Z` | |
| UpdatedAt | String | `2025-01-09T10:00:00Z` | |

**Example Item**:
```json
{
  "PK": "TENANT#acme",
  "SK": "CONFIG#archive",
  "EntityType": "TenantConfig",
  "Data": {
    "name": "ACME Corporation",
    "subdomain": "acme",
    "archive": {
      "type": "IESC",
      "endpoint": "https://iesc-acme.example.com",
      "credentialsSecretId": "arn:aws:secretsmanager:ap-southeast-2:123456789012:secret:viewdocs/acme/archive-creds"
    },
    "idp": {
      "type": "SAML",
      "metadataUrl": "https://idp.acme.com/saml/metadata"
    },
    "branding": {
      "logoUrl": "https://cdn.acme.com/logo.png",
      "primaryColor": "#003366"
    }
  },
  "CreatedAt": "2025-01-09T10:00:00Z",
  "UpdatedAt": "2025-01-09T10:00:00Z"
}
```

**Query**:
```typescript
const params = {
  TableName: 'viewdocs-data',
  Key: {
    PK: `TENANT#${tenantId}`,
    SK: 'CONFIG#archive'
  }
};
const result = await dynamodb.get(params).promise();
```

### 3.2 Role-to-ACL Mapping

**Access Pattern**: Get ACLs for a role within a tenant

| Attribute | Type | Example | Description |
|-----------|------|---------|-------------|
| PK | String | `TENANT#acme` | Partition key |
| SK | String | `ROLE#admin#ACL` | Sort key |
| EntityType | String | `RoleACL` | |
| Data.roleId | String | `admin` | Role identifier (from IdP) |
| Data.roleName | String | `Administrator` | Display name |
| Data.permissions | List | `["view", "download", "comment", "bulk_download", "admin"]` | Allowed operations |
| CreatedAt | String | `2025-01-09T10:00:00Z` | |
| UpdatedAt | String | `2025-01-09T10:00:00Z` | |

**Example Item**:
```json
{
  "PK": "TENANT#acme",
  "SK": "ROLE#admin#ACL",
  "EntityType": "RoleACL",
  "Data": {
    "roleId": "admin",
    "roleName": "Administrator",
    "permissions": ["view", "download", "comment", "bulk_download", "admin"]
  },
  "CreatedAt": "2025-01-09T10:00:00Z",
  "UpdatedAt": "2025-01-09T10:00:00Z"
}
```

### 3.3 Folder ACLs

**Access Pattern**: Get folder-level permissions for a tenant

| Attribute | Type | Example | Description |
|-----------|------|---------|-------------|
| PK | String | `TENANT#acme` | Partition key |
| SK | String | `FOLDER#/invoices/2024#ACL` | Sort key |
| EntityType | String | `FolderACL` | |
| Data.folderId | String | `/invoices/2024` | Folder path in archive |
| Data.rolePermissions | Map | `{"admin": ["view", "download"], "user": ["view"]}` | Role-to-permission mapping |
| CreatedAt | String | `2025-01-09T10:00:00Z` | |
| UpdatedAt | String | `2025-01-09T10:00:00Z` | |

**Example Item**:
```json
{
  "PK": "TENANT#acme",
  "SK": "FOLDER#/invoices/2024#ACL",
  "EntityType": "FolderACL",
  "Data": {
    "folderId": "/invoices/2024",
    "rolePermissions": {
      "admin": ["view", "download", "comment", "bulk_download"],
      "finance": ["view", "download"],
      "auditor": ["view"]
    }
  },
  "CreatedAt": "2025-01-09T10:00:00Z",
  "UpdatedAt": "2025-01-09T10:00:00Z"
}
```

**Authorization Check**:
```typescript
// Get user's role from JWT claims
const userRole = jwtClaims['custom:role']; // e.g., "finance"

// Get folder ACLs
const folderAcls = await dynamodb.get({
  TableName: 'viewdocs-data',
  Key: {
    PK: `TENANT#${tenantId}`,
    SK: `FOLDER#${folderId}#ACL`
  }
}).promise();

// Check if user's role has permission
const permissions = folderAcls.Item.Data.rolePermissions[userRole] || [];
const hasAccess = permissions.includes('view');
```

### 3.4 Audit Events

**Access Pattern**: Query audit logs by tenant + time range

| Attribute | Type | Example | Description |
|-----------|------|---------|-------------|
| PK | String | `TENANT#acme` | Partition key |
| SK | String | `AUDIT#2025-01-09T10:30:00Z#EVT123` | Sort key (timestamp + eventId) |
| EntityType | String | `AuditEvent` | |
| GSI2PK | String | `USER#user@acme.com` | For user activity queries |
| GSI2SK | String | `2025-01-09T10:30:00Z` | Timestamp |
| Data.eventType | String | `DocumentViewed` | Event type |
| Data.userId | String | `user@acme.com` | Actor |
| Data.resourceId | String | `DOC123456` | Document ID |
| Data.resourceType | String | `Document` | |
| Data.action | String | `view` | |
| Data.ipAddress | String | `203.45.67.89` | User IP |
| Data.userAgent | String | `Mozilla/5.0...` | Browser |
| Data.metadata | Map | `{"archive": "IESC", "folder": "/invoices/2024"}` | Additional context |
| TTL | Number | `1752422400` | Unix timestamp (6 months for prod) |
| CreatedAt | String | `2025-01-09T10:30:00Z` | |

**Example Item**:
```json
{
  "PK": "TENANT#acme",
  "SK": "AUDIT#2025-01-09T10:30:00Z#EVT123456",
  "EntityType": "AuditEvent",
  "GSI2PK": "USER#user@acme.com",
  "GSI2SK": "2025-01-09T10:30:00Z",
  "Data": {
    "eventType": "DocumentViewed",
    "userId": "user@acme.com",
    "resourceId": "DOC123456",
    "resourceType": "Document",
    "action": "view",
    "ipAddress": "203.45.67.89",
    "userAgent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)...",
    "metadata": {
      "archive": "IESC",
      "folder": "/invoices/2024",
      "documentTitle": "Invoice 2024-001"
    }
  },
  "TTL": 1752422400,
  "CreatedAt": "2025-01-09T10:30:00Z"
}
```

**Query: Get audit logs for tenant in date range**:
```typescript
const params = {
  TableName: 'viewdocs-data',
  KeyConditionExpression: 'PK = :pk AND SK BETWEEN :start AND :end',
  ExpressionAttributeValues: {
    ':pk': `TENANT#${tenantId}`,
    ':start': `AUDIT#2025-01-01T00:00:00Z`,
    ':end': `AUDIT#2025-01-31T23:59:59Z`
  }
};
const result = await dynamodb.query(params).promise();
```

**TTL Configuration**:
- Prod: 6 months (15,768,000 seconds)
- UAT: 1 month (2,628,000 seconds)
- Dev: 1 week (604,800 seconds)

### 3.5 Comments

**Access Pattern**: Get comments for a document

| Attribute | Type | Example | Description |
|-----------|------|---------|-------------|
| PK | String | `DOC#DOC123456` | Partition key (document ID) |
| SK | String | `COMMENT#2025-01-09T10:45:00Z#CMT789` | Sort key (timestamp + commentId) |
| EntityType | String | `Comment` | |
| Data.tenantId | String | `acme` | Tenant identifier |
| Data.commentId | String | `CMT-20250109-789` | Unique comment ID |
| Data.userId | String | `user@acme.com` | Commenter |
| Data.userName | String | `John Doe` | Display name |
| Data.text | String | `This invoice has been approved.` | Comment text |
| Data.version | Number | `1` | Version number (for edit history) |
| Data.previousVersions | List | `[{version: 1, text: "...", updatedAt: "..."}]` | Edit history |
| CreatedAt | String | `2025-01-09T10:45:00Z` | |
| UpdatedAt | String | `2025-01-09T10:45:00Z` | Last edit time |

**Example Item**:
```json
{
  "PK": "DOC#DOC123456",
  "SK": "COMMENT#2025-01-09T10:45:00Z#CMT789",
  "EntityType": "Comment",
  "Data": {
    "tenantId": "acme",
    "commentId": "CMT-20250109-789",
    "userId": "user@acme.com",
    "userName": "John Doe",
    "text": "This invoice has been approved by finance team.",
    "version": 2,
    "previousVersions": [
      {
        "version": 1,
        "text": "This invoice has been approved.",
        "updatedAt": "2025-01-09T10:45:00Z"
      }
    ]
  },
  "CreatedAt": "2025-01-09T10:45:00Z",
  "UpdatedAt": "2025-01-09T11:00:00Z"
}
```

**Business Rule Check (24-hour edit window)**:
```typescript
const canEdit = (comment: Comment, userId: string): boolean => {
  const isOwner = comment.Data.userId === userId;
  const within24Hours = (Date.now() - new Date(comment.CreatedAt).getTime()) < 24 * 60 * 60 * 1000;
  return isOwner && within24Hours;
};
```

### 3.6 Bulk Download Jobs

**Access Pattern**: Get job status, query user's jobs

| Attribute | Type | Example | Description |
|-----------|------|---------|-------------|
| PK | String | `TENANT#acme` | Partition key |
| SK | String | `DOWNLOAD#JOB-20250109-ABC123` | Sort key |
| EntityType | String | `BulkDownloadJob` | |
| GSI2PK | String | `USER#user@acme.com` | For user's jobs query |
| GSI2SK | String | `2025-01-09T10:30:00Z` | Created timestamp |
| Data.jobId | String | `JOB-20250109-ABC123` | Unique job ID |
| Data.userId | String | `user@acme.com` | Requester |
| Data.status | String | `PROCESSING` | PENDING/PROCESSING/COMPLETED/FAILED |
| Data.documentIds | List | `["DOC123", "DOC456"]` | Requested documents |
| Data.totalDocuments | Number | `150` | Total count |
| Data.completedDocuments | Number | `75` | Processed count |
| Data.failedDocuments | List | `["DOC999"]` | Failed document IDs |
| Data.totalSize | Number | `2147483648` | Total size in bytes (2GB) |
| Data.s3Key | String | `bulk-downloads/acme/JOB-ABC123.zip` | S3 object key (when complete) |
| Data.downloadUrl | String | `https://cdn.viewdocs.example.com/...` | CloudFront URL (expires 72h) |
| Data.expiresAt | String | `2025-01-12T10:30:00Z` | URL expiry |
| CreatedAt | String | `2025-01-09T10:30:00Z` | |
| UpdatedAt | String | `2025-01-09T10:45:00Z` | |
| TTL | Number | `1736595000` | Delete after 72 hours |

**Example Item**:
```json
{
  "PK": "TENANT#acme",
  "SK": "DOWNLOAD#JOB-20250109-ABC123",
  "EntityType": "BulkDownloadJob",
  "GSI2PK": "USER#user@acme.com",
  "GSI2SK": "2025-01-09T10:30:00Z",
  "Data": {
    "jobId": "JOB-20250109-ABC123",
    "userId": "user@acme.com",
    "status": "COMPLETED",
    "documentIds": ["DOC123456", "DOC123457"],
    "totalDocuments": 2,
    "completedDocuments": 2,
    "failedDocuments": [],
    "totalSize": 2147483648,
    "s3Key": "bulk-downloads/acme/JOB-20250109-ABC123.zip",
    "downloadUrl": "https://cdn.viewdocs.example.com/JOB-ABC123.zip?...",
    "expiresAt": "2025-01-12T10:30:00Z"
  },
  "CreatedAt": "2025-01-09T10:30:00Z",
  "UpdatedAt": "2025-01-09T10:45:00Z",
  "TTL": 1736595000
}
```

---

## 4. Data Access Patterns Summary

| Access Pattern | Query Type | Key Condition | GSI |
|----------------|------------|---------------|-----|
| Get tenant config | Get | PK=TENANT#{id}, SK=CONFIG#archive | - |
| Get role ACLs | Query | PK=TENANT#{id}, SK begins_with ROLE# | - |
| Get folder ACLs | Get | PK=TENANT#{id}, SK=FOLDER#{path}#ACL | - |
| Get audit logs (tenant + time) | Query | PK=TENANT#{id}, SK between AUDIT#{start} and AUDIT#{end} | - |
| Get user activity | Query | GSI2PK=USER#{id}, GSI2SK between {start} and {end} | GSI2 |
| Get comments for document | Query | PK=DOC#{id}, SK begins_with COMMENT# | - |
| Get bulk download job | Get | PK=TENANT#{id}, SK=DOWNLOAD#JOB-{id} | - |
| Get user's bulk downloads | Query | GSI2PK=USER#{id}, EntityType=BulkDownloadJob | GSI2 |
| Query all tenants (ECM Admin) | Query | GSI1PK=TenantConfig | GSI1 |

---

## 5. DynamoDB Capacity Planning

### 5.1 Estimated Item Sizes

| Entity | Avg Size | Count (500 tenants) | Total Storage |
|--------|----------|---------------------|---------------|
| Tenant Config | 2 KB | 500 | 1 MB |
| Role ACLs | 0.5 KB | 2,500 (5 roles/tenant) | 1.25 MB |
| Folder ACLs | 1 KB | 50,000 (100 folders/tenant) | 50 MB |
| Audit Events (6mo retention) | 0.8 KB | 25,000,000 (5M events/month * 5 months) | 20 GB |
| Comments | 0.5 KB | 1,000,000 | 500 MB |
| Bulk Download Jobs (72h retention) | 2 KB | 10,000 | 20 MB |
| **Total** | | | **~21 GB** |

### 5.2 Throughput Estimates

**Assumptions**:
- 500 concurrent users
- Each user performs 10 read operations/minute (search, view documents)
- 10% of users perform write operations (comments, downloads)

| Operation | Reads/sec | Writes/sec | RCU | WCU |
|-----------|-----------|------------|-----|-----|
| Document view (ACL check + audit log) | 83 | 83 | 42 | 83 |
| Search (ACL check) | 50 | 0 | 25 | 0 |
| Comments | 5 | 5 | 3 | 5 |
| Bulk download jobs | 2 | 2 | 1 | 2 |
| **Total** | **140/sec** | **90/sec** | **71 RCU** | **90 WCU** |

**Provisioned Capacity (with buffer)**:
- **Read Capacity Units (RCU)**: 100 (71 * 1.4 buffer)
- **Write Capacity Units (WCU)**: 125 (90 * 1.4 buffer)
- **Auto-Scaling**: Min 50, Max 500 for both RCU/WCU

**Cost Estimate** (ap-southeast-2):
- RCU: 100 * $0.000742/hour * 730 hours = $54/month
- WCU: 125 * $0.003710/hour * 730 hours = $338/month
- Storage: 21 GB * $0.329/GB = $7/month
- **Total**: ~$399/month (vs on-demand ~$500/month for this load)

---

## 6. S3 Bucket Design

### 6.1 Bulk Downloads Bucket

**Bucket Name**: `viewdocs-bulk-downloads-prod`

**Structure**:
```
s3://viewdocs-bulk-downloads-prod/
  └── {tenantId}/
      └── {jobId}.zip
```

**Lifecycle Policy**:
- Delete objects after 72 hours
- Transition to Glacier (not needed, direct deletion)

**Encryption**: SSE-KMS with customer-managed key

**Versioning**: Disabled (no need for versioning bulk downloads)

**Access**: CloudFront signed URLs (no public access)

### 6.2 Frontend Assets Bucket

**Bucket Name**: `viewdocs-frontend-prod`

**Structure**:
```
s3://viewdocs-frontend-prod/
  └── {version}/
      ├── index.html
      ├── main.{hash}.js
      ├── styles.{hash}.css
      └── assets/
          └── logo.png
```

**CloudFront Distribution**: `d1234abcd.cloudfront.net` → `viewdocs.example.com`

**Cache Policy**: Cache for 1 year (immutable assets with hash in filename)

---

## 7. Secrets Manager Schema

### 7.1 Archive Credentials

**Secret Name**: `viewdocs/{tenantId}/archive-creds`

**Secret Value** (JSON):
```json
{
  "username": "viewdocs-acme-user",
  "password": "secure-password-here",
  "apiKey": "optional-api-key"
}
```

**Rotation**: Enabled, every 90 days (Lambda rotation function)

**Access**: Document Service Lambda execution role has `secretsmanager:GetSecretValue` permission

---

## 8. Data Migration Strategy

**Note**: Document migration is out of scope (documents remain in IESC/IES/CMOD).

### 8.1 Configuration Migration

1. Export tenant configs from on-premise Oracle database
2. Transform to DynamoDB JSON format
3. BatchWriteItem to DynamoDB
4. Validate with smoke tests (login, search, view document)

### 8.2 User Migration

1. Users remain in IdP (IDM or external SAML)
2. No user data migration needed
3. Role mappings configured in Viewdocs admin portal

---

## 9. Data Retention & Compliance

| Data Type | Retention | Deletion Method | Compliance Requirement |
|-----------|-----------|-----------------|------------------------|
| Audit Logs (Prod) | 6 months | DynamoDB TTL | Australian Privacy Act |
| Audit Logs (UAT) | 1 month | DynamoDB TTL | - |
| Audit Logs (Dev) | 1 week | DynamoDB TTL | - |
| Bulk Download Files | 72 hours | S3 Lifecycle Policy | - |
| Comments | Indefinite (until user deletes) | Manual deletion API | - |
| Tenant Config | Indefinite | Manual deletion (ECM Admin) | - |

---

## Next Steps

1. Validate DynamoDB access patterns with POC
2. Test Global Tables replication latency
3. Proceed to [04-technology-architecture.md](04-technology-architecture.md)

---

**Document Control**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-09 | Architecture Team | Initial data architecture draft |
