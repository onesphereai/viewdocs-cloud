# Viewdocs Cloud Architecture Documentation

Welcome to the comprehensive architecture documentation for Viewdocs Cloud, a multi-tenant, serverless document management system built on AWS.

---

## Document Index

### Core Architecture Documents

| Document | Status | Description |
|----------|--------|-------------|
| [00-architecture-overview.md](00-architecture-overview.md) | ✅ Complete | High-Level Solution Design (HLSD) - Executive summary, system context, design decisions, NFRs |
| [01-business-architecture.md](01-business-architecture.md) | ✅ Complete | Business context, stakeholder analysis, use cases, capabilities, business rules, ROI |
| [02-application-architecture.md](02-application-architecture.md) | ✅ Complete | Service definitions, API specifications, application flows, archive adapter design |
| [03-data-architecture.md](03-data-architecture.md) | ✅ Complete | DynamoDB schema design, access patterns, capacity planning, data retention |
| [04-technology-architecture.md](04-technology-architecture.md) | ✅ Complete | AWS services selection, technology stack, SDKs, tooling, development tools |
| [05-security-architecture.md](05-security-architecture.md) | ✅ Complete | Authentication, authorization, encryption, compliance, threat model, incident response |
| [06-deployment-architecture.md](06-deployment-architecture.md) | ✅ Complete | CI/CD pipeline, blue-green deployment, environment strategy, rollback procedures |
| [08-cost-architecture.md](08-cost-architecture.md) | ✅ Complete | Detailed cost breakdown, optimization strategies, cost allocation tags, ROI analysis |
| [10-decision-log.md](10-decision-log.md) | ✅ Complete | Architecture Decision Records (ADRs) for all major design decisions |

### Diagrams

| Diagram | Type | Status | Description |
|---------|------|--------|-------------|
| [context-diagram.md](diagrams/context-diagram.md) | C4 Level 1 | ✅ Complete | System context showing external users and systems |
| [container-diagram.md](diagrams/container-diagram.md) | C4 Level 2 | ✅ Complete | Container architecture with AWS services and data flows |
| [sequence-diagrams.md](diagrams/sequence-diagrams.md) | Flow | ✅ Complete | Authentication, document view, bulk download, search, admin, comment flows |
| [deployment-diagram.md](diagrams/deployment-diagram.md) | Infrastructure | ✅ Complete | Multi-region deployment topology with DR failover |

---

## Quick Start

### For New Team Members

1. **Start here**: [00-architecture-overview.md](00-architecture-overview.md)
   - Read the Executive Summary and Key Highlights
   - Review the High-Level Architecture diagrams
   - Understand the Core Design Decisions

2. **Understand the business**: [01-business-architecture.md](01-business-architecture.md)
   - Review use cases (UC-001: View Document, UC-002: Bulk Download, UC-003: Onboard Tenant)
   - Understand business rules and stakeholder needs

3. **Dive into technical details**:
   - **APIs**: [02-application-architecture.md](02-application-architecture.md) - REST endpoints, request/response formats
   - **Data**: [03-data-architecture.md](03-data-architecture.md) - DynamoDB table design, query patterns
   - **Decisions**: [10-decision-log.md](10-decision-log.md) - Why we chose AWS Cognito, DynamoDB, pool multi-tenancy, etc.

### For Developers

**Before writing code**, read:
1. [CLAUDE.md](../../CLAUDE.md) - Development guidelines, common commands, testing strategy
2. [02-application-architecture.md](02-application-architecture.md) - API contracts, service responsibilities
3. [03-data-architecture.md](03-data-architecture.md) - DynamoDB schema, access patterns

**Key patterns to follow**:
- **Tenant Isolation**: Every DynamoDB query must include `tenant_id` in partition key
- **Authorization**: Every Lambda must validate user ACLs before accessing resources
- **Error Handling**: Use retry logic with exponential backoff for archive API calls
- **Audit Logging**: Log all document operations to DynamoDB audit table

### For Architects

**Reviewing the architecture?** Focus on:
1. [00-architecture-overview.md](00-architecture-overview.md) - Section 4: Core Design Decisions
2. [10-decision-log.md](10-decision-log.md) - ADRs for justification of choices
3. [diagrams/container-diagram.md](diagrams/container-diagram.md) - Service interactions and data flows

**Key architectural drivers**:
- **Multi-Tenancy**: Pool model with logical isolation (cost-efficient at 500 tenants)
- **Hybrid Cloud**: Serverless in AWS + on-premise integrations (IESC, IES, CMOD, FRS, HUB)
- **Data Residency**: All data in Australia (compliance requirement)
- **Resilience**: Multi-region DR (RPO 2hr, RTO 24hr)

### For Operations

**Deploying and monitoring**:
1. [06-deployment-architecture.md](06-deployment-architecture.md) - CI/CD pipeline, blue-green deployment
2. [07-infrastructure-architecture.md](07-infrastructure-architecture.md) - Infrastructure provisioning with CDK
3. [CLAUDE.md](../../CLAUDE.md) - Common commands for deployment, monitoring

**Monitoring resources**:
- CloudWatch dashboards for API latency, Lambda errors, DynamoDB throttles
- X-Ray for distributed tracing across services
- EventBridge for real-time events to HUB

---

## Architecture Principles

### 1. Cloud-Native Serverless

**What**: Use AWS managed services (Lambda, DynamoDB, API Gateway, Cognito) to eliminate server management

**Why**: Reduce operational overhead, auto-scaling, pay-per-use pricing

**How**: No EC2 instances, no RDS servers, all compute is Lambda or Step Functions

### 2. Multi-Tenant Pool Model

**What**: Share infrastructure across all tenants with logical isolation via `tenant_id`

**Why**: Cost-efficient at scale (500 tenants), simpler operations (single deployment)

**How**: DynamoDB partition keys prefixed with `TENANT#<tenantId>`, authorization checks in every Lambda

### 3. Event-Driven Architecture

**What**: Decouple services using EventBridge, SQS, Step Functions

**Why**: Scalability, resilience, ability to add new event consumers without code changes

**How**: Document Service publishes events to EventBridge → routed to Event Service (HUB) and future analytics

### 4. Security by Design

**What**: Authenticate and authorize every request, encrypt all data, audit all operations

**Why**: Compliance (Australian Privacy Act), zero trust security model

**How**: Cognito JWT validation, DynamoDB ACL checks, KMS encryption, audit logs with 6-month retention

### 5. Immutable Infrastructure

**What**: All infrastructure defined as code (CDK), no manual changes in AWS console

**Why**: Reproducible deployments, version-controlled, disaster recovery

**How**: CDK stacks for all resources, CDK Pipelines for automated deployment

---

## Technology Stack Summary

| Layer | Technology | Justification |
|-------|------------|---------------|
| **Frontend** | Angular 17+ (TypeScript) | Modern SPA framework, strong typing, large ecosystem |
| **API** | AWS API Gateway (REST) | Managed service, JWT validation, throttling, caching |
| **Compute** | AWS Lambda (Node.js 20.x, TypeScript) | Serverless, auto-scaling, pay-per-invocation |
| **Authentication** | AWS Cognito (SAML 2.0) | Managed SAML federation, JWT issuance, MFA support |
| **Database** | DynamoDB Global Tables | Serverless NoSQL, multi-region replication, low latency |
| **Storage** | AWS S3 | Object storage for bulk downloads, static assets |
| **Secrets** | AWS Secrets Manager | Encrypted credentials, auto-rotation |
| **Orchestration** | AWS Step Functions | Visual workflows for bulk downloads |
| **Events** | AWS EventBridge | Schema registry, content-based routing |
| **Queue** | AWS SQS (FIFO) | Message queueing for bulk download jobs |
| **CDN** | AWS CloudFront | Global edge caching for static assets and API responses |
| **DNS** | AWS Route 53 | Multi-region failover, health checks |
| **Monitoring** | CloudWatch Logs + Metrics + X-Ray | Centralized logging, metrics, distributed tracing |
| **IaC** | AWS CDK (TypeScript) | Infrastructure as code, type-safe, reusable constructs |
| **CI/CD** | CDK Pipelines | Self-mutating pipelines, automated deployments |

---

## Key Metrics & SLAs

| Metric | Target | Measurement |
|--------|--------|-------------|
| **API Latency (p95)** | <500ms | CloudWatch API Gateway metrics |
| **Document View Latency (p95)** | <2s | End-to-end from API call to browser render |
| **Search Results (p95)** | <1s | Time to return first page (50 results) |
| **Uptime SLA** | 99.9% (43.8min/month downtime) | CloudWatch availability metrics |
| **Concurrent Users** | 500 (baseline), 2000 (peak) | Load test with Artillery |
| **Bulk Download Completion** | 95% within 10 minutes (500 docs) | Step Functions execution duration |

---

## Roadmap

### Phase 1: Foundation (Completed ✅)
- Architecture design and ADRs
- DynamoDB schema design
- API specifications
- C4 diagrams (Level 1, 2)

### Phase 2: Development (4-6 weeks)
- [ ] CDK infrastructure setup
- [ ] Lambda functions (Document, Search, Admin, Auth services)
- [ ] Cognito SAML integration with IDM
- [ ] DynamoDB tables with Global Tables
- [ ] Archive clients (IESC, IES, CMOD)

### Phase 3: Frontend (4 weeks)
- [ ] Angular app (search, view, download, comments, admin)
- [ ] CloudFront distribution
- [ ] Subdomain routing

### Phase 4: Advanced Features (4 weeks)
- [ ] Bulk download (Step Functions + SQS)
- [ ] EventBridge integration with FRS Proxy
- [ ] Email notifications

### Phase 5: Testing & UAT (4 weeks)
- [ ] Unit tests (80% coverage)
- [ ] Integration tests
- [ ] E2E tests (Cypress)
- [ ] Load testing (Artillery)
- [ ] Security testing (penetration test)
- [ ] Pilot tenant UAT

### Phase 6: Production Launch (2 weeks)
- [ ] Blue-green deployment
- [ ] Canary rollout (10% → 100% of tenants)
- [ ] Monitoring dashboards
- [ ] Runbooks and documentation
- [ ] Decommission on-premise Viewdocs

---

## Contributing to Architecture Docs

### Document Standards

- **Format**: Markdown (.md)
- **Diagrams**: Mermaid (text-based) + draw.io references
- **Versioning**: Update "Document Control" table at bottom of each doc
- **Review**: Architecture review board approval required for changes to core docs (00, 01, 02, 03, 10)

### Adding New Documents

1. Create document in `/docs/architecture/`
2. Follow naming convention: `{number}-{topic}-architecture.md`
3. Update this README index
4. Submit pull request with architectural review tag

### Updating Diagrams

1. **Mermaid**: Edit diagram code directly in .md file
2. **draw.io**: Export PNG/SVG to `/docs/architecture/diagrams/` and link in .md file
3. Version diagrams (e.g., `container-diagram-v2.png`)

---

## External References

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Serverless Multi-Tenancy Best Practices](https://docs.aws.amazon.com/prescriptive-guidance/latest/saas-multitenant-api-gateway-lambda-dynamodb/welcome.html)
- [DynamoDB Single-Table Design](https://www.alexdebrie.com/posts/dynamodb-single-table/)
- [C4 Model](https://c4model.com/)
- [TOGAF](https://www.opengroup.org/togaf)

---

## Feedback & Questions

- **Architecture Review Board**: Schedule review meeting via [Confluence Calendar]
- **Questions**: Post in #viewdocs-architecture Slack channel
- **Issues**: Create GitHub issue with `architecture` label

---

**Document Control**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-01-09 | Architecture Team | Initial README for architecture documentation |
