#!/bin/bash

#   Copyright 2023 IBM Corp. All Rights Reserved.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

# exit when any command fails
set -e

# allow this script to be run from other locations, despite the
#  relative file paths used in it
if [[ $BASH_SOURCE = */* ]]; then
    cd -- "${BASH_SOURCE%/*}/" || exit
fi

# check options provided
if [ $# -ne 2 ]; then
    >&2 echo "Usage: reset-all-data.sh <NAMESPACE> <ACCESS_TOKEN>"
    exit 1
fi

# get the namespace from a command line argument
NAMESPACE=$1

# get the API access token from a command line argument
ACCESS_TOKEN=$2

# get location of the EEM manager (also useful for checking that oc login has been run)
EEM_API=$(oc get route -n $NAMESPACE my-eem-manager-ibm-eem-admin -ojsonpath='https://{.spec.host}')


echo "========================================================================="
echo " Event Automation tutorial setup "
echo "========================================================================="


# --------------------------------------
# CLUSTER
#
#  add the Event Streams cluster to EEM
# --------------------------------------

echo "> (1/3) Getting Event Streams cluster information"

# get the certificates for the Kafka cluster
ES_CERTIFICATE=$(oc get eventstreams my-kafka-cluster -o jsonpath='{.status.kafkaListeners[?(@.name=="authsslsvc")].certificates[0]}')
ES_CERTIFICATE=${ES_CERTIFICATE//$'\n'/\\\\n}

# get the password for the Kafka cluster
ES_PASSWORD=$(oc get secret kafka-demo-apps -n $NAMESPACE -ojsonpath='{.data.password}' | base64 -d)

# substitute details into the template
cat eem-01-cluster.json | \
    sed "s|ES_NAMESPACE|$NAMESPACE|" | \
    sed "s|ES_CERTIFICATE|$ES_CERTIFICATE|" | \
    sed "s|ES_PASSWORD|$ES_PASSWORD|" > \
    /tmp/eem-new-cluster.json

# submit the cluster definition
echo "> (2/3) Submitting Event Streams cluster information"
(
    set +e

    RESPONSE=$(curl -X POST -s -k \
                --dump-header /tmp/eem-api-header \
                -H 'Accept: application/json' \
                -H 'Content-Type: application/json' \
                -H "Authorization: Bearer $ACCESS_TOKEN" \
                --data @/tmp/eem-new-cluster.json \
                --output /dev/null \
                --write-out '%{response_code}' \
                $EEM_API/eem/clusters)

    if [ $? != 0 ]
    then
        echo " ----------------------------------------------------------------------- "
        echo "ERROR: Failed to connect to Event Endpoint Management"
        exit 1

    elif [ "$RESPONSE" == "409" ]
    then
        echo " Ignoring (cluster already exists)"

    elif [[ "$RESPONSE" != \2* ]]
    then
        echo " ----------------------------------------------------------------------- "
        echo "ERROR: Failed to submit Event Streams cluster information"
        echo ""
        cat /tmp/eem-api-header
        exit $RESPONSE
    fi
)

# cleanup
rm /tmp/eem-new-cluster.json

# --------------------------------------
# TOPICS
#
#  add the topics to EEM
# --------------------------------------

echo "> (3/3) Submitting Kafka topics"

topics=("CANCELLATIONS" "CUSTOMERS.NEW" "DOOR.BADGEIN" "ORDERS.NEW" "SENSOR.READINGS" "STOCK.MOVEMENT")
for topic in "${topics[@]}"
do
    RESPONSE=$(curl -X POST -s -k \
                    --dump-header /tmp/eem-api-header \
                    -H 'Accept: application/json' \
                    -H 'Content-Type: application/json' \
                    -H "Authorization: Bearer $ACCESS_TOKEN" \
                    --data @eem-03-$topic.json \
                    --output /dev/null \
                    --write-out '%{response_code}' \
                    $EEM_API/eem/catalogs/default/entries)
    if [ "$RESPONSE" == "409" ]
    then
        echo " Ignoring (topic $topic already exists)"

    elif [[ "$RESPONSE" != \2* ]]
    then
        echo " ----------------------------------------------------------------------- "
        echo "ERROR: Failed to submit topic $topic"
        echo ""
        cat /tmp/eem-api-header
        exit $RESPONSE
    fi
done


# cleanup
rm /tmp/eem-api-header

# --------------------------------------

echo "complete"
