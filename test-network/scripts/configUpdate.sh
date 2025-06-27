#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0
#

# Fetches the channel config for a given channel and decodes it to JSON
fetchChannelConfig() {
  ORG="$1"
  CHANNEL="$2"
  OUTPUT="$3"

  setGlobals "$ORG"

  infoln "🔄 Fetching latest config block for channel '${CHANNEL}' from orderer..."
  set -x
  peer channel fetch config config_block.pb \
    -o orderer.example.com:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    -c "$CHANNEL" \
    --tls --cafile "$ORDERER_CA"
  configtxlator proto_decode --input config_block.pb --type common.Block --output config_block.json
  jq .data.data[0].payload.data.config config_block.json > "$OUTPUT"
  { set +x; } 2>/dev/null
  successln "✅ Channel config for '$CHANNEL' written to '$OUTPUT'"
}

# Creates a config update from the original and modified config JSONs
createConfigUpdate() {
  CHANNEL="$1"
  ORIGINAL="$2"
  MODIFIED="$3"
  OUTPUT="$4"

  infoln "🛠️  Computing config update between '$ORIGINAL' and '$MODIFIED' for channel '$CHANNEL'"
  set -x
  configtxlator proto_encode --input "$ORIGINAL" --type common.Config --output original_config.pb
  configtxlator proto_encode --input "$MODIFIED" --type common.Config --output modified_config.pb
  configtxlator compute_update --channel_id "$CHANNEL" \
    --original original_config.pb --updated modified_config.pb --output config_update.pb
  configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate --output config_update.json

  echo '{"payload":{"header":{"channel_header":{"channel_id":"'"$CHANNEL"'","type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' \
    | jq . > config_update_in_envelope.json

  configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope --output "$OUTPUT"
  { set +x; } 2>/dev/null
  successln "✅ Config update envelope created at '$OUTPUT'"
}

# Signs a config transaction by a specified org
signConfigtxAsPeerOrg() {
  ORG="$1"
  TX="$2"

  setGlobals "$ORG"

  infoln "✍️ Signing config transaction '$TX' as Org$ORG..."
  set -x
  peer channel signconfigtx -f "$TX"
  { set +x; } 2>/dev/null
  successln "✅ Org$ORG signed the config transaction"
}
