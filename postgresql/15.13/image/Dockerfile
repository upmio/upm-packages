FROM rockylinux/rockylinux:9.6.20250531
# hadolint global ignore=DL3059

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

# install supervisor
# hadolint ignore=DL3041
RUN set -eux; \
  dnf install -y supervisor \
  && dnf clean all

# Download PostgreSQL
ENV UNIT_APP_VERSION="15.13"
ENV PG_MAJOR=15

# PostgreSQL image for UPM.
ENV SUMMARY="PostgreSQL SQL database server" \
  DESCRIPTION="PostgreSQL is a powerful, open source object-relational database system \
  with over 35 years of active development that has earned it a strong reputation for \
  reliability, feature robustness, and performance."

LABEL summary="${SUMMARY}" \
  description="${DESCRIPTION}" \
  io.k8s.description="${DESCRIPTION}" \
  io.k8s.display-name="postgresql ${UNIT_APP_VERSION}" \
  type="postgresql" \
  version="${UNIT_APP_VERSION}" \
  maintainer="upm"

RUN set -eux; \
  groupadd --system --gid 1001 "postgres"; \
  useradd --system --uid 1001 --gid 1001 -m -c "Default Application User" "postgres"

ARG TARGETPLATFORM
# Download postgresql rpm postgresql-server
RUN set -ex \
  && case "${TARGETPLATFORM}" in \
       "linux/amd64")  TINI_ARCH=x86_64  ;; \
       "linux/arm64")  TINI_ARCH=aarch64  ;; \
     esac \
  && dnf --disablerepo=* -y install "https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-${TINI_ARCH}/pgdg-redhat-repo-latest.noarch.rpm" \
  && dnf -qy module disable postgresql \
  && dnf install -y "postgresql${PG_MAJOR}-server-${UNIT_APP_VERSION}" \
  && dnf clean all \
  && /usr/pgsql-${PG_MAJOR}/bin/postgres --version

ENV PATH=$PATH:/usr/pgsql-${PG_MAJOR}/bin

COPY service-ctl.sh /usr/local/bin/
COPY supervisord.conf /etc/supervisord.conf

RUN set -eux; \
  chown 1001:1001 /usr/local/bin/service-ctl.sh; \
  chmod +x /usr/local/bin/service-ctl.sh; \
  chown 1001:1001 /etc/supervisord.conf

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

USER 1001
