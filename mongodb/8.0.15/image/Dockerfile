FROM rockylinux/rockylinux:9.6.20250531

# set timezone
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
  && echo "$TZ" > /etc/timezone

# install common tools
RUN set -eux; \
  dnf install -y \
    procps-ng \
    bzip2 \
    openssl \
    xz \
    zstd \
    net-tools \
    hostname \
    telnet \
    wget \
    epel-release

RUN set -eux; \
  dnf install -y supervisor; \
  dnf clean all

ENV UNIT_APP_VERSION="8.0.15" \
    MONGOSH_VERSION="2.5.8" \
    SUMMARY="MongoDB NoSQL database" \
    DESCRIPTION="MongoDB is a general purpose, document-based, distributed database built for modern application developers and for the cloud era."

LABEL summary="${SUMMARY}" \
      description="${DESCRIPTION}" \
      io.k8s.description="${DESCRIPTION}" \
      io.k8s.display-name="mongodb ${UNIT_APP_VERSION}" \
      name="UPM/mongodb" \
      version="${UNIT_APP_VERSION}" \
      maintainer="upm"

RUN set -eux; \
  groupadd --system --gid 1001 "mongod"; \
  useradd --system --uid 1001 --gid 1001 -c "Default Application User" "mongod"

# Configure MongoDB repository and install MongoDB server
RUN set -eux; \
  echo "[mongodb-org-8.0]" > /etc/yum.repos.d/mongodb-org.repo; \
  echo "name=MongoDB Repository" >> /etc/yum.repos.d/mongodb-org.repo; \
  echo "baseurl=https://repo.mongodb.org/yum/redhat/9/mongodb-org/8.0/\$basearch/" >> /etc/yum.repos.d/mongodb-org.repo; \
  echo "gpgcheck=1" >> /etc/yum.repos.d/mongodb-org.repo; \
  echo "enabled=1" >> /etc/yum.repos.d/mongodb-org.repo; \
  echo "gpgkey=https://pgp.mongodb.com/server-8.0.asc" >> /etc/yum.repos.d/mongodb-org.repo; \
  dnf -y install mongodb-org-server-${UNIT_APP_VERSION} mongodb-mongosh-${MONGOSH_VERSION}; \
  dnf clean all; \
  mongod --version

COPY service-ctl.sh /usr/local/bin/
COPY supervisord.conf /etc/supervisord.conf

RUN set -eux; \
  chown 1001:1001 /usr/local/bin/service-ctl.sh; \
  chmod +x /usr/local/bin/service-ctl.sh; \
  chown 1001:1001 /etc/supervisord.conf

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

USER 1001
