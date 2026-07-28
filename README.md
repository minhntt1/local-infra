# local-infra

Repository to manage the infrastructure (helm, ansible, terraform, k8s) of the lab. The entire infra runs on a Proxmox single-node host

- **Base branch**: `main`

---

## Deployment Overview

High-level view of how the `local-infra` repo drives the lab and where each component lives.

```mermaid
flowchart TB
    subgraph GH["GitHub — github.com/minhntt1/local-infra"]
        REPO["local-infra repo"]
        WF_TF["Workflow: terraform.yml\n(terraform-fmt / plan / apply)"]
        WF_ANS["Workflow: ansible.yml\n(ansible-lint / ansible-apply)"]
    end

    subgraph PVE["Proxmox single node — hp"]
        subgraph RUN["Self-Hosted Runner — automation1 (LXC, VMID 100)"]
            AGENT["GitHub Actions Runner\nuser: infra\n/home/infra/actions-runner\nNode 24 (bundled)"]
            subgraph ANS["Ansible — config & service bootstrap"]
                INV["Dynamic inventory\n(inventory/proxmox.yml)\nresolves DHCP IPs via guest agent"]
                PB["playbooks/site.yml\nk3s_common -> k3s_server -> k3s_tools -> k3s_agent"]
            end
        end

        API["Proxmox API :8006\nauth: admin@pve (username/password)"]
        TPL["Template: debian13-cloudinit-template\n(VMID 9999)"]

        subgraph SNIPPETS["Snippet Storage — local datastore\n/var/lib/vz/snippets/"]
            HOOK_PROD["nat-hook-prod.sh\n(rendered from template)"]
        end

        subgraph VMS["Managed VMs (bridge vnet1, 10.10.0.0/16)"]
            subgraph PROD["prod (VMID 200) — vnet1 -> eth0 (virtio) 10.10.0.5"]
                POD_NET["pod CIDR: 10.42.0.0/16\n(flannel VXLAN)"]
                SVC_NET["service CIDR: 10.43.0.0/16\n(ClusterIP virtual)"]
                DATA_DISK["/dev/sdb (20G on data-hdd)\nmounted at /data\n/data/k3s/"]
            end
        end

        subgraph HOST["Proxmox Host — iptables NAT"]
            DNAT["DNAT rules\nvmbr0:8080 → prod:30808\n(add on post-start,\nremove on pre-stop)"]
        end
    end

    REPO --> WF_TF
    REPO --> WF_ANS
    WF_TF -- "dispatch on push / PR" --> AGENT
    WF_ANS -- "dispatch on push / PR" --> AGENT
    AGENT -- "terraform apply\n(resolves API URL via default gw)" --> API
    AGENT -- "SSH as user1\n(SSH_RUNNER_PM_PRIVATE key)" --> SNIPPETS
    API -- "clone from template" --> TPL
    API -- "create / manage" --> PROD
    AGENT -. "runner lives on same node" .-> PVE

    SNIPPETS -- "hook_script_file_id\nwired via API" --> PROD
    PROD -- "post-start / pre-stop\ntriggers hook script" --> HOST
    HOOK_PROD -. "resolves IP via\nQEMU guest agent" .-> PROD

    AGENT -- "ansible-playbook\n(admin + become over SSH key)" --> INV
    INV -- "queries" --> API
    INV -- "groups VMs by role" --> PB
    PB -- "bootstrap services" --> PROD
```

**Key points**
- Workflows run on the **self-hosted runner** inside the lab (not GitHub-hosted) so `terraform-apply` can reach the Proxmox API on the private network.
- The runner resolves the Proxmox API URL from its **default gateway** (the Proxmox host IP on `vnet1`).
- **VM port forwarding (NAT iptables):** VMs with `forwards` entries in `var.vms` automatically get a hook script uploaded to `/var/lib/vz/snippets/` via SSH (as `user1` using `SSH_RUNNER_PM_PRIVATE` key). The script is wired to the VM via `hook_script_file_id`, and on VM start/stop it manages DNAT rules on the Proxmox host — with dynamic IP resolution via the QEMU guest agent.

---

## Project Layout

```
local-infra/
├── .github/
│   └── workflows/
│       ├── ansible.yml        # Ansible lint + apply CI
│       └── terraform.yml      # Terraform fmt / plan / apply CI
├── ansible/                   # Configuration management & service bootstrap
│   ├── ansible.cfg            # Default inventory, remote_user=admin + become
│   ├── inventory/
│   │   ├── proxmox.yml        # Dynamic Proxmox inventory (DHCP IP resolution)
│   │   └── group_vars/
│   │       └── all.yml        # Shared vars (k3s version, token placeholder)
│   ├── playbooks/
│   │   └── site.yml           # Orchestrates common -> server -> tools -> agents
│   └── roles/
│       ├── k3s_common/        # Shared prereqs (swap, kernel modules, sysctl, apt)
│       ├── k3s_server/        # Install k3s control-plane, fetch kubeconfig
│       ├── k3s_tools/         # Install Helm CLI and ArgoCD after k3s
│       └── k3s_agent/         # Join workers to the server (no-op while empty)
├── argocd/                    # ArgoCD App of Apps definitions
│   └── apps/                  # Child Application CRDs (dev, prod)
├── helm/                      # Helm charts for lab services
│   ├── fluentbit/             # Fluent Bit log shipper
│   ├── loki/                  # Loki log storage
│   ├── mysql/                 # MySQL
│   └── prometheus/            # Prometheus metrics
└── terraform/                 # Proxmox VM provisioning
    ├── backend.tf             # Remote state config
    ├── imports.tf             # Imported resources
    ├── main.tf                # VM resources + NAT hook scripts
    ├── outputs.tf             # VM IDs, names, IPs, MACs
    ├── providers.tf           # Proxmox + SSH provider config
    ├── templates/
    │   └── nat-hook.sh.tpl    # Per-VM iptables NAT hook template
    ├── terraform.tfvars.example # Example variables (no secrets)
    └── variables.tf           # All input variables + VM specs
```

## Component Documentation

- [Terraform: Proxmox VM Provisioning](./terraform/README.md)
- [Self-Hosted GitHub Runner](./.github/workflows/README.md)
- [Ansible: Configuration & Service Bootstrap](./ansible/README.md)
- [Monitoring Stack](./helm/README.md)
- [ArgoCD](./argocd/README.md)
