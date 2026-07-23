#!/bin/bash
# NAT iptables hook script for Proxmox VMs.
# Installed and managed by Terraform — do not edit manually.
#
# Dynamically resolves the VM's IP via the QEMU guest agent at runtime,
# so it works with DHCP-assigned addresses.
#
# Arguments passed by Proxmox:
#   $1 = VMID
#   $2 = phase (pre-start / post-start / pre-stop / post-stop)
set -uo pipefail

# Maximum seconds to wait for the QEMU guest agent to become responsive.
MAX_WAIT=30
WAIT_INTERVAL=2

VMID="$${1}"
PHASE="$${2}"

resolve_ip() {
  # Query the QEMU guest agent for the VM's current IPv4 address.
  # Falls back to the first IPv4 address found on any interface (excluding loopback).
  pvesh get "/nodes/localhost/qemu/$${VMID}/agent/network-get-interfaces" --output-format json 2>/dev/null \
    | python3 -c "
import sys, json
data = json.load(sys.stdin)
for iface in data.get('result', []):
    for addr in iface.get('ip-addresses', []):
        if addr.get('ip-address-type') == 'ipv4' and not addr['ip-address'].startswith('127.'):
            print(addr['ip-address'])
            sys.exit(0)
" 2>/dev/null && return 0
  return 1
}

add_rule() {
  iptables -t nat -C PREROUTING -i vmbr0 -p "$1" --dport "$2" -j DNAT --to-destination "$${IP}:$3" 2>/dev/null || \
  iptables -t nat -A PREROUTING -i vmbr0 -p "$1" --dport "$2" -j DNAT --to-destination "$${IP}:$3"
}

del_rule() {
  iptables -t nat -D PREROUTING -i vmbr0 -p "$1" --dport "$2" -j DNAT --to-destination "$${IP}:$3" 2>/dev/null || true
}

# pre-start: VM not booted yet, guest agent unavailable — silently skip.
# post-start: VM is running, resolve IP and add NAT rules.
# pre-stop: VM still running, resolve IP and remove NAT rules.
# post-stop: round complete, nothing to do.
# During post-start it may take several seconds before the guest agent is up.
wait_for_ip() {
  local elapsed=0
  while [ $elapsed -lt $MAX_WAIT ]; do
    IP=$(resolve_ip) && return 0
    sleep $WAIT_INTERVAL
    elapsed=$((elapsed + WAIT_INTERVAL))
  done
  return 1
}

if [ "$${PHASE}" = "post-start" ] || [ "$${PHASE}" = "pre-stop" ]; then
  if [ "$${PHASE}" = "post-start" ]; then
    if ! wait_for_ip; then
      echo "WARNING: Failed to resolve IP for VM $${VMID} after ${MAX_WAIT}s — port forwarding not applied" >&2
      exit 0
    fi
  else
    IP=$(resolve_ip) || {
      echo "WARNING: Failed to resolve IP for VM $${VMID} — port forwarding not removed" >&2
      exit 0
    }
  fi
  if [ "$${PHASE}" = "post-start" ]; then
%{ for f in forwards ~}
    add_rule ${f.protocol} ${f.public_port} ${f.internal_port}
%{ endfor ~}
    echo "NAT rules added for VM $${VMID} ($${IP})"
  else
%{ for f in forwards ~}
    del_rule ${f.protocol} ${f.public_port} ${f.internal_port}
%{ endfor ~}
    echo "NAT rules removed for VM $${VMID} ($${IP})"
  fi
fi