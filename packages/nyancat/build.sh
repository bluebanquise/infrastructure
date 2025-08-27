CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $CURRENT_DIR/version.sh

if [ ! -f $tags_directory/nyancat-$distribution-$distribution_version-$nyancat_version ]; then

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
    $(which cp) -af $root_directory/nyancat/* nyancat-$nyancat_version/
    tar cvzf nyancat.tar.gz nyancat-$nyancat_version
    rpmbuild -ta nyancat.tar.gz --target=$distribution_architecture --define "_software_version $nyancat_version"

    if [ $distribution == "Ubuntu" ] || [ $distribution == "Debian" ]; then
        cd /root
        alien --to-deb --scripts /root/rpmbuild/RPMS/$distribution_architecture/nyancat-*
        mkdir -p /root/debbuild/DEBS/$distribution_architecture/
        mv *.deb /root/debbuild/DEBS/$distribution_architecture/
    fi

    # Build success, tag it
    touch $tags_directory/nyancat-$distribution-$distribution_version-$nyancat_version-$(uname -p)

fi

set +x

