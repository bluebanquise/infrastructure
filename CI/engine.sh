set -e
set -x

CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Assume aarch64_worker and x86_64_worker both resolve
# Assume remote user is bluebanquise user and remote home is /home/bluebanquise

for ARGUMENT in "$@"
do
   KEY=$(echo $ARGUMENT | cut -f1 -d=)

   KEY_LENGTH=${#KEY}
   VALUE="${ARGUMENT:$KEY_LENGTH+1}"

   export "$KEY"="$VALUE"
done

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
    os_list="el7 el8 lp15 ubuntu2004"
    echo "No os list passed as argument, will generate all."
else
    echo "OS list to be generated: $os_list"
fi

mkdir -p ~/CI/
mkdir -p ~/CI/logs/
mkdir -p ~/CI/build/{el7,el8,lp15}/{x86_64,aarch64,sources}/
mkdir -p ~/CI/build/ubuntu2004/{x86_64,arm64}/
mkdir -p ~/CI/repositories/{el7,el8,lp15}/{x86_64,aarch64,sources}/bluebanquise/
mkdir -p ~/CI/repositories/ubuntu2004/{x86_64,arm64}/bluebanquise/

# BUILDS

if echo $os_list | grep -q "el8"; then
    if echo $arch_list | grep -q "x86_64"; then
    ## RedHat_8_x86_64
    rsync -av $CURRENT_DIR/build/RedHat_8_x86_64/ bluebanquise@x86_64_worker:/home/bluebanquise/Build_RedHat_8_x86_64/
    ssh bluebanquise@x86_64_worker /home/bluebanquise/Build_RedHat_8_x86_64/build.sh $packages_list
    rsync -av bluebanquise@x86_64_worker:/home/bluebanquise/build/el8/x86_64/* ~/CI/build/el8/x86_64/
    rsync -av bluebanquise@x86_64_worker:/home/bluebanquise/build/el8/sources/* ~/CI/build/el8/sources/
    fi
fi

if echo $os_list | grep -q "el7"; then
    if echo $arch_list | grep -q "x86_64"; then
    ## RedHat_7_x86_64
    rsync -av $CURRENT_DIR/build/RedHat_7_x86_64/ bluebanquise@x86_64_worker:/home/bluebanquise/Build_RedHat_7_x86_64/
    ssh bluebanquise@x86_64_worker /home/bluebanquise/Build_RedHat_7_x86_64/build.sh $packages_list
    rsync -av bluebanquise@x86_64_worker:/home/bluebanquise/build/el7/x86_64/* ~/CI/build/el7/x86_64/
    rsync -av bluebanquise@x86_64_worker:/home/bluebanquise/build/el7/sources/* ~/CI/build/el7/sources/
    fi
fi

if echo $os_list | grep -q "ubuntu2004"; then
    if echo $arch_list | grep -q "x86_64"; then
    ## Ubuntu_20.04_x86_64
    rsync -av $CURRENT_DIR/build/Ubuntu_20.04_x86_64/ bluebanquise@x86_64_worker:/home/bluebanquise/Build_Ubuntu_20.04_x86_64/
    ssh bluebanquise@x86_64_worker /home/bluebanquise/Build_Ubuntu_20.04_x86_64/build.sh $packages_list
    rsync -av bluebanquise@x86_64_worker:/home/bluebanquise/build/ubuntu2004/x86_64/* ~/CI/build/ubuntu2004/x86_64/
    fi
fi

if echo $os_list | grep -q "el8"; then
    if echo $arch_list | grep -q -E "aarch64|arm64"; then
    ## RedHat_8_aarch64
    rsync -av $CURRENT_DIR/build/RedHat_8_aarch64/ bluebanquise@aarch64_worker:/home/bluebanquise/Build_RedHat_8_aarch64/
    ssh bluebanquise@aarch64_worker /home/bluebanquise/Build_RedHat_8_aarch64/build.sh $packages_list
    rsync -av bluebanquise@aarch64_worker:/home/bluebanquise/build/el8/aarch64/* ~/CI/build/el8/aarch64/
    fi
fi

if echo $os_list | grep -q "el7"; then
    if echo $arch_list | grep -q -E "aarch64|arm64"; then
    ## RedHat_7_aarch64
    rsync -av $CURRENT_DIR/build/RedHat_7_aarch64/ bluebanquise@aarch64_worker:/home/bluebanquise/Build_RedHat_7_aarch64/
    ssh bluebanquise@aarch64_worker /home/bluebanquise/Build_RedHat_7_aarch64/build.sh $packages_list
    rsync -av bluebanquise@aarch64_worker:/home/bluebanquise/build/el7/aarch64/* ~/CI/build/el7/aarch64/
    fi
fi

if echo $os_list | grep -q "ubuntu2004"; then
    if echo $arch_list | grep -q -E "aarch64|arm64"; then
    ## Ubuntu_20.04_arm64
    rsync -av $CURRENT_DIR/build/Ubuntu_20.04_arm64/ bluebanquise@aarch64_worker:/home/bluebanquise/Build_Ubuntu_20.04_arm64/
    ssh bluebanquise@aarch64_worker /home/bluebanquise/Build_Ubuntu_20.04_arm64/build.sh $packages_list
    rsync -av bluebanquise@aarch64_worker:/home/bluebanquise/build/ubuntu2004/arm64/* ~/CI/build/ubuntu2004/arm64/
    fi
fi

# CROSS packages between archs for iPXE toms

cp ~/CI/build/el7/x86_64/noarch/bluebanquise-ipxe-x86_64*.rpm ~/CI/build/el7/aarch64/noarch/ ; \
cp ~/CI/build/el7/aarch64/noarch/bluebanquise-ipxe-arm64*.rpm ~/CI/build/el7/x86_64/noarch/ ; \
cp ~/CI/build/el8/x86_64/noarch/bluebanquise-ipxe-x86_64*.rpm ~/CI/build/el8/aarch64/noarch/ ; \
cp ~/CI/build/el8/aarch64/noarch/bluebanquise-ipxe-arm64*.rpm ~/CI/build/el8/x86_64/noarch/ ; \
cp ~/CI/build/lp15/x86_64/noarch/bluebanquise-ipxe-x86_64*.rpm ~/CI/build/lp15/aarch64/noarch/ ; \
cp ~/CI/build/lp15/aarch64/noarch/bluebanquise-ipxe-arm64*.rpm ~/CI/build/lp15/x86_64/noarch/ ; \
cp ~/CI/build/ubuntu2004/x86_64/noarch/bluebanquise-ipxe-x86-64*.deb ~/CI/build/ubuntu2004/arm64/noarch/ ; \
cp ~/CI/build/ubuntu2004/arm64/noarch/bluebanquise-ipxe-arm64*.deb ~/CI/build/ubuntu2004/x86_64/noarch/ ; \

# REPOSITORIES



## RedHat_8_x86_64
#fi
#if [ $a -eq 2 ]; then
#fi

ssh bluebanquise@x86_64_worker "mkdir -p /home/bluebanquise/repositories/el8/sources/bluebanquise/packages/; rm -Rf /home/bluebanquise/repositories/el8/sources/bluebanquise/packages/*"
rsync -av ~/CI/build/el8/sources/ bluebanquise@x86_64_worker:/home/bluebanquise/repositories/el8/sources/bluebanquise/packages/
rsync -av $CURRENT_DIR/repositories/RedHat_8_sources/ bluebanquise@x86_64_worker:/home/bluebanquise/Repositories_RedHat_8_sources/
ssh bluebanquise@x86_64_worker /home/bluebanquise/Repositories_RedHat_8_sources/build.sh
rsync -av bluebanquise@x86_64_worker:/home/bluebanquise/repositories/el8/sources/bluebanquise/* ~/CI/repositories/el8/sources/bluebanquise/

ssh bluebanquise@x86_64_worker "mkdir -p /home/bluebanquise/repositories/el7/sources/bluebanquise/packages/; rm -Rf /home/bluebanquise/repositories/el7/sources/bluebanquise/packages/*"
rsync -av ~/CI/build/el7/sources/ bluebanquise@x86_64_worker:/home/bluebanquise/repositories/el7/sources/bluebanquise/packages/
rsync -av $CURRENT_DIR/repositories/RedHat_7_sources/ bluebanquise@x86_64_worker:/home/bluebanquise/Repositories_RedHat_7_sources/
ssh bluebanquise@x86_64_worker /home/bluebanquise/Repositories_RedHat_7_sources/build.sh
rsync -av bluebanquise@x86_64_worker:/home/bluebanquise/repositories/el7/sources/bluebanquise/* ~/CI/repositories/el7/sources/bluebanquise/

ssh bluebanquise@x86_64_worker "mkdir -p /home/bluebanquise/repositories/el8/x86_64/bluebanquise/packages/; rm -Rf /home/bluebanquise/repositories/el8/x86_64/bluebanquise/packages/*"
rsync -av ~/CI/build/el8/x86_64/ bluebanquise@x86_64_worker:/home/bluebanquise/repositories/el8/x86_64/bluebanquise/packages/
rsync -av $CURRENT_DIR/repositories/RedHat_8_x86_64/ bluebanquise@x86_64_worker:/home/bluebanquise/Repositories_RedHat_8_x86_64/
ssh bluebanquise@x86_64_worker /home/bluebanquise/Repositories_RedHat_8_x86_64/build.sh
rsync -av bluebanquise@x86_64_worker:/home/bluebanquise/repositories/el8/x86_64/bluebanquise/* ~/CI/repositories/el8/x86_64/bluebanquise/

ssh bluebanquise@x86_64_worker "mkdir -p /home/bluebanquise/repositories/el7/x86_64/bluebanquise/packages/; rm -Rf /home/bluebanquise/repositories/el7/x86_64/bluebanquise/packages/*"
rsync -av ~/CI/build/el7/x86_64/ bluebanquise@x86_64_worker:/home/bluebanquise/repositories/el7/x86_64/bluebanquise/packages/
rsync -av $CURRENT_DIR/repositories/RedHat_7_x86_64/ bluebanquise@x86_64_worker:/home/bluebanquise/Repositories_RedHat_7_x86_64/
ssh bluebanquise@x86_64_worker /home/bluebanquise/Repositories_RedHat_7_x86_64/build.sh
rsync -av bluebanquise@x86_64_worker:/home/bluebanquise/repositories/el7/x86_64/bluebanquise/* ~/CI/repositories/el7/x86_64/bluebanquise/

ssh bluebanquise@aarch64_worker "mkdir -p /home/bluebanquise/repositories/el8/aarch64/bluebanquise/packages/; rm -Rf /home/bluebanquise/repositories/el8/aarch64/bluebanquise/packages/*"
rsync -av ~/CI/build/el8/aarch64/ bluebanquise@aarch64_worker:/home/bluebanquise/repositories/el8/aarch64/bluebanquise/packages/
rsync -av $CURRENT_DIR/repositories/RedHat_8_aarch64/ bluebanquise@aarch64_worker:/home/bluebanquise/Repositories_RedHat_8_aarch64/
ssh bluebanquise@aarch64_worker /home/bluebanquise/Repositories_RedHat_8_aarch64/build.sh
rsync -av bluebanquise@aarch64_worker:/home/bluebanquise/repositories/el8/aarch64/bluebanquise/* ~/CI/repositories/el8/aarch64/bluebanquise/

ssh bluebanquise@aarch64_worker "mkdir -p /home/bluebanquise/repositories/el7/aarch64/bluebanquise/packages/; rm -Rf /home/bluebanquise/repositories/el7/aarch64/bluebanquise/packages/*"
rsync -av ~/CI/build/el7/aarch64/ bluebanquise@aarch64_worker:/home/bluebanquise/repositories/el7/aarch64/bluebanquise/packages/
rsync -av $CURRENT_DIR/repositories/RedHat_7_aarch64/ bluebanquise@aarch64_worker:/home/bluebanquise/Repositories_RedHat_7_aarch64/
ssh bluebanquise@aarch64_worker /home/bluebanquise/Repositories_RedHat_7_aarch64/build.sh
rsync -av bluebanquise@aarch64_worker:/home/bluebanquise/repositories/el7/aarch64/bluebanquise/* ~/CI/repositories/el7/aarch64/bluebanquise/

ssh bluebanquise@x86_64_worker "mkdir -p /home/bluebanquise/repositories/ubuntu2004/x86_64/bluebanquise/packages/; rm -Rf /home/bluebanquise/repositories/ubuntu2004/x86_64/bluebanquise/packages/*"
rsync -av ~/CI/build/ubuntu2004/x86_64/ bluebanquise@x86_64_worker:/home/bluebanquise/repositories/ubuntu2004/x86_64/bluebanquise/packages/
rsync -av $CURRENT_DIR/repositories/Ubuntu_20.04_x86_64/ bluebanquise@x86_64_worker:/home/bluebanquise/Repositories_Ubuntu_20.04_x86_64/
ssh bluebanquise@x86_64_worker /home/bluebanquise/Repositories_Ubuntu_20.04_x86_64/build.sh
rsync -av bluebanquise@x86_64_worker:/home/bluebanquise/repositories/ubuntu2004/x86_64/bluebanquise/* ~/CI/repositories/ubuntu2004/x86_64/bluebanquise/

ssh bluebanquise@aarch64_worker "mkdir -p /home/bluebanquise/repositories/ubuntu2004/arm64/bluebanquise/packages/; rm -Rf /home/bluebanquise/repositories/ubuntu2004/arm64/bluebanquise/packages/*"
rsync -av ~/CI/build/ubuntu2004/arm64/ bluebanquise@aarch64_worker:/home/bluebanquise/repositories/ubuntu2004/arm64/bluebanquise/packages/
rsync -av $CURRENT_DIR/repositories/Ubuntu_20.04_arm64/ bluebanquise@aarch64_worker:/home/bluebanquise/Repositories_Ubuntu_20.04_arm64/
ssh bluebanquise@aarch64_worker /home/bluebanquise/Repositories_Ubuntu_20.04_arm64/build.sh
rsync -av bluebanquise@aarch64_worker:/home/bluebanquise/repositories/ubuntu2004/arm64/bluebanquise/* ~/CI/repositories/ubuntu2004/arm64/bluebanquise/

rsync -av -av $CURRENT_DIR/repositories/tree/* ~/CI/repositories/

echo "All done :-)"
