FROM quay.io/upmio/unit-agent:v1.1.0 AS agent
# Keep all ClickHouse versions on the same agent implementation.

FROM rockylinux/rockylinux:9.6.20250531

ARG BUILD_DATE
ARG VCS_REF
ARG AGENT_VERSION="v1.1.0"
ARG CLICKHOUSE_VERSION="26.3.9.8"

LABEL org.opencontainers.image.source="https://github.com/upmio/upm-packages" \
      org.opencontainers.image.created="$BUILD_DATE" \
      org.opencontainers.image.revision="$VCS_REF" \
      org.opencontainers.image.title="clickhouse-agent" \
      org.opencontainers.image.description="UPM ClickHouse Agent image" \
      org.opencontainers.image.agent.version="$AGENT_VERSION"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux; \
  dnf install -y \
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
  yum-config-manager --add-repo https://packages.clickhouse.com/rpm/clickhouse.repo; \
  dnf install -y --setopt=install_weak_deps=False --setopt=tsflags=nodocs "clickhouse-client-26.3.9.8"; \
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
  groupadd --system --gid 1001 unit-agent; \
  useradd --system --uid 1001 --gid 1001 -m -c "Default Application User" unit-agent

WORKDIR /home/unit-agent
COPY --from=agent /usr/local/bin/unit-agent /usr/local/bin/unit-agent
COPY --from=agent /opt/unit-agent/config.toml /opt/unit-agent/config.toml

CMD ["unit-agent","daemon","-f","/opt/unit-agent/config.toml"]

USER unit-agent
EXPOSE 2214
