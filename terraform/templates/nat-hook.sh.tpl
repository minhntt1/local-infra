#!/bin/bash
# NAT iptables hook script for Proxmox VMs.
# Installed and managed by Terraform — do not edit manually.
#
# Resolves the VM's IP from Proxmox SDN's IPAM state file (no guest-agent
# dependency, no boot-time race, works before cloud-init even finishes).
#
# Every invocation flushes any rules previously tagged for this VMID, then
# rebuilds from `forwards` below — so add/update/delete of a forward always
# converges correctly, regardless of what was installed before.
#
# Arguments passed by Proxmox: $1 = VMID, $2 = phase
set -uo pipefail

VMID="$${1}"
PHASE="$${2}"
BRIDGE="vmbr0"
TAG="nat-vm-$${VMID}"
LOG=/var/log/nat-hook.log

log() { echo "$(date -Is) [vm $${VMID}] $*" >> "$${LOG}"; }

resolve_ip() {
  python3 -c "
import json
try:
    data = json.load(open('/etc/pve/sdn/pve-ipam-state.json'))
except Exception:
    raise SystemExit(1)
for zone in data.get('zones', {}).values():
    for subnet in zone.get('subnets', {}).values():
        for ip, info in subnet.get('ips', {}).items():
            if str(info.get('vmid')) == '$${VMID}':
                print(ip)
                raise SystemExit(0)
raise SystemExit(1)
"
}

flush_rules() {
  local line
  while line=$(iptables -t nat -L PREROUTING -n --line-numbers | awk -v t="$${TAG}" '$0 ~ t {print $1; exit}'); do
    [ -z "$${line}" ] && break
    iptables -t nat -D PREROUTING "$${line}"
  done
  while line=$(iptables -L FORWARD -n --line-numbers | awk -v t="$${TAG}" '$0 ~ t {print $1; exit}'); do
    [ -z "$${line}" ] && break
    iptables -D FORWARD "$${line}"
  done
}

add_rule() {
  local proto=$1 pub=$2 internal=$3
  iptables -t nat -A PREROUTING -i "$${BRIDGE}" -p "$${proto}" --dport "$${pub}" \
    -m comment --comment "$${TAG}" -j DNAT --to-destination "$${IP}:$${internal}"
  iptables -A FORWARD -p "$${proto}" -d "$${IP}" --dport "$${internal}" \
    -m comment --comment "$${TAG}" -j ACCEPT
}

apply_forwards() {
  flush_rules
  if [ -z "$${IP:-}" ]; then
    log "no IP resolved — rules flushed, nothing (re)installed"
    return 1
  fi
%{ for f in forwards ~}
  add_rule ${f.protocol} ${f.public_port} ${f.internal_port}
%{ endfor ~}
  log "rules reconciled for IP $${IP} (${length(forwards)} forward(s))"
}

case "$${PHASE}" in
  post-start)
    ( for _ in $(seq 1 15); do IP=$(resolve_ip) && break; sleep 2; done
      apply_forwards
    ) >> "$${LOG}" 2>&1 &
    disown
    ;;
  pre-stop)
    flush_rules
    log "rules flushed on stop"
    ;;
  reconcile)
    for _ in $(seq 1 5); do IP=$(resolve_ip) && break; sleep 2; done
    apply_forwards
    ;;
esac
