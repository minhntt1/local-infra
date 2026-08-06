# Self-Hosted GitHub Runner

## Layout

```
.github/
└── workflows/
    ├── README.md        # This file
    ├── ansible.yml      # Ansible lint + apply CI
    ├── terraform.yml    # Terraform fmt / plan / apply CI
    ├── liquibase-preview.yml  # Liquibase preview on PR (posts DDL as comment)
    └── liquibase-sync.yml     # Apply Liquibase changelogs on merge to main
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

## K8s Runner (ARC)

Separate from the LXC runner above, the `liquibase-preview` and `liquibase-sync` workflows run on an **ephemeral self-hosted runner deployed inside the k3s cluster** via the **GitHub Actions Runner Controller (ARC)**. This gives the runner direct in-cluster DNS access to the MySQL services so Liquibase can reach them without exposing MySQL externally.

ARC consists of a controller operator (`arc-controller` ArgoCD app) and a runner scale set (`k8s-gh-runner` app), both in the `github-runners` namespace. ARC auto-scales ephemeral runner pods on demand and handles registration (no `config.sh`/`run.sh`, no env-var-based registration).

| Attribute | Value |
|-----------|-------|
| Scale set name | `k8s-gh-runner` |
| Labels | `self-hosted,k8s` |
| Namespace | `github-runners` |
| Controller chart | `ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller` (v0.14.2) |
| Runner chart | `helm/k8s-gh-runner/` (depends on `gha-runner-scale-set` OCI chart v0.14.2) |
| Lifecycle | Ephemeral — ARC creates a runner pod per job and deletes it after |

Workflows target the scale set with `runs-on: [self-hosted, k8s]`.

**Liquibase sync flow** (managed under `database/`):
- `liquibase-preview.yml` — on PR touching `database/**`, records existing baselines via `changelogSync` (non-destructive), then runs `liquibase status --verbose` + `liquibase updateSQL` and posts the pending changesets / DDL as a PR comment.
- `liquibase-sync.yml` — on push to `main` touching `database/**`, runs `changelogSync` then `liquibase update` against the dev and prod MySQL databases.
- Both use `dorny/paths-filter@v3` to only preview/sync the specific databases that changed, and provision Java + Liquibase on the runner via `actions/setup-java@v4` + `liquibase/setup-liquibase@v3`.
- Liquibase Community 4.32.0 does **not** bundle the MySQL JDBC driver. Both workflows install
  `mysql-connector-j` into `/tmp/liquibase-lib` and pass it via `--classpath="$LIQUIBASE_CLASSPATH"`
  on every `liquibase` invocation (otherwise runs fail with
  `Cannot find database driver: com.mysql.jdbc.Driver`).
- `changelogSync` is run before `update` so the baseline `v00000__baseline.sql` dumps (full
  `mysqldump` exports) are **not** replayed against already-populated databases. It records the
  `init-baseline` changeset in `DATABASECHANGELOG` without executing the SQL, so `update` becomes
  a no-op ("up to date") and never drops/recreates existing tables. New migration scripts added
  later will still apply incrementally.
- DB credentials are sealed into SealedSecrets in the `github-runners` namespace (`liquibase-dev-db` / `liquibase-prod-db`) and exposed to every runner pod as `DEV_JDBC_PASSWORD` / `PROD_JDBC_PASSWORD`.

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
