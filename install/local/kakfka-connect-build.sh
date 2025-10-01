#!/bin/bash

#   Copyright 2025 IBM Corp. All Rights Reserved.
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

mkdir kafkaconnect
cd kafkaconnect
git clone https://github.com/ibm-messaging/kafka-connect-mq-source.git
cd kafka-connect-mq-source
git checkout v2.6.0
mvn package

cd ..
git clone https://github.com/IBM/kafka-connect-loosehangerjeans-source.git
cd kafka-connect-loosehangerjeans-source
git checkout 0.5.1
mvn package

cd ..
mkdir plugins
mkdir plugins/datagen
mkdir plugins/mq-source

cp kafka-connect-mq-source/target/kafka-connect-mq-source-*-jar-with-dependencies.jar plugins/datagen
cp kafka-connect-loosehangerjeans-source/target/kafka-connect-loosehangerjeans-source-*-jar-with-dependencies.jar plugins/mq-source

mvn dependency:get -Dartifact=io.apicurio:apicurio-registry-serdes-avro-serde:2.6.6.Final -Dmaven.repo.local=./plugins/datagen
mvn dependency:get -Dartifact=io.apicurio:apicurio-registry-utils-converter:2.6.6.Final -Dmaven.repo.local=./plugins/datagen