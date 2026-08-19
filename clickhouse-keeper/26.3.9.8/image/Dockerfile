FROM rockylinux/rockylinux:9.6.20250531

ARG BUILD_DATE
ARG VCS_REF
ARG CLICKHOUSE_VERSION="26.3.9.8"

LABEL org.opencontainers.image.source="https://github.com/upmio/upm-packages" \
      org.opencontainers.image.created="$BUILD_DATE" \
      org.opencontainers.image.revision="$VCS_REF" \
      org.opencontainers.image.title="clickhouse-keeper" \
      org.opencontainers.image.description="UPM ClickHouse Keeper image"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux; \
  dnf install -y \
    yum-utils \
    procps-ng \
    openssl \
    net-tools \
    hostname \
    telnet \
    wget \
    glibc-common \
    glibc-langpack-en \
    glibc-locale-source \
    epel-release; \
  dnf install -y supervisor; \
  yum-config-manager --add-repo https://packages.clickhouse.com/rpm/clickhouse.repo; \
  dnf install -y --setopt=install_weak_deps=False --setopt=tsflags=nodocs "clickhouse-keeper-${CLICKHOUSE_VERSION}"; \
  dnf clean all; \
  rm -rf /var/cache/dnf /var/cache/yum /var/tmp/*; \
  localedef -i en_US -f UTF-8 en_US.UTF-8

ENV TZ=Asia/Shanghai
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

RUN set -eux; \
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime; \
  echo "$TZ" > /etc/timezone; \
  groupadd --system --gid 1001 unit-app; \
  useradd --system --uid 1001 --gid 1001 -m -c "Default Application User" unit-app

COPY service-ctl.sh /usr/local/bin/service-ctl.sh
COPY supervisord.conf /etc/supervisord.conf

RUN chmod +x /usr/local/bin/service-ctl.sh

USER unit-app
EXPOSE 9181 9234 9363
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
