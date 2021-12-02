# Infrastructure

<p align="center">
  <img src="https://i.pinimg.com/originals/aa/8e/8c/aa8e8c57325952dcd28cd654bd4539e7.gif" alt="Factorio"/>
</p>

This repository hosts the BlueBanquise factory, to build packages and other stack needed elements.

To generate all latest repositories, you need a cluster composed of 2 servers:

* aarch64_worker which is an aarch64/arm64 system
* x86_64_worker which is an x86_64/amd64 system

Then simply run `CI/engine.sh`. The script will need a passwordless ssh access to bluebanquise@aarch64_worker and bluebanquise@x86_64_worker.
Both worker need to have podman >= 2 installed, and be able to grab files/git clone from the web.

At the end, repositories are stored in `~/CI/repositories` on system where script is executed. Note that if using a small board like a Raspberry Pi 3 to build aarch64 packages, the whole process takes a lot of time.
