#!/bin/bash

set -e
export FABRIC_CFG_PATH=$PWD/../config

CHANNEL_NAME="mychannel"
BLOCK_FILE="./channel-artifacts/${CHANNEL_NAME}.block"

# Ensure block file exists
if [ ! -f "$BLOCK_FILE" ]; then
  echo "❌ Channel block $BLOCK_FILE not found. Make sure peer0 has generated and joined the channel."
  exit 1
fi

# Format: "OrgMSP|orgDomain|port"
PEERS=(
  "Org1MSP|org1.example.com|8051"
  "Org1MSP|org1.example.com|22051"
  "Org1MSP|org1.example.com|10051"
  "Org2MSP|org2.example.com|21051"
  "Org2MSP|org2.example.com|12051"
  "Org2MSP|org2.example.com|13051"
  "Org3MSP|org3.example.com|14051"
  "Org3MSP|org3.example.com|15051"
  "Org3MSP|org3.example.com|16051"
)

echo "🔗 Joining additional peers to channel '$CHANNEL_NAME'..."

for PEER in "${PEERS[@]}"; do
  IFS='|' read -r ORGMSP ORGDOMAIN PORT <<< "$PEER"

  export CORE_PEER_LOCALMSPID=$ORGMSP
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/${ORGDOMAIN}/peers/peer0.${ORGDOMAIN}/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/${ORGDOMAIN}/users/Admin@${ORGDOMAIN}/msp
  export CORE_PEER_ADDRESS=localhost:${PORT}

  echo "🔁 Joining $ORGMSP at $PORT..."
  peer channel join -b "$BLOCK_FILE"
done

echo "✅ All peers joined to channel: $CHANNEL_NAME"
