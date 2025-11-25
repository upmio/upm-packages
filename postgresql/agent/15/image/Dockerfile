FROM quay.io/upmio/unit-agent:v1.1.0 AS agent

FROM rockylinux/rockylinux:9.6.20250531

ARG BUILD_DATE
ARG VCS_REF
ARG AGENT_VERSION="v1.1.0"

LABEL org.opencontainers.image.source="https://github.com/upmio/upm-packages" \
      org.opencontainers.image.created="$BUILD_DATE" \
      org.opencontainers.image.revision="$VCS_REF" \
      org.opencontainers.image.title="postgresql-agent" \
      org.opencontainers.image.description="UPM PostgreSQL Agent image" \
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

ENV PG_VERSION="15.13"
ENV PG_MAJOR="15"
ARG TARGETPLATFORM
# Download postgresql rpm postgresql-server
RUN set -eux; \
  case "${TARGETPLATFORM}" in \
    linux/amd64)  TINI_ARCH=x86_64  ;; \
    linux/arm64)  TINI_ARCH=aarch64 ;; \
    *)            echo "Unsupported TARGETPLATFORM: ${TARGETPLATFORM}" >&2; exit 1 ;; \
  esac; \
  dnf --disablerepo='*' -y install "https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-${TINI_ARCH}/pgdg-redhat-repo-latest.noarch.rpm"; \
  dnf -qy module disable postgresql; \
  dnf install -y --setopt=install_weak_deps=False --setopt=tsflags=nodocs "postgresql${PG_MAJOR}-server-${PG_VERSION}"; \
  /usr/pgsql-${PG_MAJOR}/bin/postgres --version; \
  dnf clean all; \
  rm -rf /var/cache/dnf /var/cache/yum /var/tmp/*

ENV PATH=$PATH:/usr/pgsql-${PG_MAJOR}/bin

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
