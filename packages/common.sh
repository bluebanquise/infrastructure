package_path_calc() {

    if [ "$distribution" == 'RedHat' ]; then
        package_os_name="el$distribution_version"  # el8, el9, etc
        package_path=/root/rpmbuild/RPMS/$distribution_architecture/$package_name-$package_version-1.$package_os_name.$distribution_architecture.rpm
    elif [ "$distribution" == 'opensuse_leap' ]; then
        package_path=/root/rpmbuild/RPMS/$distribution_architecture/$package_name-$package_version-1.$distribution_architecture.rpm
    elif [ $distribution == 'Ubuntu' ] || [ $distribution == 'Debian' ]; then
        if [ -z ${package_native_architecture+x} ];
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
