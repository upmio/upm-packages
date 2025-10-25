FROM rockylinux/rockylinux:9.6.20250531 AS builder

# set timezone
ENV TZ=Asia/Shanghai \
    PGBOUNCER_BASE_DIR="/usr/local/pgbouncer"

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
  && echo "$TZ" > /etc/timezone

# install common tools
# install build deps
# hadolint ignore=DL3041
RUN set -eux; \
  dnf install -y \
    openssl-devel \
    libevent-devel \
    make \
    gcc \
  && dnf clean all

# Download and extract pgbouncer sources
RUN mkdir -p "${PGBOUNCER_BASE_DIR}" \
  && curl --retry 10 -S -L --output "/tmp/pgbouncer.tar.gz" "https://www.pgbouncer.org/downloads/files/1.23.1/pgbouncer-1.23.1.tar.gz" \
  && tar -zxf /tmp/pgbouncer.tar.gz -C /tmp/

# Build and install pgbouncer
WORKDIR /tmp/pgbouncer-1.23.1
RUN ./configure --prefix="${PGBOUNCER_BASE_DIR}" \
  && make \
  && make install

FROM rockylinux/rockylinux:9.6.20250531

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
ENV UNIT_APP_VERSION="1.23.1"
ENV PG_MAJOR=16

# PgBouncer image for UPM.
ENV SUMMARY="Lightweight connection pooler for PostgreSQL" \
  DESCRIPTION="pgbouncer is a PostgreSQL connection pooler. \
  Any target application can be connected to pgbouncer as if it were a PostgreSQL server, \
  and pgbouncer will create a connection to the actual server, or it will reuse one of its existing connections." \
  PGBOUNCER_BASE_DIR="/usr/local/pgbouncer"

LABEL summary="${SUMMARY}" \
  description="${DESCRIPTION}" \
  io.k8s.description="${DESCRIPTION}" \
  io.k8s.display-name="pgbouncer ${UNIT_APP_VERSION}" \
  type="pgbouncer" \
  version="${UNIT_APP_VERSION}" \
  maintainer="upm"

RUN set -eux; \
  groupadd --system --gid 1001 "pgbouncer"; \
  useradd --system --uid 1001 --gid 1001 -m -c "Default Application User" "pgbouncer"

ARG TARGETPLATFORM
# install postgresql client
# hadolint ignore=DL3041
RUN set -ex \
  && case "${TARGETPLATFORM}" in \
       "linux/amd64")  TINI_ARCH=x86_64  ;; \
       "linux/arm64")  TINI_ARCH=aarch64  ;; \
     esac \
  && dnf --disablerepo=* -y install "https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-${TINI_ARCH}/pgdg-redhat-repo-latest.noarch.rpm" \
  && dnf -qy module disable postgresql \
  && dnf install -y "postgresql${PG_MAJOR}" \
  && dnf clean all \
  && /usr/pgsql-${PG_MAJOR}/bin/psql --version

COPY --from=builder "${PGBOUNCER_BASE_DIR}" "${PGBOUNCER_BASE_DIR}"

ENV PATH=$PATH:${PGBOUNCER_BASE_DIR}/bin

COPY service-ctl.sh /usr/local/bin/
COPY supervisord.conf /etc/supervisord.conf

RUN set -eux; \
  chown -R 1001:1001 "${PGBOUNCER_BASE_DIR}"; \
  chown 1001:1001 /usr/local/bin/service-ctl.sh; \
  chmod +x /usr/local/bin/service-ctl.sh; \
  chown 1001:1001 /etc/supervisord.conf

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

USER 1001
