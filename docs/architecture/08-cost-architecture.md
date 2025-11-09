# Cost Architecture

**Document Version:** 1.0
**Last Updated:** 2025-11-09
**Status:** Draft

---

## 1. Cost Overview

### 1.1 Total Cost of Ownership (TCO)

**Monthly Cost Estimate** (Production - 500 tenants, 500 concurrent users):

| Category | Monthly Cost (USD) | Annual Cost (USD) |
|----------|-------------------|-------------------|
| **AWS Services** | $1,282 | $15,384 |
| **Direct Connect (Shared)** | $50 | $600 |
| **Support & Monitoring** | $100 | $1,200 |
| **Third-Party Tools** | $50 | $600 |
| **Total** | **$1,482** | **$17,784** |

**Cost per Tenant**: $1,482 / 500 tenants = **$2.96/tenant/month**

**Comparison to On-Premise**:
- On-premise: $200K/year ($16,667/month)
- Cloud: $17,784/year ($1,482/month)
- **Savings**: $182,216/year (91% reduction)

---

## 2. AWS Service Costs Breakdown

### 2.1 Compute (Lambda)

**Usage**:
- 50 million invocations/month
- Average duration: 500ms
- Average memory: 512MB
- Provisioned concurrency: 10 instances for Document Service

**Pricing** (ap-southeast-2):
- Invocations: $0.20 per 1M requests
- Duration: $0.0000166667 per GB-second
- Provisioned Concurrency: $0.0000041667 per GB-second

**Calculation**:
```
Invocations: 50M × $0.20/1M = $10
Duration: 50M × 0.5s × 0.5GB × $0.0000166667 = $208
Provisioned (10 instances, 512MB, 730 hours):
  10 × 0.5GB × 730h × 3600s × $0.0000041667 = $55
Total Lambda: $273/month
```

### 2.2 API Gateway

**Usage**:
- 10 million API requests/month

**Pricing**:
- REST API: $3.50 per 1M requests

**Calculation**:
```
10M × $3.50/1M = $35/month
```

### 2.3 DynamoDB

**Configuration**: Provisioned capacity
- Read Capacity Units (RCU): 100 (auto-scaling: min 50, max 500)
- Write Capacity Units (WCU): 125 (auto-scaling: min 50, max 500)
- Storage: 25GB (with Global Tables replication)

**Pricing**:
- RCU: $0.000742 per hour
- WCU: $0.003710 per hour
- Storage: $0.329 per GB-month
- Global Tables (replication): 2× write capacity cost

**Calculation**:
```
RCU: 100 × 730h × $0.000742 = $54
WCU: 125 × 730h × $0.003710 = $338
Storage: 25GB × $0.329 = $8
Global Tables (DR replication): $338 (WCU doubled)
Total DynamoDB: $738/month
```

### 2.4 S3

**Usage**:
- Frontend assets: 1GB
- Bulk downloads (average): 500GB/month (temporary, 72-hour lifecycle)
- Total storage (average): 100GB
- GET requests: 5 million/month
- PUT requests: 1 million/month

**Pricing**:
- Storage: $0.025 per GB-month
- GET: $0.0004 per 1,000 requests
- PUT: $0.005 per 1,000 requests

**Calculation**:
```
Storage: 100GB × $0.025 = $2.50
GET: 5M / 1000 × $0.0004 = $2
PUT: 1M / 1000 × $0.005 = $5
Total S3: $9.50/month
```

### 2.5 CloudFront

**Usage**:
- Data transfer out: 1TB/month (frontend assets + API responses)
- HTTPS requests: 10 million/month

**Pricing**:
- Data transfer (first 10TB): $0.140 per GB
- HTTPS requests: $0.0120 per 10,000 requests

**Calculation**:
```
Data transfer: 1000GB × $0.140 = $140
HTTPS requests: 10M / 10000 × $0.0120 = $12
Total CloudFront: $152/month
```

### 2.6 Cognito

**Usage**:
- Monthly Active Users (MAU): 2,000

**Pricing**:
- First 50,000 MAU: Free
- Beyond 50,000: $0.0055 per MAU

**Calculation**:
```
2,000 MAU < 50,000 → Free
Total Cognito: $0/month
```

### 2.7 Secrets Manager

**Usage**:
- 50 secrets (1 per tenant archive credentials + shared)

**Pricing**:
- $0.40 per secret per month
- $0.05 per 10,000 API calls

**Calculation**:
```
Secrets: 50 × $0.40 = $20
API calls (1M/month): 1M / 10000 × $0.05 = $5
Total Secrets Manager: $25/month
```

### 2.8 CloudWatch

**Usage**:
- Logs ingested: 50GB/month
- Logs stored: 100GB (7-day retention dev, 30-day prod)
- Custom metrics: 500 metrics

**Pricing**:
- Log ingestion: $0.57 per GB
- Log storage: $0.033 per GB
- Custom metrics: $0.30 per metric

**Calculation**:
```
Ingestion: 50GB × $0.57 = $28.50
Storage: 100GB × $0.033 = $3.30
Metrics: 500 × $0.30 = $150
Total CloudWatch: $181.80/month
```

### 2.9 X-Ray

**Usage**:
- 10 million traces/month (20% sampling)

**Pricing**:
- $5 per 1 million traces recorded
- $0.50 per 1 million traces retrieved

**Calculation**:
```
Recorded: 10M × $5/1M = $50
Retrieved (10% of recorded): 1M × $0.50/1M = $0.50
Total X-Ray: $50.50/month
```

### 2.10 EventBridge

**Usage**:
- 5 million events/month (document view, download, comment)

**Pricing**:
- $1 per 1 million events

**Calculation**:
```
5M × $1/1M = $5/month
```

### 2.11 Step Functions

**Usage**:
- 100,000 state transitions/month (bulk downloads)

**Pricing**:
- Standard workflow: $0.025 per 1,000 state transitions

**Calculation**:
```
100K / 1000 × $0.025 = $2.50/month
```

### 2.12 SQS

**Usage**:
- 10 million requests/month (bulk download jobs)

**Pricing**:
- Standard queue: $0.40 per 1 million requests
- FIFO queue: $0.50 per 1 million requests

**Calculation**:
```
10M × $0.50/1M = $5/month
```

### 2.13 Route 53

**Usage**:
- 2 hosted zones (viewdocs.example.com, dr-viewdocs.example.com)
- 10 million queries/month

**Pricing**:
- Hosted zone: $0.50 per zone per month
- Queries: $0.40 per 1 million queries

**Calculation**:
```
Hosted zones: 2 × $0.50 = $1
Queries: 10M × $0.40/1M = $4
Total Route 53: $5/month
```

### 2.14 WAF

**Usage**:
- 1 Web ACL
- 5 rules
- 10 million requests/month

**Pricing**:
- Web ACL: $5 per month
- Rules: $1 per rule per month
- Requests: $0.60 per 1 million requests

**Calculation**:
```
Web ACL: $5
Rules: 5 × $1 = $5
Requests: 10M × $0.60/1M = $6
Total WAF: $16/month
```

---

## 3. Multi-Region DR Costs

**DR Region** (ap-southeast-4): Standby environment

| Service | Primary (ap-southeast-2) | DR (ap-southeast-4) | Notes |
|---------|--------------------------|---------------------|-------|
| **Lambda** | $273 | $55 | Minimal provisioned concurrency in DR |
| **API Gateway** | $35 | $7 | Lower request volume (health checks only) |
| **DynamoDB** | $738 | Included | Global Tables replication (already counted) |
| **S3** | $9.50 | $4.75 | Cross-region replication |
| **CloudFront** | $152 | Shared | Single global distribution |
| **Total DR Overhead** | - | **~$67/month** | |

**Total Cost (Primary + DR)**: $1,282 + $67 = **$1,349/month**

---

## 4. Cost Optimization Strategies

### 4.1 Lambda Optimization

| Strategy | Savings | Implementation |
|----------|---------|----------------|
| **Right-Size Memory** | 10-20% | Use Lambda Power Tuning tool to find optimal memory (may reduce from 512MB to 384MB) |
| **Reduce Bundle Size** | 5-10% | Use esbuild tree-shaking, Lambda Layers for common dependencies |
| **Optimize Execution Time** | 10-15% | Cache DynamoDB responses, reuse HTTP connections |
| **Remove Provisioned Concurrency (if cold starts acceptable)** | $55/month | Evaluate if 200ms cold start acceptable for some functions |

**Potential Savings**: $40-80/month

### 4.2 DynamoDB Optimization

| Strategy | Savings | Implementation |
|----------|---------|----------------|
| **Switch to On-Demand (if unpredictable load)** | 0-30% | Compare costs after 3 months of usage data |
| **Use DynamoDB Streams instead of polling** | $10/month | Reduce Lambda invocations |
| **Optimize Single-Table Design** | 20-30% | Reduce number of queries per request (batch operations) |
| **Enable TTL for Audit Logs** | Included | Already implemented |

**Potential Savings**: $100-200/month

### 4.3 S3 Optimization

| Strategy | Savings | Implementation |
|----------|---------|----------------|
| **Lifecycle Policies** | Already implemented | Delete bulk downloads after 72 hours |
| **Intelligent-Tiering** | 10-20% | Auto-move infrequently accessed objects to cheaper tiers |
| **S3 Transfer Acceleration (disable if not needed)** | $5/month | Evaluate if needed |

**Potential Savings**: $1-2/month

### 4.4 CloudFront Optimization

| Strategy | Savings | Implementation |
|----------|---------|----------------|
| **Increase Cache TTL** | 10-20% | Cache static assets for 1 year (already done), increase API cache to 10min |
| **Enable Compression** | 5-10% | Gzip/Brotli for text assets |
| **Origin Shield** | -$10/month (cost increase) | Only enable if origin under heavy load |

**Potential Savings**: $15-30/month

### 4.5 CloudWatch Logs Optimization

| Strategy | Savings | Implementation |
|----------|---------|----------------|
| **Reduce Log Verbosity** | 30-50% | Set log level to WARN in prod (currently DEBUG in dev) |
| **Filter Logs Before Ingestion** | 20-30% | Use Lambda log filtering (exclude health checks) |
| **Shorter Retention** | 10-20% | 7 days instead of 30 days (if acceptable) |

**Potential Savings**: $50-100/month

---

## 5. Cost Allocation & Tagging

### 5.1 Cost Allocation Tags

**Tag all resources** with:
- `Environment`: dev, uat, prod
- `TenantId`: (if resource is tenant-specific, e.g., S3 objects)
- `Service`: api, frontend, data, event
- `Owner`: team-name
- `CostCenter`: FBDMS-ECM

**Example CDK Tagging**:
```typescript
cdk.Tags.of(stack).add('Environment', 'prod');
cdk.Tags.of(stack).add('Service', 'api');
cdk.Tags.of(stack).add('Owner', 'viewdocs-team');
```

### 5.2 Cost Allocation by Tenant (Future)

**Challenge**: Lambda, API Gateway costs are shared across tenants

**Approach**:
1. Log `tenant_id` in CloudWatch Logs for every Lambda invocation
2. Use CloudWatch Logs Insights to query invocation count per tenant
3. Allocate Lambda costs proportionally based on invocation count

**Example Query**:
```sql
fields @timestamp, tenant_id
| filter @type = "REPORT"
| stats count() by tenant_id
```

**Allocation Formula**:
```
Tenant A cost = Total Lambda cost × (Tenant A invocations / Total invocations)
```

---

## 6. Cost Monitoring & Alerts

### 6.1 AWS Budgets

**Budget 1: Monthly AWS Services**
- **Amount**: $1,500/month
- **Alert Threshold**: 80% ($1,200), 100% ($1,500)
- **Notification**: SNS to finance team

**Budget 2: Per-Service Budget**
- **DynamoDB**: $800/month (alert at 90%)
- **Lambda**: $300/month (alert at 90%)
- **CloudFront**: $200/month (alert at 90%)

**Budget 3: Forecast**
- **Forecasted Spend**: Alert if forecasted spend > $2,000/month

### 6.2 Cost Anomaly Detection

**AWS Cost Anomaly Detection**:
- Enable for all services
- Alert on anomalies > $50 spike
- SNS notification to DevOps team

### 6.3 Monthly Cost Review

**Process**:
1. Generate AWS Cost Explorer report (first week of month)
2. Review top 10 cost drivers
3. Identify optimization opportunities
4. Update cost forecast for next quarter

---

## 7. Scaling Cost Projections

### 7.1 Cost at Different Scales

| Tenants | Users | Monthly Cost | Cost per Tenant |
|---------|-------|--------------|-----------------|
| **5** | 500 | $400 | $80 |
| **50** | 2,000 | $700 | $14 |
| **500** | 10,000 | $1,482 | $2.96 |
| **1,000** | 20,000 | $2,500 | $2.50 |
| **5,000** | 100,000 | $8,000 | $1.60 |

**Observation**: Cost per tenant decreases with scale (economies of scale)

### 7.2 Break-Even Analysis

**Question**: At what tenant count does cloud become cheaper than on-premise?

**On-Premise Cost**: $16,667/month (fixed)
**Cloud Cost** (variable): $400 base + ($2/tenant)

**Break-Even Calculation**:
```
$16,667 = $400 + ($2 × Tenants)
Tenants = ($16,667 - $400) / $2 = 8,133 tenants
```

**Conclusion**: Cloud is cheaper below 8,133 tenants. Beyond that, hybrid or silo model may be more cost-effective.

---

## 8. Reserved Capacity & Savings Plans

### 8.1 Lambda Savings Plans

**Current**: On-demand pricing
**Alternative**: Compute Savings Plan (1-year commitment)

**Savings**: 17% discount on Lambda duration costs

**Calculation**:
```
Lambda duration cost: $208/month
Savings: $208 × 17% = $35/month
Annual savings: $420
```

**Recommendation**: Commit after 3 months of stable usage

### 8.2 DynamoDB Reserved Capacity

**Current**: Provisioned capacity (100 RCU, 125 WCU)
**Alternative**: Reserved Capacity (1-year commitment)

**Savings**: 53% discount on RCU, 76% discount on WCU

**Calculation**:
```
Current RCU cost: $54/month → Reserved: $25/month (saves $29)
Current WCU cost: $338/month → Reserved: $81/month (saves $257)
Total monthly savings: $286
Annual savings: $3,432
```

**Recommendation**: Purchase reserved capacity after 3 months

### 8.3 Total Savings with Reserved Pricing

| Item | Current | Reserved | Savings |
|------|---------|----------|---------|
| Lambda | $273 | $238 | $35 |
| DynamoDB | $738 | $452 | $286 |
| **Total** | **$1,011** | **$690** | **$321/month** |

**Annual Savings**: $3,852

---

## 9. Cost Comparison: Cloud vs On-Premise

### 9.1 On-Premise Costs (Current)

| Component | Annual Cost |
|-----------|-------------|
| **Infrastructure** | |
| Servers (4× app servers, 2× DB servers) | $40,000 |
| Oracle Database licenses | $60,000 |
| Storage (SAN) | $10,000 |
| Network equipment | $5,000 |
| Data center colocation | $15,000 |
| **Operations** | |
| 2 FTE (sysadmin, DBA) | $160,000 |
| Software patches, updates | $10,000 |
| **Disaster Recovery** | |
| DR site (none currently) | $0 |
| **Total On-Premise** | **$300,000** |

### 9.2 Cloud Costs (Proposed)

| Component | Annual Cost |
|-----------|-------------|
| **AWS Services** (with reserved pricing) | $13,000 |
| **Direct Connect** (shared) | $600 |
| **Support** (Business tier, shared) | $1,200 |
| **Operations** | |
| 0.5 FTE (cloud engineer) | $80,000 |
| Third-party monitoring | $600 |
| **Disaster Recovery** | |
| Multi-region (ap-southeast-4) | Included |
| **Total Cloud** | **$95,400** |

### 9.3 Cost Savings Summary

| Item | On-Premise | Cloud | Savings |
|------|-----------|-------|---------|
| **Infrastructure** | $130,000 | $13,000 | $117,000 (90%) |
| **Operations** | $170,000 | $80,600 | $89,400 (53%) |
| **Total** | **$300,000** | **$93,600** | **$206,400** (69%) |

**ROI**: With $400K initial investment (development), payback period = 1.9 years

---

## 10. Cost Governance

### 10.1 Cost Accountability

| Team | Responsibility |
|------|----------------|
| **DevOps Team** | Optimize infrastructure costs, monitor budgets |
| **Development Team** | Write efficient code, optimize Lambda execution time |
| **Architecture Team** | Design cost-effective solutions |
| **Finance Team** | Review monthly costs, approve budgets |

### 10.2 Cost Review Cadence

| Frequency | Activity | Attendees |
|-----------|----------|-----------|
| **Weekly** | Review cost anomalies | DevOps lead |
| **Monthly** | Cost review meeting, optimization backlog | DevOps, Architecture, Finance |
| **Quarterly** | Budget planning, savings plan evaluation | Leadership team |

---

## Next Steps

1. Enable AWS Cost Explorer and tag all resources
2. Set up AWS Budgets with alerts
3. Implement cost allocation logging (tenant_id in CloudWatch)
4. After 3 months, evaluate reserved capacity purchase
5. Create cost optimization backlog

---

**Document Control**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-09 | Finance Team, Architecture Team | Initial cost architecture |
