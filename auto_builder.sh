# Force script to stop if any error
set -e

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
echo "    (c) 2019-2020 Benoit Leveugle"
echo

### TO BE DONE: test if invocation is done in the script dir

echo " Detecting distribution..."
distribution=$(grep ^NAME /etc/os-release | awk -F '"' '{print $2}')
distribution_version=$(grep ^VERSION_ID /etc/os-release | awk -F '"' '{print $2}')
distribution_architecture=$(uname --m)
echo " Found $distribution $distribution_version $distribution_architecture"

echo " Creating working directory..."
root_directory=$(pwd)
working_directory=$(pwd)/wd/
echo " Working directory: $working_directory"
mkdir -p $working_directory

echo " Creating source directory..."
mkdir -p $working_directory/sources/

echo " Sourcing parameters."
source parameters.conf
echo " Sourcing versions."
source versions.conf

while [ true ]
do

echo
echo " Select operation:"
echo
echo " 0 - Install needed requirements to build packages"
echo " Build packages:"
echo "     1 - Nyancat"
echo "     2 - Prometheus and related tools"
echo "     3 - AnsibleCMDB"
echo "     4 - Slurm and Munge"
echo "     5 - Atftp"
echo "     6 - Powerman"
echo "     7 - Conman"
echo "     8 - iPXE roms"
echo " 9 - Exit."

read value
case $value in

    0) ######################################################################################
        echo " Installing needed packages... may take some time."
        if [ "$distribution" = 'openSUSE Leap' ]; then
          if [ "$distribution_version" = "15.1" ]; then
            zypper -n install gcc rpm-build make mkisofs xz xz-devel automake autoconf bzip2 openssl-devel zlib-devel readline-devel pam-devel perl-ExtUtils-MakeMaker grub2 grub2-x86_64-efi mariadb munge munge-devel freeipmi freeipmi-devel  mariadb mariadb-client libmariadb-devel libmariadb3
          fi
        else
          if [ $distribution_version -eq 8 ]; then
            if [ $distribution_architecture == 'x86_64' ]; then
              dnf install make rpm-build genisoimage xz xz-devel automake autoconf python36 bzip2-devel openssl-devel zlib-devel readline-devel pam-devel perl-ExtUtils-MakeMaker grub2-tools-extra grub2-efi-x64-modules gcc mariadb mariadb-devel dnf-plugins-core curl-devel net-snmp-devel -y
              dnf config-manager --set-enabled PowerTools
              dnf install freeipmi-devel -y
#              alternatives --set python /usr/bin/python3
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
    ;;

    1) ######################################################################################
        set -x
        if [ ! -f $working_directory/sources/nyancat-1.5.2.tar.gz ]; then
            wget -P $working_directory/sources/ https://github.com/klange/nyancat/archive/1.5.2.tar.gz
            mv $working_directory/sources/1.5.2.tar.gz $working_directory/sources/nyancat-1.5.2.tar.gz
        fi
        rm -Rf $working_directory/build/nyancat
        mkdir -p $working_directory/build/nyancat
        cd $working_directory/build/nyancat
        cp $working_directory/sources/nyancat-1.5.2.tar.gz .
        tar xvzf nyancat-1.5.2.tar.gz
        /usr/bin/cp -af $working_directory/sources/bluebanquise/packages/nyancat-1.5.2/* nyancat-1.5.2/
        tar cvzf nyancat.tar.gz nyancat-1.5.2
        rpmbuild -ta nyancat.tar.gz
        set +x
    ;;

    2) ######################################################################################
        set -x
        if [ ! -f $working_directory/sources/prometheus_client-$prometheus_client_version.tar.gz ]; then
            wget -P $working_directory/sources/ https://github.com/prometheus/client_python/archive/v$prometheus_client_version.tar.gz
            mv $working_directory/sources/v$prometheus_client_version.tar.gz $working_directory/sources/prometheus_client-$prometheus_client_version.tar.gz
        fi
        rm -Rf $working_directory/build/prometheus
        mkdir -p $working_directory/build/prometheus
        cd $working_directory/build/prometheus
        cp $working_directory/sources/prometheus_client-$prometheus_client_version.tar.gz .
        tar xvzf prometheus_client-$prometheus_client_version.tar.gz
        cd client_python-$prometheus_client_version
        python setup.py bdist_rpm --spec-only
        cd ..
        mv client_python-$prometheus_client_version prometheus_client-$prometheus_client_version
        tar cvzf prometheus_client-$prometheus_client_version.tar.gz prometheus_client-$prometheus_client_version
        rpmbuild -ta prometheus_client-$prometheus_client_version.tar.gz

        if [ $distribution_architecture == 'x86_64' ]; then

            cp -a $root_directory/packages/prometheus $working_directory/build/prometheus/prometheus
            mv prometheus prometheus-$prometheus_version
            tar cvzf prometheus-$prometheus_version.linux-amd64.tar.gz prometheus-$prometheus_version
            rpmbuild -ta prometheus-$prometheus_version.linux-amd64.tar.gz --define "_software_version $prometheus_version"

            cp -a $root_directory/packages/alertmanager $working_directory/build/prometheus/alertmanager
            mv alertmanager alertmanager-$alertmanager_version
            tar cvzf alertmanager-$alertmanager_version.linux-amd64.tar.gz alertmanager-$alertmanager_version
            rpmbuild -ta alertmanager-$alertmanager_version.linux-amd64.tar.gz --define "_software_version $alertmanager_version"

            cp -a $root_directory/packages/node_exporter $working_directory/build/prometheus/node_exporter
            mv node_exporter node_exporter-$node_exporter_version
            tar cvzf node_exporter-$node_exporter_version.linux-amd64.tar.gz node_exporter-$node_exporter_version
            rpmbuild -ta node_exporter-$node_exporter_version.linux-amd64.tar.gz --define "_software_version $node_exporter_version"

            cp -a $root_directory/packages/ipmi_exporter $working_directory/build/prometheus/ipmi_exporter
            mv ipmi_exporter ipmi_exporter-$ipmi_exporter_version
            tar cvzf ipmi_exporter-$ipmi_exporter_version.linux-amd64.tar.gz ipmi_exporter-$ipmi_exporter_version
            rpmbuild -ta ipmi_exporter-$ipmi_exporter_version.linux-amd64.tar.gz --define "_software_version $ipmi_exporter_version"

            cp -a $root_directory/packages/snmp_exporter $working_directory/build/prometheus/snmp_exporter
            mv snmp_exporter snmp_exporter-$snmp_exporter_version
            tar cvzf snmp_exporter-$snmp_exporter_version.linux-amd64.tar.gz snmp_exporter-$snmp_exporter_version
            rpmbuild -ta snmp_exporter-$snmp_exporter_version.linux-amd64.tar.gz --define "_software_version $snmp_exporter_version"

            cp -a $root_directory/packages/karma $working_directory/build/prometheus/karma
            mv karma karma-$karma_version
            tar cvzf karma-linux-amd64.tar.gz karma-$karma_version
            rpmbuild -ta karma-linux-amd64.tar.gz --define "_software_version $karma_version"

        fi
        set +x
    ;;

    3) ######################################################################################
        set -x
        if [ ! -f $working_directory/sources/ansible-cmdb-$ansible_cmdb_version.tar.gz ]; then
            wget -P $working_directory/sources/ https://github.com/fboender/ansible-cmdb/releases/download/$ansible_cmdb_version/ansible-cmdb-$ansible_cmdb_version.tar.gz
        fi
        rm -Rf $working_directory/build/ansible-cmdb
        mkdir $working_directory/build/ansible-cmdb
        cd $working_directory/build/ansible-cmdb
        cp $working_directory/sources/ansible-cmdb-$ansible_cmdb_version.tar.gz $working_directory/build/ansible-cmdb/
        tar xvzf ansible-cmdb-$ansible_cmdb_version.tar.gz
        /usr/bin/cp -af $root_directory/packages/ansible-cmdb/* ansible-cmdb-$ansible_cmdb_version/
        tar cvzf ansible-cmdb-$ansible_cmdb_version.tar.gz ansible-cmdb-$ansible_cmdb_version
        rpmbuild -ta ansible-cmdb-$ansible_cmdb_version.tar.gz --define "_software_version $ansible_cmdb_version"
        set +x
    ;;

    4) ######################################################################################
        set -x

        if [ ! -f $working_directory/sources/slurm-$slurm_version.tar.bz2 ]; then
          wget -P $working_directory/sources/ https://download.schedmd.com/slurm/slurm-$slurm_version.tar.bz2
        fi
        #wget https://github.com/SchedMD/slurm/archive/slurm-18-08-8-1.tar.gz
        if [ ! -f $working_directory/sources/munge-$munge_version.tar.xz ]; then
          wget -P $working_directory/sources/ https://github.com/dun/munge/releases/download/munge-$munge_version/munge-$munge_version.tar.xz
        fi

        mkdir $working_directory/build/munge
        cd $working_directory/build/munge
        cp $working_directory/sources/munge-$munge_version.tar.xz $working_directory/build/munge/
        rpmbuild -ta munge-$munge_version.tar.xz

        # We need to install munge to build slurm
        if [ $distribution_version -eq 8 ]; then
          dnf install /root/rpmbuild/RPMS/x86_64/munge* -y
        fi
        if [ $distribution_version -eq 7 ]; then
          yum install /root/rpmbuild/RPMS/x86_64/munge* -y
        fi

        mkdir $working_directory/build/slurm
        cd $working_directory/build/slurm
        cp  $working_directory/sources/slurm-$slurm_version.tar.bz2 $working_directory/build/slurm
        tar xjvf slurm-$slurm_version.tar.bz2
        sed -i '1s/^/%global _hardened_ldflags\ "-Wl,-z,lazy"\n/' slurm-$slurm_version/slurm.spec
        sed -i '1s/^/%global _hardened_cflags\ "-Wl,-z,lazy"\n/' slurm-$slurm_version/slurm.spec
        sed -i '1s/^/%undefine\ _hardened_build\n/' slurm-$slurm_version/slurm.spec
        sed -i 's/BuildRequires:\ python/#BuildRequires:\ python/g' slurm-$slurm_version/slurm.spec
        tar cjvf slurm-$slurm_version.tar.bz2 slurm-$slurm_version

        rpmbuild -ta slurm-$slurm_version.tar.bz2

        set +x
    ;;

    5) ######################################################################################
        set -x

        if [ $distribution_version -eq 7 ]; then
            ln -s /usr/bin/aclocal /usr/bin/aclocal-1.16
            ln -s /usr/bin/autoconf /usr/bin/autoconf-1.16
            ln -s /usr/bin/automake /usr/bin/automake-1.16
        fi
        rm -Rf $working_directory/build/atftp
        mkdir -p $working_directory/build/atftp/

        if [ ! -f $working_directory/sources/atftp-0.7.2.tar.gz ]; then
            wget -P $working_directory/sources/ https://freefr.dl.sourceforge.net/project/atftp/atftp-0.7.2.tar.gz
        fi

        cd $working_directory/build/atftp/
        cp $working_directory/sources/atftp-0.7.2.tar.gz $working_directory/build/atftp/
        tar xvzf atftp-0.7.2.tar.gz
        /usr/bin/cp -f $root_directory/packages/atftp/* atftp-0.7.2/
        rm -f atftp-0.7.2/redhat/atftp.spec
        tar cvzf atftp.tar.gz atftp-0.7.2
        rpmbuild -ta atftp.tar.gz

        set +x
    ;;

    6) ######################################################################################

        set -x
        
        if [ ! -f $working_directory/sources/powerman-2.3.26.tar.gz ]; then
          wget -P $working_directory/sources/ https://github.com/chaos/powerman/releases/download/2.3.26/powerman-2.3.26.tar.gz
        fi
        rm -Rf $working_directory/build/powerman
        mkdir -p $working_directory/build/powerman
        cd $working_directory/build/powerman
        cp $working_directory/sources/powerman-2.3.26.tar.gz $working_directory/build/powerman
        tar xvzf powerman-2.3.26.tar.gz
        /usr/bin/cp -f $root_directory/packages/powerman/* powerman-2.3.26/
        rm -f powerman-2.3.26/examples/powerman_el72.spec
        tar cvzf powerman-2.3.26.tar.gz powerman-2.3.26
        rpmbuild -ta powerman-2.3.26.tar.gz

        set +x
    ;;
         
    7) ######################################################################################

       set -x

        if [ ! -f $working_directory/sources/conman-0.3.0.tar.xz ]; then
          wget -P $working_directory/sources/ https://github.com/dun/conman/releases/download/conman-0.3.0/conman-0.3.0.tar.xz
        fi
        rm -Rf $working_directory/build/conman
        mkdir -p $working_directory/build/conman
        cd $working_directory/build/conman
        cp $working_directory/sources/conman-0.3.0.tar.xz $working_directory/build/conman
        tar xJvf conman-0.3.0.tar.xz
        /usr/bin/cp -f $root_directory/packages/conman/* conman-0.3.0/
        tar cvJf conman-0.3.0.tar.xz conman-0.3.0
        rpmbuild -ta conman-0.3.0.tar.xz

        set +x
    ;;

    8) ######################################################################################

       set -x

        # iPXE
        if [ ! -f $working_directory/sources/ipxe/README ]; then
          mkdir -p $working_directory/sources/ipxe/
          cd $working_directory/sources/ipxe/
          git clone https://github.com/ipxe/ipxe.git .
        fi

        # No git pull by default, could not be what is expected
        # git pull

        rm -Rf $working_directory/build/ipxe/
        mkdir $working_directory/build/ipxe/
        cd $working_directory/build/ipxe/
        cp -a $working_directory/sources/ipxe/* $working_directory/build/ipxe/

        cp $root_directory/packages/ipxe-bluebanquise/grub2-efi-autofind.cfg .
        cp $root_directory/packages/ipxe-bluebanquise/grub2-shell.cfg .

        # Customizing
        # Building embed ipxe files
        echo "#!ipxe" > src/bluebanquise_standard.ipxe
        cat $root_directory/packages/ipxe-bluebanquise/$ipxe_bluebanquise_logo.ipxe >> src/bluebanquise_standard.ipxe
        cat $root_directory/packages/ipxe-bluebanquise/bluebanquise_standard.ipxe >> src/bluebanquise_standard.ipxe

        echo "#!ipxe" > src/bluebanquise_dhcpretry.ipxe
        cat $root_directory/packages/ipxe-bluebanquise/$ipxe_bluebanquise_logo.ipxe >> src/bluebanquise_dhcpretry.ipxe
        cat $root_directory/packages/ipxe-bluebanquise/bluebanquise_dhcpretry.ipxe >> src/bluebanquise_dhcpretry.ipxe

        if [ $distribution_architecture == 'x86_64' ]; then

        mkdir $working_directory/build/ipxe/bin/x86_64/ -p

        grub2-mkstandalone -O x86_64-efi -o grub2_efi_autofind.img "boot/grub/grub.cfg=grub2-efi-autofind.cfg"
        grub2-mkstandalone -O x86_64-efi -o grub2_shell.img "boot/grub/grub.cfg=grub2-shell.cfg"

        mv grub2_efi_autofind.img $working_directory/build/ipxe/bin/x86_64/
        mv grub2_shell.img $working_directory/build/ipxe/bin/x86_64/

        cd src

        # Not sure it worh enabling https without injecting certificates...
        sed -i 's/#undef\       DOWNLOAD_PROTO_HTTPS/#define\   DOWNLOAD_PROTO_HTTPS/g' config/general.h

        sed -i 's/\/\/#define\  CONSOLE_FRAMEBUFFER/#define\  CONSOLE_FRAMEBUFFER/g' config/console.h

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
        cp $root_directory//packages/ipxe-bluebanquise/ipxe-x86_64-bluebanquise.spec ipxe-x86_64-bluebanquise-$ipxe_bluebanquise_version
        #sed -i "s|Version:\ \ XXX|Version:\ \ $ipxe_bluebanquise_version|g" ipxe-x86_64-bluebanquise-$ipxe_bluebanquise_version/ipxe-x86_64-bluebanquise.spec
        sed -i "s|working_directory=XXX|working_directory=$working_directory|g" ipxe-x86_64-bluebanquise-$ipxe_bluebanquise_version/ipxe-x86_64-bluebanquise.spec
        tar cvzf ipxe-x86_64-bluebanquise.tar.gz ipxe-x86_64-bluebanquise-$ipxe_bluebanquise_version
        rpmbuild -ta ipxe-x86_64-bluebanquise.tar.gz --target=noarch --define "_software_version $ipxe_bluebanquise_version" --define "_software_release 1$ipxe_bluebanquise_release"

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
        #sed -i "s|Version:\ \ XXX|Version:\ \ $ipxe_bluebanquise_version|g" ipxe-arm64-bluebanquise-$ipxe_bluebanquise_version/ipxe-arm64-bluebanquise.spec
        sed -i "s|working_directory=XXX|working_directory=$working_directory|g" ipxe-arm64-bluebanquise-$ipxe_bluebanquise_version/ipxe-arm64-bluebanquise.spec
        tar cvzf ipxe-arm64-bluebanquise.tar.gz ipxe-arm64-bluebanquise-$ipxe_bluebanquise_version
        rpmbuild -ta ipxe-arm64-bluebanquise.tar.gz --target=noarch

        fi


       set +x
    ;;

    9) ######################################################################################
        echo "  Exiting."
        exit
    ;;

esac

done

exit

