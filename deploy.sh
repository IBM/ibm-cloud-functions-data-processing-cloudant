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
  echo "Installing OpenWhisk actions, triggers, and rules for Cloudant sample..."

  echo "Binding Cloudant package with credential parameters"
  wsk package bind /whisk.system/cloudant "$CLOUDANT_INSTANCE" \
    --param username "$CLOUDANT_USERNAME" \
    --param password "$CLOUDANT_PASSWORD" \
    --param host "$CLOUDANT_USERNAME.cloudant.com"

  echo "Creating trigger to fire events when data is inserted"
  wsk trigger create image-uploaded \
    --feed "/_/$CLOUDANT_INSTANCE/changes" \
    --param dbname "$CLOUDANT_DATABASE"

  echo "Creating action that is manually invoked to write to the database"
  wsk action create write-to-cloudant actions/write-to-cloudant.js \
    --param CLOUDANT_USERNAME "$CLOUDANT_USERNAME" \
    --param CLOUDANT_PASSWORD "$CLOUDANT_PASSWORD" \
    --param CLOUDANT_DATABASE "$CLOUDANT_DATABASE"

  echo "Creating action to respond to database insertions"
  wsk action create write-from-cloudant actions/write-from-cloudant.js

  echo "Creating sequence that ties database read to handling action"
  wsk action create write-from-cloudant-sequence \
    --sequence /_/$CLOUDANT_INSTANCE/read,write-from-cloudant

  echo "Creating rule that maps database change trigger to sequence"
  wsk rule create echo-images image-uploaded write-from-cloudant-sequence

  echo "Install complete"
}

function uninstall() {
  echo "Uninstalling..."

  echo "Removing rules..."
  wsk rule disable echo-images
  sleep 1
  wsk rule delete echo-images

  echo "Removing triggers..."
  wsk trigger delete image-uploaded

  echo "Removing actions..."
  wsk action delete write-to-cloudant
  wsk action delete write-from-cloudant
  wsk action delete write-from-cloudant-sequence

  echo "Removing packages..."
  wsk package delete "$CLOUDANT_INSTANCE"

  echo "Uninstall complete"
}

function showenv() {
  echo -e CLOUDANT_INSTANCE="$CLOUDANT_INSTANCE"
  echo -e CLOUDANT_USERNAME="$CLOUDANT_USERNAME"
  echo -e CLOUDANT_PASSWORD="$CLOUDANT_PASSWORD"
  echo -e CLOUDANT_DATABASE="$CLOUDANT_DATABASE"
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
