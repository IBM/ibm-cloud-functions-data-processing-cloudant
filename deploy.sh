#!/bin/bash
#
# Copyright 2016 IBM Corp. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the “License”);
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Color vars to be used in shell script output
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Load configuration variables
source local.env

# Capture the namespace where actions will be created
WSK='wsk'
CURRENT_NAMESPACE=`$WSK property get --namespace | sed -n -e 's/^whisk namespace//p' | tr -d '\t '`
echo "Current namespace is $CURRENT_NAMESPACE."

function usage() {
  echo -e "${YELLOW}Usage: $0 [--install,--uninstall,--env]${NC}"
}

function install() {
  echo -e "${YELLOW}Installing OpenWhisk actions, triggers, and rules for check-deposit..."

  echo "Binding package"
  wsk package bind /whisk.system/cloudant "$CLOUDANT_INSTANCE" \
  --param username "$CLOUDANT_USER" \
  --param password "$CLOUDANT_PASS" \
  --param host "$CLOUDANT_USER.cloudant.com"

  echo "Creating triggers"
  $WSK trigger create check-ready-to-echo \
    --feed "/$CURRENT_NAMESPACE/$CLOUDANT_INSTANCE/changes" \
    --param dbname "$CLOUDANT_DATABASE"

  echo "Creating actions"
  wsk action create write-to-cloudant actions/write-to-cloudant.js \
  --param CLOUDANT_USER "$CLOUDANT_USER" \
  --param CLOUDANT_PASS "$CLOUDANT_PASS" \
  --param CLOUDANT_DATABASE "$CLOUDANT_DATABASE"

  $WSK action create write-from-cloudant actions/write-from-cloudant.js \
  --param CLOUDANT_USER "$CLOUDANT_USER" \
  --param CLOUDANT_PASS "$CLOUDANT_PASS" \
  --param CLOUDANT_DATABASE "$CLOUDANT_DATABASE"

  # The new approach for processing Cloudant database triggers.
  $WSK action create write-from-cloudant-sequence \
    --sequence /$CURRENT_NAMESPACE/$CLOUDANT_INSTANCE/read,write-from-cloudant

  echo "Enabling rules"
  $WSK rule create echo-checks check-ready-to-echo write-from-cloudant-sequence

  echo -e "${GREEN}Install Complete${NC}"
}

function uninstall() {
  echo -e "${RED}Uninstalling..."

  echo "Removing rules..."
  $WSK rule disable echo-checks
  sleep 1
  $WSK rule delete echo-checks

  echo "Removing triggers..."
  $WSK trigger delete check-ready-to-echo

  echo "Removing actions..."
  $WSK action delete write-to-cloudant
  $WSK action delete write-from-cloudant
  $WSK action delete write-from-cloudant-sequence

  echo "Removing packages..."
  $WSK package delete "$CLOUDANT_INSTANCE"

  echo -e "${GREEN}Uninstall Complete${NC}"
}

function showenv() {
  echo -e "${YELLOW}"
  echo CLOUDANT_INSTANCE=$CLOUDANT_INSTANCE
  echo CLOUDANT_USER=$CLOUDANT_USER
  echo CLOUDANT_PASS=$CLOUDANT_PASS
  echo CLOUDANT_DATABASE=$CLOUDANT_DATABASE
  echo -e "${NC}"
}

case "$1" in
"--install" )
install
;;
"--uninstall" )
uninstall
;;
"--env" )
showenv
;;
* )
usage
;;
esac
