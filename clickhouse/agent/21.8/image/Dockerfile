FROM quay.io/upmio/unit-agent:main-546b491 AS agent
# Rebuild against the business-backup agent.

FROM rockylinux/rockylinux:9.6.20250531

ARG BUILD_DATE
ARG VCS_REF
ARG TARGETARCH
ARG AGENT_VERSION="v1.1.0"
ARG CLICKHOUSE_VERSION="21.8.15.7"
ARG CLICKHOUSE_RELEASE="2"
ARG CLICKHOUSE_REPOSITORY="https://packages.clickhouse.com/rpm/lts"
ARG CLICKHOUSE_CLIENT_SHA256="d449dd91a4ec33181bbf16205fe99b39ad6b1f1b4bafea3d63f597ed643485f7"
ARG CLICKHOUSE_COMMON_STATIC_SHA256="6dc4786865520f9fcd64bcc74df2e63e3c08a3ed92809ee56bf81ea76ece8c57"

# Upstream 21.8.15.7 RPM packages are available only for linux/amd64.
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
    amd64|x86_64) ;; \
    *) echo "ClickHouse ${CLICKHOUSE_VERSION} upstream packages support linux/amd64 only, got ${target_arch}" >&2; exit 1 ;; \
  esac; \
  dnf install -y --setopt=install_weak_deps=False --setopt=tsflags=nodocs \
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
  client_rpm="clickhouse-client-${CLICKHOUSE_VERSION}-${CLICKHOUSE_RELEASE}.noarch.rpm"; \
  common_rpm="clickhouse-common-static-${CLICKHOUSE_VERSION}-${CLICKHOUSE_RELEASE}.x86_64.rpm"; \
  curl --fail --location --retry 3 --output "/tmp/${client_rpm}" "${CLICKHOUSE_REPOSITORY}/${client_rpm}"; \
  curl --fail --location --retry 3 --output "/tmp/${common_rpm}" "${CLICKHOUSE_REPOSITORY}/${common_rpm}"; \
  echo "${CLICKHOUSE_CLIENT_SHA256}  /tmp/${client_rpm}" | sha256sum --check --strict; \
  echo "${CLICKHOUSE_COMMON_STATIC_SHA256}  /tmp/${common_rpm}" | sha256sum --check --strict; \
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
