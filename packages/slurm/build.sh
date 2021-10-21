set -x

CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $CURRENT_DIR/version.sh

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
    sed -i '1s|^|%define\ _unitdir\ /etc/systemd/system\n|' slurm-$slurm_version/slurm.spec
    sed -i 's|BuildRequires:\ systemd|#BuildRequires:\ systemd|' slurm-$slurm_version/slurm.spec
    sed -i 's|BuildRequires:\ munge-devel|#BuildRequires:\ munge-devel|' slurm-$slurm_version/slurm.spec
    sed -i 's|BuildRequires:\ python3|#BuildRequires:\ python3|' slurm-$slurm_version/slurm.spec
    sed -i 's|BuildRequires:\ readline-devel|#BuildRequires:\ readline-devel|' slurm-$slurm_version/slurm.spec
    sed -i 's|BuildRequires:\ perl(ExtUtils::MakeMaker)|#BuildRequires:\ perl(ExtUtils::MakeMaker)|' slurm-$slurm_version/slurm.spec
    sed -i 's|BuildRequires:\ pam-devel|#BuildRequires:\ pam-devel|' slurm-$slurm_version/slurm.spec
    sed -i 's|%{_perlman3dir}/Slurm*|#%{_perlman3dir}/Slurm*|' slurm-$slurm_version/slurm.spec
tar cjvf slurm-$slurm_version.tar.bz2 slurm-$slurm_version
fi

rpmbuild -ta slurm-$slurm_version.tar.bz2

if [ $distribution == "Ubuntu" ]; then
    cd /root
    alien --to-deb /root/rpmbuild/RPMS/$distribution_architecture/slurm*
    mkdir -p /root/debbuild/DEBS/$distribution_architecture/
    mv *.deb /root/debbuild/DEBS/$distribution_architecture/
fi

set +x