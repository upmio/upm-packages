FROM maven:3.9.0-eclipse-temurin-11 AS build

ARG HUBBLE_VERSION=1.3.0

RUN set -eux; \
    apt-get -o Acquire::ForceIPv4=true -o Acquire::http::Timeout=30 -o Acquire::Retries=3 update; \
    apt-get install -y --no-install-recommends git; \
    rm -rf /var/lib/apt/lists/*; \
    git clone --depth 1 --branch "${HUBBLE_VERSION}" https://github.com/apache/hugegraph-toolchain.git /src

WORKDIR /src

# The 1.3.0 source lockfile points at the retired registry.nlark.com host.
# Rewrite only the resolved tarball host; package versions and integrity hashes
# remain pinned by yarn.lock.
RUN sed -i 's|https://registry\.nlark\.com|https://registry.npmmirror.com|g' \
    hugegraph-hubble/hubble-fe/yarn.lock

# Build the shared toolchain separately so this expensive, successful step is
# cached when a frontend registry transient requires a later retry.
RUN mvn install -pl hugegraph-client,hugegraph-loader -am -Dmaven.javadoc.skip=true -DskipTests -ntp

RUN cd hugegraph-hubble \
    && mvn package -e -B -ntp -DskipTests -Dmaven.javadoc.skip=true

# Docker Hub no longer publishes openjdk:11-slim. Eclipse Temurin is the
# maintained Java 11 runtime and provides both amd64 and arm64 images used by
# the release workflow.
FROM eclipse-temurin:11-jre-jammy

USER root

RUN set -eux; \
    apt-get -o Acquire::ForceIPv4=true -o Acquire::http::Timeout=30 -o Acquire::Retries=3 update; \
    apt-get install -y --no-install-recommends supervisor curl; \
    rm -rf /var/lib/apt/lists/*; \
    groupadd --system --gid 1001 hugegraph-hubble; \
    useradd --system --uid 1001 --gid 1001 --no-create-home --shell /usr/sbin/nologin hugegraph-hubble

COPY --from=build /src/hugegraph-hubble/apache-hugegraph-hubble-incubating-*/ /hubble/
COPY service-ctl.sh /usr/local/bin/service-ctl.sh
COPY supervisord.conf /etc/supervisord.conf

RUN set -eux; \
    chmod 0755 /usr/local/bin/service-ctl.sh; \
    chown -R hugegraph-hubble:hugegraph-hubble /hubble /usr/local/bin/service-ctl.sh /etc/supervisord.conf

ENV HUBBLE_HOME=/hubble \
    LANG=C.UTF-8

LABEL type="hugegraph-hubble" \
      version="1.3.0" \
      maintainer="upm"

WORKDIR /hubble

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

USER hugegraph-hubble
