# Ansible: Configuration & Service Bootstrap

Ansible is the **configuration-management and service-bootstrap** layer for the lab. It sits on top of the infrastructure Terraform provisions and turns bare Debian VMs into running services.

## Division of responsibility

| Layer | Tool | Owns |
|-------|------|------|
| Infrastructure | Terraform (bpg/proxmox) | VM creation, CPU/memory/disk, network bridge, power state, Proxmox API auth |
| Configuration | **Ansible** | OS hardening, package installs, Kubernetes (k3s), and every future service |

Terraform stops at "the VM exists and is powered on with an IP". Ansible takes over from there. The two never overlap: Terraform never installs software inside a guest; Ansible never creates or destroys VMs.

## Long-term vision

k3s is only the **first** Ansible-managed workload. The same inventory and role pattern is intended to grow to cover, for example:

- **k3s cluster** — control-plane on `prod` (VMID 200), with an agent role ready for future workers. Done first.
- **Observability** — Prometheus / Grafana / Loki agents pushed to nodes.
- **Networking services** — Pi-hole, reverse proxy, VPN, cert-manager.
- **Shared tooling** — log shipping, node exporters, backup agents.

The design goal is that **adding a new service is just adding a role + a playbook entry**, not re-architecting how Ansible talks to the lab.

## Inventory strategy

VMs receive **DHCP addresses** on the Proxmox bridge `vnet1` (10.10.0.0/16), so static IPs in inventory would drift. Instead Ansible uses a **Proxmox dynamic inventory** (`inventory/proxmox.yml`) that:

1. Authenticates to the Proxmox API with the same `admin@pve!terraform` token Terraform uses (supplied via env vars, never committed).
2. Reads each VM's current IPv4 from the QEMU guest agent (enabled in `terraform/main.tf`).
3. Groups VMs by purpose using VMID-based rules, e.g. VMID 200 → `k3s_servers`.

The inventory is always correct after a DHCP renew or VM recreate — no manual IP updates.

### Grouping convention

Groups are named by **role**, not by VM name, so playbooks target intent:

| Group | Current members | Future |
|-------|-----------------|--------|
| `k3s_servers` | `prod` (VMID 200) | — |
| `k3s_agents` | (empty) | added as needed |
| `<service>_servers` / `<service>_agents` | — | added as needed |

To onboard a new service, define its group in the dynamic inventory and write a role under `roles/`.

## Repository layout

```
ansible/
├── ansible.cfg              # default inventory (the inventory/ dir), remote_user=admin + become, key-file auth
├── inventory/
│   ├── proxmox.yml          # dynamic inventory (resolves DHCP IPs at runtime)
│   └── group_vars/
│       └── all.yml          # shared vars (k3s version, token placeholder, toggles)
├── playbooks/
│   └── site.yml             # orchestrates common -> server -> tools -> agents
└── roles/
    ├── k3s_common/          # shared prereqs (swap, kernel modules, sysctl, apt)
    ├── k3s_server/          # install k3s control-plane, fetch kubeconfig
    ├── k3s_tools/           # install Helm CLI and ArgoCD after k3s
    └── k3s_agent/           # join workers to the server (no-op while empty)
```

New services follow the same shape: a shared prereq role (reusing `k3s_common` patterns) plus a service-specific role, wired into `site.yml` or a new playbook.

## How to add a new bootstrap target (pattern)

1. **Inventory** — add a group rule in `inventory/proxmox.yml` (by VMID or Proxmox tag) for the new service's nodes.
2. **Vars** — add service defaults in `group_vars/` (or a dedicated `group_vars/<group>.yml`). Keep secrets as placeholders / vault / extra-vars.
3. **Role** — create `roles/<service>/` with `tasks/main.yml` (and `defaults/main.yml` for tunables).
4. **Playbook** — add a play targeting the new group in `playbooks/site.yml` (or a separate `playbooks/<service>.yml`).
5. **Run** — execute with the Proxmox env vars set; the dynamic inventory resolves IPs automatically.

## Required collections

```bash
ansible-galaxy collection install community.general ansible.posix
```

## Secrets handling

- Proxmox API token secret: environment variables only (`PM_API_TOKEN_SECRET`).
- Service join tokens (e.g. `k3s_token`): placeholder in `group_vars/all.yml`, overridden per run with `--extra-vars` or an Ansible vault. Never committed.

## First concrete use case: k3s

The k3s bootstrap (single control-plane on `prod`, with an agent role reserved for future workers) is the reference implementation of this pattern.

Run commands and k3s-specific flags:

```bash
cd local-infra/ansible
export PM_API_URL="https://<proxmox-ip>:8006/api2/json"
export PM_API_TOKEN_ID="admin@pve!terraform"
export PM_API_TOKEN_SECRET="<secret>"

# Preview the resolved inventory (confirms prod IP is discovered):
ansible-inventory -i inventory --list

# Bootstrap the cluster (generate a fresh token each run):
ansible-playbook -i inventory playbooks/site.yml \
  --extra-vars "k3s_token=$(openssl rand -hex 32)"
```

The server role fetches `/etc/rancher/k3s/k3s.yaml` to `kubeconfig-prod.yaml` (git-ignored) with the server address rewritten to the node IP:

```bash
kubectl --kubeconfig kubeconfig-prod.yaml get nodes
```

Re-running the playbook is idempotent: install steps use `creates:` guards and services are reconciled to `started`.

## k3s Details

### Network Configuration
The k3s installation uses the following network configuration:
- **Pod CIDR**: `10.42.0.0/16` (flannel VXLAN for pod-to-pod communication)
- **Service CIDR**: `10.43.0.0/16` (ClusterIP virtual IPs for Services)
- Both ranges are chosen to not conflict with the Proxmox bridge `vnet1` (`10.10.0.0/16`)

### DHCP Resilience
Since the prod VM gets its IP via DHCP on the Proxmox bridge `vnet1`:
- k3s binds to `0.0.0.0` (all interfaces) and auto-detects its node IP from the default route
- The kubeconfig uses the hostname `prod` instead of an IP, leveraging Proxmox SDN resolution
- No hardcoded `--node-ip` or `--advertise-address` flags are used
- This makes the installation resilient to DHCP IP changes

### Single-Node Scheduling
By default, k3s applies a control-plane taint (`node-role.kubernetes.io/control-plane:NoSchedule`) to prevent workloads from running on server nodes. In a single-node cluster, this would block all pod scheduling. The bootstrap removes this taint after k3s is ready, allowing user workloads to run on the control-plane node.

### Accessing the Cluster
After bootstrapping, you can access the cluster with:

```bash
kubectl --kubeconfig kubeconfig-prod.yaml get nodes
kubectl --kubeconfig kubeconfig-prod.yaml get pods -A
```

The kubeconfig file is git-ignored and contains the rewritten server address pointing to `https://prod:6443`.
