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
    nmap-ncat \
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
  dnf install -y supervisor; \
  dnf clean all

ENV SUMMARY="High Performance Object Storage" \
    DESCRIPTION="MinIO is a high performance, Kubernetes-native object storage server compatible with Amazon S3 APIs." \
    UNIT_APP_VERSION="20250907161309.0.0-1"

LABEL summary="${SUMMARY}" \
  description="${DESCRIPTION}" \
  io.k8s.description="${DESCRIPTION}" \
  io.k8s.display-name="minio ${UNIT_APP_VERSION}" \
  type="minio" \
  version="${UNIT_APP_VERSION}" \
  maintainer="upm"

RUN set -eux; \
  groupadd --system --gid 1001 "minio"; \
  useradd --system --uid 1001 --gid 1001 --no-create-home -s /sbin/nologin -c "Default Application User" "minio"

ENV MINIO_BASE_DIR="/usr/local/minio"

ARG TARGETPLATFORM
RUN set -euxo pipefail; \
  case "${TARGETPLATFORM}" in \
    "linux/amd64")  platform_dir="linux-amd64"; rpm_arch="x86_64";; \
    "linux/arm64")  platform_dir="linux-arm64"; rpm_arch="aarch64";; \
    *) echo "Unsupported TARGETPLATFORM: ${TARGETPLATFORM}" >&2; exit 1;; \
  esac; \
  rpm_url="https://dl.min.io/server/minio/release/${platform_dir}/archive/minio-${UNIT_APP_VERSION}.${rpm_arch}.rpm"; \
  dnf install -y "${rpm_url}"; \
  dnf clean all; \
  rm -rf /var/cache/dnf /var/cache/yum

ENV PATH="${MINIO_BASE_DIR}:${PATH}"

COPY service-ctl.sh /usr/local/bin/
RUN chown 1001:1001 /usr/local/bin/service-ctl.sh && chmod +x /usr/local/bin/service-ctl.sh

COPY supervisord.conf /etc/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

USER 1001
