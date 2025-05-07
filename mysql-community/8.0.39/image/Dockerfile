FROM rockylinux/rockylinux:8.10

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

# Download MySQL
ENV UNIT_APP_VERSION="8.0.39"
ENV MYSQL_VERSION="${UNIT_APP_VERSION}-1.el8"

# MySQL image for UPM.
ENV SUMMARY="MySQL SQL Database Server Community Edition" \
  DESCRIPTION="MySQL is a multi-user, multi-threaded SQL database server. The container \
  image provides a containerized packaging of the MySQL mysqld daemon and client application. \
  The mysqld server daemon accepts connections from clients and provides access to content from \
  MySQL databases on behalf of the clients."

LABEL summary="${SUMMARY}" \
  description="${DESCRIPTION}" \
  io.k8s.description="${DESCRIPTION}" \
  io.k8s.display-name="mysql ${UNIT_APP_VERSION}" \
  type="mysql" \
  edition="Community" \
  version="${UNIT_APP_VERSION}" \
  maintainer="upm"

RUN set -eux; \
  groupadd --system --gid 1001 "mysql"; \
  useradd --system --uid 1001 --gid 1001 --no-create-home -s /sbin/nologin -c "Default Application User" "mysql"

# Download mysql80-community mysql-shell and mysql client
RUN set -eu; \
  dnf -y install "https://repo.mysql.com/mysql80-community-release-el8.rpm"; \
  dnf module disable -y mysql; \
  dnf config-manager --set-enabled mysql-tools-community; \
  dnf install -y "mysql-shell-${MYSQL_VERSION}"; \
  dnf clean all; \
  mysqlsh --version

# Download mysql-community-server-minimal
RUN set -eu; \
  dnf -y install "https://repo.mysql.com/mysql-community-minimal-release-el8.rpm"; \
  dnf module disable -y mysql; \
  dnf config-manager --set-enabled mysql80-community-minimal; \
  dnf install -y "mysql-community-server-minimal-${MYSQL_VERSION}"; \
  mysqld --version

COPY serverMGR.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/serverMGR.sh

COPY supervisord.conf /etc/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
