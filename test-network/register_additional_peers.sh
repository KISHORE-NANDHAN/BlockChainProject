#!/bin/bash

set -e

# --- Input Validation ---
if [ "$#" -ne 2 ]; then
  echo "Usage: ./register_additional_peers.sh <org_domain> <org_msp_id>"
  echo "Example: ./register_additional_peers.sh org1.example.com Org1MSP"
  exit 1
fi

ORG_DOMAIN=$1           # e.g., org1.example.com
ORG_MSP=$2              # e.g., Org1MSP

if [[ "$ORG_DOMAIN" == "org3.example.com" ]]; then
  echo "📦 Copying fresh Org3 CA cert from container..."
  mkdir -p organizations/peerOrganizations/org3.example.com/ca/
  docker cp ca_org3:/etc/hyperledger/fabric-ca-server/ca-cert.pem organizations/peerOrganizations/org3.example.com/ca/ca.org3.example.com-cert.pem
fi

# Adjust CA port based on org
case "$ORG_DOMAIN" in
  org1.example.com)
    CA_PORT="7054"
    ;;
  org2.example.com)
    CA_PORT="8054"
    ;;
  org3.example.com)
    CA_PORT="11054"
    ;;
  *)
    echo "❌ Unknown organization domain. Please configure CA_PORT for $ORG_DOMAIN"
    exit 1
    ;;
esac

CA_NAME="ca-${ORG_DOMAIN%%.*}"   # ca-org1, ca-org2, etc.
CA_HOST="localhost"
BASE_DIR="organizations/peerOrganizations/${ORG_DOMAIN}"
TLS_CERT="ca/ca.${ORG_DOMAIN}-cert.pem"

# --- Enroll the CA admin ---
echo "🔐 Enrolling CA admin for $ORG_DOMAIN..."
export FABRIC_CA_CLIENT_HOME=organizations/peerOrganizations/${ORG_DOMAIN}

fabric-ca-client enroll -u https://admin:adminpw@${CA_HOST}:${CA_PORT} \
  --caname $CA_NAME \
  --tls.certfiles $TLS_CERT

# --- Register peer1, peer2, peer3 ---
for i in 1 2 3; do
  PEER_NAME="peer$i"

  echo "📌 Registering ${PEER_NAME}.${ORG_DOMAIN}..."

  fabric-ca-client register \
    --caname $CA_NAME \
    --id.name $PEER_NAME \
    --id.secret ${PEER_NAME}pw \
    --id.type peer \
    --tls.certfiles $TLS_CERT

  echo "✅ Registered: ${PEER_NAME}.${ORG_DOMAIN}"
done

echo "🎉 Done! Registered peer1, peer2, and peer3 for $ORG_DOMAIN"
