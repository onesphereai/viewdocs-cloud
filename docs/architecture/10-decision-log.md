# Architecture Decision Records (ADRs)

**Document Version:** 1.0
**Last Updated:** 2025-11-09
**Status:** Draft

---

## ADR Template

```markdown
# ADR-XXX: [Title]

**Status:** Proposed | Accepted | Deprecated | Superseded
**Date:** YYYY-MM-DD
**Deciders:** [List of people involved]
**Context:** What is the issue we're trying to solve?
**Decision:** What did we decide?
**Consequences:** What are the positive and negative outcomes?
**Alternatives Considered:** What other options did we evaluate?
```

---

## ADR-001: Multi-Tenancy Model - Pool vs Silo

**Status:** Accepted
**Date:** 2025-01-09
**Deciders:** Architecture Team, Platform Team

### Context

Viewdocs needs to support 5-500 tenants with varying sizes (10-1000 users each). We need to choose between:
- **Silo Model**: Dedicated AWS resources (Lambda, DynamoDB, API Gateway) per tenant
- **Pool Model**: Shared AWS resources with logical isolation via tenant_id
- **Hybrid Model**: Premium tenants get silo, standard tenants share pool

### Decision

**Adopt Pool Model** with logical isolation via `tenant_id` partitioning in DynamoDB and authorization checks in every Lambda function.

### Rationale

1. **Cost Efficiency**: At 500 tenants, silo model would require 500 × (API Gateway + Lambda + DynamoDB) = prohibitive cost and operational overhead
2. **Operational Simplicity**: Single deployment pipeline, single CloudWatch dashboard, single set of IAM roles
3. **AWS Best Practices**: AWS SaaS Factory recommendations favor pool model for this scale
4. **Proven Pattern**: DynamoDB single-table design with partition key isolation is battle-tested

### Consequences

**Positive:**
- Lower cost ($1,300/month vs $50,000/month for 500-tenant silo)
- Faster tenant onboarding (config change vs stack deployment)
- Centralized monitoring and logging
- Easier version upgrades (single deployment)

**Negative:**
- Requires rigorous tenant isolation in code (every query must include `tenant_id`)
- Risk of noisy neighbor (mitigated with Lambda concurrency limits, DynamoDB auto-scaling)
- More complex authorization logic vs silo

### Alternatives Considered

1. **Full Silo**: Too expensive at scale, complex operations
2. **Hybrid (Silo for premium, Pool for standard)**: Operational complexity of managing two deployment models
3. **Account-per-Tenant**: AWS account limits (default 20, can request increase), cross-account complexity

---

## ADR-002: Authentication - Cognito vs Custom JWT

**Status:** Accepted
**Date:** 2025-01-09
**Deciders:** Architecture Team, Security Team

### Context

Need to support:
- SAML 2.0 federation with IDM (internal IdP)
- SAML 2.0 federation with customer IdPs (external)
- Multi-factor authentication (MFA) managed by IdP
- Session management with token refresh

### Decision

**Use AWS Cognito User Pools** with SAML federation for both IDM and external IdPs.

### Rationale

1. **Managed Service**: No need to build custom JWT issuance, token validation, session storage
2. **SAML 2.0 Support**: Native support for multiple SAML IdPs, supports IdP-initiated and SP-initiated flows
3. **API Gateway Integration**: Cognito authorizer validates JWTs automatically
4. **MFA**: Delegated to IdP (IDM or customer IdP)
5. **Security**: AWS-managed key rotation, token encryption

### Consequences

**Positive:**
- Reduced development time (no custom auth service)
- Automatic JWT validation in API Gateway (no Lambda authorizer needed)
- Built-in token refresh logic
- Cognito Hosted UI as fallback (customizable per tenant)

**Negative:**
- Cognito pricing ($0.0055/MAU beyond 50K) - mitigated by low MAU initially
- Less control over token claims (limited to 2KB) - acceptable for our use case
- Vendor lock-in to AWS Cognito - acceptable given full AWS stack

### Alternatives Considered

1. **Custom Auth0/Okta**: Additional SaaS cost, more integration points
2. **Custom JWT Service**: Significant development effort, security risks
3. **Direct SAML Integration**: No session management, would need to build token store

---

## ADR-003: Database - DynamoDB vs RDS Aurora Serverless

**Status:** Accepted
**Date:** 2025-01-09
**Deciders:** Architecture Team, Data Team

### Context

Need to store:
- Tenant configurations (500 tenants × 2KB = 1MB)
- ACLs (50K folder ACLs × 1KB = 50MB)
- Audit logs (25M events × 0.8KB = 20GB with 6-month retention)
- Comments (1M comments × 0.5KB = 500MB)

Requirements:
- Multi-region replication for DR (ap-southeast-2 → ap-southeast-4)
- Low latency (<10ms for authorization checks)
- Serverless (no server management)
- TTL for automatic audit log deletion

### Decision

**Use DynamoDB with Global Tables** for multi-region replication and single-table design.

### Rationale

1. **Serverless**: Zero server management, auto-scaling built-in
2. **Multi-Region**: Global Tables provide active-active replication (1-second replication lag typical)
3. **Performance**: Single-digit millisecond latency, predictable at scale
4. **TTL**: Native support for automatic item deletion (audit logs)
5. **Cost**: Provisioned capacity cheaper than on-demand for predictable load

### Consequences

**Positive:**
- No database administration overhead
- Automatic multi-region replication (RPO < 1 minute)
- TTL eliminates need for cleanup jobs
- Single-table design reduces query complexity

**Negative:**
- NoSQL learning curve (requires careful access pattern design upfront)
- Limited query flexibility vs SQL (mitigated with GSIs)
- DynamoDB transactions limited to 25 items (not a blocker for our use cases)

### Alternatives Considered

1. **RDS Aurora Serverless v2**: More expensive, requires read replica setup for DR, SQL overkill for our access patterns
2. **DocumentDB**: MongoDB-compatible, but no Global Tables equivalent, more expensive
3. **ElastiCache + RDS**: Complex architecture, dual data stores to manage

---

## ADR-004: Archive Integration - Direct Sync vs Queue-Based Async

**Status:** Accepted
**Date:** 2025-01-09
**Deciders:** Architecture Team, Integration Team

### Context

Need to integrate with three archive systems:
- IESC (REST API, AWS-hosted, <100ms latency)
- IES (SOAP API, on-premise via Direct Connect, <200ms latency)
- CMOD (SOAP API, on-premise via Direct Connect, <300ms latency)

Use cases:
- **Document View/Search**: User expects <2s response time
- **Bulk Download**: Up to 500 documents, 5GB total, user willing to wait (async)

### Decision

**Hybrid approach**:
- **Synchronous** for document view/search: Lambda → Archive API (with 29s timeout, 3 retries)
- **Asynchronous** for bulk download: Step Functions → SQS → Lambda (per document, concurrency=1)

### Rationale

1. **User Experience**: Real-time search/view requires low latency
2. **Resilience**: Synchronous calls with exponential backoff retry for transient failures
3. **Bulk Downloads**: Long-running (15min+ for 500 docs), Step Functions ideal for orchestration
4. **Lambda Limits**: 15min max timeout, use concurrency=1 to avoid overwhelming archive APIs

### Consequences

**Positive:**
- Optimal user experience (fast search, async bulk download with email notification)
- Step Functions visual workflow for debugging bulk downloads
- SQS dead-letter queue for failed document fetches

**Negative:**
- Synchronous calls can timeout if archive slow (mitigated with 29s timeout, retry logic)
- Step Functions adds cost ($0.025/1K transitions) - minimal given low volume

### Alternatives Considered

1. **All Async (Queue-Based)**: Slower user experience for search/view
2. **All Sync**: Lambda timeout issues for bulk downloads
3. **Cache Archive Data in DynamoDB**: Stale data risk, complex sync logic

---

## ADR-005: Event Processing - EventBridge vs SQS/SNS

**Status:** Accepted
**Date:** 2025-01-09
**Deciders:** Architecture Team

### Context

Need to publish document events (view, download, comment) to:
1. HUB (on-premise event aggregator via FRS Proxy)
2. Future: Analytics pipeline (S3 + Athena)
3. Future: Real-time dashboards

### Decision

**Use EventBridge** as central event bus with rules to route events to FRS Proxy Lambda and future targets.

### Rationale

1. **Schema Registry**: Define and version event schemas
2. **Content-Based Filtering**: Route events based on event type, tenant, etc.
3. **Multiple Targets**: Easily add S3, Lambda, Step Functions targets without code changes
4. **Audit Trail**: Built-in event history

### Consequences

**Positive:**
- Future-proof for analytics, real-time dashboards
- Decoupled event producers (Document Service) from consumers (Event Service)
- No code changes to add new event targets

**Negative:**
- EventBridge costs ($1/million events) - minimal given event volume
- 5MB event size limit (not a concern for our metadata-only events)

### Alternatives Considered

1. **Direct Lambda Invocation**: Tight coupling, no ability to add targets without code changes
2. **SNS + SQS**: More components to manage, no schema registry
3. **Kinesis Data Streams**: Overkill for our event volume, more expensive

---

## ADR-006: Frontend Hosting - S3+CloudFront vs Amplify

**Status:** Accepted
**Date:** 2025-01-09
**Deciders:** Architecture Team, Frontend Team

### Context

Need to host Angular single-page application (SPA) with:
- Global CDN distribution
- Custom domain (viewdocs.example.com)
- SSL/TLS termination
- Multi-tenant subdomain routing (tenant1.viewdocs.example.com)

### Decision

**Use S3 for static hosting + CloudFront** for CDN distribution.

### Rationale

1. **Cost**: S3 ($0.025/GB storage) + CloudFront ($0.14/GB transfer) cheaper than Amplify Hosting ($0.15/GB transfer + $0.01/build minute)
2. **Control**: Full control over cache policies, WAF rules, custom headers
3. **Multi-Tenant Routing**: CloudFront behaviors can route by subdomain
4. **Maturity**: S3+CloudFront battle-tested, Amplify relatively newer

### Consequences

**Positive:**
- Lower cost at scale
- Fine-grained cache control (1-year TTL for versioned assets)
- Integrate with WAF for DDoS protection

**Negative:**
- Manual deployment vs Amplify's automatic CI/CD (mitigated with CDK Pipelines)
- No built-in preview environments (mitigated with separate CloudFront distributions for dev/uat/prod)

### Alternatives Considered

1. **AWS Amplify Hosting**: Higher cost, less control
2. **API Gateway + Lambda**: Can serve SPA, but higher latency than CloudFront, more expensive
3. **Elastic Beanstalk**: Overkill for static SPA

---

## ADR-007: Infrastructure as Code - CDK vs Terraform vs CloudFormation

**Status:** Accepted
**Date:** 2025-01-09
**Deciders:** Architecture Team, DevOps Team

### Context

Need to provision:
- 50+ AWS resources (Lambda, DynamoDB, API Gateway, Cognito, S3, CloudFront, etc.)
- Multi-environment (dev, uat, prod)
- Multi-region (ap-southeast-2, ap-southeast-4)

### Decision

**Use AWS CDK (TypeScript)** for infrastructure as code.

### Rationale

1. **Language Consistency**: TypeScript for backend Lambda + CDK = single language
2. **Abstraction**: CDK constructs provide higher-level abstractions vs raw CloudFormation
3. **Type Safety**: Compile-time validation of resource properties
4. **AWS Native**: First-class support for new AWS services
5. **CDK Pipelines**: Self-mutating CI/CD pipelines

### Consequences

**Positive:**
- Faster development (less YAML, more code)
- Reusable constructs (e.g., TenantStack construct)
- CDK synth generates CloudFormation for audit
- Strong team TypeScript skills

**Negative:**
- CDK adds layer of abstraction (debugging may require looking at synthesized CloudFormation)
- CDK version upgrades can introduce breaking changes (mitigated with semver pinning)

### Alternatives Considered

1. **Terraform**: Multi-cloud portability not needed (committed to AWS), HCL learning curve
2. **CloudFormation (raw)**: Too verbose (1000+ lines of YAML), limited abstraction
3. **Serverless Framework**: Focused on Lambda, less support for other AWS services

---

## ADR-008: Lambda Runtime - Node.js vs Python vs Go

**Status:** Accepted
**Date:** 2025-01-09
**Deciders:** Architecture Team, Development Team

### Context

Need to implement Lambda functions for:
- Document Service, Search Service, Admin Service (business logic)
- Event Service (lightweight event forwarding)
- Archive clients (SOAP + REST integrations)

### Decision

**Use Node.js 20.x with TypeScript** for all Lambda functions.

### Rationale

1. **Language Consistency**: TypeScript for frontend (Angular) + backend (Lambda) + IaC (CDK)
2. **Ecosystem**: Rich npm ecosystem for SOAP clients, HTTP clients, AWS SDK
3. **Cold Start**: Node.js cold starts (<200ms) faster than Java, comparable to Python
4. **Team Skills**: Strong TypeScript skills in team

### Consequences

**Positive:**
- Single language across stack (hiring, knowledge sharing)
- TypeScript type safety reduces runtime errors
- esbuild for fast bundling, tree-shaking

**Negative:**
- Node.js single-threaded (not a blocker for I/O-bound workloads)
- Larger bundle size than Python (mitigated with Lambda Layers for aws-sdk)

### Alternatives Considered

1. **Python**: Popular for Lambda, but splits team between TypeScript (frontend) and Python (backend)
2. **Go**: Fastest cold starts, but learning curve, limited team experience
3. **Java**: JVM warm-up overhead, slow cold starts (1-3s)

---

## ADR-009: API Design - REST vs GraphQL

**Status:** Accepted
**Date:** 2025-01-09
**Deciders:** Architecture Team, Frontend Team

### Context

Frontend needs to:
- Fetch document metadata, search results, comments
- Upload comments, initiate bulk downloads
- Manage tenant configurations

### Decision

**Use REST API** with resource-based endpoints (e.g., `/documents/{id}`, `/search`).

### Rationale

1. **Simplicity**: REST well-understood by team, standard HTTP verbs
2. **API Gateway Integration**: Native REST API support in API Gateway
3. **Caching**: HTTP caching (ETag, Cache-Control) works out-of-box with CloudFront
4. **Tooling**: OpenAPI/Swagger for API docs, Postman for testing

### Consequences

**Positive:**
- Standard REST patterns (CRUD)
- HTTP status codes for error handling
- CloudFront caching for GET requests

**Negative:**
- Over-fetching (fetch entire document metadata when only need title)
- Multiple roundtrips for related resources (mitigated with compound endpoints like `/documents/{id}/comments`)

### Alternatives Considered

1. **GraphQL (AppSync)**: Flexible querying, but adds complexity, team unfamiliar
2. **gRPC**: High performance, but limited browser support, requires HTTP/2

---

## ADR-010: Deployment Strategy - Blue-Green vs Canary vs Rolling

**Status:** Accepted
**Date:** 2025-01-09
**Deciders:** Architecture Team, DevOps Team

### Context

Need to deploy updates to multi-tenant production environment with:
- Zero downtime
- Ability to rollback within minutes
- Gradual rollout to minimize blast radius

### Decision

**Blue-Green deployment with canary tenant rollout**:
1. Deploy new version to "green" API Gateway stage
2. Route 1-2 canary tenants to green stage (via Route 53 subdomain)
3. Monitor for 24-48 hours
4. Gradual rollout: 10% → 25% → 50% → 100% of tenants
5. Rollback via API Gateway stage swap if issues detected

### Rationale

1. **Zero Downtime**: Traffic switches at DNS/API Gateway level
2. **Fast Rollback**: Revert DNS or API Gateway stage (< 1 minute)
3. **Risk Mitigation**: Canary tenants detect issues before full rollout
4. **Gradual Rollout**: CloudWatch alarms halt rollout if error rate spikes

### Consequences

**Positive:**
- Minimal risk to production
- Instant rollback capability
- Aligns with AWS Well-Architected operational excellence pillar

**Negative:**
- Requires duplicate Lambda functions during deployment (higher cost for 1-2 hours)
- DNS propagation delay (5-60 minutes depending on TTL)

### Alternatives Considered

1. **Rolling Deployment**: Higher risk (gradual rollout of broken code affects all tenants)
2. **Canary Deployment (Lambda Weighted Aliases)**: Complex to implement per-tenant routing
3. **Recreate Deployment**: Downtime during deployment

---

## ADR-011: Observability - CloudWatch vs ELK vs Datadog

**Status:** Accepted
**Date:** 2025-01-09
**Deciders:** Architecture Team, Operations Team

### Context

Need to:
- Centralize logs from Lambda, API Gateway, CloudFront
- Monitor metrics (latency, error rate, throughput)
- Trace distributed requests across services
- Alert on anomalies

### Decision

**Use AWS-native observability stack**:
- **CloudWatch Logs** for centralized logging
- **CloudWatch Metrics** for custom metrics
- **CloudWatch Alarms** for alerting
- **X-Ray** for distributed tracing

### Rationale

1. **Native Integration**: Lambda, API Gateway, DynamoDB automatically publish to CloudWatch
2. **Cost**: CloudWatch included in AWS bill, no additional SaaS cost
3. **Data Sovereignty**: Logs remain in Australia (compliance requirement)
4. **X-Ray**: Built-in service map, latency distribution

### Consequences

**Positive:**
- No third-party SaaS vendor contracts
- Data residency compliance
- Unified billing (AWS)

**Negative:**
- CloudWatch Insights query language learning curve vs SQL (ELK)
- Log retention costs ($0.57/GB/month) - mitigated with log filtering, sampling
- Less feature-rich dashboards than Datadog

### Alternatives Considered

1. **ELK Stack (self-hosted)**: EC2 costs, operational overhead
2. **Datadog**: $15-31/host/month, excellent UX but data leaves Australia (compliance risk)
3. **Splunk**: Enterprise pricing ($2000+/GB/year), overkill for our scale

---

## ADR-012: Lambda Deployment - VPC vs Non-VPC

**Status:** Accepted
**Date:** 2025-11-09
**Deciders:** Architecture Team, Network Team, Security Team

### Context

Lambda functions need to:
- Connect to AWS managed services (DynamoDB, S3, Secrets Manager, Cognito)
- Connect to on-premise systems (IES, CMOD, FRS) via Direct Connect (10Gbps)
- Meet security and compliance requirements (Australian Privacy Act, data residency)

We need to choose between:
- **Option 1**: Lambda WITHOUT VPC (public IPs, TLS + IPsec encryption)
- **Option 2**: Lambda IN VPC (private IPs, NAT Gateway, VPC Endpoints)

### Decision

**Deploy Lambda functions WITHOUT VPC** (Option 1), using public IP connectivity with TLS 1.2+ encryption and IPsec VPN over Direct Connect.

### Rationale

1. **Cost Savings**: Avoid NAT Gateway costs ($135/month for 3 AZs) and VPC Endpoint costs (~$21/month)
   - Total savings: **$156/month ($1,872/year)**

2. **Performance**: No Lambda cold start penalty
   - VPC Lambda adds ~2 seconds to cold starts (ENI creation/attachment)
   - Non-VPC Lambda starts in ~200-500ms

3. **Security is Equivalent**:
   - **Encryption in Transit**: TLS 1.2+ (HTTPS) + IPsec VPN over Direct Connect
   - **Encryption at Rest**: KMS for DynamoDB, S3, Secrets Manager
   - **Authentication**: Cognito JWT validation at API Gateway
   - **Authorization**: IAM execution roles with least privilege
   - **Data Residency**: All data in ap-southeast-2 / ap-southeast-4 (region selection, not VPC)

4. **AWS Managed Services Don't Require VPC**:
   - DynamoDB, S3, Secrets Manager, Cognito, API Gateway are accessible via public endpoints
   - AWS IAM provides access control (no network segmentation needed)
   - Multi-tenancy security is **logical isolation** (tenant_id), not network isolation

5. **Direct Connect Supports Public IPs**:
   - Confirmed with Network Team: Direct Connect can route to AWS public IPs
   - Traffic encrypted with IPsec VPN tunnel
   - No requirement for private IP ranges from on-premise side

6. **Simpler Architecture**:
   - No subnets, route tables, security groups, NAT Gateways to manage
   - Easier debugging (no VPC flow logs, no NAT troubleshooting)
   - Faster deployments (no VPC resource creation delays)

### Consequences

**Positive:**
- **$1,872/year cost savings** (NAT + VPC Endpoints)
- **Faster Lambda cold starts** (~2s faster)
- **Simpler operations** (no VPC management)
- **Easier troubleshooting** (no NAT Gateway failures, no ENI limits)
- **Faster deployments** (no VPC dependencies)

**Negative:**
- Lambda uses **public IPs** (mitigated: traffic still encrypted via TLS + IPsec)
- Cannot access resources requiring **private connectivity** (not applicable - no RDS, ElastiCache, or private IES/CMOD endpoints)
- If on-premise network policy changes to require private IPs, migration to VPC would be needed (rare scenario)

### Alternatives Considered

1. **Lambda in VPC with NAT Gateway**:
   - **Pros**: Private IP connectivity, perceived as "more secure"
   - **Cons**: $156/month extra cost, slower cold starts, operational complexity
   - **Verdict**: Not needed - security is equivalent with TLS + IPsec

2. **Lambda in VPC with VPC Endpoints (no NAT)**:
   - **Pros**: Private connectivity to DynamoDB/S3, no NAT cost
   - **Cons**: Still requires NAT for on-premise connectivity (IES/CMOD/FRS), VPC endpoint costs, cold start penalty
   - **Verdict**: Doesn't solve Direct Connect connectivity, still incurs costs

3. **Hybrid (some Lambdas in VPC, some not)**:
   - **Pros**: Only put archive-integration Lambdas in VPC
   - **Cons**: Operational complexity, inconsistent architecture
   - **Verdict**: Unnecessary complexity for no security gain

### Implementation Notes

- **Direct Connect Configuration**: Public VIF (Virtual Interface) routing to AWS public IP ranges
- **Encryption**: TLS 1.2+ for all HTTPS traffic, IPsec VPN tunnel for Direct Connect
- **IAM Policies**: Restrict Lambda execution roles to specific DynamoDB tables, S3 buckets, Secrets
- **Security Groups**: Not applicable (no VPC)
- **Monitoring**: CloudWatch Logs, X-Ray tracing (same as VPC Lambda)

### Re-evaluation Criteria

Re-evaluate this decision if:
1. On-premise network team mandates private IP connectivity (policy change)
2. Compliance audit requires network-level isolation (unlikely for serverless)
3. Need to access VPC-only resources (RDS, ElastiCache) - not in current architecture

---

## ADR-013: MailRoom Integration - Backend-Only Platform with Viewdocs UI Wrapper

**Status:** Accepted
**Date:** 2025-11-10
**Deciders:** Architecture Team, Product Team

### Context

We are building two new platforms simultaneously:
- **Viewdocs**: Document management and viewing platform
- **MailRoom**: Mail/correspondence management platform (NEW)

**Requirements**:
1. MailRoom UI will be part of the Viewdocs UI (unified user experience)
2. MailRoom backend should remain independent and reusable
3. Other clients (future mobile apps, API consumers) should be able to consume MailRoom services
4. Both platforms should be able to evolve independently
5. Single authentication/authorization model (Cognito + Viewdocs ACLs)

**Decision Needed**: How should MailRoom be architected in relation to Viewdocs?

**Options**:
- **Option 1**: MailRoom as backend-only platform with Viewdocs wrapper services
- **Option 2**: MailRoom as full-stack platform with separate UI
- **Option 3**: MailRoom fully integrated into Viewdocs codebase

### Decision

**Adopt Option 1: MailRoom as Backend-Only Platform with Viewdocs Wrapper Services**

**Architecture**:
```
┌───────────────────────────────────────────┐
│       Viewdocs UI (Angular 17+)           │
│  ┌─────────────────────────────────────┐  │
│  │ Viewdocs Components                 │  │
│  │  - Document Viewer                  │  │
│  │  - Search                           │  │
│  │  - Comments                         │  │
│  └─────────────────────────────────────┘  │
│  ┌─────────────────────────────────────┐  │
│  │ MailRoom UI Components (integrated) │  │
│  │  - Mail List                        │  │
│  │  - Mail Viewer                      │  │
│  │  - Mail Actions (archive, forward)  │  │
│  └─────────────────────────────────────┘  │
└───────────────┬───────────────────────────┘
                │ Single API Gateway
    ┌───────────┼────────────────┐
    │           │                │
┌───▼───────┐ ┌─▼──────────────┐ ┌─▼────────┐
│ Document  │ │ MailRoom       │ │ Search   │
│ Service   │ │ Wrapper Service│ │ Service  │
│ (Lambda)  │ │ (Lambda) ←NEW  │ │ (Lambda) │
└───────────┘ └────────┬───────┘ └──────────┘
                       │
              ┌────────▼──────────────────┐
              │ MailRoom Backend API      │
              │ (Independent Microservice)│
              │  - Lambda/ECS             │
              │  - Own database           │
              │  - Reusable by others     │
              └───────────────────────────┘
```

### Rationale

1. **Unified User Experience**:
   - Users see MailRoom as part of Viewdocs (single Angular app)
   - Single login, single navigation, consistent UI/UX
   - No context switching between applications

2. **MailRoom Independence**:
   - MailRoom backend can be consumed by other clients (future mobile app, third-party integrations)
   - MailRoom can be deployed/scaled independently from Viewdocs
   - MailRoom team can work independently on backend features

3. **Separation of Concerns**:
   - **Viewdocs** owns: Authentication, Authorization, UI, Tenant Management
   - **MailRoom** owns: Mail processing business logic, Mail storage, Mail workflows
   - **Wrapper** owns: Protocol translation, ACL enforcement, Audit logging

4. **Backend for Frontend (BFF) Pattern**:
   - Wrapper provides Viewdocs-specific API optimized for UI needs
   - Hides MailRoom backend complexity
   - Allows MailRoom backend API to evolve without breaking Viewdocs UI

5. **Technology Consistency**:
   - Both platforms use same tech stack (TypeScript, Lambda, DynamoDB)
   - Shared CDK infrastructure code
   - Same CI/CD pipeline (Bitbucket + Jenkins)
   - Same monitoring (CloudWatch + X-Ray)

6. **Cost Efficiency**:
   - Shared infrastructure (API Gateway, CloudFront, Cognito)
   - No duplicate authentication/authorization services
   - Single deployment pipeline

### Consequences

**Positive:**
- ✅ **Unified UX** - Users perceive single platform
- ✅ **MailRoom reusability** - Can be consumed by other clients
- ✅ **Independent evolution** - Teams can work in parallel
- ✅ **Clear boundaries** - Well-defined service contracts
- ✅ **Shared auth** - Single Cognito + ACL model
- ✅ **Consistent tech stack** - TypeScript, Lambda, DynamoDB
- ✅ **Simplified deployment** - Single Viewdocs UI deployment
- ✅ **Future-proof** - Easy to extract MailRoom if needed

**Negative:**
- ❌ **Wrapper complexity** - Additional translation layer
- ❌ **Coordination required** - API contract between wrapper and MailRoom
- ❌ **Slight latency** - Extra hop through wrapper (~50-100ms)

**Mitigations:**
- Wrapper is thin translation layer, minimal logic
- Use OpenAPI/Swagger for contract definition
- Async pattern for heavy operations (no latency impact)

### Implementation Design

#### MailRoom Wrapper Service Responsibilities:

1. **Authentication**: Inherit from API Gateway (Cognito JWT already validated)
2. **Authorization**: Check Viewdocs ACLs (tenant_id + user roles)
3. **Tenant Isolation**: Inject `tenant_id` into every MailRoom call
4. **Request Translation**: Map Viewdocs API format → MailRoom API format
5. **Response Translation**: Map MailRoom response → Viewdocs UI format
6. **Error Handling**: Translate MailRoom errors to Viewdocs error codes
7. **Audit Logging**: Log mail operations to Viewdocs audit table
8. **Circuit Breaker**: Handle MailRoom downtime gracefully

#### API Structure:

**Viewdocs MailRoom Wrapper API** (exposed to Angular UI):
```
# Mail Items
GET    /api/v1/{tenantId}/mailroom/items
POST   /api/v1/{tenantId}/mailroom/items/search
GET    /api/v1/{tenantId}/mailroom/items/{itemId}

# Mail Actions
POST   /api/v1/{tenantId}/mailroom/items/{itemId}/actions/archive
POST   /api/v1/{tenantId}/mailroom/items/{itemId}/actions/forward
POST   /api/v1/{tenantId}/mailroom/items/{itemId}/actions/annotate

# Bulk Operations (async)
POST   /api/v1/{tenantId}/mailroom/bulk-operations
GET    /api/v1/{tenantId}/mailroom/bulk-operations/{jobId}/status
```

**MailRoom Backend API** (internal, called by wrapper):
```
POST   https://mailroom-api.internal/v1/search
GET    https://mailroom-api.internal/v1/items/{itemId}
POST   https://mailroom-api.internal/v1/items/{itemId}/archive
POST   https://mailroom-api.internal/v1/items/{itemId}/forward
POST   https://mailroom-api.internal/v1/bulk-operations
```

#### Integration Patterns:

**Synchronous (Request-Response)**: For quick operations (<2s)
- Get mail items (list view)
- Search mail
- Get item details
- Simple actions (mark as read)

**Asynchronous (Event-Driven)**: For heavy operations (>2s)
- Bulk archive (100+ items)
- Bulk forwarding
- OCR processing
- Email generation

**Async Flow**:
```
Viewdocs Wrapper → SQS Queue → MailRoom Worker Lambda
MailRoom Worker → EventBridge (MailRoomJobCompleted event)
EventBridge → Viewdocs Notification Lambda → WebSocket/Email
```

#### Database Design:

**MailRoom owns its own data**:
- MailRoom has separate DynamoDB tables (or own database)
- Viewdocs does NOT query MailRoom tables directly
- All access via MailRoom API

**Viewdocs stores references**:
- Viewdocs audit table logs mail operations (metadata only)
- Viewdocs ACL table controls who can access MailRoom features

### Alternatives Considered

#### 1. **Full-Stack MailRoom with Separate UI (Option 2)**:

**Approach**: MailRoom has its own Angular app, separate deployment

**Pros**:
- Complete independence
- No wrapper needed

**Cons**:
- ❌ **Fragmented UX** - Users switch between apps
- ❌ **Duplicate auth** - Need separate login or SSO
- ❌ **Higher cost** - Duplicate CloudFront, API Gateway
- ❌ **Maintenance overhead** - Two Angular apps to maintain

**Verdict**: Not recommended - violates unified UX requirement

#### 2. **Fully Integrated MailRoom (Option 3)**:

**Approach**: Merge MailRoom code into Viewdocs monolith

**Pros**:
- Simplest architecture
- No integration complexity

**Cons**:
- ❌ **MailRoom NOT reusable** - Cannot be consumed by other clients
- ❌ **Tight coupling** - Hard to separate later
- ❌ **Deployment coupling** - Single deployment for both
- ❌ **Team boundaries blur** - Harder to parallelize work

**Verdict**: Not recommended - violates reusability requirement

### Technology Stack for MailRoom Backend

| Component | Technology | Rationale |
|-----------|------------|-----------|
| **Runtime** | Node.js 20.x Lambda | Consistent with Viewdocs |
| **Language** | TypeScript | Consistent with Viewdocs |
| **Database** | DynamoDB | Serverless, consistent with Viewdocs |
| **API** | REST (API Gateway) | Consistent with Viewdocs |
| **Queue** | SQS | For async operations |
| **Events** | EventBridge | For notifications |
| **Storage** | S3 | For mail attachments |
| **Secrets** | Secrets Manager | For external integrations |

### Deployment Strategy

**MailRoom Backend**:
- Deployed via same CDK infrastructure as Viewdocs
- Separate CDK stack: `MailRoomBackendStack`
- Same CI/CD pipeline (Bitbucket → Jenkins)
- Independent versioning (`mailroom-v1.0.0`)

**Viewdocs MailRoom Wrapper**:
- Part of Viewdocs CDK stack: `ApiStack`
- Deployed together with other Viewdocs services
- Shares API Gateway with Viewdocs endpoints

**Viewdocs UI (with MailRoom components)**:
- Single Angular app deployment
- MailRoom UI components in `/src/app/mailroom/` module
- Lazy-loaded for performance

### Re-evaluation Criteria

Re-evaluate this decision if:
1. MailRoom needs to be a standalone product (separate pricing, licensing)
2. Performance requirements exceed wrapper overhead (latency >200ms p95)
3. Other clients don't materialize within 12 months (MailRoom only used by Viewdocs)
4. Significant API contract friction between wrapper and MailRoom backend

### Related ADRs

- **ADR-001**: Pool Multi-Tenancy - MailRoom follows same tenant isolation model
- **ADR-002**: Cognito Auth - MailRoom uses same Cognito User Pool
- **ADR-003**: DynamoDB - MailRoom uses DynamoDB for data storage
- **ADR-004**: Sync/Async - Applies to MailRoom operations
- **ADR-005**: EventBridge - Used for MailRoom async workflows
- **ADR-012**: Non-VPC Lambda - MailRoom Lambda also without VPC

---

## Summary of Decisions

| ADR | Decision | Status |
|-----|----------|--------|
| ADR-001 | Pool Model Multi-Tenancy | Accepted |
| ADR-002 | AWS Cognito for Auth | Accepted |
| ADR-003 | DynamoDB with Global Tables | Accepted |
| ADR-004 | Hybrid Sync/Async Archive Integration | Accepted |
| ADR-005 | EventBridge for Event Processing | Accepted |
| ADR-006 | S3 + CloudFront for Frontend | Accepted |
| ADR-007 | AWS CDK (TypeScript) | Accepted |
| ADR-008 | Node.js + TypeScript for Lambda | Accepted |
| ADR-009 | REST API | Accepted |
| ADR-010 | Blue-Green with Canary Rollout | Accepted |
| ADR-011 | CloudWatch + X-Ray | Accepted |
| ADR-012 | Lambda WITHOUT VPC | Accepted |
| ADR-013 | MailRoom Backend-Only + Wrapper | Accepted |

---

**Document Control**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-01-09 | Architecture Team | Initial ADRs for core decisions |
