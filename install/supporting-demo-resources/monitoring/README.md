# Monitoring Setup

This directory contains Ansible playbooks and Grafana dashboards for monitoring IBM Event Automation components.

## Configuration

The monitoring setup can be configured using the following variables in [`install.yaml`](install.yaml):

### Required Variables

- **`eventautomation_namespace`** (default: `"event-automation"`)
  - The Kubernetes namespace where Event Automation components are deployed

### Optional Variables

- **`eventstreams_instance_name`** (default: `"my-kafka-cluster"`)
  - Name of the Event Streams (Kafka) cluster instance
  - Used for granting monitoring permissions to the Event Streams admin API service account

## Grafana Dashboards

The `dashboards/` directory contains pre-configured Grafana dashboards for monitoring:

- **es-health.json** - Event Streams cluster health metrics
- **es-performance.json** - Event Streams performance metrics  
- **eem-health.json** - Event Endpoint Management health metrics
- **eem-activity.json** - Event Endpoint Management activity metrics

### Important Note About Custom Instance Names

⚠️ **The Grafana dashboard JSON files contain hard-coded references to the default instance name `my-kafka-cluster`.** 

If you use a custom `eventstreams_instance_name`, you will need to manually update the dashboard JSON files before importing them into Grafana. Use a text editor to find and replace all occurrences of `my-kafka-cluster` with your custom instance name in the following files:

- `dashboards/es-health.json`
- `dashboards/es-performance.json`

Alternatively, you can edit the queries directly in Grafana after importing the dashboards.

## Usage

### Install Monitoring with Default Settings

```bash
ansible-playbook install/supporting-demo-resources/monitoring/install.yaml \
  -e eventautomation_namespace="event-automation"
```

### Install with Custom Event Streams Instance Name

```bash
ansible-playbook install/supporting-demo-resources/monitoring/install.yaml \
  -e eventautomation_namespace="event-automation" \
  -e eventstreams_instance_name="prod-kafka"
```

**Remember:** If using a custom instance name, update the dashboard JSON files before importing them into Grafana.

## What This Playbook Does

1. Enables user workload monitoring in OpenShift
2. Installs Grafana Operator
3. Creates Grafana instance
4. Configures Prometheus data source
5. Grants monitoring permissions to Event Streams service account
6. Sets up OpenTelemetry Collector for metrics collection
7. Configures monitoring for Event Endpoint Management components

## Accessing Grafana

After installation, you can access Grafana through the OpenShift route:

```bash
oc get route grafana-route -n event-automation -o jsonpath='{.spec.host}'
```

## Importing Dashboards

1. Log into Grafana
2. Navigate to Dashboards → Import
3. Upload the JSON files from the `dashboards/` directory
4. Select the Prometheus data source when prompted

## Troubleshooting

### Check Grafana Status

```bash
kubectl get grafana -n event-automation
```

### View Grafana Logs

```bash
kubectl logs -n event-automation -l app=grafana
```

### Verify Prometheus Data Source

```bash
kubectl get grafanadatasource -n event-automation