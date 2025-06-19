#!/bin/bash

orgs=("org1" "org2" "org3")
peers=("peer1" "peer2" "peer3")

for org in "${orgs[@]}"; do
  for peer in "${peers[@]}"; do
    path="./organizations/peerOrganizations/${org}.example.com/peers/${peer}.${org}.example.com"
    echo "🔍 Checking $path"
    if [[ -d "$path" ]]; then
      missing=()
      [[ -f "$path/core.yaml" ]] || missing+=("core.yaml")
      [[ -d "$path/msp" ]] || missing+=("msp/")
      [[ -d "$path/tls" ]] || missing+=("tls/")
      if [ ${#missing[@]} -eq 0 ]; then
        echo "✅ All OK"
      else
        echo "❌ Missing: ${missing[*]}"
      fi
    else
      echo "🚫 Directory $path does not exist"
    fi
    echo ""
  done
done
