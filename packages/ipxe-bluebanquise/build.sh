set -x

CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $CURRENT_DIR/version.sh

if [ "$distribution" == 'RedHat' ]; then
    if [ $distribution_version -eq 7 ]; then
        if [ $distribution_architecture == 'aarch64' ]; then
            # scl enable devtoolset-7 bash
	    yum install centos-release-scl -y
	    yum install devtoolset-7 -y
	    source scl_source enable devtoolset-7
        fi
    fi
fi

# iPXE
if [ ! -f $working_directory/sources/ipxe/README ]; then
    mkdir -p $working_directory/sources/ipxe/
    cd $working_directory/sources/ipxe/
    git clone https://github.com/ipxe/ipxe.git .
fi

# No git pull by default, could not be what is expected
# git pull

rm -Rf $working_directory/build/ipxe/
mkdir -p $working_directory/build/ipxe/
cd $working_directory/build/ipxe/
cp -a $working_directory/sources/ipxe/* $working_directory/build/ipxe/

cp $root_directory/packages/ipxe-bluebanquise/grub2-efi-autofind.cfg .
cp $root_directory/packages/ipxe-bluebanquise/grub2-shell.cfg .

# Customizing
# Building embed ipxe files
last_commit=$(cd $working_directory/sources/ipxe; git log | grep commit | sed -n 1p | awk -F ' ' '{print $2}'; cd ../../../;)
if [ -z $ipxe_bluebanquise_release ]
then
    ipxe_bluebanquise_release=$last_commit
fi
echo "#!ipxe" > src/bluebanquise_standard.ipxe
echo "cpair --foreground 6 0" >> src/bluebanquise_standard.ipxe
cat $root_directory/packages/ipxe-bluebanquise/$ipxe_bluebanquise_logo.ipxe >> src/bluebanquise_standard.ipxe
cat $root_directory/packages/ipxe-bluebanquise/bluebanquise_standard.ipxe >> src/bluebanquise_standard.ipxe
sed -i "s/IPXECOMMIT/$last_commit/" src/bluebanquise_standard.ipxe
echo "cpair 0" >> src/bluebanquise_standard.ipxe

echo "#!ipxe" > src/bluebanquise_dhcpretry.ipxe
echo "cpair --foreground 6 0" >> src/bluebanquise_dhcpretry.ipxe
cat $root_directory/packages/ipxe-bluebanquise/$ipxe_bluebanquise_logo.ipxe >> src/bluebanquise_dhcpretry.ipxe
cat $root_directory/packages/ipxe-bluebanquise/bluebanquise_dhcpretry.ipxe >> src/bluebanquise_dhcpretry.ipxe
sed -i "s/IPXECOMMIT/$last_commit/" src/bluebanquise_dhcpretry.ipxe
echo "cpair 0" >> src/bluebanquise_dhcpretry.ipxe

echo "#!ipxe" > src/bluebanquise_noshell.ipxe
echo "cpair --foreground 6 0" >> src/bluebanquise_noshell.ipxe
cat $root_directory/packages/ipxe-bluebanquise/$ipxe_bluebanquise_logo.ipxe >> src/bluebanquise_noshell.ipxe
cat $root_directory/packages/ipxe-bluebanquise/bluebanquise_noshell.ipxe >> src/bluebanquise_noshell.ipxe
sed -i "s/IPXECOMMIT/$last_commit/" src/bluebanquise_noshell.ipxe
echo "cpair 0" >> src/bluebanquise_noshell.ipxe

if [ $distribution_architecture == 'x86_64' ]; then
    ipxe_arch=x86_64
    debug_flags=intel,dhcp,vesafb
elif [ $distribution_architecture == 'aarch64' ] || [ $distribution_architecture == 'arm64' ]; then
    ipxe_arch=arm64
    debug_flags=intel,dhcp
fi

mkdir $working_directory/build/ipxe/bin/$ipxe_arch/ -p

if [ $distribution == "Ubuntu" ]; then
    grub-mkstandalone -O $ipxe_arch-efi -o grub2_efi_autofind.img "boot/grub/grub.cfg=grub2-efi-autofind.cfg"
    grub-mkstandalone -O $ipxe_arch-efi -o grub2_shell.img "boot/grub/grub.cfg=grub2-shell.cfg"
else
    grub2-mkstandalone -O $ipxe_arch-efi -o grub2_efi_autofind.img "boot/grub/grub.cfg=grub2-efi-autofind.cfg"
    grub2-mkstandalone -O $ipxe_arch-efi -o grub2_shell.img "boot/grub/grub.cfg=grub2-shell.cfg"
fi
mv grub2_efi_autofind.img $working_directory/build/ipxe/bin/$ipxe_arch/
mv grub2_shell.img $working_directory/build/ipxe/bin/$ipxe_arch/

cd src

# Not sure it worh enabling https without injecting certificates...

sed -i 's/.*DOWNLOAD_PROTO_HTTPS.*/#define DOWNLOAD_PROTO_HTTPS/' config/general.h
sed -i 's/.*PING_CMD.*/#define PING_CMD/' config/general.h
sed -i 's/.*CONSOLE_CMD.*/#define CONSOLE_CMD/' config/general.h
sed -i 's/.*CONSOLE_FRAMEBUFFER.*/#define CONSOLE_FRAMEBUFFER/' config/console.h
#sed -i 's/.*IMAGE_BZIMAGE.*/#define IMAGE_BZIMAGE/' config/general.h
sed -i 's/.*IMAGE_ZLIB.*/#define IMAGE_ZLIB/' config/general.h
sed -i 's/.*IMAGE_GZIP.*/#define IMAGE_GZIP/' config/general.h
#sed -i 's/.*IMAGE_EFI.*/#define IMAGE_EFI/' config/general.h

############################################################################################### STANDARD
if [ $distribution_architecture == 'x86_64' ]; then
    make -j $nb_cores bin/undionly.kpxe EMBED=bluebanquise_standard.ipxe DEBUG=$debug_flags
fi
make -j $nb_cores bin-$ipxe_arch-efi/ipxe.efi EMBED=bluebanquise_standard.ipxe DEBUG=$debug_flags
make -j $nb_cores bin-$ipxe_arch-efi/snponly.efi EMBED=bluebanquise_standard.ipxe DEBUG=$debug_flags
make -j $nb_cores bin-$ipxe_arch-efi/snp.efi EMBED=bluebanquise_standard.ipxe DEBUG=$debug_flags
#        make -j $nb_cores bin/ipxe.iso EMBED=bluebanquise_standard.ipxe DEBUG=$debug_flags
#        make -j $nb_cores bin/ipxe.usb EMBED=bluebanquise_standard.ipxe DEBUG=$debug_flags

if [ $distribution_architecture == 'x86_64' ]; then
    rm -Rf /dev/shm/efiiso/efi/boot
    mkdir -p /dev/shm/efiiso/efi/boot
    cp bin-x86_64-efi/ipxe.efi /dev/shm/efiiso/efi/boot/bootx64.efi
    mkisofs -o standard_efi.iso -J -r /dev/shm/efiiso
    cp standard_efi.iso $working_directory/build/ipxe/bin/x86_64/standard_efi.iso
fi

mv bin-$ipxe_arch-efi/ipxe.efi $working_directory/build/ipxe/bin/$ipxe_arch/standard_ipxe.efi
mv bin-$ipxe_arch-efi/snponly.efi $working_directory/build/ipxe/bin/$ipxe_arch/standard_snponly_ipxe.efi
mv bin-$ipxe_arch-efi/snp.efi $working_directory/build/ipxe/bin/$ipxe_arch/standard_snp_ipxe.efi
if [ $distribution_architecture == 'x86_64' ]; then
    mv bin/undionly.kpxe $working_directory/build/ipxe/bin/x86_64/standard_undionly.kpxe
fi
#        mv bin/ipxe.iso $working_directory/build/ipxe/bin/x86_64/standard_pcbios.iso
#        mv bin/ipxe.usb $working_directory/build/ipxe/bin/x86_64/standard_pcbios.usb

############################################################################################### DHCPRETRY
if [ $distribution_architecture == 'x86_64' ]; then
    make -j $nb_cores bin/undionly.kpxe EMBED=bluebanquise_dhcpretry.ipxe DEBUG=$debug_flags
fi
make -j $nb_cores bin-$ipxe_arch-efi/ipxe.efi EMBED=bluebanquise_dhcpretry.ipxe DEBUG=$debug_flags
make -j $nb_cores bin-$ipxe_arch-efi/snponly.efi EMBED=bluebanquise_dhcpretry.ipxe DEBUG=$debug_flags
make -j $nb_cores bin-$ipxe_arch-efi/snp.efi EMBED=bluebanquise_dhcpretry.ipxe DEBUG=$debug_flags
#        make -j $nb_cores bin/ipxe.iso EMBED=bluebanquise_dhcpretry.ipxe DEBUG=$debug_flags
#        make -j $nb_cores bin/ipxe.usb EMBED=bluebanquise_dhcpretry.ipxe DEBUG=$debug_flags

if [ $distribution_architecture == 'x86_64' ]; then
    rm -Rf /dev/shm/efiiso/efi/boot
    mkdir -p /dev/shm/efiiso/efi/boot
    cp bin-x86_64-efi/ipxe.efi /dev/shm/efiiso/efi/boot/bootx64.efi
    mkisofs -o dhcpretry_efi.iso -J -r /dev/shm/efiiso
    cp dhcpretry_efi.iso $working_directory/build/ipxe/bin/x86_64/dhcpretry_efi.iso
fi

mv bin-$ipxe_arch-efi/ipxe.efi $working_directory/build/ipxe/bin/$ipxe_arch/dhcpretry_ipxe.efi
mv bin-$ipxe_arch-efi/snponly.efi $working_directory/build/ipxe/bin/$ipxe_arch/dhcpretry_snponly_ipxe.efi
mv bin-$ipxe_arch-efi/snp.efi $working_directory/build/ipxe/bin/$ipxe_arch/dhcpretry_snp_ipxe.efi
if [ $distribution_architecture == 'x86_64' ]; then
    mv bin/undionly.kpxe $working_directory/build/ipxe/bin/x86_64/dhcpretry_undionly.kpxe
fi
#        mv bin/ipxe.iso $working_directory/build/ipxe/bin/x86_64/dhcpretry_pcbios.iso
#        mv bin/ipxe.usb $working_directory/build/ipxe/bin/x86_64/dhcpretry_pcbios.usb



############################################################################################### NOSHELL
if [ $distribution_architecture == 'x86_64' ]; then
    make -j $nb_cores bin/undionly.kpxe EMBED=bluebanquise_noshell.ipxe DEBUG=$debug_flags
fi
make -j $nb_cores bin-$ipxe_arch-efi/ipxe.efi EMBED=bluebanquise_noshell.ipxe DEBUG=$debug_flags
make -j $nb_cores bin-$ipxe_arch-efi/snponly.efi EMBED=bluebanquise_noshell.ipxe DEBUG=$debug_flags
make -j $nb_cores bin-$ipxe_arch-efi/snp.efi EMBED=bluebanquise_noshell.ipxe DEBUG=$debug_flags
#        make -j $nb_cores bin/ipxe.iso EMBED=bluebanquise_dhcpretry.ipxe DEBUG=$debug_flags
#        make -j $nb_cores bin/ipxe.usb EMBED=bluebanquise_dhcpretry.ipxe DEBUG=$debug_flags

if [ $distribution_architecture == 'x86_64' ]; then
    rm -Rf /dev/shm/efiiso/efi/boot
    mkdir -p /dev/shm/efiiso/efi/boot
    cp bin-x86_64-efi/ipxe.efi /dev/shm/efiiso/efi/boot/bootx64.efi
    mkisofs -o noshell_efi.iso -J -r /dev/shm/efiiso
    cp noshell_efi.iso $working_directory/build/ipxe/bin/x86_64/noshell_efi.iso
fi

mv bin-$ipxe_arch-efi/ipxe.efi $working_directory/build/ipxe/bin/$ipxe_arch/noshell_ipxe.efi
mv bin-$ipxe_arch-efi/snponly.efi $working_directory/build/ipxe/bin/$ipxe_arch/noshell_snponly_ipxe.efi
mv bin-$ipxe_arch-efi/snp.efi $working_directory/build/ipxe/bin/$ipxe_arch/noshell_snp_ipxe.efi
if [ $distribution_architecture == 'x86_64' ]; then
    mv bin/undionly.kpxe $working_directory/build/ipxe/bin/x86_64/noshell_undionly.kpxe
fi
#        mv bin/ipxe.iso $working_directory/build/ipxe/bin/x86_64/dhcpretry_pcbios.iso
#        mv bin/ipxe.usb $working_directory/build/ipxe/bin/x86_64/dhcpretry_pcbios.usb

###############################################################################################

cd $working_directory/build/ipxe/
mkdir ipxe-$ipxe_arch-bluebanquise-$ipxe_bluebanquise_version
cp $root_directory//packages/ipxe-bluebanquise/ipxe-$ipxe_arch-bluebanquise.spec ipxe-$ipxe_arch-bluebanquise-$ipxe_bluebanquise_version
#sed -i "s|Version:\ \ XXX|Version:\ \ $ipxe_bluebanquise_version|g" ipxe-$ipxe_arch-bluebanquise-$ipxe_bluebanquise_version/ipxe-$ipxe_arch-bluebanquise.spec
sed -i "s|working_directory=XXX|working_directory=$working_directory|g" ipxe-$ipxe_arch-bluebanquise-$ipxe_bluebanquise_version/ipxe-$ipxe_arch-bluebanquise.spec
tar cvzf ipxe-$ipxe_arch-bluebanquise.tar.gz ipxe-$ipxe_arch-bluebanquise-$ipxe_bluebanquise_version
if [ "$distribution" == "Ubuntu" ]; then
    if [ "$distribution_version" == "18.04" ]; then
    rpmbuild -ta ipxe-$ipxe_arch-bluebanquise.tar.gz --target=noarch --define "_software_version $ipxe_bluebanquise_version" --define "_software_release $ipxe_bluebanquise_release" --define "dist .ubuntu1804"
elif [ "$distribution_version" == "20.04" ]; then
rpmbuild -ta ipxe-$ipxe_arch-bluebanquise.tar.gz --target=noarch --define "_software_version $ipxe_bluebanquise_version" --define "_software_release $ipxe_bluebanquise_release" --define "dist .ubuntu2004"
fi
else
    rpmbuild -ta ipxe-$ipxe_arch-bluebanquise.tar.gz --target=noarch --define "_software_version $ipxe_bluebanquise_version" --define "_software_release $ipxe_bluebanquise_release"
fi
if [ "$distribution" == "Ubuntu" ]; then
    cd /dev/shm
    alien --to-deb --scripts /root/rpmbuild/RPMS/noarch/ipxe*
    mkdir -p /root/debbuild/DEBS/noarch/
    mv *.deb /root/debbuild/DEBS/noarch/
fi


set +x
