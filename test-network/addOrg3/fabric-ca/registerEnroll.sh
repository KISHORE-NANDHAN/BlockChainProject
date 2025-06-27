#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

function createOrg3 {
	infoln "Enrolling the CA admin"
	mkdir -p ../organizations/peerOrganizations/revenue.gov.in/

	export FABRIC_CA_CLIENT_HOME=${PWD}/../organizations/peerOrganizations/revenue.gov.in/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:11054 --caname ca-revenue --tls.certfiles "${PWD}/fabric-ca/revenue/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-revenue.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-revenue.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-revenue.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-revenue.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/../organizations/peerOrganizations/revenue.gov.in/msp/config.yaml"

	infoln "Registering mro"
  set -x
	fabric-ca-client register --caname ca-revenue --id.name mro --id.secret mropw --id.type peer --tls.certfiles "${PWD}/fabric-ca/revenue/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering user"
  set -x
  fabric-ca-client register --caname ca-revenue --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/fabric-ca/revenue/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the org admin"
  set -x
  fabric-ca-client register --caname ca-revenue --id.name revenueadmin --id.secret revenueadminpw --id.type admin --tls.certfiles "${PWD}/fabric-ca/revenue/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the mro msp"
  set -x
	fabric-ca-client enroll -u https://mro:mropw@localhost:11054 --caname ca-revenue -M "${PWD}/../organizations/peerOrganizations/revenue.gov.in/peers/mro.revenue.gov.in/msp" --csr.hosts mro.revenue.gov.in --tls.certfiles "${PWD}/fabric-ca/revenue/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/../organizations/peerOrganizations/revenue.gov.in/msp/config.yaml" "${PWD}/../organizations/peerOrganizations/revenue.gov.in/peers/mro.revenue.gov.in/msp/config.yaml"

  infoln "Generating the mro-tls certificates"
  set -x
  fabric-ca-client enroll -u https://mro:mropw@localhost:11054 --caname ca-revenue -M "${PWD}/../organizations/peerOrganizations/revenue.gov.in/peers/mro.revenue.gov.in/tls" --enrollment.profile tls --csr.hosts mro.revenue.gov.in --csr.hosts localhost --tls.certfiles "${PWD}/fabric-ca/revenue/tls-cert.pem"
  { set +x; } 2>/dev/null


  cp "${PWD}/../organizations/peerOrganizations/revenue.gov.in/peers/mro.revenue.gov.in/tls/tlscacerts/"* "${PWD}/../organizations/peerOrganizations/revenue.gov.in/peers/mro.revenue.gov.in/tls/ca.crt"
  cp "${PWD}/../organizations/peerOrganizations/revenue.gov.in/peers/mro.revenue.gov.in/tls/signcerts/"* "${PWD}/../organizations/peerOrganizations/revenue.gov.in/peers/mro.revenue.gov.in/tls/server.crt"
  cp "${PWD}/../organizations/peerOrganizations/revenue.gov.in/peers/mro.revenue.gov.in/tls/keystore/"* "${PWD}/../organizations/peerOrganizations/revenue.gov.in/peers/mro.revenue.gov.in/tls/server.key"

  mkdir "${PWD}/../organizations/peerOrganizations/revenue.gov.in/msp/tlscacerts"
  cp "${PWD}/../organizations/peerOrganizations/revenue.gov.in/peers/mro.revenue.gov.in/tls/tlscacerts/"* "${PWD}/../organizations/peerOrganizations/revenue.gov.in/msp/tlscacerts/ca.crt"

  mkdir "${PWD}/../organizations/peerOrganizations/revenue.gov.in/tlsca"
  cp "${PWD}/../organizations/peerOrganizations/revenue.gov.in/peers/mro.revenue.gov.in/tls/tlscacerts/"* "${PWD}/../organizations/peerOrganizations/revenue.gov.in/tlsca/tlsca.revenue.gov.in-cert.pem"

  mkdir "${PWD}/../organizations/peerOrganizations/revenue.gov.in/ca"
  cp "${PWD}/../organizations/peerOrganizations/revenue.gov.in/peers/mro.revenue.gov.in/msp/cacerts/"* "${PWD}/../organizations/peerOrganizations/revenue.gov.in/ca/ca.revenue.gov.in-cert.pem"

  infoln "Generating the user msp"
  set -x
	fabric-ca-client enroll -u https://user1:user1pw@localhost:11054 --caname ca-revenue -M "${PWD}/../organizations/peerOrganizations/revenue.gov.in/users/User1@revenue.gov.in/msp" --tls.certfiles "${PWD}/fabric-ca/revenue/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/../organizations/peerOrganizations/revenue.gov.in/msp/config.yaml" "${PWD}/../organizations/peerOrganizations/revenue.gov.in/users/User1@revenue.gov.in/msp/config.yaml"

  infoln "Generating the org admin msp"
  set -x
	fabric-ca-client enroll -u https://revenueadmin:revenueadminpw@localhost:11054 --caname ca-revenue -M "${PWD}/../organizations/peerOrganizations/revenue.gov.in/users/Admin@revenue.gov.in/msp" --tls.certfiles "${PWD}/fabric-ca/revenue/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/../organizations/peerOrganizations/revenue.gov.in/msp/config.yaml" "${PWD}/../organizations/peerOrganizations/revenue.gov.in/users/Admin@revenue.gov.in/msp/config.yaml"
}
