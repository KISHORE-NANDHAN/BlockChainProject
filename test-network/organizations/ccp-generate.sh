#!/bin/bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local ORG_NAME=$1
    local PEER_PORT=$2
    local CA_PORT=$3
    local PEER_HOST=$4
    local CA_HOST=$5
    local PEERPEM=$(one_line_pem $6)
    local CAPEM=$(one_line_pem $7)

    sed -e "s/\${ORG_NAME}/${ORG_NAME}/" \
        -e "s/\${MSPID}/${ORG_NAME}MSP/" \
        -e "s/\${PEER_PORT}/${PEER_PORT}/" \
        -e "s/\${CA_PORT}/${CA_PORT}/" \
        -e "s/\${PEER_HOST}/${PEER_HOST}/" \
        -e "s/\${CA_HOST}/${CA_HOST}/" \
        -e "s/\${CA_NAME}/ca-${ORG_NAME,,}/" \
        -e "s#\${PEERPEM}#${PEERPEM}#" \
        -e "s#\${CAPEM}#${CAPEM}#" \
        organizations/ccp-template.json
}

function yaml_ccp {
    local ORG_NAME=$1
    local PEER_PORT=$2
    local CA_PORT=$3
    local PEER_HOST=$4
    local CA_HOST=$5
    local PEERPEM=$(one_line_pem $6)
    local CAPEM=$(one_line_pem $7)

    sed -e "s/\${ORG_NAME}/${ORG_NAME}/" \
        -e "s/\${MSPID}/${ORG_NAME}MSP/" \
        -e "s/\${PEER_PORT}/${PEER_PORT}/" \
        -e "s/\${CA_PORT}/${CA_PORT}/" \
        -e "s/\${PEER_HOST}/${PEER_HOST}/" \
        -e "s/\${CA_HOST}/${CA_HOST}/" \
        -e "s/\${CA_NAME}/ca-${ORG_NAME,,}/" \
        -e "s#\${PEERPEM}#${PEERPEM}#" \
        -e "s#\${CAPEM}#${CAPEM}#" \
        organizations/ccp-template.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

# ORG 1: ITDA
ORG_NAME="ITDA"
PEER_HOST="clerk.itda.gov.in"
CA_HOST="ca.itda.gov.in"
PEER_PORT=7051
CA_PORT=7054
PEERPEM=organizations/peerOrganizations/itda.gov.in/tlsca/tlsca.itda.gov.in-cert.pem
CAPEM=organizations/peerOrganizations/itda.gov.in/ca/ca.itda.gov.in-cert.pem

echo "$(json_ccp $ORG_NAME $PEER_PORT $CA_PORT $PEER_HOST $CA_HOST $PEERPEM $CAPEM)" > organizations/peerOrganizations/itda.gov.in/connection-itda.json
echo "$(yaml_ccp $ORG_NAME $PEER_PORT $CA_PORT $PEER_HOST $CA_HOST $PEERPEM $CAPEM)" > organizations/peerOrganizations/itda.gov.in/connection-itda.yaml

# ORG 2: District
ORG_NAME="District"
PEER_HOST="projectofficer.district.gov.in"
CA_HOST="ca.district.gov.in"
PEER_PORT=8051
CA_PORT=8054
PEERPEM=organizations/peerOrganizations/district.gov.in/tlsca/tlsca.district.gov.in-cert.pem
CAPEM=organizations/peerOrganizations/district.gov.in/ca/ca.district.gov.in-cert.pem

echo "$(json_ccp $ORG_NAME $PEER_PORT $CA_PORT $PEER_HOST $CA_HOST $PEERPEM $CAPEM)" > organizations/peerOrganizations/district.gov.in/connection-district.json
echo "$(yaml_ccp $ORG_NAME $PEER_PORT $CA_PORT $PEER_HOST $CA_HOST $PEERPEM $CAPEM)" > organizations/peerOrganizations/district.gov.in/connection-district.yaml

# ORG 3: Revenue
ORG_NAME="Revenue"
PEER_HOST="mro.revenue.gov.in"
CA_HOST="ca.revenue.gov.in"
PEER_PORT=9051
CA_PORT=9054
PEERPEM=organizations/peerOrganizations/revenue.gov.in/tlsca/tlsca.revenue.gov.in-cert.pem
CAPEM=organizations/peerOrganizations/revenue.gov.in/ca/ca.revenue.gov.in-cert.pem

echo "$(json_ccp $ORG_NAME $PEER_PORT $CA_PORT $PEER_HOST $CA_HOST $PEERPEM $CAPEM)" > organizations/peerOrganizations/revenue.gov.in/connection-revenue.json
echo "$(yaml_ccp $ORG_NAME $PEER_PORT $CA_PORT $PEER_HOST $CA_HOST $PEERPEM $CAPEM)" > organizations/peerOrganizations/revenue.gov.in/connection-revenue.yaml
