#!/bin/bash
# =============================================================================
# MCBDS API - Self-Signed Certificate Generator
# =============================================================================
# This script generates a self-signed SSL certificate for the MCBDS API server.
# Run this script on your server before starting the HTTPS Docker container.
# =============================================================================

set -e

# Configuration
CERT_DIR="./certs"
CERT_NAME="mcbds-api"
CERT_PASSWORD="McbdsApiCert123!"
VALIDITY_DAYS=1825  # 5 years

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  MCBDS API Certificate Generator${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Get server IP
echo -e "${YELLOW}Enter your server's IP address (or press Enter for localhost only):${NC}"
read -r SERVER_IP

if [ -z "$SERVER_IP" ]; then
    SERVER_IP="127.0.0.1"
    echo -e "Using default: ${SERVER_IP}"
fi

# Create certs directory
echo ""
echo -e "${YELLOW}Step 1: Creating certificate directory...${NC}"
mkdir -p "$CERT_DIR"
echo -e "${GREEN}? Created ${CERT_DIR}${NC}"

# Generate certificate
echo ""
echo -e "${YELLOW}Step 2: Generating self-signed certificate...${NC}"

openssl req -x509 -nodes -days $VALIDITY_DAYS -newkey rsa:2048 \
    -keyout "$CERT_DIR/$CERT_NAME.key" \
    -out "$CERT_DIR/$CERT_NAME.crt" \
    -subj "/CN=mcbds-api/O=MCBDSHost/C=US" \
    -addext "subjectAltName=DNS:localhost,DNS:mcbds-api,IP:127.0.0.1,IP:$SERVER_IP"

echo -e "${GREEN}? Generated certificate and private key${NC}"

# Convert to PFX
echo ""
echo -e "${YELLOW}Step 3: Converting to PFX format...${NC}"

openssl pkcs12 -export -out "$CERT_DIR/$CERT_NAME.pfx" \
    -inkey "$CERT_DIR/$CERT_NAME.key" \
    -in "$CERT_DIR/$CERT_NAME.crt" \
    -password pass:$CERT_PASSWORD

echo -e "${GREEN}? Created PFX file${NC}"

# Set permissions
echo ""
echo -e "${YELLOW}Step 4: Setting file permissions...${NC}"

chmod 600 "$CERT_DIR/$CERT_NAME.pfx"
chmod 600 "$CERT_DIR/$CERT_NAME.key"
chmod 644 "$CERT_DIR/$CERT_NAME.crt"

echo -e "${GREEN}? Permissions set${NC}"

# Summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Certificate Generated Successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Files created:"
echo -e "  ${CERT_DIR}/${CERT_NAME}.pfx  - SSL certificate (for Docker)"
echo -e "  ${CERT_DIR}/${CERT_NAME}.crt  - Public certificate"
echo -e "  ${CERT_DIR}/${CERT_NAME}.key  - Private key"
echo ""
echo -e "Certificate password: ${YELLOW}${CERT_PASSWORD}${NC}"
echo -e "Valid for: ${VALIDITY_DAYS} days (5 years)"
echo -e "Server IP: ${SERVER_IP}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Start the HTTPS Docker container:"
echo -e "   ${GREEN}docker-compose -f docker-compose.https.yml up -d${NC}"
echo ""
echo -e "2. Test HTTPS connection:"
echo -e "   ${GREEN}curl -k https://localhost:8081/api/runner/status${NC}"
echo ""
echo -e "3. Update PublicUI.Web to use:"
echo -e "   ${GREEN}https://${SERVER_IP}:8081${NC}"
echo ""
