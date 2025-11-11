# Application Architecture - draw.io Diagram (Enhanced with Security & Flows)

This document provides the draw.io XML for the complete Logical Application Architecture diagram with AWS components, security layers, and numbered flow labels.

---

## Quick Start

### Option 1: Import XML Directly (RECOMMENDED)
1. Go to https://app.diagrams.net/
2. Click **File → Import from → Text**
3. Scroll down to the XML section
4. Copy the entire XML content and paste it
5. Click **Import**
6. The complete diagram will be created automatically!

### Option 2: Manual Creation with AWS Icons
Follow the step-by-step instructions below to build the diagram manually.

---

## What's Included in This Diagram

### Architectural Layers (9 layers):
1. **User Layer** - End users (browser/mobile)
2. **Security & CDN Layer** - Route 53, WAF, CloudFront, Shield
3. **Presentation Layer** - S3 static hosting
4. **API & Auth Layer** - API Gateway, Cognito
5. **Application Services** - 8 Lambda functions
6. **Orchestration & Events** - Step Functions, EventBridge, SQS
7. **Data & Storage** - DynamoDB, S3, Secrets Manager
8. **Monitoring & Security** - CloudWatch, X-Ray, GuardDuty, KMS
9. **External Systems** - IESC, IES, CMOD, FRS, MailRoom

### Flow Labels (17 numbered flows):
- **1-5**: User → Route 53 → WAF → Shield → CloudFront (security flow)
- **6-7**: CloudFront → S3 static assets & API Gateway
- **8-10**: API Gateway → Cognito → Lambda services
- **11**: Document Service flows (ACLs, fetch docs, events)
- **12**: Search Service flows
- **13**: Download Service flows (Step Functions, SQS)
- **14**: Comment & Admin Service flows
- **15**: Auth Service flows
- **16**: Event Service flows (EventBridge → FRS)
- **17**: MailRoom Wrapper flows

### Security Components:
- WAF (Web Application Firewall)
- Shield Standard (DDoS Protection)
- Route 53 (DNS + Health Checks)
- CloudWatch (Monitoring)
- X-Ray (Tracing)
- GuardDuty (Threat Detection)
- KMS (Encryption)

---

## draw.io XML (Ready to Import)

**NOTE**: This is a simplified XML structure. For a complete production diagram, I recommend following the manual instructions below which give you full control over positioning and styling.

```xml
<mxfile host="app.diagrams.net">
  <diagram name="Application Architecture - Enhanced" id="app-arch-enhanced">
    <mxGraphModel dx="2200" dy="1400" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1600" pageHeight="2400" math="0" shadow="0">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />

        <!-- Title -->
        <mxCell id="title" value="Viewdocs Cloud - Application Architecture with Security &amp; Monitoring" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;whiteSpace=wrap;rounded=0;fontSize=20;fontStyle=1;fontColor=#232F3E;" vertex="1" parent="1">
          <mxGeometry x="400" y="20" width="800" height="40" as="geometry" />
        </mxCell>

        <!-- Legend -->
        <mxCell id="legend-box" value="" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#ffffff;strokeColor=#232F3E;strokeWidth=2;" vertex="1" parent="1">
          <mxGeometry x="40" y="80" width="300" height="180" as="geometry" />
        </mxCell>
        <mxCell id="legend-title" value="Color Legend" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=top;whiteSpace=wrap;rounded=0;fontSize=14;fontStyle=1;fontColor=#232F3E;" vertex="1" parent="1">
          <mxGeometry x="50" y="90" width="280" height="30" as="geometry" />
        </mxCell>
        <mxCell id="legend-compute" value="Compute (Lambda)" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#FF9900;strokeColor=#232F3E;fontColor=#232F3E;fontSize=11;" vertex="1" parent="1">
          <mxGeometry x="60" y="130" width="120" height="30" as="geometry" />
        </mxCell>
        <mxCell id="legend-security" value="Security" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#DD344C;strokeColor=#232F3E;fontColor=#ffffff;fontSize=11;" vertex="1" parent="1">
          <mxGeometry x="200" y="130" width="120" height="30" as="geometry" />
        </mxCell>
        <mxCell id="legend-data" value="Data &amp; Storage" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#3F8624;strokeColor=#232F3E;fontColor=#ffffff;fontSize=11;" vertex="1" parent="1">
          <mxGeometry x="60" y="170" width="120" height="30" as="geometry" />
        </mxCell>
        <mxCell id="legend-integration" value="Integration" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#527FFF;strokeColor=#232F3E;fontColor=#ffffff;fontSize=11;" vertex="1" parent="1">
          <mxGeometry x="200" y="170" width="120" height="30" as="geometry" />
        </mxCell>
        <mxCell id="legend-monitoring" value="Monitoring" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#759C3E;strokeColor=#232F3E;fontColor=#ffffff;fontSize=11;" vertex="1" parent="1">
          <mxGeometry x="60" y="210" width="120" height="30" as="geometry" />
        </mxCell>
        <mxCell id="legend-external" value="External Systems" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#879196;strokeColor=#232F3E;fontColor=#ffffff;fontSize=11;" vertex="1" parent="1">
          <mxGeometry x="200" y="210" width="120" height="30" as="geometry" />
        </mxCell>

        <!-- NOTE TO USER -->
        <mxCell id="note-to-user" value="⚠️ SIMPLIFIED XML - For best results, follow the manual instructions below to create the complete diagram with proper AWS icons, precise positioning, and all 17 numbered flow arrows." style="rounded=1;whiteSpace=wrap;html=1;fillColor=#fff9c4;strokeColor=#f57f17;strokeWidth=2;fontSize=12;fontStyle=1;fontColor=#232F3E;align=left;verticalAlign=top;" vertex="1" parent="1">
          <mxGeometry x="400" y="80" width="1120" height="80" as="geometry" />
        </mxCell>

      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

---

## Manual Creation Instructions (RECOMMENDED for Production Quality)

### Step 1: Set Up draw.io with AWS Architecture Icons
1. Go to https://app.diagrams.net/
2. Create a new diagram (Blank Diagram)
3. Enable AWS icon libraries:
   - Click **More Shapes...** (bottom left)
   - Search for "AWS 19"
   - Enable **AWS 19** library
   - Also enable **AWS 17** (for some legacy icons)
   - Click **Apply**
4. Set canvas size:
   - **File → Page Setup**
   - Set to **A3 Landscape** or custom **1600 x 2400 px**

### Step 2: Create the Layer Structure (9 Swimlanes)

Create vertical swimlanes from top to bottom. Use **Container** shape for each:

#### Layer 1: User Layer
- **Height**: 100px
- **Fill Color**: #f5f5f5 (light grey)
- **Border**: #232F3E (AWS dark grey), 2px
- **Title**: "User Layer"

#### Layer 2: Security & CDN Layer
- **Height**: 140px
- **Fill Color**: #ffebee (light red)
- **Border**: #c62828 (red), 2px
- **Title**: "Security & CDN Layer"

#### Layer 3: Presentation Layer
- **Height**: 120px
- **Fill Color**: #e3f2fd (light blue)
- **Border**: #1976d2 (blue), 2px
- **Title**: "Presentation Layer"

#### Layer 4: API & Auth Layer
- **Height**: 140px
- **Fill Color**: #fff3e0 (light orange)
- **Border**: #e65100 (orange), 2px
- **Title**: "API & Auth Layer"

#### Layer 5: Application Services - Lambda Functions
- **Height**: 200px
- **Fill Color**: #fff3e0 (light orange)
- **Border**: #ff6f00 (deep orange), 2px
- **Title**: "Application Services - Lambda Functions"

#### Layer 6: Orchestration & Events
- **Height**: 140px
- **Fill Color**: #e8eaf6 (light indigo)
- **Border**: #3f51b5 (indigo), 2px
- **Title**: "Orchestration & Events"

#### Layer 7: Data & Storage Layer
- **Height**: 140px
- **Fill Color**: #e8f5e9 (light green)
- **Border**: #2e7d32 (green), 2px
- **Title**: "Data & Storage Layer"

#### Layer 8: Monitoring & Security
- **Height**: 140px
- **Fill Color**: #f3e5f5 (light purple)
- **Border**: #6a1b9a (purple), 2px
- **Title**: "Monitoring & Security"

#### Layer 9: External Systems
- **Height**: 140px
- **Fill Color**: #eceff1 (light grey)
- **Border**: #546e7a (grey), 2px
- **Title**: "External Systems"

### Step 3: Add AWS Components to Each Layer

#### Layer 1: User Layer
**Component**: User icon (person)
- Use generic person/user icon from draw.io
- **Label**: "End Users (Browser/Mobile)"
- **Style**: Simple icon or rounded rectangle

#### Layer 2: Security & CDN Layer
Add 4 AWS components horizontally:

1. **Route 53**
   - AWS Icon: Search "Route 53" → use Route 53 icon
   - **Label**: "Route 53\nDNS + Health Checks\nFailover Routing"
   - **Color**: Blue (#527FFF)

2. **WAF**
   - AWS Icon: Search "WAF" → use AWS WAF icon
   - **Label**: "WAF\nWeb Application Firewall\nRate Limiting | IP Filtering"
   - **Color**: Red (#DD344C)

3. **CloudFront**
   - AWS Icon: Search "CloudFront" → use CloudFront Distribution icon
   - **Label**: "CloudFront CDN\nEdge Locations\nTLS 1.2+ | HTTPS Only"
   - **Color**: Blue (#527FFF)

4. **Shield Standard**
   - AWS Icon: Search "Shield" → use AWS Shield icon
   - **Label**: "Shield Standard\nDDoS Protection\nAlways On"
   - **Color**: Red (#DD344C)

#### Layer 3: Presentation Layer
**Component**: S3 Bucket
- AWS Icon: S3
- **Label**: "S3 Bucket\nStatic Website Hosting\nAngular SPA | Versioned"
- **Color**: Green (#3F8624)

#### Layer 4: API & Auth Layer
Add 2 components:

1. **API Gateway**
   - AWS Icon: API Gateway
   - **Label**: "API Gateway\nREST API\nThrottling: 10K RPS"
   - **Color**: Blue (#527FFF)

2. **Cognito User Pool**
   - AWS Icon: Cognito
   - **Label**: "Cognito\nUser Pool\nSAML 2.0 | MFA"
   - **Color**: Red (#DD344C)

#### Layer 5: Application Services - Lambda Functions
Add 8 Lambda functions horizontally. For each, use AWS Lambda icon (#FF9900):

1. **Document Service**
   - Label: "Document Service\nNode.js 20.x\n512MB | 29s | Concurrency: 100"

2. **Search Service**
   - Label: "Search Service\nNode.js 20.x\n512MB | 29s | Concurrency: 100"

3. **Download Service**
   - Label: "Download Service\nNode.js 20.x\n256MB | 15s | Concurrency: 50"

4. **Comment Service**
   - Label: "Comment Service\nNode.js 20.x\n256MB | 10s | Concurrency: 50"

5. **Admin Service**
   - Label: "Admin Service\nNode.js 20.x\n512MB | 15s | Concurrency: 10"

6. **Auth Service**
   - Label: "Auth Service\nNode.js 20.x\n256MB | 10s | Concurrency: 50"

7. **Event Service**
   - Label: "Event Service\nNode.js 20.x\n256MB | 5s | Concurrency: 50"

8. **MailRoom Wrapper**
   - Label: "MailRoom Wrapper\nNode.js 20.x\n512MB | 29s | Concurrency: 50"
   - **Special styling**: Add red border stroke (#C92A2A, width 3px)

#### Layer 6: Orchestration & Events
Add 3 components:

1. **Step Functions**
   - AWS Icon: Step Functions
   - Label: "Step Functions\nBulk Download Workflow\nMax Duration: 15min"
   - Color: Blue (#527FFF)

2. **EventBridge**
   - AWS Icon: EventBridge
   - Label: "EventBridge\nEvent Bus\nSchema Registry"
   - Color: Blue (#527FFF)

3. **SQS**
   - AWS Icon: SQS
   - Label: "SQS Queue\nDownload Jobs\nFIFO | DLQ Enabled"
   - Color: Blue (#527FFF)

#### Layer 7: Data & Storage Layer
Add 3 components:

1. **DynamoDB**
   - AWS Icon: DynamoDB
   - Label: "DynamoDB\nGlobal Tables\nConfig | ACLs | Audit\nEncrypted at Rest (KMS)"
   - Color: Green (#3F8624)

2. **S3 Buckets**
   - AWS Icon: S3
   - Label: "S3 Buckets\nBulk Downloads\n72h Lifecycle | Encrypted"
   - Color: Green (#3F8624)

3. **Secrets Manager**
   - AWS Icon: Secrets Manager
   - Label: "Secrets Manager\nArchive Credentials\nAuto-rotation 90d | KMS"
   - Color: Red (#DD344C)

#### Layer 8: Monitoring & Security
Add 4 components:

1. **CloudWatch**
   - AWS Icon: CloudWatch
   - Label: "CloudWatch\nLogs + Metrics\nAlarms"
   - Color: Olive Green (#759C3E)

2. **X-Ray**
   - AWS Icon: X-Ray
   - Label: "X-Ray\nDistributed Tracing\nPerformance Analysis"
   - Color: Olive Green (#759C3E)

3. **GuardDuty**
   - AWS Icon: GuardDuty
   - Label: "GuardDuty\nThreat Detection\nContinuous Monitoring"
   - Color: Red (#DD344C)

4. **KMS**
   - AWS Icon: KMS (Key Management Service)
   - Label: "KMS\nEncryption Keys\nAuto-rotation"
   - Color: Red (#DD344C)

#### Layer 9: External Systems
Create 5 rounded rectangles (grey fill #879196):

1. **IESC**
   - Label: "IESC\nREST API\nTLS 1.2+"

2. **IES**
   - Label: "IES\nSOAP API\nDirect Connect + IPsec"

3. **CMOD**
   - Label: "CMOD\nSOAP API\nDirect Connect + IPsec"

4. **FRS Proxy**
   - Label: "FRS Proxy\nSOAP API\nDirect Connect + IPsec"

5. **MailRoom Backend**
   - Label: "MailRoom Backend\nREST API\nIndependent Platform"

### Step 4: Add Arrows with Numbered Labels

**IMPORTANT**: Use solid arrows (→) for data flow and dashed arrows (⋯>) for validation/monitoring.

#### Flow Group 1: User to Security (Steps 1-5)

1. **User → Route 53**
   - Arrow: Solid blue
   - Label: "**1.** DNS Query"
   - Style: Arrow end, stroke width 2px

2. **Route 53 → CloudFront**
   - Arrow: Solid blue
   - Label: "**2.** Resolve to CloudFront"

3. **User → WAF**
   - Arrow: Solid blue
   - Label: "**3.** HTTPS Request"

4. **WAF → Shield**
   - Arrow: Solid red
   - Label: "**4.** Filter Threats"

5. **Shield → CloudFront**
   - Arrow: Solid blue
   - Label: "**5.** Allow Traffic"

#### Flow Group 2: CloudFront to Services (Steps 6-7)

6. **CloudFront → S3 Static**
   - Arrow: Solid blue
   - Label: "**6.** Serve Static Assets"

7. **CloudFront → API Gateway**
   - Arrow: Solid blue
   - Label: "**7.** Proxy API Requests\nHTTPS + JWT Bearer"

#### Flow Group 3: API Gateway to Auth & Lambda (Steps 8-10)

8. **API Gateway → Cognito**
   - Arrow: Dashed red (validation)
   - Label: "**8.** Validate JWT"

9. **Cognito → API Gateway** (return arrow)
   - Arrow: Dashed red
   - Label: "**9.** Token Valid\nReturn User Claims"

10. **API Gateway → All 8 Lambda Functions**
    - Create 8 arrows (one to each Lambda)
    - Labels: "**10a.** Invoke Lambda (Sync)", "**10b.** Invoke Lambda (Sync)", etc.
    - Arrow: Solid orange

#### Flow Group 4: Document Service (Step 11)

11a. **Document Service → DynamoDB**
    - Label: "**11a.** Query ACLs\nWrite Audit Logs"
    - Arrow: Solid orange → green

11b. **Document Service → IESC**
    - Label: "**11b.** Fetch Document\nREST HTTPS"
    - Arrow: Solid orange → grey

11c. **Document Service → IES**
    - Label: "**11c.** Fetch Document\nSOAP over IPsec"
    - Arrow: Solid orange → grey

11d. **Document Service → CMOD**
    - Label: "**11d.** Fetch Document\nSOAP over IPsec"
    - Arrow: Solid orange → grey

11e. **Document Service → EventBridge**
    - Label: "**11e.** Publish Event\nDocumentViewed"
    - Arrow: Solid orange → blue

11f. **Document Service → Secrets Manager**
    - Label: "**11f.** Get Archive Credentials\nEncrypted"
    - Arrow: Solid orange → red

#### Flow Group 5: Search Service (Step 12)

12a. **Search Service → DynamoDB**
    - Label: "**12a.** Query User ACLs\nFilter Folders"

12b. **Search Service → IESC**
    - Label: "**12b.** Search Index\nREST HTTPS"

12c. **Search Service → IES**
    - Label: "**12c.** Search Index\nSOAP over IPsec"

12d. **Search Service → CMOD**
    - Label: "**12d.** Search Index\nSOAP over IPsec"

12e. **Search Service → Secrets Manager**
    - Label: "**12e.** Get Credentials\nDecrypt"

#### Flow Group 6: Download Service (Step 13)

13a. **Download Service → Step Functions**
    - Label: "**13a.** Start Execution\nAsync Workflow"

13b. **Download Service → DynamoDB**
    - Label: "**13b.** Query Job Status"

13c. **Step Functions → SQS**
    - Label: "**13c.** Enqueue Jobs\nFan-out per Doc"

13d. **SQS → Document Service**
    - Label: "**13d.** Trigger Worker\nEvent Source Mapping"

13e. **Document Service → S3 Buckets**
    - Label: "**13e.** Upload Zip File\nServer-side Encryption"

#### Flow Group 7: Comment & Admin Services (Step 14)

14a. **Comment Service → DynamoDB**
    - Label: "**14a.** CRUD Comments\nVersioned"

14b. **Admin Service → DynamoDB**
    - Label: "**14b.** Manage Tenants\nCreate/Update ACLs"

14c. **Admin Service → Secrets Manager**
    - Label: "**14c.** Store Credentials\nEncrypt with KMS"

#### Flow Group 8: Auth Service (Step 15)

15a. **Auth Service → Cognito**
    - Label: "**15a.** Token Refresh\nSAML Callback"

15b. **Auth Service → DynamoDB**
    - Label: "**15b.** Store Session Metadata"

#### Flow Group 9: Event Service (Step 16)

16a. **EventBridge → Event Service**
    - Label: "**16a.** Rule Trigger\nEvent Pattern Match"

16b. **Event Service → FRS Proxy**
    - Label: "**16b.** Forward to HUB\nSOAP over IPsec"

#### Flow Group 10: MailRoom Wrapper (Step 17)

17a. **MailRoom Wrapper → DynamoDB**
    - Label: "**17a.** Check ACLs\nWrite Audit Logs"

17b. **MailRoom Wrapper → MailRoom Backend**
    - Label: "**17b.** Forward Request\nREST HTTPS + tenant_id"

#### Monitoring & Security Flows (Dotted Lines)

**All Lambda Functions → CloudWatch**
- Arrow: Dashed olive green
- Label: "Logs"

**Key Services → X-Ray**
- Document Service → X-Ray: "Traces"
- Search Service → X-Ray: "Traces"
- API Gateway → X-Ray: "Traces"
- Arrow: Dashed olive green

**Encrypted Services → KMS**
- DynamoDB → KMS: "Encrypt/Decrypt"
- S3 → KMS: "Encrypt/Decrypt"
- Secrets Manager → KMS: "Encrypt/Decrypt"
- Arrow: Dashed red

**GuardDuty → CloudWatch**
- Label: "Monitor Threats\nVPC Flow Logs"
- Arrow: Dashed red

### Step 5: Formatting & Styling

#### Arrow Styles:
- **Solid arrows**: Data flow (stroke width 2px)
- **Dashed arrows**: Validation, monitoring (stroke width 1.5px, dash pattern)
- **Arrow heads**: Standard triangle
- **Arrow colors**: Match the source component color

#### Text Labels:
- **Flow labels**: Bold numbered format (**1.**, **2.**, etc.)
- **Font**: Arial or Helvetica, 10pt for labels, 12pt for component text
- **Label position**: Middle of arrow (centered)

#### Component Sizing:
- **AWS icons**: 78x78 pixels (standard)
- **Lambda functions**: Uniform 78x78 pixels
- **Spacing**: 40-50px between components horizontally, 40px vertically between layers

#### Color Consistency:
Use the color palette defined at the top:
- Compute: #FF9900
- Security: #DD344C
- Data: #3F8624
- Integration: #527FFF
- Monitoring: #759C3E
- External: #879196

### Step 6: Add Legend and Title

#### Title Box (Top of diagram):
- Text: "Viewdocs Cloud - Application Architecture with Security & Monitoring"
- Font: 18-20pt, Bold
- Position: Centered at top

#### Legend Box (Top-right corner):
Create a rounded rectangle with color samples:
- Compute (Lambda): Orange square
- Security: Red square
- Data & Storage: Green square
- Integration: Blue square
- Monitoring: Olive green square
- External Systems: Grey square

### Step 7: Export Options

1. **PNG Export** (for documentation):
   - **File → Export as → PNG**
   - Resolution: 300 DPI
   - Transparent background: No
   - Include a border: Yes (10px)
   - Save as: `application-architecture-enhanced.png`

2. **SVG Export** (for websites):
   - **File → Export as → SVG**
   - Embedded fonts: Yes
   - Save as: `application-architecture-enhanced.svg`

3. **PDF Export** (for presentations):
   - **File → Export as → PDF**
   - Include: All pages
   - Save as: `application-architecture-enhanced.pdf`

4. **Save draw.io file**:
   - **File → Save as**
   - Save as: `application-architecture-enhanced.drawio`
   - Also save to repository: `docs/architecture/diagrams/application-architecture-enhanced.drawio`

---

## Diagram Layout Best Practices

### Visual Hierarchy:
1. **Top to Bottom**: User flow from entry point to data storage
2. **Left to Right**: Service dependencies (Lambda → Data stores)
3. **Color Coding**: Immediate visual identification of service types

### Flow Clarity:
1. **Numbered Flows**: Easy to follow end-to-end request journey
2. **Grouped Arrows**: Related flows grouped together (e.g., all Document Service flows)
3. **Label Positioning**: Labels on top/side of arrows, never crossing components

### Spacing:
- **Between layers**: 40-50px vertical spacing
- **Between components**: 40-50px horizontal spacing
- **Arrow clearance**: Minimum 20px from component edges

### Alignment:
- Use **Align** tools (Ctrl+Shift+A) to align components horizontally
- Use **Distribute** tools to evenly space components
- Enable **Grid** (10px) for precise positioning

---

## Flow Summary Reference

### Security Flow (1-5):
User → Route 53 → WAF → Shield → CloudFront

### Content Delivery Flow (6-7):
CloudFront → S3 Static / API Gateway

### Authentication Flow (8-9):
API Gateway ↔ Cognito (JWT validation)

### Service Invocation Flow (10):
API Gateway → All 8 Lambda functions

### Service-Specific Flows (11-17):
- **11**: Document Service (6 sub-flows)
- **12**: Search Service (5 sub-flows)
- **13**: Download Service (5 sub-flows)
- **14**: Comment & Admin Services (3 sub-flows)
- **15**: Auth Service (2 sub-flows)
- **16**: Event Service (2 sub-flows)
- **17**: MailRoom Wrapper (2 sub-flows)

### Monitoring Flows (Dotted):
- Lambda → CloudWatch (logs)
- Services → X-Ray (traces)
- Data → KMS (encryption)
- GuardDuty → CloudWatch (threats)

---

## Color Reference Table

| Component Type | Fill Color | Hex Code | Stroke | Usage |
|----------------|-----------|----------|--------|-------|
| User Layer | Grey | #f5f5f5 | #232F3E | End users |
| Lambda (Compute) | Orange | #FF9900 | #232F3E | All Lambda functions |
| Data Services | Green | #3F8624 | #232F3E | DynamoDB, S3 |
| Integration | Blue | #527FFF | #232F3E | API Gateway, CloudFront, EventBridge, SQS, Route 53 |
| Security | Red | #DD344C | #232F3E | WAF, Shield, Cognito, Secrets Manager, GuardDuty, KMS |
| Monitoring | Olive Green | #759C3E | #232F3E | CloudWatch, X-Ray |
| External Systems | Grey | #879196 | #232F3E | IESC, IES, CMOD, FRS, MailRoom |
| MailRoom Wrapper | Orange | #FF9900 | #C92A2A (thick 3px) | Special highlight |

---

## Tips for Large Diagrams

1. **Use Layers** in draw.io:
   - Separate layer for components
   - Separate layer for arrows/flows
   - Separate layer for labels
   - Makes editing easier without accidentally moving components

2. **Group Related Components**:
   - Right-click → Group (Ctrl+G)
   - Makes it easier to move entire layers

3. **Use Guides**:
   - Drag from rulers to create alignment guides
   - Helps maintain consistent spacing

4. **Save Frequently**:
   - Auto-save enabled by default
   - Manual save: Ctrl+S

5. **Zoom Navigation**:
   - Ctrl + Mouse Wheel to zoom in/out
   - Ctrl + 0 to fit to window

---

## Troubleshooting

### Issue: AWS icons not showing
**Solution**: Make sure AWS 19 library is enabled in More Shapes

### Issue: Arrows overlapping
**Solution**: Use waypoints (click arrow, drag control points) to route around components

### Issue: Labels too small
**Solution**: Select all labels, increase font size to 11-12pt

### Issue: Export image quality low
**Solution**: Use 300 DPI for PNG export, or export as SVG for vector graphics

### Issue: Diagram too large for page
**Solution**: File → Page Setup → Fit to window, or use A3/A2 paper size

---

## Final Checklist

Before finalizing your diagram:

- [ ] All 9 layers created with correct colors
- [ ] All AWS icons properly sized (78x78px)
- [ ] All 8 Lambda functions added with specs
- [ ] All security components added (WAF, Shield, GuardDuty, KMS)
- [ ] All monitoring components added (CloudWatch, X-Ray)
- [ ] All 17 numbered flows added with labels
- [ ] Dotted lines for monitoring flows added
- [ ] Color coding consistent with legend
- [ ] Title and legend added
- [ ] Components properly aligned and spaced
- [ ] Arrow labels readable and non-overlapping
- [ ] Exported as PNG (300 DPI) and SVG
- [ ] Saved .drawio file to repository

---

**Document Control**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-01-11 | Architecture Team | Initial draw.io specification |
| 2.0 | 2025-01-11 | Architecture Team | Enhanced with security components (WAF, Shield, GuardDuty, KMS), monitoring (CloudWatch, X-Ray), and 17 numbered flow labels |

---

## Repository Location

Save the completed diagram to:
- `docs/architecture/diagrams/application-architecture-enhanced.drawio` (source file)
- `docs/architecture/diagrams/application-architecture-enhanced.png` (rendered image)
- `docs/architecture/diagrams/application-architecture-enhanced.svg` (vector format)
