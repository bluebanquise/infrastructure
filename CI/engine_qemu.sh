set -e
#set -x

# For me
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
mkdir -p $HOME/CI/tmp/tags/
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
    echo "No packages list passed as argument, will generate all."
else
    echo "Packages list to be generated: $packages_list"
fi

if [ -z ${arch_list+x} ]; then
    arch_list="x86_64 aarch64 arm64"
    echo "No arch list passed as argument, will generate all."
else
    echo "Arch list to be generated: $arch_list"
fi

if [ -z ${os_list+x} ]; then
    os_list="el7 el8 el9 lp15 ubuntu2004 ubuntu2204 ubuntu2404 debian11 debian12"
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

if [ "$clean_build_repo" == 'yes' ]; then
    sudo rm -Rf $HOME/CI/build* $HOME/CI/build $HOME/CI/repositories* $HOME/CI/repositories
fi

if [ "$clean_all" == 'yes' ]; then
    sudo rm -Rf $HOME/CI/
fi

mkdir -p $HOME/CI/
mkdir -p $HOME/CI/logs/
mkdir -p $HOME/CI/build/{el7,el8,el9,lp15}/{x86_64,aarch64,sources}/
mkdir -p $HOME/CI/build/{debian11,debian12}/{x86_64,arm64}/
mkdir -p $HOME/CI/build/{ubuntu2004,ubuntu2204,ubuntu2404}/{x86_64,arm64}/
mkdir -p $HOME/CI/repositories/{el7,el8,el9,lp15}/{x86_64,aarch64,sources}/bluebanquise/
mkdir -p $HOME/CI/repositories/{debian11,debian12}/{x86_64,arm64}/bluebanquise/
mkdir -p $HOME/CI/repositories/{deb11,deb12}/{x86_64,arm64}/bluebanquise/
mkdir -p $HOME/CI/repositories/{u20,u22,u24}/{x86_64,arm64}/bluebanquise/


################################################################################
#################### BUILDS
####

if echo $steps | grep -q "build"; then

    # We need EL9 first, aka recent GCC, to build cached files
    if echo $os_list | grep -q "el9"; then
        if echo $arch_list | grep -q "x86_64"; then
            ## RedHat_9_x86_64
            cp -a $CURRENT_DIR/build/RedHat_9_x86_64/ $HOME/CI/Build_RedHat_9_x86_64/
            $HOME/CI/Build_RedHat_9_x86_64/build.sh $packages_list
            cp -a $HOME/CI/build/el9/x86_64/* $HOME/CI/build/el9/x86_64/
            cp -a $HOME/CI/build/el9/sources/* $HOME/CI/build/el9/sources/
        fi
        if echo $arch_list | grep -q -E "aarch64|arm64"; then
            ## RedHat_9_aarch64
            cp -a $CURRENT_DIR/build/RedHat_9_aarch64/ $HOME/CI/Build_RedHat_9_aarch64/
            $HOME/CI/Build_RedHat_9_aarch64/build.sh $packages_list "--platform linux/arm64"
            cp -a $HOME/CI/build/el9/aarch64/* $HOME/CI/build/el9/aarch64/
        fi
    fi

    if echo $os_list | grep -q "ubuntu2204"; then
        if echo $arch_list | grep -q "x86_64"; then
            ## Ubuntu_22.04_x86_64
            cp -a $CURRENT_DIR/build/Ubuntu_22.04_x86_64/ $HOME/CI/Build_Ubuntu_22.04_x86_64/
            $HOME/CI/Build_Ubuntu_22.04_x86_64/build.sh $packages_list
            cp -a $HOME/CI/build/ubuntu2204/x86_64/* $HOME/CI/build/ubuntu2204/x86_64/
        fi
        if echo $arch_list | grep -q -E "aarch64|arm64"; then
            ## Ubuntu_22.04_arm64
            cp -a $CURRENT_DIR/build/Ubuntu_22.04_arm64/ $HOME/CI/Build_Ubuntu_22.04_arm64/
            $HOME/CI/Build_Ubuntu_22.04_arm64/build.sh $packages_list
            cp -a $HOME/CI/build/ubuntu2204/arm64/* $HOME/CI/build/ubuntu2204/arm64/
        fi
    fi

    if echo $os_list | grep -q "ubuntu2404"; then
        if echo $arch_list | grep -q "x86_64"; then
            ## Ubuntu_24.04_x86_64
            cp -a $CURRENT_DIR/build/Ubuntu_24.04_x86_64/ $HOME/CI/Build_Ubuntu_24.04_x86_64/
            $HOME/CI/Build_Ubuntu_24.04_x86_64/build.sh $packages_list
            cp -a $HOME/CI/build/ubuntu2404/x86_64/* $HOME/CI/build/ubuntu2404/x86_64/
        fi
        if echo $arch_list | grep -q -E "aarch64|arm64"; then
            ## Ubuntu_24.04_arm64
            cp -a $CURRENT_DIR/build/Ubuntu_24.04_arm64/ $HOME/CI/Build_Ubuntu_24.04_arm64/
            $HOME/CI/Build_Ubuntu_24.04_arm64/build.sh $packages_list
            cp -a $HOME/CI/build/ubuntu2404/arm64/* $HOME/CI/build/ubuntu2404/arm64/
        fi
    fi

    if echo $os_list | grep -q "el7"; then
        if echo $arch_list | grep -q "x86_64"; then
            ## RedHat_7_x86_64
            cp -a $CURRENT_DIR/build/RedHat_7_x86_64/ $HOME/CI/Build_RedHat_7_x86_64/
            $HOME/CI/Build_RedHat_7_x86_64/build.sh $packages_list
            cp -a $HOME/CI/build/el7/x86_64/* $HOME/CI/build/el7/x86_64/
            cp -a $HOME/CI/build/el7/sources/* $HOME/CI/build/el7/sources/
        fi
        if echo $arch_list | grep -q -E "aarch64|arm64"; then
            ## RedHat_7_aarch64
            cp -a $CURRENT_DIR/build/RedHat_7_aarch64/ $HOME/CI/Build_RedHat_7_aarch64/
            $HOME/CI/Build_RedHat_7_aarch64/build.sh $packages_list
            cp -a $HOME/CI/build/el7/aarch64/* $HOME/CI/build/el7/aarch64/
        fi
    fi

    if echo $os_list | grep -q "el8"; then
        if echo $arch_list | grep -q "x86_64"; then
            ## RedHat_8_x86_64
            cp -a $CURRENT_DIR/build/RedHat_8_x86_64/ $HOME/CI/Build_RedHat_8_x86_64/
            $HOME/CI/Build_RedHat_8_x86_64/build.sh $packages_list
            cp -a $HOME/CI/build/el8/x86_64/* $HOME/CI/build/el8/x86_64/
            cp -a $HOME/CI/build/el8/sources/* $HOME/CI/build/el8/sources/
        fi
        if echo $arch_list | grep -q -E "aarch64|arm64"; then
            ## RedHat_8_aarch64
            cp -a $CURRENT_DIR/build/RedHat_8_aarch64/ $HOME/CI/Build_RedHat_8_aarch64/
            $HOME/CI/Build_RedHat_8_aarch64/build.sh $packages_list
            cp -a $HOME/CI/build/el8/aarch64/* $HOME/CI/build/el8/aarch64/
        fi
    fi

    if echo $os_list | grep -q "lp15"; then
        if echo $arch_list | grep -q "x86_64"; then
            ## OpenSuse Leap 15
            cp -a $CURRENT_DIR/build/OpenSUSELeap_15_x86_64/ $HOME/CI/Build_OpenSUSELeap_15_x86_64/
            $HOME/CI/Build_OpenSUSELeap_15_x86_64/build.sh $packages_list
            cp -a $HOME/CI/build/lp15/x86_64/* $HOME/CI/build/lp15/x86_64/
            cp -a $HOME/CI/build/lp15/sources/* $HOME/CI/build/lp15/sources/
        fi
        if echo $arch_list | grep -q -E "aarch64|arm64"; then
            ## OpenSuse Leap 15
            cp -a $CURRENT_DIR/build/OpenSUSELeap_15_aarch64/ $HOME/CI/Build_OpenSUSELeap_15_aarch64/
            $HOME/CI/Build_OpenSUSELeap_15_aarch64/build.sh $packages_list
            cp -a $HOME/CI/build/lp15/aarch64/* $HOME/CI/build/lp15/aarch64/
        fi
    fi

    if echo $os_list | grep -q "ubuntu2004"; then
        if echo $arch_list | grep -q "x86_64"; then
            ## Ubuntu_20.04_x86_64
            cp -a $CURRENT_DIR/build/Ubuntu_20.04_x86_64/ $HOME/CI/Build_Ubuntu_20.04_x86_64/
            $HOME/CI/Build_Ubuntu_20.04_x86_64/build.sh $packages_list
            cp -a $HOME/CI/build/ubuntu2004/x86_64/* $HOME/CI/build/ubuntu2004/x86_64/
        fi
        if echo $arch_list | grep -q -E "aarch64|arm64"; then
            ## Ubuntu_20.04_arm64
            cp -a $CURRENT_DIR/build/Ubuntu_20.04_arm64/ $HOME/CI/Build_Ubuntu_20.04_arm64/
            $HOME/CI/Build_Ubuntu_20.04_arm64/build.sh $packages_list
            cp -a $HOME/CI/build/ubuntu2004/arm64/* $HOME/CI/build/ubuntu2004/arm64/
        fi
    fi

    if echo $os_list | grep -q "debian11"; then
        if echo $arch_list | grep -q "x86_64"; then
            ## Debian_11_x86_64
            cp -a $CURRENT_DIR/build/Debian_11_x86_64/ $HOME/CI/Build_Debian_11_x86_64/
            $HOME/CI/Build_Debian_11_x86_64/build.sh $packages_list
            cp -a $HOME/CI/build/debian11/x86_64/* $HOME/CI/build/debian11/x86_64/
        fi
        if echo $arch_list | grep -q -E "aarch64|arm64"; then
            ## Debian_11_arm64
            cp -a $CURRENT_DIR/build/Debian_11_arm64/ $HOME/CI/Build_Debian_11_arm64/
            $HOME/CI/Build_Debian_11_arm64/build.sh $packages_list
            cp -a $HOME/CI/build/debian11/arm64/* $HOME/CI/build/debian11/arm64/
        fi
    fi

    if echo $os_list | grep -q "debian12"; then
        if echo $arch_list | grep -q "x86_64"; then
            ## Debian_12_x86_64
            cp -a $CURRENT_DIR/build/Debian_12_x86_64/ $HOME/CI/Build_Debian_12_x86_64/
            $HOME/CI/Build_Debian_12_x86_64/build.sh $packages_list
            #cp -a $HOME/CI/build/debian12/x86_64/* $HOME/CI/build/debian12/x86_64/
        fi
        if echo $arch_list | grep -q -E "aarch64|arm64"; then
            ## Debian_12_arm64
            cp -a $CURRENT_DIR/build/Debian_12_arm64/ $HOME/CI/Build_Debian_12_arm64/
            $HOME/CI/Build_Debian_12_arm64/build.sh $packages_list "--platform linux/arm64"
            #cp -a $HOME/CI/build/debian12/arm64/* $HOME/CI/build/debian12/arm64/
        fi
    fi

fi

################################################################################
#################### AGGREGATE IPXE PACKAGES
####
if echo $steps | grep -q "repos"; then
# CROSS packages between archs for iPXE roms

    if echo $packages_list | grep -q "ipxe" || echo $packages_list | grep -q "all" ; then

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
        mkdir -p $HOME/CI/repositories/el8/sources/bluebanquise/packages/rm-Rf $HOME/CI/repositories/el8/sources/bluebanquise/packages/*
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
            cp -a $HOME/CI/build/el7/x86_64/ $HOME/CI/repositories/el7/x86_64/bluebanquise/packages/
            cp -a $CURRENT_DIR/repositories/RedHat_7_x86_64/ $HOME/CI/repositories_RedHat_7_x86_64/
            $HOME/CI/repositories_RedHat_7_x86_64/build.sh $reset_repos
            cp -a $HOME/CI/repositories/el7/x86_64/bluebanquise/* $HOME/CI/repositories/el7/x86_64/bluebanquise/
        fi
        if echo $arch_list | grep -q -E "aarch64|arm64"; then
            mkdir -p $HOME/CI/repositories/el7/aarch64/bluebanquise/packages/
            rm -Rf $HOME/CI/repositories/el7/aarch64/bluebanquise/packages/*
            cp -a $HOME/CI/build/el7/aarch64/ $HOME/CI/repositories/el7/aarch64/bluebanquise/packages/
            cp -a $CURRENT_DIR/repositories/RedHat_7_aarch64/ $HOME/CI/repositories_RedHat_7_aarch64/
            $HOME/CI/repositories_RedHat_7_aarch64/build.sh $reset_repos
            cp -a $HOME/CI/repositories/el7/aarch64/bluebanquise/* $HOME/CI/repositories/el7/aarch64/bluebanquise/
        fi
    fi

    if echo $os_list | grep -q "el8"; then
        if echo $arch_list | grep -q -E "x86_64"; then
            mkdir -p $HOME/CI/repositories/el8/x86_64/bluebanquise/packages/
            rm -Rf $HOME/CI/repositories/el8/x86_64/bluebanquise/packages/*
            cp -a $HOME/CI/build/el8/x86_64/ $HOME/CI/repositories/el8/x86_64/bluebanquise/packages/
            cp -a $CURRENT_DIR/repositories/RedHat_8_x86_64/ $HOME/CI/repositories_RedHat_8_x86_64/
            $HOME/CI/repositories_RedHat_8_x86_64/build.sh $reset_repos
            cp -a $HOME/CI/repositories/el8/x86_64/bluebanquise/* $HOME/CI/repositories/el8/x86_64/bluebanquise/
        fi
        if echo $arch_list | grep -q -E "aarch64|arm64"; then
            mkdir -p $HOME/CI/repositories/el8/aarch64/bluebanquise/packages/
            rm -Rf $HOME/CI/repositories/el8/aarch64/bluebanquise/packages/*
            cp -a $HOME/CI/build/el8/aarch64/ $HOME/CI/repositories/el8/aarch64/bluebanquise/packages/
            cp -a $CURRENT_DIR/repositories/RedHat_8_aarch64/ $HOME/CI/repositories_RedHat_8_aarch64/
            $HOME/CI/repositories_RedHat_8_aarch64/build.sh $reset_repos
            cp -a $HOME/CI/repositories/el8/aarch64/bluebanquise/* $HOME/CI/repositories/el8/aarch64/bluebanquise/
        fi
    fi

    if echo $os_list | grep -q "el9"; then
        if echo $arch_list | grep -q -E "x86_64"; then
            mkdir -p $HOME/CI/repositories/el9/x86_64/bluebanquise/packages/
            rm -Rf $HOME/CI/repositories/el9/x86_64/bluebanquise/packages/*
            cp -a $HOME/CI/build/el9/x86_64/ $HOME/CI/repositories/el9/x86_64/bluebanquise/packages/
            cp -a $CURRENT_DIR/repositories/RedHat_9_x86_64/ $HOME/CI/repositories_RedHat_9_x86_64/
            $HOME/CI/repositories_RedHat_9_x86_64/build.sh $reset_repos
            cp -a $HOME/CI/repositories/el9/x86_64/bluebanquise/* $HOME/CI/repositories/el9/x86_64/bluebanquise/
        fi
        if echo $arch_list | grep -q -E "aarch64|arm64"; then
            mkdir -p $HOME/CI/repositories/el9/aarch64/bluebanquise/packages/
            rm -Rf $HOME/CI/repositories/el9/aarch64/bluebanquise/packages/*
            cp -a $HOME/CI/build/el9/aarch64/ $HOME/CI/repositories/el9/aarch64/bluebanquise/packages/
            cp -a $CURRENT_DIR/repositories/RedHat_9_aarch64/ $HOME/CI/repositories_RedHat_9_aarch64/
            $HOME/CI/repositories_RedHat_9_aarch64/build.sh $reset_repos
            cp -a $HOME/CI/repositories/el9/aarch64/bluebanquise/* $HOME/CI/repositories/el9/aarch64/bluebanquise/
        fi
    fi

    if echo $os_list | grep -q "lp15"; then
        if echo $arch_list | grep -q "x86_64"; then
            mkdir -p $HOME/CI/repositories/lp15/x86_64/bluebanquise/packages/
            rm -Rf $HOME/CI/repositories/lp15/x86_64/bluebanquise/packages/*
            cp -a $HOME/CI/build/lp15/x86_64/ $HOME/CI/repositories/lp15/x86_64/bluebanquise/packages/
            cp -a $CURRENT_DIR/repositories/OpenSUSELeap_15_x86_64/ $HOME/CI/repositories_OpenSUSELeap_15_x86_64/
            $HOME/CI/repositories_OpenSUSELeap_15_x86_64/build.sh $reset_repos
            cp -a $HOME/CI/repositories/lp15/x86_64/bluebanquise/* $HOME/CI/repositories/lp15/x86_64/bluebanquise/
        fi
        if echo $arch_list | grep -q -E "aarch64|arm64"; then
            mkdir -p $HOME/CI/repositories/lp15/aarch64/bluebanquise/packages/
            rm -Rf $HOME/CI/repositories/lp15/aarch64/bluebanquise/packages/*
            cp -a $HOME/CI/build/lp15/aarch64/ $HOME/CI/repositories/lp15/aarch64/bluebanquise/packages/
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
            cp -a $HOME/CI/build/debian12/x86_64/ $HOME/CI/repositories/debian12/x86_64/bluebanquise/packages/
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

    cp -a -av $CURRENT_DIR/repositories/tree/* $HOME/CI/repositories/

fi

echo "All done :-)"
