echo
echo "  __                 "
echo " '. \                "
echo "  '- \               "
echo "   / /_         .---."
echo "  / | \\,.\/--.//    )"
echo "  |  \//        )/  / "
echo "   \  ' ^ ^    /    )____.----..  6"
echo "    '.____.    .___/            \._) "
echo "       .\/.                      )"
echo "        '\                       /"
echo "        _/ \/    ).        )    ("
echo "       /#  .!    |        /\    /"
echo "       \  C// #  /'-----''/ #  / "
echo "    .   'C/ |    |    |   |    |mrf  ,"
echo "    \), .. .'OOO-'. ..'OOO'OOO-'. ..\(,"
echo
echo "  BlueBanquise packages builder"
echo "    (c) 2019 Benoit Leveugle"
echo
echo " Detecting distribution..."
distribution=$(grep ^NAME /etc/os-release | awk -F '"' '{print $2}')
distribution_version=$(grep ^VERSION_ID /etc/os-release | awk -F '"' '{print $2}')
distribution_architecture=$(uname --m)
echo " Found $distribution $distribution_version $distribution_architecture"

working_directory=/root/bbbuilder
echo " Working directory: $working_directory"
mkdir -p $working_directory

# Packages versions
ipxe_bluebanquise_version=1.1.0

# Number of cores
nb_cores=14

set -x
echo "Cleaning"
#rm -Rf $working_directory/build
mkdir -p $working_directory/build
mkdir $working_directory/sources

echo " Installing needed packages... may take some time."
if [ "$distribution" = 'openSUSE Leap' ]; then
  if [ "$distribution_version" = "15.1" ]; then
    zypper -n install gcc rpm-build make mkisofs xz xz-devel automake autoconf bzip2 openssl-devel zlib-devel readline-devel pam-devel perl-ExtUtils-MakeMaker grub2 grub2-x86_64-efi mariadb
  fi
else
  if [ $distribution_version -eq 8 ]; then
    if [ $distribution_architecture == 'x86_64' ]; then
      dnf install make rpm-build genisoimage xz xz-devel automake autoconf python36 bzip2-devel openssl-devel zlib-devel readline-devel pam-devel perl-ExtUtils-MakeMaker grub2-tools-extra grub2-efi-x64-modules gcc mariadb mariadb-devel -y
      alternatives --set python /usr/bin/python3
    fi
    if [ $distribution_architecture == 'aarch64' ]; then
      dnf install make rpm-build genisoimage xz xz-devel automake autoconf python36 bzip2-devel openssl-devel zlib-devel readline-devel pam-devel perl-ExtUtils-MakeMaker grub2-tools-extra grub2-efi-aa64-modules gcc mariadb mariadb-devel -y
      alternatives --set python /usr/bin/python3
    fi
  fi
  if [ $distribution_version -eq 7 ]; then
    if [ $distribution_architecture == 'x86_64' ]; then
      yum install make rpm-build genisoimage xz xz-devel automake autoconf python36 bzip2-devel openssl-devel zlib-devel readline-devel pam-devel perl-ExtUtils-MakeMaker grub2-tools-extra grub2-efi-x64-modules gcc mariadb mariadb-devel -y
    fi
    if [ $distribution_architecture == 'aarch64' ]; then
      yum install make rpm-build genisoimage xz xz-devel automake autoconf python36 bzip2-devel openssl-devel zlib-devel readline-devel pam-devel perl-ExtUtils-MakeMaker grub2-tools-extra grub2-efi-aa64-modules gcc mariadb mariadb-devel -y
    fi
  fi
fi

mkdir $working_directory/sources/bluebanquise
cd $working_directory/sources/bluebanquise
if [ ! -f $working_directory/sources/bluebanquise/README.md ]; then
  git clone https://github.com/bluebanquise/bluebanquise-infrastructure.git .
fi
git pull

if false; then

cd $working_directory/sources/bluebanquise/packages/
if [ ! -f $working_directory/sources/nyancat-1.5.2.tar.gz ]; then
  wget -P $working_directory/sources/ https://github.com/klange/nyancat/archive/1.5.2.tar.gz
  mv $working_directory/sources/1.5.2.tar.gz $working_directory/sources/nyancat-1.5.2.tar.gz
fi
mkdir $working_directory/build/nyancat
cd $working_directory/build/nyancat
cp $working_directory/sources/nyancat-1.5.2.tar.gz .
tar xvzf nyancat-1.5.2.tar.gz
/usr/bin/cp -af $working_directory/sources/bluebanquise/packages/nyancat-1.5.2/* nyancat-1.5.2/
tar cvzf nyancat.tar.gz nyancat-1.5.2
rpmbuild -ta nyancat.tar.gz

if [ $distribution_architecture == 'x86_64' ]; then
# Prometheus
cd $working_directory/sources/bluebanquise/packages/
tar cvzf alertmanager-0.18.0.tar.gz alertmanager-0.18.0
rpmbuild -ta alertmanager-0.18.0.tar.gz
tar cvzf node_exporter-0.18.1.tar.gz node_exporter-0.18.1
rpmbuild -ta node_exporter-0.18.1.tar.gz
tar cvzf prometheus-2.11.1.tar.gz prometheus-2.11.1
rpmbuild -ta prometheus-2.11.1.tar.gz
fi

# Ansible CMDB
if [ ! -f $working_directory/sources/ansible-cmdb-1.30.tar.gz ]; then
  wget -P $working_directory/sources/ https://github.com/fboender/ansible-cmdb/releases/download/1.30/ansible-cmdb-1.30.tar.gz
fi
mkdir $working_directory/build/ansible-cmdb
cd ansible-cmdb
cp $working_directory/sources/ansible-cmdb-1.30.tar.gz .
tar xvzf ansible-cmdb-1.30.tar.gz
/usr/bin/cp -af $working_directory/sources/bluebanquise/packages/ansible-cmdb-1.30/* ansible-cmdb-1.30
tar cvzf ansible-cmdb-1.30.tar.gz ansible-cmdb-1.30
rpmbuild -ta ansible-cmdb-1.30.tar.gz

# Slurm
if [ ! -f $working_directory/sources/slurm-19.05.4.tar.bz2 ]; then
  wget -P $working_directory/sources/ https://download.schedmd.com/slurm/slurm-19.05.4.tar.bz2
fi
#wget https://github.com/SchedMD/slurm/archive/slurm-18-08-8-1.tar.gz
if [ ! -f $working_directory/sources/munge-0.5.13.tar.xz ]; then
  wget -P $working_directory/sources/ https://github.com/dun/munge/releases/download/munge-0.5.13/munge-0.5.13.tar.xz
fi

mkdir $working_directory/build/munge
cd $working_directory/build/munge
cp $working_directory/sources/munge-0.5.13.tar.xz .
rpmbuild -ta munge-0.5.13.tar.xz
if [ $distribution_version -eq 8 ]; then
dnf install /root/rpmbuild/RPMS/x86_64/munge* -y
fi
if [ $distribution_version -eq 7 ]; then
yum install /root/rpmbuild/RPMS/x86_64/munge* -y
fi

mkdir $working_directory/build/slurm
cd $working_directory/build/slurm
cp  $working_directory/sources/slurm-19.05.4.tar.bz2 .
tar xjvf slurm-19.05.4.tar.bz2
sed -i '1s/^/%global _hardened_ldflags\ "-Wl,-z,lazy"\n/' slurm-19.05.4/slurm.spec
sed -i '1s/^/%global _hardened_cflags\ "-Wl,-z,lazy"\n/' slurm-19.05.4/slurm.spec
sed -i '1s/^/%undefine\ _hardened_build\n/' slurm-19.05.4/slurm.spec
sed -i 's/BuildRequires:\ python/#BuildRequires:\ python/g' slurm-19.05.4/slurm.spec
tar cjvf slurm-19.05.4.tar.bz2 slurm-19.05.4

rpmbuild -ta slurm-19.05.4.tar.bz2

# Atftp
if [ $distribution_version -eq 7 ]; then
ln -s /usr/bin/aclocal /usr/bin/aclocal-1.16
ln -s /usr/bin/autoconf /usr/bin/autoconf-1.16
ln -s /usr/bin/automake /usr/bin/automake-1.16
fi
mkdir -p $working_directory/build/atftp/
if [ ! -f $working_directory/sources/atftp-0.7.2.tar.gz ]; then
  wget -P $working_directory/sources/ https://freefr.dl.sourceforge.net/project/atftp/atftp-0.7.2.tar.gz
fi
cd $working_directory/build/atftp/
cp $working_directory/sources/atftp-0.7.2.tar.gz .
tar xvzf atftp-0.7.2.tar.gz
/usr/bin/cp -f $working_directory/sources/bluebanquise/packages/atftp/* atftp-0.7.2/
rm -f atftp-0.7.2/redhat/atftp.spec
tar cvzf atftp.tar.gz atftp-0.7.2
rpmbuild -ta atftp.tar.gz

fi

# iPXE
mkdir $working_directory/sources/ipxe/
cd $working_directory/sources/ipxe/
if [ ! -f $working_directory/sources/ipxe/README.md ]; then
  git clone https://github.com/ipxe/ipxe.git .
fi
git pull
mkdir $working_directory/build/ipxe/
cd $working_directory/build/ipxe/
rm -Rf $working_directory/build/ipxe/*
cp -a $working_directory/sources/ipxe/* .
cp $working_directory/sources/bluebanquise/packages/ipxe-bluebanquise/bluebanquise_standard.ipxe src/
cp $working_directory/sources/bluebanquise/packages/ipxe-bluebanquise/bluebanquise_dhcpretry.ipxe src/
cp $working_directory/sources/bluebanquise/packages/ipxe-bluebanquise/grub2-efi-autofind.cfg .
cp $working_directory/sources/bluebanquise/packages/ipxe-bluebanquise/grub2-shell.cfg . 

if [ $distribution_architecture == 'x86_64' ]; then

mkdir $working_directory/build/ipxe/bin/x86_64/ -p

grub2-mkstandalone -O x86_64-efi -o grub2_efi_autofind.img "boot/grub/grub.cfg=grub2-efi-autofind.cfg"
grub2-mkstandalone -O x86_64-efi -o grub2_shell.img "boot/grub/grub.cfg=grub2-shell.cfg"

mv grub2_efi_autofind.img $working_directory/build/ipxe/bin/x86_64/
mv grub2_shell.img $working_directory/build/ipxe/bin/x86_64/

cd src
sed -i 's/#undef\	DOWNLOAD_PROTO_HTTPS/#define\	DOWNLOAD_PROTO_HTTPS/g' config/general.h
sed -i 's/\/\/#define\	CONSOLE_FRAMEBUFFER/#define\  CONSOLE_FRAMEBUFFER/g' config/console.h
make -j $nb_cores bin-x86_64-efi/ipxe.efi EMBED=bluebanquise_standard.ipxe DEBUG=intel,dhcp,vesafb
make -j $nb_cores bin/undionly.kpxe EMBED=bluebanquise_standard.ipxe DEBUG=intel,dhcp,vesafb
make -j $nb_cores bin-x86_64-efi/snponly.efi EMBED=bluebanquise_standard.ipxe DEBUG=intel,dhcp,vesafb
make -j $nb_cores bin-x86_64-efi/snp.efi EMBED=bluebanquise_standard.ipxe DEBUG=intel,dhcp,vesafb
make -j $nb_cores bin/ipxe.iso EMBED=bluebanquise_standard.ipxe DEBUG=intel,dhcp,vesafb
make -j $nb_cores bin/ipxe.usb EMBED=bluebanquise_standard.ipxe DEBUG=intel,dhcp,vesafb

rm -Rf /dev/shm/efiiso/efi/boot
mkdir -p /dev/shm/efiiso/efi/boot
cp bin-x86_64-efi/ipxe.efi /dev/shm/efiiso/efi/boot/bootx64.efi
mkisofs -o standard_efi.iso -J -r /dev/shm/efiiso
cp standard_efi.iso $working_directory/build/ipxe/bin/x86_64/standard_efi.iso

mv bin-x86_64-efi/ipxe.efi $working_directory/build/ipxe/bin/x86_64/standard_ipxe.efi
mv bin-x86_64-efi/snponly.efi $working_directory/build/ipxe/bin/x86_64/standard_snponly_ipxe.efi
mv bin-x86_64-efi/snp.efi $working_directory/build/ipxe/bin/x86_64/standard_snp_ipxe.efi
mv bin/undionly.kpxe $working_directory/build/ipxe/bin/x86_64/standard_undionly.kpxe
mv bin/ipxe.iso $working_directory/build/ipxe/bin/x86_64/standard_pcbios.iso
mv bin/ipxe.usb $working_directory/build/ipxe/bin/x86_64/standard_pcbios.usb

# Doing dhcpretry
make -j $nb_cores bin-x86_64-efi/ipxe.efi EMBED=bluebanquise_dhcpretry.ipxe DEBUG=intel,dhcp,vesafb
make -j $nb_cores bin/undionly.kpxe EMBED=bluebanquise_dhcpretry.ipxe DEBUG=intel,dhcp,vesafb
make -j $nb_cores bin-x86_64-efi/snponly.efi EMBED=bluebanquise_dhcpretry.ipxe DEBUG=intel,dhcp,vesafb
make -j $nb_cores bin-x86_64-efi/snp.efi EMBED=bluebanquise_dhcpretry.ipxe DEBUG=intel,dhcp,vesafb
make -j $nb_cores bin/ipxe.iso EMBED=bluebanquise_dhcpretry.ipxe DEBUG=intel,dhcp,vesafb
make -j $nb_cores bin/ipxe.usb EMBED=bluebanquise_dhcpretry.ipxe DEBUG=intel,dhcp,vesafb

rm -Rf /dev/shm/efiiso/efi/boot
mkdir -p /dev/shm/efiiso/efi/boot
cp bin-x86_64-efi/ipxe.efi /dev/shm/efiiso/efi/boot/bootx64.efi
mkisofs -o dhcpretry_efi.iso -J -r /dev/shm/efiiso
cp dhcpretry_efi.iso $working_directory/build/ipxe/bin/x86_64/dhcpretry_efi.iso

mv bin-x86_64-efi/ipxe.efi $working_directory/build/ipxe/bin/x86_64/dhcpretry_ipxe.efi
mv bin-x86_64-efi/snponly.efi $working_directory/build/ipxe/bin/x86_64/dhcpretry_snponly_ipxe.efi
mv bin-x86_64-efi/snp.efi $working_directory/build/ipxe/bin/x86_64/dhcpretry_snp_ipxe.efi
mv bin/undionly.kpxe $working_directory/build/ipxe/bin/x86_64/dhcpretry_undionly.kpxe
mv bin/ipxe.iso $working_directory/build/ipxe/bin/x86_64/dhcpretry_pcbios.iso
mv bin/ipxe.usb $working_directory/build/ipxe/bin/x86_64/dhcpretry_pcbios.usb

cd $working_directory/build/ipxe/
mkdir ipxe-x86_64-bluebanquise-$ipxe_bluebanquise_version
cp $working_directory/sources/bluebanquise/packages/ipxe-bluebanquise/ipxe-x86_64-bluebanquise.spec ipxe-x86_64-bluebanquise-$ipxe_bluebanquise_version
sed -i "s|Version:\ \ XXX|Version:\ \ $ipxe_bluebanquise_version|g" ipxe-x86_64-bluebanquise-$ipxe_bluebanquise_version/ipxe-x86_64-bluebanquise.spec
sed -i "s|working_directory=XXX|working_directory=$working_directory|g" ipxe-x86_64-bluebanquise-$ipxe_bluebanquise_version/ipxe-x86_64-bluebanquise.spec
tar cvzf ipxe-x86_64-bluebanquise.tar.gz ipxe-x86_64-bluebanquise-$ipxe_bluebanquise_version
rpmbuild -ta ipxe-x86_64-bluebanquise.tar.gz --target=noarch

fi

if [ $distribution_architecture == 'aarch64' ]; then

mkdir $working_directory/build/ipxe/bin/arm64/ -p

grub2-mkstandalone -O arm64-efi -o grub2_efi_autofind.img "boot/grub/grub.cfg=grub2-efi-autofind.cfg"
grub2-mkstandalone -O arm64-efi -o grub2_shell.img "boot/grub/grub.cfg=grub2-shell.cfg"

mv grub2_efi_autofind.img $working_directory/build/ipxe/bin/arm64/
mv grub2_shell.img $working_directory/build/ipxe/bin/arm64/

cd src
sed -i 's/#undef\       DOWNLOAD_PROTO_HTTPS/#define\   DOWNLOAD_PROTO_HTTPS/g' config/general.h
sed -i 's/\/\/#define\  CONSOLE_FRAMEBUFFER/#define\  CONSOLE_FRAMEBUFFER/g' config/console.h
make -j $nb_cores bin-arm64-efi/ipxe.efi EMBED=bluebanquise_standard.ipxe DEBUG=intel,dhcp
make -j $nb_cores bin-arm64-efi/snponly.efi EMBED=bluebanquise_standard.ipxe DEBUG=intel,dhcp
make -j $nb_cores bin-arm64-efi/snp.efi EMBED=bluebanquise_standard.ipxe DEBUG=intel,dhcp

rm -Rf /root/dev/shm/efiiso/efi/boot
mkdir -p /root/dev/shm/efiiso/efi/boot
cp bin-arm64-efi/ipxe.efi /root/dev/shm/efiiso/efi/boot/bootx64.efi
mkisofs -o standard_efi.iso -J -r /root/dev/shm/efiiso
cp standard_efi.iso $working_directory/build/ipxe/bin/arm64/standard_efi.iso


mv bin-arm64-efi/ipxe.efi $working_directory/build/ipxe/bin/arm64/standard_ipxe.efi
mv bin-arm64-efi/snponly.efi $working_directory/build/ipxe/bin/arm64/standard_snponly_ipxe.efi
mv bin-arm64-efi/snp.efi $working_directory/build/ipxe/bin/arm64/standard_snp_ipxe.efi

# Doing dhcpretry
make -j $nb_cores bin-arm64-efi/ipxe.efi EMBED=bluebanquise_dhcpretry.ipxe DEBUG=intel,dhcp
make -j $nb_cores bin-arm64-efi/snponly.efi EMBED=bluebanquise_dhcpretry.ipxe DEBUG=intel,dhcp
make -j $nb_cores bin-arm64-efi/snp.efi EMBED=bluebanquise_dhcpretry.ipxe DEBUG=intel,dhcp

rm -Rf /root/dev/shm/efiiso/efi/boot
mkdir -p /root/dev/shm/efiiso/efi/boot
cp bin-arm64-efi/ipxe.efi /root/dev/shm/efiiso/efi/boot/bootx64.efi
mkisofs -o dhcpretry_efi.iso -J -r /root/dev/shm/efiiso
cp dhcpretry_efi.iso $working_directory/build/ipxe/bin/arm64/dhcpretry_efi.iso


mv bin-arm64-efi/ipxe.efi $working_directory/build/ipxe/bin/arm64/dhcpretry_ipxe.efi
mv bin-arm64-efi/snponly.efi $working_directory/build/ipxe/bin/arm64/dhcpretry_snponly_ipxe.efi
mv bin-arm64-efi/snp.efi $working_directory/build/ipxe/bin/arm64/dhcpretry_snp_ipxe.efi


cd $working_directory/build/ipxe/
mkdir ipxe-arm64-bluebanquise-$ipxe_bluebanquise_version
cp $working_directory/sources/bluebanquise/packages/ipxe-bluebanquise/ipxe-arm64-bluebanquise.spec ipxe-arm64-bluebanquise-$ipxe_bluebanquise_version/
sed -i "s|Version:\ \ XXX|Version:\ \ $ipxe_bluebanquise_version|g" ipxe-arm64-bluebanquise-$ipxe_bluebanquise_version/ipxe-arm64-bluebanquise.spec
sed -i "s|working_directory=XXX|working_directory=$working_directory|g" ipxe-arm64-bluebanquise-$ipxe_bluebanquise_version/ipxe-arm64-bluebanquise.spec
tar cvzf ipxe-arm64-bluebanquise.tar.gz ipxe-arm64-bluebanquise-$ipxe_bluebanquise_version
rpmbuild -ta ipxe-arm64-bluebanquise.tar.gz --target=noarch

fi
