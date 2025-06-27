#!/bin/bash

function createOrg1() {
  infoln "Enrolling the CA admin"
  mkdir -p organizations/peerOrganizations/itda.gov.in/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/itda.gov.in/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca-itda --tls.certfiles "${PWD}/organizations/fabric-ca/itda/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-itda.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-itda.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-itda.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-itda.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/peerOrganizations/itda.gov.in/msp/config.yaml"

  infoln "Registering clerk"
  set -x
  fabric-ca-client register --caname ca-itda --id.name clerk --id.secret clerkpw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/itda/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering user"
  set -x
  fabric-ca-client register --caname ca-itda --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/itda/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the org admin"
  set -x
  fabric-ca-client register --caname ca-itda --id.name itdaadmin --id.secret itdaadminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/itda/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the clerk msp"
  set -x
  fabric-ca-client enroll -u https://clerk:clerkpw@localhost:7054 --caname ca-itda -M "${PWD}/organizations/peerOrganizations/itda.gov.in/peers/clerk.itda.gov.in/msp" --csr.hosts clerk.itda.gov.in --tls.certfiles "${PWD}/organizations/fabric-ca/itda/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/itda.gov.in/msp/config.yaml" "${PWD}/organizations/peerOrganizations/itda.gov.in/peers/clerk.itda.gov.in/msp/config.yaml"

  infoln "Generating the clerk-tls certificates"
  set -x
  fabric-ca-client enroll -u https://clerk:clerkpw@localhost:7054 --caname ca-itda -M "${PWD}/organizations/peerOrganizations/itda.gov.in/peers/clerk.itda.gov.in/tls" --enrollment.profile tls --csr.hosts clerk.itda.gov.in --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/itda/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/itda.gov.in/peers/clerk.itda.gov.in/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/itda.gov.in/peers/clerk.itda.gov.in/tls/ca.crt"
  cp "${PWD}/organizations/peerOrganizations/itda.gov.in/peers/clerk.itda.gov.in/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/itda.gov.in/peers/clerk.itda.gov.in/tls/server.crt"
  cp "${PWD}/organizations/peerOrganizations/itda.gov.in/peers/clerk.itda.gov.in/tls/keystore/"* "${PWD}/organizations/peerOrganizations/itda.gov.in/peers/clerk.itda.gov.in/tls/server.key"

  mkdir -p "${PWD}/organizations/peerOrganizations/itda.gov.in/msp/tlscacerts"
  cp "${PWD}/organizations/peerOrganizations/itda.gov.in/peers/clerk.itda.gov.in/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/itda.gov.in/msp/tlscacerts/ca.crt"

  mkdir -p "${PWD}/organizations/peerOrganizations/itda.gov.in/tlsca"
  cp "${PWD}/organizations/peerOrganizations/itda.gov.in/peers/clerk.itda.gov.in/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/itda.gov.in/tlsca/tlsca.itda.gov.in-cert.pem"

  mkdir -p "${PWD}/organizations/peerOrganizations/itda.gov.in/ca"
  cp "${PWD}/organizations/peerOrganizations/itda.gov.in/peers/clerk.itda.gov.in/msp/cacerts/"* "${PWD}/organizations/peerOrganizations/itda.gov.in/ca/ca.itda.gov.in-cert.pem"

  infoln "Generating the user msp"
  set -x
  fabric-ca-client enroll -u https://user1:user1pw@localhost:7054 --caname ca-itda -M "${PWD}/organizations/peerOrganizations/itda.gov.in/users/User1@itda.gov.in/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/itda/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/itda.gov.in/msp/config.yaml" "${PWD}/organizations/peerOrganizations/itda.gov.in/users/User1@itda.gov.in/msp/config.yaml"

  infoln "Generating the org admin msp"
  set -x
  fabric-ca-client enroll -u https://itdaadmin:itdaadminpw@localhost:7054 --caname ca-itda -M "${PWD}/organizations/peerOrganizations/itda.gov.in/users/Admin@itda.gov.in/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/itda/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/itda.gov.in/msp/config.yaml" "${PWD}/organizations/peerOrganizations/itda.gov.in/users/Admin@itda.gov.in/msp/config.yaml"
}

function createOrg2() {
  infoln "Enrolling the CA admin"
  mkdir -p organizations/peerOrganizations/district.gov.in/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/district.gov.in/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:8054 --caname ca-district --tls.certfiles "${PWD}/organizations/fabric-ca/district/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-district.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-district.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-district.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-district.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/peerOrganizations/district.gov.in/msp/config.yaml"

  infoln "Registering project_officer"
  set -x
  fabric-ca-client register --caname ca-district --id.name project_officer --id.secret project_officerpw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/district/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering user"
  set -x
  fabric-ca-client register --caname ca-district --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/district/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the org admin"
  set -x
  fabric-ca-client register --caname ca-district --id.name districtadmin --id.secret districtadminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/district/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the project_officer msp"
  set -x
  fabric-ca-client enroll -u https://project_officer:project_officerpw@localhost:8054 --caname ca-district -M "${PWD}/organizations/peerOrganizations/district.gov.in/peers/project_officer.district.gov.in/msp" --csr.hosts project_officer.district.gov.in --tls.certfiles "${PWD}/organizations/fabric-ca/district/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/district.gov.in/msp/config.yaml" "${PWD}/organizations/peerOrganizations/district.gov.in/peers/project_officer.district.gov.in/msp/config.yaml"

  infoln "Generating the project_officer-tls certificates"
  set -x
  fabric-ca-client enroll -u https://project_officer:project_officerpw@localhost:8054 --caname ca-district -M "${PWD}/organizations/peerOrganizations/district.gov.in/peers/project_officer.district.gov.in/tls" --enrollment.profile tls --csr.hosts project_officer.district.gov.in --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/district/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/district.gov.in/peers/project_officer.district.gov.in/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/district.gov.in/peers/project_officer.district.gov.in/tls/ca.crt"
  cp "${PWD}/organizations/peerOrganizations/district.gov.in/peers/project_officer.district.gov.in/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/district.gov.in/peers/project_officer.district.gov.in/tls/server.crt"
  cp "${PWD}/organizations/peerOrganizations/district.gov.in/peers/project_officer.district.gov.in/tls/keystore/"* "${PWD}/organizations/peerOrganizations/district.gov.in/peers/project_officer.district.gov.in/tls/server.key"

  mkdir -p "${PWD}/organizations/peerOrganizations/district.gov.in/msp/tlscacerts"
  cp "${PWD}/organizations/peerOrganizations/district.gov.in/peers/project_officer.district.gov.in/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/district.gov.in/msp/tlscacerts/ca.crt"

  mkdir -p "${PWD}/organizations/peerOrganizations/district.gov.in/tlsca"
  cp "${PWD}/organizations/peerOrganizations/district.gov.in/peers/project_officer.district.gov.in/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/district.gov.in/tlsca/tlsca.district.gov.in-cert.pem"

  mkdir -p "${PWD}/organizations/peerOrganizations/district.gov.in/ca"
  cp "${PWD}/organizations/peerOrganizations/district.gov.in/peers/project_officer.district.gov.in/msp/cacerts/"* "${PWD}/organizations/peerOrganizations/district.gov.in/ca/ca.district.gov.in-cert.pem"

  infoln "Generating the user msp"
  set -x
  fabric-ca-client enroll -u https://user1:user1pw@localhost:8054 --caname ca-district -M "${PWD}/organizations/peerOrganizations/district.gov.in/users/User1@district.gov.in/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/district/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/district.gov.in/msp/config.yaml" "${PWD}/organizations/peerOrganizations/district.gov.in/users/User1@district.gov.in/msp/config.yaml"

  infoln "Generating the org admin msp"
  set -x
  fabric-ca-client enroll -u https://districtadmin:districtadminpw@localhost:8054 --caname ca-district -M "${PWD}/organizations/peerOrganizations/district.gov.in/users/Admin@district.gov.in/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/district/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/district.gov.in/msp/config.yaml" "${PWD}/organizations/peerOrganizations/district.gov.in/users/Admin@district.gov.in/msp/config.yaml"
}

function createOrderer() {
  infoln "Enrolling the CA admin"
  mkdir -p organizations/ordererOrganizations/example.com

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrganizations/example.com

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:9054 --caname ca-orderer --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/ordererOrganizations/example.com/msp/config.yaml"

  infoln "Registering orderer"
  set -x
  fabric-ca-client register --caname ca-orderer --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the orderer admin"
  set -x
  fabric-ca-client register --caname ca-orderer --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the orderer msp"
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp" --csr.hosts orderer.example.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/ordererOrganizations/example.com/msp/config.yaml" "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/config.yaml"

  infoln "Generating the orderer-tls certificates"
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls" --enrollment.profile tls --csr.hosts orderer.example.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/tlscacerts/"* "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt"
  cp "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/signcerts/"* "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt"
  cp "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/keystore/"* "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key"

  mkdir -p "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts"
  cp "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/tlscacerts/"* "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

  mkdir -p "${PWD}/organizations/ordererOrganizations/example.com/msp/tlscacerts"
  cp "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/tlscacerts/"* "${PWD}/organizations/ordererOrganizations/example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

  infoln "Generating the admin msp"
  set -x
  fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:9054 --caname ca-orderer -M "${PWD}/organizations/ordererOrganizations/example.com/users/Admin@example.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/ordererOrganizations/example.com/msp/config.yaml" "${PWD}/organizations/ordererOrganizations/example.com/users/Admin@example.com/msp/config.yaml"
}
