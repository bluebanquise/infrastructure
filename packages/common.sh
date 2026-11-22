

package_path_calc() {
    set -x
    if [[ "$distribution" == 'RedHat' ]]; then
        if [[ "$package_native_architecture" == "noarch" ]]; then
            package_distribution_architecture="noarch"
        else
            package_distribution_architecture=$distribution_architecture
        fi
        if [[ $package_sub_version =~ [0-9] ]]; then
            f_package_sub_version=$package_sub_version
        else
            f_package_sub_version=1
        fi
        if [[ "$package_no_os_name" == "true" ]]; then
            package_os_name=""
        else
            package_os_name=".el$distribution_version"  # el8, el9, etc
        fi
        package_path=/root/rpmbuild/RPMS/$package_distribution_architecture/$package_name-$package_version-$f_package_sub_version$package_os_name.$package_distribution_architecture.rpm
    elif [[ "$distribution" == 'opensuse_leap' ]]; then
        if [[ "$package_native_architecture" == "noarch" ]]; then
            package_distribution_architecture="noarch"
        else
            package_distribution_architecture=$distribution_architecture
        fi
        if [[ $package_sub_version =~ [0-9] ]]; then
            f_package_sub_version=$package_sub_version
        else
            f_package_sub_version=1
        fi
        package_path=/usr/src/packages/RPMS/$package_distribution_architecture/$package_name-$package_version-$f_package_sub_version.$package_distribution_architecture.rpm
    elif [[ $distribution == 'Ubuntu' ]] || [[ $distribution == 'Debian' ]]; then
        if [[ "$package_native_architecture" == "noarch" ]]; then
            package_distribution_architecture="all"
            package_folder_architecture='noarch'
        else
            if [[ $distribution_architecture == 'x86_64' ]]; then
                package_distribution_architecture='amd64'
                package_folder_architecture='x86_64'
            elif [[ $distribution_architecture == 'arm64' ]] || [[ $distribution_architecture == 'aarch64' ]]; then
                package_distribution_architecture='arm64'
                package_folder_architecture='aarch64'
            elif [[ $distribution_architecture == 'riscv64' ]]; then
                package_distribution_architecture='riscv64'
                package_folder_architecture='riscv64'
            fi
        fi
        if [[ $package_sub_version =~ [0-9] ]]; then
            f_package_sub_version=$package_sub_version
        else
            f_package_sub_version=2
        fi
        f_package_name=$(echo $package_name | sed 's/_/-/g')
        package_path=/root/debbuild/DEBS/$package_folder_architecture/$f_package_name\_$package_version-$f_package_sub_version\_$package_distribution_architecture.deb
    else
    echo "Error, unknown distribution!"
    exit 1
    fi

    echo "[ < < DEBUG > > ]"
    echo "[ < < DEBUG > > ]Package path calculated: $package_path"
    echo "[ < < DEBUG > > ]"

}


# Download a source or binary once into $sources_directory, shared by all builds.
# Parallel builds wanting the same file wait on its lock: the first one downloads,
# the others then find the file. Downloading to .part then renaming means a failed
# download never leaves a truncated file behind.
# Usage: download_locked <url> <file name> [extra wget arguments]
download_locked() {
    (
        flock 9
        if [ ! -f $sources_directory/$2 ]; then
            wget --timeout=30 --tries=5 --retry-connrefused --waitretry=30 "${@:3}" -O $sources_directory/$2.part "$1"
            mv $sources_directory/$2.part $sources_directory/$2
        fi
    ) 9>$sources_directory/$2.lock
}
