#!/usr/bin/env bash
# Per-distro configuration and shared helpers.
# Sourced by every per_distro step script.

# libvirt picks system vs. session URI by UID, not by libvirt group membership —
# a plain `virsh`/`virt-install` run as a non-root user silently connects to
# qemu:///session (spawning an unprivileged per-user libvirtd with no bridge
# capability) unless told otherwise. Force system mode for every script here.
export LIBVIRT_DEFAULT_URI=qemu:///system

# ---------------------------------------------------------------------------
# Per-distro static configuration
# ---------------------------------------------------------------------------

declare -A DISTRO_VM_NAME
DISTRO_VM_NAME[rhel9]=mgmt_rhel9
DISTRO_VM_NAME[rhel10]=mgmt_rhel10
DISTRO_VM_NAME[ubuntu24]=mgmt_ubuntu24
DISTRO_VM_NAME[debian13]=mgmt_debian13

# IP of the mgmt VM on virbr1 (assigned by mgt1 DHCP via MAC).
declare -A DISTRO_MGMT_VIRBR1_IP
DISTRO_MGMT_VIRBR1_IP[rhel9]=10.10.0.21
DISTRO_MGMT_VIRBR1_IP[rhel10]=10.10.0.22
DISTRO_MGMT_VIRBR1_IP[ubuntu24]=10.10.0.23
DISTRO_MGMT_VIRBR1_IP[debian13]=10.10.0.24

# MACs for the mgmt VM on virbr1 (used by mgt1 DHCP for static assignment).
declare -A DISTRO_MGMT_MAC_VIRBR1
DISTRO_MGMT_MAC_VIRBR1[rhel9]=52:54:00:bb:09:01
DISTRO_MGMT_MAC_VIRBR1[rhel10]=52:54:00:bb:10:01
DISTRO_MGMT_MAC_VIRBR1[ubuntu24]=52:54:00:bb:24:01
DISTRO_MGMT_MAC_VIRBR1[debian13]=52:54:00:bb:13:01

# MACs for the mgmt VM on virbr2 (cluster network).
declare -A DISTRO_MGMT_MAC_VIRBR2
DISTRO_MGMT_MAC_VIRBR2[rhel9]=52:54:00:cc:09:01
DISTRO_MGMT_MAC_VIRBR2[rhel10]=52:54:00:cc:10:01
DISTRO_MGMT_MAC_VIRBR2[ubuntu24]=52:54:00:cc:24:01
DISTRO_MGMT_MAC_VIRBR2[debian13]=52:54:00:cc:13:01

# ISO filenames (downloaded to http/ on the host).
declare -A DISTRO_ISO_NAME
DISTRO_ISO_NAME[rhel9]=Rocky-9-latest-x86_64-dvd.iso
DISTRO_ISO_NAME[rhel10]=Rocky-10-latest-x86_64-dvd.iso
DISTRO_ISO_NAME[ubuntu24]=ubuntu-24.04.4-live-server-amd64.iso
DISTRO_ISO_NAME[debian13]=debian-testing-amd64-netinst.iso

# ISO download URLs.
declare -A DISTRO_ISO_URL
DISTRO_ISO_URL[rhel9]=https://dl.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9-latest-x86_64-dvd.iso
DISTRO_ISO_URL[rhel10]=https://dl.rockylinux.org/pub/rocky/10/isos/x86_64/Rocky-10-latest-x86_64-dvd.iso
DISTRO_ISO_URL[ubuntu24]=https://releases.ubuntu.com/24.04.4/ubuntu-24.04.4-live-server-amd64.iso
DISTRO_ISO_URL[debian13]=https://cdimage.debian.org/cdimage/daily-builds/daily/arch-latest/amd64/iso-cd/debian-testing-amd64-netinst.iso

# netboot_id, as keyed in pxe_stack's own netboots_installer.yml (files/
# netboots_installer.yml), used with `bluebanquise-netboots-installer`.
declare -A DISTRO_NETBOOT_ID
DISTRO_NETBOOT_ID[rhel9]=rhel_9
DISTRO_NETBOOT_ID[rhel10]=rhel_10
DISTRO_NETBOOT_ID[ubuntu24]=ubuntu_24.04
DISTRO_NETBOOT_ID[debian13]=debian_13

# Architecture for bluebanquise-netboots-installer — fixed, this validation
# effort only ever targets x86_64.
DISTRO_NETBOOT_ARCH=x86_64

# virt-install --os-variant value.
declare -A DISTRO_OS_VARIANT
DISTRO_OS_VARIANT[rhel9]=rhel8-unknown
DISTRO_OS_VARIANT[rhel10]=rhel8-unknown
DISTRO_OS_VARIANT[ubuntu24]=ubuntu24.04
DISTRO_OS_VARIANT[debian13]=debian12

# Extra virt-install boot flags. RHEL9/10 initially looked like they needed
# legacy BIOS to avoid "Initramfs unpacking failed: invalid magic at start of
# compressed archive" panics on their large (~200MB+) installer initrd — but
# the real root cause (2026-08-07) was menu.ipxe.j2 leaking a "stage_report"
# resident image (imgfetch'd, never imgfree'd) that got bundled into the
# initrd payload at boot time; fixed there, independent of firmware mode.
# rhel9 stays on legacy BIOS as the already-validated config; rhel10 is back
# on EFI so both boot paths get exercised now that the actual fix is in.
declare -A DISTRO_BOOT_FLAGS
DISTRO_BOOT_FLAGS[rhel9]=""
DISTRO_BOOT_FLAGS[rhel10]="--boot firmware=efi,firmware.feature0.enabled=no,firmware.feature0.name=secure-boot"
DISTRO_BOOT_FLAGS[ubuntu24]=""
DISTRO_BOOT_FLAGS[debian13]=""

# Extra virsh undefine flags (--nvram only applies to EFI domains).
declare -A DISTRO_UNDEFINE_FLAGS
DISTRO_UNDEFINE_FLAGS[rhel9]=""
DISTRO_UNDEFINE_FLAGS[rhel10]=--nvram
DISTRO_UNDEFINE_FLAGS[ubuntu24]=""
DISTRO_UNDEFINE_FLAGS[debian13]=""

# Initial SSH user created by the OS installer (used before BB bootstrap).
declare -A DISTRO_INITIAL_USER
DISTRO_INITIAL_USER[rhel9]=bluebanquise
DISTRO_INITIAL_USER[rhel10]=bluebanquise
DISTRO_INITIAL_USER[ubuntu24]=bluebanquise
DISTRO_INITIAL_USER[debian13]=bluebanquise

# Pre-bootstrap commands run on the mgmt VM before online_bootstrap.sh.
# These install EPEL on RHEL and update packages everywhere. wget is also
# installed explicitly on RHEL — the minimal Rocky DVD kickstart doesn't ship
# it, but per_distro/11's very next step (online_bootstrap.sh download) uses
# it unconditionally (real live failure, 2026-08-09: "wget: command not
# found"). Ubuntu/Debian cloud/live images ship wget by default already.
declare -A DISTRO_PRE_BOOTSTRAP
DISTRO_PRE_BOOTSTRAP[rhel9]='sudo dnf install -y epel-release wget && sudo dnf update -y'
DISTRO_PRE_BOOTSTRAP[rhel10]='sudo dnf install -y epel-release wget && sudo dnf update -y'
DISTRO_PRE_BOOTSTRAP[ubuntu24]='sudo DEBIAN_FRONTEND=noninteractive apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y'
DISTRO_PRE_BOOTSTRAP[debian13]='sudo DEBIAN_FRONTEND=noninteractive apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y'

# Cluster nodes (fixed for all distros since runs are sequential).
export CLUSTER_MGMT_IP=10.20.0.1
export CLUSTER_LOGIN1_IP=10.20.0.2
export CLUSTER_C001_IP=10.20.0.3
export CLUSTER_C002_IP=10.20.0.4

export CLUSTER_LOGIN1_MAC=52:54:00:cc:00:10
export CLUSTER_C001_MAC=52:54:00:cc:00:11
export CLUSTER_C002_MAC=52:54:00:cc:00:12

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

# SSH shortcuts built at runtime from distro-specific IPs.
# Call setup_ssh_aliases <distro> after sourcing common.sh to populate these.
setup_ssh_aliases() {
    local distro=$1
    local mgmt_ip=${DISTRO_MGMT_VIRBR1_IP[$distro]}
    local ssh_opts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

    SSH_MGT1="ssh $ssh_opts bluebanquise@${MGT1_IP}"
    SCP_MGT1="scp $ssh_opts"

    # Host → mgmt VM via ProxyJump through mgt1.
    SSH_MGMT="ssh $ssh_opts -J bluebanquise@${MGT1_IP} bluebanquise@${mgmt_ip}"
    SCP_MGMT="scp $ssh_opts -J bluebanquise@${MGT1_IP}"
}

log() {
    echo "[$(date '+%H:%M:%S')] $*"
}
