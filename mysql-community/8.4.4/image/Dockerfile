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
    epel-release

# install supervisor
RUN set -eux; \
  dnf install -y supervisor

# Download MySQL
ARG UNIT_APP_VERSION="8.4.4"
ARG MYSQL_SERVER_PACKAGE="mysql-community-server-minimal-${UNIT_APP_VERSION}-1.el9"
ARG MYSQL_SHELL_PACKAGE="mysql-shell-${UNIT_APP_VERSION}-1.el9"

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

# Add a user with an explicit UID/GID and create necessary directories
RUN set -eux; \
  groupadd --system --gid 1001 "mysql" \
  && useradd --system --uid 1001 --gid 1001 --no-create-home -s /sbin/nologin -c "Default Application User" "mysql"

# install mysql84-community mysql-shell and mysql-community-server-minimal
RUN set -eu; \
  dnf -y install "https://repo.mysql.com/mysql84-community-release-el9.rpm" \
  && dnf config-manager --set-enabled mysql-tools-community \
  && dnf install -y "${MYSQL_SHELL_PACKAGE}" \
  && mysqlsh --version \
  && dnf -y install "https://repo.mysql.com/mysql-community-minimal-release-el9.rpm" \
  && dnf config-manager --set-enabled mysql84-community-minimal \
  && dnf install -y "${MYSQL_SERVER_PACKAGE}" \
  && mysqld --version \
  && dnf clean all

COPY serverMGR.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/serverMGR.sh

COPY supervisord.conf /etc/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
