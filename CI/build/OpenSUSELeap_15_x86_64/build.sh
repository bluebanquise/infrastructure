set -e
set -x
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

set +e
docker images | grep opensuse_leap_15_build
if [ $? -ne 0 ]; then
  set -e
  docker pull docker.io/opensuse/leap:15
  docker build --no-cache --tag opensuse_leap_15_build -f $CURRENT_DIR/Dockerfile .
fi
set -e

if [[ -d "~/build/lp15/x86_64/" ]]; then
rm -Rf ~/build/lp15/x86_64/
fi
mkdir -p ~/build/lp15/x86_64/

if [[ -d "~/build/lp15/sources/" ]]; then
rm -Rf ~/build/lp15/sources/
fi
mkdir -p ~/build/lp15/sources/

if [ "$1" == "all" ]; then
docker run -it --rm -v ~/build/lp15/x86_64/:/usr/src/packages/RPMS/ -v ~/build/lp15/sources/:/usr/src/packages/SRPMS/ -v /tmp:/tmp opensuse_leap_15_build nyancat opensuse_leap 15
#docker run -it --rm -v ~/build/lp15/x86_64/:/usr/src/packages/RPMS/ -v ~/build/lp15/sources/:/usr/src/packages/SRPMS/ -v /tmp:/tmp opensuse_leap_15_build conman opensuse_leap 15
# docker run -it --rm -v ~/build/lp15/x86_64/:/usr/src/packages/RPMS/ -v ~/build/lp15/sources/:/usr/src/packages/SRPMS/ opensuse_leap_15_build ansible-cmd opensuse_leap 15
# docker run -it --rm -v ~/build/lp15/x86_64/:/usr/src/packages/RPMS/ -v ~/build/lp15/sources/:/usr/src/packages/SRPMS/ opensuse_leap_15_build atftp opensuse_leap 15
docker run -it --rm -v ~/build/lp15/x86_64/:/usr/src/packages/RPMS/ -v ~/build/lp15/sources/:/usr/src/packages/SRPMS/ -v /tmp:/tmp opensuse_leap_15_build bluebanquise-ipxe opensuse_leap 15
docker run -it --rm -v ~/build/lp15/x86_64/:/usr/src/packages/RPMS/ -v ~/build/lp15/sources/:/usr/src/packages/SRPMS/ -v /tmp:/tmp opensuse_leap_15_build atftp opensuse_leap 15
# docker run -it --rm -v ~/build/lp15/x86_64/:/usr/src/packages/RPMS/ -v ~/build/lp15/sources/:/usr/src/packages/SRPMS/ opensuse_leap_15_build bluebanquise-tools opensuse_leap 15
# docker run -it --rm -v ~/build/lp15/x86_64/:/usr/src/packages/RPMS/ -v ~/build/lp15/sources/:/usr/src/packages/SRPMS/ -v /tmp:/tmp opensuse_leap_15_build slurm opensuse_leap 15
docker run -it --rm -v ~/build/lp15/x86_64/:/usr/src/packages/RPMS/ -v ~/build/lp15/sources/:/usr/src/packages/SRPMS/ -v /tmp:/tmp opensuse_leap_15_build prometheus opensuse_leap 15
docker run -it --rm -v ~/build/lp15/x86_64/:/usr/src/packages/RPMS/ -v ~/build/lp15/sources/:/usr/src/packages/SRPMS/ -v /tmp:/tmp opensuse_leap_15_build loki opensuse_leap 15
docker run -it --rm -v ~/build/lp15/x86_64/:/usr/src/packages/RPMS/ -v ~/build/lp15/sources/:/usr/src/packages/SRPMS/ -v /tmp:/tmp opensuse_leap_15_build alpine opensuse_leap 15
docker run -it --rm -v ~/build/lp15/x86_64/:/usr/src/packages/RPMS/ -v ~/build/lp15/sources/:/usr/src/packages/SRPMS/ -v /tmp:/tmp opensuse_leap_15_build clonezilla opensuse_leap 15
docker run -it --rm -v ~/build/lp15/x86_64/:/usr/src/packages/RPMS/ -v ~/build/lp15/sources/:/usr/src/packages/SRPMS/ -v /tmp:/tmp opensuse_leap_15_build memtest86plus opensuse_leap 15

else
docker run -it --rm -v ~/build/lp15/x86_64/:/usr/src/packages/RPMS/ -v ~/build/lp15/sources/:/usr/src/packages/SRPMS/ -v /tmp:/tmp opensuse_leap_15_build $1 opensuse_leap 15
fi
