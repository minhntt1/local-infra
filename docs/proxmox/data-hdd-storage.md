# data-hdd Storage — LVM-Thin Pool on Proxmox

## Overview

The `data-hdd` storage is an LVM-thin pool on the Proxmox host providing additional disk capacity separate from `local-lvm` (which holds the OS and VM root disks).

## Discovery

Discovered when listing Proxmox local storage via `pvesm status`:

| Name | Type | Status | Total | Used | Available | % Used |
|------|------|--------|-------|------|-----------|--------|
| data-hdd | lvmthin | active | ~684 GiB | 0 | ~684 GiB | 0.00% |
| local | dir | active | ~94 GiB | ~9.2 GiB | ~80 GiB | 9.83% |
| local-lvm | lvmthin | active | ~338 GiB | ~17 GiB | ~321 GiB | 5.08% |

## Purpose

- Provides **bulk storage** (~684 GiB) for data that does not need to live on the faster `local-lvm` pool.
- Used as the backing store for the **prod VM's secondary disk** (scsi1, 20G).
- Future VMs or additional disks can target `data-hdd` for capacity-oriented workloads.

## Consumption

### Prod VM (VMID 200)

A 20 GB disk is attached as `scsi1` on `data-hdd`, configured via Terraform's `extra_disks` mechanism:

```
scsi1: data-hdd:vm-200-disk-0,aio=io_uring,backup=1,cache=none,size=20G,ssd=0
```

Inside the VM the disk appears as `/dev/sdb` and is managed by Ansible (k3s_common role):
- Partitioned as GPT single ext4 partition (`/dev/sdb1`)
- Formatted as ext4
- Mounted at `/data` with `defaults,noatime`
- `/data/k3s/` directory created for k3s workload storage

## Terraform Integration

The `extra_disks` field in `variables.tf` allows any VM to attach additional disks:

```hcl
extra_disks = optional(list(object({
  datastore_id = string
  interface    = string
  size         = number
  ssd          = optional(bool, false)
})), [])
```

Example for prod VM:

```hcl
extra_disks = [
  {
    datastore_id = "data-hdd"
    interface    = "scsi1"
    size         = 20
    ssd          = false
  }
]
```

## Ansible Integration

The `k3s_common` role handles disk setup inside the VM:

1. Check if `/dev/sdb` exists
2. Create GPT partition + ext4 filesystem (skipped if `/dev/sdb1` already exists)
3. Mount to `/data` (idempotent, checks fstab and mount state)
4. Create `/data/k3s` directory

All tasks are safe to re-run — existing data is never overwritten.

## Future Use

- Additional VMs can consume `data-hdd` capacity via the same `extra_disks` pattern
- The pool has ~684 GiB available for new disks