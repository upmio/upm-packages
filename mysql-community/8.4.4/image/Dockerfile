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

RUN set -eux; \
# https://dev.mysql.com/doc/refman/8.0/en/checking-gpg-signature.html
# pub   rsa4096 2023-10-23 [SC] [expires: 2025-10-22]
#       BCA4 3417 C3B4 85DD 128E  C6D4 B7B3 B788 A8D3 785C
# uid           [ unknown] MySQL Release Engineering <mysql-build@oss.oracle.com>
# sub   rsa4096 2023-10-23 [E] [expires: 2025-10-22]
	key='BCA4 3417 C3B4 85DD 128E C6D4 B7B3 B788 A8D3 785C'; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
	gpg --batch --export --armor "$key" > /etc/pki/rpm-gpg/RPM-GPG-KEY-mysql; \
	rm -rf "$GNUPGHOME \

ARG UNIT_APP_VERSION="8.4.4"
ARG MYSQL_VERSION="${UNIT_APP_VERSION}-1.el9"
ARG MYSQL_SHELL_VERSION="${UNIT_APP_VERSION}-1.el9"

# Download MySQL
RUN set -eu; \
	{ \
		echo '[mysql8.4-server-minimal]'; \
		echo 'name=MySQL 8.4 Server Minimal'; \
		echo 'enabled=1'; \
		echo 'baseurl=https://repo.mysql.com/yum/mysql-8.4-community/docker/el/9/$basearch/'; \
		echo 'gpgcheck=1'; \
		echo 'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql'; \
		echo 'module_hotfixes=true'; \
	} | tee /etc/yum.repos.d/mysql-community-minimal.repo
RUN set -eux; \
	dnf install -y "mysql-community-server-minimal-$MYSQL_VERSION"; \
	dnf clean all; \
	mysqld --version; \
	mysql --version

# Download MySQL Shell
RUN set -eu; \
	{ \
		echo '[mysql-tools-community]'; \
		echo 'name=MySQL Tools Community'; \
		echo 'baseurl=https://repo.mysql.com/yum/mysql-tools-8.4-community/el/9/$basearch/'; \
		echo 'enabled=1'; \
		echo 'gpgcheck=1'; \
		echo 'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql'; \
		echo 'module_hotfixes=true'; \
	} | tee /etc/yum.repos.d/mysql-community-tools.repo
RUN set -eux; \
	dnf install -y "mysql-shell-$MYSQL_SHELL_VERSION"; \
	dnf clean all; \
	mysqlsh --version

COPY serverMGR.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/serverMGR.sh

COPY supervisord.conf /etc/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
