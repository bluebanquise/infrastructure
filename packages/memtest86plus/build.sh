CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $CURRENT_DIR/version.sh

set -x
if [ ! -f $working_directory/sources/memtest86plus-$memtest86plus_version.tar.gz ]; then
    wget -P $working_directory/sources/ https://github.com/memtest86plus/memtest86plus/archive/refs/tags/v$memtest86plus_version.tar.gz
    mv $working_directory/sources/v$memtest86plus_version.tar.gz $working_directory/sources/memtest86plus-$memtest86plus_version.tar.gz
fi
rm -Rf $working_directory/build/memtest86plus
mkdir -p $working_directory/build/memtest86plus
cd $working_directory/build/memtest86plus
cp $working_directory/sources/memtest86plus-$memtest86plus_version.tar.gz .
tar xvzf memtest86plus-$memtest86plus_version.tar.gz
$(which cp) -af $root_directory/memtest86plus/* memtest86plus-$memtest86plus_version/
tar cvzf memtest86plus.tar.gz memtest86plus-$memtest86plus_version
rpmbuild -ta memtest86plus.tar.gz --target=$distribution_architecture --define "_software_version $memtest86plus_version"

if [ $distribution == "Ubuntu" ] || [ $distribution == "Debian" ]; then
    cd /root
    alien --to-deb --scripts /root/rpmbuild/RPMS/$distribution_architecture/memtest86plus-*
    mkdir -p /root/debbuild/DEBS/$distribution_architecture/
    mv *.deb /root/debbuild/DEBS/$distribution_architecture/
fi

set +x




git clone https://github.com/memtest86plus/memtest86plus