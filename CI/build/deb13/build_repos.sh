set -x
docker run --rm $PLATFORM -v $1:/repo/ $2 /bin/bash -c ' \
    set -x ; \
    export cpu_arch="$(dpkg --print-architecture)"; \
    export folder_cpu_arch="$(uname -m)"; \
    cd /repo/; \
    rm -Rf repo; \
    mkdir repo && cd repo && mkdir conf -p; \
    echo "Origin: BlueBanquise" > conf/distributions; \
    echo "Label: bluebanquise" >> conf/distributions; \
    echo "Codename: trixie" >> conf/distributions; \
    echo "Suite: stable" >> conf/distributions; \
    echo "Architectures: $cpu_arch" >> conf/distributions; \
    echo "Components: main" >> conf/distributions; \
    cd /repo/$folder_cpu_arch/; \
    reprepro -b /repo/repo/ includedeb trixie *.deb; \
    cd ../noarch/; \
    reprepro -b /repo/repo/ includedeb trixie *.deb; \
    reprepro -b /repo/repo/ list trixie; \
    rm -Rf /repo/$folder_cpu_arch
    rm -Rf /repo/noarch
    $(which cp) -rf /repo/repo/* /repo
    rm -Rf /repo/repo
    '
