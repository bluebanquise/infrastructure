#!/usr/bin/env bash
set -x
source /etc/os-release
NAME=$(echo -n $NAME | sed 's/\ /_/g')

rm -Rf /image
mkdir /image
cd /image
mkdir proc
mkdir sys
mkdir dev
mount -t proc /proc proc/
mount --rbind /sys sys/
mount --rbind /dev dev/

if [[ $PLATFORM_ID == "platform:el8" ]]; then
	dnf install -y --installroot=/image dnf sudo vi yum iproute procps-ng openssh-server NetworkManager kernel-modules kernel dracut dracut-live nfs-utils --exclude glibc-all-langpacks --exclude grubby --exclude libxkbcommon --exclude pinentry --exclude python3-unbound --exclude unbound-libs --exclude xkeyboard-config --exclude trousers --exclude gnupg2-smime --exclude openssl-pkcs11 --exclude rpm-plugin-systemd-inhibit --exclude shared-mime-info --exclude glibc-langpack-* --setopt=module_platform_id=$PLATFORM_ID --nobest --releasever=$VERSION_ID
fi
if [[ $PLATFORM_ID == "platform:el9" ]]; then
    dnf install -y --installroot=/image dnf vi sudo yum iproute procps-ng openssh-server NetworkManager kernel-modules kernel dracut dracut-live nfs-utils --exclude glibc-all-langpacks --exclude grubby --exclude libxkbcommon --exclude pinentry --exclude python3-unbound --exclude unbound-libs --exclude xkeyboard-config --exclude trousers --exclude gnupg2-smime --exclude openssl-pkcs11 --exclude rpm-plugin-systemd-inhibit --exclude shared-mime-info --exclude glibc-langpack-* --setopt=module_platform_id=$PLATFORM_ID --nobest --releasever=$VERSION_ID
fi

cat << EOF > /image/etc/dracut.conf.d/bluebanquise.conf
add_dracutmodules+=" nfs livenet dmsquash-live "
add_drivers+=" xfs "
hostonly=no
show_modules=yes
EOF

chroot /image /bin/bash -c "dracut --regenerate-all --force"

PLATFORM=$(echo ${PLATFORM_ID} | sed 's/platform://')
KERNEL=$(ls /image/usr/lib/modules)
KERNEL=$(echo -n ${KERNEL})

cat << EOF > /image/metadata.yaml
name: ${NAME}_${VERSION_ID}
version: ${VERSION_ID}
family: ${PLATFORM}
cpu_arch: $(uname -m)
description: |
  $NAME $VERSION minimal, including vi and iproute for easier debugging
kernel: $KERNEL
packager: Benoit LEVEUGLE <benoit.leveugle@gmail.com>
url: http://bluebanquise.com/diskless/images/${NAME}_${VERSION_ID}_minimal_$(uname -m).tar.gz
packaging_date: $(date)
EOF

cd /image
umount proc/
umount sys/
umount dev/
shopt -s dotglob
tar --exclude="proc" --exclude="sys" --exclude="dev" -czf /tmp/${NAME}_${VERSION_ID}_minimal_$(uname -m).tar.gz *
chmod 777 /tmp/${NAME}_${VERSION_ID}_minimal_$(uname -m).tar.gz
shopt -u dotglob

cd
#rm -Rf /image
rm -f /tmp/$1.image_link
echo "${NAME}_${VERSION_ID}_minimal_$(uname -m).tar.gz" > /tmp/$1.image_link
