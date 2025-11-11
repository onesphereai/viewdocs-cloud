# Application Architecture - draw.io Diagram

This document provides the draw.io XML for the Logical Application Architecture diagram with AWS components.

---

## Quick Start

### Option 1: Import XML Directly
1. Go to https://app.diagrams.net/
2. Click **File → Import from → Text**
3. Copy the entire XML content below and paste it
4. Click **Import**

### Option 2: Manual Creation with AWS Icons
1. Go to https://app.diagrams.net/
2. Click **File → Open Library from → URL**
3. Enter: `https://github.com/aws/aws-icons-for-plantuml/raw/main/AWSSymbols.xml`
4. Follow the step-by-step instructions below

---

## draw.io XML (Ready to Import)

```xml
<mxfile host="app.diagrams.net">
  <diagram name="Application Architecture" id="application-arch">
    <mxGraphModel dx="1422" dy="794" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1169" pageHeight="1654" math="0" shadow="0">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />

        <!-- Presentation Layer -->
        <mxCell id="layer-presentation" value="Presentation Layer" style="swimlane;whiteSpace=wrap;html=1;fillColor=#e3f2fd;strokeColor=#1976d2;fontStyle=1;fontSize=14;" vertex="1" parent="1">
          <mxGeometry x="80" y="40" width="1000" height="120" as="geometry" />
        </mxCell>
        <mxCell id="cloudfront" value="CloudFront CDN&#xa;+ S3 Angular SPA" style="sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#527FFF;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.cloudfront_distribution;" vertex="1" parent="layer-presentation">
          <mxGeometry x="440" y="40" width="120" height="60" as="geometry" />
        </mxCell>

        <!-- API & Auth Layer -->
        <mxCell id="layer-api" value="API &amp; Auth Layer" style="swimlane;whiteSpace=wrap;html=1;fillColor=#fff3e0;strokeColor=#e65100;fontStyle=1;fontSize=14;" vertex="1" parent="1">
          <mxGeometry x="80" y="180" width="1000" height="140" as="geometry" />
        </mxCell>
        <mxCell id="api-gateway" value="API Gateway&#xa;REST API" style="sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#527FFF;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.api_gateway;" vertex="1" parent="layer-api">
          <mxGeometry x="280" y="40" width="78" height="78" as="geometry" />
        </mxCell>
        <mxCell id="cognito" value="Cognito&#xa;User Pool&#xa;SAML 2.0" style="sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#DD344C;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.cognito;" vertex="1" parent="layer-api">
          <mxGeometry x="640" y="40" width="78" height="78" as="geometry" />
        </mxCell>

        <!-- Application Services Layer -->
        <mxCell id="layer-services" value="Application Services - Lambda Functions" style="swimlane;whiteSpace=wrap;html=1;fillColor=#fff3e0;strokeColor=#ff6f00;fontStyle=1;fontSize=14;" vertex="1" parent="1">
          <mxGeometry x="80" y="340" width="1000" height="180" as="geometry" />
        </mxCell>
        <mxCell id="lambda-doc" value="Document Service&#xa;Node.js 20.x&#xa;512MB | 29s" style="sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#FF9900;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=11;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.lambda_function;" vertex="1" parent="layer-services">
          <mxGeometry x="40" y="50" width="78" height="78" as="geometry" />
        </mxCell>
        <mxCell id="lambda-search" value="Search Service&#xa;Node.js 20.x&#xa;512MB | 29s" style="sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#FF9900;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=11;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.lambda_function;" vertex="1" parent="layer-services">
          <mxGeometry x="160" y="50" width="78" height="78" as="geometry" />
        </mxCell>
        <mxCell id="lambda-download" value="Download Service&#xa;Node.js 20.x&#xa;256MB | 15s" style="sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#FF9900;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=11;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.lambda_function;" vertex="1" parent="layer-services">
          <mxGeometry x="280" y="50" width="78" height="78" as="geometry" />
        </mxCell>
        <mxCell id="lambda-comment" value="Comment Service&#xa;Node.js 20.x&#xa;256MB | 10s" style="sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#FF9900;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=11;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.lambda_function;" vertex="1" parent="layer-services">
          <mxGeometry x="400" y="50" width="78" height="78" as="geometry" />
        </mxCell>
        <mxCell id="lambda-admin" value="Admin Service&#xa;Node.js 20.x&#xa;512MB | 15s" style="sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#FF9900;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=11;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.lambda_function;" vertex="1" parent="layer-services">
          <mxGeometry x="520" y="50" width="78" height="78" as="geometry" />
        </mxCell>
        <mxCell id="lambda-auth" value="Auth Service&#xa;Node.js 20.x&#xa;256MB | 10s" style="sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#FF9900;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=11;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.lambda_function;" vertex="1" parent="layer-services">
          <mxGeometry x="640" y="50" width="78" height="78" as="geometry" />
        </mxCell>
        <mxCell id="lambda-event" value="Event Service&#xa;Node.js 20.x&#xa;256MB | 5s" style="sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#FF9900;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=11;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.lambda_function;" vertex="1" parent="layer-services">
          <mxGeometry x="760" y="50" width="78" height="78" as="geometry" />
        </mxCell>
        <mxCell id="lambda-mailroom" value="MailRoom Wrapper&#xa;Node.js 20.x&#xa;512MB | 29s" style="sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;gradientColor=#FF6B6B;fillColor=#FF9900;strokeColor=#C92A2A;strokeWidth=2;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=11;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.lambda_function;" vertex="1" parent="layer-services">
          <mxGeometry x="880" y="50" width="78" height="78" as="geometry" />
        </mxCell>

        <!-- Orchestration & Events Layer -->
        <mxCell id="layer-orchestration" value="Orchestration &amp; Events" style="swimlane;whiteSpace=wrap;html=1;fillColor=#e8eaf6;strokeColor=#3f51b5;fontStyle=1;fontSize=14;" vertex="1" parent="1">
          <mxGeometry x="80" y="540" width="1000" height="140" as="geometry" />
        </mxCell>
        <mxCell id="step-functions" value="Step Functions&#xa;Bulk Download&#xa;Workflow" style="sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#527FFF;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.step_functions;" vertex="1" parent="layer-orchestration">
          <mxGeometry x="200" y="40" width="78" height="78" as="geometry" />
        </mxCell>
        <mxCell id="eventbridge" value="EventBridge&#xa;Event Bus" style="sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#527FFF;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.eventbridge;" vertex="1" parent="layer-orchestration">
          <mxGeometry x="440" y="40" width="78" height="78" as="geometry" />
        </mxCell>
        <mxCell id="sqs" value="SQS Queue&#xa;Download Jobs" style="sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#527FFF;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.sqs;" vertex="1" parent="layer-orchestration">
          <mxGeometry x="680" y="40" width="78" height="78" as="geometry" />
        </mxCell>

        <!-- Data & Storage Layer -->
        <mxCell id="layer-data" value="Data &amp; Storage Layer" style="swimlane;whiteSpace=wrap;html=1;fillColor=#e8f5e9;strokeColor=#2e7d32;fontStyle=1;fontSize=14;" vertex="1" parent="1">
          <mxGeometry x="80" y="700" width="1000" height="140" as="geometry" />
        </mxCell>
        <mxCell id="dynamodb" value="DynamoDB&#xa;Global Tables&#xa;Config | ACLs | Audit" style="sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#3F8624;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.dynamodb;" vertex="1" parent="layer-data">
          <mxGeometry x="200" y="40" width="78" height="78" as="geometry" />
        </mxCell>
        <mxCell id="s3" value="S3 Buckets&#xa;Bulk Downloads&#xa;72h Lifecycle" style="sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#3F8624;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.s3;" vertex="1" parent="layer-data">
          <mxGeometry x="440" y="40" width="78" height="78" as="geometry" />
        </mxCell>
        <mxCell id="secrets" value="Secrets Manager&#xa;Archive Credentials&#xa;Auto-rotation" style="sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#DD344C;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.secrets_manager;" vertex="1" parent="layer-data">
          <mxGeometry x="680" y="40" width="78" height="78" as="geometry" />
        </mxCell>

        <!-- External Systems Layer -->
        <mxCell id="layer-external" value="External Systems" style="swimlane;whiteSpace=wrap;html=1;fillColor=#eceff1;strokeColor=#546e7a;fontStyle=1;fontSize=14;" vertex="1" parent="1">
          <mxGeometry x="80" y="860" width="1000" height="140" as="geometry" />
        </mxCell>
        <mxCell id="iesc" value="IESC&#xa;REST API&#xa;(Cloud)" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#879196;strokeColor=#232F3E;fontColor=#ffffff;fontSize=12;" vertex="1" parent="layer-external">
          <mxGeometry x="80" y="50" width="120" height="60" as="geometry" />
        </mxCell>
        <mxCell id="ies" value="IES&#xa;SOAP API&#xa;(Direct Connect)" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#879196;strokeColor=#232F3E;fontColor=#ffffff;fontSize=12;" vertex="1" parent="layer-external">
          <mxGeometry x="240" y="50" width="120" height="60" as="geometry" />
        </mxCell>
        <mxCell id="cmod" value="CMOD&#xa;SOAP API&#xa;(Direct Connect)" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#879196;strokeColor=#232F3E;fontColor=#ffffff;fontSize=12;" vertex="1" parent="layer-external">
          <mxGeometry x="400" y="50" width="120" height="60" as="geometry" />
        </mxCell>
        <mxCell id="frs" value="FRS Proxy&#xa;SOAP API&#xa;(Direct Connect)" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#879196;strokeColor=#232F3E;fontColor=#ffffff;fontSize=12;" vertex="1" parent="layer-external">
          <mxGeometry x="560" y="50" width="120" height="60" as="geometry" />
        </mxCell>
        <mxCell id="mailroom-backend" value="MailRoom Backend&#xa;REST API&#xa;(Independent Platform)" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#879196;strokeColor=#232F3E;fontColor=#ffffff;fontSize=12;" vertex="1" parent="layer-external">
          <mxGeometry x="720" y="50" width="160" height="60" as="geometry" />
        </mxCell>

        <!-- Connections -->
        <mxCell id="edge1" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeColor=#527FFF;strokeWidth=2;fontSize=11;" edge="1" parent="1" source="cloudfront" target="api-gateway">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="edge2" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeColor=#527FFF;strokeWidth=2;fontSize=11;dashed=1;" edge="1" parent="1" source="api-gateway" target="cognito">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>

      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

---

## Manual Creation Instructions

### Step 1: Set Up draw.io with AWS Icons
1. Go to https://app.diagrams.net/
2. Create a new diagram (Blank Diagram)
3. Load AWS icon library:
   - Click **More Shapes...** (bottom left)
   - Search for "AWS 19"
   - Enable **AWS 19** library
   - Click **Apply**

### Step 2: Create Swimlane Layers
Create 6 horizontal swimlanes (Container shapes):

1. **Presentation Layer**
   - Width: 1000px, Height: 120px
   - Fill: Light Blue (#e3f2fd)
   - Border: Blue (#1976d2)

2. **API & Auth Layer**
   - Fill: Light Orange (#fff3e0)
   - Border: Orange (#e65100)

3. **Application Services - Lambda Functions**
   - Fill: Light Orange (#fff3e0)
   - Border: Orange (#ff6f00)

4. **Orchestration & Events**
   - Fill: Light Indigo (#e8eaf6)
   - Border: Indigo (#3f51b5)

5. **Data & Storage Layer**
   - Fill: Light Green (#e8f5e9)
   - Border: Green (#2e7d32)

6. **External Systems**
   - Fill: Light Grey (#eceff1)
   - Border: Grey (#546e7a)

### Step 3: Add AWS Components

#### Presentation Layer
- **CloudFront**: Search "CloudFront" in AWS icons, add distribution icon
- Add label: "CloudFront CDN + S3 Angular SPA"

#### API & Auth Layer
- **API Gateway**: AWS icon → API Gateway
- **Cognito**: AWS icon → Cognito

#### Application Services Layer (8 Lambda Functions)
For each Lambda, use AWS Lambda icon and add labels:
1. Document Service (Node.js 20.x, 512MB, 29s)
2. Search Service (Node.js 20.x, 512MB, 29s)
3. Download Service (Node.js 20.x, 256MB, 15s)
4. Comment Service (Node.js 20.x, 256MB, 10s)
5. Admin Service (Node.js 20.x, 512MB, 15s)
6. Auth Service (Node.js 20.x, 256MB, 10s)
7. Event Service (Node.js 20.x, 256MB, 5s)
8. MailRoom Wrapper (Node.js 20.x, 512MB, 29s) - Add red border stroke

#### Orchestration & Events Layer
- **Step Functions**: AWS icon → Step Functions
- **EventBridge**: AWS icon → EventBridge
- **SQS**: AWS icon → SQS

#### Data & Storage Layer
- **DynamoDB**: AWS icon → DynamoDB (add "Global Tables" label)
- **S3**: AWS icon → S3 (add "Bulk Downloads, 72h Lifecycle" label)
- **Secrets Manager**: AWS icon → Secrets Manager

#### External Systems Layer
Create 5 rounded rectangles (grey fill #879196):
1. IESC (REST API - Cloud)
2. IES (SOAP API - Direct Connect)
3. CMOD (SOAP API - Direct Connect)
4. FRS Proxy (SOAP API - Direct Connect)
5. MailRoom Backend (REST API - Independent Platform)

### Step 4: Add Connections

Use connectors (arrows) with labels:

**From CloudFront:**
- → API Gateway: "HTTPS + JWT"

**From API Gateway:**
- → Cognito: "Validate Token" (dashed line)
- → All 8 Lambda functions: "Invoke"

**From Document Service:**
- → DynamoDB: "Query/Write"
- → IESC, IES, CMOD: "Fetch Docs"
- → EventBridge: "Publish Events"
- → Secrets Manager: "Get Credentials"

**From Search Service:**
- → DynamoDB: "Query ACLs"
- → IESC, IES, CMOD: "Search"
- → Secrets Manager: "Get Credentials"

**From Download Service:**
- → Step Functions: "Start Workflow"
- → DynamoDB: "Query Status"

**From Step Functions:**
- → SQS: "Enqueue Jobs"

**From SQS:**
- → Document Service: "Trigger Worker"

**From Document Service (bulk download):**
- → S3: "Upload Zip"

**From Comment Service:**
- → DynamoDB: "CRUD Comments"

**From Admin Service:**
- → DynamoDB: "Manage Tenants/ACLs"
- → Secrets Manager: "Store Credentials"

**From Auth Service:**
- → Cognito: "Token Operations"
- → DynamoDB: "Session Metadata"

**From EventBridge:**
- → Event Service: "Trigger"

**From Event Service:**
- → FRS: "Forward Events"

**From MailRoom Wrapper:**
- → DynamoDB: "Check ACLs/Audit"
- → MailRoom Backend: "API Calls"

### Step 5: Color Scheme

Apply these colors to match AWS branding:

- **Compute (Lambda)**: Orange (#FF9900)
- **Data (DynamoDB, S3)**: Green (#3F8624)
- **Integration (API Gateway, EventBridge, SQS, Step Functions)**: Blue (#527FFF)
- **Security (Cognito, Secrets Manager)**: Red (#DD344C)
- **External Systems**: Grey (#879196)
- **MailRoom Wrapper**: Orange with red border (#C92A2A)

### Step 6: Export
1. **File → Export as → PNG** (recommended: 300 DPI)
2. **File → Export as → SVG** (for vector graphics)
3. Save to: `docs/architecture/diagrams/application-architecture.png`

---

## Diagram Layout Tips

1. **Spacing**: Use 40px vertical spacing between swimlanes
2. **Alignment**: Align Lambda functions horizontally with 20px gaps
3. **Labels**: Use Arial or Helvetica, 11-12pt for component text
4. **Arrows**: Use solid lines for data flow, dashed for validation/auth
5. **Grid**: Enable 10px grid snap for consistent alignment

---

## Color Reference

| Component Type | Fill Color | Hex Code | Stroke |
|----------------|-----------|----------|--------|
| Lambda (Compute) | AWS Orange | #FF9900 | #232F3E |
| Data Services | AWS Green | #3F8624 | #232F3E |
| Integration | AWS Blue | #527FFF | #232F3E |
| Security | AWS Red | #DD344C | #232F3E |
| External Systems | Grey | #879196 | #232F3E |
| MailRoom Wrapper | Orange | #FF9900 | #C92A2A |

---

**Document Control**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-01-11 | Architecture Team | Initial draw.io diagram specification |
