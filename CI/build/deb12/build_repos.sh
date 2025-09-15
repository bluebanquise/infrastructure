set -x
docker run --rm $PLATFORM -v $1:/repo/ $2 /bin/bash -c ' \
    set -x ; \
    [ "$(uname -m)" == "x86_64" ] && export cpu_arch="amd64" || export cpu_arch="arm64"; \
    [ "$(uname -m)" == "x86_64" ] && export folder_cpu_arch="x86_64" || export folder_cpu_arch="arm64"; \
    cd /repo/; \
    rm -Rf repo; \
    mkdir repo && cd repo && mkdir conf -p; \
    echo "Origin: BlueBanquise" > conf/distributions; \
    echo "Label: bluebanquise" >> conf/distributions; \
    echo "Codename: bookworm" >> conf/distributions; \
    echo "Suite: stable" >> conf/distributions; \
    echo "Architectures: $cpu_arch" >> conf/distributions; \
    echo "Components: main" >> conf/distributions; \
    cd /repo/$folder_cpu_arch/; \
    reprepro -b /repo/repo/ includedeb bookworm *.deb; \
    cd ../noarch/; \
    reprepro -b /repo/repo/ includedeb bookworm *.deb; \
    reprepro -b /repo/repo/ list bookworm; \
    '
