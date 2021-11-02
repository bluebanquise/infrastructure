CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Assume aarch64_worker and x86_64_worker both resolve
# Assume remote user is bluebanquise user and remote home is /home/bluebanquise

mkdir -p ~/CI/
mkdir -p ~/CI/logs/
mkdir -p ~/CI/{build,repositories}/{el7,el8}/{x86_64,aarch64}/
mkdir -p ~/CI/{build,repositories}/ubuntu2004/{x86_64,arm64}/

# BUILDS

## Different archs == different hosts -> parallel

(
    ## RedHat_8_x86_64
    set -e
    rsync -av $CURRENT_DIR/build/RedHat_8_x86_64/ bluebanquise@x86_64_worker:/home/bluebanquise/RedHat_8_x86_64/
    ssh bluebanquise@x86_64_worker /home/bluebanquise/RedHat_8_x86_64/build.sh
    rsync -av bluebanquise@x86_64_worker:/home/bluebanquise/rpmbuild/RPMS/* ~/CI/build/el8/x86_64/

    ## RedHat_7_x86_64
    rsync -av $CURRENT_DIR/build/RedHat_7_x86_64/ bluebanquise@x86_64_worker:/home/bluebanquise/RedHat_7_x86_64/
    ssh bluebanquise@x86_64_worker /home/bluebanquise/RedHat_7_x86_64/build.sh
    rsync -av bluebanquise@x86_64_worker:/home/bluebanquise/rpmbuild/RPMS/* ~/CI/build/el7/x86_64/

) >  ~/CI/logs/x86_64.log &

wait $!