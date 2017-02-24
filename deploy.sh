#!/bin/bash
#
# Copyright 2017 IBM Corp. All Rights Reserved.
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

# Load configuration variables
source local.env

function usage() {
  echo -e "Usage: $0 [--install,--uninstall,--env]"
}

function install() {
  echo -e "Installing OpenWhisk actions, triggers, and rules for Cloudant sample..."

  echo "Binding package"
  wsk package bind /whisk.system/cloudant "$CLOUDANT_INSTANCE" \
    --param username "$CLOUDANT_USERNAME" \
    --param password "$CLOUDANT_PASSWORD" \
    --param host "$CLOUDANT_USERNAME.cloudant.com"

  echo "Creating triggers"
  wsk trigger create image-ready-to-echo \
    --feed "/_/$CLOUDANT_INSTANCE/changes" \
    --param dbname "$CLOUDANT_DATABASE"

  echo "Creating actions"
  wsk action create write-to-cloudant actions/write-to-cloudant.js \
    --param CLOUDANT_USERNAME "$CLOUDANT_USERNAME" \
    --param CLOUDANT_PASSWORD "$CLOUDANT_PASSWORD" \
    --param CLOUDANT_DATABASE "$CLOUDANT_DATABASE"

  wsk action create read-from-cloudant actions/read-from-cloudant.js

  # The new approach for processing Cloudant database triggers.
  wsk action create read-from-cloudant-sequence \
    --sequence /_/$CLOUDANT_INSTANCE/read,read-from-cloudant

  echo "Enabling rules"
  wsk rule create echo-images image-ready-to-echo read-from-cloudant-sequence

  echo -e "Install Complete"
}

function uninstall() {
  echo -e "Uninstalling..."

  echo "Removing rules..."
  wsk rule disable echo-images
  sleep 1
  wsk rule delete echo-images

  echo "Removing triggers..."
  wsk trigger delete image-ready-to-echo

  echo "Removing actions..."
  wsk action delete write-to-cloudant
  wsk action delete read-from-cloudant
  wsk action delete read-from-cloudant-sequence

  echo "Removing packages..."
  wsk package delete "$CLOUDANT_INSTANCE"

  echo -e "Uninstall Complete"
}

function showenv() {
  echo CLOUDANT_INSTANCE="$CLOUDANT_INSTANCE"
  echo CLOUDANT_USERNAME="$CLOUDANT_USERNAME"
  echo CLOUDANT_PASSWORD="$CLOUDANT_PASSWORD"
  echo CLOUDANT_DATABASE="$CLOUDANT_DATABASE"
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
