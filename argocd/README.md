# ArgoCD

## Layout

```
argocd/
├── README.md                         # This file
├── sealed-secrets-onboard.md         # Sealed Secrets onboarding guide
├── apps/                             # ArgoCD Application CRDs (App of Apps)
│   ├── infra/                        # Infrastructure apps (sealed-secrets, traefik-config)
│   ├── dev/                          # Dev environment apps (mysql, network-statistics)
│   ├── monitoring/                   # Monitoring apps (fluentbit, grafana, loki, prometheus)
│   └── prod/                         # Prod environment apps (mysql, mysql-exporter, network-statistics)
└── infra/
    └── traefik/                      # Traefik HelmChartConfig
        └── helmchartconfig.yaml
```

## Architecture — App of Apps Pattern

ArgoCD uses the **App of Apps** pattern to manage workloads declaratively. A single root Application (`apps`) watches the `argocd/apps/` directory in the repo and creates child Applications based on the YAML manifests found there.

## App Overview

```mermaid
flowchart LR
    ROOT["Root App: apps\nargocd/apps/"] --> INFRA["Child App: infra\nargocd/apps/infra/\nNamespace: kube-system"]
    ROOT --> DEV["Child App: dev\nargocd/apps/dev/\nNamespace: dev"]
    ROOT --> MON["Child App: monitoring\nargocd/apps/monitoring/\nNamespace: monitoring"]
    ROOT --> PROD["Child App: prod\nargocd/apps/prod/\nNamespace: prod"]

    INFRA --> TRAEFIK_CFG["HelmChartConfig: traefik\nargocd/infra/traefik/\nNamespace: kube-system"]
    INFRA --> SEALED["App: sealed-secrets\nargocd/apps/infra/\nNamespace: kube-system (bitnami chart)"]
    DEV --> MYSQL_DEV["Helm Chart: mysql/dev\nhelm/mysql/dev/"]
    DEV --> NETSTATS_DEV["Helm Chart: network-statistics/dev\nhelm/network-statistics/dev/"]
    MON --> FB["Helm Chart: fluentbit\nhelm/fluentbit/"]
    MON --> GRAFANA["Helm Chart: grafana\nhelm/grafana/"]
    MON --> LOKI["Helm Chart: loki\nhelm/loki/"]
    MON --> PROM["Helm Chart: prometheus\nhelm/prometheus/"]
    PROD --> MYSQL_PROD["Helm Chart: mysql/prod\nhelm/mysql/prod/"]
    PROD --> MYSQL_EXPORTER["Helm Chart: mysql-exporter-prod\nhelm/mysql-exporter/prod/"]
    PROD --> NETSTATS_PROD["Helm Chart: network-statistics/prod\nhelm/network-statistics/prod/"]
```

| Child App | ArgoCD Path | Namespace | Helm Chart Source |
|-----------|-------------|-----------|-------------------|
| `infra` | `argocd/apps/infra/` | `kube-system` | `argocd/infra/traefik/` (HelmChartConfig), `sealed-secrets-app.yaml` (bitnami Helm chart) |
| `dev` | `argocd/apps/dev/` | `dev` | `helm/mysql/dev/`, `helm/network-statistics/dev/` |
| `monitoring` | `argocd/apps/monitoring/` | `monitoring` | `helm/fluentbit/`, `helm/loki/`, `helm/prometheus/`, `helm/grafana/` |
| `prod` | `argocd/apps/prod/` | `prod` | `helm/mysql/prod/`, `helm/mysql-exporter/prod/`, `helm/network-statistics/prod/` |

## Applications

| App | Branch | Path | Namespace | Sync Policy |
|-----|--------|------|-----------|-------------|
| `apps` (root) | `main` | `argocd/apps/` (recursive) | `argocd` | Automated + Prune |
| `infra` | `main` | `argocd/apps/infra/` | `argocd` | Automated + Prune |
| `traefik-config` | `main` | `argocd/apps/infra/` | `kube-system` | Automated + Prune |
| `sealed-secrets` | `main` | `argocd/apps/infra/` | `kube-system` | Automated + Prune |
| `mysql-dev` | `main` | `argocd/apps/dev/` | `dev` | Automated + Prune |
| `network-statistics-dev` | `main` | `argocd/apps/dev/` | `dev` | Automated + Prune |
| `fluentbit` | `main` | `argocd/apps/monitoring/` | `monitoring` | Automated + Prune |
| `loki` | `main` | `argocd/apps/monitoring/` | `monitoring` | Automated + Prune |
| `prometheus` | `main` | `argocd/apps/monitoring/` | `monitoring` | Automated + Prune |
| `grafana` | `main` | `argocd/apps/monitoring/` | `monitoring` | Automated + Prune |
| `mysql-prod` | `main` | `argocd/apps/prod/` | `prod` | Automated + Prune |
| `mysql-exporter-prod` | `main` | `argocd/apps/prod/` | `prod` | Automated + Prune |
| `network-statistics-prod` | `main` | `argocd/apps/prod/` | `prod` | Automated + Prune |

## Secrets Management (Sealed Secrets)

[Sealed Secrets](https://github.com/bitnami/sealed-secrets) encrypts Kubernetes `Secret` data into commit-safe `SealedSecret` manifests. The controller (bitnami chart `2.19.1`, `fullnameOverride=sealed-secrets-controller`) runs in `kube-system` and decrypts them in-cluster.

**Hard rules:**
- **NEVER commit raw or base64-encoded credentials** — GitHub push protection decodes base64 and blocks `ghp_…` tokens.
- **GitHub Actions tokens** (e.g. `LOCAL_INFRA_PAT`) stay in GitHub's store, never in this repo.
- **Use the `seal-secret` skill** (`seal.sh`) to seal — the skill has `KUBECONFIG` built in and auto-fetches the public cert; sealing is local encryption with zero cluster writes.

> **Step-by-step onboarding guide:** [sealed-secrets-onboard.md](sealed-secrets-onboard.md)

Reference implementation: `helm/network-statistics/` (PRs #60, #67).

## How to Add a New App

See the step-by-step guide: [docs/create-argocd-app-guide.md](../docs/create-argocd-app-guide.md).

## Status

| Component | Value |
|-----------|--------|
| **ArgoCD URL** | `http://10.10.0.5:30808` (k3s prod VM, Traefik ingress) |
| **Server Version** | `v3.1.0` |
| **Sync Policy** | All apps: automated prune, selfHeal disabled, CreateNamespace=true |
| **Total Apps** | 13 (root + 12 child apps, see Applications table above) |
| **Repository** | `https://github.com/minhntt1/local-infra` (via HTTPS) |

> **✅ Resolved (2026-07-27):** A second, full ArgoCD install was previously running in the **`default`** namespace (7 `argocd-*` pods, image `v3.4.5`, ClusterIP only — no nodePort, so it never bound host port 30808). It was unmanaged (no Helm release, no Application CR, empty config) and redundant vs the intended Helm-managed install in the `argocd` namespace. It has been **deleted** (all workloads, services, RBAC in `default`, plus cluster-wide `argocd-*` ClusterRoles/Bindings). The intended `argocd`-ns instance (image `v3.1.0`) remains and still serves port 30808.
