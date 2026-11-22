set -x

CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $CURRENT_DIR/version.sh
source $CURRENT_DIR/../common.sh

package_path_calc

if [ ! -f $package_path ]; then

    download_locked https://github.com/klange/nyancat/archive/$package_version.tar.gz nyancat-$package_version.tar.gz
    rm -Rf $working_directory/build/nyancat
    mkdir -p $working_directory/build/nyancat
    cd $working_directory/build/nyancat
    cp $sources_directory/nyancat-$package_version.tar.gz .
    tar xvzf nyancat-$package_version.tar.gz
    $(which cp) -af $root_directory/nyancat/* nyancat-$package_version/
    tar cvzf nyancat.tar.gz nyancat-$package_version
    rpmbuild -ta nyancat.tar.gz --target=$distribution_architecture --define "_software_version $package_version"

    if [ $distribution == "Ubuntu" ] || [ $distribution == "Debian" ]; then
        cd /root
        alien --to-deb --scripts /root/rpmbuild/RPMS/$distribution_architecture/nyancat-*
        mkdir -p /root/debbuild/DEBS/$distribution_architecture/
        mv *.deb /root/debbuild/DEBS/$distribution_architecture/
    fi

fi
