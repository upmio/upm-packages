FROM quay.io/upmio/unit-agent:v1.3.0 AS agent

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

ENV PG_MAJOR=15
ARG TARGETPLATFORM
# Download postgresql rpm postgresql-server
RUN set -ex \
  && case ${TARGETPLATFORM} in \
       "linux/amd64")  TINI_ARCH=x86_64  ;; \
       "linux/arm64")  TINI_ARCH=aarch64  ;; \
     esac \
  && dnf --disablerepo=* -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-${TINI_ARCH}/pgdg-redhat-repo-latest.noarch.rpm \
  && dnf -qy module disable postgresql \
  && dnf install -y "postgresql${PG_MAJOR}-server-${UNIT_APP_VERSION}" \
  && dnf clean all \
  && /usr/pgsql-${PG_MAJOR}/bin/postgres --version

ENV PATH=$PATH:/usr/pgsql-${PG_MAJOR}/bin

# install unit-agent
ENV AGENT_VERSION="v2.0.0"
COPY --from=agent /usr/local/bin/unit-agent /usr/local/bin/unit-agent
COPY --from=agent /etc/unit-agent/config.toml /etc/unit-agent/config.toml
RUN unit-agent --version

CMD ["unit-agent","daemon","-f","/etc/unit-agent/config.toml"]
