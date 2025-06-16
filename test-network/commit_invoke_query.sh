#!/bin/bash

set -e

CHANNEL_NAME="mychannel"
CHAINCODE_NAME="basic"
CHAINCODE_VERSION="1.0"
CHAINCODE_SEQUENCE="2"
ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

PEERS=(
  "Org1MSP|7051|org1.example.com"
  "Org2MSP|9051|org2.example.com"
  "Org3MSP|11051|org3.example.com"
)

echo "🔍 Verifying all peers have chaincode installed..."

for PEER in "${PEERS[@]}"; do
  IFS="|" read ORGMSP PORT ORGDOMAIN <<< "$PEER"

  export CORE_PEER_LOCALMSPID="$ORGMSP"
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/$ORGDOMAIN/peers/peer0.$ORGDOMAIN/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/$ORGDOMAIN/users/Admin@$ORGDOMAIN/msp
  export CORE_PEER_ADDRESS=localhost:$PORT

  echo "🔎 Checking install on $ORGMSP..."

  if ! peer lifecycle chaincode queryinstalled | grep -q "$CHAINCODE_NAME"; then
    echo "❌ Chaincode $CHAINCODE_NAME is NOT installed on $ORGMSP. Aborting!"
    exit 1
  fi
  echo "✅ Chaincode is installed on $ORGMSP."
done

echo "🧱 Committing chaincode definition..."

if peer lifecycle chaincode commit \
  --channelID $CHANNEL_NAME \
  --name $CHAINCODE_NAME \
  --version $CHAINCODE_VERSION \
  --sequence $CHAINCODE_SEQUENCE \
  --orderer localhost:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile $ORDERER_CA \
  --peerAddresses localhost:7051 \
  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
  --peerAddresses localhost:9051 \
  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
  --peerAddresses localhost:11051 \
  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
then
  echo "✅ Commit complete!"
else
  echo "⚠️ Commit may have already been done. Continuing..."
fi

echo "🔍 Verifying commit..."
peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name $CHAINCODE_NAME

echo "🔁 Invoking InitLedger on all peers..."

peer chaincode invoke \
  -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile $ORDERER_CA \
  -C $CHANNEL_NAME \
  -n $CHAINCODE_NAME \
  --peerAddresses localhost:7051 \
  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
  --peerAddresses localhost:9051 \
  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
  --peerAddresses localhost:11051 \
  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt \
  -c '{"function":"InitLedger","Args":[]}'

sleep 3

echo "🔎 Querying from Org3..."

export CORE_PEER_LOCALMSPID="Org3MSP"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
export CORE_PEER_ADDRESS=localhost:11051

peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_NAME -c '{"Args":["GetAllAssets"]}'

echo "✅ Chaincode committed, invoked, and queried successfully!"
