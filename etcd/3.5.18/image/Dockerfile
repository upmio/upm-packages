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

ENV SUMMARY="Distributed reliable key-value store" \
    DESCRIPTION="etcd is a distributed, reliable key-value store that provides a \
    consistent way to store data across a cluster of machines. The container image \
    provides a containerized packaging of the etcd server. The etcd server accepts \
    gRPC and HTTP requests from clients and stores configuration data, metadata, and \
    service discovery information reliably and consistently across the cluster." \
    UNIT_APP_VERSION="3.5.18"

LABEL summary="${SUMMARY}" \
  description="${DESCRIPTION}" \
  io.k8s.description="${DESCRIPTION}" \
  io.k8s.display-name="etcd ${UNIT_APP_VERSION}" \
  type="etcd" \
  version="${UNIT_APP_VERSION}" \
  maintainer="upm"

RUN set -eux; \
  groupadd --system --gid 1001 "etcd"; \
  useradd --system --uid 1001 --gid 1001 --no-create-home -s /sbin/nologin -c "Default Application User" "etcd"

ENV ETCD_BASE_DIR="/usr/local/etcd"
ENV ETCDCTL_API=3

ARG TARGETPLATFORM
RUN set -ex \
  && case ${TARGETPLATFORM} in \
       "linux/amd64")  TINI_ARCH=amd64  ;; \
       "linux/arm64")  TINI_ARCH=arm64  ;; \
     esac \
  && curl -L https://github.com/etcd-io/etcd/releases/download/${UNIT_APP_VERSION}/etcd-${UNIT_APP_VERSION}-linux-${TINI_ARCH}.tar.gz -o /tmp/etcd-${UNIT_APP_VERSION}.tar.gz \
  && mkdir -p "${ETCD_BASE_DIR}" \
  && tar xzvf /tmp/etcd-${UNIT_APP_VERSION}.tar.gz -C "${ETCD_BASE_DIR}" --strip-components=1 \
  && rm -f /tmp/etcd-${UNIT_APP_VERSION}-linux-amd64.tar.gz

ENV PATH="${ETCD_BASE_DIR}:${PATH}" \
    ETCDCTL_BIN="${ETCD_BASE_DIR}/etcdctl"

COPY service-ctl.sh /usr/local/bin/
RUN chown 1001:1001 /usr/local/bin/service-ctl.sh && chmod +x /usr/local/bin/service-ctl.sh

COPY supervisord.conf /etc/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

USER 1001
