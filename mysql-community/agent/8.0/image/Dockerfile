FROM quay.io/upmio/unit-agent:v2.0-0b317c0 AS agent

FROM rockylinux/rockylinux:9.5.20241118

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
    glibc-common \
    epel-release
# generate en_US.UTF-8
RUN dnf install -y glibc-langpack-en glibc-locale-source \
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

ENV XTRABACKUP_VERSION="8.0.35-32"
ENV MYSQL_VERSION="8.0.40-1.el9"

# Download mysql80-community mysql client
RUN set -eu; \
  dnf -y install "https://repo.mysql.com/mysql80-community-release-el9.rpm"; \
  dnf config-manager --set-enabled mysql-tools-community; \
  dnf install -y "mysql-community-client-${MYSQL_VERSION}"; \
  dnf clean all; \
  mysqldump --version

# install percona xtrabackup
RUN set -ex \
  && case ${TARGETPLATFORM} in \
       "linux/amd64")  TINI_ARCH=x86_64  ;; \
       "linux/arm64")  TINI_ARCH=aarch64  ;; \
     esac \
  && dnf install -y "https://downloads.percona.com/downloads/Percona-XtraBackup-8.0/Percona-XtraBackup-${XTRABACKUP_VERSION}/binary/redhat/9/${TINI_ARCH}/percona-xtrabackup-80-${XTRABACKUP_VERSION}.1.el9.${TINI_ARCH}.rpm" \
  && dnf clean all

# install unit-agent
ENV AGENT_VERSION="v1.3.0"
COPY --from=agent /usr/local/bin/unit-agent /usr/local/bin/unit-agent
COPY --from=agent /etc/unit-agent/config.toml /etc/unit-agent/config.toml
RUN unit-agent --version

CMD ["unit-agent","daemon","-f","/etc/unit-agent/config.toml"]
