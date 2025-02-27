# Install options


---
## No persistent storage
To install everything, including a certificate manager, but without persistent storage:
```sh
ansible-playbook \
    -e license_accept=true \
    -e ibm_entitlement_key=YOUR-ENTITLEMENT-KEY \
    -e install_certmgr=true \
    -e eventautomation_namespace=event-automation \
    install/event-automation.yaml
```
---
## Use existing certificate manager
To install Event Automation without persistent storage, using an existing certificate manager:
```sh
ansible-playbook \
    -e license_accept=true \
    -e ibm_entitlement_key=YOUR-ENTITLEMENT-KEY \
    -e eventautomation_namespace=event-automation \
    install/event-automation.yaml
```
---
## Rook Ceph storage
To install everything, with persistent storage, using Rook Ceph storage classes:
```sh
ansible-playbook \
    -e license_accept=true \
    -e ibm_entitlement_key=YOUR-ENTITLEMENT-KEY \
    -e install_certmgr=true \
    -e eventstreams_storage_class=rook-ceph-block \
    -e eventendpointmanagement_storage_class=rook-cephfs \
    -e eventprocessing_storage_class=rook-cephfs \
    -e eventautomation_namespace=event-automation \
    install/event-automation.yaml
```
---
## ROKS
To install everything, with persistent storage, using the IBM storage classes available on Red Hat OpenShift Kubernetes Service on IBM Cloud ("ROKS"):
```sh
ansible-playbook \
    -e license_accept=true \
    -e ibm_entitlement_key=YOUR-ENTITLEMENT-KEY \
    -e install_certmgr=true \
    -e eventstreams_storage_class=ibmc-block-gold \
    -e eventendpointmanagement_storage_class=ibmc-block-bronze \
    -e eventprocessing_storage_class=ibmc-block-bronze \
    -e eventautomation_namespace=event-automation \
    install/event-automation.yaml
```
---
## OCS
To install everything, with persistent storage using OpenShift Container Storage:
```sh
ansible-playbook \
    -e license_accept=true \
    -e ibm_entitlement_key=YOUR-ENTITLEMENT-KEY \
    -e install_certmgr=true \
    -e eventstreams_storage_class=ocs-storagecluster-ceph-rbd \
    -e eventendpointmanagement_storage_class=ocs-storagecluster-cephfs \
    -e eventprocessing_storage_class=ocs-storagecluster-cephfs \
    -e eventautomation_namespace=event-automation \
    install/event-automation.yaml
```
---
## VPC
To install everything, using persistent storage, on OpenShift on IBM Cloud (VPC):
```sh
ansible-playbook \
    -e license_accept=true \
    -e ibm_entitlement_key=<YOUR-ENTITLEMENT-KEY> \
    -e install_certmgr=true \
    -e eventstreams_storage_class=ibmc-vpc-block-general-purpose \
    -e eventendpointmanagement_storage_class=ibmc-vpc-block-general-purpose \
    -e eventprocessing_storage_class=ibmc-vpc-block-general-purpose \
    -e eventautomation_namespace=event-automation \
    install/event-automation.yaml
```
---
## Event Streams only
To install Event Streams only:
```sh
ansible-playbook \
    -e license_accept=true \
    -e ibm_entitlement_key=YOUR-ENTITLEMENT-KEY \
    -e eventautomation_namespace=event-automation \
    install/eventstreams/install.yaml
```
---
## Event Endpoint Management only
To install Event Endpoint Management only:
```sh
ansible-playbook \
    -e license_accept=true \
    -e ibm_entitlement_key=YOUR-ENTITLEMENT-KEY \
    -e eventautomation_namespace=event-automation \
    install/eventendpointmanagement/install.yaml
```
---
## Event Processing only
To install Event Processing only:
```sh
ansible-playbook \
    -e license_accept=true \
    -e ibm_entitlement_key=YOUR-ENTITLEMENT-KEY \
    -e eventautomation_namespace=event-automation \
    install/eventprocessing/install.yaml
```
---
## Apache Flink only
To install Apache Flink only:
```sh
ansible-playbook \
    -e license_accept=true \
    -e ibm_entitlement_key=YOUR-ENTITLEMENT-KEY \
    -e eventautomation_namespace=event-automation \
    install/flink/install.yaml
```
---
## Monitoring
To set up monitoring - including installing Grafana using the Grafana Operator:
```sh
ansible-playbook \
    -e license_accept=true \
    -e ibm_entitlement_key=YOUR-ENTITLEMENT-KEY \
    -e eventautomation_namespace=event-automation \
    install/supporting-demo-resources/monitoring/install.yaml
```
---
## Kafka workload applications
To run a high-throughput Kafka workload:
```sh
ansible-playbook \
    -e license_accept=true \
    -e ibm_entitlement_key=YOUR-ENTITLEMENT-KEY \
    -e eventautomation_namespace=event-automation \
    install/supporting-demo-resources/kafka-workload/run.yaml
```

To delete the resources used by the Kafka workload application:
```sh
oc delete job        -n event-automation workload-producer
oc delete job        -n event-automation workload-consumer
oc delete configmap  -n event-automation workload-credentials
oc delete kafkauser  -n event-automation workload-apps
oc delete kafkatopic -n event-automation workload-topic
```
---
## IBM MQ
To install an IBM MQ queue manager:
```sh
ansible-playbook \
    -e license_accept=true \
    -e ibm_entitlement_key=YOUR-ENTITLEMENT-KEY \
    -e eventautomation_namespace=event-automation \
    install/supporting-demo-resources/mq/install.yaml
```
---
## IBM App Connect
To install an IBM App Connect Designer:
```sh
ansible-playbook \
    -e license_accept=true \
    -e ibm_entitlement_key=YOUR-ENTITLEMENT-KEY \
    -e eventautomation_namespace=event-automation \
    install/supporting-demo-resources/appconnect/install.yaml
```
---
## PostgreSQL
To install a PostgreSQL database:
```sh
ansible-playbook \
    -e license_accept=true \
    -e ibm_entitlement_key=YOUR-ENTITLEMENT-KEY \
    -e eventautomation_namespace=event-automation \
    install/supporting-demo-resources/pgsql/install.yaml
```
---
