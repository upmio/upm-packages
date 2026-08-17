FROM rockylinux/rockylinux:9.6.20250531

ARG BUILD_DATE
ARG VCS_REF
ARG TARGETARCH
ARG CLICKHOUSE_VERSION="25.8.29.51"
ARG CLICKHOUSE_REPOSITORY="https://packages.clickhouse.com/rpm/lts"
ARG CLICKHOUSE_CLIENT_SHA256_AMD64="4f8057a334302a8f20aa5d68df633c210ca8bd0330efd24a7830bd1766792ad6"
ARG CLICKHOUSE_COMMON_STATIC_SHA256_AMD64="ea80d14747d3da9403572bf76cea6da6c67848592740d94c2bfb801129c46f75"
ARG CLICKHOUSE_SERVER_SHA256_AMD64="ed627af6e6508d8f430cf16acd746127b35802aebcac627e28d837834e64ee26"
ARG CLICKHOUSE_CLIENT_SHA256_ARM64="1ef50b0e03fb2f8f7de76830728507238f551ce3e093778148dce9ba9192891d"
ARG CLICKHOUSE_COMMON_STATIC_SHA256_ARM64="5ed4412b30b1ea5578501e701118728d31ea941a380fb43e6dc5af88267b04e6"
ARG CLICKHOUSE_SERVER_SHA256_ARM64="7a5281608ffc0fd5fa09b967ca076a9c808629ff016d78dcb3590a69eb8ba1e2"

# Upstream 25.8.29.51 RPM packages are available for linux/amd64 and linux/arm64.
LABEL org.opencontainers.image.source="https://github.com/upmio/upm-packages" \
      org.opencontainers.image.created="$BUILD_DATE" \
      org.opencontainers.image.revision="$VCS_REF" \
      org.opencontainers.image.title="clickhouse-keeper" \
      org.opencontainers.image.description="UPM ClickHouse Keeper image"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux; \
  target_arch="${TARGETARCH:-$(uname -m)}"; \
  case "${target_arch}" in \
    amd64|x86_64) \
      rpm_arch="x86_64"; \
      client_sha256="${CLICKHOUSE_CLIENT_SHA256_AMD64}"; \
      common_static_sha256="${CLICKHOUSE_COMMON_STATIC_SHA256_AMD64}"; \
      server_sha256="${CLICKHOUSE_SERVER_SHA256_AMD64}" ;; \
    arm64|aarch64) \
      rpm_arch="aarch64"; \
      client_sha256="${CLICKHOUSE_CLIENT_SHA256_ARM64}"; \
      common_static_sha256="${CLICKHOUSE_COMMON_STATIC_SHA256_ARM64}"; \
      server_sha256="${CLICKHOUSE_SERVER_SHA256_ARM64}" ;; \
    *) echo "Unsupported architecture: ${target_arch}" >&2; exit 1 ;; \
  esac; \
  dnf install -y --setopt=ip_resolve=4 --setopt=optional_metadata_types=none \
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
  dnf install -y --setopt=ip_resolve=4 --setopt=optional_metadata_types=none supervisor; \
  client_rpm="clickhouse-client-${CLICKHOUSE_VERSION}.${rpm_arch}.rpm"; \
  common_rpm="clickhouse-common-static-${CLICKHOUSE_VERSION}.${rpm_arch}.rpm"; \
  server_rpm="clickhouse-server-${CLICKHOUSE_VERSION}.${rpm_arch}.rpm"; \
  curl --fail --location --retry 3 --output "/tmp/${client_rpm}" "${CLICKHOUSE_REPOSITORY}/${client_rpm}"; \
  curl --fail --location --retry 3 --output "/tmp/${common_rpm}" "${CLICKHOUSE_REPOSITORY}/${common_rpm}"; \
  curl --fail --location --retry 3 --output "/tmp/${server_rpm}" "${CLICKHOUSE_REPOSITORY}/${server_rpm}"; \
  echo "${client_sha256}  /tmp/${client_rpm}" | sha256sum --check --strict; \
  echo "${common_static_sha256}  /tmp/${common_rpm}" | sha256sum --check --strict; \
  echo "${server_sha256}  /tmp/${server_rpm}" | sha256sum --check --strict; \
  dnf install -y --setopt=install_weak_deps=False --setopt=tsflags=nodocs \
    "/tmp/${common_rpm}" "/tmp/${client_rpm}" "/tmp/${server_rpm}"; \
  clickhouse-keeper --version | grep -F "${CLICKHOUSE_VERSION}"; \
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
