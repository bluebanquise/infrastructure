# Kickstart for the mgmt VM, el9 and el10. Injected in the installer initrd
# by virt-install (--initrd-inject), installation source is the DVD.
# @...@ placeholders are replaced by per_distro/10_install_mgmt.sh.
text
cdrom
lang en_US.UTF-8
keyboard us
timezone Etc/UTC

# Uplink only (DHCP from libvirt). The cluster NIC is left to BlueBanquise's
# nic role, as on a real first management server.
network --device=@MAC_UPLINK@ --bootproto=dhcp --activate --hostname=@HOSTNAME@

rootpw --lock
user --name=@USER@ --groups=wheel --iscrypted --password=@PASSWORD_HASH@
sshkey --username=@USER@ "@SSH_KEY@"

zerombr
clearpart --all --initlabel --drives=vda
autopart --type=plain --nohome
bootloader --boot-drive=vda

firewall --enabled --ssh
selinux --enforcing
services --enabled=sshd
skipx
firstboot --disabled

%packages
@^minimal-environment
curl
%end

%post
echo '@USER@ ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/@USER@
chmod 440 /etc/sudoers.d/@USER@
%end

poweroff
