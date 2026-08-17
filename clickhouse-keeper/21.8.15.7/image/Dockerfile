FROM rockylinux/rockylinux:9.6.20250531

ARG BUILD_DATE
ARG VCS_REF
ARG TARGETARCH
ARG CLICKHOUSE_VERSION="21.8.15.7"
ARG CLICKHOUSE_RELEASE="2"
ARG CLICKHOUSE_REPOSITORY="https://packages.clickhouse.com/rpm/lts"
ARG CLICKHOUSE_CLIENT_SHA256="d449dd91a4ec33181bbf16205fe99b39ad6b1f1b4bafea3d63f597ed643485f7"
ARG CLICKHOUSE_COMMON_STATIC_SHA256="6dc4786865520f9fcd64bcc74df2e63e3c08a3ed92809ee56bf81ea76ece8c57"
ARG CLICKHOUSE_SERVER_SHA256="b8568ad49552741c2ea057848a45e4d83930711144d8bb81a4c150e553956856"

LABEL org.opencontainers.image.source="https://github.com/upmio/upm-packages" \
      org.opencontainers.image.created="$BUILD_DATE" \
      org.opencontainers.image.revision="$VCS_REF" \
      org.opencontainers.image.title="clickhouse-keeper" \
      org.opencontainers.image.description="UPM ClickHouse Keeper image"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux; \
  target_arch="${TARGETARCH:-$(uname -m)}"; \
  case "${target_arch}" in \
    amd64|x86_64) ;; \
    *) echo "ClickHouse ${CLICKHOUSE_VERSION} upstream packages support linux/amd64 only, got ${target_arch}" >&2; exit 1 ;; \
  esac; \
  dnf install -y \
    yum-utils \
    procps-ng \
    openssl \
    net-tools \
    hostname \
    telnet \
    glibc-common \
    glibc-langpack-en \
    glibc-locale-source \
    epel-release; \
  dnf install -y supervisor; \
  client_rpm="clickhouse-client-${CLICKHOUSE_VERSION}-${CLICKHOUSE_RELEASE}.noarch.rpm"; \
  common_rpm="clickhouse-common-static-${CLICKHOUSE_VERSION}-${CLICKHOUSE_RELEASE}.x86_64.rpm"; \
  server_rpm="clickhouse-server-${CLICKHOUSE_VERSION}-${CLICKHOUSE_RELEASE}.noarch.rpm"; \
  curl --fail --location --retry 3 --output "/tmp/${client_rpm}" "${CLICKHOUSE_REPOSITORY}/${client_rpm}"; \
  curl --fail --location --retry 3 --output "/tmp/${common_rpm}" "${CLICKHOUSE_REPOSITORY}/${common_rpm}"; \
  curl --fail --location --retry 3 --output "/tmp/${server_rpm}" "${CLICKHOUSE_REPOSITORY}/${server_rpm}"; \
  echo "${CLICKHOUSE_CLIENT_SHA256}  /tmp/${client_rpm}" | sha256sum --check --strict; \
  echo "${CLICKHOUSE_COMMON_STATIC_SHA256}  /tmp/${common_rpm}" | sha256sum --check --strict; \
  echo "${CLICKHOUSE_SERVER_SHA256}  /tmp/${server_rpm}" | sha256sum --check --strict; \
  dnf install -y --setopt=install_weak_deps=False --setopt=tsflags=nodocs \
    "/tmp/${common_rpm}" "/tmp/${client_rpm}" "/tmp/${server_rpm}"; \
  clickhouse keeper --version | grep -F "${CLICKHOUSE_VERSION}"; \
  dnf clean all; \
  rm -rf /var/cache/dnf /var/cache/yum /var/tmp/* /tmp/*.rpm; \
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
EXPOSE 9181 9234
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
