FROM docker.io/opensuse/leap:16
RUN zypper -n install git 
RUN mkdir /infra
RUN git clone https://github.com/bluebanquise/infrastructure.git /infra
RUN chmod +x /infra/auto_builder.sh
RUN /infra/auto_builder.sh dependencies opensuse_leap 16
ENTRYPOINT ["/infra/auto_builder.sh"]
