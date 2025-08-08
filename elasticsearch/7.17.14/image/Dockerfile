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

# Download elasticsearch, untar and clean up
ENV UNIT_APP_VERSION="7.17.14" \
    SUMMARY="Elasticsearch is a distributed, JSON-based search and analytics engine" \
    DESCRIPTION="Elasticsearch is the distributed search and analytics engine at the heart of the Elastic Stack." \
    ELASTICSEARCH_BASE_DIR="/usr/local/elasticsearch"

RUN set -eux; \
  groupadd --system --gid 1001 "elastic"; \
  useradd --system --uid 1001 --gid 1001 --no-create-home -s /bin/bash -c "Default Application User" "elastic"

RUN mkdir -p "${ELASTICSEARCH_BASE_DIR}" \
    && curl --retry 10 -S -L --output "/tmp/elasticsearch.tar.gz" "https://artifacts-no-kpi.elastic.co/downloads/elasticsearch/elasticsearch-${UNIT_APP_VERSION}-linux-$(arch).tar.gz" \
    && tar -zxf "/tmp/elasticsearch.tar.gz" --strip-components=1 -C "${ELASTICSEARCH_BASE_DIR}" \
    && "${ELASTICSEARCH_BASE_DIR}/bin/elasticsearch-plugin" install repository-s3 -b \
    && chown -R "1001:1001" "${ELASTICSEARCH_BASE_DIR}" \
    && rm -rf "/tmp/elasticsearch.tar.gz"

ENV PATH="${ELASTICSEARCH_BASE_DIR}/bin:${PATH}"

LABEL summary="${SUMMARY}" \
  description="${DESCRIPTION}" \
  io.k8s.description="${DESCRIPTION}" \
  io.k8s.display-name="elasticsearch ${UNIT_APP_VERSION}" \
  type="elasticsearch" \
  version="${UNIT_APP_VERSION}" \
  maintainer="upm"

COPY service-ctl.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/service-ctl.sh

COPY supervisord.conf /etc/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]