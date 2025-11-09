# Technology Architecture

**Document Version:** 1.0
**Last Updated:** 2025-11-09
**Status:** Draft

---

## 1. Technology Stack Overview

### 1.1 Technology Selection Principles

1. **Cloud-Native First**: Prefer AWS managed services over self-managed solutions
2. **TypeScript Everywhere**: Single language across frontend, backend, and IaC
3. **Proven at Scale**: Choose mature technologies with strong community support
4. **Security by Default**: Select services with built-in security features
5. **Cost-Effective**: Optimize for serverless, pay-per-use pricing

---

## 2. Frontend Technology Stack

### 2.1 Core Framework

| Component | Technology | Version | Justification |
|-----------|------------|---------|---------------|
| **Framework** | Angular | 17+ | Type-safe, enterprise-ready, strong CLI, RxJS for reactive programming |
| **Language** | TypeScript | 5.x | Type safety, IDE support, aligns with backend |
| **State Management** | NgRx | 17.x | Redux pattern for complex state, DevTools support |
| **HTTP Client** | Angular HttpClient | Built-in | Interceptors for auth tokens, error handling |
| **Routing** | Angular Router | Built-in | Lazy loading, route guards for authorization |
| **UI Components** | Angular Material | 17.x | Accessible, responsive, consistent design system |

### 2.2 Additional Libraries

```json
{
  "dependencies": {
    "@angular/core": "^17.0.0",
    "@angular/material": "^17.0.0",
    "@ngrx/store": "^17.0.0",
    "@ngrx/effects": "^17.0.0",
    "rxjs": "^7.8.0",
    "pdf.js": "^3.11.0",
    "file-saver": "^2.0.5",
    "date-fns": "^2.30.0"
  },
  "devDependencies": {
    "@angular/cli": "^17.0.0",
    "typescript": "^5.2.0",
    "jest": "^29.7.0",
    "@testing-library/angular": "^14.0.0",
    "cypress": "^13.6.0",
    "eslint": "^8.54.0"
  }
}
```

### 2.3 Build & Bundle

| Tool | Purpose | Configuration |
|------|---------|---------------|
| **Angular CLI** | Build, serve, test | `angular.json` with production optimizations |
| **esbuild** | Fast bundling | Enabled by default in Angular 17+ |
| **Terser** | JS minification | Production builds only |
| **CSS Optimization** | PurgeCSS, minification | Remove unused styles |

**Build Targets**:
- **Development**: Source maps, no minification, fast rebuild
- **UAT**: Minified, source maps included, environment variables for UAT API
- **Production**: Fully optimized, no source maps, CDN URLs, environment variables for prod API

### 2.4 Document Viewer

**Library**: PDF.js (Mozilla)

**Features**:
- Client-side PDF rendering (no server-side conversion)
- Zoom, rotate, print
- Text search within document
- Mobile-responsive

**Alternative for Office Docs**: Office Online Viewer (iframe embed) or conversion to PDF server-side

---

## 3. Backend Technology Stack

### 3.1 Runtime & Language

| Component | Technology | Version | Justification |
|-----------|------------|---------|---------------|
| **Runtime** | Node.js | 20.x | LTS, fast cold starts (<200ms), rich ecosystem |
| **Language** | TypeScript | 5.x | Type safety, alignment with frontend/IaC |
| **Package Manager** | npm | 10.x | Standard, lockfile support |
| **Build Tool** | esbuild | 0.19.x | Fast bundling, tree-shaking, <5MB bundles |

### 3.2 Lambda Dependencies

```json
{
  "dependencies": {
    "aws-sdk": "^2.1500.0",
    "@aws-sdk/client-dynamodb": "^3.460.0",
    "@aws-sdk/client-s3": "^3.460.0",
    "@aws-sdk/client-secrets-manager": "^3.460.0",
    "@aws-sdk/client-eventbridge": "^3.460.0",
    "axios": "^1.6.0",
    "soap": "^1.0.0",
    "uuid": "^9.0.0",
    "date-fns": "^2.30.0",
    "zod": "^3.22.0"
  },
  "devDependencies": {
    "@types/node": "^20.10.0",
    "@types/aws-lambda": "^8.10.130",
    "esbuild": "^0.19.8",
    "jest": "^29.7.0",
    "@types/jest": "^29.5.10",
    "eslint": "^8.54.0",
    "@typescript-eslint/eslint-plugin": "^6.13.0",
    "aws-sdk-client-mock": "^3.0.0"
  }
}
```

### 3.3 Lambda Layers

**Purpose**: Share common dependencies across Lambda functions to reduce bundle size

| Layer | Dependencies | Size | Usage |
|-------|-------------|------|-------|
| **AWS SDK Layer** | @aws-sdk/client-* | ~15MB | All Lambda functions |
| **HTTP Client Layer** | axios, soap | ~2MB | Document, Search, Event services |
| **Utilities Layer** | uuid, date-fns, zod | ~1MB | All Lambda functions |

**Benefits**:
- Reduce individual function bundle size (5MB → 2MB)
- Faster deployments (layer cached, only function code changes)
- Consistent dependency versions across functions

### 3.4 Testing Framework

| Type | Framework | Configuration |
|------|-----------|---------------|
| **Unit Tests** | Jest | 80% coverage target, mock AWS SDK |
| **Integration Tests** | Jest + DynamoDB Local | Test with real DynamoDB tables |
| **Load Tests** | Artillery | Simulate 500 concurrent users |

**Jest Configuration** (`jest.config.js`):
```javascript
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  },
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.test.ts'
  ]
};
```

---

## 4. AWS Services

### 4.1 Compute

| Service | Use Case | Configuration |
|---------|----------|---------------|
| **Lambda** | Application services (Document, Search, etc.) | Node.js 20.x, 256MB-512MB, 5s-29s timeout |
| **Step Functions** | Bulk download orchestration | Standard workflow, 15min max duration |

**Lambda Best Practices**:
- Use environment variables for config (DynamoDB table names, archive endpoints)
- Enable X-Ray tracing for all functions
- Set reserved concurrency for critical functions (Document Service: 100)
- Use VPC only if needed (Direct Connect to on-premise)

### 4.2 API & Frontend

| Service | Use Case | Configuration |
|---------|----------|---------------|
| **API Gateway** | REST API endpoints | Regional endpoint, Cognito authorizer, throttling 10,000 RPS |
| **CloudFront** | CDN for static assets and API caching | Custom domain, SSL cert (ACM), WAF enabled |
| **S3** | Static hosting (Angular app), bulk downloads | Standard storage, lifecycle policies |
| **Route 53** | DNS, multi-region failover | Hosted zone, health checks, latency-based routing |

### 4.3 Data Storage

| Service | Use Case | Configuration |
|---------|----------|---------------|
| **DynamoDB** | Tenant config, ACLs, audit logs, comments | Global Tables (ap-southeast-2 + ap-southeast-4), provisioned capacity with auto-scaling |
| **S3** | Bulk downloads (temp), static assets | S3 Standard, lifecycle policy (72h deletion), versioning for frontend |
| **Secrets Manager** | Archive credentials | KMS encryption, auto-rotation every 90 days |

**DynamoDB Configuration**:
- **Table**: `viewdocs-data`
- **Billing**: Provisioned (100 RCU, 125 WCU) with auto-scaling (min 50, max 500)
- **TTL**: Enabled on `TTL` attribute (audit logs)
- **Encryption**: AWS-managed KMS key
- **Backups**: Point-in-time recovery enabled

### 4.4 Security & Identity

| Service | Use Case | Configuration |
|---------|----------|---------------|
| **Cognito** | User authentication, JWT issuance | User Pool with SAML IdP connections, 30min token expiry |
| **IAM** | Service permissions | Least-privilege roles for Lambda, DynamoDB, S3 |
| **KMS** | Encryption keys | Customer-managed keys for DynamoDB, S3, Secrets Manager |
| **WAF** | Web application firewall | Rate limiting, SQL injection protection, geo-blocking |
| **Secrets Manager** | Credential storage | Encrypted secrets, auto-rotation Lambda |

### 4.5 Integration & Messaging

| Service | Use Case | Configuration |
|---------|----------|---------------|
| **EventBridge** | Event routing to HUB | Event bus with schema registry, archive to S3 for replay |
| **SQS** | Bulk download job queue | FIFO queue, 4-day retention, DLQ for failed jobs |
| **Direct Connect** | On-premise connectivity | Shared 10Gbps connection to IES, CMOD, FRS |

### 4.6 Monitoring & Observability

| Service | Use Case | Configuration |
|---------|----------|---------------|
| **CloudWatch Logs** | Centralized logging | Log groups per Lambda, 7-day retention for dev, 30-day for prod |
| **CloudWatch Metrics** | Custom metrics | API latency, DynamoDB throttles, Lambda errors |
| **CloudWatch Alarms** | Alerting | SNS topic for critical alarms (error rate >5%, latency >1s) |
| **X-Ray** | Distributed tracing | Enabled on all Lambda functions, API Gateway |
| **CloudWatch Dashboards** | Operational visibility | Real-time metrics for API, Lambda, DynamoDB |

---

## 5. Infrastructure as Code (IaC)

### 5.1 AWS CDK

**Version**: AWS CDK 2.x
**Language**: TypeScript

**CDK App Structure**:
```
infrastructure/
├── bin/
│   └── app.ts                    # CDK app entry point
├── lib/
│   ├── stacks/
│   │   ├── foundation-stack.ts   # IAM roles, KMS keys
│   │   ├── data-stack.ts         # DynamoDB, S3
│   │   ├── api-stack.ts          # API Gateway, Lambda functions
│   │   ├── auth-stack.ts         # Cognito User Pool
│   │   ├── frontend-stack.ts     # S3, CloudFront
│   │   ├── event-stack.ts        # EventBridge, SQS, Step Functions
│   │   └── monitoring-stack.ts   # CloudWatch dashboards, alarms
│   ├── constructs/
│   │   ├── tenant-isolated-table.ts  # Reusable DynamoDB construct
│   │   ├── lambda-service.ts     # Reusable Lambda construct with X-Ray, logging
│   │   └── multi-region-bucket.ts    # S3 with cross-region replication
│   └── config/
│       ├── dev.ts                # Dev environment config
│       ├── uat.ts                # UAT environment config
│       └── prod.ts               # Prod environment config
├── test/
│   └── stacks.test.ts            # CDK snapshot tests
├── cdk.json
└── package.json
```

**CDK Dependencies**:
```json
{
  "dependencies": {
    "aws-cdk-lib": "^2.110.0",
    "constructs": "^10.3.0"
  },
  "devDependencies": {
    "@types/node": "^20.10.0",
    "typescript": "^5.2.0",
    "ts-node": "^10.9.0",
    "jest": "^29.7.0"
  }
}
```

### 5.2 CDK Patterns

**Multi-Environment Pattern**:
```typescript
// bin/app.ts
const app = new cdk.App();
const env = app.node.tryGetContext('env') || 'dev';
const config = require(`../lib/config/${env}`).default;

new DataStack(app, `Viewdocs-Data-${env}`, {
  env: { account: config.account, region: config.region },
  config
});
```

**Reusable Lambda Construct**:
```typescript
// lib/constructs/lambda-service.ts
export class LambdaService extends Construct {
  public readonly function: lambda.Function;

  constructor(scope: Construct, id: string, props: LambdaServiceProps) {
    super(scope, id);

    this.function = new lambda.Function(this, 'Function', {
      runtime: lambda.Runtime.NODEJS_20_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('dist/backend'),
      environment: {
        TABLE_NAME: props.tableName,
        LOG_LEVEL: props.logLevel || 'INFO'
      },
      tracing: lambda.Tracing.ACTIVE,
      timeout: cdk.Duration.seconds(props.timeout || 29),
      memorySize: props.memorySize || 512,
      reservedConcurrentExecutions: props.reservedConcurrency
    });

    // Add X-Ray permissions
    this.function.addToRolePolicy(new iam.PolicyStatement({
      actions: ['xray:PutTraceSegments', 'xray:PutTelemetryRecords'],
      resources: ['*']
    }));
  }
}
```

---

## 6. Development Tools

### 6.1 IDE & Extensions

**Recommended IDE**: Visual Studio Code

**Extensions**:
- AWS Toolkit for VS Code
- ESLint
- Prettier
- TypeScript Importer
- Angular Language Service
- GitLens
- Jest Runner
- AWS CDK Snippets

### 6.2 Code Quality

| Tool | Purpose | Configuration |
|------|---------|---------------|
| **ESLint** | Linting | TypeScript rules, Angular plugin |
| **Prettier** | Code formatting | 2-space indent, single quotes, trailing commas |
| **Husky** | Git hooks | Pre-commit: lint + format, pre-push: tests |
| **SonarQube** | Code quality analysis | 80% coverage, no critical issues |

**ESLint Config** (`.eslintrc.json`):
```json
{
  "parser": "@typescript-eslint/parser",
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "prettier"
  ],
  "rules": {
    "no-console": "warn",
    "@typescript-eslint/explicit-function-return-type": "warn",
    "@typescript-eslint/no-unused-vars": "error"
  }
}
```

### 6.3 Version Control

**Git Branching Strategy**: GitFlow

| Branch | Purpose | Deployment |
|--------|---------|------------|
| `main` | Production-ready code | Auto-deploy to prod (with approval) |
| `develop` | Integration branch | Auto-deploy to dev |
| `feature/*` | Feature development | N/A |
| `release/*` | Release preparation | Deploy to UAT |
| `hotfix/*` | Production hotfixes | Fast-track to prod |

**Commit Convention**: Conventional Commits
```
feat(api): add bulk download endpoint
fix(auth): resolve JWT expiry issue
docs(arch): update DynamoDB schema
```

---

## 7. CI/CD Pipeline

### 7.1 Pipeline Tools

**Primary**: AWS CDK Pipelines (self-mutating)
**Alternative**: GitHub Actions (for external repos)

**Pipeline Stages**:
1. **Source**: CodeCommit / GitHub
2. **Build**: npm install, TypeScript compile, esbuild bundle
3. **Test**: Jest unit tests, coverage check (80%)
4. **Synth**: CDK synth (generate CloudFormation)
5. **Deploy Dev**: Auto-deploy to dev environment
6. **Integration Tests**: Run against dev environment
7. **Manual Approval**: Tech lead approval for UAT
8. **Deploy UAT**: Deploy to UAT environment
9. **E2E Tests**: Cypress tests against UAT
10. **Load Tests**: Artillery tests (500 concurrent users)
11. **Manual Approval**: Product owner approval for prod
12. **Deploy Prod**: Blue-green deployment with canary rollout

### 7.2 Build Artifacts

| Artifact | Contents | Storage |
|----------|----------|---------|
| **Frontend Bundle** | Angular dist/ folder | S3 `viewdocs-artifacts` bucket |
| **Lambda Bundles** | Individual function .zip files | S3 `viewdocs-artifacts` bucket |
| **CDK Templates** | CloudFormation JSON | CDK bootstrap bucket |
| **Test Reports** | Jest coverage, Cypress videos | S3 `viewdocs-test-reports` bucket |

---

## 8. Third-Party Services & APIs

### 8.1 Archive Systems

| System | Protocol | SDK/Library | Authentication |
|--------|----------|-------------|----------------|
| **IESC** | REST API (HTTPS) | axios | Basic Auth (username/password in Secrets Manager) |
| **IES** | SOAP | node-soap | WS-Security (username/password in Secrets Manager) |
| **CMOD** | SOAP | node-soap | WS-Security (username/password in Secrets Manager) |

**SOAP Client Example**:
```typescript
import soap from 'soap';

const wsdlUrl = 'https://ies.example.com/services?wsdl';
const client = await soap.createClientAsync(wsdlUrl);
client.setSecurity(new soap.BasicAuthSecurity(username, password));

const result = await client.SearchDocumentsAsync({ query: {...} });
```

### 8.2 Email Service

**Current**: IDM Email Service (SOAP)
**Future** (3 months): Email Platform (REST API)

**Library**: axios (REST), node-soap (SOAP)

### 8.3 FRS Proxy

**Protocol**: SOAP over Direct Connect
**Library**: node-soap
**Payload**: XML messages forwarded to IBM MQ

---

## 9. SDK Versions & Updates

### 9.1 AWS SDK

**Version Strategy**: AWS SDK v3 (modular)

**Why v3?**
- Smaller bundle sizes (import only needed clients)
- Improved TypeScript support
- Middleware for custom logic

**Example**:
```typescript
import { DynamoDBClient, GetItemCommand } from '@aws-sdk/client-dynamodb';

const client = new DynamoDBClient({ region: 'ap-southeast-2' });
const result = await client.send(new GetItemCommand({ TableName, Key }));
```

### 9.2 Dependency Updates

**Policy**: Monthly dependency updates (first Tuesday of month)

**Process**:
1. Run `npm outdated` to check for updates
2. Update non-breaking (minor/patch) versions
3. Test in dev environment
4. Update breaking (major) versions in separate PRs with testing
5. Document breaking changes in CHANGELOG.md

**Automated Updates**: Dependabot enabled for security patches

---

## 10. Performance Optimization

### 10.1 Lambda Optimizations

| Technique | Benefit | Implementation |
|-----------|---------|----------------|
| **Provisioned Concurrency** | Eliminate cold starts | Document Service: 10 instances |
| **Bundle Optimization** | Faster cold starts | esbuild with tree-shaking, <5MB bundles |
| **Connection Reuse** | Lower latency | HTTP keep-alive for archive APIs |
| **Lambda Layers** | Smaller deployments | Common dependencies in layers |
| **Memory Tuning** | Cost optimization | Use Lambda Power Tuning tool |

**Lambda Power Tuning**: Run automated tests to find optimal memory allocation (cost vs performance).

### 10.2 DynamoDB Optimizations

| Technique | Benefit | Implementation |
|-----------|---------|----------------|
| **Single-Table Design** | Fewer queries | All entities in one table |
| **Batch Operations** | Reduce API calls | BatchGetItem for ACLs |
| **Projection Expressions** | Reduce data transfer | Fetch only required attributes |
| **Auto-Scaling** | Cost optimization | Scale RCU/WCU based on demand |

### 10.3 CloudFront Optimizations

| Technique | Benefit | Implementation |
|-----------|---------|----------------|
| **Cache Policies** | Higher cache hit ratio | 1 year for static assets, 5 min for API |
| **Compression** | Faster transfers | Gzip/Brotli for text assets |
| **HTTP/2** | Multiplexing | Enabled by default |
| **Origin Shield** | Reduced origin load | Enable for high-traffic routes |

---

## 11. Security Tools

### 11.1 Vulnerability Scanning

| Tool | Purpose | Frequency |
|------|---------|-----------|
| **npm audit** | Scan dependencies for CVEs | Every commit (pre-commit hook) |
| **Snyk** | Continuous vulnerability monitoring | Daily scans |
| **AWS Inspector** | EC2/Lambda vulnerability scanning | Weekly (if using VPC Lambda) |
| **SonarQube** | Code security analysis | Every PR |

### 11.2 Secrets Management

**Tool**: AWS Secrets Manager

**Rotation**: Lambda function for automatic rotation every 90 days

**Access Control**: IAM policies with least privilege (Lambda execution role can only read specific secrets)

---

## 12. Technology Roadmap

### Phase 1 (Current): Foundation
- ✅ TypeScript across stack
- ✅ AWS CDK for IaC
- ✅ DynamoDB Global Tables
- ✅ Cognito SAML

### Phase 2 (6 months): AI/ML Enhancements
- [ ] AWS Bedrock for conversational search (RAG)
- [ ] Amazon Textract for document OCR (via IESC)
- [ ] Amazon Comprehend for document classification

### Phase 3 (12 months): Advanced Analytics
- [ ] AWS Glue for ETL (DynamoDB → S3)
- [ ] Amazon Athena for audit log analysis
- [ ] Amazon QuickSight for tenant dashboards

### Phase 4 (18 months): Mobile App
- [ ] React Native mobile app
- [ ] AWS AppSync for GraphQL API
- [ ] AWS Amplify for mobile backend

---

## Next Steps

1. Set up development environment with recommended tools
2. Bootstrap CDK in AWS accounts (dev, uat, prod)
3. Install dependencies (npm install in backend, frontend, infrastructure)
4. Run unit tests to validate setup
5. Proceed to [05-security-architecture.md](05-security-architecture.md)

---

**Document Control**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-09 | Architecture Team | Initial technology architecture |
