Pods that are created running the demo setup playbook.

This list is not intended to imply the resource requirements for Event Automation. It is a record of the footprint resulting from creating the tutorial deployment. For information about IBM Event Automation resource requirements, refer to:

- https://ibm.github.io/event-automation/es/installing/planning/
- https://ibm.github.io/event-automation/eem/installing/planning/
- https://ibm.github.io/event-automation/ep/installing/planning/

The reference column contains a link to where the sizing of that component can be modified. These links are pointers to where you can scale components up or down if you need to customize the demo deployment for different environments or uses.

A superscript asterisk <sup>*</sup> in the reference column indicates that the resource sizing value is not explicitly specified in the demo setup playbook, and that the current footprint is a default sizing. The link in these cases is to where an override can be added to modify the deployment footprint.

|  **POD**                                | **CPU REQUESTS** | **CPU LIMITS** | **MEMORY REQUESTS** | **MEMORY LIMITS** | **ref** |
| --------------------------------------- | ---------------- | -------------- | ------------------- | ----------------- | ------- |
|  eventstreams-cluster-operator          |           `200m` |        `1000m` |            `1024Mi` |          `1024Mi` |
|  my-kafka-cluster-entity-operator       |            `30m` |        `2100m` |            `2176Mi` |          `2176Mi` | [ref](https://github.com/IBM/event-automation-demo/blob/c71003ab8372046291b87b854074cadd79f3fc52/install/eventstreams/templates/03-es.yaml#L25) <sup>*</sup> |
|  my-kafka-cluster-zookeeper-0           |           `100m` |        `1000m` |             `128Mi` |          `1024Mi` | [ref](https://github.com/IBM/event-automation-demo/blob/c71003ab8372046291b87b854074cadd79f3fc52/install/eventstreams/templates/03-es.yaml#L51) <sup>*</sup> |
|  my-kafka-cluster-zookeeper-1           |           `100m` |        `1000m` |             `128Mi` |          `1024Mi` | [ref](https://github.com/IBM/event-automation-demo/blob/c71003ab8372046291b87b854074cadd79f3fc52/install/eventstreams/templates/03-es.yaml#L51) <sup>*</sup> |
|  my-kafka-cluster-zookeeper-2           |           `100m` |        `1000m` |             `128Mi` |          `1024Mi` | [ref](https://github.com/IBM/event-automation-demo/blob/c71003ab8372046291b87b854074cadd79f3fc52/install/eventstreams/templates/03-es.yaml#L51) <sup>*</sup> |
|  my-kafka-cluster-kafka-0               |           `100m` |        `1000m` |             `128Mi` |          `2048Mi` | [ref](https://github.com/IBM/event-automation-demo/blob/c71003ab8372046291b87b854074cadd79f3fc52/install/eventstreams/templates/03-es.yaml#L28) <sup>*</sup> |
|  my-kafka-cluster-kafka-1               |           `100m` |        `1000m` |             `128Mi` |          `2048Mi` | [ref](https://github.com/IBM/event-automation-demo/blob/c71003ab8372046291b87b854074cadd79f3fc52/install/eventstreams/templates/03-es.yaml#L28) <sup>*</sup> |
|  my-kafka-cluster-kafka-2               |           `100m` |        `1000m` |             `128Mi` |          `2048Mi` | [ref](https://github.com/IBM/event-automation-demo/blob/c71003ab8372046291b87b854074cadd79f3fc52/install/eventstreams/templates/03-es.yaml#L28) <sup>*</sup> |
|  my-kafka-cluster-ibm-es-ui             |           `350m` |        `1100m` |             `640Mi` |           `640Mi` | [ref](https://github.com/IBM/event-automation-demo/blob/c71003ab8372046291b87b854074cadd79f3fc52/install/eventstreams/templates/03-es.yaml#L7)  <sup>*</sup> |
|  my-kafka-cluster-ibm-es-admapi         |           `500m` |        `2000m` |            `1024Mi` |          `1024Mi` | [ref](https://github.com/IBM/event-automation-demo/blob/c71003ab8372046291b87b854074cadd79f3fc52/install/eventstreams/templates/03-es.yaml#L6)  <sup>*</sup> |
|  kafka-connect-cluster-connect          |          `2048m` |        `2048m` |            `2048Mi` |          `2048Mi` | [ref](https://github.com/IBM/event-automation-demo/blob/c71003ab8372046291b87b854074cadd79f3fc52/install/eventstreams/templates/07-kafkaconnect.yaml#L16-L21) |
|  ibm-eem-operator                       |           `200m` |        `1000m` |             `256Mi` |           `256Mi` |
|  my-eem-manager-ibm-eem-manager-0       |           `250m` |         `500m` |             `256Mi` |           `512Mi` | [ref](https://github.com/IBM/event-automation-demo/blob/af10324efdf4133cfc279335878aa340032d1767/install/eventendpointmanagement/templates/03-eem.yaml#L31-L36) |
|  my-eem-gateway-ibm-egw-gateway         |           `500m` |        `1000m` |             `512Mi` |          `1024Mi` | [ref](https://github.com/IBM/event-automation-demo/blob/af10324efdf4133cfc279335878aa340032d1767/install/eventendpointmanagement/templates/04-egw.yaml#L20-L25) |
|  flink-kubernetes-operator              |           `200m` |        `1000m` |             `256Mi` |           `512Mi` |
|  ibm-ep-operator                        |           `200m` |        `1000m` |             `256Mi` |           `256Mi` |
|  my-event-processing-ibm-ep-sts-0       |          `1000m` |        `2000m` |            `1024Mi` |          `2048Mi` | [ref](https://github.com/IBM/event-automation-demo/blob/af10324efdf4133cfc279335878aa340032d1767/install/eventprocessing/templates/03-ep.yaml#L20) <sup>*</sup> |
|  my-flink                               |          `1000m` |        `1000m` |            `2048Mi` |          `2048Mi` | [ref](https://github.com/IBM/event-automation-demo/blob/af10324efdf4133cfc279335878aa340032d1767/install/flink/templates/03-flink.yaml#L23-L24) |
|  my-flink-taskmanager-1-1               |          `4000m` |        `4000m` |            `3048Mi` |          `3048Mi` | [ref](https://github.com/IBM/event-automation-demo/blob/af10324efdf4133cfc279335878aa340032d1767/install/flink/templates/03-flink.yaml#L28-L29) |
| --------------------------------------- | ---------------- | -------------- | ------------------- | ----------------- | ------- |
| **total**                               |             `11` |           `26` |              `15Gi` |            `26Gi` |