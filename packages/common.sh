package_path_calc() {

    if [ "$distribution" == 'RedHat' ]; then
        if [ -z ${package_native_architecture+x} ]; then
            package_distribution_architecture=$package_native_architecture
        else
            package_distribution_architecture=$distribution_architecture
        fi
        package_os_name="el$distribution_version"  # el8, el9, etc
        package_path=/root/rpmbuild/RPMS/$package_distribution_architecture/$package_name-$package_version-1.$package_os_name.$package_distribution_architecture.rpm
    elif [ "$distribution" == 'opensuse_leap' ]; then
        if [ -z ${package_native_architecture+x} ]; then
            package_distribution_architecture=$package_native_architecture
        else
            package_distribution_architecture=$distribution_architecture
        fi
        package_path=/root/rpmbuild/RPMS/$package_distribution_architecture/$package_name-$package_version-1.$package_distribution_architecture.rpm
    elif [ $distribution == 'Ubuntu' ] || [ $distribution == 'Debian' ]; then
        if [ -z ${package_native_architecture+x} ]; then
            if [ $distribution_architecture == 'x86_64' ]; then
                package_distribution_architecture='amd64'
            elif [ $distribution_architecture == 'arm64' ]; then
                package_distribution_architecture='arm64'
            fi
        else
            package_distribution_architecture=$package_native_architecture
        fi
        package_path=/root/debbuild/DEBS/$package_distribution_architecture/$package_name-$package_version-2.$package_distribution_architecture.deb
    else
    echo "Error, unknown distribution!"
    exit 1
    fi

    echo "Package path calculated: $package_path"

}
