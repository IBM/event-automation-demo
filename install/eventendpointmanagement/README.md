# Event Endpoint Management Installation

This Ansible playbook installs IBM Event Endpoint Management (EEM) including the Manager and Event Gateway components.

## Configuration Variables

The playbook supports the following configurable variables in [`install.yaml`](install.yaml):

### Required Variables

- **`eventautomation_namespace`** (required)
  - The Kubernetes namespace where Event Endpoint Management will be deployed
  
- **`license_accept`** (required)
  - Must be set to accept the Event Automation license
  
- **`ibm_entitlement_key`** (required)
  - Your IBM Entitled Registry key for pulling container images

### Optional Variables

- **`eem_manager_name`** (default: `"my-eem-manager"`)
  - The name of the Event Endpoint Management Manager instance
  - This name is used for:
    - The EventEndpointManagement custom resource
    - Generated secrets (user credentials, roles)
    - Generated routes
    - CA certificate secrets
  
- **`eem_gateway_name`** (default: `"my-eem-gateway"`)
  - The name of the Event Gateway instance
  - This name is used for the EventGateway custom resource

- **`eventendpointmanagement_storage_class`** (optional)
  - Storage class for persistent storage
  - If not provided, ephemeral storage will be used

## Usage

### Default Configuration

Install with default names (`my-eem-manager` and `my-eem-gateway`):

```bash
ansible-playbook install/eventendpointmanagement/install.yaml \
  -e eventautomation_namespace="event-automation" \
  -e license_accept=true \
  -e ibm_entitlement_key="YOUR_KEY_HERE"
```

### Custom Instance Names

Use custom names for the EEM Manager and Gateway:

```bash
ansible-playbook install/eventendpointmanagement/install.yaml \
  -e eventautomation_namespace="event-automation" \
  -e license_accept=true \
  -e ibm_entitlement_key="YOUR_KEY_HERE" \
  -e eem_manager_name="production-eem-manager" \
  -e eem_gateway_name="production-eem-gateway"
```

### With Persistent Storage

Specify a storage class for persistent storage:

```bash
ansible-playbook install/eventendpointmanagement/install.yaml \
  -e eventautomation_namespace="event-automation" \
  -e license_accept=true \
  -e ibm_entitlement_key="YOUR_KEY_HERE" \
  -e eventendpointmanagement_storage_class="ibmc-block-gold"
```

### Install Only Operator

Use tags to install only the operator without creating instances:

```bash
ansible-playbook install/eventendpointmanagement/install.yaml \
  -e eventautomation_namespace="event-automation" \
  -e license_accept=true \
  -e ibm_entitlement_key="YOUR_KEY_HERE" \
  --tags operator
```

### Install Only Instances

If the operator is already installed, create only the instances:

```bash
ansible-playbook install/eventendpointmanagement/install.yaml \
  -e eventautomation_namespace="event-automation" \
  -e license_accept=true \
  -e ibm_entitlement_key="YOUR_KEY_HERE" \
  --tags instance
```

## What This Playbook Does

1. **Operator Installation** (tag: `operator`)
   - Creates catalog source for EEM operator
   - Creates operator subscription
   - Waits for operator to be ready

2. **Instance Creation** (tag: `instance`)
   - Creates namespace if it doesn't exist
   - Deploys Event Endpoint Management Manager
   - Retrieves the gateway route from the Manager
   - Deploys Event Gateway configured to connect to the Manager
   - Adds demo users to the authentication configuration
   - Adds demo roles to the authorization configuration

## Resources Created

### Manager Resources

- **EventEndpointManagement**: `<eem_manager_name>` (default: `my-eem-manager`)
- **Route**: `<eem_manager_name>-ibm-eem-gateway` (for gateway connection)
- **Secret**: `<eem_manager_name>-ibm-eem-user-credentials` (user authentication)
- **Secret**: `<eem_manager_name>-ibm-eem-user-roles` (user authorization)
- **Secret**: `<eem_manager_name>-ibm-eem-manager-ca` (CA certificate)

### Gateway Resources

- **EventGateway**: `<eem_gateway_name>` (default: `my-eem-gateway`)

## Template Files

All template files now support configurable instance names:

- [`01-catalog-source.yaml`](templates/01-catalog-source.yaml) - Operator catalog source
- [`02-operator-subscription.yaml`](templates/02-operator-subscription.yaml) - Operator subscription
- [`03-eem.yaml`](templates/03-eem.yaml) - Event Endpoint Management Manager instance
- [`04-egw.yaml`](templates/04-egw.yaml) - Event Gateway instance
- [`05-users.json`](templates/05-users.json) - Demo user credentials
- [`06-roles.json`](templates/06-roles.json) - Demo user roles

## Certificate Configuration

The Event Gateway automatically connects to the Manager using TLS. The CA certificate secret name follows the pattern:

```
<eem_manager_name>-ibm-eem-manager-ca
```

For example:
- Default: `my-eem-manager-ibm-eem-manager-ca`
- Custom: `production-eem-manager-ibm-eem-manager-ca`

This is automatically configured in the EventGateway resource.

## Migration from Hard-coded Names

If you previously used this playbook with hard-coded `my-eem-manager` and `my-eem-gateway` names, no changes are required. The default values maintain backward compatibility.

To migrate to different instance names, simply set the `eem_manager_name` and `eem_gateway_name` variables as shown in the usage examples above.

## Accessing the Manager UI

After installation, you can access the Event Endpoint Management Manager UI through the OpenShift route:

```bash
# Get the route URL
oc get route <eem_manager_name>-ibm-eem-ui -n <namespace> -o jsonpath='{.spec.host}'

# Example with defaults
oc get route my-eem-manager-ibm-eem-ui -n event-automation -o jsonpath='{.spec.host}'
```

## Demo Users

The playbook creates demo users defined in [`05-users.json`](templates/05-users.json) with roles defined in [`06-roles.json`](templates/06-roles.json).