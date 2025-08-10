set -e
set -x
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

set +e
docker images | grep rockylinux_8_build
if [ $? -ne 0 ]; then
  set -e
  docker pull docker.io/rockylinux/rockylinux:8
  docker build --no-cache --tag rockylinux_8_build -f $CURRENT_DIR/Dockerfile
fi
set -e

if [[ -d "~/build/el8/x86_64/" ]]; then
rm -Rf ~/build/el8/x86_64/
fi
mkdir -p ~/build/el8/x86_64/

if [[ -d "~/build/el8/sources/" ]]; then
rm -Rf ~/build/el8/sources/
fi
mkdir -p ~/build/el8/sources/

if [ "$1" == "all" ]; then
docker run -it --rm -v ~/build/el8/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el8/sources/:/root/rpmbuild/SRPMS/ -v /tmp:/tmp rockylinux_8_build nyancat RedHat 8
docker run -it --rm -v ~/build/el8/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el8/sources/:/root/rpmbuild/SRPMS/ -v /tmp:/tmp rockylinux_8_build conman RedHat 8
docker run -it --rm -v ~/build/el8/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el8/sources/:/root/rpmbuild/SRPMS/ -v /tmp:/tmp rockylinux_8_build atftp RedHat 8
docker run -it --rm -v ~/build/el8/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el8/sources/:/root/rpmbuild/SRPMS/ -v /tmp:/tmp rockylinux_8_build bluebanquise-ipxe RedHat 8
docker run -it --rm -v ~/build/el8/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el8/sources/:/root/rpmbuild/SRPMS/ -v /tmp:/tmp rockylinux_8_build slurm RedHat 8
docker run -it --rm -v ~/build/el8/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el8/sources/:/root/rpmbuild/SRPMS/ -v /tmp:/tmp rockylinux_8_build prometheus RedHat 8
docker run -it --rm -v ~/build/el8/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el8/sources/:/root/rpmbuild/SRPMS/ -v /tmp:/tmp rockylinux_8_build loki RedHat 8
docker run -it --rm -v ~/build/el8/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el8/sources/:/root/rpmbuild/SRPMS/ -v /tmp:/tmp rockylinux_8_build alpine RedHat 8
docker run -it --rm -v ~/build/el8/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el8/sources/:/root/rpmbuild/SRPMS/ -v /tmp:/tmp rockylinux_8_build clonezilla RedHat 8
docker run -it --rm -v ~/build/el8/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el8/sources/:/root/rpmbuild/SRPMS/ -v /tmp:/tmp rockylinux_8_build memtest86plus RedHat 8

else
docker run -it --rm -v ~/build/el8/x86_64/:/root/rpmbuild/RPMS/ -v ~/build/el8/sources/:/root/rpmbuild/SRPMS/ -v /tmp:/tmp rockylinux_8_build $1 RedHat 8
fi
