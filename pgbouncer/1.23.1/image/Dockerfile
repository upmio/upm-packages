FROM rockylinux/rockylinux:9.5.20241118 AS builder

# set timezone
ENV TZ=Asia/Shanghai \
    PGBOUNCER_BASE_DIR="/usr/local/pgbouncer"


# PgBouncer env
ENV PGBOUNCER_MAJOR=1.23.1
ENV PG_MAJOR=16


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
  && curl --retry 10 -S -L --output "/tmp/pgbouncer.tar.gz" https://www.pgbouncer.org/downloads/files/1.23.1/pgbouncer-1.23.1.tar.gz \
  && tar -zxf /tmp/pgbouncer.tar.gz -C /tmp/ \
  && cd /tmp/pgbouncer-1.23.1 \
  && ./configure --prefix="${PGBOUNCER_BASE_DIR}" \
  && make \
  && make install

FROM rockylinux/rockylinux:9.5.20241118

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
    epel-release \
    libevent-devel

# install supervisor
RUN set -eux; \
  dnf install -y supervisor


# PgBouncer image for UPM.
ENV SUMMARY="Lightweight connection pooler for PostgreSQL" \
  DESCRIPTION="pgbouncer is a PostgreSQL connection pooler. \
  Any target application can be connected to pgbouncer as if it were a PostgreSQL server, \
  and pgbouncer will create a connection to the actual server, or it will reuse one of its existing connections." \
  PGBOUNCER_BASE_DIR="/usr/local/pgbouncer"

LABEL summary="${SUMMARY}" \
  description="${DESCRIPTION}" \
  io.k8s.description="${DESCRIPTION}" \
  io.k8s.display-name="pgbouncer ${PGBOUNCER_MAJOR}" \
  name="UPM/pgbouncers" \
  version="${PGBOUNCER_MAJOR}" \
  maintainer="bsgchina.com"

ARG TARGETPLATFORM
# Download postgresql rpm postgresql-server
RUN set -ex \
  && case ${TARGETPLATFORM} in \
       "linux/amd64")  TINI_ARCH=x86_64  ;; \
       "linux/arm64")  TINI_ARCH=aarch64  ;; \
     esac \
  && dnf --disablerepo=* -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-${TINI_ARCH}/pgdg-redhat-repo-latest.noarch.rpm \
  && dnf -qy module disable postgresql \
  && dnf install -y "postgresql${PG_MAJOR}" \
  && dnf clean all \
  && psql --version

RUN set -eux; \
  groupadd --system --gid 1001 "pgbouncer"; \
  useradd --system --uid 1001 --gid 1001 --no-create-home -c "Default Application User" "pgbouncer"

COPY --from=builder "${PGBOUNCER_BASE_DIR}" "${PGBOUNCER_BASE_DIR}"

# Download pgbouncer package
RUN chown -R "pgbouncer:pgbouncer" "${PGBOUNCER_BASE_DIR}"

ENV PATH=$PATH:${PGBOUNCER_BASE_DIR}/bin

COPY serverMGR.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/serverMGR.sh

COPY supervisord.conf /etc/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
