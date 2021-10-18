CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $CURRENT_DIR/version.sh

set -x
if [ ! -f $working_directory/sources/nyancat-$nyancat_version.tar.gz ]; then
    wget -P $working_directory/sources/ https://github.com/klange/nyancat/archive/$nyancat_version.tar.gz
    mv $working_directory/sources/$nyancat_version.tar.gz $working_directory/sources/nyancat-$nyancat_version.tar.gz
fi
rm -Rf $working_directory/build/nyancat
mkdir -p $working_directory/build/nyancat
cd $working_directory/build/nyancat
cp $working_directory/sources/nyancat-$nyancat_version.tar.gz .
tar xvzf nyancat-$nyancat_version.tar.gz
$(which cp) -af $root_directory/packages/nyancat/* nyancat-$nyancat_version/
tar cvzf nyancat.tar.gz nyancat-$nyancat_version
rpmbuild -ta nyancat.tar.gz --define "_software_version $nyancat_version"

if [ $distribution == "Ubuntu" ]; then
    cd /root
    alien --to-deb --scripts /root/rpmbuild/RPMS/x86_64/nyancat-*
    mkdir -p /root/debbuild/DEBS/noarch/
    mv *.deb /root/debbuild/DEBS/noarch/
fi

set +x

