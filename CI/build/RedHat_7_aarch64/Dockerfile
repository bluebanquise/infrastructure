FROM docker.io/centos:7
RUN yum install git -y
RUN mkdir /infra
RUN git clone https://github.com/bluebanquise/infrastructure.git /infra
RUN chmod +x /infra/auto_builder.sh
RUN /infra/auto_builder.sh dependencies RedHat 7
ENTRYPOINT ["/infra/auto_builder.sh"]
