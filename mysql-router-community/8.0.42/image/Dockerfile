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
  dnf install -y supervisor \
  && dnf clean all

# Download MySQL
ENV UNIT_APP_VERSION="8.0.42"
ENV MYSQL_VERSION="${UNIT_APP_VERSION}-1.el9"

# MySQL image for UPM.
ENV SUMMARY="MySQL Router Community Edition" \
  DESCRIPTION="MySQL Router is part of InnoDB Cluster, and is lightweight middleware that provides transparent routing between your application and back-end MySQL Servers."

LABEL summary="${SUMMARY}" \
  description="${DESCRIPTION}" \
  io.k8s.description="${DESCRIPTION}" \
  io.k8s.display-name="mysql router ${UNIT_APP_VERSION}" \
  type="mysql-router" \
  edition="Community" \
  version="${UNIT_APP_VERSION}" \
  maintainer="upm"

RUN set -eux; \
  groupadd --system --gid 1001 "mysql-router"; \
  useradd --system --uid 1001 --gid 1001 -m -c "Default Application User" "mysql-router"

# Download mysql80-community mysql-shell and mysql-router
RUN set -eu; \
  dnf -y install "https://repo.mysql.com/mysql80-community-release-el9.rpm"; \
  dnf config-manager --set-enabled mysql-tools-community; \
  dnf install -y "mysql-shell-${MYSQL_VERSION}" "mysql-router-community-${MYSQL_VERSION}"; \
  dnf clean all; \
  mysqlsh --version

COPY service-ctl.sh /usr/local/bin/
RUN chown 1001:1001 /usr/local/bin/service-ctl.sh && chmod +x /usr/local/bin/service-ctl.sh

COPY supervisord.conf /etc/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

USER 1001
