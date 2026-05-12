# Event Streams Installation

This Ansible playbook installs IBM Event Streams (Kafka) for use with IBM Event Automation components.

## Configuration Variables

The playbook supports the following configurable variables in [`install.yaml`](install.yaml):

### Required Variables

- **`eventautomation_namespace`** (required)
  - The Kubernetes namespace where Event Streams will be deployed
  
- **`license_accept`** (required)
  - Must be set to accept the Event Automation license
  
- **`ibm_entitlement_key`** (required)
  - Your IBM Entitled Registry key for pulling container images

### Optional Variables

- **`eventstreams_instance_name`** (default: `"my-kafka-cluster"`)
  - Name of the Event Streams (Kafka) cluster instance
  - This name is used for the EventStreams custom resource and affects generated resource names
  - Examples: "my-kafka-cluster", "prod-kafka", "dev-eventstreams"

- **`eventstreams_storage_class`** (optional)
  - Storage class for persistent storage
  - If not provided, ephemeral storage will be used

- **`eventstreams_broker_storage_size`** (default: `"50Gi"`)
  - Storage size for each Kafka broker
  - Only used when `eventstreams_storage_class` is specified
  - Examples: "50Gi", "100Gi", "200Gi"

- **`eventstreams_controller_storage_size`** (default: `"3Gi"`)
  - Storage size for each Kafka controller
  - Only used when `eventstreams_storage_class` is specified
  - Examples: "3Gi", "5Gi", "10Gi"

## Usage

### Default Configuration

Install with ephemeral storage:

```bash
ansible-playbook install/eventstreams/install.yaml \
  -e eventautomation_namespace="event-automation" \
  -e license_accept=true \
  -e ibm_entitlement_key="YOUR_KEY_HERE"
```

### With Custom Instance Name

Specify a custom name for the Event Streams cluster:

```bash
ansible-playbook install/eventstreams/install.yaml \
  -e eventautomation_namespace="event-automation" \
  -e license_accept=true \
  -e ibm_entitlement_key="YOUR_KEY_HERE" \
  -e eventstreams_instance_name="prod-kafka"
```

### With Persistent Storage

Specify a storage class for persistent storage:

```bash
ansible-playbook install/eventstreams/install.yaml \
  -e eventautomation_namespace="event-automation" \
  -e license_accept=true \
  -e ibm_entitlement_key="YOUR_KEY_HERE" \
  -e eventstreams_storage_class="ibmc-block-gold"
```

### With Custom Storage Sizes

Customize storage sizes for brokers and controllers (requires storage class to be set):

```bash
ansible-playbook install/eventstreams/install.yaml \
  -e eventautomation_namespace="event-automation" \
  -e license_accept=true \
  -e ibm_entitlement_key="YOUR_KEY_HERE" \
  -e eventstreams_storage_class="ibmc-block-gold" \
  -e eventstreams_broker_storage_size="100Gi" \
  -e eventstreams_controller_storage_size="5Gi"
```

### Complete Custom Configuration

Combine all customization options:

```bash
ansible-playbook install/eventstreams/install.yaml \
  -e eventautomation_namespace="event-automation" \
  -e license_accept=true \
  -e ibm_entitlement_key="YOUR_KEY_HERE" \
  -e eventstreams_instance_name="prod-kafka" \
  -e eventstreams_storage_class="ibmc-block-gold" \
  -e eventstreams_broker_storage_size="100Gi" \
  -e eventstreams_controller_storage_size="5Gi"
```

### Install Only Operator

Use tags to install only the operator without creating instances:

```bash
ansible-playbook install/eventstreams/install.yaml \
  -e eventautomation_namespace="event-automation" \
  -e license_accept=true \
  -e ibm_entitlement_key="YOUR_KEY_HERE" \
  --tags operator
```

### Install Only Instance

If the operator is already installed, create only the instance:

```bash
ansible-playbook install/eventstreams/install.yaml \
  -e eventautomation_namespace="event-automation" \
  -e license_accept=true \
  -e ibm_entitlement_key="YOUR_KEY_HERE" \
  --tags instance
```

## What This Playbook Does

1. **Operator Installation** (tag: `operator`)
   - Creates catalog source for Event Streams operator
   - Creates operator subscription
   - Waits for operator to be ready

2. **Instance Creation** (tag: `instance`)
   - Creates namespace if it doesn't exist
   - Deploys Event Streams cluster with:
     - 3 Kafka brokers (combined broker/controller mode)
     - 3 Kafka controllers
     - Schema Registry
     - Kafka Connect
   - Creates users for various components
   - Sets up topics for Kafka Connect
   - Configures data generation connectors
   - Enables metrics collection

## Resources Created

### Event Streams Resources

- **EventStreams**: Kafka cluster with brokers and controllers
- **KafkaUser**: Multiple users for different components (apps, connect, schema registry)
- **KafkaTopic**: Topics for Kafka Connect configuration
- **KafkaConnect**: Kafka Connect cluster for data integration
- **KafkaConnector**: Data generation connectors

## Storage Configuration

Event Streams uses two types of storage:

### Broker Storage
- **Default size**: 50Gi per broker
- **Purpose**: Stores Kafka topic data and logs
- **Replicas**: 3 brokers
- **Total default storage**: 150Gi (3 × 50Gi)

### Controller Storage
- **Default size**: 3Gi per controller
- **Purpose**: Stores cluster metadata and coordination data
- **Replicas**: 3 controllers
- **Total default storage**: 9Gi (3 × 3Gi)

### Storage Sizing Guidelines

**Development/Testing:**
- Brokers: 50Gi (default)
- Controllers: 3Gi (default)

**Production (Small):**
- Brokers: 100Gi
- Controllers: 5Gi

**Production (Medium):**
- Brokers: 200Gi
- Controllers: 10Gi

**Production (Large):**
- Brokers: 500Gi+
- Controllers: 20Gi+

## Template Files

- [`01-catalog-source.yaml`](templates/01-catalog-source.yaml) - Operator catalog source
- [`02-operator-subscription.yaml`](templates/02-operator-subscription.yaml) - Operator subscription
- [`03-es.yaml`](templates/03-es.yaml) - Event Streams cluster configuration
- [`04-es-user.yaml`](templates/04-es-user.yaml) - Admin user
- [`05-kafkaconnect-topics.yaml`](templates/05-kafkaconnect-topics.yaml) - Kafka Connect topics
- [`06-kafkaconnect-user.yaml`](templates/06-kafkaconnect-user.yaml) - Kafka Connect user
- [`07-kafkaconnect.yaml`](templates/07-kafkaconnect.yaml) - Kafka Connect cluster
- [`08-datagen.yaml`](templates/08-datagen.yaml) - Data generation connectors
- [`09-apps-user.yaml`](templates/09-apps-user.yaml) - Application user
- [`10-metrics.yaml`](templates/10-metrics.yaml) - Metrics configuration
- [`11-schemaregistry-user.yaml`](templates/11-schemaregistry-user.yaml) - Schema Registry user

## Accessing Event Streams

After installation, you can access the Event Streams UI through the OpenShift route:

```bash
# Get the route URL (replace <instance-name> with your eventstreams_instance_name)
oc get route <instance-name>-ibm-es-ui -n <namespace> -o jsonpath='{.spec.host}'

# Example with default instance name and namespace
oc get route my-kafka-cluster-ibm-es-ui -n event-automation -o jsonpath='{.spec.host}'

# Example with custom instance name
oc get route prod-kafka-ibm-es-ui -n event-automation -o jsonpath='{.spec.host}'
```

## Bootstrap Server

Applications can connect to Kafka using the bootstrap server:

```
<instance-name>-kafka-bootstrap.<namespace>.svc:9095
```

Examples:
```
# With default instance name
my-kafka-cluster-kafka-bootstrap.event-automation.svc:9095

# With custom instance name
prod-kafka-kafka-bootstrap.event-automation.svc:9095
```

## Prerequisites

- OpenShift cluster with appropriate permissions
- IBM Entitled Registry key
- Sufficient cluster resources (minimum 6 CPU, 12Gi memory for default configuration)
- Storage provisioner if using persistent storage

## Troubleshooting

### Check Event Streams Status

```bash
# Replace <instance-name> with your eventstreams_instance_name
kubectl get eventstreams <instance-name> -n <namespace>

# Example with default instance name
kubectl get eventstreams my-kafka-cluster -n event-automation
```

### View Kafka Broker Logs

```bash
# Replace <instance-name> with your eventstreams_instance_name
kubectl logs -n <namespace> -l app.kubernetes.io/name=kafka,strimzi.io/cluster=<instance-name>

# Example with default instance name
kubectl logs -n event-automation -l app.kubernetes.io/name=kafka,strimzi.io/cluster=my-kafka-cluster
```

### Check Storage Usage

```bash
kubectl get pvc -n <namespace>