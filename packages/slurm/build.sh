set -x

CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $CURRENT_DIR/version.sh

###### MUNGE

# Munge only needs to be built on RHEL systems, it is provided by all distributions in native repos.

#if [ ! -f $tags_directory/munge-$distribution-$distribution_version-$munge_version ]; then
if [ ! -f $tags_directory/slurm-$distribution-$distribution_version-$slurm_version ]; then


    if [ ! -f $working_directory/sources/munge-$munge_version.tar.xz ]; then
        wget -P $working_directory/sources/ https://github.com/dun/munge/releases/download/munge-$munge_version/munge-$munge_version.tar.xz
    fi

    if [ ! -f $working_directory/sources/dun.gpg ]; then
        wget -P $working_directory/sources/ https://github.com/dun.gpg
    fi

    if [ ! -f $working_directory/sources/munge-$munge_version.tar.xz.asc ]; then
        wget -P $working_directory/sources/ https://github.com/dun/munge/releases/download/munge-$munge_version/munge-$munge_version.tar.xz.asc
    fi

    if [ $distribution != "Ubuntu" ] && [ $distribution != "opensuse_leap" ] && [ $distribution != "Debian" ]; then
        rm -Rf $working_directory/build/munge
        mkdir -p $working_directory/build/munge
        cd $working_directory/build/munge
        cp $working_directory/sources/munge-$munge_version.tar.xz $working_directory/build/munge/
        cp $working_directory/sources/dun.gpg $working_directory/build/munge/dun.gpg
        cp $working_directory/sources/munge-$munge_version.tar.xz.asc $working_directory/build/munge/munge-$munge_version.tar.xz.asc
        rm -f /root/rpmbuild/RPMS/$distribution_architecture/munge*
        rpmbuild -ta munge-$munge_version.tar.xz

        # We need to install munge to build slurm
        if [ $distribution_version -eq 8 ]; then
        dnf install /root/rpmbuild/RPMS/$distribution_architecture/munge* -y
        fi
        if [ $distribution_version -eq 9 ]; then
        dnf install /root/rpmbuild/RPMS/$distribution_architecture/munge* -y
        fi
        if [ $distribution_version -eq 7 ]; then
        yum install /root/rpmbuild/RPMS/$distribution_architecture/munge* -y
        fi
    fi

    # Build success, tag it
    touch $tags_directory/munge-$distribution-$distribution_version-$munge_version

#fi

###### SLURM

# Since 23.11, it is possible to build slurm packages natively with deb mechanism.


    if [ ! -f $working_directory/sources/slurm-$slurm_version.tar.bz2 ]; then
        wget -P $working_directory/sources/ https://download.schedmd.com/slurm/slurm-$slurm_version.tar.bz2
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
    if [ $distribution == "Ubuntu" ] || [ $distribution == "Debian" ]; then
        tar xjvf slurm-$slurm_version.tar.bz2
        cd slurm-$slurm_version
        mk-build-deps -i debian/control
        debuild -b -uc -us
        cd ../
        mkdir -p /root/debbuild/DEBS/$distribution_architecture/
        mv *.deb /root/debbuild/DEBS/$distribution_architecture/
        # sed -i 's|%{!?_unitdir|#%{!?_unitdir|' slurm-$slurm_version/slurm.spec
        # sed -i '1s|^|%define\ _unitdir\ /etc/systemd/system\n|' slurm-$slurm_version/slurm.spec
        # sed -i 's|BuildRequires:\ systemd|#BuildRequires:\ systemd|' slurm-$slurm_version/slurm.spec
        # sed -i 's|BuildRequires:\ munge-devel|#BuildRequires:\ munge-devel|' slurm-$slurm_version/slurm.spec
        # sed -i 's|BuildRequires:\ python3|#BuildRequires:\ python3|' slurm-$slurm_version/slurm.spec
        # sed -i 's|BuildRequires:\ readline-devel|#BuildRequires:\ readline-devel|' slurm-$slurm_version/slurm.spec
        # sed -i 's|BuildRequires:\ perl(ExtUtils::MakeMaker)|#BuildRequires:\ perl(ExtUtils::MakeMaker)|' slurm-$slurm_version/slurm.spec
        # # sed -i 's|BuildRequires:\ mariadb-devel|#BuildRequires:\ mariadb-devel|' slurm-$slurm_version/slurm.spec
        # sed -i 's|BuildRequires:\ pam-devel|#BuildRequires:\ pam-devel|' slurm-$slurm_version/slurm.spec
        # sed -i 's|%{_perlman3dir}/Slurm*|#%{_perlman3dir}/Slurm*|' slurm-$slurm_version/slurm.spec
        # sed -i '1s/^/%define _build_id_links none\n/' slurm-$slurm_version/slurm.spec
        # tar cjvf slurm-$slurm_version.tar.bz2 slurm-$slurm_version
    else

    # if [ $distribution == "opensuse_leap" ]; then
    #     tar xjvf slurm-$slurm_version.tar.bz2
    #     # Package on sles is libmariadb-devel
    #     sed -i 's|BuildRequires:\ mariadb-devel|#BuildRequires:\ mariadb-devel|' slurm-$slurm_version/slurm.spec
    #     tar cjvf slurm-$slurm_version.tar.bz2 slurm-$slurm_version
    # fi

        rpmbuild -ta --target=$distribution_architecture slurm-$slurm_version.tar.bz2
    fi

    # if [ $distribution == "Ubuntu" ] || [ $distribution == "Debian" ]; then
    #     cd /root
    #     alien --to-deb /root/rpmbuild/RPMS/$distribution_architecture/slurm*
    #     mkdir -p /root/debbuild/DEBS/$distribution_architecture/
    #     mv *.deb /root/debbuild/DEBS/$distribution_architecture/
    # fi

    # Build success, tag it
    touch $tags_directory/slurm-$distribution-$distribution_version-$slurm_version

fi

set +x
