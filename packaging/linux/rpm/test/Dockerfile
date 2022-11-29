FROM centos:7

RUN adduser seal

RUN mkdir /etc/sudoers.d

COPY ./output /output

RUN yum -y --nogpgcheck localinstall /output/*.rpm

CMD [ "/bin/bash" ]
