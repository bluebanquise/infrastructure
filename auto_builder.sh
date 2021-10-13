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
echo "    (c) 2019-2021 Benoit Leveugle"
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
        set -x
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
        set +x
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
        source $root_directory/packages/ipxe-bluebanquise/build.sh
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
        if [ -z $4 ]
        then
          echo "Error, please add a tag"
        else
          bb_tag=$4
        fi
        source $root_directory/packages/bluebanquise/build.sh
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
        source $root_directory/packages/mll/build.sh
    ;;

    15) #####################################################################################
        source $root_directory/packages/ssh-wait/build.sh
    ;;

    16) #####################################################################################
        source $root_directory/packages/colour_text/build.sh
    ;;

esac

exit

