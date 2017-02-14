/**
 * Copyright 2016 IBM Corp. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

var Cloudant = require('cloudant');
var async = require('async');

/**
 * This action writes new data to a cloudant database.
 * This action is idempotent. If it fails, it can be retried.
 *
 * @param   params._id                            The id of the record in the Cloudant 'processed' database
 * @param   params.CLOUDANT_USER                 Cloudant username
 * @param   params.CLOUDANT_PASS                 Cloudant password
 * @param   params.CLOUDANT_DATABASE             Cloudant database to write data to
 * @param   params.SENDGRID_API_KEY              Cloudant password
 * @return                                       Standard OpenWhisk success/error response
 */
function main(params) {

  // Configure database connection
  console.log(params);
  var cloudant = new Cloudant({
    account: params.CLOUDANT_USER,
    password: params.CLOUDANT_PASS
  });

  var cloudantDB = cloudant.db.use(params.CLOUDANT_DATABASE);

  if (!params.deleted) {

    var dataToWrite = {};
    dataToWrite._id = "12345";
    dataToWrite.randomTextData = "asdfasdf";

    // TODO don't need waterfall here
    async.waterfall([

        // Insert the check data into the cloudant database.
        function(callback) {
          console.log('[record-check-deposit.main] Updating the database');
          cloudantDB.insert(dataToWrite, function(err, body, head) {
            if (err) {
              console.log('[record-check-deposit.main] error: cloudantDB');
              console.log(err);
              return callback(err);
            } else {
              console.log('[record-check-deposit.main] success: cloudantDB');
              console.log(body);
              return callback(null, dataToWrite);
            }
          });
        }

      ],

      function(err, result) {
        if (err) {
          console.log("[KO]", err);
        } else {
          console.log("[OK]");
        }
        whisk.done(null, err);
      }
    );

  }

  return whisk.async();
}
