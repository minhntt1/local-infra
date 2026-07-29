# Monitoring Stack

An observability layer runs in the `monitoring` namespace, deployed as three independent ArgoCD Applications (each in `argocd/apps/monitoring/`, all with automated sync + prune without selfHeal and `CreateNamespace=true`):

| Component | ArgoCD App | Helm chart | Image | Notes |
|-----------|------------|------------|-------|-------|
| **Loki** | `loki` | `helm/loki` | `grafana/loki:3.5.6` | Log storage. 5Gi PVC on `local-path`, 512Mi/500m limits. |
| **Prometheus** | `prometheus` | `helm/prometheus` | `prom/prometheus:latest` | Metrics. 5Gi PVC on `local-path`, 1Gi/500m limits. |
| **Fluent Bit** | `fluentbit` | `helm/fluentbit` | (chart default) | Log shipper into Loki. |

All three target the `monitoring` namespace on the prod k3s cluster. As of the last live check, Prometheus and Fluent Bit were `Running`; Loki was in `CrashLoopBackOff` (see below).

## Loki config fix (Loki 3.5.6 compatibility)

Loki `3.5.6` rejects config keys that were removed in newer Loki releases. The deployed config (`helm/loki/templates/configmap.yaml` + `helm/loki/values.yaml`) used three deprecated keys, causing the pod to crash on startup (`failed parsing config … field … not found`):

| Removed key | Location | Replacement |
|-------------|----------|-------------|
| `boltdb_shipper.shared_store` | `storage_config.boltdb_shipper` | Object store now comes from `schema_config.configs[].object_store` (already set to `filesystem`) — key deleted |
| `compactor.shared_store` | `compactor` | `compactor.delete_request_store: filesystem` (required when `retention_enabled: true`) |
| `limits_config.enforce_metric_name` | `limits_config` | Deleted (removed in Loki 2.4+) |

Fixed in `local-infra` branch `fix/loki-config-deprecated-fields` (commit `c1c7ef5`) — removes the three keys and adds `compactor.delete_request_store`. Rendered config verified to parse as valid YAML with no deprecated keys. After the PR merges, ArgoCD self-heals the `loki` app and the pod should leave `CrashLoopBackOff`.
