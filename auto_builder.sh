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
echo "     9 - fbtftp"
echo "     10 - bluebanquise"
echo "     11 - Documentation"
echo "     12 - grubby"
echo "     13 - ara"
echo " Q - Quit."

read value
case $value in

    0) ######################################################################################
        echo " Installing needed packages... may take some time."
        if [ "$distribution" = 'openSUSE Leap' ]; then
          if [ "$distribution_version" = "15.1" ]; then
            zypper -n install gcc rpm-build make mkisofs xz xz-devel automake autoconf bzip2 openssl-devel zlib-devel readline-devel pam-devel perl-ExtUtils-MakeMaker grub2 grub2-x86_64-efi mariadb munge munge-devel freeipmi freeipmi-devel  mariadb mariadb-client libmariadb-devel libmariadb3
          fi
	elif [ "$distribution" = 'Ubuntu' ]; then
	    apt-get install -y liblzma-dev mkisofs rpm alien grub-efi-amd64 libpopt-dev libblkid-dev munge libmunge-dev libmunge2  libreadline-dev libextutils-makemaker-cpanfile-perl libpam0g-dev mariadb-common mariadb-server libmariadb-dev libmariadb-dev-compat zlib1g-dev  libssl-dev python3-setuptools
	    # Possibly missing python3-mysqldb libmysqld-dev
        else
          if [ $distribution_version -eq 8 ]; then
            if [ $distribution_architecture == 'x86_64' ]; then
              dnf install 'dnf-command(config-manager)'
              dnf install make rpm-build genisoimage xz xz-devel automake autoconf python36 bzip2-devel openssl-devel zlib-devel readline-devel pam-devel perl-ExtUtils-MakeMaker grub2-tools-extra grub2-efi-x64-modules gcc mariadb mariadb-devel dnf-plugins-core curl-devel net-snmp-devel -y
              dnf config-manager --set-enabled PowerTools
              dnf install freeipmi-devel -y
#              alternatives --set python /usr/bin/python3
            fi
            if [ $distribution_architecture == 'aarch64' ]; then
              dnf install 'dnf-command(config-manager)'
              dnf install make rpm-build genisoimage xz xz-devel automake autoconf python36 bzip2-devel openssl-devel zlib-devel readline-devel pam-devel perl-ExtUtils-MakeMaker grub2-tools-extra grub2-efi-aa64-modules gcc mariadb mariadb-devel curl-devel net-snmp-devel dnf-plugins-core -y
              dnf config-manager --set-enabled powertools
              dnf install freeipmi-devel -y
#              alternatives --set python /usr/bin/python3
            fi
          fi
          if [ $distribution_version -eq 7 ]; then
            if [ $distribution_architecture == 'x86_64' ]; then
              yum install make rpm-build genisoimage xz xz-devel automake autoconf python36 bzip2-devel openssl-devel zlib-devel readline-devel pam-devel perl-ExtUtils-MakeMaker grub2-tools-extra grub2-efi-x64-modules gcc mariadb mariadb-devel wget git gcc-c++ python-setuptools python3-setuptools net-snmp-devel curl-devel freeipmi-devel -y
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
        $(which cp) -af $root_directory/packages/nyancat-1.5.2/* nyancat-1.5.2/
        tar cvzf nyancat.tar.gz nyancat-1.5.2
        rpmbuild -ta nyancat.tar.gz
        set +x
    ;;

    2) ######################################################################################
        set -x

        if [ $distribution_version -eq 8 ]; then
          if [ ! -f $working_directory/sources/prometheus_client-$prometheus_client_version.tar.gz ]; then
            wget -P $working_directory/sources/ https://github.com/prometheus/client_python/archive/v$prometheus_client_version.tar.gz
            mv $working_directory/sources/v$prometheus_client_version.tar.gz $working_directory/sources/prometheus_client-$prometheus_client_version.tar.gz
          fi
        fi
        rm -Rf $working_directory/build/prometheus
        mkdir -p $working_directory/build/prometheus
        cd $working_directory/build/prometheus

        if [ $distribution_version -eq 8 ]; then
          cp $working_directory/sources/prometheus_client-$prometheus_client_version.tar.gz .
          tar xvzf prometheus_client-$prometheus_client_version.tar.gz
          cd client_python-$prometheus_client_version
          python setup.py bdist_rpm --spec-only
          cd ..
          mv client_python-$prometheus_client_version prometheus_client-$prometheus_client_version
          tar cvzf prometheus_client-$prometheus_client_version.tar.gz prometheus_client-$prometheus_client_version
          rpmbuild -ta prometheus_client-$prometheus_client_version.tar.gz
        fi

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
            tar cvzf ipmi_exporter-v$ipmi_exporter_version.linux-amd64.tar.gz ipmi_exporter-$ipmi_exporter_version
            rpmbuild -ta ipmi_exporter-v$ipmi_exporter_version.linux-amd64.tar.gz --define "_software_version $ipmi_exporter_version"

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
        $(which cp) -af $root_directory/packages/ansible-cmdb/* ansible-cmdb-$ansible_cmdb_version/
        tar cvzf ansible-cmdb-$ansible_cmdb_version.tar.gz ansible-cmdb-$ansible_cmdb_version
        rpmbuild -ta ansible-cmdb-$ansible_cmdb_version.tar.gz --define "_software_version $ansible_cmdb_version"
        set +x
    ;;

    4) ######################################################################################
        set -x

        if [ ! -f $working_directory/sources/slurm-$slurm_version.tar.bz2 ]; then
          wget -P $working_directory/sources/ https://download.schedmd.com/slurm/slurm-$slurm_version.tar.bz2
        fi

        if [ ! -f $working_directory/sources/munge-$munge_version.tar.xz ]; then
          wget -P $working_directory/sources/ https://github.com/dun/munge/releases/download/munge-$munge_version/munge-$munge_version.tar.xz
        fi

	if [ $distribution != "Ubuntu" ]; then
          rm -Rf $working_directory/build/munge
          mkdir -p $working_directory/build/munge
          cd $working_directory/build/munge
          cp $working_directory/sources/munge-$munge_version.tar.xz $working_directory/build/munge/
          wget https://github.com/dun.gpg -O $working_directory/build/munge/dun.gpg
          wget https://github.com/dun/munge/releases/download/munge-$munge_version/munge-$munge_version.tar.xz.asc -O $working_directory/build/munge/munge-$munge_version.tar.xz.asc
          rpmbuild -ta munge-$munge_version.tar.xz

          # We need to install munge to build slurm
          if [ $distribution_version -eq 8 ]; then
            dnf install /root/rpmbuild/RPMS/$distribution_architecture/munge* -y
          fi
          if [ $distribution_version -eq 7 ]; then
            yum install /root/rpmbuild/RPMS/$distribution_architecture/munge* -y
          fi
	fi

        rm -Rf $working_directory/build/slurm
        mkdir -p $working_directory/build/slurm
        cd $working_directory/build/slurm
        cp  $working_directory/sources/slurm-$slurm_version.tar.bz2 $working_directory/build/slurm
#        tar xjvf slurm-$slurm_version.tar.bz2
#        sed -i '1s/^/%global _hardened_ldflags\ "-Wl,-z,lazy"\n/' slurm-$slurm_version/slurm.spec
#        sed -i '1s/^/%global _hardened_cflags\ "-Wl,-z,lazy"\n/' slurm-$slurm_version/slurm.spec
#        sed -i '1s/^/%undefine\ _hardened_build\n/' slurm-$slurm_version/slurm.spec
#        sed -i 's/BuildRequires:\ python/#BuildRequires:\ python/g' slurm-$slurm_version/slurm.spec
#        tar cjvf slurm-$slurm_version.tar.bz2 slurm-$slurm_version
        if [ $distribution == "Ubuntu" ]; then
          tar xjvf slurm-$slurm_version.tar.bz2
          sed -i 's|%{!?_unitdir|#%{!?_unitdir|' slurm-$slurm_version/slurm.spec
          sed -i 's|BuildRequires:\ systemd|#BuildRequires:\ systemd|' slurm-$slurm_version/slurm.spec
          sed -i 's|BuildRequires:\ munge-devel|#BuildRequires:\ munge-devel|' slurm-$slurm_version/slurm.spec
          sed -i 's|BuildRequires:\ python3|#BuildRequires:\ python3|' slurm-$slurm_version/slurm.spec
          sed -i 's|BuildRequires:\ readline-devel|#BuildRequires:\ readline-devel|' slurm-$slurm_version/slurm.spec
          sed -i 's|BuildRequires:\ perl(ExtUtils::MakeMaker)|#BuildRequires:\ perl(ExtUtils::MakeMaker)|' slurm-$slurm_version/slurm.spec
          sed -i 's|BuildRequires:\ pam-devel|#BuildRequires:\ pam-devel|' slurm-$slurm_version/slurm.spec
	  tar cjvf slurm-$slurm_version.tar.bz2 slurm-$slurm_version
	fi

        rpmbuild -ta slurm-$slurm_version.tar.bz2

        if [ $distribution == "Ubuntu" ]; then
           cd /dev/shm
           alien --to-deb /root/rpmbuild/RPMS/x86_64/slurm*
           mkdir -p /root/debbuild/DEBS/x86_64/
           mv *.deb /root/debbuild/DEBS/x86_64/
        fi

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
           ipxe_arch=x86_64
           debug_flags=intel,dhcp,vesafb
        elif [ $distribution_architecture == 'aarch64' ]; then
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
        sed -i 's/#undef\       DOWNLOAD_PROTO_HTTPS/#define\   DOWNLOAD_PROTO_HTTPS/g' config/general.h
        sed -i 's/\/\/#define\  CONSOLE_FRAMEBUFFER/#define\  CONSOLE_FRAMEBUFFER/g' config/console.h

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

        # Doing dhcpretry
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

        cd $working_directory/build/ipxe/
        mkdir ipxe-$ipxe_arch-bluebanquise-$ipxe_bluebanquise_version
        cp $root_directory//packages/ipxe-bluebanquise/ipxe-$ipxe_arch-bluebanquise.spec ipxe-$ipxe_arch-bluebanquise-$ipxe_bluebanquise_version
        #sed -i "s|Version:\ \ XXX|Version:\ \ $ipxe_bluebanquise_version|g" ipxe-$ipxe_arch-bluebanquise-$ipxe_bluebanquise_version/ipxe-$ipxe_arch-bluebanquise.spec
        sed -i "s|working_directory=XXX|working_directory=$working_directory|g" ipxe-$ipxe_arch-bluebanquise-$ipxe_bluebanquise_version/ipxe-$ipxe_arch-bluebanquise.spec
        tar cvzf ipxe-$ipxe_arch-bluebanquise.tar.gz ipxe-$ipxe_arch-bluebanquise-$ipxe_bluebanquise_version
	if [ $distribution == "Ubuntu" ]; then
          if [ $distribution_version == "18.04" ]; then
            rpmbuild -ta ipxe-$ipxe_arch-bluebanquise.tar.gz --target=noarch --define "_software_version $ipxe_bluebanquise_version" --define "_software_release 1$ipxe_bluebanquise_release" --define "dist .ubuntu18"
	  elif [ $distribution_version == "20.04" ]; then
	    rpmbuild -ta ipxe-$ipxe_arch-bluebanquise.tar.gz --target=noarch --define "_software_version $ipxe_bluebanquise_version" --define "_software_release 1$ipxe_bluebanquise_release" --define "dist .ubuntu20"
	  fi
	else
          rpmbuild -ta ipxe-$ipxe_arch-bluebanquise.tar.gz --target=noarch --define "_software_version $ipxe_bluebanquise_version" --define "_software_release 1$ipxe_bluebanquise_release"
	fi
        if [ $distribution == "Ubuntu" ]; then
           cd /dev/shm
           alien --to-deb --scripts /root/rpmbuild/RPMS/noarch/ipxe*
           mkdir -p /root/debbuild/DEBS/noarch/
           mv *.deb /root/debbuild/DEBS/noarch/
        fi

       set +x
    ;;

    9) ######################################################################################
       set -x
       if [ ! -f $working_directory/sources/fbtftp-$fbtftp_version.tar.gz ]; then
           cd $working_directory/sources/
           rm -Rf fbtftp-$fbtftp_version
           mkdir fbtftp-$fbtftp_version
           cd fbtftp-$fbtftp_version
           git clone https://github.com/facebook/fbtftp.git .
           cd ../
           tar cvzf fbtftp-$fbtftp_version.tar.gz fbtftp-$fbtftp_version
       fi
       rm -Rf $working_directory/build/fbtftp
       mkdir -p $working_directory/build/fbtftp
       cd $working_directory/build/fbtftp
       cp $working_directory/sources/fbtftp-$fbtftp_version.tar.gz .
       tar xvzf fbtftp-$fbtftp_version.tar.gz
       cd fbtftp-$fbtftp_version
       python3 setup.py bdist_rpm --spec-only
       cd ..
       tar cvzf fbtftp-$fbtftp_version.tar.gz fbtftp-$fbtftp_version
       rpmbuild -ta fbtftp-$fbtftp_version.tar.gz

       cp -a $root_directory/packages/fbtftp_server fbtftp-server-$fbtftp_server_version
       tar cvzf fbtftp-server-$fbtftp_server_version.tar.gz fbtftp-server-$fbtftp_server_version
       rpmbuild -ta fbtftp-server-$fbtftp_server_version.tar.gz --define "_software_version $fbtftp_server_version" --target=noarch
      
       if [ $distribution == "Ubuntu" ]; then
	   cd /dev/shm
           alien --to-deb --scripts /root/rpmbuild/RPMS/noarch/fbtftp-*
	   mkdir -p /root/debbuild/DEBS/noarch/
	   mv *.deb /root/debbuild/DEBS/noarch/
       fi 
       set +x
    ;;

    10) ######################################################################################

        set -x

        rm -Rf $working_directory/build/bluebanquise
        mkdir -p $working_directory/build/bluebanquise
        echo "Tag to checkout will be asked."
        echo "Tag will be used as version for rpm."
        cd $working_directory/build/bluebanquise
        mkdir bluebanquise
        cd bluebanquise
        git clone https://github.com/bluebanquise/bluebanquise.git .
        git fetch --all --tags
        echo
        echo "Available tags:"
        git tag
        echo
        read -p "Please enter tag to be used: " bb_tag
        git checkout tags/$bb_tag -b build
        cd ../
        mv bluebanquise bluebanquise-$bb_tag
        tar cvzf bluebanquise-$bb_tag.tar.gz bluebanquise-$bb_tag
        rpmbuild -ta bluebanquise-$bb_tag.tar.gz --define "version $bb_tag"

        set +x
    ;;
        
    11) #####################################################################################
        set -x

        pip3 install sphinx sphinx_rtd_theme

        rm -Rf $working_directory/build/documentation
        mkdir -p $working_directory/build/documentation
        cd $working_directory/build/documentation
        git clone https://github.com/bluebanquise/bluebanquise.git .
        cd resources/documentation/
        make html
        tar cvJf documentation.tar.xz _build/html
        cp documentation.tar.xz $working_directory/../

        set +x
        ;;

    12) #####################################################################################

        set -x
        if [ ! -f $working_directory/sources/grubby-$grubby_version.tar.gz ]; then
            wget -P $working_directory/sources/ https://github.com/rhboot/grubby/archive/refs/tags/$grubby_version.tar.gz
            mv $working_directory/sources/$grubby_version.tar.gz $working_directory/sources/grubby-$grubby_version.tar.gz
        fi
        rm -Rf $working_directory/build/grubby
        mkdir -p $working_directory/build/grubby
        cd $working_directory/build/grubby
        cp $working_directory/sources/grubby-$grubby_version.tar.gz .
        tar xvzf grubby-$grubby_version.tar.gz
	cd grubby-$grubby_version
        make	
        $(which cp) -af $root_directory/packages/grubby/* .
	cd ../
        tar cvzf grubby-$grubby_version.tar.gz grubby-$grubby_version
        rpmbuild -ta grubby-$grubby_version.tar.gz --define "_software_version $grubby_version"
        if [ $distribution == "Ubuntu" ]; then
           cd /dev/shm
           alien --to-deb --scripts /root/rpmbuild/RPMS/x86_64/grubby-*
           mkdir -p /root/debbuild/DEBS/noarch/
           mv *.deb /root/debbuild/DEBS/noarch/
        fi
        set +x
    ;;

    13) #####################################################################################

        set -x
        if [ ! -f $working_directory/sources/ara-$ara_version.tar.gz ]; then
            wget -P $working_directory/sources/ https://files.pythonhosted.org/packages/$ara_link/ara-$ara_version.tar.gz
        fi
        rm -Rf $working_directory/build/ara
        mkdir -p $working_directory/build/ara
        cd $working_directory/build/ara
        cp $working_directory/sources/ara-$ara_version.tar.gz .
        tar xvzf ara-$ara_version.tar.gz
	cd ara-$ara_version
        python3 setup.py bdist_rpm --spec-only	
	cd ../
        tar cvzf ara-$ara_version.tar.gz ara-$ara_version
        rpmbuild -ta ara-$ara_version.tar.gz
        if [ $distribution == "Ubuntu" ]; then
           cd /dev/shm
           alien --to-deb --scripts /root/rpmbuild/RPMS/noarch/ara-*
           mkdir -p /root/debbuild/DEBS/noarch/
           mv *.deb /root/debbuild/DEBS/noarch/
        fi
        set +x
    ;;

    Q) ######################################################################################
        echo "  Exiting."
        exit
    ;;

esac

done

exit

