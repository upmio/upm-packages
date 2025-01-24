FROM quay.io/upmio/unit-agent:v1.3.0 AS agent

FROM rockylinux/rockylinux:8.10

# set timezone
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
  && echo "$TZ" > /etc/timezone

# install common tools
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
    epel-release

# install unit-agent
ENV AGENT_VERSION="1.3.0"
COPY --from=agent /usr/local/bin/unit-agent /usr/local/bin/unit-agent
COPY --from=agent /etc/unit-agent/config.toml /etc/unit-agent/config.toml
RUN unit-agent --version

ARG TARGETOS
ARG TARGETARCH
ARG TARGETPLATFORM

ENV XTRABACKUP_VERSION="8.0.35-32"

# install percona xtrabackup
RUN set -ex \
  && case ${TARGETPLATFORM} in \
       "linux/amd64")  TINI_ARCH=x86_64  ;; \
       "linux/arm64")  TINI_ARCH=aarch64  ;; \
     esac \
  && dnf install -y "https://downloads.percona.com/downloads/Percona-XtraBackup-8.0/Percona-XtraBackup-${XTRABACKUP_VERSION}/binary/redhat/8/${TINI_ARCH}/percona-xtrabackup-80-${XTRABACKUP_VERSION}.1.el8.${TINI_ARCH}.rpm" \
  && dnf clean all

COPY toolkit /usr/local/bin/
RUN chmod +x /usr/local/bin/toolkit

CMD ["unit-agent","daemon","-f","/etc/unit-agent/config.toml"]