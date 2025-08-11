#!/bin/bash

# Certificate generation script for local development
# Requires mkcert to be installed

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get project name from .env file
if [ ! -f docker/.env ]; then
    echo -e "${RED}Error:${NC} docker/.env file not found"
    echo "Please run 'make setup' first and configure your .env file"
    exit 1
fi

PROJECT_NAME=$(grep "^PROJECT_NAME=" docker/.env | cut -d '=' -f2)

if [ -z "$PROJECT_NAME" ]; then
    echo -e "${RED}Error:${NC} PROJECT_NAME not set in docker/.env"
    echo "Please edit docker/.env and set PROJECT_NAME"
    exit 1
fi

echo -e "${YELLOW}Generating certificates for ${PROJECT_NAME}.test...${NC}"

# Check if mkcert is installed
if ! command -v mkcert &> /dev/null; then
    echo -e "${RED}Error:${NC} mkcert is not installed"
    echo "Install it with: brew install mkcert"
    echo "Then run: mkcert -install"
    exit 1
fi

# Create certificates directory
mkdir -p docker/certs

# Check if root CA exists in ~/local-cert-authority
CA_DIR="$HOME/local-cert-authority"
if [ ! -f "$CA_DIR/rootCA.pem" ] || [ ! -f "$CA_DIR/rootCA-key.pem" ]; then
    echo -e "${YELLOW}Setting up shared certificate authority...${NC}"
    
    # Create CA directory
    mkdir -p "$CA_DIR"
    
    # Install mkcert root CA
    mkcert -install
    
    # Copy CA files to shared location
    CAROOT=$(mkcert -CAROOT)
    cp "$CAROOT/rootCA.pem" "$CA_DIR/"
    cp "$CAROOT/rootCA-key.pem" "$CA_DIR/"
    
    echo -e "${GREEN}✓${NC} Certificate Authority set up in $CA_DIR"
fi

# Set CAROOT to use shared CA
export CAROOT="$CA_DIR"

# Generate certificate for this project
echo -e "${YELLOW}Generating certificate for ${PROJECT_NAME}.test...${NC}"

cd docker/certs
mkcert "${PROJECT_NAME}.test"

# Rename files to expected format for Nginx
if [ -f "${PROJECT_NAME}.test.pem" ]; then
    # Create symlinks with generic names for Nginx
    ln -sf "${PROJECT_NAME}.test.pem" cert.pem
    ln -sf "${PROJECT_NAME}.test-key.pem" cert-key.pem
    
    echo -e "${GREEN}✓${NC} Certificate generated successfully"
    echo -e "${GREEN}✓${NC} Files created:"
    echo "    docker/certs/${PROJECT_NAME}.test.pem"
    echo "    docker/certs/${PROJECT_NAME}.test-key.pem"
    echo "    docker/certs/cert.pem (symlink)"
    echo "    docker/certs/cert-key.pem (symlink)"
    echo ""
    echo -e "${GREEN}You can now access your project via HTTPS:${NC}"
    echo "    https://${PROJECT_NAME}.test:$(grep "^HTTPS_PORT=" ../docker/.env | cut -d '=' -f2 || echo "8443")"
else
    echo -e "${RED}Error:${NC} Certificate generation failed"
    exit 1
fi

echo ""
echo -e "${YELLOW}Note:${NC} If this is your first time using mkcert, you may need to:"
echo "1. Restart your browser"
echo "2. Check that the CA is installed in your keychain"
echo "3. Ensure your dnsmasq is configured to point *.test to 127.0.0.1"