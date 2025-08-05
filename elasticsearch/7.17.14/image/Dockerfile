# Builder stage
FROM rockylinux/rockylinux:9.5.20241118 AS builder

# Install minimal build tools
RUN set -eux; \
  dnf install -y \
    tar \
    gzip \
  && dnf clean all \
  && rm -rf /var/cache/dnf/*

# Download and extract elasticsearch
ENV UNIT_APP_VERSION="7.17.14" \
    ELASTICSEARCH_BASE_DIR="/tmp/elasticsearch"

RUN set -eux; \
  mkdir -p "${ELASTICSEARCH_BASE_DIR}"; \
  curl --retry 10 -S -L --output "/tmp/elasticsearch.tar.gz" "https://artifacts-no-kpi.elastic.co/downloads/elasticsearch/elasticsearch-${UNIT_APP_VERSION}-linux-$(arch).tar.gz"; \
  tar -zxf "/tmp/elasticsearch.tar.gz" --strip-components=1 -C "${ELASTICSEARCH_BASE_DIR}"; \
  rm -rf "/tmp/elasticsearch.tar.gz"

# Final minimal stage
FROM rockylinux/rockylinux:9.5.20241118

# Install only runtime dependencies and clean up
RUN set -eux; \
  dnf install -y \
    procps-ng \
    openssl \
    epel-release \
    glibc-langpack-en \
    glibc-locale-source \
  && localedef -i en_US -f UTF-8 en_US.UTF-8 \
  && dnf install -y supervisor \
  && dnf clean all \
  && rm -rf /var/cache/dnf/*

# Set timezone and locale
ENV TZ=Asia/Shanghai \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
  && echo "$TZ" > /etc/timezone

# Create user and directories
ENV UNIT_APP_VERSION="7.17.14" \
    SUMMARY="Elasticsearch is a distributed, JSON-based search and analytics engine" \
    DESCRIPTION="Elasticsearch is the distributed search and analytics engine at the heart of the Elastic Stack." \
    ELASTICSEARCH_BASE_DIR="/usr/local/elasticsearch"

RUN set -eux; \
  groupadd --system --gid 1001 "elastic"; \
  useradd --system --uid 1001 --gid 1001 --no-create-home -s /bin/bash -c "Default Application User" "elastic"; \
  mkdir -p "${ELASTICSEARCH_BASE_DIR}"

# Copy elasticsearch from builder stage
COPY --from=builder /tmp/elasticsearch/ "${ELASTICSEARCH_BASE_DIR}/"

#
RUN set -eux; \
  "${ELASTICSEARCH_BASE_DIR}/bin/elasticsearch-plugin" install repository-s3 -b; \
  chown -R "1001:1001" "${ELASTICSEARCH_BASE_DIR}"

ENV PATH="${ELASTICSEARCH_BASE_DIR}/bin:${PATH}"

LABEL summary="${SUMMARY}" \
  description="${DESCRIPTION}" \
  io.k8s.description="${DESCRIPTION}" \
  io.k8s.display-name="elasticsearch ${UNIT_APP_VERSION}" \
  type="elasticsearch" \
  version="${UNIT_APP_VERSION}" \
  maintainer="upm"

COPY serverMGR.sh /usr/local/bin/
COPY supervisord.conf /etc/supervisord.conf
RUN chmod +x /usr/local/bin/serverMGR.sh

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
