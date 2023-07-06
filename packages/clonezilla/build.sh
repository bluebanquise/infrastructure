CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $CURRENT_DIR/version.sh

set -x
if [ ! -f $working_directory/sources/clonezilla-live-$clonezilla_version-amd64.iso ]; then
    wget -P $working_directory/sources/ $clonezilla_iso_url
fi

rm -Rf $working_directory/build/clonezilla
mkdir -p $working_directory/build/clonezilla
cd $working_directory/build/clonezilla
mkdir clonezilla-$clonezilla_version
cp $working_directory/sources/clonezilla-live-$clonezilla_version-amd64.iso clonezilla-$clonezilla_version/
$(which cp) -af $root_directory/clonezilla/* clonezilla-$clonezilla_version/
sed -i "s/CLONEZILLA_VERSION/$clonezilla_version/" clonezilla-$clonezilla_version/boot.ipxe
tar cvzf clonezilla.tar.gz clonezilla-$clonezilla_version
rpmbuild -ta clonezilla.tar.gz --target=noarch --define "_software_version $clonezilla_version"

if [ $distribution == "Ubuntu" ] || [ $distribution == "Debian" ]; then
    cd /root
    alien --to-deb --scripts /root/rpmbuild/RPMS/$distribution_architecture/clonezilla-*
    mkdir -p /root/debbuild/DEBS/$distribution_architecture/
    mv *.deb /root/debbuild/DEBS/$distribution_architecture/
fi

set +x
