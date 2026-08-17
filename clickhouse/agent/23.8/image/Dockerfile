FROM quay.io/upmio/unit-agent:main-546b491 AS agent

FROM rockylinux/rockylinux:9.6.20250531

ARG BUILD_DATE
ARG VCS_REF
ARG TARGETARCH
ARG AGENT_VERSION="v1.1.0"
ARG CLICKHOUSE_VERSION="23.8.16.40"
ARG CLICKHOUSE_REPOSITORY="https://packages.clickhouse.com/rpm/lts"
ARG CLICKHOUSE_CLIENT_SHA256_AMD64="819b6dcfcf1fd98ef6059294e305618e6381dbe4042ac2f4d332060e828d6a45"
ARG CLICKHOUSE_COMMON_STATIC_SHA256_AMD64="03422a17503bee7143f38ed70f219545057806d856992453564b0620846c0e39"
ARG CLICKHOUSE_CLIENT_SHA256_ARM64="51a67c7085443cd92f0e17ce10613184f26d22669535de3af800e16b380e9b68"
ARG CLICKHOUSE_COMMON_STATIC_SHA256_ARM64="ab056040c6697353b375c35112b567cdbbcff222654fe6400ac17c5916e1cfdf"

# Upstream 23.8.16.40 RPM packages are available for linux/amd64 and linux/arm64.
LABEL org.opencontainers.image.source="https://github.com/upmio/upm-packages" \
      org.opencontainers.image.created="$BUILD_DATE" \
      org.opencontainers.image.revision="$VCS_REF" \
      org.opencontainers.image.title="clickhouse-agent" \
      org.opencontainers.image.description="UPM ClickHouse Agent image" \
      org.opencontainers.image.agent.version="$AGENT_VERSION"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux; \
  target_arch="${TARGETARCH:-$(uname -m)}"; \
  case "${target_arch}" in \
    amd64|x86_64) \
      rpm_arch="x86_64"; \
      client_sha256="${CLICKHOUSE_CLIENT_SHA256_AMD64}"; \
      common_static_sha256="${CLICKHOUSE_COMMON_STATIC_SHA256_AMD64}" ;; \
    arm64|aarch64) \
      rpm_arch="aarch64"; \
      client_sha256="${CLICKHOUSE_CLIENT_SHA256_ARM64}"; \
      common_static_sha256="${CLICKHOUSE_COMMON_STATIC_SHA256_ARM64}" ;; \
    *) echo "Unsupported architecture: ${target_arch}" >&2; exit 1 ;; \
  esac; \
  dnf install -y --setopt=ip_resolve=4 --setopt=optional_metadata_types=none \
    yum-utils \
    procps-ng \
    openssl \
    xz \
    zstd \
    net-tools \
    hostname \
    telnet \
    wget \
    glibc-common \
    glibc-langpack-en \
    glibc-locale-source \
    ca-certificates \
    awscli; \
  client_rpm="clickhouse-client-${CLICKHOUSE_VERSION}.${rpm_arch}.rpm"; \
  common_rpm="clickhouse-common-static-${CLICKHOUSE_VERSION}.${rpm_arch}.rpm"; \
  curl --fail --location --retry 3 --output "/tmp/${client_rpm}" "${CLICKHOUSE_REPOSITORY}/${client_rpm}"; \
  curl --fail --location --retry 3 --output "/tmp/${common_rpm}" "${CLICKHOUSE_REPOSITORY}/${common_rpm}"; \
  echo "${client_sha256}  /tmp/${client_rpm}" | sha256sum --check --strict; \
  echo "${common_static_sha256}  /tmp/${common_rpm}" | sha256sum --check --strict; \
  dnf install -y --setopt=install_weak_deps=False --setopt=tsflags=nodocs \
    "/tmp/${common_rpm}" "/tmp/${client_rpm}"; \
  clickhouse-client --version | grep -F "${CLICKHOUSE_VERSION}"; \
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
  groupadd --system --gid 1001 unit-agent; \
  useradd --system --uid 1001 --gid 1001 -m -c "Default Application User" unit-agent

WORKDIR /home/unit-agent
COPY --from=agent /usr/local/bin/unit-agent /usr/local/bin/unit-agent
COPY --from=agent /opt/unit-agent/config.toml /opt/unit-agent/config.toml

CMD ["unit-agent","daemon","-f","/opt/unit-agent/config.toml"]

USER unit-agent
EXPOSE 2214
