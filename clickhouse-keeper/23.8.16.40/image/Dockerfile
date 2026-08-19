FROM rockylinux/rockylinux:9.6.20250531

ARG BUILD_DATE
ARG VCS_REF
ARG TARGETARCH
ARG CLICKHOUSE_VERSION="23.8.16.40"
ARG CLICKHOUSE_REPOSITORY="https://packages.clickhouse.com/rpm/lts"
ARG CLICKHOUSE_CLIENT_SHA256_AMD64="819b6dcfcf1fd98ef6059294e305618e6381dbe4042ac2f4d332060e828d6a45"
ARG CLICKHOUSE_COMMON_STATIC_SHA256_AMD64="03422a17503bee7143f38ed70f219545057806d856992453564b0620846c0e39"
ARG CLICKHOUSE_SERVER_SHA256_AMD64="5c3c505fe88c76b18f9a97c7973206a09c1252e15917fe4a313c7d48b26fee2e"
ARG CLICKHOUSE_CLIENT_SHA256_ARM64="51a67c7085443cd92f0e17ce10613184f26d22669535de3af800e16b380e9b68"
ARG CLICKHOUSE_COMMON_STATIC_SHA256_ARM64="ab056040c6697353b375c35112b567cdbbcff222654fe6400ac17c5916e1cfdf"
ARG CLICKHOUSE_SERVER_SHA256_ARM64="ef38b480bf91982bb3637db6d332c843de5aedea94395dea4a9cb86a45198bdc"

# Upstream 23.8.16.40 RPM packages are available for linux/amd64 and linux/arm64.
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
EXPOSE 9181 9234 9363
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
