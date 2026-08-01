# Creating an ArgoCD App with Helm Chart

This guide walks through declaring a new ArgoCD-managed service — from Helm chart to Application CRD.

## Architecture Recap

ArgoCD uses the **App of Apps** pattern. A root Application watches `argocd/apps/` recursively and auto-discovers child Application YAML files. Each child app points to a Helm chart under `helm/<app>/<env>/`.

```
argocd/apps/<namespace>/<app>.yaml   →   helm/<app>/<env>/
```

No manual registration in the root `apps` Application is needed — just drop the child YAML in the right directory.

## Step 1: Choose the namespace and naming convention

| Namespace | Purpose | Example apps |
|-----------|---------|-------------|
| `kube-system` | Infrastructure (sealed-secrets, traefik-config) | `sealed-secrets` |
| `monitoring` | Observability (fluentbit, grafana, loki, prometheus) | `grafana` |
| `dev` | Development environment | `mysql-dev`, `network-statistics-dev` |
| `prod` | Production environment | `mysql-prod`, `network-statistics-prod` |

**Naming rule:** `<app>-<env>` for multi-environment, `<app>` for single-environment.
- `mysql-dev`, `mysql-prod`
- `fluentbit` (only in monitoring)

## Step 2: Create the Helm chart

### 2a. Directory structure

**Multi-environment** (e.g., mysql, network-statistics, mysql-exporter):

```
helm/<app>/
└── <env>/                  # dev or prod
    ├── Chart.yaml
    ├── values.yaml
    └── templates/
        ├── _helpers.tpl
        ├── deployment.yaml
        ├── service.yaml
        ├── configmap.yaml          # if needed
        ├── pvc.yaml                # if needed
        ├── ingressroute.yaml       # if HTTP ingress
        ├── ingressroute-tcp.yaml   # if TCP ingress (e.g., MySQL)
        ├── secret.yaml             # guarded by useSealed flag
        └── sealedsecret-*.yaml     # static, if using SealedSecrets
```

**Single-environment** (e.g., monitoring services):

```
helm/<app>/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── _helpers.tpl
    ├── deployment.yaml
    ├── service.yaml
    └── ...
```

### 2b. `Chart.yaml`

The `name` field **must** match the chart directory name exactly (critical for label generation).

```yaml
apiVersion: v2
name: <app>-<env>                     # e.g., mysql-dev, grafana
description: <one-line description>
type: application
version: 0.1.0
appVersion: "<image-tag>"             # e.g., "8.4.6", "3.5.6", "latest"
```

### 2c. `_helpers.tpl`

Copy from any existing chart, replace the template prefix string. The four named templates are boilerplate:

```go
{{- define "<prefix>.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "<prefix>.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "<prefix>.labels" -}}
helm.sh/chart: {{ include "<prefix>.name" . }}-{{ .Chart.Version | replace "+" "_" }}
{{ include "<prefix>.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "<prefix>.selectorLabels" -}}
app.kubernetes.io/name: {{ include "<prefix>.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

Where `<prefix>` = chart `name` with hyphens, e.g., `mysql-dev`, `grafana`, `network-statistics-prod`.

### 2d. `values.yaml`

Always include these top-level keys:

```yaml
replicaCount: 1

image:
  repository: <docker-image>            # e.g., mysql, ghcr.io/minhntt1/network-statistics
  tag: <tag>                            # e.g., 8.4.6, latest, c00621f
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: <port>

resources:
  limits:
    cpu: <200m-500m>
    memory: <128Mi-1Gi>
  requests:
    cpu: <50m-200m>
    memory: <64Mi-512Mi>

# Optional: persistence
persistence:
  enabled: true
  size: <5Gi, 10Gi>
  storageClass: local-path

# Optional: ingress
ingressRoute:
  enabled: true
```

**Dev vs Prod tips:**
- Dev: `replicaCount: 0` (scaled down)
- Prod: `replicaCount: 1` (or more)
- Dev credentials can use dummy values; prod should use SealedSecrets

### 2e. Templates — common patterns

All templates use the same metadata/labels blocks:

```yaml
metadata:
  name: {{ include "<prefix>.fullname" . }}
  labels:
    {{- include "<prefix>.labels" . | nindent 4 }}
```

**Service selector** pattern:

```yaml
selector:
  {{- include "<prefix>.selectorLabels" . | nindent 4 }}
```

**PVC** pattern:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ include "<prefix>.fullname" . }}-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: {{ .Values.persistence.size }}
  storageClassName: {{ .Values.persistence.storageClass }}
```

**IngressRoute** pattern:
```yaml
{{- if .Values.ingressRoute.enabled }}
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: {{ include "<prefix>.fullname" . }}
spec:
  entryPoints:
    - web
  routes:
    - match: PathPrefix(`/<path-prefix>`)         # e.g., /grafana, /prod/network-statistics
      kind: Rule
      services:
        - name: {{ include "<prefix>.fullname" . }}
          port: {{ .Values.service.port }}
{{- end }}
```

**Important:** Do **not** add a `stripPrefix` middleware. The backend application must handle its own path prefix via `server.servlet.context-path` (Spring Boot) or equivalent.

## Step 3: Create the ArgoCD Application YAML

Create a file at `argocd/apps/<namespace>/<app>.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: <app>-<env>                                   # e.g., mysql-prod, grafana
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/minhntt1/local-infra
    targetRevision: main
    path: helm/<app>/<env>                            # e.g., helm/mysql/prod, helm/grafana
  destination:
    server: https://kubernetes.default.svc
    namespace: <namespace>                            # dev, prod, monitoring, kube-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: false
    syncOptions:
      - CreateNamespace=true
```

Only three fields vary:
- `metadata.name` — unique ArgoCD app name
- `spec.source.path` — path to the Helm chart in this repo
- `spec.destination.namespace` — Kubernetes namespace

## Step 4: Secrets (Sealed Secrets)

If the app needs credentials, use [Sealed Secrets](sealed-secrets-onboard.md). The pattern used by `network-statistics`:

1. Create a `sealedsecret-db.yaml` in the chart's `templates/` directory with the encrypted data:

```yaml
---
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: <app>-<env>-db-secret                          # hardcoded
  namespace: <namespace>                                # hardcoded
spec:
  encryptedData:
    <key>: <sealed-ciphertext>
  template:
    metadata:
      name: <app>-<env>-db-secret
      namespace: <namespace>
    type: Opaque
```

2. In the deployment, reference secrets via `secretKeyRef`:

```yaml
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ include "<prefix>.fullname" . }}-db-secret
        key: db-password
```

3. Use the `seal-secret` skill (`.kilo/skills/seal-secret/seal.sh`) to generate the encrypted YAML. **Never commit plaintext secrets.**

4. For GHCR pull secrets (private container images), use a `sealedsecret-ghcr.yaml` with `type: kubernetes.io/dockerconfigjson`.

## Step 5: Verify

1. Push the branch and create a PR.
2. After merge, ArgoCD auto-discovers the new Application YAML and syncs it.
3. Check sync status:

```bash
export KUBECONFIG=/path/to/temp/k3s/confg.yaml
kubectl get applications -n argocd
```

## Checklist

- [ ] Helm chart directory created under `helm/<app>/<env>/`
- [ ] `Chart.yaml` has correct `name` (matches directory), `version`, `appVersion`
- [ ] `_helpers.tpl` has all four named templates with correct prefix
- [ ] `values.yaml` has `replicaCount`, `image`, `service`, `resources`
- [ ] Templates use `{{ include "<prefix>.fullname" . }}` and `.labels`/`.selectorLabels`
- [ ] ArgoCD Application YAML created at `argocd/apps/<namespace>/<app>.yaml`
- [ ] `spec.source.path` matches the Helm chart directory
- [ ] `metadata.name` and `spec.destination.namespace` are correct
- [ ] Secrets managed via SealedSecrets (not plaintext `secret.yaml`)
- [ ] No `stripPrefix` middleware in IngressRoute — app handles its own context-path