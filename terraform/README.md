# Terraform: Proxmox VM Provisioning

Terraform configs live in [`terraform/`](./) and use the [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest) provider to clone VMs from a Proxmox template and deploy them on the Proxmox node.

## Prerequisites

1. **Proxmox API Username & Password** — The provider authenticates to the Proxmox API using the `admin@pve` username and password, passed via `TF_VAR_pm_api_username` and `TF_VAR_pm_api_password`.
2. **GitHub Secrets** — Must be added to the `local-infra` repository:
   - `PM_API_USERNAME` → `admin@pve`
   - `PM_API_PASSWORD` → (the Proxmox API password for `admin@pve`)
   - `SSH_RUNNER_ANSIBLE_PUBLIC` → the runner's SSH **public** key (e.g. `ssh-ed25519 AAAA... runner@automation1`). Injected into each VM's cloud-init user account so the runner can reach the guests over key-based SSH (in addition to the password). The matching private key lives in `SSH_RUNNER_ANSIBLE_PRIVATE` and is loaded into the runner's SSH agent for Ansible.
   - `SSH_RUNNER_PM_PUBLIC` / `SSH_RUNNER_PM_PRIVATE` → SSH key pair for authenticating as `user1` on the Proxmox host. Required by the `proxmox_virtual_environment_file` resource (snippet uploads need SSH — API alone is insufficient for this operation). The private key is passed to the provider via `TF_VAR_ssh_pm_private_key`.

## GitHub Actions Workflow

Located at [`.github/workflows/terraform.yml`](../../.github/workflows/terraform.yml).

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

## Files

| File | Description |
|------|-------------|
| `providers.tf` | Provider config with username/password auth and SSH key-based auth (user1) for file operations |
| `variables.tf` | All variables: API URL, username, password, VM specs with defaults, plus `vm_id` and `forwards` for each VM |
| `main.tf` | VM resources: clone from template with customized CPU/memory/disk, plus `proxmox_virtual_environment_file.nat_hook` for iptables DNAT hook scripts |
| `outputs.tf` | Outputs VM IDs, names, IPs, and MACs after apply |
| `templates/nat-hook.sh.tpl` | Template for per-VM iptables NAT hook scripts (rendered via `templatefile()`) |
| `terraform.tfvars.example` | Example variable file (without secrets) |

## NAT Hook Scripts — iptables Port Forwarding

Certain services running inside VMs need to be reachable from outside the Proxmox host (e.g. exposing a web app on port 8080). Rather than hardcoding iptables rules per VM, Terraform generates them dynamically via Proxmox [hook scripts](https://pve.proxmox.com/wiki/Hook_Scripts).

**How it works:**

1. Each VM in `var.vms` can optionally define a `forwards` list:
   ```hcl
   forwards = [
     { protocol = "tcp", public_port = 8080, internal_port = 8080 }
   ]
   ```
2. The `proxmox_virtual_environment_file.nat_hook` resource renders `templates/nat-hook.sh.tpl` once per VM (skipping VMs with empty `forwards`) and uploads it to the Proxmox host's `local` datastore under `/var/lib/vz/snippets/nat-hook-<name>.sh`.
3. `hook_script_file_id = try(proxmox_virtual_environment_file.nat_hook[each.key].id, null)` wires the hook script to the VM. VMs with no forwards gracefully fall back to `null` (no hook script).

**What the hook script does:**

- Runs on the **Proxmox host** during VM lifecycle events (`post-start` / `pre-stop` / `reconcile`)
- **Dynamically resolves the VM's IP** at runtime from the Proxmox SDN IPAM state file (`/etc/pve/sdn/pve-ipam-state.json`), so DHCP-assigned addresses work without hardcoding and no guest-agent dependency or boot-time race
- On `post-start`: adds iptables DNAT rules to forward host ports to the VM (retries IP resolution up to 15× with 2s sleep)
- On `pre-stop`: removes those rules
- On `reconcile`: flushes all previously tagged rules and rebuilds from the `forwards` list — idempotent convergence on every invocation, no duplicates
- All iptables commands use the `-w` (wait) option to handle lock contention when multiple VMs are reconciled simultaneously

**To expose a new port:** add an entry to the VM's `forwards` list and push. The hook script content changes (triggered by `template_hash`), Terraform re-uploads it, and the next VM start applies the new rules.

**Prerequisite:** The `local` datastore must have `snippets` content type enabled:
```bash
ssh proxmox-local sudo pvesm set local --content backup,import,iso,vztmpl,snippets
```

**SSH auth for snippet uploads:** The `proxmox_virtual_environment_file` resource requires SSH to upload files to the `local` datastore (the API alone cannot write files to the host filesystem). The provider authenticates as `user1` on the Proxmox host using the `SSH_RUNNER_PM_PRIVATE` key passed via `TF_VAR_ssh_pm_private_key`. The matching public key must be in `user1`'s `~/.ssh/authorized_keys` on the Proxmox host.
