FROM rockylinux/rockylinux:9.5.20241118 AS builder

# set timezone
ENV TZ=Asia/Shanghai \
    PGBOUNCER_BASE_DIR="/usr/local/pgbouncer"

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
  && echo "$TZ" > /etc/timezone

# install common tools
RUN set -eux; \
  dnf install -y \
    openssl-devel \
    libevent-devel \
    make \
    gcc

# Download pgbouncer package
RUN mkdir -p "${PGBOUNCER_BASE_DIR}" \
  && curl --retry 10 -S -L --output "/tmp/pgbouncer.tar.gz" https://www.pgbouncer.org/downloads/files/1.24.1/pgbouncer-1.24.1.tar.gz \
  && tar -zxf /tmp/pgbouncer.tar.gz -C /tmp/ \
  && cd /tmp/pgbouncer-1.24.1 \
  && ./configure --prefix="${PGBOUNCER_BASE_DIR}" \
  && make \
  && make install

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

# install supervisor
RUN set -eux; \
  dnf install -y supervisor

# Download PostgreSQL
ENV UNIT_APP_VERSION="1.24.1"
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
# Install postgresql client
RUN set -ex \
  && case ${TARGETPLATFORM} in \
       "linux/amd64")  TINI_ARCH=x86_64  ;; \
       "linux/arm64")  TINI_ARCH=aarch64  ;; \
     esac \
  && dnf --disablerepo=* -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-${TINI_ARCH}/pgdg-redhat-repo-latest.noarch.rpm \
  && dnf -qy module disable postgresql \
  && dnf install -y "postgresql${PG_MAJOR}" \
  && dnf clean all \
  && /usr/pgsql-${PG_MAJOR}/bin/psql --version

COPY --from=builder "${PGBOUNCER_BASE_DIR}" "${PGBOUNCER_BASE_DIR}"

# Download pgbouncer package
RUN chown -R "1001:1001" "${PGBOUNCER_BASE_DIR}"

ENV PATH=$PATH:${PGBOUNCER_BASE_DIR}/bin

COPY service-ctl.sh /usr/local/bin/
RUN chown 1001:1001 /usr/local/bin/service-ctl.sh && chmod +x /usr/local/bin/service-ctl.sh

COPY supervisord.conf /etc/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
USER 1001
