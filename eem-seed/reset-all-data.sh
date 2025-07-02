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
# RESET
#
#  clear the EEM storage
# --------------------------------------
function reset_eem() {
    echo " ----------------------------------------------------------------------- "
    echo " This will CLEAR ALL STORAGE for the my-eem-manager instance "
    echo "  of Event Endpoint Management in the $NAMESPACE namespace "
    echo "  and replace it with definitions for the tutorial topics. "
    echo " ----------------------------------------------------------------------- "
    read -p "Press Y to continue: " -n 1 -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
    fi

    echo "..."

    echo "> Clearing existing storage"

    oc exec -it -n $NAMESPACE my-eem-manager-ibm-eem-manager-0 -- rm -rf /opt/storage/eem
    oc delete pod -n $NAMESPACE my-eem-manager-ibm-eem-manager-0
    # waiting for replacement pod to be created
    until oc get pod -n $NAMESPACE my-eem-manager-ibm-eem-manager-0 >/dev/null 2>&1; do
        sleep 1
    done
    # waiting for replacement pod to become ready
    oc wait -n $NAMESPACE --for=condition=ready pod my-eem-manager-ibm-eem-manager-0 --timeout=120s
}


# --------------------------------------
# Helper function to get the ID returned
#  by the API when we create new things
# --------------------------------------
extract_id() {
    grep -o '"id"\s*:\s*"[^"]*' $1 | grep -o '[^"]*$'
}



# --------------------------------------
# CLUSTER
#
#  add the Event Streams cluster to EEM
# --------------------------------------

echo "> (1/3) Getting Event Streams cluster information"

# get the certificates for the Kafka cluster
ES_CERTIFICATE=$(oc get eventstreams my-kafka-cluster -n $NAMESPACE -o jsonpath='{.status.kafkaListeners[?(@.name=="authsslsvc")].certificates[0]}')
ES_CERTIFICATE=${ES_CERTIFICATE//$'\n'/\\\\n}

# get the password for the Kafka cluster
ES_PASSWORD=$(oc get secret kafka-demo-apps -n $NAMESPACE -ojsonpath='{.data.password}' | base64 -d)

# substitute details into the template
cat eem-01-cluster.json | \
    sed "s|ES_NAMESPACE|$NAMESPACE|" | \
    sed "s|ES_CERTIFICATE|$ES_CERTIFICATE|" | \
    sed "s|ES_PASSWORD|$ES_PASSWORD|" > \
    eem-request-new-cluster.json

# submit the cluster definition
echo "> (2/3) Submitting Event Streams cluster information"
(
    set +e

    RESPONSE=$(curl -X POST -s -k \
                --dump-header eem-api-header \
                -H 'Accept: application/json' \
                -H 'Content-Type: application/json' \
                -H "Authorization: Bearer $ACCESS_TOKEN" \
                --data @eem-request-new-cluster.json \
                --output eem-response-new-cluster.json \
                --write-out '%{response_code}' \
                $EEM_API/eem/clusters)

    if [ $? != 0 ]
    then
        echo " ----------------------------------------------------------------------- "
        echo "ERROR: Failed to connect to Event Endpoint Management"
        exit 1

    elif [ "$RESPONSE" == "409" ]
    then
        echo " ----------------------------------------------------------------------- "
        echo "ERROR: Event Streams cluster already in Event Endpoint Management"
        echo ""

        reset_eem

        echo ""
        echo "You can now re-run this script (with a new access token)."
        echo ""

        exit $RESPONSE

    elif [[ "$RESPONSE" != \2* ]]
    then
        echo " ----------------------------------------------------------------------- "
        echo "ERROR: Failed to submit Event Streams cluster information"
        echo ""
        cat eem-api-header
        exit $RESPONSE
    fi
)

# read the new cluster id into a variable so we can
#  add topics from this cluster
CLUSTERID=$(extract_id eem-response-new-cluster.json)

# cleanup
rm -f eem-request-new-cluster.json
rm -f eem-response-new-cluster.json


# --------------------------------------
# TOPICS
#
#  add the topics to EEM
# --------------------------------------

echo "> (3/3) Submitting Kafka topics"

topics=("CANCELLATIONS" "CUSTOMERS.NEW" "DOOR.BADGEIN" "ORDERS.ONLINE" "ORDERS.NEW" "STOCK.NOSTOCK" "SENSOR.READINGS" "STOCK.MOVEMENT" "PRODUCT.RETURNS" "PRODUCT.REVIEWS" "TRANSACTIONS" "ORDERS.ABANDONED")
for topic in "${topics[@]}"
do
    echo "         $topic"

    # -------------------------
    # adding topic
    # -------------------------

    cat eem-03-$topic.json | \
        sed "s|CLUSTERID|$CLUSTERID|" > \
        eem-request-new-topic.json

    RESPONSE=$(curl -X POST -s -k \
                    --dump-header eem-api-header \
                    -H 'Accept: application/json' \
                    -H 'Content-Type: application/json' \
                    -H "Authorization: Bearer $ACCESS_TOKEN" \
                    --data @eem-request-new-topic.json \
                    --output eem-response-new-topic.json \
                    --write-out '%{response_code}' \
                    $EEM_API/eem/eventsources)
    if [[ "$RESPONSE" != \2* ]]
    then
        echo " ----------------------------------------------------------------------- "
        echo "ERROR: Failed to submit topic $topic"
        echo ""
        cat eem-api-header
        exit $RESPONSE
    fi

    # read the new topic id into a variable so we can
    #  add an option to this topic
    TOPICID=$(extract_id eem-response-new-topic.json)

    # -------------------------
    # publishing topic
    # -------------------------

    cat eem-03-$topic-option.json | \
        sed "s|EVENTSOURCEID|$TOPICID|" > \
        eem-request-new-topic-option.json

    RESPONSE=$(curl -X POST -s -k \
                    --dump-header eem-api-header \
                    -H 'Accept: application/json' \
                    -H 'Content-Type: application/json' \
                    -H "Authorization: Bearer $ACCESS_TOKEN" \
                    --data @eem-request-new-topic-option.json \
                    --output /dev/null \
                    --write-out '%{response_code}' \
                    $EEM_API/eem/options)
    if [[ "$RESPONSE" != \2* ]]
    then
        echo " ----------------------------------------------------------------------- "
        echo "ERROR: Failed to submit topic $topic option"
        echo ""
        cat eem-api-header
        exit $RESPONSE
    fi
done


# cleanup
rm -f eem-api-header
rm -f eem-request-new-topic.json
rm -f eem-response-new-topic.json
rm -f eem-request-new-topic-option.json

# --------------------------------------

echo "complete"
