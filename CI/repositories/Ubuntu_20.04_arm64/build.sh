set -x
podman run -it --rm -v /home/bluebanquise/repositories/ubuntu2004/arm64/:/repo/ ubuntu:20.04 /bin/bash -c ' \
    set -x ; \
    apt-get update ; \
    apt-get install -y wget dpkg-dev apt-mirror rsync ; \
    echo "deb [trusted=yes] http://bluebanquise.com/repository/releases/1.5-dev/ubuntu2004/arm64/bluebanquise/ ./" > bluebanquise.list ; \
    #apt-mirror bluebanquise.list ; \
    #rsync -a -v --ignore-times /var/spool/apt-mirror/mirror/bluebanquise.com/repository/releases/1.5-dev/ubuntu2004/arm64/bluebanquise/packages/* /repo/packages/ ; \
    dpkg-scanpackages /repo/ /dev/null | gzip -9c > /repo/Packages.gz ; \
    '
