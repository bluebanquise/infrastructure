set -e
set -x

CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Assume aarch64_worker and x86_64_worker both resolve
# Assume remote user is bluebanquise user and remote home is /home/bluebanquise

mkdir -p ~/CI/
mkdir -p ~/CI/logs/
mkdir -p ~/CI/{build,repositories}/{el7,el8}/{x86_64,aarch64}/
mkdir -p ~/CI/{build,repositories}/ubuntu2004/{x86_64,arm64}/

# BUILDS

## Different archs == different hosts -> parallel

#(
a=1
if [ $a -eq 2 ]; then
    ## RedHat_8_x86_64
    rsync -av $CURRENT_DIR/build/RedHat_8_x86_64/ bluebanquise@x86_64_worker:/home/bluebanquise/RedHat_8_x86_64/
    ssh bluebanquise@x86_64_worker /home/bluebanquise/RedHat_8_x86_64/build.sh
    rsync -av bluebanquise@x86_64_worker:/home/bluebanquise/build/el8/x86_64/* ~/CI/build/el8/x86_64/

    ## RedHat_7_x86_64
    rsync -av $CURRENT_DIR/build/RedHat_7_x86_64/ bluebanquise@x86_64_worker:/home/bluebanquise/RedHat_7_x86_64/
#    ssh bluebanquise@x86_64_worker /home/bluebanquise/RedHat_7_x86_64/build.sh
    rsync -av bluebanquise@x86_64_worker:/home/bluebanquise/build/el7/x86_64/* ~/CI/build/el7/x86_64/
#fi
    ## Ubuntu_20.04_x86_64
    rsync -av $CURRENT_DIR/build/Ubuntu_20.04_x86_64/ bluebanquise@x86_64_worker:/home/bluebanquise/Ubuntu_20.04_x86_64/
#    ssh bluebanquise@x86_64_worker /home/bluebanquise/Ubuntu_20.04_x86_64/build.sh
    rsync -av bluebanquise@x86_64_worker:/home/bluebanquise/build/ubuntu2004/x86_64/* ~/CI/build/ubuntu2004/x86_64/
#exit
    ## RedHat_8_aarch64
    rsync -av $CURRENT_DIR/build/RedHat_8_aarch64/ bluebanquise@aarch64_worker:/home/bluebanquise/RedHat_8_aarch64/
#    ssh bluebanquise@aarch64_worker /home/bluebanquise/RedHat_8_aarch64/build.sh
    rsync -av bluebanquise@aarch64_worker:/home/bluebanquise/build/el8/aarch64/* ~/CI/build/el8/aarch64/
#fi
    ## RedHat_7_aarch64
    rsync -av $CURRENT_DIR/build/RedHat_7_aarch64/ bluebanquise@aarch64_worker:/home/bluebanquise/RedHat_7_aarch64/
#    ssh bluebanquise@aarch64_worker /home/bluebanquise/RedHat_7_aarch64/build.sh
    rsync -av bluebanquise@aarch64_worker:/home/bluebanquise/build/el7/aarch64/* ~/CI/build/el7/aarch64/

    ## Ubuntu_20.04_arm64
    rsync -av $CURRENT_DIR/build/Ubuntu_20.04_arm64/ bluebanquise@aarch64_worker:/home/bluebanquise/Ubuntu_20.04_arm64/
#    ssh bluebanquise@aarch64_worker /home/bluebanquise/Ubuntu_20.04_arm64/build.sh
    rsync -av bluebanquise@aarch64_worker:/home/bluebanquise/build/ubuntu2004/arm64/* ~/CI/build/ubuntu2004/arm64/

#) >  ~/CI/logs/x86_64.log 2>&1 &

#wait $!

# CROSS packages between archs for iPXE toms

cp ~/CI/build/el7/x86_64/noarch/ipxe-x86_64-bluebanquise*.rpm ~/CI/build/el7/aarch64/noarch/ ; \
cp ~/CI/build/el7/aarch64/noarch/ipxe-arm64-bluebanquise*.rpm ~/CI/build/el7/x86_64/noarch/ ; \
cp ~/CI/build/el8/x86_64/noarch/ipxe-x86_64-bluebanquise*.rpm ~/CI/build/el8/aarch64/noarch/ ; \
cp ~/CI/build/el8/aarch64/noarch/ipxe-arm64-bluebanquise*.rpm ~/CI/build/el8/x86_64/noarch/ ; \
cp ~/CI/build/ubuntu2004/x86_64/noarch/ipxe-x86-64-bluebanquise*.deb ~/CI/build/ubuntu2004/arm64/noarch/ ; \
cp ~/CI/build/ubuntu2004/arm64/noarch/ipxe-arm64-bluebanquise*.deb ~/CI/build/ubuntu2004/x86_64/noarch/ ; \



# REPOSITORIES

## RedHat_8_x86_64

ssh bluebanquise@x86_64_worker "mkdir -p /home/bluebanquise/repositories/el8/x86_64/packages/; rm -Rf /home/bluebanquise/repositories/el8/x86_64/packages/*"
rsync -av ~/CI/build/el8/x86_64/ bluebanquise@x86_64_worker:/home/bluebanquise/repositories/el8/x86_64/packages/
rsync -av $CURRENT_DIR/repositories/RedHat_8_x86_64/ bluebanquise@x86_64_worker:/home/bluebanquise/Repositories_RedHat_8_x86_64/
ssh bluebanquise@x86_64_worker /home/bluebanquise/Repositories_RedHat_8_x86_64/build.sh
rsync -av bluebanquise@x86_64_worker:/home/bluebanquise/repositories/el8/x86_64/* ~/CI/repositories/el8/x86_64/

ssh bluebanquise@x86_64_worker "mkdir -p /home/bluebanquise/repositories/el7/x86_64/packages/; rm -Rf /home/bluebanquise/repositories/el7/x86_64/packages/*"
rsync -av ~/CI/build/el7/x86_64/ bluebanquise@x86_64_worker:/home/bluebanquise/repositories/el7/x86_64/packages/
rsync -av $CURRENT_DIR/repositories/RedHat_7_x86_64/ bluebanquise@x86_64_worker:/home/bluebanquise/Repositories_RedHat_7_x86_64/
ssh bluebanquise@x86_64_worker /home/bluebanquise/Repositories_RedHat_7_x86_64/build.sh
rsync -av bluebanquise@x86_64_worker:/home/bluebanquise/repositories/el7/x86_64/* ~/CI/repositories/el7/x86_64/

ssh bluebanquise@aarch64_worker "mkdir -p /home/bluebanquise/repositories/el8/aarch64/packages/; rm -Rf /home/bluebanquise/repositories/el8/aarch64/packages/*"
rsync -av ~/CI/build/el8/aarch64/ bluebanquise@aarch64_worker:/home/bluebanquise/repositories/el8/aarch64/packages/
rsync -av $CURRENT_DIR/repositories/RedHat_8_aarch64/ bluebanquise@aarch64_worker:/home/bluebanquise/Repositories_RedHat_8_aarch64/
ssh bluebanquise@aarch64_worker /home/bluebanquise/Repositories_RedHat_8_aarch64/build.sh
rsync -av bluebanquise@aarch64_worker:/home/bluebanquise/repositories/el8/aarch64/* ~/CI/repositories/el8/aarch64/

ssh bluebanquise@aarch64_worker "mkdir -p /home/bluebanquise/repositories/el7/aarch64/packages/; rm -Rf /home/bluebanquise/repositories/el7/aarch64/packages/*"
rsync -av ~/CI/build/el7/aarch64/ bluebanquise@aarch64_worker:/home/bluebanquise/repositories/el7/aarch64/packages/
rsync -av $CURRENT_DIR/repositories/RedHat_7_aarch64/ bluebanquise@aarch64_worker:/home/bluebanquise/Repositories_RedHat_7_aarch64/
ssh bluebanquise@aarch64_worker /home/bluebanquise/Repositories_RedHat_7_aarch64/build.sh
rsync -av bluebanquise@aarch64_worker:/home/bluebanquise/repositories/el7/aarch64/* ~/CI/repositories/el7/aarch64/
fi

ssh bluebanquise@x86_64_worker "mkdir -p /home/bluebanquise/repositories/ubuntu2004/x86_64/packages/; rm -Rf /home/bluebanquise/repositories/ubuntu2004/x86_64/packages/*"
rsync -av ~/CI/build/ubuntu2004/x86_64/ bluebanquise@x86_64_worker:/home/bluebanquise/repositories/ubuntu2004/x86_64/packages/
rsync -av $CURRENT_DIR/repositories/Ubuntu_20.04_x86_64/ bluebanquise@x86_64_worker:/home/bluebanquise/Repositories_Ubuntu_20.04_x86_64/
ssh bluebanquise@x86_64_worker /home/bluebanquise/Repositories_Ubuntu_20.04_x86_64/build.sh
rsync -av bluebanquise@x86_64_worker:/home/bluebanquise/repositories/ubuntu2004/x86_64/* ~/CI/repositories/ubuntu2004/x86_64/

