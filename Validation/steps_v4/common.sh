#!/usr/bin/env bash
# Per-distro configuration and shared helpers for validation v4.
# Sourced by launch_v4.sh and by every per_distro step script.

# libvirt picks system vs. session URI by UID, not by libvirt group membership:
# a plain `virsh`/`virt-install` run as a non-root user silently connects to
# qemu:///session unless told otherwise. Force system mode everywhere.
export LIBVIRT_DEFAULT_URI=qemu:///system

# ---------------------------------------------------------------------------
# Per-distro static configuration
# ---------------------------------------------------------------------------

# OS family, drives the unattended file format and the package manager calls.
declare -A DISTRO_FAMILY
DISTRO_FAMILY[rhel9]=redhat
DISTRO_FAMILY[rhel10]=redhat
DISTRO_FAMILY[debian13]=debian
DISTRO_FAMILY[ubuntu24]=ubuntu
DISTRO_FAMILY[ubuntu26]=ubuntu
DISTRO_FAMILY[leap16]=suse

# ISO filenames (cached in $ISO_DIR on the host) and their download URLs.
declare -A DISTRO_ISO_NAME
DISTRO_ISO_NAME[rhel9]=Rocky-9.8-x86_64-dvd.iso
DISTRO_ISO_NAME[rhel10]=Rocky-10.2-x86_64-dvd1.iso
DISTRO_ISO_NAME[debian13]=debian-13.7.0-amd64-netinst.iso
DISTRO_ISO_NAME[ubuntu24]=ubuntu-24.04.4-live-server-amd64.iso
DISTRO_ISO_NAME[ubuntu26]=ubuntu-26.04.1-live-server-amd64.iso
DISTRO_ISO_NAME[leap16]=Leap-16.0-offline-installer-x86_64.install.iso

declare -A DISTRO_ISO_URL
DISTRO_ISO_URL[rhel9]=https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9.8-x86_64-dvd.iso
DISTRO_ISO_URL[rhel10]=https://download.rockylinux.org/pub/rocky/10/isos/x86_64/Rocky-10.2-x86_64-dvd1.iso
DISTRO_ISO_URL[debian13]=https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.7.0-amd64-netinst.iso
DISTRO_ISO_URL[ubuntu24]=https://releases.ubuntu.com/24.04.4/ubuntu-24.04.4-live-server-amd64.iso
DISTRO_ISO_URL[ubuntu26]=https://releases.ubuntu.com/26.04.1/ubuntu-26.04.1-live-server-amd64.iso
DISTRO_ISO_URL[leap16]=https://download.opensuse.org/distribution/leap/16.0/offline/Leap-16.0-offline-installer-x86_64.install.iso

# netboot_id, as keyed in pxe_stack's netboots_installer.yml, used with
# `bluebanquise-netboots-installer` to PXE-deploy the cluster nodes.
declare -A DISTRO_NETBOOT_ID
DISTRO_NETBOOT_ID[rhel9]=rhel_9
DISTRO_NETBOOT_ID[rhel10]=rhel_10
DISTRO_NETBOOT_ID[debian13]=debian_13
DISTRO_NETBOOT_ID[ubuntu24]=ubuntu_24.04
DISTRO_NETBOOT_ID[ubuntu26]=ubuntu_26.04
DISTRO_NETBOOT_ID[leap16]=opensuse_16

# This validation only targets x86_64.
DISTRO_NETBOOT_ARCH=x86_64

# virt-install --os-variant. The hypervisor's osinfo-db has no rocky10,
# ubuntu26.04 or opensuse16 yet: closest known entries are used instead.
declare -A DISTRO_OS_VARIANT
DISTRO_OS_VARIANT[rhel9]=rocky9
DISTRO_OS_VARIANT[rhel10]=rhel10.0
DISTRO_OS_VARIANT[debian13]=debian13
DISTRO_OS_VARIANT[ubuntu24]=ubuntu24.04
DISTRO_OS_VARIANT[ubuntu26]=ubuntu25.10
DISTRO_OS_VARIANT[leap16]=opensusetumbleweed

# Firmware of all VMs of a distro run. rhel9 stays on legacy BIOS so this
# path keeps being exercised, everything else is UEFI (no secure boot).
declare -A DISTRO_FIRMWARE
DISTRO_FIRMWARE[rhel9]=bios
DISTRO_FIRMWARE[rhel10]=efi
DISTRO_FIRMWARE[debian13]=efi
DISTRO_FIRMWARE[ubuntu24]=efi
DISTRO_FIRMWARE[ubuntu26]=efi
DISTRO_FIRMWARE[leap16]=efi

# The mgmt VM's two NICs: an uplink on the $UPLINK_NETWORK NAT network
# (internet, like an admin's uplink), and the cluster network where its own
# BlueBanquise serves DHCP/PXE. MACs must match the cluster inventory.
declare -A DISTRO_MGMT_MAC_UPLINK
DISTRO_MGMT_MAC_UPLINK[rhel9]=52:54:00:bb:09:01
DISTRO_MGMT_MAC_UPLINK[rhel10]=52:54:00:bb:10:01
DISTRO_MGMT_MAC_UPLINK[debian13]=52:54:00:bb:13:01
DISTRO_MGMT_MAC_UPLINK[ubuntu24]=52:54:00:bb:24:01
DISTRO_MGMT_MAC_UPLINK[ubuntu26]=52:54:00:bb:26:01
DISTRO_MGMT_MAC_UPLINK[leap16]=52:54:00:bb:16:01

# Fixed by MAC in the uplink network DHCP (vms/validation_uplink.xml).
declare -A DISTRO_MGMT_UPLINK_IP
DISTRO_MGMT_UPLINK_IP[rhel9]=192.168.123.9
DISTRO_MGMT_UPLINK_IP[rhel10]=192.168.123.10
DISTRO_MGMT_UPLINK_IP[debian13]=192.168.123.13
DISTRO_MGMT_UPLINK_IP[ubuntu24]=192.168.123.24
DISTRO_MGMT_UPLINK_IP[ubuntu26]=192.168.123.26
DISTRO_MGMT_UPLINK_IP[leap16]=192.168.123.16

declare -A DISTRO_MGMT_MAC_CLUSTER
DISTRO_MGMT_MAC_CLUSTER[rhel9]=52:54:00:cc:09:01
DISTRO_MGMT_MAC_CLUSTER[rhel10]=52:54:00:cc:10:01
DISTRO_MGMT_MAC_CLUSTER[debian13]=52:54:00:cc:13:01
DISTRO_MGMT_MAC_CLUSTER[ubuntu24]=52:54:00:cc:24:01
DISTRO_MGMT_MAC_CLUSTER[ubuntu26]=52:54:00:cc:26:01
DISTRO_MGMT_MAC_CLUSTER[leap16]=52:54:00:cc:16:01

# Cluster nodes (same for all distros, since runs are sequential).
export CLUSTER_MGMT_IP=10.20.0.1
export CLUSTER_LOGIN1_MAC=52:54:00:cc:00:10
export CLUSTER_C001_MAC=52:54:00:cc:00:11
export CLUSTER_C002_MAC=52:54:00:cc:00:12

# Hostname of the mgmt VM, as named in the cluster inventory.
export MGMT_HOSTNAME=mgt

# Admin user created by the OS installer, the "USB key" install. Its password
# only serves console debugging, SSH is key only.
export INSTALL_USER=validation
export INSTALL_USER_PASSWORD=validation

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

# ServerAlive: a connection to a VM that rebooted or changed IP fails after a
# minute instead of hanging forever.
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=10 -o ServerAliveInterval=15 -o ServerAliveCountMax=4"

log() {
    echo "[$(date '+%H:%M:%S')] $*"
}

mgmt_vm_name() {
    echo "mgmt_$1"
}

# SSH shortcuts to the mgmt VM.
setup_ssh_aliases() {
    local distro=$1
    MGMT_IP=${DISTRO_MGMT_UPLINK_IP[$distro]}
    SSH_INSTALL="ssh $SSH_OPTS $INSTALL_USER@$MGMT_IP"
    SSH_MGMT="ssh $SSH_OPTS bluebanquise@$MGMT_IP"
    SCP_MGMT="scp $SSH_OPTS"
}

# virt-install firmware flags and the matching virsh undefine flags.
firmware_flags() {
    if [ "${DISTRO_FIRMWARE[$1]}" == "efi" ]; then
        echo "--boot uefi,firmware.feature0.enabled=no,firmware.feature0.name=secure-boot"
    fi
}

destroy_vm() {
    local vm=$1
    virsh destroy "$vm" 2>/dev/null && log "  $vm destroyed." || true
    virsh undefine "$vm" --nvram 2>/dev/null && log "  $vm undefined." || true
    rm -f "$IMAGES_DIR/$vm.qcow2"
}
