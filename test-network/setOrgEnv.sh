#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0

# default to using itda
ORG=${1:-itda}

# Exit on error from piped command
set -o pipefail

# Determine base directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

# Common certificates
export ORDERER_CA=${DIR}/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export PEER0_ITDA_CA=${DIR}/test-network/organizations/peerOrganizations/itda.gov.in/peers/clerk.itda.gov.in/tls/ca.crt
export PEER0_DISTRICT_CA=${DIR}/test-network/organizations/peerOrganizations/district.gov.in/peers/project_officer.district.gov.in/tls/ca.crt
export PEER0_REVENUE_CA=${DIR}/test-network/organizations/peerOrganizations/revenue.gov.in/peers/mro.revenue.gov.in/tls/ca.crt

# Org-specific settings
if [[ ${ORG,,} == "itda" ]]; then

   export CORE_PEER_LOCALMSPID=ItdaMSP
   export CORE_PEER_MSPCONFIGPATH=${DIR}/test-network/organizations/peerOrganizations/itda.gov.in/users/Admin@itda.gov.in/msp
   export CORE_PEER_ADDRESS=localhost:7051
   export CORE_PEER_TLS_ROOTCERT_FILE=${PEER0_ITDA_CA}

elif [[ ${ORG,,} == "district" ]]; then

   export CORE_PEER_LOCALMSPID=DistrictMSP
   export CORE_PEER_MSPCONFIGPATH=${DIR}/test-network/organizations/peerOrganizations/district.gov.in/users/Admin@district.gov.in/msp
   export CORE_PEER_ADDRESS=localhost:9051
   export CORE_PEER_TLS_ROOTCERT_FILE=${PEER0_DISTRICT_CA}

elif [[ ${ORG,,} == "revenue" ]]; then

   export CORE_PEER_LOCALMSPID=RevenueMSP
   export CORE_PEER_MSPCONFIGPATH=${DIR}/test-network/organizations/peerOrganizations/revenue.gov.in/users/Admin@revenue.gov.in/msp
   export CORE_PEER_ADDRESS=localhost:11051
   export CORE_PEER_TLS_ROOTCERT_FILE=${PEER0_REVENUE_CA}

else
   echo "❌ Unknown organization: \"$ORG\""
   echo "✅ Valid options: itda, district, revenue"
   return 1 2>/dev/null || exit 1
fi

# Common settings
export FABRIC_CFG_PATH=${DIR}/config
export CORE_PEER_TLS_ENABLED=true

# ✅ Print environment details
echo "✅ Environment variables set for organization: $ORG"
echo "---------------------------------------------"
echo "CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID"
echo "CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH"
echo "CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS"
echo "CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE"
echo "ORDERER_CA=$ORDERER_CA"
echo "FABRIC_CFG_PATH=$FABRIC_CFG_PATH"
echo "CORE_PEER_TLS_ENABLED=$CORE_PEER_TLS_ENABLED"
echo "---------------------------------------------"
