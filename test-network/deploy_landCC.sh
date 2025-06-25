#!/bin/bash

set -e

###########################
### CONFIGURATION SECTION
###########################

CHANNEL_NAME="mychannel"
CHAINCODE_NAME="landrequest"
CHAINCODE_LABEL="landrequest_1.0"
CHAINCODE_VERSION="1.0"
CHAINCODE_LANG="node"
CHAINCODE_PATH="../chaincode/landrequest"
CHAINCODE_PACKAGE="${CHAINCODE_NAME}.tar.gz"
export PATH="${PWD}/../bin:$PATH"
export FABRIC_CFG_PATH="${PWD}/../config/"

ORDERER_CA="${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

PEERS=(
  "Org1MSP|7051|org1.example.com"
  "Org2MSP|9051|org2.example.com"
  "Org3MSP|11051|org3.example.com"
)

###########################
### STEP 1: Reset Network
###########################

echo "🛑 Bringing down previous network (if any)..."
./network.sh down || echo "ℹ️ No existing network to shut down."

echo "🚀 Starting network with Org1 & Org2..."
./network.sh up createChannel -ca -c $CHANNEL_NAME -s couchdb

###########################
### STEP 2: Package Chaincode
###########################

echo "📦 Packaging Node.js chaincode..."
peer lifecycle chaincode package "$CHAINCODE_PACKAGE" \
  --path "$CHAINCODE_PATH" \
  --lang "$CHAINCODE_LANG" \
  --label "$CHAINCODE_LABEL"

###########################
### STEP 3: Add Org3
###########################

echo "➕ Adding Org3 to the network..."
cd addOrg3
./addOrg3.sh up -c $CHANNEL_NAME -ca -s couchdb
cd ..

###########################
### STEP 4: Install on All Peers
###########################

echo "📥 Installing chaincode on all orgs..."

install_chaincode() {
  ORGMSP="$1"
  PORT="$2"
  DOMAIN="$3"

  export CORE_PEER_LOCALMSPID="$ORGMSP"
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_TLS_ROOTCERT_FILE="${PWD}/organizations/peerOrganizations/${DOMAIN}/peers/peer0.${DOMAIN}/tls/ca.crt"
  export CORE_PEER_MSPCONFIGPATH="${PWD}/organizations/peerOrganizations/${DOMAIN}/users/Admin@${DOMAIN}/msp"
  export CORE_PEER_ADDRESS="localhost:${PORT}"

  peer lifecycle chaincode install "$CHAINCODE_PACKAGE"
  echo "✅ Installed on $ORGMSP"
}

for PEER in "${PEERS[@]}"; do
  IFS="|" read -r ORGMSP PORT DOMAIN <<< "$PEER"
  install_chaincode "$ORGMSP" "$PORT" "$DOMAIN"
done

###########################
### STEP 5: Extract Package ID
###########################

echo "🔍 Extracting PACKAGE_ID from Org1..."

export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE="${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
export CORE_PEER_MSPCONFIGPATH="${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
export CORE_PEER_ADDRESS="localhost:7051"

PACKAGE_ID=$(peer lifecycle chaincode queryinstalled | grep "$CHAINCODE_LABEL" | sed -E 's/^Package ID: (.*), Label:.*/\1/')
echo "✅ PACKAGE_ID = $PACKAGE_ID"

###########################
### STEP 6: Approve Chaincode
###########################

detect_sequence() {
  peer lifecycle chaincode querycommitted --channelID "$CHANNEL_NAME" --name "$CHAINCODE_NAME" 2>/dev/null | grep "Sequence:" | awk '{gsub(",", "", $2); print int($2)}'
}

SEQUENCE=$(detect_sequence)
if [ -n "$SEQUENCE" ]; then
  CHAINCODE_SEQUENCE=$((SEQUENCE + 1))
else
  CHAINCODE_SEQUENCE=1
fi

echo "🔢 Using sequence number: $CHAINCODE_SEQUENCE"

approve_chaincode() {
  ORGMSP="$1"
  PORT="$2"
  DOMAIN="$3"

  export CORE_PEER_LOCALMSPID="$ORGMSP"
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_TLS_ROOTCERT_FILE="${PWD}/organizations/peerOrganizations/${DOMAIN}/peers/peer0.${DOMAIN}/tls/ca.crt"
  export CORE_PEER_MSPCONFIGPATH="${PWD}/organizations/peerOrganizations/${DOMAIN}/users/Admin@${DOMAIN}/msp"
  export CORE_PEER_ADDRESS="localhost:${PORT}"

  peer lifecycle chaincode approveformyorg \
    --channelID "$CHANNEL_NAME" \
    --name "$CHAINCODE_NAME" \
    --version "$CHAINCODE_VERSION" \
    --package-id "$PACKAGE_ID" \
    --sequence "$CHAINCODE_SEQUENCE" \
    --orderer localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --tls \
    --cafile "$ORDERER_CA"

  echo "✅ Approved for $ORGMSP"
}

for PEER in "${PEERS[@]}"; do
  IFS="|" read -r ORGMSP PORT DOMAIN <<< "$PEER"
  approve_chaincode "$ORGMSP" "$PORT" "$DOMAIN"
done

###########################
### STEP 7: Commit Chaincode
###########################

echo "🧱 Committing chaincode definition..."

COMMIT_CMD=(peer lifecycle chaincode commit
  --channelID "$CHANNEL_NAME"
  --name "$CHAINCODE_NAME"
  --version "$CHAINCODE_VERSION"
  --sequence "$CHAINCODE_SEQUENCE"
  --orderer localhost:7050
  --ordererTLSHostnameOverride orderer.example.com
  --tls
  --cafile "$ORDERER_CA"
)

for PEER in "${PEERS[@]}"; do
  IFS="|" read -r ORGMSP PORT DOMAIN <<< "$PEER"
  COMMIT_CMD+=(--peerAddresses "localhost:${PORT}")
  COMMIT_CMD+=(--tlsRootCertFiles "${PWD}/organizations/peerOrganizations/${DOMAIN}/peers/peer0.${DOMAIN}/tls/ca.crt")
done

"${COMMIT_CMD[@]}"
echo "✅ Chaincode committed successfully."

###########################
### STEP 8: Invoke InitLedger
###########################

echo "🔁 Invoking InitLedger..."

INVOKE_CMD=(peer chaincode invoke
  -o localhost:7050
  --ordererTLSHostnameOverride orderer.example.com
  --tls
  --cafile "$ORDERER_CA"
  -C "$CHANNEL_NAME"
  -n "$CHAINCODE_NAME"
)

for PEER in "${PEERS[@]}"; do
  IFS="|" read -r ORGMSP PORT DOMAIN <<< "$PEER"
  INVOKE_CMD+=(--peerAddresses "localhost:${PORT}")
  INVOKE_CMD+=(--tlsRootCertFiles "${PWD}/organizations/peerOrganizations/${DOMAIN}/peers/peer0.${DOMAIN}/tls/ca.crt")
done

INVOKE_CMD+=(-c '{"function":"InitLedger","Args":[]}')
"${INVOKE_CMD[@]}"

###########################
### STEP 9: Query from Org3
###########################

echo "🔎 Querying from Org3..."

export CORE_PEER_LOCALMSPID="Org3MSP"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE="${PWD}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt"
export CORE_PEER_MSPCONFIGPATH="${PWD}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp"
export CORE_PEER_ADDRESS="localhost:11051"

peer chaincode query -C "$CHANNEL_NAME" -n "$CHAINCODE_NAME" -c '{"Args":["getRequest","REQ001"]}'

echo ""
echo "✅ Chaincode '$CHAINCODE_NAME' deployed, invoked, and queried successfully from Org3!"
