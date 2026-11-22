set -x

CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $CURRENT_DIR/version.sh
source $CURRENT_DIR/../common.sh

# memtest86+ builds for x86_64 and, since 9.00, arm64; there is no riscv64 build.
# Like iPXE, each arch build makes its own noarch package, memtest86plus-<arch>, and
# the repositories step copies the noarch packages to every arch: an arm64 management
# server can then serve memtest to x86_64 nodes, and the other way round.
if [ $distribution_architecture == 'x86_64' ]; then
    memtest86plus_arch=x86_64
    memtest86plus_build_dir=x86_64
elif [ $distribution_architecture == 'aarch64' ] || [ $distribution_architecture == 'arm64' ]; then
    memtest86plus_arch=arm64
    memtest86plus_build_dir=aarch64
else
    echo "memtest86+ has no $distribution_architecture build, skipping."
    return 0
fi

package_name=memtest86plus-$memtest86plus_arch
package_path_calc

memtest86plus_version=$package_version

if [ ! -f $package_path ]; then

    download_locked https://github.com/memtest86plus/memtest86plus/archive/refs/tags/v$memtest86plus_version.tar.gz memtest86plus-$memtest86plus_version.tar.gz
    rm -Rf $working_directory/build/memtest86plus
    mkdir -p $working_directory/build/memtest86plus
    cd $working_directory/build/memtest86plus
    cp $sources_directory/memtest86plus-$memtest86plus_version.tar.gz .
    tar xvzf memtest86plus-$memtest86plus_version.tar.gz
    $(which cp) -af $root_directory/memtest86plus/* memtest86plus-$memtest86plus_version/
    tar cvzf memtest86plus.tar.gz memtest86plus-$memtest86plus_version
    rpmbuild -ta memtest86plus.tar.gz --target=noarch --define "_software_version $memtest86plus_version" --define "_memtest86plus_arch $memtest86plus_arch" --define "_memtest86plus_build_dir $memtest86plus_build_dir"

    if [ $distribution == "Ubuntu" ] || [ $distribution == "Debian" ]; then
        cd /root
        alien --to-deb --scripts /root/rpmbuild/RPMS/noarch/memtest86plus-*
        mkdir -p /root/debbuild/DEBS/noarch/
        mv *.deb /root/debbuild/DEBS/noarch/
    fi

fi
