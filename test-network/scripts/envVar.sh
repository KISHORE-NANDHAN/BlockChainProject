#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0
#

# Imports
. scripts/utils.sh

# Global TLS flags and paths
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA="${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
export PEER0_ORG1_CA="${PWD}/organizations/peerOrganizations/itda.gov.in/peers/clerk.itda.gov.in/tls/ca.crt"
export PEER0_ORG2_CA="${PWD}/organizations/peerOrganizations/district.gov.in/peers/project_officer.district.gov.in/tls/ca.crt"
export PEER0_ORG3_CA="${PWD}/organizations/peerOrganizations/revenue.gov.in/peers/mro.revenue.gov.in/tls/ca.crt"
export ORDERER_ADMIN_TLS_SIGN_CERT="${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt"
export ORDERER_ADMIN_TLS_PRIVATE_KEY="${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key"

# Set environment variables for the peer org
setGlobals() {
  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG="$1"
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi

  infoln "🌐 Using organization $USING_ORG"
  if [ "$USING_ORG" -eq 1 ]; then
    export CORE_PEER_LOCALMSPID="ItdaMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE="$PEER0_ORG1_CA"
    export CORE_PEER_MSPCONFIGPATH="${PWD}/organizations/peerOrganizations/itda.gov.in/users/Admin@itda.gov.in/msp"
    export CORE_PEER_ADDRESS="localhost:7051"
  elif [ "$USING_ORG" -eq 2 ]; then
    export CORE_PEER_LOCALMSPID="DistrictMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE="$PEER0_ORG2_CA"
    export CORE_PEER_MSPCONFIGPATH="${PWD}/organizations/peerOrganizations/district.gov.in/users/Admin@district.gov.in/msp"
    export CORE_PEER_ADDRESS="localhost:9051"
  elif [ "$USING_ORG" -eq 3 ]; then
    export CORE_PEER_LOCALMSPID="RevenueMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE="$PEER0_ORG3_CA"
    export CORE_PEER_MSPCONFIGPATH="${PWD}/organizations/peerOrganizations/revenue.gov.in/users/Admin@revenue.gov.in/msp"
    export CORE_PEER_ADDRESS="localhost:11051"
  else
    errorln "❌ Unknown organization ID: $USING_ORG"
  fi

  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}

# CLI version (inside CLI container)
setGlobalsCLI() {
  setGlobals "$1"
  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG="$1"
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi

  if [ "$USING_ORG" -eq 1 ]; then
    export CORE_PEER_ADDRESS="clerk.itda.gov.in:7051"
  elif [ "$USING_ORG" -eq 2 ]; then
    export CORE_PEER_ADDRESS="project_officer.district.gov.in:9051"
  elif [ "$USING_ORG" -eq 3 ]; then
    export CORE_PEER_ADDRESS="mro.revenue.gov.in:11051"
  else
    errorln "❌ Unknown organization ID: $USING_ORG"
  fi
}

# Set peer connection parameters for chaincode commands
parsePeerConnectionParameters() {
  PEER_CONN_PARMS=()
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals "$1"
    if [ "$1" -eq 1 ]; then
      PEER="clerk.itda.gov.in"
      CA="$PEER0_ORG1_CA"
    elif [ "$1" -eq 2 ]; then
      PEER="project_officer.district.gov.in"
      CA="$PEER0_ORG2_CA"
    elif [ "$1" -eq 3 ]; then
      PEER="mro.revenue.gov.in"
      CA="$PEER0_ORG3_CA"
    else
      errorln "❌ Unknown org for peer connection: $1"
      exit 1
    fi

    PEERS="$PEERS $PEER"
    PEER_CONN_PARMS+=("--peerAddresses" "${CORE_PEER_ADDRESS}")
    PEER_CONN_PARMS+=("--tlsRootCertFiles" "$CA")

    shift
  done
}

verifyResult() {
  if [ "$1" -ne 0 ]; then
    fatalln "$2"
  fi
}
