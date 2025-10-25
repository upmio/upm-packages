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

ENV UNIT_APP_VERSION="3.5.2"

# Download Apache Kafka, verify its PGP signature, untar and clean up
ENV SUMMARY="Kafka distributed event streaming platform" \
  DESCRIPTION="Apache Kafka is an open-source distributed event streaming platform used by thousands of companies for high-performance data pipelines, streaming analytics, \
data integration, and mission-critical applications." \
  SCALA_VERSION="2.13" \
  KAFKA_BASE_DIR="/usr/local/kafka"

LABEL summary="${SUMMARY}" \
  description="${DESCRIPTION}" \
  io.k8s.description="${DESCRIPTION}" \
  io.k8s.display-name="kafka ${UNIT_APP_VERSION}" \
  type="kafka" \
  version="${UNIT_APP_VERSION}" \
  maintainer="upm"

RUN set -eux; \
  groupadd --system --gid 1001 "kafka"; \
  useradd --system --uid 1001 --gid 1001 --no-create-home -s /sbin/nologin -c "Default Application User" "kafka"

# install java 11
RUN set -eux; \
  dnf install -y \
    java-11-openjdk \
    java-11-openjdk-devel \
    tzdata-java; \
  dnf clean all

ENV PATH="${KAFKA_BASE_DIR}/bin:$PATH"

RUN set -ex \
  && mkdir -p "${KAFKA_BASE_DIR}" \
  && curl --output "/tmp/kafka.tar.gz" "https://archive.apache.org/dist/kafka/${UNIT_APP_VERSION}/kafka_${SCALA_VERSION}-${UNIT_APP_VERSION}.tgz" \
  && tar -xf "/tmp/kafka.tar.gz" -C "${KAFKA_BASE_DIR}" --strip-components 1 \
  && chown -R "1001:1001" "${KAFKA_BASE_DIR}" \
  && rm -rf "/tmp/kafka.tar.gz"

COPY service-ctl.sh /usr/local/bin/
COPY supervisord.conf /etc/supervisord.conf

RUN set -eux; \
  chown 1001:1001 /usr/local/bin/service-ctl.sh; \
  chmod +x /usr/local/bin/service-ctl.sh; \
  chown 1001:1001 /etc/supervisord.conf

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

USER 1001
