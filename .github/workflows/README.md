# Self-Hosted GitHub Runner

## Layout

```
.github/
└── workflows/
    ├── README.md        # This file
    ├── ansible.yml      # Ansible lint + apply CI
    └── terraform.yml    # Terraform fmt / plan / apply CI
```

The `local-infra` workflows run on a self-hosted GitHub Actions runner hosted inside the Proxmox lab, not on GitHub's shared infrastructure. This is required because the `terraform-apply` job must reach the Proxmox API on the private lab network.

## Runner Host

| Attribute | Value |
|-----------|-------|
| Guest | `lxc1` (LXC container, VMID `100`) — *note: the PVE container is named `lxc1`; older docs referenced `automation1`. Verify the runner is registered under the expected agent name.* |
| Proxmox node | Single-node Proxmox host (via `ssh proxmox-local`) |
| Runner user | `infra` |
| Install path | `/home/infra/actions-runner` |
| Agent name | `automation1` |
| Registered repo | `https://github.com/minhntt1/local-infra` |
| Pool | `Default` |
| Work folder | `_work` |
| Service | `runsvc.sh` → `RunnerService.js` → `Runner.Listener` (systemd-style service) |

## Notes

- The runner is a **persistent LXC container** with its rootfs on `local-lvm` (LVM thin pool), so the runner install and state survive reboots.
- The container is set with `onboot: 1`, so the runner comes back online automatically after a host reboot.
- Verify the runner is live from the Proxmox host:

  ```bash
  ssh proxmox-local sudo pct exec 100 -- cat /home/infra/actions-runner/.runner
  ```

- The runner must be online for `terraform-apply` (and any other workflow) to execute, since jobs are pinned to this self-hosted runner.

## Runner Rules

Conventions every workflow must follow when running on this self-hosted runner. They exist because the `automation1` LXC is a minimal Debian image with no Node/pip cache and no preinstalled Python packaging tooling.

### Python — always use a venv

The container ships `python3` (3.13) but **no `pip` and no `venv`**. Never install packages into the system interpreter, and never use `actions/setup-python` (it has no cached interpreter here and fails). Instead:

```bash
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv
python3 -m venv ~/.infra_venv          # created once, reused on later runs
export PATH="$HOME/.infra_venv/bin:$PATH"
pip install --upgrade pip
pip install <packages>                  # ansible, ansible-lint, etc.
```

All `pip` / `python3` / `ansible` / `ansible-lint` commands in the workflows run from `~/.infra_venv`, so installs never touch the system Python.

### apt — update, upgrade, then clean

Every job that installs OS packages must keep the runner patched and lean:

```bash
sudo apt-get update
sudo apt-get upgrade -y                  # full upgrade before installing deps
sudo apt-get install -y <packages>
# ... do the work ...
sudo apt-get clean                       # always, even on failure (if: always())
sudo apt-get autoremove -y
```

- `update` + `upgrade -y` run first so the runner is fully patched before any tooling is installed.
- `clean` + `autoremove -y` run at the **end of every job** (wrapped in `if: always()`) so the image does not accumulate downloaded `.deb` caches or orphaned packages between runs.
