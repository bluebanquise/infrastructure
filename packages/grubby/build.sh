set -x

CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $CURRENT_DIR/version.sh

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
sed -i 's|-Werror||' Makefile
make	
$(which cp) -af $root_directory/packages/grubby/* .
cd ../
tar cvzf grubby-$grubby_version.tar.gz grubby-$grubby_version
rpmbuild -ta grubby-$grubby_version.tar.gz --define "_software_version $grubby_version"
if [ $distribution == "Ubuntu" ]; then
    cd /root
    alien --to-deb --scripts /root/rpmbuild/RPMS/$distribution_architecture/grubby-*
    mkdir -p /root/debbuild/DEBS/$distribution_architecture/
    mv *.deb /root/debbuild/DEBS/$distribution_architecture/
fi

set +x