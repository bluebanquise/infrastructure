set -x

CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $CURRENT_DIR/version.sh
source $CURRENT_DIR/../common.sh

package_path_calc

if [ ! -f $package_path ]; then

    rm -Rf $working_directory/build/bluebanquise-venv
    mkdir -p $working_directory/build/bluebanquise-venv
    cd $working_directory/build/bluebanquise-venv
    mkdir bluebanquise-venv-$package_version/
    $(which cp) -af $root_directory/bluebanquise-venv/* bluebanquise-venv-$package_version/
    tar cvzf bluebanquise-venv.tar.gz bluebanquise-venv-$package_version
    rpmbuild -ta bluebanquise-venv.tar.gz --target=$distribution_architecture --define "_software_version $package_version"

    if [ $distribution == "Ubuntu" ] || [ $distribution == "Debian" ]; then
        cd /root
        alien --to-deb --scripts /root/rpmbuild/RPMS/$distribution_architecture/bluebanquise-venv-*
        mkdir -p /root/debbuild/DEBS/$distribution_architecture/
        mv *.deb /root/debbuild/DEBS/$distribution_architecture/
    fi

fi
