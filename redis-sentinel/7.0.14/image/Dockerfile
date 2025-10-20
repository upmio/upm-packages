FROM fullstorydev/grpcurl:v1.8.9 AS grpcurl

FROM rockylinux/rockylinux:9.6.20250531

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

RUN set -eux; \
  dnf install -y supervisor; \
  dnf clean all

ENV UNIT_APP_VERSION="7.0.14" \
    SUMMARY="Redis in-memory data structure store, used as database, cache and message broker" \
    DESCRIPTION="Redis available as container, is an advanced key-value store. It is often referred to as a data structure server since keys can contain strings, hashes, lists, sets and sorted sets."

LABEL summary="${SUMMARY}" \
      description="${DESCRIPTION}" \
      io.k8s.description="${DESCRIPTION}" \
      io.k8s.display-name="redis ${UNIT_APP_VERSION}" \
      name="UPM/redis" \
      version="${UNIT_APP_VERSION}" \
      maintainer="upm"

# install grpcurl
ENV GRPCURL_VERSION="v1.8.9"
COPY --from=grpcurl /bin/grpcurl /usr/local/bin/
RUN grpcurl -version

RUN set -eux; \
  groupadd --system --gid 1001 "redis"; \
  useradd --system --uid 1001 --gid 1001 --no-create-home -s /sbin/nologin -c "Default Application User" "redis"

ARG TARGETPLATFORM
RUN set -ex \
  && case ${TARGETPLATFORM} in \
       "linux/amd64")  TINI_ARCH=x86_64  ;; \
       "linux/arm64")  TINI_ARCH=aarch64  ;; \
     esac \
  && dnf install -y "http://rpms.remirepo.net/enterprise/9/modular/${TINI_ARCH}/redis-${UNIT_APP_VERSION}-1.el9.remi.${TINI_ARCH}.rpm" \
  && dnf clean all; \
  redis-server --version

COPY sentinelReconfig.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/sentinelReconfig.sh
COPY service-ctl.sh /usr/local/bin/
RUN chown 1001:1001 /usr/local/bin/service-ctl.sh && chmod +x /usr/local/bin/service-ctl.sh

COPY supervisord.conf /etc/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

USER 1001
