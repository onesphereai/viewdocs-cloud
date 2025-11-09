#!/bin/bash

# Setup GitHub Repository for Viewdocs Cloud
# This script initializes git, commits files, and pushes to GitHub

set -e  # Exit on error

echo "🚀 Setting up Viewdocs Cloud GitHub repository..."

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
REPO_NAME="viewdocs-cloud"
ORG_NAME="onesphereai"
REPO_URL="https://github.com/${ORG_NAME}/${REPO_NAME}.git"

# Check if GitHub CLI is installed
if command -v gh &> /dev/null; then
    echo -e "${GREEN}✓ GitHub CLI detected${NC}"
    USE_GH_CLI=true
else
    echo -e "${YELLOW}! GitHub CLI not found. Will use manual method.${NC}"
    USE_GH_CLI=false
fi

# Check if git is initialized
if [ ! -d ".git" ]; then
    echo "📁 Initializing git repository..."
    git init
    echo -e "${GREEN}✓ Git initialized${NC}"
else
    echo -e "${GREEN}✓ Git already initialized${NC}"
fi

# Check for existing .gitignore
if [ ! -f ".gitignore" ]; then
    echo "📝 Creating .gitignore..."
    cat > .gitignore << 'EOF'
# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Build outputs
dist/
build/
.next/
out/

# Environment variables
.env
.env.local
.env.*.local
*.env

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# CDK
cdk.out/
cdk.context.json

# Logs
*.log
logs/

# Test coverage
coverage/
.nyc_output/

# Temporary files
*.tmp
.cache/
EOF
    echo -e "${GREEN}✓ .gitignore created${NC}"
fi

# Stage all files
echo "📦 Staging all files..."
git add .
echo -e "${GREEN}✓ Files staged${NC}"

# Check if there are changes to commit
if git diff --cached --quiet; then
    echo -e "${YELLOW}! No changes to commit${NC}"
else
    # Create initial commit
    echo "💬 Creating initial commit..."
    git commit -m "Initial commit: Viewdocs Cloud architecture documentation

- Complete architecture documentation (TOGAF + C4 model)
- 9 core architecture documents (business, application, data, technology, security, deployment, cost)
- 11 Architecture Decision Records (ADRs)
- Mermaid diagrams (context, container, sequence, deployment)
- Draw.io instructions for AWS icon diagrams
- CLAUDE.md guide for future development
- Total: ~270KB comprehensive documentation

Tech Stack:
- Frontend: Angular 17+, TypeScript
- Backend: Node.js 20.x Lambda, TypeScript
- Infrastructure: AWS CDK
- Database: DynamoDB Global Tables
- Auth: AWS Cognito with SAML 2.0

Architecture Highlights:
- Multi-tenant pool model (\$2.96/tenant/month)
- Multi-region DR (RPO: 2hr, RTO: 24hr)
- 500 concurrent users, 5-500 tenants
- Data residency: Australia (ap-southeast-2 + ap-southeast-4)

🤖 Generated with Claude Code (https://claude.com/claude-code)"
    echo -e "${GREEN}✓ Commit created${NC}"
fi

# Create and push to GitHub
if [ "$USE_GH_CLI" = true ]; then
    echo "🌐 Creating GitHub repository using gh CLI..."

    # Check if authenticated
    if ! gh auth status &> /dev/null; then
        echo -e "${YELLOW}! GitHub CLI not authenticated. Please run: gh auth login${NC}"
        exit 1
    fi

    # Create repository
    gh repo create ${ORG_NAME}/${REPO_NAME} \
        --public \
        --description "Multi-tenant serverless document management system - AWS Cloud Architecture" \
        --source=. \
        --remote=origin \
        --push

    echo -e "${GREEN}✓ Repository created and pushed!${NC}"
    echo ""
    echo "🎉 Success! Repository URL:"
    echo "   https://github.com/${ORG_NAME}/${REPO_NAME}"
    echo ""
    echo "📖 View repository:"
    gh repo view ${ORG_NAME}/${REPO_NAME} --web

else
    echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Manual Setup Required${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo "1. Create repository on GitHub:"
    echo "   https://github.com/organizations/${ORG_NAME}/repositories/new"
    echo ""
    echo "   Repository name: ${REPO_NAME}"
    echo "   Description: Multi-tenant serverless document management system - AWS Cloud Architecture"
    echo "   Visibility: Public (or Private)"
    echo "   ❌ DO NOT initialize with README, .gitignore, or license"
    echo ""
    echo "2. After creating, run these commands:"
    echo ""
    echo "   git remote add origin ${REPO_URL}"
    echo "   git branch -M main"
    echo "   git push -u origin main"
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
fi

echo ""
echo "✅ Setup complete!"
