#!/bin/bash

set -e

if [ "$#" -ne 2 ]; then
  echo "Usage: ./enroll_additional_peers.sh <org_domain> <org_msp_id>"
  echo "Example: ./enroll_additional_peers.sh org1.example.com Org1MSP"
  exit 1
fi

ORG_DOMAIN=$1
ORG_MSP=$2
CA_HOST="localhost"

# Port mapping
case "$ORG_DOMAIN" in
  org1.example.com) CA_PORT="7054" ;;
  org2.example.com) CA_PORT="8054" ;;
  org3.example.com) CA_PORT="11054" ;;
  *) echo "❌ Unknown org domain"; exit 1 ;;
esac

CA_NAME="ca-${ORG_DOMAIN%%.*}"
ORG_BASE_DIR="organizations/peerOrganizations/${ORG_DOMAIN}"
TLS_CERT="${PWD}/${ORG_BASE_DIR}/ca/ca.${ORG_DOMAIN}-cert.pem"

for i in 1 2 3; do
  PEER_NAME="peer$i"
  PEER_DIR="${ORG_BASE_DIR}/peers/${PEER_NAME}.${ORG_DOMAIN}"

  echo "📥 Enrolling MSP for ${PEER_NAME}.${ORG_DOMAIN}..."

  # Enroll MSP
  fabric-ca-client enroll -u https://${PEER_NAME}:${PEER_NAME}pw@${CA_HOST}:${CA_PORT} \
    --caname $CA_NAME \
    -M ${PEER_DIR}/msp \
    --csr.hosts ${PEER_NAME}.${ORG_DOMAIN} \
    --tls.certfiles ${TLS_CERT}

  # Copy config.yaml
  cp ${ORG_BASE_DIR}/msp/config.yaml ${PEER_DIR}/msp/

  echo "🔐 Generating TLS cert for ${PEER_NAME}.${ORG_DOMAIN}..."

  # Enroll TLS
  fabric-ca-client enroll -u https://${PEER_NAME}:${PEER_NAME}pw@${CA_HOST}:${CA_PORT} \
    --caname $CA_NAME \
    -M ${PEER_DIR}/tls \
    --enrollment.profile tls \
    --csr.hosts ${PEER_NAME}.${ORG_DOMAIN} \
    --csr.hosts localhost \
    --tls.certfiles ${TLS_CERT}

  # Rename TLS files for Fabric conventions
  if [ -d ${PEER_DIR}/tls/tlscacerts ]; then
    cp ${PEER_DIR}/tls/tlscacerts/* ${PEER_DIR}/tls/ca.crt
  elif [ -d ${PEER_DIR}/tls/cacerts ]; then
    cp ${PEER_DIR}/tls/cacerts/* ${PEER_DIR}/tls/ca.crt
  else
    echo "❌ TLS CA cert not found in either tlscacerts or cacerts"
    exit 1
  fi

  cp ${PEER_DIR}/tls/signcerts/* ${PEER_DIR}/tls/server.crt
  cp ${PEER_DIR}/tls/keystore/* ${PEER_DIR}/tls/server.key

  echo "✅ Enrolled: ${PEER_NAME}.${ORG_DOMAIN}"
done

echo "🎉 Done! peer1-3 enrolled for $ORG_DOMAIN"
