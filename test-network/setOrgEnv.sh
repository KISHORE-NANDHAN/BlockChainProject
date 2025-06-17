#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0

# default to using Org1
ORG=${1:-Org1}

# Exit on first error, print all commands.
# set -e
set -o pipefail

# Determine base directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

# Common certificates
export ORDERER_CA=${DIR}/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export PEER0_ORG1_CA=${DIR}/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export PEER0_ORG2_CA=${DIR}/test-network/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export PEER0_ORG3_CA=${DIR}/test-network/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt

# Org-specific settings
if [[ ${ORG,,} == "org1" || ${ORG,,} == "itda" ]]; then

   export CORE_PEER_LOCALMSPID=Org1MSP
   export CORE_PEER_MSPCONFIGPATH=${DIR}/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
   export CORE_PEER_ADDRESS=localhost:7051
   export CORE_PEER_TLS_ROOTCERT_FILE=${PEER0_ORG1_CA}

elif [[ ${ORG,,} == "org2" || ${ORG,,} == "district" ]]; then

   export CORE_PEER_LOCALMSPID=Org2MSP
   export CORE_PEER_MSPCONFIGPATH=${DIR}/test-network/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
   export CORE_PEER_ADDRESS=localhost:9051
   export CORE_PEER_TLS_ROOTCERT_FILE=${PEER0_ORG2_CA}

elif [[ ${ORG,,} == "org3" || ${ORG,,} == "revenue" ]]; then

   export CORE_PEER_LOCALMSPID=Org3MSP
   export CORE_PEER_MSPCONFIGPATH=${DIR}/test-network/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
   export CORE_PEER_ADDRESS=localhost:11051
   export CORE_PEER_TLS_ROOTCERT_FILE=${PEER0_ORG3_CA}

else
   echo "❌ Unknown organization: \"$ORG\""
   echo "✅ Valid options: Org1/itda, Org2/district, Org3/revenue"
   return 1 2>/dev/null || exit 1
fi

echo "✅ Environment variables set for $ORG"
export FABRIC_CFG_PATH=${DIR}/config
export CORE_PEER_TLS_ENABLED=true