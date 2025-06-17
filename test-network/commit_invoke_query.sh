#!/bin/bash

set -e

### ---- CONFIGURATION ---- ###
export PATH="${PWD}/../bin:$PATH"
export FABRIC_CFG_PATH="${PWD}/../config/"

CHANNEL_NAME="mychannel"
CHAINCODE_NAME="basic"
CHAINCODE_LABEL="basic_1.0"
CHAINCODE_VERSION="1.0"
ORDERER_CA="${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

# Peer configuration: "MSP|PORT|DOMAIN"
PEERS=(
  "Org1MSP|7051|org1.example.com"
  "Org2MSP|9051|org2.example.com"
  "Org3MSP|11051|org3.example.com"
)

### ---- CHECK: Is 'peer' CLI available? ---- ###
if ! command -v peer &>/dev/null; then
  echo "❌ 'peer' CLI not found in PATH. Please check your setup."
  exit 1
fi

### ---- STEP 1: Verify chaincode installed on all peers ---- ###
echo "🔍 Verifying all peers have chaincode installed..."

for PEER in "${PEERS[@]}"; do
  IFS="|" read -r ORGMSP PORT ORGDOMAIN <<< "$PEER"

  export CORE_PEER_LOCALMSPID="$ORGMSP"
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_TLS_ROOTCERT_FILE="${PWD}/organizations/peerOrganizations/${ORGDOMAIN}/peers/peer0.${ORGDOMAIN}/tls/ca.crt"
  export CORE_PEER_MSPCONFIGPATH="${PWD}/organizations/peerOrganizations/${ORGDOMAIN}/users/Admin@${ORGDOMAIN}/msp"
  export CORE_PEER_ADDRESS="localhost:${PORT}"

  echo "🔎 Checking install on $ORGMSP..."
  if ! peer lifecycle chaincode queryinstalled | grep -q "$CHAINCODE_LABEL"; then
    echo "❌ Chaincode '$CHAINCODE_LABEL' is NOT installed on $ORGMSP. Aborting!"
    exit 1
  fi
  echo "✅ Chaincode is installed on $ORGMSP."
done

### ---- STEP 2: Detect latest committed sequence ---- ###
echo "🔍 Detecting latest sequence number..."

export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE="${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
export CORE_PEER_MSPCONFIGPATH="${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
export CORE_PEER_ADDRESS="localhost:7051"

LATEST_SEQUENCE=$(peer lifecycle chaincode querycommitted --channelID "$CHANNEL_NAME" --name "$CHAINCODE_NAME" 2>/dev/null | grep "Sequence:" | awk '{gsub(",", "", $2); print int($2)}')
if [ -n "$LATEST_SEQUENCE" ]; then
  CHAINCODE_SEQUENCE=$((LATEST_SEQUENCE + 1))
  echo "ℹ️ Last committed sequence: $LATEST_SEQUENCE ➡️ Using next sequence: $CHAINCODE_SEQUENCE"
else
  CHAINCODE_SEQUENCE=1
  echo "ℹ️ No previous sequence found. Using sequence: $CHAINCODE_SEQUENCE"
fi

### ---- STEP 3: Commit chaincode definition ---- ###
echo "🧱 Committing chaincode definition with sequence $CHAINCODE_SEQUENCE..."

COMMIT_CMD=(
  peer lifecycle chaincode commit
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
  IFS="|" read -r ORGMSP PORT ORGDOMAIN <<< "$PEER"
  COMMIT_CMD+=(--peerAddresses "localhost:${PORT}")
  COMMIT_CMD+=(--tlsRootCertFiles "${PWD}/organizations/peerOrganizations/${ORGDOMAIN}/peers/peer0.${ORGDOMAIN}/tls/ca.crt")
done

if "${COMMIT_CMD[@]}" 2>&1 | tee /tmp/commit.log | grep -q "cannot be approved again"; then
  echo "⚠️ Chaincode may have already been committed."
elif grep -q "Error" /tmp/commit.log; then
  echo "❌ Error while committing chaincode. Check above log."
  exit 1
else
  echo "✅ Commit successful!"
fi

### ---- STEP 4: Verify commit ---- ###
echo "🔍 Verifying committed chaincode..."
peer lifecycle chaincode querycommitted --channelID "$CHANNEL_NAME" --name "$CHAINCODE_NAME"

### ---- STEP 5: Invoke InitLedger ---- ###
echo "🔁 Invoking InitLedger on chaincode..."

INVOKE_CMD=(
  peer chaincode invoke
  -o localhost:7050
  --ordererTLSHostnameOverride orderer.example.com
  --tls
  --cafile "$ORDERER_CA"
  -C "$CHANNEL_NAME"
  -n "$CHAINCODE_NAME"
)

for PEER in "${PEERS[@]}"; do
  IFS="|" read -r ORGMSP PORT ORGDOMAIN <<< "$PEER"
  INVOKE_CMD+=(--peerAddresses "localhost:${PORT}")
  INVOKE_CMD+=(--tlsRootCertFiles "${PWD}/organizations/peerOrganizations/${ORGDOMAIN}/peers/peer0.${ORGDOMAIN}/tls/ca.crt")
done

INVOKE_CMD+=(-c '{"function":"InitLedger","Args":[]}')

"${INVOKE_CMD[@]}"

sleep 3

### ---- STEP 6: Query chaincode from Org3 ---- ###
echo "🔎 Querying from Org3..."

export CORE_PEER_LOCALMSPID="Org3MSP"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE="${PWD}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt"
export CORE_PEER_MSPCONFIGPATH="${PWD}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp"
export CORE_PEER_ADDRESS="localhost:11051"

peer chaincode query -C "$CHANNEL_NAME" -n "$CHAINCODE_NAME" -c '{"Args":["GetAllAssets"]}'

echo ""
echo "✅ Chaincode committed, initialized (InitLedger), and queried successfully from Org3!"
