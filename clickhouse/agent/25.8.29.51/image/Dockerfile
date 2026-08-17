FROM quay.io/upmio/unit-agent:v1.1.0 AS agent

FROM rockylinux/rockylinux:9.6.20250531

ARG BUILD_DATE
ARG VCS_REF
ARG TARGETARCH
ARG AGENT_VERSION="v1.1.0"
ARG CLICKHOUSE_VERSION="25.8.29.51"
ARG CLICKHOUSE_REPOSITORY="https://packages.clickhouse.com/rpm/lts"
ARG CLICKHOUSE_CLIENT_SHA256_AMD64="4f8057a334302a8f20aa5d68df633c210ca8bd0330efd24a7830bd1766792ad6"
ARG CLICKHOUSE_COMMON_STATIC_SHA256_AMD64="ea80d14747d3da9403572bf76cea6da6c67848592740d94c2bfb801129c46f75"
ARG CLICKHOUSE_CLIENT_SHA256_ARM64="1ef50b0e03fb2f8f7de76830728507238f551ce3e093778148dce9ba9192891d"
ARG CLICKHOUSE_COMMON_STATIC_SHA256_ARM64="5ed4412b30b1ea5578501e701118728d31ea941a380fb43e6dc5af88267b04e6"

# Upstream 25.8.29.51 RPM packages are available for linux/amd64 and linux/arm64.
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
