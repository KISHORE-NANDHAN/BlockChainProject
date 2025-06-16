#!/bin/bash

set -e

CHANNEL_NAME="mychannel"
CHAINCODE_NAME="basic"
CHAINCODE_LABEL="basic_1.0"
CHAINCODE_VERSION="1.0"
CHAINCODE_SEQUENCE="2"
CHAINCODE_PACKAGE="basic.tar.gz"

ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

PEERS=(
  "Org1MSP|7051|org1.example.com"
  "Org2MSP|9051|org2.example.com"
  "Org3MSP|11051|org3.example.com"
)

echo "🔁 Reinstalling chaincode on all organizations..."

install_chaincode() {
  ORGMSP=$1
  PORT=$2
  DOMAIN=$3

  export CORE_PEER_LOCALMSPID="$ORGMSP"
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/$DOMAIN/peers/peer0.$DOMAIN/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/$DOMAIN/users/Admin@$DOMAIN/msp
  export CORE_PEER_ADDRESS=localhost:$PORT

  echo "📦 Installing chaincode on $ORGMSP..."
if peer lifecycle chaincode install $CHAINCODE_PACKAGE 2>&1 | tee /tmp/install.log | grep -q "already successfully installed"; then
  echo "ℹ️ Chaincode already installed on $ORGMSP. Skipping."
elif grep -q "Error" /tmp/install.log; then
  echo "❌ Unexpected error during install on $ORGMSP. Check logs above."
  exit 1
else
  echo "✅ Successfully installed on $ORGMSP."
fi

}

for PEER in "${PEERS[@]}"; do
  IFS="|" read ORGMSP PORT DOMAIN <<< "$PEER"
  install_chaincode "$ORGMSP" "$PORT" "$DOMAIN"
done

# Use Org1 to get the PACKAGE_ID
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

echo "🔍 Getting PACKAGE_ID from Org1..."
PACKAGE_ID=$(peer lifecycle chaincode queryinstalled | grep "$CHAINCODE_LABEL" | awk -F "[,:]" '{print $3}' | tr -d ' ')
echo "✅ PACKAGE_ID: $PACKAGE_ID"

approve_chaincode() {
  ORGMSP=$1
  PORT=$2
  DOMAIN=$3

  export CORE_PEER_LOCALMSPID="$ORGMSP"
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/$DOMAIN/peers/peer0.$DOMAIN/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/$DOMAIN/users/Admin@$DOMAIN/msp
  export CORE_PEER_ADDRESS=localhost:$PORT

  echo "✅ Approving chaincode for $ORGMSP..."
  if peer lifecycle chaincode approveformyorg \
  --channelID $CHANNEL_NAME \
  --name $CHAINCODE_NAME \
  --version $CHAINCODE_VERSION \
  --package-id $PACKAGE_ID \
  --sequence $CHAINCODE_SEQUENCE \
  --orderer localhost:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile $ORDERER_CA 2>&1 | tee /tmp/approve.log | grep -q "attempted to redefine the current committed sequence"; then
  echo "ℹ️ Approval already exists for $ORGMSP. Skipping."
elif grep -q "Error" /tmp/approve.log; then
  echo "❌ Unexpected error while approving for $ORGMSP."
  exit 1
else
  echo "✅ Approved for $ORGMSP."
fi
}

for PEER in "${PEERS[@]}"; do
  IFS="|" read ORGMSP PORT DOMAIN <<< "$PEER"
  approve_chaincode "$ORGMSP" "$PORT" "$DOMAIN"
done

echo "✅ All orgs have reinstalled and approved the chaincode."
