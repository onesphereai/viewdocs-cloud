# Deployment Topology Diagram

**Document Version:** 1.0
**Last Updated:** 2025-11-09

This document shows the multi-region deployment topology for Viewdocs Cloud with disaster recovery configuration.

---

## 1. Multi-Region Deployment Architecture

### 1.1 Primary and DR Regions

```mermaid
graph TB
    subgraph "Global Services"
        R53[Route 53<br/>DNS + Health Checks]
        CFGlobal[CloudFront<br/>Global CDN]
    end

    subgraph "ap-southeast-2 (Sydney) - PRIMARY"
        subgraph "Edge Services"
            WAF2[AWS WAF<br/>Web ACL]
        end

        subgraph "API Layer"
            APIGW2[API Gateway<br/>REST API]
            Cog2[Cognito<br/>User Pool]
        end

        subgraph "Compute"
            Lambda2[Lambda Functions<br/>Document, Search,<br/>Download, Admin]
            SF2[Step Functions<br/>Bulk Download]
        end

        subgraph "Data"
            DDB2[DynamoDB<br/>Global Table<br/>Primary]
            S32[S3 Buckets<br/>Bulk Downloads<br/>Frontend Assets]
            Secrets2[Secrets Manager<br/>Archive Credentials]
        end

        subgraph "Messaging"
            EB2[EventBridge<br/>Event Bus]
            SQS2[SQS<br/>Download Queue]
        end

        subgraph "Monitoring"
            CW2[CloudWatch<br/>Logs, Metrics, Alarms]
            XRay2[X-Ray<br/>Tracing]
        end
    end

    subgraph "ap-southeast-4 (Melbourne) - DR"
        subgraph "API Layer DR"
            APIGW4[API Gateway<br/>REST API<br/>Standby]
            Cog4[Cognito<br/>User Pool<br/>Replica]
        end

        subgraph "Compute DR"
            Lambda4[Lambda Functions<br/>Minimal Concurrency]
            SF4[Step Functions]
        end

        subgraph "Data DR"
            DDB4[DynamoDB<br/>Global Table<br/>Replica]
            S34[S3 Buckets<br/>Cross-Region Replica]
            Secrets4[Secrets Manager<br/>Replica]
        end

        subgraph "Messaging DR"
            EB4[EventBridge]
            SQS4[SQS]
        end

        subgraph "Monitoring DR"
            CW4[CloudWatch]
            XRay4[X-Ray]
        end
    end

    subgraph "On-Premise (via Direct Connect)"
        DX[Direct Connect<br/>10Gbps]
        VPN[VPN Tunnel<br/>IPsec]
        IES[IES<br/>SOAP API]
        CMOD[CMOD<br/>SOAP API]
        FRS[FRS Proxy<br/>SOAP API]
        HUB[HUB<br/>IBM MQ]
    end

    subgraph "External Systems"
        IDM[IDM<br/>SAML IdP]
        IESC[IESC<br/>Cloud ECM<br/>Tenant Stacks]
        ExtIdP[Customer IdPs<br/>SAML 2.0]
    end

    %% Global routing
    R53 -->|Primary| WAF2
    R53 -.->|Failover| APIGW4
    CFGlobal --> S32
    CFGlobal -.-> S34

    %% Primary region flow
    WAF2 --> CFGlobal
    CFGlobal --> APIGW2
    APIGW2 --> Cog2
    APIGW2 --> Lambda2
    Lambda2 --> DDB2
    Lambda2 --> S32
    Lambda2 --> Secrets2
    Lambda2 --> SF2
    SF2 --> SQS2
    SQS2 --> Lambda2
    Lambda2 --> EB2
    Lambda2 --> CW2
    Lambda2 --> XRay2

    %% DR region (standby)
    APIGW4 -.-> Cog4
    APIGW4 -.-> Lambda4
    Lambda4 -.-> DDB4
    Lambda4 -.-> S34
    Lambda4 -.-> Secrets4

    %% Data replication
    DDB2 <-->|Continuous<br/>Replication| DDB4
    S32 -->|Cross-Region<br/>Replication| S34
    Secrets2 -->|Replication| Secrets4

    %% External integrations
    Cog2 --> IDM
    Cog2 --> ExtIdP
    Cog4 -.-> IDM
    Lambda2 --> IESC
    Lambda4 -.-> IESC

    %% On-premise integration
    Lambda2 --> DX
    DX --> VPN
    VPN --> IES
    VPN --> CMOD
    EB2 --> DX
    DX --> FRS
    FRS --> HUB

    style R53 fill:#FF6B6B,stroke:#C92A2A,stroke-width:2px
    style DDB2 fill:#4ECDC4,stroke:#0A6C74,stroke-width:2px
    style DDB4 fill:#95E1D3,stroke:#38A89D,stroke-dasharray: 5 5
    style Lambda4 stroke-dasharray: 5 5
    style APIGW4 stroke-dasharray: 5 5
```

---

## 2. Deployment Layers

### 2.1 Layer Breakdown

| Layer | Primary Region | DR Region | Replication |
|-------|----------------|-----------|-------------|
| **Global Services** | Route 53, CloudFront | Same (global) | N/A |
| **Edge Security** | WAF (ap-southeast-2) | WAF (ap-southeast-4) | Manual config sync |
| **API Layer** | API Gateway, Cognito | API Gateway, Cognito | Manual deployment |
| **Compute** | Lambda (100 concurrency) | Lambda (10 concurrency) | CDK deployment |
| **Data** | DynamoDB (primary), S3 | DynamoDB (replica), S3 (replica) | Automatic (Global Tables, CRR) |
| **Secrets** | Secrets Manager | Secrets Manager (replica) | Automatic |
| **Messaging** | EventBridge, SQS | EventBridge, SQS | Manual deployment |
| **Monitoring** | CloudWatch, X-Ray | CloudWatch, X-Ray | Independent |

---

## 3. Multi-Region Failover

### 3.1 Health Check Configuration

**Route 53 Health Check**:
- **Endpoint**: `https://api.viewdocs.example.com/health`
- **Protocol**: HTTPS
- **Port**: 443
- **Path**: `/health`
- **Interval**: 30 seconds
- **Failure Threshold**: 3 consecutive failures (90 seconds)
- **Regions**: 3 different AWS regions monitoring endpoint

**Health Check Lambda**:
```typescript
export async function healthHandler(): Promise<APIGatewayProxyResult> {
  try {
    // Check DynamoDB
    await dynamoDb.getItem({
      TableName: 'viewdocs-data',
      Key: { PK: 'HEALTH', SK: 'CHECK' }
    }).promise();

    // Check Cognito
    await cognito.describeUserPool({ UserPoolId }).promise();

    return {
      statusCode: 200,
      body: JSON.stringify({
        status: 'healthy',
        region: process.env.AWS_REGION,
        timestamp: new Date().toISOString()
      })
    };
  } catch (error) {
    return {
      statusCode: 503,
      body: JSON.stringify({ status: 'unhealthy', error: error.message })
    };
  }
}
```

### 3.2 Failover Sequence

```mermaid
sequenceDiagram
    participant R53 as Route 53
    participant HC as Health Check
    participant Primary as ap-southeast-2<br/>(Primary)
    participant DR as ap-southeast-4<br/>(DR)
    participant User

    loop Every 30 seconds
        HC->>Primary: GET /health
        Primary->>HC: HTTP 200 (healthy)
    end

    Note over Primary: PRIMARY REGION FAILURE

    HC->>Primary: GET /health
    Primary--xHC: Timeout (no response)
    HC->>Primary: GET /health (retry 1)
    Primary--xHC: Timeout
    HC->>Primary: GET /health (retry 2)
    Primary--xHC: Timeout

    HC->>R53: Mark primary unhealthy<br/>(3 consecutive failures)

    R53->>R53: Update DNS records<br/>api.viewdocs.example.com → DR region

    User->>R53: DNS query: api.viewdocs.example.com
    R53->>User: Return DR region IP<br/>(ap-southeast-4)

    User->>DR: API request
    DR->>DR: Process request<br/>(DynamoDB Global Table replica)
    DR->>User: Response

    Note over DR: DR region now serving traffic

    Note over Primary: PRIMARY REGION RECOVERED

    HC->>Primary: GET /health
    Primary->>HC: HTTP 200 (healthy)

    HC->>R53: Mark primary healthy

    Note over R53,DR: Automatic failback<br/>can be disabled (manual only)

    alt Automatic Failback Enabled
        R53->>R53: Update DNS records<br/>api.viewdocs.example.com → Primary
        User->>Primary: API request
    else Manual Failback
        Note over R53: Admin manually triggers failback
    end
```

**Failover Time**:
- Health check failure detection: 90 seconds (3 × 30s)
- DNS propagation: 60 seconds (TTL)
- **Total RTO**: ~2.5 minutes

---

## 4. Deployment Environments

### 4.1 Environment Topology

```mermaid
graph TB
    subgraph "Dev Environment (Account: 123456789012)"
        DevAPi[API Gateway<br/>api-dev.viewdocs]
        DevLambda[Lambda<br/>10 concurrency]
        DevDDB[DynamoDB<br/>On-Demand<br/>Single Region]
        DevS3[S3]
    end

    subgraph "UAT Environment (Account: 234567890123)"
        UATAPI[API Gateway<br/>api-uat.viewdocs]
        UATLambda[Lambda<br/>50 concurrency]
        UATDDB[DynamoDB<br/>Provisioned<br/>Single Region]
        UATS3[S3]
    end

    subgraph "Prod Environment (Account: 345678901234)"
        subgraph "ap-southeast-2"
            ProdAPI[API Gateway<br/>api.viewdocs]
            ProdLambda[Lambda<br/>100 concurrency]
            ProdDDB[DynamoDB<br/>Global Table]
            ProdS3[S3]
        end

        subgraph "ap-southeast-4"
            ProdAPI_DR[API Gateway]
            ProdLambda_DR[Lambda<br/>10 concurrency]
            ProdDDB_DR[DynamoDB<br/>Replica]
            ProdS3_DR[S3 Replica]
        end
    end

    DevAPi --> DevLambda
    DevLambda --> DevDDB
    DevLambda --> DevS3

    UATAPI --> UATLambda
    UATLambda --> UATDDB
    UATLambda --> UATS3

    ProdAPI --> ProdLambda
    ProdLambda --> ProdDDB
    ProdLambda --> ProdS3
    ProdDDB <-->|Replication| ProdDDB_DR
    ProdS3 -->|CRR| ProdS3_DR

    style ProdDDB fill:#4ECDC4,stroke:#0A6C74,stroke-width:2px
    style ProdDDB_DR fill:#95E1D3,stroke:#38A89D
```

**Key Differences**:
- **Dev**: On-demand DynamoDB, single region, no DR
- **UAT**: Provisioned DynamoDB, single region, no DR
- **Prod**: Provisioned + auto-scaling, Global Tables, full DR

---

## 5. Network Topology

### 5.1 On-Premise Connectivity

```mermaid
graph LR
    subgraph "AWS - ap-southeast-2"
        subgraph "VPC (Optional)"
            PrivateSubnet[Private Subnet<br/>Lambda ENI]
            NAT[NAT Gateway<br/>Public Subnet]
        end

        Lambda[Lambda Functions]
        DXGateway[Direct Connect Gateway]
    end

    subgraph "AWS Direct Connect Location"
        DXConnection[Direct Connect<br/>10Gbps Connection]
    end

    subgraph "On-Premise Data Center"
        Router[Border Router]
        Firewall[Firewall]
        IES[IES Server<br/>SOAP API]
        CMOD[CMOD Server<br/>SOAP API]
        FRS[FRS Proxy<br/>SOAP API]
        HUB[HUB<br/>IBM MQ]
    end

    Lambda -->|If VPC Lambda| PrivateSubnet
    PrivateSubnet --> NAT
    NAT --> DXGateway
    Lambda -->|Direct (no VPC)| DXGateway

    DXGateway --> DXConnection
    DXConnection --> Router
    Router --> Firewall
    Firewall --> IES
    Firewall --> CMOD
    Firewall --> FRS
    FRS --> HUB

    style DXConnection fill:#FF6B6B,stroke:#C92A2A
    style Lambda fill:#4ECDC4
```

**Connectivity Options**:

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| **Lambda in VPC** | Private IP connectivity, enhanced security | NAT costs ($45/AZ/month), cold start penalty (+2s) | Use if required by on-premise network policies |
| **Lambda without VPC** | No NAT costs, faster cold starts | Public IP connectivity (still encrypted via TLS/IPsec) | **Recommended** if Direct Connect supports public IPs |

---

## 6. Deployment Pipeline Topology

### 6.1 CI/CD Pipeline Flow

```mermaid
graph LR
    CodeCommit[CodeCommit<br/>develop branch]
    BuildStage[CodeBuild<br/>npm install, test, synth]
    DevDeploy[Deploy Dev<br/>ap-southeast-2]
    IntegrationTest[Integration Tests]
    ManualApproval1[Manual Approval<br/>Tech Lead]
    UATDeploy[Deploy UAT<br/>ap-southeast-2]
    E2ETest[E2E Tests<br/>Cypress]
    LoadTest[Load Tests<br/>Artillery]
    ManualApproval2[Manual Approval<br/>Product Owner]
    ProdDeploy[Deploy Prod<br/>Blue-Green]

    CodeCommit --> BuildStage
    BuildStage --> DevDeploy
    DevDeploy --> IntegrationTest
    IntegrationTest --> ManualApproval1
    ManualApproval1 --> UATDeploy
    UATDeploy --> E2ETest
    E2ETest --> LoadTest
    LoadTest --> ManualApproval2
    ManualApproval2 --> ProdDeploy

    subgraph "Production Deployment"
        ProdDeploy --> ProdPrimary[Deploy<br/>ap-southeast-2]
        ProdDeploy --> ProdDR[Deploy<br/>ap-southeast-4]
    end

    style ProdDeploy fill:#FF6B6B,stroke:#C92A2A
    style ManualApproval1 fill:#FFD93D
    style ManualApproval2 fill:#FFD93D
```

---

## 7. Monitoring & Observability Topology

### 7.1 Centralized Monitoring

```mermaid
graph TB
    subgraph "Application Layer"
        API[API Gateway]
        Lambda[Lambda Functions]
        DDB[DynamoDB]
        S3[S3]
    end

    subgraph "Monitoring Layer"
        CWLogs[CloudWatch Logs<br/>Log Groups per Lambda]
        CWMetrics[CloudWatch Metrics<br/>Custom + AWS Metrics]
        XRay[X-Ray<br/>Distributed Tracing]
    end

    subgraph "Alerting Layer"
        CWAlarms[CloudWatch Alarms<br/>Error Rate, Latency]
        SNS[SNS Topics<br/>Email, Slack]
    end

    subgraph "Visualization Layer"
        CWDashboard[CloudWatch Dashboard<br/>Real-time Metrics]
        XRayMap[X-Ray Service Map<br/>Trace Analysis]
    end

    API --> CWLogs
    API --> CWMetrics
    Lambda --> CWLogs
    Lambda --> CWMetrics
    Lambda --> XRay
    DDB --> CWMetrics
    S3 --> CWMetrics

    CWMetrics --> CWAlarms
    CWAlarms --> SNS
    CWMetrics --> CWDashboard
    XRay --> XRayMap

    style CWDashboard fill:#4ECDC4
    style XRayMap fill:#4ECDC4
```

---

## Next Steps

1. Review deployment topology with infrastructure team
2. Test failover procedure in UAT environment
3. Configure Route 53 health checks
4. Set up Direct Connect connectivity
5. Create runbook for manual failover procedure

---

**Document Control**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-09 | Infrastructure Team | Initial deployment topology |
