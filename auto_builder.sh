#!/bin/bash
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
if [ -z $2 ]
then
   distribution=$(grep ^NAME /etc/os-release | awk -F '"' '{print $2}')
else
   distribution=$2
fi
if [ -z $3 ]
then
   distribution_version=$(grep ^VERSION_ID /etc/os-release | awk -F '"' '{print $2}')
else
   distribution_version=$3
fi

distribution_architecture=$(uname --m)
echo " Settings set to $distribution $distribution_version $distribution_architecture"



echo " Creating working directory..."
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
root_directory=$SCRIPT_DIR
working_directory=$(pwd)/wd/
echo " Working directory: $working_directory"
mkdir -p $working_directory

echo " Creating source directory..."
mkdir -p $working_directory/sources/

echo " Sourcing parameters."
source $root_directory/parameters.conf
echo " Sourcing versions."
source $root_directory/versions.conf


if [ -z $1 ]
then
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
  echo "     14 - MLL"

  read value

else
  value=$1
fi

case $value in

    0) ######################################################################################
        echo " Installing needed packages... may take some time."
        if [ "$distribution" == 'openSUSE Leap' ]; then
          if [ "$distribution_version" == "15.1" ]; then
            zypper -n install gcc rpm-build make mkisofs xz xz-devel automake autoconf bzip2 openssl-devel zlib-devel readline-devel pam-devel perl-ExtUtils-MakeMaker grub2 grub2-x86_64-efi mariadb munge munge-devel freeipmi freeipmi-devel  mariadb mariadb-client libmariadb-devel libmariadb3
          fi
	elif [ "$distribution" == 'Ubuntu' ]; then
	    apt-get install -y liblzma-dev mkisofs rpm alien grub-efi-amd64 libpopt-dev libblkid-dev munge libmunge-dev libmunge2  libreadline-dev libextutils-makemaker-cpanfile-perl libpam0g-dev mariadb-common mariadb-server libmariadb-dev libmariadb-dev-compat zlib1g-dev  libssl-dev python3-setuptools
	    # Possibly missing python3-mysqldb libmysqld-dev
        elif [ "$distribution" == 'RedHat' ]; then
          if [ $distribution_version -eq 8 ]; then
            if [ $distribution_architecture == 'x86_64' ]; then
              dnf install 'dnf-command(config-manager)' -y
	      dnf install dnf-plugins-core -y
              dnf install make rpm-build genisoimage xz xz-devel automake autoconf python36 bzip2-devel openssl-devel zlib-devel readline-devel pam-devel perl-ExtUtils-MakeMaker grub2-tools-extra grub2-efi-x64-modules gcc mariadb mariadb-devel dnf-plugins-core curl-devel net-snmp-devel wget -y
              dnf config-manager --set-enabled powertools
              dnf install freeipmi-devel -y
	      dnf groupinstall 'Development Tools' -y
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
        source $root_directory/packages/nyancat/build.sh
    ;;

    2) ######################################################################################
        source $root_directory/packages/prometheus/build.sh
    ;;

    3) ######################################################################################
        source $root_directory/packages/ansible-cmdb/build.sh
    ;;

    4) ######################################################################################
        source $root_directory/packages/slurm/build.sh
    ;;

    5) ######################################################################################
        source $root_directory/packages/atftp/build.sh
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
        mkdir -p $working_directory/build/ipxe/
        cd $working_directory/build/ipxe/
        cp -a $working_directory/sources/ipxe/* $working_directory/build/ipxe/

        cp $root_directory/packages/ipxe-bluebanquise/grub2-efi-autofind.cfg .
        cp $root_directory/packages/ipxe-bluebanquise/grub2-shell.cfg .

        # Customizing
        # Building embed ipxe files
	last_commit=$(cd wd/sources/ipxe; git log | grep commit | sed -n 1p | awk -F ' ' '{print $2}'; cd ../../../;)
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
            rpmbuild -ta ipxe-$ipxe_arch-bluebanquise.tar.gz --target=noarch --define "_software_version $ipxe_bluebanquise_version" --define "_software_release 1$ipxe_bluebanquise_release" --define "dist .ubuntu18"
	  elif [ "$distribution_version" == "20.04" ]; then
	    rpmbuild -ta ipxe-$ipxe_arch-bluebanquise.tar.gz --target=noarch --define "_software_version $ipxe_bluebanquise_version" --define "_software_release 1$ipxe_bluebanquise_release" --define "dist .ubuntu20"
	  fi
	else
          rpmbuild -ta ipxe-$ipxe_arch-bluebanquise.tar.gz --target=noarch --define "_software_version $ipxe_bluebanquise_version" --define "_software_release 1$ipxe_bluebanquise_release"
	fi
        if [ "$distribution" == "Ubuntu" ]; then
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

    14) #####################################################################################
        set -x
        rm -Rf $working_directory/build/MLL
        mkdir -p $working_directory/build/MLL
        cd $working_directory/build/MLL
        git clone https://github.com/ivandavidov/minimal.git .
        cd src
        sed -i 's/^OVERLAY_BUNDLES.*$/OVERLAY_BUNDLES=dhcp,dropbear,coreutils,static_get,util_linux/' .config
	sed -i 's/^NCURSES_SOURCE_URL.*$/NCURSES_SOURCE_URL=https:\/\/ftp.gnu.org\/pub\/gnu\/ncurses\/ncurses-5.9.tar.gz/' minimal_overlay/bundles/ncurses/.config
	sed -i 's/^cd\ \$DEST_DIR\/usr\/lib/cd\ \$DEST_DIR\/usr\/lib64/' minimal_overlay/bundles/ncurses/02_build.sh
        export FORCE_UNSAFE_CONFIGURE=1
        ./build_minimal_linux_live.sh
	kernelversion=$(ls -l source/ | grep -i '\ linux-' | awk -F 'linux-' '{print $2}' | awk -F '.tar.xz' '{print $1}')
        mount $working_directory/build/MLL/src/minimal_linux_live.iso /mnt
        cd $working_directory/build/MLL/
        mkdir mll-$kernelversion
        cp /mnt/boot/*.xz mll-$kernelversion/
        cp -a $root_directory/packages/mll mll-$kernelversion/
        tar cvzf mll-$kernelversion.tar.gz mll-$kernelversion
        rpmbuild -ta mll-$kernelversion.tar.gz --define "_software_version $kernelversion" --define "_architecture $(uname -m)"
	set +x
    ;;

    15) #####################################################################################
        source $root_directory/packages/ssh-wait/build.sh
    ;;

    16) #####################################################################################
        source $root_directory/packages/colour_text/build.sh
    ;;

esac

exit

