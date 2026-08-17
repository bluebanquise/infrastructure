# AI Generated version of my hand made script.
# Do not edit this script, only edit original one and ask an AI to paralelize it
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

mkdir -p $HOME/CI/tmp/cache/ipxe-arm
mkdir -p $HOME/CI/tmp/cache/ipxe-x86_64
cd $HOME/CI/tmp/cache/
rm -f ipxe-arm64
rm -f ipxe-aarch64
ln -sf ipxe-arm ipxe-aarch64
ln -sf ipxe-arm ipxe-arm64
cd $CURRENT_DIR

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

if [ -z ${parallel_os_builds+x} ]; then
    parallel_os_builds="no"
    echo "OS builds will run sequentially. Pass parallel_os_builds=yes to run them in parallel."
else
    echo "Parallel OS builds: $parallel_os_builds"
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
mkdir -p $HOME/CI/build/{el9,el10,osl15,u22,u24,deb12,deb13}/{x86_64,aarch64,sources}/
mkdir -p $HOME/CI/repositories/{el9,el10,osl15,u22,u24,deb12,deb13}/{x86_64,aarch64}/bluebanquise/

cd $CURRENT_DIR

rsync -av $CURRENT_DIR/repositories/tree/* $HOME/CI/repositories/

################################################################################
#################### BUILDS
####

if [ "$os_list" == "all" ]; then
#    os_list="el9,el8,el10,osl15,u20,u22,u24,deb11,deb12,deb13"
    os_list="el9,el10,osl15,u22,u24,deb12,deb13"
fi

# All the per-OS work lives in this function so it can be run either
# sequentially or in a background subshell (parallel), with its own
# local variables (no cross-OS / cross-job clobbering of packages_list,
# archs_list, etc.).
build_and_repo_for_os() {
    local os_name="$1"
    local packages_list_arg="$2"
    local arch_list_arg="$3"
    local steps="$4"

    local packages_list="$packages_list_arg"
    local archs_list

    # If default request, get packages to be built for this OS
    if [ "$packages_list_arg" == "all" ]; then
        packages_list=$(cat $CURRENT_DIR/build_matrix | grep $os_name | awk -F ' ' '{print $6}')
    fi
    if [ "$arch_list_arg" == "all" ]; then
        archs_list=$(cat $CURRENT_DIR/build_matrix | grep $os_name | awk -F ' ' '{print $2}')
    else
        archs_list=$arch_list_arg
    fi
    local os_distribution_name=$(cat $CURRENT_DIR/build_matrix | grep $os_name | awk -F ' ' '{print $3}')
    local os_distribution_version_major=$(cat $CURRENT_DIR/build_matrix | grep $os_name | awk -F ' ' '{print $4}')
    local os_package_format=$(cat $CURRENT_DIR/build_matrix | grep $os_name | awk -F ' ' '{print $5}')
    local internal_build_path

    if [ "$os_package_format" == "RPM" ]; then
        if [ "$os_distribution_name" == "opensuse_leap" ]; then
            internal_build_path="/usr/src/packages/RPMS/"
        else
            internal_build_path="/root/rpmbuild/RPMS/"
        fi
    else
        internal_build_path="/root/debbuild/DEBS/"
    fi

    #### BUILD
    if echo $steps | grep -q "build"; then
        for cpu_arch in $(echo $archs_list | sed 's/,/ /g'); do

            local PLATFORM=""
            # For now I build on amd64 CPU, might need to update that later
            if [ "$cpu_arch" == "aarch64" ] ; then
                PLATFORM="--platform linux/arm64"
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
                docker run --rm $PLATFORM -v $HOME/CI/build/$os_name/:$internal_build_path -v $HOME/CI/tmp/:/tmp $os_name-build-$cpu_arch $package $os_distribution_name $os_distribution_version_major
            done

        done
    fi

    #### REPOS
    if echo $steps | grep -q "repos"; then

        for cpu_arch in $(echo $archs_list | sed 's/,/ /g'); do

            local PLATFORM=""
            # For now I build on amd64 CPU, might need to update that later
            if [ "$cpu_arch" == "aarch64" ] ; then
                PLATFORM="--platform linux/arm64"
            fi

            # Check if base image already exists, if not build it
            set +e
            docker images | grep $os_name-repos-$cpu_arch
            if [ $? -ne 0 ]; then
                set -e
                docker build $PLATFORM --no-cache --tag $os_name-repos-$cpu_arch -f $CURRENT_DIR/build/$os_name/Dockerfile_repos $CURRENT_DIR/build/$os_name/
            fi
            set -e

            # Build repo
            local repos_path=$HOME/CI/repositories/$os_name/$cpu_arch/bluebanquise/
            mkdir -p $repos_path
            $(which cp) -af $HOME/CI/build/$os_name/$cpu_arch $repos_path
            $(which cp) -af $HOME/CI/build/$os_name/noarch $repos_path
            source $CURRENT_DIR/build/$os_name/build_repos.sh $repos_path $os_name-repos-$cpu_arch # $reset_repos

        done
    fi
}

# From here on, failures for individual OS runs are captured (not fatal to
# the whole script immediately) so that: 1) all requested OSes get a chance
# to run, 2) we can print a recap, 3) the script still exits non-zero at
# the very end if ANY of them failed.
set +e

IFS=',' read -ra os_array <<< "$os_list"

declare -A os_status
declare -A os_log

pids=()
pid_os_names=()

for os_name in "${os_array[@]}"; do

    log_file="$HOME/CI/logs/${os_name}.log"
    os_log[$os_name]="$log_file"

    if [ "$parallel_os_builds" == "yes" ]; then
        (
            set -e
            set -x
            build_and_repo_for_os "$os_name" "$packages_list" "$arch_list" "$steps"
        ) &> "$log_file" &
        pids+=("$!")
        pid_os_names+=("$os_name")
        echo "Launched $os_name in background (log: $log_file)"
    else
        (
            set -e
            set -x
            build_and_repo_for_os "$os_name" "$packages_list" "$arch_list" "$steps"
        ) &> "$log_file"
        os_status[$os_name]=$?
    fi

done

# If parallel, wait for every job and record its individual status
if [ "$parallel_os_builds" == "yes" ]; then
    for i in "${!pids[@]}"; do
        wait "${pids[$i]}"
        os_status["${pid_os_names[$i]}"]=$?
    done
fi

set -e

################################################################################
#################### RECAP
####

echo ""
echo "################################################################################"
echo "#################### BUILD RECAP"
echo "####"

overall_fail=0
for os_name in "${os_array[@]}"; do
    if [ "${os_status[$os_name]}" -eq 0 ]; then
        echo "  [OK]     $os_name"
    else
        echo "  [FAILED] $os_name  (exit code ${os_status[$os_name]}, log: ${os_log[$os_name]})"
        overall_fail=1
    fi
done
echo ""

if [ "$overall_fail" -ne 0 ]; then
    echo "One or more OS builds/repos steps FAILED. See above and the corresponding logs under $HOME/CI/logs/"
    exit 1
fi

echo "ALL DONE"