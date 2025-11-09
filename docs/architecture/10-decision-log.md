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

---

**Document Control**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-01-09 | Architecture Team | Initial ADRs for core decisions |
