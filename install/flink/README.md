# Apache Flink Installation

This Ansible playbook installs Apache Flink for use with IBM Event Processing. Flink provides the stream processing engine that powers Event Processing flows.

## Configuration Variables

The playbook supports the following configurable variables in [`install.yaml`](install.yaml):

### Required Variables

- **`eventautomation_namespace`** (default: `"event-automation"`)
  - The Kubernetes namespace where Flink will be deployed
  
- **`license_accept`** (required)
  - Must be set to accept the Event Automation license
  
- **`ibm_entitlement_key`** (required)
  - Your IBM Entitled Registry key for pulling container images

### Optional Variables

- **`flink_instance_name`** (default: `"my-flink"`)
  - The name of the Flink deployment instance
  - This name is used for:
    - The FlinkDeployment custom resource
    - The Flink REST service endpoint (used by Event Processing)

## Usage

### Default Configuration

Install with default name (`my-flink`):

```bash
ansible-playbook install/flink/install.yaml \
  -e eventautomation_namespace="event-automation" \
  -e license_accept=true \
  -e ibm_entitlement_key="YOUR_KEY_HERE"
```

### Custom Instance Name

Use a custom name for the Flink deployment:

```bash
ansible-playbook install/flink/install.yaml \
  -e eventautomation_namespace="event-automation" \
  -e license_accept=true \
  -e ibm_entitlement_key="YOUR_KEY_HERE" \
  -e flink_instance_name="production-flink"
```

### Install Only Operator

Use tags to install only the operator without creating instances:

```bash
ansible-playbook install/flink/install.yaml \
  -e eventautomation_namespace="event-automation" \
  -e license_accept=true \
  -e ibm_entitlement_key="YOUR_KEY_HERE" \
  --tags operator
```

### Install Only Instance

If the operator is already installed, create only the instance:

```bash
ansible-playbook install/flink/install.yaml \
  -e eventautomation_namespace="event-automation" \
  -e license_accept=true \
  -e ibm_entitlement_key="YOUR_KEY_HERE" \
  --tags instance
```

## What This Playbook Does

1. **Operator Installation** (tag: `operator`)
   - Creates catalog source for Flink Kubernetes operator
   - Creates operator subscription
   - Waits for operator to be ready

2. **Instance Creation** (tag: `instance`)
   - Creates namespace if it doesn't exist
   - Creates Event Automation truststore (if not already present)
   - Deploys Flink cluster with JobManager and TaskManager

## Resources Created

### Flink Resources

- **FlinkDeployment**: `<flink_instance_name>` (default: `my-flink`)
- **Service**: `<flink_instance_name>-rest` (REST API endpoint on port 8081)
- **Secret**: `eventautomation-truststore` (shared truststore for Kafka connectivity)

## Template Files

All template files now support configurable instance names:

- [`01-catalog-source.yaml`](templates/01-catalog-source.yaml) - Operator catalog source
- [`02-operator-subscription.yaml`](templates/02-operator-subscription.yaml) - Operator subscription
- [`03-flink.yaml`](templates/03-flink.yaml) - Flink deployment configuration

## Flink Configuration

The Flink deployment is configured with:

### Resource Allocation

- **JobManager**: 1 replica, 0.25 CPU, 2048Mi memory
- **TaskManager**: 1 CPU, 2048Mi memory, 4 task slots per TaskManager
- **Minimum slots**: 1 (auto-scaling enabled)

### State Management

- **State backend**: RocksDB (for large state)
- **Checkpointing**: Every 5 seconds
- **Incremental checkpoints**: Enabled
- **Retained checkpoints**: 3

### Behavior Settings

- **JSON parsing**: Ignore parse errors
- **Source idle timeout**: 30 seconds
- **Restart strategy**: None (manual restart required)

### Truststore Configuration

Flink is configured to use the Event Automation truststore for secure connections to Kafka and Event Endpoint Management:

- **Truststore location**: `/certs/eventautomation.jks`
- **Truststore password**: `eventautomationstore`
- **Applied to**: Both JobManager and TaskManager JVMs

## Integration with Event Processing

Event Processing connects to Flink using the REST API endpoint. The endpoint URL follows the pattern:

```
<flink_instance_name>-rest:8081
```

For example:
- Default: `my-flink-rest:8081`
- Custom: `production-flink-rest:8081`

**Important**: If you use a custom `flink_instance_name`, you must also update the Event Processing configuration to use the correct Flink endpoint. Update the `flink.endpoint` value in [`install/eventprocessing/templates/03-ep.yaml`](../eventprocessing/templates/03-ep.yaml):

```yaml
flink:
  endpoint: '<flink_instance_name>-rest:8081'
```

## Migration from Hard-coded Names

If you previously used this playbook with the hard-coded `my-flink` name, no changes are required. The default value maintains backward compatibility.

To migrate to a different instance name:

1. Set the `flink_instance_name` variable when running this playbook
2. Update the Event Processing configuration to reference the new Flink endpoint

## Accessing the Flink Dashboard

The Flink web dashboard is available through the REST service:

```bash
# Port-forward to access locally
kubectl port-forward -n <namespace> svc/<flink_instance_name>-rest 8081:8081

# Then access at http://localhost:8081
```

Or expose via OpenShift route:

```bash
oc expose svc/<flink_instance_name>-rest -n <namespace>
oc get route <flink_instance_name>-rest -n <namespace>
```

## Prerequisites

- OpenShift cluster with appropriate permissions
- IBM Entitled Registry key
- Sufficient cluster resources (minimum 3.25 CPU, 4Gi memory)

## Troubleshooting

### Check Flink Deployment Status

```bash
kubectl get flinkdeployment <flink_instance_name> -n <namespace>
```

### View Flink Logs

```bash
# JobManager logs
kubectl logs -n <namespace> -l component=jobmanager,app=<flink_instance_name>

# TaskManager logs
kubectl logs -n <namespace> -l component=taskmanager,app=<flink_instance_name>
```

### Verify REST API

```bash
kubectl port-forward -n <namespace> svc/<flink_instance_name>-rest 8081:8081
curl http://localhost:8081/v1/overview