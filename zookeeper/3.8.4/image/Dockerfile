FROM rockylinux/rockylinux:9.6.20250531

# install common tools
# hadolint ignore=DL3041
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
    glibc-common \
    nmap-ncat \
    epel-release \
  && dnf clean all
# generate en_US.UTF-8
RUN dnf install -y glibc-langpack-en glibc-locale-source \
  && dnf clean all \
  && localedef -i en_US -f UTF-8 en_US.UTF-8

# set timezone
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
  && echo "$TZ" > /etc/timezone

# set default locale
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# install supervisor
# hadolint ignore=DL3041
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
  type="zookeeper" \
  version="${UNIT_APP_VERSION}" \
  maintainer="upm"

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
ARG SHORT_DISTRO_NAME=zookeeper-${UNIT_APP_VERSION}
ARG DISTRO_NAME=apache-zookeeper-${UNIT_APP_VERSION}-bin
RUN set -eux; \
  GPG_KEY="AF3D175EC05DB249738D01AC8D8C3C3ED0B02E66"; \
  dist() { \
    f="$1"; shift; \
    distFile="$1"; shift; \
    success=''; \
    distUrl=''; \
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
    dist "$DISTRO_NAME.tar.gz" "zookeeper/$SHORT_DISTRO_NAME/$DISTRO_NAME.tar.gz"; \
    dist "$DISTRO_NAME.tar.gz.asc" "zookeeper/$SHORT_DISTRO_NAME/$DISTRO_NAME.tar.gz.asc"; \
    GNUPGHOME="$(mktemp -d)"; export GNUPGHOME; \
    gpg --keyserver hkps://keyserver.pgp.com --recv-key "$GPG_KEY" || \
    gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys "$GPG_KEY" || \
    gpg --keyserver hkps://pgp.mit.edu --recv-keys "$GPG_KEY"; \
    gpg --batch --verify "$DISTRO_NAME.tar.gz.asc" "$DISTRO_NAME.tar.gz"; \
    tar -zxf "$DISTRO_NAME.tar.gz"; \
    rm -rf "$GNUPGHOME" "$DISTRO_NAME.tar.gz" "$DISTRO_NAME.tar.gz.asc"; \
    chown -R 1001:1001 "/$DISTRO_NAME"

ENV PATH=$PATH:/$DISTRO_NAME/bin

COPY service-ctl.sh /usr/local/bin/
RUN chown 1001:1001 /usr/local/bin/service-ctl.sh && chmod +x /usr/local/bin/service-ctl.sh

COPY supervisord.conf /etc/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

USER 1001
