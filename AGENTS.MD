# local-infra

Repository to manage the infrastructure (helm, ansible, terraform, k8s) of the lab.

- **Base branch**: `main`

---

## Terraform: Proxmox VM Provisioning

Terraform configs live in [`terraform/`](terraform/) and use the [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest) provider to clone VMs from a Proxmox template and deploy them on the Proxmox node.

### Prerequisites

1. **Proxmox API Token** — Created for user `admin@pve` with token ID `admin@pve!terraform` (non-privsep). The secret was output once during creation.
2. **GitHub Secrets** — Must be added to the `local-infra` repository:
   - `PM_API_TOKEN_ID` → `admin@pve!terraform`
   - `PM_API_TOKEN_SECRET` → (the secret value from token creation)

### GitHub Actions Workflow

Located at [`.github/workflows/terraform.yml`](.github/workflows/terraform.yml).

The workflow follows a safe pattern:

| Job | Trigger | Description |
|-----|---------|-------------|
| `terraform-fmt` | PR or push to `main` | Checks Terraform formatting |
| `terraform-plan` | PR or push to `main` | Validates and shows the plan |
| `terraform-apply` | Push to `main` only (after merge) | Applies changes to Proxmox |

**Flow:**
1. On PR: `terraform-fmt` and `terraform-plan` run (no changes applied)
2. On merge to `main`: All three jobs run, with `terraform-apply` applying the changes
3. The workflow resolves the Proxmox API URL dynamically using the runner's **default gateway** (which is the Proxmox host IP on the same bridge)

### Files

| File | Description |
|------|-------------|
| `providers.tf` | Provider config with API token auth and SSH over agent |
| `variables.tf` | All variables: API URL, token, VM specs with defaults |
| `main.tf` | VM resources: clone from template with customized CPU/memory/disk |
| `outputs.tf` | Outputs VM IDs, names, IPs, and MACs after apply |
| `terraform.tfvars.example` | Example variable file (without secrets) |
