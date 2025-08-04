# Build stage
FROM rockylinux/rockylinux:9.5.20241118 AS builder

# MySQL image for UPM
ENV UNIT_APP_VERSION="8.4.5"
ENV MYSQL_VERSION="${UNIT_APP_VERSION}-1.el9"

# Install minimal required packages and MySQL in single RUN layer
RUN set -eux; \
  # Install minimal packages including pip and dnf config-manager
  dnf install -y --setopt=install_weak_deps=False \
    epel-release \
    procps-ng \
    bzip2 \
    openssl \
    xz \
    zstd \
    hostname \
    glibc-common \
    glibc-langpack-en \
    dnf-plugins-core \
    dnf-utils \
    python3 \
    python3-pip; \
  # Update Python packages to fix security vulnerabilities
  python3 -m pip install --upgrade \
    setuptools>=70.0.0 \
    cryptography>=41.0.0 \
    pip>=23.0.0; \
  # Install supervisor from EPEL (requires EPEL to be enabled first)
  dnf install -y --setopt=install_weak_deps=False supervisor; \
  # Install MySQL repositories
  dnf -y install "https://repo.mysql.com/mysql84-community-release-el9.rpm" \
    "https://repo.mysql.com/mysql-community-minimal-release-el9.rpm"; \
  # Enable MySQL repositories
  dnf config-manager --set-enabled mysql-tools-community mysql-8.4-lts-community-minimal; \
  # Install MySQL packages
  dnf install -y --setopt=install_weak_deps=False \
    "mysql-shell-${MYSQL_VERSION}" \
    "mysql-community-server-minimal-${MYSQL_VERSION}"; \
  # Create necessary directories
  mkdir -p /var/lib/mysql /var/log/mysql /var/run/mysqld /tmp/mysql; \
  # Clean up package cache aggressively
  dnf clean all; \
  rm -rf /var/cache/dnf/* /var/log/dnf.* /usr/share/doc/* /usr/share/man/*; \
  # Clean up Python cache
  python3 -m pip cache purge; \
  rm -rf /root/.cache/pip; \
  # Verify installation
  mysqlsh --version; \
  mysqld --version

# Final stage
FROM rockylinux/rockylinux:9.5.20241118

# MySQL image for UPM
ENV UNIT_APP_VERSION="8.4.5"
ENV MYSQL_VERSION="${UNIT_APP_VERSION}-1.el9"
ENV SUMMARY="MySQL SQL Database Server Community Edition" \
    DESCRIPTION="MySQL is a multi-user, multi-threaded SQL database server. The container image provides a containerized packaging of the MySQL mysqld daemon and client application. The mysqld server daemon accepts connections from clients and provides access to content from MySQL databases on behalf of the clients."

LABEL summary="${SUMMARY}" \
    description="${DESCRIPTION}" \
    io.k8s.description="${DESCRIPTION}" \
    io.k8s.display-name="mysql ${UNIT_APP_VERSION}" \
    type="mysql" \
    edition="Community" \
    version="${UNIT_APP_VERSION}" \
    maintainer="upm"

# Environment variables
ENV TZ=Asia/Shanghai \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Copy required files from builder stage
COPY --from=builder /usr/bin/mysql* /usr/bin/
COPY --from=builder /usr/bin/my* /usr/bin/
COPY --from=builder /usr/sbin/mysqld /usr/sbin/
COPY --from=builder /usr/lib64/mysql* /usr/lib64/
COPY --from=builder /usr/share/mysql* /usr/share/mysql/
COPY --from=builder /usr/bin/supervisord* /usr/bin/
COPY --from=builder /usr/bin/python* /usr/bin/
COPY --from=builder /usr/lib64/python* /usr/lib64/
# Copy essential system libraries
COPY --from=builder /usr/lib64/libz* /usr/lib64/
COPY --from=builder /usr/lib64/libssl* /usr/lib64/
COPY --from=builder /usr/lib64/libcrypto* /usr/lib64/
COPY --from=builder /usr/lib64/libprocps* /usr/lib64/
COPY --from=builder /usr/lib64/libncurses* /usr/lib64/
COPY --from=builder /usr/lib64/libtinfo* /usr/lib64/
COPY --from=builder /usr/lib64/libreadline* /usr/lib64/
COPY --from=builder /usr/lib64/libgssapi_krb5* /usr/lib64/
COPY --from=builder /usr/lib64/libkrb5* /usr/lib64/
COPY --from=builder /usr/lib64/libcom_err* /usr/lib64/
COPY --from=builder /usr/lib64/libkeyutils* /usr/lib64/
COPY --from=builder /usr/lib64/libresolv* /usr/lib64/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# Create directories and set permissions in single RUN layer
RUN set -eux; \
  # Set timezone and locale
  ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone; \
  localedef -i en_US -f UTF-8 en_US.UTF-8; \
  # Create mysql user and directories
  groupadd --system --gid 1001 "mysql"; \
  useradd --system --uid 1001 --gid 1001 -m -c "Default Application User" "mysql"; \
  mkdir -p /var/lib/mysql /var/log/mysql /var/run/mysqld /tmp/mysql; \
  chown -R 1001:1001 /var/lib/mysql /var/log/mysql /var/run/mysqld /tmp/mysql; \
  chmod 777 /var/run/mysqld; \
  # Clean up unnecessary files
  rm -rf /var/cache/dnf/* /var/log/dnf.* /usr/share/doc/* /usr/share/man/*

# Copy application files
COPY serverMGR.sh /usr/local/bin/
COPY supervisord.conf /etc/supervisord.conf

RUN chown 1001:1001 /usr/local/bin/serverMGR.sh && chmod +x /usr/local/bin/serverMGR.sh

# Switch to non-root user
USER 1001:1001

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]