#!/bin/bash

# Exit on error
set -e

echo "Cleaning wallet ..."
rm -rf ./blockchain-api/wallet

# CONFIG
ORG="org1.example.com"
ORG_SHORT="org1"
CONN_PROFILE_SRC="../../fabric-samples/test-network/organizations/peerOrganizations/$ORG/connection-$ORG_SHORT.json"
DEST_DIR="./config"
DEST_FILE="$DEST_DIR/connection-org1.json"

echo "Copying connection-org1.json ..."
mkdir -p "$DEST_DIR"

if [ -f "$CONN_PROFILE_SRC" ]; then
  cp "$CONN_PROFILE_SRC" "$DEST_FILE"
  echo "connection-org1.json copied successfully."
else
  echo "❌ ERROR: $CONN_PROFILE_SRC not found. Please generate it using Fabric CLI tools."
  exit 1
fi

echo "Enrolling admin identity ..."
if node enrollAdmin.js; then
  echo "✅ Admin enrolled successfully."
else
  echo "❌ Failed to enroll admin user \"admin\""
  exit 1
fi

echo "✅ Setup complete. You're ready to run your API."
