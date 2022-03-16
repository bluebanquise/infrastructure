set -x
if [ "$1" == 'yes' ]; then
podman run -it --rm -v /home/bluebanquise/repositories/ubuntu2004/x86_64/bluebanquise/:/repo/ ubuntu:20.04 /bin/bash -c ' \
    set -x ; \
    apt-get update ; \
    apt-get install -y dpkg-dev ; \
    cd /repo/; \
    dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz ; \
    '
else
podman run -it --rm -v /home/bluebanquise/repositories/ubuntu2004/x86_64/bluebanquise/:/repo/ ubuntu:20.04 /bin/bash -c ' \
    set -x ; \
    apt-get update ; \
    apt-get install -y wget dpkg-dev apt-mirror rsync ; \
    #wget http://bluebanquise.com/repository/releases/1.5-dev/ubuntu2004/x86_64/bluebanquise/bluebanquise.list ; \
    # echo "deb [trusted=yes] http://bluebanquise.com/repository/releases/1.5-dev/ubuntu2004/x86_64/bluebanquise/ ./" > bluebanquise.list ; \
    #apt-mirror bluebanquise.list ; \
    wget -np -nH --cut-dirs 5 -r --reject "index.html*" http://bluebanquise.com/repository/releases/1.5/ubuntu2004/x86_64/bluebanquise/ ; \
    rsync -a -v --ignore-times bluebanquise/packages/* /repo/packages/ ; \
    cd /repo/; \
    dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz ; \
    '
fi
