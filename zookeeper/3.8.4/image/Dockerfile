FROM rockylinux/rockylinux:9.5.20241118

# set timezone
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
  && echo "$TZ" > /etc/timezone

# install common tools
RUN set -eux; \
  dnf install -y \
    procps-ng \
    nmap-ncat \
    bzip2 \
    openssl \
    xz \
    zstd \
    net-tools \
    telnet \
    wget \
    epel-release

RUN set -eux; \
  dnf install -y supervisor; \
  dnf clean all

ENV SUMMARY="ZooKeeper is an effort to develop and maintain an open-source server which enables highly reliable distributed coordination" \
  DESCRIPTION="ZooKeeper is a centralized service for maintaining configuration information, naming, providing distributed synchronization, and providing group services. \
All of these kinds of services are used in some form or another by distributed applications." \
  UNIT_APP_VERSION="3.8.4"

LABEL summary="${SUMMARY}" \
      description="${DESCRIPTION}" \
      io.k8s.description="${DESCRIPTION}" \
      io.k8s.display-name="zookeeper ${UNIT_APP_VERSION}" \
      name="UPM/zookeeper" \
      version="${UNIT_APP_VERSION}" \
      maintainer="upmio"

RUN set -eux; \
  groupadd --system --gid 1001 "zookeeper"; \
  useradd --system --uid 1001 --gid 1001 --no-create-home -s /sbin/nologin -c "Default Application User" "zookeeper"

# install java 11
RUN set -eux; \
  dnf install -y \
   java-11-openjdk \
   java-11-openjdk-devel \
   tzdata-java; \
  dnf clean all

# Download Apache Zookeeper, verify its PGP signature, untar and clean up
ARG GPG_KEY=AF3D175EC05DB249738D01AC8D8C3C3ED0B02E66
ARG SHORT_DISTRO_NAME=zookeeper-${UNIT_APP_VERSION}
ARG DISTRO_NAME=apache-zookeeper-${UNIT_APP_VERSION}-bin
RUN set -eux; \
    ddist() { \
        local f="$1"; shift; \
        local distFile="$1"; shift; \
        local success=; \
        local distUrl=; \
        for distUrl in \
            'https://www.apache.org/dyn/closer.cgi?action=download&filename=' \
            https://www-us.apache.org/dist/ \
            https://www.apache.org/dist/ \
            https://archive.apache.org/dist/ \
        ; do \
            if wget -q -O "$f" "$distUrl$distFile" && [ -s "$f" ]; then \
                success=1; \
                break; \
            fi; \
        done; \
        [ -n "$success" ]; \
    }; \
    ddist "$DISTRO_NAME.tar.gz" "zookeeper/$SHORT_DISTRO_NAME/$DISTRO_NAME.tar.gz"; \
    ddist "$DISTRO_NAME.tar.gz.asc" "zookeeper/$SHORT_DISTRO_NAME/$DISTRO_NAME.tar.gz.asc"; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --keyserver hkps://keyserver.pgp.com --recv-key "$GPG_KEY" || \
    gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys "$GPG_KEY" || \
    gpg --keyserver hkps://pgp.mit.edu --recv-keys "$GPG_KEY"; \
    gpg --batch --verify "$DISTRO_NAME.tar.gz.asc" "$DISTRO_NAME.tar.gz"; \
    tar -zxf "$DISTRO_NAME.tar.gz"; \
    rm -rf "$GNUPGHOME" "$DISTRO_NAME.tar.gz" "$DISTRO_NAME.tar.gz.asc"; \
    chown -R zookeeper:zookeeper "/$DISTRO_NAME"

ENV PATH=$PATH:/$DISTRO_NAME/bin

COPY service-ctl.sh /usr/local/bin/
RUN chown 1001:1001 /usr/local/bin/service-ctl.sh && chmod +x /usr/local/bin/service-ctl.sh

COPY supervisord.conf /etc/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]