FROM milvusdb/milvus:v2.6.2 AS builder
FROM rockylinux/rockylinux:10.0.20250606

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
  dnf install -y supervisor \
  && dnf clean all

ENV SUMMARY="High Performance Vector Database" \
    DESCRIPTION="Milvus is an open-source vector database built for scalable similarity search and AI applications." \
    UNIT_APP_VERSION="v2.6.2"

LABEL summary="${SUMMARY}" \
  description="${DESCRIPTION}" \
  io.k8s.description="${DESCRIPTION}" \
  io.k8s.display-name="milvus ${UNIT_APP_VERSION}" \
  type="milvus" \
  version="${UNIT_APP_VERSION}" \
  maintainer="upm"

RUN set -eux; \
  groupadd --system --gid 1001 "milvus"; \
  useradd --system --uid 1001 --gid 1001 --no-create-home -s /bin/bash -c "Default Application User" "milvus"; \
  dnf install -y openblas-serial libaio;

COPY service-ctl.sh /usr/local/bin/
RUN chown 1001:1001 /usr/local/bin/service-ctl.sh && chmod +x /usr/local/bin/service-ctl.sh

ENV MILVUS_BASE_DIR="/usr/local/milvus"
ENV PATH="${MILVUS_BASE_DIR}/bin:${PATH}" \
    LD_LIBRARY_PATH="${MILVUS_BASE_DIR}/lib"

COPY --from=builder /milvus/bin /usr/local/milvus/bin
COPY --from=builder /milvus/lib /usr/local/milvus/lib

COPY service-ctl.sh /usr/local/bin/
COPY supervisord.conf /etc/supervisord.conf

RUN set -eux; \
  chown -R 1001:1001 /usr/local/milvus; \
  chown 1001:1001 /usr/local/bin/service-ctl.sh; \
  chmod +x /usr/local/bin/service-ctl.sh; \
  chown 1001:1001 /etc/supervisord.conf

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

USER 1001
