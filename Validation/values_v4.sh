#!/usr/bin/env bash
# Host-level configuration for validation v4.
# Edit this file to match your environment before running launch_v4.sh.

# libvirt networks: the mgmt VM's NAT uplink (vms/validation_uplink.xml), and
# the cluster network (the mgmt VM serves DHCP/PXE on it).
export UPLINK_NETWORK=validation_uplink
export CLUSTER_NETWORK=cluster_network

# Bandwidth cap of the mgmt VM uplink, in KiB/s (inbound and outbound). The
# whole cluster reaches internet through it. Below 2 MB/s: the hypervisor's
# network link (power line) overheats on sustained load.
export UPLINK_RATE_KBPS=1900

# Storage, all on the fast data disk:
#   ISO_DIR         downloaded installation ISOs (cache, kept between runs)
#   UNATTENDED_DIR  rendered unattended files, per distro
#   IMAGES_DIR      VM disks
export VALIDATION_DATA_DIR=/data2/validation
export ISO_DIR=$VALIDATION_DATA_DIR/iso
export UNATTENDED_DIR=$VALIDATION_DATA_DIR/unattended
export IMAGES_DIR=$VALIDATION_DATA_DIR/images

# BlueBanquise tested is master: the mgmt VM is bootstrapped the documented
# way (online_bootstrap.sh), which clones and installs master. Patches not yet
# merged on master can be dropped in steps_v4/patches/ (git diff format,
# collection paths), they are applied on top by per_distro/11.

# Ordered list of distributions to validate. Override from the environment
# with a space separated list, e.g.: DISTROS="rhel9 debian13" ./launch_v4.sh
DISTROS=(${DISTROS:-rhel9 rhel10 debian13 ubuntu24 ubuntu26 leap16})

# Resume control: set STEP=<n> to skip steps already completed (with
# CURRENT_DISTRO=<distro> to skip the distros before it).
# Steps: 1=networks,
#        10=install_mgmt, 11=bb_mgmt, 12=mgmt_stack, 13=pxe_prep,
#        14=pxe_nodes, 15=node_stacks, 16=slurm_test, 17=cleanup
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
    echo "[values_v4] Generated new munge key: $MUNGE_KEY_FILE"
fi
