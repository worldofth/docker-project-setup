#!/bin/bash

# Ensure SSL certificates exist for nginx to start
# Creates fallback self-signed certificates if none exist

set -e

# Handle both host and container contexts
if [ -d "/certs" ]; then
    # Running in container
    CERTS_DIR="/certs"
else
    # Running on host
    CERTS_DIR="docker/certs"
fi

CERT_FILE="$CERTS_DIR/cert.pem"
KEY_FILE="$CERTS_DIR/cert-key.pem"

# Create certs directory if it doesn't exist
mkdir -p "$CERTS_DIR"

# Check if certificates already exist
if [ -f "$CERT_FILE" ] && [ -f "$KEY_FILE" ]; then
    echo "✓ SSL certificates already exist"
    exit 0
fi

echo "⚠ No SSL certificates found, generating fallback self-signed certificates..."
echo "  (Run 'make certs' for proper mkcert certificates)"

# Generate self-signed certificate valid for 365 days
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$KEY_FILE" \
    -out "$CERT_FILE" \
    -subj "/C=UK/ST=Local/L=Development/O=Docker Dev/CN=localhost" \
    -addext "subjectAltName=DNS:localhost,DNS:*.test,IP:127.0.0.1" \
    2>/dev/null

echo "✓ Fallback SSL certificates generated"
echo "  Note: These are self-signed and will show security warnings"
echo "  Run 'make certs' to generate trusted certificates with mkcert"