# Kafka Workload Configuration

This Ansible playbook creates and runs a Kafka workload for testing Event Streams performance.

## Configuration Variables

The playbook supports the following configurable variables in [`run.yaml`](run.yaml):

### Required Variables

- **`eventautomation_namespace`** (default: `"event-automation"`)
  - The Kubernetes namespace where Event Automation resources are deployed
  
- **`kafka_cluster_name`** (default: `"my-kafka-cluster"`)
  - The name of the Kafka cluster to connect to
  - This should match the name of your EventStreams custom resource

## Usage

### Default Configuration

Run with default settings (connects to `my-kafka-cluster` in `event-automation` namespace):

```bash
ansible-playbook install/supporting-demo-resources/kafka-workload/run.yaml
```

### Custom Kafka Cluster Name

To connect to a different Kafka cluster, override the `kafka_cluster_name` variable:

```bash
ansible-playbook install/supporting-demo-resources/kafka-workload/run.yaml \
  -e kafka_cluster_name="my-custom-cluster"
```

### Custom Namespace and Cluster

Override both namespace and cluster name:

```bash
ansible-playbook install/supporting-demo-resources/kafka-workload/run.yaml \
  -e eventautomation_namespace="my-namespace" \
  -e kafka_cluster_name="my-custom-cluster"
```

## What This Playbook Does

1. Creates a Kafka topic named `WORKLOAD` with 6 partitions and 3 replicas
2. Creates a KafkaUser `workload-apps` with permissions to read/write to all topics
3. Retrieves cluster CA certificates and user credentials
4. Creates ConfigMap with Kafka client properties (consumer and producer)
5. Starts workload jobs:
   - **Producer job**: 3 parallel producers writing 500M records (128 bytes each)
   - **Consumer job**: 3 parallel consumers reading from the topic

## Resources Created

- **KafkaTopic**: `workload-topic` (topic name: `WORKLOAD`)
- **KafkaUser**: `workload-apps`
- **ConfigMap**: `workload-credentials` (contains consumer.properties and producer.properties)
- **Job**: `workload-producer` (3 parallel pods)
- **Job**: `workload-consumer` (3 parallel pods)

## Template Files

All template files now support the `kafka_cluster_name` variable:

- [`01-topic.yaml`](templates/01-topic.yaml) - KafkaTopic definition
- [`02-user.yaml`](templates/02-user.yaml) - KafkaUser definition
- [`03-credentials.yaml`](templates/03-credentials.yaml) - ConfigMap with Kafka client properties
- [`04-jobs.yaml`](templates/04-jobs.yaml) - Producer and Consumer jobs

## Migration from Hard-coded Cluster Name

If you previously used this playbook with the hard-coded `my-kafka-cluster` name, no changes are required. The default value maintains backward compatibility.

To migrate to a different cluster name, simply set the `kafka_cluster_name` variable as shown in the usage examples above.