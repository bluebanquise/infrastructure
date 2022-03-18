set -x
if [ "$1" == 'yes' ]; then
podman run -it --rm -v /home/bluebanquise/repositories/debian11/arm64/bluebanquise/:/repo/ debian:11 /bin/bash -c ' \
    set -x ; \
    apt update ; \
    apt install -y dpkg-dev ; \
    cd /repo/ ; \
    dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz ; \
    '
else
podman run -it --rm -v /home/bluebanquise/repositories/debian11/arm64/bluebanquise/:/repo/ debian:11 /bin/bash -c ' \
    set -x ; \
    apt update ; \
    apt install -y wget dpkg-dev apt-mirror rsync ; \
    #wget http://bluebanquise.com/repository/releases/1.5-dev/debian11/x86_64/bluebanquise/bluebanquise.list ; \
    #echo "deb [trusted=yes] http://bluebanquise.com/repository/releases/1.5-dev/debian11/arm64/bluebanquise/ ./" > bluebanquise.list ; \
    #apt-mirror bluebanquise.list ; \
    #rsync -a -v --ignore-times /var/spool/apt-mirror/mirror/bluebanquise.com/repository/releases/1.5-dev/debian11/arm64/bluebanquise/packages/* /repo/packages/ ; \
    wget -np -nH --cut-dirs 5 -r --reject "index.html*" http://bluebanquise.com/repository/releases/latest/debian11/arm64/bluebanquise/ ; \
    rsync -a -v --ignore-times bluebanquise/packages/* /repo/packages/ ; \
    cd /repo/ ; \
    dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz ; \
    '
fi
