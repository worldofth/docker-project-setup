#!/bin/bash

# Initial project setup script

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Docker Development Environment Setup ===${NC}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error:${NC} Docker is not running"
    echo "Please start Docker Desktop and try again"
    exit 1
fi

# Create .env file if it doesn't exist
if [ ! -f docker/.env ]; then
    echo -e "${YELLOW}Creating docker/.env file...${NC}"
    cp docker/.env.example docker/.env
    echo -e "${GREEN}✓${NC} Created docker/.env from example"
    
    # Auto-detect UID and GID on macOS/Linux
    if [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "linux"* ]]; then
        sed -i.bak "s/UID=1000/UID=$(id -u)/" docker/.env
        sed -i.bak "s/GID=1000/GID=$(id -g)/" docker/.env
        rm docker/.env.bak
        echo -e "${GREEN}✓${NC} Auto-configured UID/GID for your system"
    fi
else
    echo -e "${YELLOW}⚠${NC} docker/.env already exists, skipping creation"
fi

# Create necessary directories
echo -e "${YELLOW}Creating project directories...${NC}"
mkdir -p docker/mysql-data
mkdir -p docker/certs
mkdir -p docker/dumps
mkdir -p public
echo -e "${GREEN}✓${NC} Created directory structure"

# Make scripts executable
chmod +x docker/scripts/*.sh
echo -e "${GREEN}✓${NC} Made scripts executable"

# Check if PROJECT_NAME is set
PROJECT_NAME=$(grep "^PROJECT_NAME=" docker/.env | cut -d '=' -f2 || echo "")
if [ -z "$PROJECT_NAME" ]; then
    echo ""
    echo -e "${RED}⚠ IMPORTANT:${NC} Please edit docker/.env and set PROJECT_NAME"
    echo ""
    echo "Example:"
    echo "  PROJECT_NAME=myproject"
    echo ""
    echo "This will be used for:"
    echo "  - Container names"
    echo "  - Domain name (myproject.test)"
    echo "  - Network name"
    echo ""
    NEED_CONFIG=true
else
    echo -e "${GREEN}✓${NC} PROJECT_NAME is set to: $PROJECT_NAME"
fi

# Check if HTTP_PORT is configured
HTTP_PORT=$(grep "^HTTP_PORT=" docker/.env | cut -d '=' -f2 || echo "")
if [ -z "$HTTP_PORT" ]; then
    echo -e "${YELLOW}⚠${NC} HTTP_PORT not set, using default: 8014"
else
    echo -e "${GREEN}✓${NC} HTTP_PORT is set to: $HTTP_PORT"
fi

echo ""
echo -e "${GREEN}=== Setup Summary ===${NC}"
echo "✓ Docker environment files created"
echo "✓ Directory structure created"
echo "✓ Scripts made executable"

if [ "$NEED_CONFIG" = true ]; then
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Edit docker/.env and set PROJECT_NAME"
    echo "2. Run: make up"
    echo "3. Visit: http://localhost:${HTTP_PORT:-8014}"
    echo ""
    echo -e "${YELLOW}Optional:${NC}"
    echo "- Run: make certs (for HTTPS support)"
    echo "- Run: make composer install (if you have composer.json)"
else
    echo ""
    echo -e "${GREEN}Ready to start!${NC}"
    echo "Run: make up"
    echo "Visit: http://localhost:${HTTP_PORT:-8014}"
    echo ""
    echo -e "${YELLOW}Optional:${NC}"
    echo "- Run: make certs (for HTTPS support)"
fi