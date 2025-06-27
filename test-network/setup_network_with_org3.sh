#!/bin/bash

set -e

CHANNEL_NAME="mychannel"
CHAINCODE_NAME="basic"
CHAINCODE_PATH="../asset-transfer-basic/chaincode-go"
CHAINCODE_LANG="go"

echo "🔁 Bringing down any existing Fabric network (if running)..."
./network.sh down || echo "ℹ️ No existing network to shut down."

echo "🧹 Cleaning old Org3 artifacts..."
rm -rf ../organizations/peerOrganizations/revenue.gov.in
rm -rf ../organizations/peerOrganizations/org3.example.com
rm -f addOrg3/org3_update_in_envelope.pb

echo "🚀 Starting Fabric network with Org1 and Org2..."
./network.sh up createChannel -ca -c $CHANNEL_NAME -s couchdb

# echo "📦 Deploying chaincode '$CHAINCODE_NAME' to Org1 and Org2..."
# ./network.sh deployCC -ccn $CHAINCODE_NAME -ccp $CHAINCODE_PATH -ccl $CHAINCODE_LANG

echo "➕ Adding Org3 to the network..."
if [ -d "addOrg3" ]; then
  cd addOrg3
  ./addOrg3.sh generate -ca
  ./addOrg3.sh up -c $CHANNEL_NAME -ca -s couchdb -verbose
  cd ..
else
  echo "❌ 'addOrg3' folder not found. Aborting."
  exit 1
fi

echo ""
echo "✅ Org3 has been successfully added to the network."
echo "👉 Next steps:"
echo "   1️⃣ Run:   ./install_approve_all_orgs.sh   (install & approve chaincode on Org3)"
echo "   2️⃣ Run:   ./commit_invoke_query.sh        (commit definition, invoke, query)"
