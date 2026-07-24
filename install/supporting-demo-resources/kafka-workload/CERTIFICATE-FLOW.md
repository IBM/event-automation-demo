# Certificate Configuration Flow

This document explains how certificates are handled with the configurable `kafka_cluster_name` variable.

## Certificate Secret Naming Convention

Kafka clusters create a CA certificate secret with the naming pattern:
```
<kafka_cluster_name>-cluster-ca-cert
```

For example:
- Default: `my-kafka-cluster-cluster-ca-cert`
- Custom: `my-custom-cluster-cluster-ca-cert`

## Certificate Flow in the Playbook

### 1. Retrieve Truststore Password (run.yaml)

The playbook retrieves the CA certificate secret using the configurable cluster name:

```yaml
- name: Retrieve truststore password
  kubernetes.core.k8s_info:
    api_version: v1
    kind: Secret
    name: "{{ kafka_cluster_name }}-cluster-ca-cert"
    namespace: "{{ eventautomation_namespace }}"
  register: truststore_password_secret
```

**Variable used**: `{{ kafka_cluster_name }}-cluster-ca-cert`

### 2. Pass to Credentials ConfigMap (03-credentials.yaml)

The truststore password is extracted and passed to the ConfigMap:

```yaml
vars:
  truststore_password: "{{ truststore_password_secret.resources[0].data['ca.password'] | ansible.builtin.b64decode }}"
```

The ConfigMap contains SSL configuration for both consumer and producer:

```properties
ssl.protocol=TLSv1.3
ssl.truststore.location=/certs/cluster/ca.p12
ssl.truststore.password={{ truststore_password }}
ssl.truststore.type=PKCS12
```

### 3. Mount Certificates in Jobs (04-jobs.yaml)

Both producer and consumer jobs mount the CA certificate secret:

```yaml
volumes:
  - name: cluster-ca
    secret:
      items:
        - key: ca.crt
          path: ca.crt
        - key: ca.p12
          path: ca.p12
        - key: ca.password
          path: ca.password
      secretName: {{ kafka_cluster_name }}-cluster-ca-cert
```

**Variable used**: `{{ kafka_cluster_name }}-cluster-ca-cert`

The certificates are mounted at `/certs/cluster/` in the containers.

## Certificate Contents

The secret contains three keys:
- **ca.crt**: CA certificate in PEM format
- **ca.p12**: CA certificate in PKCS12 format (used by Java clients)
- **ca.password**: Password for the PKCS12 keystore

## Verification

To verify the certificate secret exists for your cluster:

```bash
kubectl get secret <kafka_cluster_name>-cluster-ca-cert -n <namespace>
```

Example with default values:
```bash
kubectl get secret my-kafka-cluster-cluster-ca-cert -n event-automation
```

Example with custom cluster name:
```bash
kubectl get secret my-custom-cluster-cluster-ca-cert -n event-automation
```

## Impact of Cluster Name Change

When you change the `kafka_cluster_name` variable:

✅ **Automatically Updated**:
- Secret name retrieval in run.yaml
- Secret name references in job volumes
- Bootstrap server URLs
- All Kafka resource labels

✅ **No Manual Changes Required**:
- Certificate paths remain `/certs/cluster/ca.p12`
- Truststore configuration remains the same
- SSL/TLS settings remain the same

The variable substitution ensures all certificate references point to the correct secret for your cluster.