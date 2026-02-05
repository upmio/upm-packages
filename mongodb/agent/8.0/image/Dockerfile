FROM quay.io/upmio/unit-agent:v1.1.0 AS agent

FROM rockylinux/rockylinux:9.6.20250531

ARG BUILD_DATE
ARG VCS_REF
ARG AGENT_VERSION="v1.1.0"

LABEL org.opencontainers.image.source="https://github.com/upmio/upm-packages" \
      org.opencontainers.image.created="$BUILD_DATE" \
      org.opencontainers.image.revision="$VCS_REF" \
      org.opencontainers.image.title="mongodb-agent" \
      org.opencontainers.image.description="UPM MongoDB Agent image" \
      org.opencontainers.image.agent.version="$AGENT_VERSION"

# Ensure robust shell behavior for all RUN instructions
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

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

ARG TARGETOS
ARG TARGETARCH
ARG TARGETPLATFORM

ENV MONGODB_TOOL_VERSION="100.14.0"

# Download mongodb database tools
RUN set -eux; \
  printf '%s\n' \
    '[mongodb-org-8.0]' \
    'name=MongoDB Repository' \
    'baseurl=https://repo.mongodb.org/yum/redhat/9/mongodb-org/8.0/$basearch/' \
    'gpgcheck=1' \
    'enabled=1' \
    'gpgkey=https://pgp.mongodb.com/server-8.0.asc' \
    > /etc/yum.repos.d/mongodb-org-8.0.repo; \
  dnf -y install --setopt=install_weak_deps=False --setopt=tsflags=nodocs \
    mongodb-database-tools-${MONGODB_TOOL_VERSION}-1; \
  dnf clean all; \
  rm -rf /var/cache/dnf

# add user and group
RUN set -eux; \
  groupadd --system --gid 1001 "unit-agent"; \
  useradd --system --uid 1001 --gid 1001 -m -c "Default Application User" "unit-agent";

WORKDIR /home/unit-agent
COPY --from=agent /usr/local/bin/unit-agent /usr/local/bin/unit-agent
COPY --from=agent /opt/unit-agent/config.toml /opt/unit-agent/config.toml

CMD ["unit-agent","daemon","-f","/opt/unit-agent/config.toml"]

USER unit-agent
EXPOSE 2214
