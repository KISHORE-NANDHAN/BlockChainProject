#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0
#

# Import utility functions
. scripts/envVar.sh
. scripts/configUpdate.sh

# Create anchor peer update transaction
createAnchorPeerUpdate() {
  infoln "📥 Fetching channel config for channel '${CHANNEL_NAME}'..."
  fetchChannelConfig "$ORG" "$CHANNEL_NAME" "${CORE_PEER_LOCALMSPID}config.json"

  infoln "⚙️ Generating anchor peer update transaction for ${CORE_PEER_LOCALMSPID} on channel '${CHANNEL_NAME}'..."

  # Define anchor peer details based on ORG number
  if [ "$ORG" -eq 1 ]; then
    HOST="clerk.itda.gov.in"
    PORT=7051
  elif [ "$ORG" -eq 2 ]; then
    HOST="project_officer.district.gov.in"
    PORT=9051
  elif [ "$ORG" -eq 3 ]; then
    HOST="mro.revenue.gov.in"
    PORT=11051
  else
    errorln "❌ Unknown organization ID: ${ORG}"
    exit 1
  fi

  # Inject anchor peer configuration into modified config JSON
  set -x
  jq '.channel_group.groups.Application.groups."'${CORE_PEER_LOCALMSPID}'".values += {
      "AnchorPeers": {
        "mod_policy": "Admins",
        "value": {
          "anchor_peers": [{
            "host": "'$HOST'",
            "port": '$PORT'
          }]
        },
        "version": "0"
      }
    }' "${CORE_PEER_LOCALMSPID}config.json" > "${CORE_PEER_LOCALMSPID}modified_config.json"
  { set +x; } 2>/dev/null

  # Create config update transaction file
  createConfigUpdate "$CHANNEL_NAME" "${CORE_PEER_LOCALMSPID}config.json" "${CORE_PEER_LOCALMSPID}modified_config.json" "${CORE_PEER_LOCALMSPID}anchors.tx"
}

# Submit anchor peer update to the channel
updateAnchorPeer() {
  infoln "📤 Submitting anchor peer update transaction for ${CORE_PEER_LOCALMSPID}..."
  set -x
  peer channel update \
    -o orderer.example.com:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    -c "$CHANNEL_NAME" \
    -f "${CORE_PEER_LOCALMSPID}anchors.tx" \
    --tls --cafile "$ORDERER_CA" >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "❌ Anchor peer update failed for ${CORE_PEER_LOCALMSPID}"
  successln "✅ Anchor peer set successfully for ${CORE_PEER_LOCALMSPID} on channel '${CHANNEL_NAME}'"
}

# MAIN
ORG=$1
CHANNEL_NAME=$2

setGlobalsCLI "$ORG"
createAnchorPeerUpdate
updateAnchorPeer
