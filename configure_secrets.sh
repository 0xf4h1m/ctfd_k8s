#!/bin/bash

# configure_secrets.sh
# Automates the generation of secrets and updates the Kubernetes manifests.

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# File Paths
MYSQL_SECRET_FILE="mysql-secret.yaml"
CTFD_CONFIG_FILE="ctfd-configmap.yaml"

if [[ ! -f "$MYSQL_SECRET_FILE" || ! -f "$CTFD_CONFIG_FILE" ]]; then
    echo -e "${RED}[!] Error: Configuration files not found in current directory.${NC}"
    exit 1
fi

echo -e "${GREEN}[*] Generating Random Secrets...${NC}"

# Generate Secrets
ROOT_PASS=$(openssl rand -hex 16)
USER_PASS=$(openssl rand -hex 16)
SECRET_KEY=$(openssl rand -hex 32)

echo "MySQL Root Password: $ROOT_PASS"
echo "MySQL User Password: $USER_PASS"
echo "CTFd Secret Key:     $SECRET_KEY"

# Base64 Encode for Kubernetes Secret
ROOT_PASS_B64=$(echo -n "$ROOT_PASS" | base64)
USER_PASS_B64=$(echo -n "$USER_PASS" | base64)

echo -e "${GREEN}[*] Updating mysql-secret.yaml...${NC}"

# Update MySQL Secret (Linux sed syntax)
sed -i "s/MYSQL_ROOT_PASSWORD: .*/MYSQL_ROOT_PASSWORD: $ROOT_PASS_B64/" "$MYSQL_SECRET_FILE"
sed -i "s/MYSQL_PASSWORD: .*/MYSQL_PASSWORD: $USER_PASS_B64/" "$MYSQL_SECRET_FILE"

echo -e "${GREEN}[*] Updating ctfd-configmap.yaml...${NC}"

# Update ConfigMap SECRET_KEY
sed -i "s/SECRET_KEY: .*/SECRET_KEY: \"$SECRET_KEY\"/" "$CTFD_CONFIG_FILE"

# Update ConfigMap DATABASE_URL
# Construct the new URL string carefully escaping special chars isn't strictly needed if we use | delimiter in sed
NEW_DB_URL="mysql+pymysql://ctfd:$USER_PASS@mysql-svc:3306/ctfd"
sed -i "s|DATABASE_URL: .*|DATABASE_URL: \"$NEW_DB_URL\"|" "$CTFD_CONFIG_FILE"

echo -e "${GREEN}[✔] Secrets updated successfully!${NC}"
echo -e "${GREEN}[*] You can now deploy the manifests using: sudo kubectl apply -f ./${NC}"
