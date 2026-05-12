# Event Processing Installation

This Ansible playbook installs IBM Event Processing, which provides a low-code authoring tool for creating event stream processing flows using Apache Flink.

## Configuration Variables

The playbook supports the following configurable variables in [`install.yaml`](install.yaml):

### Required Variables

- **`eventautomation_namespace`** (required)
  - The Kubernetes namespace where Event Processing will be deployed
  
- **`license_accept`** (required)
  - Must be set to accept the Event Automation license
  
- **`ibm_entitlement_key`** (required)
  - Your IBM Entitled Registry key for pulling container images

### Optional Variables

- **`eventprocessing_instance_name`** (default: `"my-event-processing"`)
  - The name of the Event Processing instance
  - This name is used for:
    - The EventProcessing custom resource
    - Generated secrets (user credentials, roles)
    - Generated routes

- **`eventprocessing_storage_class`** (optional)
  - Storage class for persistent storage
  - If not provided, ephemeral storage will be used

- **`eventprocessing_storage_size`** (default: `"100M"`)
  - Storage size for the Event Processing authoring tool
  - Only used when `eventprocessing_storage_class` is specified
  - Examples: "100M", "500M", "1Gi"

## Usage

### Default Configuration

Install with default name (`my-event-processing`):

```bash
ansible-playbook install/eventprocessing/install.yaml \
  -e eventautomation_namespace="event-automation" \
  -e license_accept=true \
  -e ibm_entitlement_key="YOUR_KEY_HERE"
```

### Custom Instance Name

Use a custom name for the Event Processing instance:

```bash
ansible-playbook install/eventprocessing/install.yaml \
  -e eventautomation_namespace="event-automation" \
  -e license_accept=true \
  -e ibm_entitlement_key="YOUR_KEY_HERE" \
  -e eventprocessing_instance_name="production-event-processing"
```

### With Persistent Storage

Specify a storage class for persistent storage:

```bash
ansible-playbook install/eventprocessing/install.yaml \
  -e eventautomation_namespace="event-automation" \
  -e license_accept=true \
  -e ibm_entitlement_key="YOUR_KEY_HERE" \
  -e eventprocessing_storage_class="ibmc-block-gold"
```

### With Custom Storage Size

Customize the storage size (requires storage class to be set):

```bash
ansible-playbook install/eventprocessing/install.yaml \
  -e eventautomation_namespace="event-automation" \
  -e license_accept=true \
  -e ibm_entitlement_key="YOUR_KEY_HERE" \
  -e eventprocessing_storage_class="ibmc-block-gold" \
  -e eventprocessing_storage_size="500M"
```

### Install Only Operator

Use tags to install only the operator without creating instances:

```bash
ansible-playbook install/eventprocessing/install.yaml \
  -e eventautomation_namespace="event-automation" \
  -e license_accept=true \
  -e ibm_entitlement_key="YOUR_KEY_HERE" \
  --tags operator
```

### Install Only Instance

If the operator is already installed, create only the instance:

```bash
ansible-playbook install/eventprocessing/install.yaml \
  -e eventautomation_namespace="event-automation" \
  -e license_accept=true \
  -e ibm_entitlement_key="YOUR_KEY_HERE" \
  --tags instance
```

## What This Playbook Does

1. **Operator Installation** (tag: `operator`)
   - Creates catalog source for Event Processing operator
   - Creates operator subscription
   - Waits for operator to be ready

2. **Instance Creation** (tag: `instance`)
   - Creates namespace if it doesn't exist
   - Creates Event Automation truststore (if not already present)
   - Deploys Event Processing authoring tool
   - Adds demo users to the authentication configuration
   - Adds demo roles to the authorization configuration

## Resources Created

### Event Processing Resources

- **EventProcessing**: `<eventprocessing_instance_name>` (default: `my-event-processing`)
- **Secret**: `<eventprocessing_instance_name>-ibm-ep-user-credentials` (user authentication)
- **Secret**: `<eventprocessing_instance_name>-ibm-ep-user-roles` (user authorization)
- **Secret**: `eventautomation-truststore` (shared truststore for Kafka connectivity)

## Template Files

All template files now support configurable instance names:

- [`01-catalog-source.yaml`](templates/01-catalog-source.yaml) - Operator catalog source
- [`02-operator-subscription.yaml`](templates/02-operator-subscription.yaml) - Operator subscription
- [`03-ep.yaml`](templates/03-ep.yaml) - Event Processing instance
- [`05-users.json`](templates/05-users.json) - Demo user credentials
- [`06-roles.json`](templates/06-roles.json) - Demo user roles

## Flink Integration

Event Processing uses Apache Flink as its processing engine. The Flink endpoint is configured in the EventProcessing resource:

```yaml
flink:
  endpoint: 'my-flink-rest:8081'
```

Make sure you have a Flink deployment available before installing Event Processing. See the [Flink installation guide](../flink/README.md) for details.

## Truststore Configuration

Event Processing requires a truststore to connect securely to Kafka clusters. The playbook automatically:

1. Checks if an `eventautomation-truststore` secret exists
2. Creates one if it doesn't exist (using the common truststore setup task)
3. Mounts the truststore in the Event Processing backend container

The truststore is configured with:
- **Location**: `/opt/ibm/sp-backend/certs/eventautomation.jks`
- **Password**: `eventautomationstore`

## Migration from Hard-coded Names

If you previously used this playbook with the hard-coded `my-event-processing` name, no changes are required. The default value maintains backward compatibility.

To migrate to a different instance name, simply set the `eventprocessing_instance_name` variable as shown in the usage examples above.

## Accessing the Event Processing UI

After installation, you can access the Event Processing UI through the OpenShift route:

```bash
# Get the route URL
oc get route <eventprocessing_instance_name>-ibm-ep-ui -n <namespace> -o jsonpath='{.spec.host}'

# Example with defaults
oc get route my-event-processing-ibm-ep-ui -n event-automation -o jsonpath='{.spec.host}'
```

## Demo Users

The playbook creates demo users defined in [`05-users.json`](templates/05-users.json) with roles defined in [`06-roles.json`](templates/06-roles.json).

## Prerequisites

- OpenShift cluster with appropriate permissions
- IBM Entitled Registry key
- Flink deployment (see [Flink installation](../flink/README.md))
- Event Streams or another Kafka cluster for event sources