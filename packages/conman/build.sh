set -x

CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $CURRENT_DIR/version.sh

rm -Rf $working_directory/build/conman
mkdir -p $working_directory/build/conman

if [ ! -f $working_directory/sources/conman-$conman_version.tar.xz ]; then
  wget -P $working_directory/sources/ https://github.com/dun/conman/releases/download/conman-$conman_version/conman-$conman_version.tar.xz
fi

cd $working_directory/build/conman
cp $working_directory/sources/conman-$conman_version.tar.xz $working_directory/build/conman
tar xJvf conman-$conman_version.tar.xz
/usr/bin/cp -f $root_directory/packages/conman/* conman-$conman_version/
tar cvJf conman-$conman_version.tar.xz conman-$conman_version
rpmbuild -ta conman-$conman_version.tar.xz --define "_software_version $conman_version"

if [ $distribution == "Ubuntu" ] || [ $distribution == "Debian" ]; then
    cd /root
    alien --to-deb /root/rpmbuild/RPMS/$distribution_architecture/conman*
    mkdir -p /root/debbuild/DEBS/$distribution_architecture/
    mv *.deb /root/debbuild/DEBS/$distribution_architecture/
fi

set +x
