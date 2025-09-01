set -e
set -x

# Enable QEMU
docker run --privileged --rm tonistiigi/binfmt --install arm64

# Custom docker cache folder
# oxedions@prima:~/gits/infrastructure$ sudo systemctl restart docker
# oxedions@prima:~/gits/infrastructure$ cat /etc/docker/daemon.json 
# {
#         "bip": "172.26.0.1/16",
#         "data-root": "/docker_cache/"
# }
# oxedions@prima:~/gits/infrastructure$

CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Introduce tags, that allows to prevent super long and stupid rebuilds
mkdir -p $HOME/CI/tmp/wd/
mkdir -p $HOME/CI/tmp/cache/

################################################################################
#################### INIT STEP
####

for ARGUMENT in "$@"
do
   KEY=$(echo $ARGUMENT | cut -f1 -d=)

   KEY_LENGTH=${#KEY}
   VALUE="${ARGUMENT:$KEY_LENGTH+1}"

   export "$KEY"="$VALUE"
done

# Clean cache, it was meant to be redone at each build pass
if [ "$clean_cache" == 'yes' ]; then
    rm -Rf $HOME/CI/tmp/cache/*
fi

if [ -z ${packages_list+x} ]; then
    packages_list="all"
    packages_list_for_ipxe=$packages_list
    echo "No packages list passed as argument, will generate all."
else
    echo "Packages list to be generated: $packages_list"
fi

if [ -z ${arch_list+x} ]; then
    arch_list="all"
    echo "No arch list passed as argument, will generate all."
else
    echo "Arch list to be generated: $arch_list"
fi

if [ -z ${os_list+x} ]; then
    os_list="all"
    echo "No os list passed as argument, will generate all."
else
    echo "OS list to be generated: $os_list"
fi

if [ -z ${reset_repos+x} ]; then
    reset_repos="false"
    echo "No repo reset required."
else
    echo "Reset repo: $reset_repos"
fi

if [ -z ${clean_all+x} ]; then
    clean_all="false"
    echo "No clean required."
else
    echo "Clean all: $clean_all"
fi

if [ -z ${steps+x} ]; then
    steps="build repos"
    echo "Will do both build and repositories."
else
    echo "Steps: $steps"
fi

if [ "$clean_build" == 'yes' ]; then
    # Clean builds since it requires sudo, so better ask at the beggining
    sudo rm -Rf $HOME/CI/build
fi

if [ "$clean_all" == 'yes' ]; then
    sudo rm -Rf $HOME/CI/
fi

mkdir -p $HOME/CI/
mkdir -p $HOME/CI/logs/
mkdir -p $HOME/CI/build/{el8,el9,el10,lp15}/{x86_64,aarch64,sources}/
mkdir -p $HOME/CI/build/{u20,u22,u24,deb11,deb12,deb13}/{x86_64,arm64}/
mkdir -p $HOME/CI/repositories/{el8,el9,el10,lp15}/{x86_64,aarch64,sources}/bluebanquise/
mkdir -p $HOME/CI/repositories/{u20,u22,u24,deb11,deb12,deb13}/{x86_64,arm64}/bluebanquise/

################################################################################
#################### BUILDS
####

if [ "$os_list" == "all" ]; then
    os_list="el8,el9,el10,lp15,u20,u22,u24,deb11,deb12,deb13"
fi

if echo $steps | grep -q "build"; then
    for os_name in $(echo $os_list | sed 's/,/ /g'); do

        # If default request, get packages to be built for this OS
        if [ "$packages_list" == "all" ]; then
            packages_list=$(cat $CURRENT_DIR/build_matrix | grep $os_name | awk -F ' ' '{print $5}')
        fi
        if [ "$arch_list" == "all" ]; then
            archs_list=$(cat $CURRENT_DIR/build_matrix | grep $os_name | awk -F ' ' '{print $2}')
        fi
        os_distribution_name=$(cat $CURRENT_DIR/build_matrix | grep $os_name | awk -F ' ' '{print $3}')
        os_distribution_version_major=$(cat $CURRENT_DIR/build_matrix | grep $os_name | awk -F ' ' '{print $4}')

        for cpu_arch in $(echo $archs_list | sed 's/,/ /g'); do

            # For now I build on amd64 CPU, might need to update that later
            if [ "$cpu_arch" == "arm64" ] || [ "$cpu_arch" == "aarch64" ] ; then
                PLATFORM="--platform linux/arm64"
            else
                PLATFORM=""
            fi

            # Check if base image already exists, if not build it
            set +e
            docker images | grep $os_name-build-$cpu_arch
            if [ $? -ne 0 ]; then
                set -e
                docker build $PLATFORM --no-cache --tag $os_name-build-$cpu_arch -f $CURRENT_DIR/build/$os_name/Dockerfile $CURRENT_DIR/build/$os_name/
            fi
            set -e

            # Now build packages
            mkdir -p $HOME/CI/build/$os_name/$cpu_arch/
            for package in $(echo $packages_list | sed 's/,/ /g'); do
                docker run --rm $PLATFORM -v $HOME/CI/build/$os_name/:/root/rpmbuild/RPMS/ -v $HOME/CI/tmp/:/tmp $os_name-build-$cpu_arch $package $os_distribution_name $os_distribution_version_major
            done
        done
    done
fi
echo "ALL DONE"
exit O

################################################################################
#################### AGGREGATE IPXE PACKAGES
####
if echo $steps | grep -q "repos"; then
    # CROSS packages between archs for iPXE roms
    if echo $packages_list_for_ipxe | grep -q "ipxe" || echo $packages_list_for_ipxe | grep -q "all" ; then
    for os_name in $(echo $os_list | sed 's/,/ /g'); do


    

        if echo $os_list | grep -q "el7"; then
            cp $HOME/CI/build/el7/x86_64/noarch/bluebanquise-ipxe-x86_64*.rpm $HOME/CI/build/el7/aarch64/noarch/ ; \
            cp $HOME/CI/build/el7/x86_64/noarch/memtest86plus*.rpm $HOME/CI/build/el7/aarch64/noarch/ ; \
            cp $HOME/CI/build/el7/aarch64/noarch/bluebanquise-ipxe-arm64*.rpm $HOME/CI/build/el7/x86_64/noarch/ ; \
        fi
        if echo $os_list | grep -q "el8"; then
            cp $HOME/CI/build/el8/x86_64/noarch/bluebanquise-ipxe-x86_64*.rpm $HOME/CI/build/el8/aarch64/noarch/ ; \
            cp $HOME/CI/build/el8/x86_64/noarch/memtest86plus*.rpm $HOME/CI/build/el8/aarch64/noarch/ ; \
            cp $HOME/CI/build/el8/aarch64/noarch/bluebanquise-ipxe-arm64*.rpm $HOME/CI/build/el8/x86_64/noarch/ ; \
        fi
        if echo $os_list | grep -q "el9"; then
            cp $HOME/CI/build/el9/x86_64/noarch/bluebanquise-ipxe-x86_64*.rpm $HOME/CI/build/el9/aarch64/noarch/ ; \
            cp $HOME/CI/build/el9/x86_64/noarch/memtest86plus*.rpm $HOME/CI/build/el9/aarch64/noarch/ ; \
            cp $HOME/CI/build/el9/aarch64/noarch/bluebanquise-ipxe-arm64*.rpm $HOME/CI/build/el9/x86_64/noarch/ ; \
        fi
        if echo $os_list | grep -q "lp15"; then
            cp $HOME/CI/build/lp15/x86_64/noarch/bluebanquise-ipxe-x86_64*.rpm $HOME/CI/build/lp15/aarch64/noarch/ ; \
            cp $HOME/CI/build/lp15/x86_64/noarch/memtest86plus*.rpm $HOME/CI/build/lp15/aarch64/noarch/ ; \
            cp $HOME/CI/build/lp15/aarch64/noarch/bluebanquise-ipxe-arm64*.rpm $HOME/CI/build/lp15/x86_64/noarch/ ; \
        fi
        if echo $os_list | grep -q "ubuntu2004"; then
            cp $HOME/CI/build/ubuntu2004/x86_64/noarch/bluebanquise-ipxe-x86-64*.deb $HOME/CI/build/ubuntu2004/arm64/noarch/ ; \
            cp $HOME/CI/build/ubuntu2004/x86_64/noarch/memtest86plus*.deb $HOME/CI/build/ubuntu2004/arm64/noarch/ ; \
            cp $HOME/CI/build/ubuntu2004/arm64/noarch/bluebanquise-ipxe-arm64*.deb $HOME/CI/build/ubuntu2004/x86_64/noarch/ ; \
        fi
        if echo $os_list | grep -q "ubuntu2204"; then
            cp $HOME/CI/build/ubuntu2204/x86_64/noarch/bluebanquise-ipxe-x86-64*.deb $HOME/CI/build/ubuntu2204/arm64/noarch/ ; \
            cp $HOME/CI/build/ubuntu2204/x86_64/noarch/memtest86plus*.deb $HOME/CI/build/ubuntu2204/arm64/noarch/ ; \
            cp $HOME/CI/build/ubuntu2204/arm64/noarch/bluebanquise-ipxe-arm64*.deb $HOME/CI/build/ubuntu2204/x86_64/noarch/ ; \
        fi
        if echo $os_list | grep -q "ubuntu2404"; then
            cp $HOME/CI/build/ubuntu2404/x86_64/noarch/bluebanquise-ipxe-x86-64*.deb $HOME/CI/build/ubuntu2404/arm64/noarch/ ; \
            cp $HOME/CI/build/ubuntu2404/x86_64/noarch/memtest86plus*.deb $HOME/CI/build/ubuntu2404/arm64/noarch/ ; \
            cp $HOME/CI/build/ubuntu2404/arm64/noarch/bluebanquise-ipxe-arm64*.deb $HOME/CI/build/ubuntu2404/x86_64/noarch/ ; \
        fi
        if echo $os_list | grep -q "ubuntu2404"; then
            cp $HOME/CI/build/ubuntu2404/x86_64/noarch/bluebanquise-ipxe-x86-64*.deb $HOME/CI/build/ubuntu2404/arm64/noarch/ ; \
            cp $HOME/CI/build/ubuntu2404/x86_64/noarch/memtest86plus*.deb $HOME/CI/build/ubuntu2404/arm64/noarch/ ; \
            cp $HOME/CI/build/ubuntu2404/arm64/noarch/bluebanquise-ipxe-arm64*.deb $HOME/CI/build/ubuntu2404/x86_64/noarch/ ; \
        fi
        if echo $os_list | grep -q "debian11"; then
            cp $HOME/CI/build/debian11/x86_64/noarch/bluebanquise-ipxe-x86-64*.deb $HOME/CI/build/debian11/arm64/noarch/ ; \
            cp $HOME/CI/build/debian11/x86_64/noarch/memtest86plus*.deb $HOME/CI/build/debian11/arm64/noarch/ ; \
            cp $HOME/CI/build/debian11/arm64/noarch/bluebanquise-ipxe-arm64*.deb $HOME/CI/build/debian11/x86_64/noarch/ ; \
        fi
        if echo $os_list | grep -q "debian12"; then
            cp $HOME/CI/build/debian12/x86_64/noarch/bluebanquise-ipxe-x86-64*.deb $HOME/CI/build/debian12/arm64/noarch/ ; \
            cp $HOME/CI/build/debian12/x86_64/noarch/memtest86plus*.deb $HOME/CI/build/debian12/arm64/noarch/ ; \
            cp $HOME/CI/build/debian12/arm64/noarch/bluebanquise-ipxe-arm64*.deb $HOME/CI/build/debian12/x86_64/noarch/ ; \
        fi
    fi

################################################################################
#################### REPOSITORIES
####


    #### SOURCES

    if echo $os_list | grep -q "el7"; then
        mkdir -p $HOME/CI/repositories/el7/sources/bluebanquise/packages/
        rm -Rf $HOME/CI/repositories/el7/sources/bluebanquise/packages/*
        cp -a $HOME/CI/build/el7/sources/ $HOME/CI/repositories/el7/sources/bluebanquise/packages/
        cp -a $CURRENT_DIR/repositories/RedHat_7_sources/ $HOME/CI/repositories_RedHat_7_sources/
        $HOME/CI/repositories_RedHat_7_sources/build.sh $reset_repos
        cp -a $HOME/CI/repositories/el7/sources/bluebanquise/* $HOME/CI/repositories/el7/sources/bluebanquise/
    fi

    if echo $os_list | grep -q "el8"; then
        mkdir -p $HOME/CI/repositories/el8/sources/bluebanquise/packages/
        rm -Rf $HOME/CI/repositories/el8/sources/bluebanquise/packages/*
        cp -a $HOME/CI/build/el8/sources/ $HOME/CI/repositories/el8/sources/bluebanquise/packages/
        cp -a $CURRENT_DIR/repositories/RedHat_8_sources/ $HOME/CI/repositories_RedHat_8_sources/
        $HOME/CI/repositories_RedHat_8_sources/build.sh $reset_repos
        cp -a $HOME/CI/repositories/el8/sources/bluebanquise/* $HOME/CI/repositories/el8/sources/bluebanquise/
    fi

    if echo $os_list | grep -q "el9"; then
        mkdir -p $HOME/CI/repositories/el9/sources/bluebanquise/packages/
        rm -Rf $HOME/CI/repositories/el9/sources/bluebanquise/packages/*
        cp -a $HOME/CI/build/el9/sources/ $HOME/CI/repositories/el9/sources/bluebanquise/packages/
        cp -a $CURRENT_DIR/repositories/RedHat_9_sources/ $HOME/CI/repositories_RedHat_9_sources/
        $HOME/CI/repositories_RedHat_9_sources/build.sh $reset_repos
        cp -a $HOME/CI/repositories/el9/sources/bluebanquise/* $HOME/CI/repositories/el9/sources/bluebanquise/
    fi

    #### BINARIES

    if echo $os_list | grep -q "el7"; then
        if echo $arch_list | grep -q -E "x86_64"; then
            mkdir -p $HOME/CI/repositories/el7/x86_64/bluebanquise/packages/
            rm -Rf $HOME/CI/repositories/el7/x86_64/bluebanquise/packages/*
            cp -a $HOME/CI/build/el7/x86_64/x86_64/ $HOME/CI/repositories/el7/x86_64/bluebanquise/packages/
            cp -a $CURRENT_DIR/repositories/RedHat_7_x86_64/ $HOME/CI/repositories_RedHat_7_x86_64/
            $HOME/CI/repositories_RedHat_7_x86_64/build.sh $reset_repos
            cp -a $HOME/CI/repositories/el7/x86_64/bluebanquise/* $HOME/CI/repositories/el7/x86_64/bluebanquise/
        fi
        if echo $arch_list | grep -q -E "aarch64|arm64"; then
            mkdir -p $HOME/CI/repositories/el7/aarch64/bluebanquise/packages/
            rm -Rf $HOME/CI/repositories/el7/aarch64/bluebanquise/packages/*
            cp -a $HOME/CI/build/el7/aarch64/aarch64/ $HOME/CI/repositories/el7/aarch64/bluebanquise/packages/
            cp -a $CURRENT_DIR/repositories/RedHat_7_aarch64/ $HOME/CI/repositories_RedHat_7_aarch64/
            $HOME/CI/repositories_RedHat_7_aarch64/build.sh $reset_repos
            cp -a $HOME/CI/repositories/el7/aarch64/bluebanquise/* $HOME/CI/repositories/el7/aarch64/bluebanquise/
        fi
    fi

    if echo $os_list | grep -q "el8"; then
        if echo $arch_list | grep -q -E "x86_64"; then
            mkdir -p $HOME/CI/repositories/el8/x86_64/bluebanquise/packages/
            rm -Rf $HOME/CI/repositories/el8/x86_64/bluebanquise/packages/*
            cp -a $HOME/CI/build/el8/x86_64/x86_64/ $HOME/CI/repositories/el8/x86_64/bluebanquise/packages/
            cp -a $CURRENT_DIR/repositories/RedHat_8_x86_64/ $HOME/CI/repositories_RedHat_8_x86_64/
            $HOME/CI/repositories_RedHat_8_x86_64/build.sh $reset_repos
            cp -a $HOME/CI/repositories/el8/x86_64/bluebanquise/* $HOME/CI/repositories/el8/x86_64/bluebanquise/
        fi
        if echo $arch_list | grep -q -E "aarch64|arm64"; then
            mkdir -p $HOME/CI/repositories/el8/aarch64/bluebanquise/packages/
            rm -Rf $HOME/CI/repositories/el8/aarch64/bluebanquise/packages/*
            cp -a $HOME/CI/build/el8/aarch64/aarch64/ $HOME/CI/repositories/el8/aarch64/bluebanquise/packages/
            cp -a $CURRENT_DIR/repositories/RedHat_8_aarch64/ $HOME/CI/repositories_RedHat_8_aarch64/
            $HOME/CI/repositories_RedHat_8_aarch64/build.sh $reset_repos
            cp -a $HOME/CI/repositories/el8/aarch64/bluebanquise/* $HOME/CI/repositories/el8/aarch64/bluebanquise/
        fi
    fi

    if echo $os_list | grep -q "el9"; then
        if echo $arch_list | grep -q -E "x86_64"; then
            mkdir -p $HOME/CI/repositories/el9/x86_64/bluebanquise/packages/
            rm -Rf $HOME/CI/repositories/el9/x86_64/bluebanquise/packages/*
            cp -a $HOME/CI/build/el9/x86_64/x86_64/ $HOME/CI/repositories/el9/x86_64/bluebanquise/packages/
            cp -a $CURRENT_DIR/repositories/RedHat_9_x86_64/ $HOME/CI/repositories_RedHat_9_x86_64/
            $HOME/CI/repositories_RedHat_9_x86_64/build.sh $reset_repos
            cp -a $HOME/CI/repositories/el9/x86_64/bluebanquise/* $HOME/CI/repositories/el9/x86_64/bluebanquise/
        fi
        if echo $arch_list | grep -q -E "aarch64|arm64"; then
            mkdir -p $HOME/CI/repositories/el9/aarch64/bluebanquise/packages/
            rm -Rf $HOME/CI/repositories/el9/aarch64/bluebanquise/packages/*
            cp -a $HOME/CI/build/el9/aarch64/aarch64/ $HOME/CI/repositories/el9/aarch64/bluebanquise/packages/
            cp -a $CURRENT_DIR/repositories/RedHat_9_aarch64/ $HOME/CI/repositories_RedHat_9_aarch64/
            $HOME/CI/repositories_RedHat_9_aarch64/build.sh $reset_repos
            cp -a $HOME/CI/repositories/el9/aarch64/bluebanquise/* $HOME/CI/repositories/el9/aarch64/bluebanquise/
        fi
    fi

    if echo $os_list | grep -q "lp15"; then
        if echo $arch_list | grep -q "x86_64"; then
            mkdir -p $HOME/CI/repositories/lp15/x86_64/bluebanquise/packages/
            rm -Rf $HOME/CI/repositories/lp15/x86_64/bluebanquise/packages/*
            cp -a $HOME/CI/build/lp15/x86_64/x86_64/ $HOME/CI/repositories/lp15/x86_64/bluebanquise/packages/
            cp -a $CURRENT_DIR/repositories/OpenSUSELeap_15_x86_64/ $HOME/CI/repositories_OpenSUSELeap_15_x86_64/
            $HOME/CI/repositories_OpenSUSELeap_15_x86_64/build.sh $reset_repos
            cp -a $HOME/CI/repositories/lp15/x86_64/bluebanquise/* $HOME/CI/repositories/lp15/x86_64/bluebanquise/
        fi
        if echo $arch_list | grep -q -E "aarch64|arm64"; then
            mkdir -p $HOME/CI/repositories/lp15/aarch64/bluebanquise/packages/
            rm -Rf $HOME/CI/repositories/lp15/aarch64/bluebanquise/packages/*
            cp -a $HOME/CI/build/lp15/aarch64/aarch64/ $HOME/CI/repositories/lp15/aarch64/bluebanquise/packages/
            cp -a $CURRENT_DIR/repositories/OpenSUSELeap_15_aarch64/ $HOME/CI/repositories_OpenSUSELeap_15_aarch64/
            $HOME/CI/repositories_OpenSUSELeap_15_aarch64/build.sh $reset_repos
            cp -a $HOME/CI/repositories/lp15/aarch64/bluebanquise/* $HOME/CI/repositories/lp15/aarch64/bluebanquise/
        fi
    fi

    if echo $os_list | grep -q "ubuntu2004"; then
        if echo $arch_list | grep -q "x86_64"; then
	        rm -Rf $HOME/CI/repositories/u20/x86_64/bluebanquise/*
            mkdir -p $HOME/CI/repositories/ubuntu2004/x86_64/bluebanquise/packages/
            rm -Rf $HOME/CI/repositories/ubuntu2004/x86_64/bluebanquise/packages/*
            cp -a $HOME/CI/build/ubuntu2004/x86_64/ $HOME/CI/repositories/ubuntu2004/x86_64/bluebanquise/packages/
            cp -a $CURRENT_DIR/repositories/Ubuntu_20.04_x86_64/ $HOME/CI/repositories_Ubuntu_20.04_x86_64/
            $HOME/CI/repositories_Ubuntu_20.04_x86_64/build.sh $reset_repos
            cp -a $HOME/CI/repositories/ubuntu2004/x86_64/bluebanquise/* $HOME/CI/repositories/u20/x86_64/bluebanquise/
            rm -Rf $HOME/CI/repositories/u20/x86_64/bluebanquise/packages
            mv $HOME/CI/repositories/u20/x86_64/bluebanquise/repo/* $HOME/CI/repositories/u20/x86_64/bluebanquise/
            rm -Rf $HOME/CI/repositories/u20/x86_64/bluebanquise/repo
        fi
        if echo $arch_list | grep -q -E "aarch64|arm64"; then
	        rm -Rf $HOME/CI/repositories/u20/arm64/bluebanquise/*
            mkdir -p $HOME/CI/repositories/ubuntu2004/arm64/bluebanquise/packages/
            rm -Rf $HOME/CI/repositories/ubuntu2004/arm64/bluebanquise/packages/*
            cp -a $HOME/CI/build/ubuntu2004/arm64/ $HOME/CI/repositories/ubuntu2004/arm64/bluebanquise/packages/
            cp -a $CURRENT_DIR/repositories/Ubuntu_20.04_arm64/ $HOME/CI/repositories_Ubuntu_20.04_arm64/
            $HOME/CI/repositories_Ubuntu_20.04_arm64/build.sh $reset_repos
            cp -a $HOME/CI/repositories/ubuntu2004/arm64/bluebanquise/* $HOME/CI/repositories/u20/arm64/bluebanquise/
            rm -Rf $HOME/CI/repositories/u20/arm64/bluebanquise/packages
            mv $HOME/CI/repositories/u20/arm64/bluebanquise/repo/* $HOME/CI/repositories/u20/arm64/bluebanquise/
            rm -Rf $HOME/CI/repositories/u20/arm64/bluebanquise/repo
        fi
    fi

    if echo $os_list | grep -q "ubuntu2204"; then
        if echo $arch_list | grep -q "x86_64"; then
	        rm -Rf $HOME/CI/repositories/u22/x86_64/bluebanquise/*
            mkdir -p $HOME/CI/repositories/ubuntu2204/x86_64/bluebanquise/packages/
            rm -Rf $HOME/CI/repositories/ubuntu2204/x86_64/bluebanquise/packages/*
            cp -a $HOME/CI/build/ubuntu2204/x86_64/ $HOME/CI/repositories/ubuntu2204/x86_64/bluebanquise/packages/
            cp -a $CURRENT_DIR/repositories/Ubuntu_22.04_x86_64/ $HOME/CI/repositories_Ubuntu_22.04_x86_64/
            $HOME/CI/repositories_Ubuntu_22.04_x86_64/build.sh $reset_repos
            cp -a $HOME/CI/repositories/ubuntu2204/x86_64/bluebanquise/* $HOME/CI/repositories/u22/x86_64/bluebanquise/
            rm -Rf $HOME/CI/repositories/u22/x86_64/bluebanquise/packages
            mv $HOME/CI/repositories/u22/x86_64/bluebanquise/repo/* $HOME/CI/repositories/u22/x86_64/bluebanquise/
            rm -Rf $HOME/CI/repositories/u22/x86_64/bluebanquise/repo
        fi
        if echo $arch_list | grep -q -E "aarch64|arm64"; then
	        rm -Rf $HOME/CI/repositories/u22/arm64/bluebanquise/*
            mkdir -p $HOME/CI/repositories/ubuntu2204/arm64/bluebanquise/packages/
            rm -Rf $HOME/CI/repositories/ubuntu2204/arm64/bluebanquise/packages/*
            cp -a $HOME/CI/build/ubuntu2204/arm64/ $HOME/CI/repositories/ubuntu2204/arm64/bluebanquise/packages/
            cp -a $CURRENT_DIR/repositories/Ubuntu_22.04_arm64/ $HOME/CI/repositories_Ubuntu_22.04_arm64/
            $HOME/CI/repositories_Ubuntu_22.04_arm64/build.sh $reset_repos
            cp -a $HOME/CI/repositories/ubuntu2204/arm64/bluebanquise/* $HOME/CI/repositories/u22/arm64/bluebanquise/
            rm -Rf $HOME/CI/repositories/u22/arm64/bluebanquise/packages
            mv $HOME/CI/repositories/u22/arm64/bluebanquise/repo/* $HOME/CI/repositories/u22/arm64/bluebanquise/
            rm -Rf $HOME/CI/repositories/u22/arm64/bluebanquise/repo
        fi
    fi

    if echo $os_list | grep -q "ubuntu2404"; then
        if echo $arch_list | grep -q "x86_64"; then
	        rm -Rf $HOME/CI/repositories/u24/x86_64/bluebanquise/*
            mkdir -p $HOME/CI/repositories/ubuntu2404/x86_64/bluebanquise/packages/
            rm -Rf $HOME/CI/repositories/ubuntu2404/x86_64/bluebanquise/packages/*
            cp -a $HOME/CI/build/ubuntu2404/x86_64/ $HOME/CI/repositories/ubuntu2404/x86_64/bluebanquise/packages/
            cp -a $CURRENT_DIR/repositories/Ubuntu_24.04_x86_64/ $HOME/CI/repositories_Ubuntu_24.04_x86_64/
            $HOME/CI/repositories_Ubuntu_24.04_x86_64/build.sh $reset_repos
            cp -a $HOME/CI/repositories/ubuntu2404/x86_64/bluebanquise/* $HOME/CI/repositories/u24/x86_64/bluebanquise/
            rm -Rf $HOME/CI/repositories/u24/x86_64/bluebanquise/packages
            mv $HOME/CI/repositories/u24/x86_64/bluebanquise/repo/* $HOME/CI/repositories/u24/x86_64/bluebanquise/
            rm -Rf $HOME/CI/repositories/u24/x86_64/bluebanquise/repo
        fi
        if echo $arch_list | grep -q -E "aarch64|arm64"; then
	        rm -Rf $HOME/CI/repositories/u24/arm64/bluebanquise/*
            mkdir -p $HOME/CI/repositories/ubuntu2404/arm64/bluebanquise/packages/
            rm -Rf $HOME/CI/repositories/ubuntu2404/arm64/bluebanquise/packages/*
            cp -a $HOME/CI/build/ubuntu2404/arm64/ $HOME/CI/repositories/ubuntu2404/arm64/bluebanquise/packages/
            cp -a $CURRENT_DIR/repositories/Ubuntu_24.04_arm64/ $HOME/CI/repositories_Ubuntu_24.04_arm64/
            $HOME/CI/repositories_Ubuntu_24.04_arm64/build.sh $reset_repos
            cp -a $HOME/CI/repositories/ubuntu2404/arm64/bluebanquise/* $HOME/CI/repositories/u24/arm64/bluebanquise/
            rm -Rf $HOME/CI/repositories/u24/arm64/bluebanquise/packages
            mv $HOME/CI/repositories/u24/arm64/bluebanquise/repo/* $HOME/CI/repositories/u24/arm64/bluebanquise/
            rm -Rf $HOME/CI/repositories/u24/arm64/bluebanquise/repo
        fi
    fi

    if echo $os_list | grep -q "debian11"; then
        if echo $arch_list | grep -q "x86_64"; then
	        rm -Rf $HOME/CI/repositories/deb11/x86_64/bluebanquise/*
            mkdir -p $HOME/CI/repositories/debian11/x86_64/bluebanquise/packages/
            rm -Rf $HOME/CI/repositories/debian11/x86_64/bluebanquise/packages/*
            cp -a $HOME/CI/build/debian11/x86_64/ $HOME/CI/repositories/debian11/x86_64/bluebanquise/packages/
            cp -a $CURRENT_DIR/repositories/Debian_11_x86_64/ $HOME/CI/repositories_Debian_11_x86_64/
            $HOME/CI/repositories_Debian_11_x86_64/build.sh $reset_repos
            cp -a $HOME/CI/repositories/debian11/x86_64/bluebanquise/* $HOME/CI/repositories/deb11/x86_64/bluebanquise/
            rm -Rf $HOME/CI/repositories/deb11/x86_64/bluebanquise/packages
            mv $HOME/CI/repositories/deb11/x86_64/bluebanquise/repo/* $HOME/CI/repositories/deb11/x86_64/bluebanquise/
            rm -Rf $HOME/CI/repositories/deb11/x86_64/bluebanquise/repo
        fi
        if echo $arch_list | grep -q -E "aarch64|arm64"; then
            rm -Rf $HOME/CI/repositories/deb11/arm64/bluebanquise/*
            mkdir -p $HOME/CI/repositories/debian11/arm64/bluebanquise/packages/
            rm -Rf $HOME/CI/repositories/debian11/arm64/bluebanquise/packages/*
            cp -a $HOME/CI/build/debian11/arm64/ $HOME/CI/repositories/debian11/arm64/bluebanquise/packages/
            cp -a $CURRENT_DIR/repositories/Debian_11_arm64/ $HOME/CI/repositories_Debian_11_arm64/
            $HOME/CI/repositories_Debian_11_arm64/build.sh $reset_repos
            cp -a $HOME/CI/repositories/debian11/arm64/bluebanquise/* $HOME/CI/repositories/deb11/arm64/bluebanquise/
            rm -Rf $HOME/CI/repositories/deb11/arm64/bluebanquise/packages
            mv $HOME/CI/repositories/deb11/arm64/bluebanquise/repo/* $HOME/CI/repositories/deb11/arm64/bluebanquise/
            rm -Rf $HOME/CI/repositories/deb11/arm64/bluebanquise/repo
        fi
    fi

    if echo $os_list | grep -q "debian12"; then
        if echo $arch_list | grep -q "x86_64"; then
	        rm -Rf $HOME/CI/repositories/deb12/x86_64/bluebanquise/*
            mkdir -p $HOME/CI/repositories/debian12/x86_64/bluebanquise/packages/
            rm -Rf $HOME/CI/repositories/debian12/x86_64/bluebanquise/packages/*
            cp -a $HOME/CI/build/debian12/x86_64/x86_64/ $HOME/CI/repositories/debian12/x86_64/bluebanquise/packages/
            cp -a $CURRENT_DIR/repositories/Debian_12_x86_64/ $HOME/CI/repositories_Debian_12_x86_64/
            $HOME/CI/repositories_Debian_12_x86_64/build.sh $reset_repos
            cp -a $HOME/CI/repositories/debian12/x86_64/bluebanquise/* $HOME/CI/repositories/deb12/x86_64/bluebanquise/
            rm -Rf $HOME/CI/repositories/deb12/x86_64/bluebanquise/packages
            mv $HOME/CI/repositories/deb12/x86_64/bluebanquise/repo/* $HOME/CI/repositories/deb12/x86_64/bluebanquise/
            rm -Rf $HOME/CI/repositories/deb12/x86_64/bluebanquise/repo
        fi
        if echo $arch_list | grep -q -E "aarch64|arm64"; then
            rm -Rf $HOME/CI/repositories/deb12/arm64/bluebanquise/*
            mkdir -p $HOME/CI/repositories/debian12/arm64/bluebanquise/packages/
            rm -Rf $HOME/CI/repositories/debian12/arm64/bluebanquise/packages/*
            cp -a $HOME/CI/build/debian12/arm64/ $HOME/CI/repositories/debian12/arm64/bluebanquise/packages/
            cp -a $CURRENT_DIR/repositories/Debian_12_arm64/ $HOME/CI/repositories_Debian_12_arm64/
            $HOME/CI/repositories_Debian_12_arm64/build.sh $reset_repos
            cp -a $HOME/CI/repositories/debian12/arm64/bluebanquise/* $HOME/CI/repositories/deb12/arm64/bluebanquise/
            rm -Rf $HOME/CI/repositories/deb12/arm64/bluebanquise/packages
            mv $HOME/CI/repositories/deb12/arm64/bluebanquise/repo/* $HOME/CI/repositories/deb12/arm64/bluebanquise/
            rm -Rf $HOME/CI/repositories/deb12/arm64/bluebanquise/repo
        fi
    fi

    # cp -a -av $CURRENT_DIR/repositories/tree/* $HOME/CI/repositories/

fi

echo "All done :-)"
