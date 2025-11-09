# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Viewdocs Cloud Migration** is a multi-tenant, serverless document management system migrating from on-premise Java/Spring/Tomcat/Oracle stack to AWS serverless architecture. The system provides document viewing, search, download, and management capabilities across multiple archive systems (IESC, IES, CMOD).

### Key Characteristics
- **Multi-tenant**: Pool model with logical isolation (5-500 tenants)
- **Serverless**: AWS Lambda, API Gateway, DynamoDB, S3, CloudFront
- **Hybrid**: Integrates with on-premise systems (IES, CMOD, FRS, HUB) via Direct Connect
- **Multi-region**: Primary in ap-southeast-2, DR in ap-southeast-4 (Active-Passive failover)
- **Scale**: 500 concurrent users, 10-1000 users per tenant

## Technology Stack

### Backend
- **Language**: TypeScript
- **Runtime**: Node.js on AWS Lambda
- **API**: API Gateway (REST)
- **Database**: DynamoDB with Global Tables
- **Storage**: S3 (temporary document storage, bulk downloads)
- **Authentication**: AWS Cognito with SAML 2.0 federation
- **Event Processing**: EventBridge, Step Functions, SQS

### Frontend
- **Framework**: Angular
- **Hosting**: S3 + CloudFront

### Infrastructure as Code
- **Tool**: AWS CDK (TypeScript)
- **Deployment**: CDK Pipelines

### Integrations
- **IESC**: REST API (AWS-hosted, per-tenant stack)
- **IES**: SOAP API (on-premise via Direct Connect)
- **CMOD**: SOAP API (IBM on-premise via Direct Connect)
- **FRS Proxy**: SOAP API (AWS proxy to on-premise FRS/IBM MQ via Direct Connect)
- **IDM**: SAML 2.0 IdP (AWS-hosted) + support for external IdPs
- **Email**: IDM Email Service (current), Email Platform REST (future)

## Architecture Principles

### Multi-Tenancy (Pool Model)
- **Logical Isolation**: Single shared infrastructure with tenant_id partitioning
- **Tenant Identification**: Subdomain-based routing (tenant1.viewdocs.example.com)
- **Data Isolation**: DynamoDB partition key design with tenant_id prefix
- **No Cross-Tenant Access**: Strict authorization checks on every request

### Security
- **Data Residency**: All data in Australia (ap-southeast-2, ap-southeast-4)
- **Encryption**: At rest (DynamoDB, S3 with KMS) and in transit (TLS 1.2+)
- **Authentication**: Cognito with SAML 2.0, support for external IdPs
- **Authorization**: Role-based access control (RBAC) with ACLs stored in DynamoDB
- **Audit**: All document operations logged to DynamoDB with TTL (6mo prod, 1mo UAT, 1wk dev)

### Performance & Resilience
- **Caching**: CloudFront for static assets, DynamoDB for configuration/ACLs
- **Async Processing**: Step Functions for bulk downloads (up to 5GB)
- **Retry Logic**: Built into FRS Proxy for on-premise integrations
- **Concurrency**: Lambda concurrency controls to prevent noisy neighbor

### Observability
- **Logging**: CloudWatch Logs (centralized per tenant)
- **Metrics**: CloudWatch Metrics
- **Tracing**: X-Ray for distributed tracing
- **Events**: EventBridge for real-time events to HUB

## Common Development Commands

### CDK Infrastructure
```bash
# Install dependencies
npm install

# Bootstrap CDK (first time only per account/region)
cdk bootstrap aws://ACCOUNT-ID/ap-southeast-2
cdk bootstrap aws://ACCOUNT-ID/ap-southeast-4

# Synthesize CloudFormation templates
cdk synth

# Deploy to dev environment
cdk deploy --all --context env=dev

# Deploy to UAT environment
cdk deploy --all --context env=uat

# Deploy to prod environment
cdk deploy --all --context env=prod

# Destroy stack (dev/uat only)
cdk destroy --all --context env=dev
```

### Backend Lambda Development
```bash
# Install dependencies
cd backend
npm install

# Run unit tests
npm test

# Run single test file
npm test -- --testPathPattern=document-service.test.ts

# Run tests with coverage
npm test -- --coverage

# Lint code
npm run lint

# Fix linting issues
npm run lint:fix

# Build for deployment
npm run build

# Run locally with SAM (if configured)
sam local start-api
```

### Frontend Angular Development
```bash
# Install dependencies
cd frontend
npm install

# Run dev server
npm start
# Access at http://localhost:4200

# Run unit tests
npm test

# Run single test file
npm test -- --include='**/document-viewer.component.spec.ts'

# Run e2e tests
npm run e2e

# Build for production
npm run build:prod

# Lint
npm run lint
```

## Repository Structure

```
/
├── docs/
│   └── architecture/          # Architecture documentation (TOGAF + C4)
│       ├── 00-architecture-overview.md
│       ├── 01-business-architecture.md
│       ├── 02-application-architecture.md
│       ├── 03-data-architecture.md
│       ├── 04-technology-architecture.md
│       ├── 05-security-architecture.md
│       ├── 06-deployment-architecture.md
│       ├── 07-infrastructure-architecture.md
│       ├── 08-cost-architecture.md
│       ├── 10-decision-log.md
│       └── diagrams/          # Mermaid + draw.io diagrams
├── infrastructure/            # AWS CDK code
│   ├── bin/                   # CDK app entry point
│   ├── lib/                   # CDK stack definitions
│   │   ├── stacks/
│   │   │   ├── api-stack.ts
│   │   │   ├── auth-stack.ts
│   │   │   ├── data-stack.ts
│   │   │   ├── frontend-stack.ts
│   │   │   ├── event-stack.ts
│   │   │   └── monitoring-stack.ts
│   │   └── constructs/        # Reusable CDK constructs
│   ├── test/                  # CDK tests
│   └── cdk.json
├── backend/                   # Lambda functions (TypeScript)
│   ├── src/
│   │   ├── functions/         # Lambda handlers
│   │   ├── services/          # Business logic
│   │   ├── models/            # Data models
│   │   ├── middleware/        # Auth, logging, error handling
│   │   └── utils/             # Shared utilities
│   ├── test/
│   └── package.json
├── frontend/                  # Angular application
│   ├── src/
│   │   ├── app/
│   │   │   ├── core/          # Singleton services, guards
│   │   │   ├── shared/        # Shared components, pipes, directives
│   │   │   ├── features/      # Feature modules
│   │   │   │   ├── documents/
│   │   │   │   ├── search/
│   │   │   │   ├── admin/
│   │   │   │   └── ...
│   │   │   └── app.module.ts
│   │   ├── assets/
│   │   └── environments/
│   └── package.json
└── intent-statement.md        # Business requirements
```

## Key Architecture Patterns

### 1. Tenant Isolation Pattern
```typescript
// Every Lambda function extracts tenant_id from request
const tenantId = extractTenantIdFromSubdomain(event.headers.host);
// All DynamoDB queries include tenant_id partition key
const params = {
  TableName: 'viewdocs-config',
  Key: { PK: `TENANT#${tenantId}`, SK: `CONFIG#archive` }
};
```

### 2. Archive Abstraction Pattern
```typescript
// Factory pattern for different archive types
interface ArchiveClient {
  search(params): Promise<SearchResult>;
  getDocument(docId): Promise<Document>;
}

class IESCClient implements ArchiveClient { /* REST */ }
class IESClient implements ArchiveClient { /* SOAP */ }
class CMODClient implements ArchiveClient { /* SOAP */ }
```

### 3. Event-Driven Pattern
```typescript
// All document operations emit events to EventBridge
await eventBridge.putEvents({
  Entries: [{
    Source: 'viewdocs',
    DetailType: 'DocumentViewed',
    Detail: JSON.stringify({ tenantId, userId, documentId })
  }]
});
// EventBridge rule forwards to FRS Proxy → HUB
```

### 4. Bulk Download Pattern
```typescript
// Step Functions orchestration
{
  "StartAt": "ValidateRequest",
  "States": {
    "ValidateRequest": { /* Check ACLs */ },
    "FanOutDocuments": { /* Map over document IDs */ },
    "FetchDocument": { /* Lambda per document, concurrency=1 */ },
    "AggregateToS3": { /* Zip documents */ },
    "NotifyUser": { /* Email via IDM Email Service */ }
  }
}
```

## DynamoDB Table Design

### Single-Table Design with GSIs

**Main Table**: `viewdocs-data` (Global Table)

#### Access Patterns:
1. Get tenant configuration
2. Get user's role-to-ACL mapping
3. Get folder ACLs
4. Query audit logs by tenant + time range
5. Query comments by document
6. Get bulk download job status

#### Key Schema:
```
PK (Partition Key)         SK (Sort Key)                    Entity Type
-----------------------------------------------------------------------------------
TENANT#<tenantId>          CONFIG#archive                   Archive config
TENANT#<tenantId>          ROLE#<roleId>#ACL                Role-to-ACL mapping
TENANT#<tenantId>          FOLDER#<folderId>#ACL            Folder ACL
TENANT#<tenantId>          AUDIT#<timestamp>#<eventId>      Audit event
TENANT#<tenantId>          DOWNLOAD#<jobId>                 Bulk download job
DOC#<docId>                COMMENT#<timestamp>#<commentId>  Document comment
```

#### GSIs:
- **GSI1**: For querying documents by tenant (PK=TENANT#<tenantId>, SK=DOC#<docId>)
- **GSI2**: For user activity queries (PK=USER#<userId>, SK=AUDIT#<timestamp>)

## Security Guidelines

### Authentication Flow
1. User accesses `https://<tenant>.viewdocs.example.com`
2. CloudFront → S3 Angular app loads
3. Angular initiates Cognito-hosted UI login
4. Cognito redirects to appropriate IdP (IDM SAML or external SAML)
5. After SAML assertion, Cognito issues JWT tokens
6. Frontend includes JWT in Authorization header for API calls
7. API Gateway validates JWT with Cognito authorizer

### Authorization Flow
1. Lambda extracts `tenantId` from subdomain + `userId` from JWT
2. Query DynamoDB for user's roles (from IdP claim mapped to Viewdocs roles)
3. For document operation, check folder ACLs against user roles
4. If authorized, proceed; else return 403

### Secrets Management
- **Never hardcode**: Archive endpoints, API keys, credentials
- **Use AWS Secrets Manager**: Store per-tenant archive credentials
- **Rotation**: Enable automatic rotation for credentials
- **Access**: Lambda execution role with least-privilege access to secrets

## Testing Strategy

### Unit Tests
- **Coverage**: Minimum 80% for backend services
- **Mocking**: Mock DynamoDB, archive clients, EventBridge
- **Framework**: Jest

### Integration Tests
- **Scope**: Test Lambda + DynamoDB + SQS interactions
- **Environment**: Dedicated test DynamoDB tables
- **Cleanup**: Tear down test data after each run

### E2E Tests
- **Scope**: Frontend → API Gateway → Lambda → DynamoDB
- **Framework**: Cypress or Playwright
- **Environment**: UAT environment with test tenants

### Load Tests
- **Tool**: Artillery or Locust
- **Scenarios**: 500 concurrent users, document search/view/download
- **Metrics**: p95/p99 latency, error rate, Lambda throttles

## Deployment Strategy

### Environments
- **Dev**: Rapid iteration, auto-deploy on commit to `develop` branch
- **UAT**: Stable for testing, manual approval required
- **Prod**: Blue-green deployment with canary tenant rollout

### Blue-Green Deployment for Multi-Tenant
1. Deploy new version to "green" API Gateway stage
2. Select 1-2 canary tenants, route via DNS to green stage
3. Monitor for 24-48 hours (CloudWatch alarms)
4. Gradual rollout: 10% → 25% → 50% → 100% of tenants
5. If issues, instant rollback by reverting DNS/API Gateway stage

### Rollback Procedure
```bash
# Immediate rollback via API Gateway stage swap
aws apigateway update-stage --rest-api-id <api-id> --stage-name prod --patch-operations op=replace,path=/deploymentId,value=<previous-deployment-id>

# Or rollback CDK deployment
cdk deploy --all --context env=prod --rollback
```

## Monitoring & Alerting

### Key Metrics to Monitor
- **API Latency**: p95/p99 response times per endpoint
- **Error Rate**: 4xx/5xx errors per tenant
- **Lambda Duration**: Near timeout warnings
- **DynamoDB Throttles**: Read/write capacity exceeded
- **Archive Failures**: IESC/IES/CMOD API errors
- **Bulk Download Queue**: SQS queue depth, age of oldest message

### CloudWatch Alarms
```typescript
// Example: Lambda error rate > 5%
new cloudwatch.Alarm(this, 'HighErrorRate', {
  metric: lambdaFunction.metricErrors(),
  threshold: 5,
  evaluationPeriods: 2,
  datapointsToAlarm: 2,
  alarmActions: [snsTopic]
});
```

### X-Ray Tracing
- Enable on all Lambda functions
- Trace archive API calls to identify slow integrations
- Correlate errors across services

## Cost Optimization

### Lambda
- Right-size memory (start at 512MB, tune based on CloudWatch metrics)
- Use Lambda Insights for memory/CPU utilization
- Reserved concurrency only for critical functions

### DynamoDB
- On-demand pricing for dev/UAT (unpredictable load)
- Provisioned capacity for prod (predictable, cheaper at scale)
- Enable DynamoDB auto-scaling for provisioned mode
- TTL for audit logs (automatic deletion)

### S3
- Lifecycle policies: Move bulk download files to Glacier after 7 days, delete after 30 days
- Intelligent-Tiering for infrequently accessed documents

### CloudFront
- Optimize cache hit ratio (longer TTLs for static assets)
- Enable compression

### Direct Connect
- Shared with other FBDMS systems to amortize cost

## Disaster Recovery

### RPO: 2 hours | RTO: 24 hours (Active-Passive)

#### Backup Strategy
- **DynamoDB Global Tables**: Continuous replication to ap-southeast-4
- **S3 Cross-Region Replication**: Bulk download buckets to DR region
- **Secrets Manager**: Replicated to DR region
- **CloudFront**: Multi-origin failover (automatic)

#### Failover Procedure
1. Detect primary region failure (Route 53 health checks)
2. Route 53 automatically fails over to DR region (ap-southeast-4)
3. Verify DynamoDB Global Tables in DR region are healthy
4. Scale up Lambda concurrency in DR region if needed
5. Monitor for 24 hours, then fail back to primary region

## Common Pitfalls to Avoid

1. **Lambda Cold Starts**: Use provisioned concurrency for latency-sensitive functions
2. **DynamoDB Hot Partitions**: Design partition keys with high cardinality (tenant_id + random suffix)
3. **Timeout Cascades**: Set Lambda timeout < API Gateway timeout (29s max)
4. **CORS Issues**: Configure API Gateway CORS properly for Angular app
5. **Large Lambda Packages**: Use Lambda Layers for shared dependencies (AWS SDK, utilities)
6. **Hardcoded Tenant IDs**: Always extract dynamically from request context
7. **Missing Authorization Checks**: Every Lambda must validate tenant + user access
8. **Unencrypted Secrets**: Use Secrets Manager, never environment variables for sensitive data

## References

- **AWS Well-Architected Framework**: https://aws.amazon.com/architecture/well-architected/
- **AWS Serverless Multi-Tenancy**: https://aws.amazon.com/solutions/implementations/saas-identity-cognito/
- **DynamoDB Best Practices**: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html
- **TOGAF**: https://www.opengroup.org/togaf
- **C4 Model**: https://c4model.com/

## Decision Log

See [docs/architecture/10-decision-log.md](docs/architecture/10-decision-log.md) for Architecture Decision Records (ADRs).

## Contact & Support

- **Project Team**: FBDMS ECM Team
- **Architect**: [TBD]
- **Tech Lead**: [TBD]
