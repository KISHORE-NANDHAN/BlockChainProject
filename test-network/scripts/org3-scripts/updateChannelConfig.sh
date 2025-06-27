#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0
#

# This script creates and submits a configuration transaction to add RevenueMSP to the test network

CHANNEL_NAME="$1"
DELAY="$2"
TIMEOUT="$3"
VERBOSE="$4"

: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${TIMEOUT:="10"}
: ${VERBOSE:="false"}
COUNTER=1
MAX_RETRY=5

# Import utility scripts
. scripts/envVar.sh
. scripts/configUpdate.sh
. scripts/utils.sh

infoln "🔧 Creating config transaction to add RevenueMSP (revenue.gov.in) to the channel '${CHANNEL_NAME}'..."

# Step 1: Fetch the current channel config (using Org1 = itda.gov.in)
fetchChannelConfig 1 ${CHANNEL_NAME} config.json

# Step 2: Append RevenueMSP (Org3) to the config
infoln "📦 Modifying configuration to include RevenueMSP..."
set -x
jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"RevenueMSP":.[1]}}}}}' \
  config.json ../organizations/peerOrganizations/revenue.gov.in/revenue.json > modified_config.json
{ set +x; } 2>/dev/null

# Step 3: Compute the config update envelope
infoln "🛠️ Computing config update..."
createConfigUpdate ${CHANNEL_NAME} config.json modified_config.json revenue_update_in_envelope.pb

# Step 4: Sign the config update as ItdaMSP
infoln "✍️ Signing config update as ItdaMSP (Org1)..."
signConfigtxAsPeerOrg 1 revenue_update_in_envelope.pb

# Step 5: Submit the config update from DistrictMSP (Org2)
infoln "📤 Submitting config update from DistrictMSP (Org2)..."
setGlobals 2
set -x
peer channel update -f revenue_update_in_envelope.pb -c ${CHANNEL_NAME} \
  -o orderer.example.com:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls --cafile "$ORDERER_CA"
{ set +x; } 2>/dev/null

successln "✅ RevenueMSP (revenue.gov.in) has been successfully added to channel '${CHANNEL_NAME}'"
