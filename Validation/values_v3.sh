#!/usr/bin/env bash
# Host-level configuration for validation v3.
# Edit this file to match your environment before running launch_v3.sh.

# IP of the host on virbr0 (libvirt default NAT network).
export HOST_IP=192.168.122.1
export HOST_HTTP_PORT=8000

# BlueBanquise git branch to install on all management VMs.
export BB_BRANCH=master

# libvirt network names.
export VIRBR1_NETWORK=private_network
export VIRBR2_NETWORK=cluster_network

# mgt1 MAC on virbr0 (used to discover its DHCP-assigned IP).
export MGT1_MAC_VIRBR0=52:54:00:fa:12:01

# Ordered list of distributions to validate.
export DISTROS=(rhel9 rhel10 ubuntu24 debian13)

# Resume control: set STEP=<n> to skip steps already completed.
# Steps: 1=networks, 2=http_server, 3=mgt1_install, 4=mgt1_bb,
#        10=pxe_mgmt, 11=bb_mgmt, 12=mgmt_stack, 13=pxe_prep,
#        14=pxe_nodes, 15=node_stacks, 16=slurm_test
export STEP=${STEP:-0}

# Munge key: generated once and stored locally (gitignored).
# All cluster Slurm deployments share this key.
LAUNCH_CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
MUNGE_KEY_FILE="$LAUNCH_CURRENT_DIR/.munge_key_b64"
if [ -f "$MUNGE_KEY_FILE" ]; then
    export SLURM_MUNGE_KEY_B64=$(cat "$MUNGE_KEY_FILE")
else
    export SLURM_MUNGE_KEY_B64=$(dd if=/dev/urandom bs=64 count=1 2>/dev/null | base64 -w 0)
    echo "$SLURM_MUNGE_KEY_B64" > "$MUNGE_KEY_FILE"
    echo "[values_v3] Generated new munge key: $MUNGE_KEY_FILE"
fi
