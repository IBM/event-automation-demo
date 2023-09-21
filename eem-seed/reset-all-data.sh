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

cookieCurlParams() {
    USERNAME="${1}"
    COOKIE_JAR="/tmp/${USERNAME}-cookies.txt"
    echo -n "-b ${COOKIE_JAR} -c ${COOKIE_JAR}"
}

csrfHeader() {
    USERNAME="${1}"
    COOKIE_JAR="/tmp/${USERNAME}-cookies.txt"
    CSRF=($(cat -v ${COOKIE_JAR} | grep "ibm-ei-csrf-token"))
    CSRF_TOKEN="${CSRF[6]}"
    CSRF_TOKEN="${CSRF_TOKEN//^M/}"
    echo -n "x-ibm-ei-csrf-token: ${CSRF_TOKEN}"
}

login() {
    echo "Logging in as ${1}"
    USERNAME="${1}"
    PASSWORD="${2}"
    # count the number of times we have tried this
    #  default to "first" attempt if not specified
    ATTEMPT=${3:-1}

    COOKIE_JAR="/tmp/${USERNAME}-cookies.txt"
    HEADERS_FILE="/tmp/login-response-headers.txt"

    # Trigger redirect and capture response
    REDIRECT_RESPONSE=$(curl -f -k -s ${EEM_API} -c ${COOKIE_JAR} || true)
    if [ -z "$REDIRECT_RESPONSE" ]
    then
        echo "Login unsuccessful."
        if [[ $ATTEMPT -lt 5 ]]
        then
            echo "Retrying..."
            sleep 2
            login $USERNAME $PASSWORD $((ATTEMPT+=1))
            return
        else
            exit 1
        fi
    fi

    # Parse the response to identify callback URL
    PARTS=($(echo $REDIRECT_RESPONSE | tr "?" " "))
    QUERY=${PARTS[3]}
    QUERY_PARAMS=($(echo $QUERY | tr "&" " "))

    # Use response state to login as user and capture callback
    curl -k -f "${EEM_API}/login/oauth/authorize/login" -F "username=${USERNAME}" -F "password=${PASSWORD}" -F ${QUERY_PARAMS[0]} -D ${HEADERS_FILE}
    LOCATION=($(cat -v ${HEADERS_FILE} | grep location))
    CALLBACK="${LOCATION[1]}"
    CALLBACK="${CALLBACK//^M/}"
    rm ${HEADERS_FILE}

    # Call callback
    curl -s -k "${CALLBACK}" $(cookieCurlParams ${USERNAME}) -o /dev/null

    # Print user and grab CSRF
    echo "Authenticated user"
    curl -k "${EEM_API}/auth/protected/userinfo" $(cookieCurlParams ${USERNAME}) -s -o /dev/null
}

# get the namespace from a command line argument
NAMESPACE=$1

# get location of the EEM manager (also useful for checking that oc login has been run)
EEM_API=$(oc get route -n $NAMESPACE my-eem-manager-ibm-eem-manager -ojsonpath='https://{.spec.host}')


# check namespace option provided
if [ $# -eq 0 ]; then
    >&2 echo "Usage: reset-all-data.sh <NAMESPACE>"
    exit 1
fi


# --------------------------------------
# WARNING
#
#  ensure the user is aware the script
#  will clear the EEM storage
# --------------------------------------

echo "========================================================================="
echo " Event Automation tutorial setup "
echo " ----------------------------------------------------------------------- "
echo " This will CLEAR ALL STORAGE for the my-eem-manager instance "
echo "  of Event Endpoint Management in the $NAMESPACE namespace "
echo "  and replace it with definitions for the tutorial topics. "
echo "========================================================================="
read -p "Press Y to continue: " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
fi

echo "..."

# --------------------------------------
# RESET
#
#  clear the EEM storage
# --------------------------------------

echo "> Clearing existing storage"

oc exec -it -n $NAMESPACE my-eem-manager-ibm-eem-manager-0 -- rm -rf /opt/storage/eem
oc delete pod -n $NAMESPACE my-eem-manager-ibm-eem-manager-0
# waiting for replacement pod to be created
until oc get pod -n $NAMESPACE my-eem-manager-ibm-eem-manager-0 >/dev/null 2>&1; do
    sleep 1
done
# waiting for replacement pod to become ready
oc wait -n $NAMESPACE --for=condition=ready pod my-eem-manager-ibm-eem-manager-0 --timeout=180s


# --------------------------------------
# Login
#
#  login with various users
# --------------------------------------

echo "> Logging into EEM manager"

# TODO - get credentials dynamically
CURRENT_USER=eem-admin
PWD='Th1$ISTh3Adm1nPa$SW0Rd'
login ${CURRENT_USER} ${PWD}


# --------------------------------------
# CLUSTER
#
#  add the Event Streams cluster to EEM
# --------------------------------------

echo "> Submitting Event Streams cluster information"

# get the certificates for the the Kafka cluster
bootstrap_response=$(curl -s -X POST -k -k $(cookieCurlParams ${CURRENT_USER}) \
    -H "$(csrfHeader ${CURRENT_USER})" \
    -H "Content-Type: application/json" \
    --data "{\"bootstrapServers\":[{\"host\":\"my-kafka-cluster-kafka-bootstrap.$NAMESPACE.svc\",\"port\":9095}]}" \
    $EEM_API/api/discovery/validate-bootstrap )

# add the credentials to the cluster definition
credentials=$(cat eem-01-credentials.tmpl | sed "s/PLACEHOLDER/$(oc get secret es-admin -n $NAMESPACE -ojsonpath='{.data.password}' | base64 -d)/")
echo "$bootstrap_response" | tr '\n' ' ' | sed "s/, *\"errors\" : \[ \"SSL_HANDSHAKE_EXCEPTION\" \] *} *\]/$credentials/g" > /tmp/eem-new-cluster.json

# submit the cluster definition
curl -X POST -s -k $(cookieCurlParams ${CURRENT_USER}) \
    -H "$(csrfHeader ${CURRENT_USER})" \
    -H "Content-Type: application/json" \
    --data @/tmp/eem-new-cluster.json \
    $EEM_API/api/eem/clusters

# cleanup
rm /tmp/eem-new-cluster.json


# --------------------------------------
# TOPICS
#
#  add the topics to EEM
# --------------------------------------

echo "> Submitting Kafka topics"

curl -X POST -s -k $(cookieCurlParams ${CURRENT_USER}) \
    -H "$(csrfHeader ${CURRENT_USER})" \
    -H "Content-Type: application/json" \
    --data @eem-02-topics.json \
    $EEM_API/api/eem/catalogues/entries


# --------------------------------------
# DOCUMENT
#
#  document & publish the topics in EEM
# --------------------------------------

echo "> Documenting Kafka topics"

curl -k -s $(cookieCurlParams ${CURRENT_USER}) \
    $EEM_API/api/eem/topics > /tmp/eem-topics.json

topics=("CANCELLATIONS" "CUSTOMERS.NEW" "DOOR.BADGEIN" "ORDERS.NEW" "SENSOR.READINGS" "STOCK.MOVEMENT")
for topic in "${topics[@]}"
do

    topicid=$(grep -B 1 "\"alias\" : \"$topic\"" /tmp/eem-topics.json | grep '"id"' | cut -d '"' -f 4)
    cat eem-03-$topic.json | sed "s/PLACEHOLDERID/$topicid/g" > /tmp/eem-topic.json

    curl -X POST -s -k $(cookieCurlParams ${CURRENT_USER}) \
        -H "$(csrfHeader ${CURRENT_USER})" \
        -H "Content-Type: application/json" \
        --data @/tmp/eem-topic.json \
        $EEM_API/api/eem/catalogues/entries/$topicid
    cat eem-04-gateway.json | sed "s/PLACEHOLDERID/$topicid/g" > /tmp/eem-gateway.json
    curl -X POST -s -k $(cookieCurlParams ${CURRENT_USER}) \
        -H "$(csrfHeader ${CURRENT_USER})" \
        -H "Content-Type: application/json" \
        --data @/tmp/eem-gateway.json \
        $EEM_API/api/eem/publish

done

# cleanup
rm /tmp/eem-topic.json
rm /tmp/eem-gateway.json


# --------------------------------------

echo "complete"
