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

# Download proxysql, verify its PGP signature, untar and clean up
ENV SUMMARY="High-performance MySQL proxy" \
  DESCRIPTION="ProxySQL is a high performance, high availability, protocol aware proxy for MySQL \
and forks (like Percona Server and MariaDB). All the while getting the unlimited \
freedom that comes with a GPL license." \
  UNIT_APP_VERSION="2.7.2"

LABEL summary="${SUMMARY}" \
  description="${DESCRIPTION}" \
  io.k8s.description="${DESCRIPTION}" \
  io.k8s.display-name="proxysql ${UNIT_APP_VERSION}" \
  name="UPM/proxysql" \
  version="${UNIT_APP_VERSION}" \
  maintainer="upm"

# Download mysql80-community mysql-shell and mysql client
RUN set -eu; \
  dnf -y install "https://repo.mysql.com/mysql80-community-release-el9.rpm"; \
  dnf config-manager --set-enabled mysql80-community; \
  dnf install -y "mysql-shell" "mysql-community-client"; \
  dnf clean all; \
  mysqlsh --version

RUN set -eux; \
  groupadd --system --gid 1001 "proxysql"; \
  useradd --system --uid 1001 --gid 1001 -m -c "Default Application User" "proxysql"

RUN set -eu; \
  . /etc/os-release; \
  { \
    echo '[proxysql-repository]'; \
    echo 'name=ProxySQL repository'; \
    echo "baseurl=https://repo.proxysql.com/ProxySQL/proxysql-2.7.x/centos/${VERSION_ID%%[.-]*}"; \
    echo 'enabled=1'; \
    echo 'gpgcheck=1'; \
    echo 'gpgkey=https://repo.proxysql.com/ProxySQL/proxysql-2.7.x/repo_pub_key'; \
  } | tee /etc/yum.repos.d/proxysql.repo

RUN set -ex \
  && rpmkeys --import https://repo.proxysql.com/ProxySQL/repo_pub_key \
  && dnf install -y "proxysql-${UNIT_APP_VERSION}" \
  && rm -f /etc/proxysql.cnf \
  && dnf clean all \
  && proxysql --version

COPY serverMGR.sh /usr/local/bin/
RUN chown 1001:1001 /usr/local/bin/serverMGR.sh
RUN chmod +x /usr/local/bin/serverMGR.sh

COPY supervisord.conf /etc/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
