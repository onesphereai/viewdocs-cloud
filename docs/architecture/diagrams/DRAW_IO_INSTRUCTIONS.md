# Draw.io Diagrams with AWS Icons - Setup Instructions

This guide explains how to create professional architecture diagrams using draw.io with official AWS Architecture Icons.

---

## Initial Setup (One-time)

### 1. Access draw.io
- Go to https://app.diagrams.net/
- Or download desktop version: https://github.com/jgraph/drawio-desktop/releases

### 2. Import AWS Icon Library

**Option A: Built-in AWS Icons (Recommended)**
1. In draw.io, click **More Shapes** (bottom left)
2. Search for "AWS 19" or scroll to find **AWS Architecture 2021**
3. Check the box next to **AWS Architecture 2021**
4. Click **Apply**

**Option B: Download Official AWS Icons**
1. Download from AWS: https://aws.amazon.com/architecture/icons/
2. In draw.io: **File** → **Open Library** → Select downloaded `.xml` file

### 3. Verify Icon Library
You should see a new section in the left panel with AWS service icons organized by category:
- Compute (Lambda, EC2, etc.)
- Database (DynamoDB, RDS, etc.)
- Networking (CloudFront, Route 53, API Gateway, etc.)
- Security (WAF, Cognito, Secrets Manager, etc.)

---

## Creating the Diagrams

### Diagram 1: High-Level Architecture (00-architecture-overview.md)

**File**: `00-high-level-architecture.drawio`

#### Layout Structure:
```
+------------------+     +--------------------------------+     +------------------+
|                  |     |        AWS Cloud               |     |   External       |
|   Users          | --> |                                | --> |   Systems        |
|  (4 personas)    |     |  Edge → API → Compute → Data   |     |  IDM, IESC, IES  |
+------------------+     +--------------------------------+     +------------------+
```

#### Steps:

1. **Create Canvas**
   - New Diagram → Blank
   - Page Setup: 1600 x 1200 px
   - Grid: 10px, Snap to Grid ON

2. **Add Title**
   - Insert → Text
   - Text: "Viewdocs Cloud - High-Level Solution Architecture"
   - Font: Arial, 24pt, Bold
   - Position: Top center

3. **Users Section** (Left)
   - Insert → Rectangle (200 x 300px)
   - Fill: Light Blue (#E1F5FF)
   - Title: "Users"
   - Add 4 user icons:
     - Search shapes for "user" or use generic person icons
     - Labels: Client Users, Client Admins, HelpDesk, ECM Admins

4. **AWS Cloud Section** (Center)
   - Insert → Rectangle (900 x 700px)
   - Fill: Light Orange (#FFF4E6)
   - Border: Dashed
   - Title: "AWS Cloud - ap-southeast-2 (Sydney)"

   **Inside AWS Cloud, create 4 horizontal layers:**

   **Layer 1: Edge & Security (Top)**
   - Rectangle (860 x 100px), Fill: Light Green (#E8F5E9)
   - Add AWS icons:
     - **CloudFront**: From AWS → Networking → CloudFront
     - **Route 53**: From AWS → Networking → Route 53
     - **WAF**: From AWS → Security → WAF

   **Layer 2: API & Auth**
   - Rectangle (860 x 100px), Fill: Light Pink (#FCE4EC)
   - Add AWS icons:
     - **API Gateway**: From AWS → Networking → API Gateway
     - **Cognito**: From AWS → Security → Cognito

   **Layer 3: Compute (Lambda Functions)**
   - Rectangle (860 x 120px), Fill: Light Yellow (#FFF3E0)
   - Add AWS icons (all from AWS → Compute → Lambda):
     - 5x Lambda icons labeled: Document Service, Search Service, Download Service, Admin Service, Comment Service
     - **Step Functions**: From AWS → Application Integration → Step Functions
     - **EventBridge**: From AWS → Application Integration → EventBridge

   **Layer 4: Data**
   - Rectangle (860 x 120px), Fill: Light Blue (#E3F2FD)
   - Add AWS icons:
     - **DynamoDB**: From AWS → Database → DynamoDB (label: "Global Tables")
     - **S3**: From AWS → Storage → S3 (label: "Bulk Downloads")
     - **Secrets Manager**: From AWS → Security → Secrets Manager
     - **CloudWatch**: From AWS → Management → CloudWatch

5. **DR Region Section** (Bottom of AWS Cloud)
   - Rectangle (860 x 80px), Fill: Light Purple (#F3E5F5)
   - Border: Dashed
   - Title: "DR Region - ap-southeast-4 (Melbourne)"
   - Add 3 AWS icons with 60% opacity:
     - DynamoDB (label: "Replica")
     - S3 (label: "Replica")
     - Lambda (label: "Standby")

6. **External Systems Section** (Right)
   - Rectangle (320 x 700px), Fill: Light Yellow (#FFFDE7)
   - Title: "External Systems & Archives"
   - Add rectangles for each system:
     - **IDM** (SAML IdP) - Blue
     - **IESC** (Cloud ECM) - Green
     - **IES** (On-Prem ECM) - Orange
     - **CMOD** (IBM Archive) - Orange
     - **FRS Proxy** - Purple
     - **HUB** (Event Bus) - Purple

7. **Add Connections**
   - Use connectors (straight arrows, 2px width):
     - Users → CloudFront (Blue, label: "HTTPS")
     - CloudFront → API Gateway (Blue)
     - API Gateway → Lambda functions (Blue)
     - Lambda → DynamoDB (Blue)
     - Lambda → IESC/IES/CMOD (Green/Orange, labels: "REST/SOAP", "Direct Connect")
     - Cognito → IDM (Pink dashed, label: "SAML Auth")
     - EventBridge → FRS (Purple, label: "Events")
     - FRS → HUB (Purple, label: "IBM MQ")
     - DynamoDB ↔ DynamoDB Replica (Purple dashed bidirectional, label: "Replication")

8. **Add Legend** (Bottom Left)
   - Rectangle (200 x 180px), Fill: Light Gray (#ECEFF1)
   - Title: "Legend"
   - Add text:
     - "Multi-tenant pool model"
     - "Cost: $2.96/tenant/month"
     - "RPO: 2 hours | RTO: 24 hours"
     - "Data Residency: Australia"

9. **Add Annotations** (Text boxes with colored backgrounds)
   - "500 concurrent users, 5-500 tenants" (Yellow, near compute layer)
   - "DynamoDB Global Tables - Continuous replication" (Light blue, near DR)

10. **Save**
    - File → Save As → `00-high-level-architecture.drawio`
    - File → Export As → PNG (for documentation)

---

### Diagram 2: Technology Stack (04-technology-architecture.md)

**File**: `04-technology-stack.drawio`

#### Layout: Layered Architecture (similar to OSI model visualization)

```
+--------------------------------------------------+
|  Frontend: Angular 17+ (S3 + CloudFront)         |
+--------------------------------------------------+
|  API Layer: API Gateway + Cognito                |
+--------------------------------------------------+
|  Compute: Node.js 20.x Lambda (TypeScript)       |
+--------------------------------------------------+
|  Data: DynamoDB Global Tables, S3, Secrets Mgr   |
+--------------------------------------------------+
|  Integration: EventBridge, Step Functions, SQS   |
+--------------------------------------------------+
|  Monitoring: CloudWatch, X-Ray                   |
+--------------------------------------------------+
```

#### AWS Icons to Use:
- **Compute**: Lambda
- **Frontend**: S3, CloudFront
- **API**: API Gateway, Cognito
- **Database**: DynamoDB
- **Storage**: S3
- **Security**: Secrets Manager, KMS
- **Integration**: EventBridge, Step Functions, SQS
- **Management**: CloudWatch, X-Ray

#### Additional Elements:
- Add technology logos (if available): Angular, TypeScript, Node.js, npm, esbuild
- Add version numbers: "Node.js 20.x", "Angular 17+", "TypeScript 5.x"
- Add badges for "AWS CDK", "Jest", "Cypress"

---

### Diagram 3: Security Architecture (05-security-architecture.md)

**File**: `05-security-architecture.drawio`

#### Layout: Security Zones

```
+--------------------+      +----------------------+      +--------------------+
| Public Zone        |      | Application Zone     |      | Data Zone          |
|                    | ---> |                      | ---> |                    |
| CloudFront + WAF   |      | Lambda + API Gateway |      | DynamoDB + S3      |
+--------------------+      +----------------------+      +--------------------+
         |                           |                            |
         v                           v                            v
    [ TLS 1.2+ ]            [ JWT + ACL Checks ]        [ KMS Encryption ]
```

#### Key Elements:

1. **Authentication Flow Diagram**
   - User → CloudFront → Cognito → IDM (SAML) → JWT Token
   - Use sequence diagram layout (vertical flow)

2. **Security Layers**
   - **Edge Security**: WAF, CloudFront (DDoS protection)
   - **API Security**: API Gateway (throttling), Cognito (JWT validation)
   - **Application Security**: Lambda (ACL checks, input validation)
   - **Data Security**: DynamoDB encryption (KMS), S3 encryption (KMS)

3. **AWS Icons**:
   - **WAF**, **CloudFront**, **Shield** (DDoS protection)
   - **Cognito**, **IAM**, **Secrets Manager**, **KMS**
   - **GuardDuty** (threat detection)
   - **CloudTrail** (audit logging)

4. **Security Controls** (Text annotations):
   - "TLS 1.2+ in transit"
   - "AES-256 at rest"
   - "SAML 2.0 + MFA"
   - "6-month audit retention"

---

### Diagram 4: Deployment Architecture (06-deployment-architecture.md)

**File**: `06-blue-green-deployment.drawio`

#### Layout: Blue-Green Deployment Visualization

```
                    Route 53
                       |
         +-------------+-------------+
         |                           |
    [Blue Environment]        [Green Environment]
         |                           |
    API Gateway v1.2.3          API Gateway v1.3.0
         |                           |
    Lambda v1.2.3               Lambda v1.3.0
         |                           |
         +-------------+-------------+
                       |
                  DynamoDB
                  (shared)
```

#### AWS Icons:
- **Route 53** (with health check icon)
- **API Gateway** (2 instances: blue and green)
- **Lambda** (2 versions)
- **DynamoDB** (shared)
- **CloudWatch** (monitoring both environments)

#### Additional Elements:
- Use different colors for blue (existing) and green (new) environments
- Add percentage labels: "100% traffic" → "0% traffic" → "100% traffic"
- Add timeline arrows showing gradual rollout: 10% → 25% → 50% → 100%

---

### Diagram 5: Multi-Region Deployment (06-deployment-architecture.md)

**File**: `06-multi-region-topology.drawio`

#### Layout: Side-by-side regions

```
+-------------------------+          +-------------------------+
| ap-southeast-2 (Primary)|          | ap-southeast-4 (DR)     |
|                         |   <-->   |                         |
| Full Stack              |          | Standby Stack           |
+-------------------------+          +-------------------------+
              |                                  |
              +----------Route 53----------------+
                      (Health Check)
```

#### AWS Icons:
- **Primary Region**: Full set (API Gateway, Lambda, DynamoDB, S3, etc.)
- **DR Region**: Same icons but with 60% opacity (standby)
- **Route 53**: At the top with health check notation
- **DynamoDB**: Show bidirectional replication arrow between regions
- **S3**: Show unidirectional replication arrow (Primary → DR)

---

## Tips for Professional Diagrams

### Color Scheme (AWS-style)
- **Compute**: Orange (#FF9900)
- **Networking**: Purple (#945DF2)
- **Database**: Blue (#3334B9)
- **Storage**: Green (#277116)
- **Security**: Red (#C7131F)
- **Analytics**: Yellow (#FFC107)

### Layout Best Practices
1. **Alignment**: Use draw.io's alignment tools (Arrange → Align)
2. **Spacing**: Keep consistent spacing between elements (20-40px)
3. **Grouping**: Group related elements (Ctrl+G / Cmd+G)
4. **Layers**: Use layers for complex diagrams (View → Layers)
5. **Connectors**: Use orthogonal or straight connectors (avoid curved)
6. **Labels**: Keep labels concise, use tooltips for details

### Exporting
1. **PNG**: File → Export As → PNG (300 DPI for high quality)
2. **SVG**: File → Export As → SVG (for scalable graphics)
3. **PDF**: File → Export As → PDF (for printing)

### Version Control
- Save `.drawio` files in `/docs/architecture/diagrams/`
- Export PNG/SVG to same directory
- Include both in Git for version tracking

---

## Quick Reference: AWS Icon Locations

| Service | Category | Icon Name |
|---------|----------|-----------|
| Lambda | Compute | Lambda |
| API Gateway | Networking & Content Delivery | API Gateway |
| DynamoDB | Database | DynamoDB |
| S3 | Storage | Simple Storage Service (S3) |
| CloudFront | Networking & Content Delivery | CloudFront |
| Route 53 | Networking & Content Delivery | Route 53 |
| Cognito | Security, Identity & Compliance | Cognito |
| WAF | Security, Identity & Compliance | WAF |
| Secrets Manager | Security, Identity & Compliance | Secrets Manager |
| KMS | Security, Identity & Compliance | Key Management Service |
| CloudWatch | Management & Governance | CloudWatch |
| X-Ray | Developer Tools | X-Ray |
| EventBridge | Application Integration | EventBridge |
| Step Functions | Application Integration | Step Functions |
| SQS | Application Integration | Simple Queue Service |

---

## Next Steps

1. Start with **00-high-level-architecture.drawio** (most important)
2. Create **05-security-architecture.drawio** (authentication flow)
3. Create **06-blue-green-deployment.drawio** (deployment strategy)
4. Create **04-technology-stack.drawio** (technology layers)
5. Export all diagrams to PNG (300 DPI)
6. Update markdown files to reference PNG files

---

**Need Help?**
- draw.io documentation: https://www.drawio.com/doc/
- AWS Architecture Icons guide: https://aws.amazon.com/architecture/icons/
- Community examples: https://www.drawio.com/blog/aws-diagrams
