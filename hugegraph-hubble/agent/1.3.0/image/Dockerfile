# Build the HugeGraph Tools distribution required by the Hubble backup and
# restore gRPC operations. HugeGraph 1.3.0 does not include these tools in
# either the HugeGraph Server or Hubble image.
FROM maven:3.9.0-eclipse-temurin-11 AS hugegraph-tools-builder

ARG HUGEGRAPH_VERSION=1.3.0

RUN set -eux; \
    apt-get -o Acquire::ForceIPv4=true -o Acquire::http::Timeout=30 -o Acquire::Retries=3 update; \
    apt-get install -y --no-install-recommends git; \
    rm -rf /var/lib/apt/lists/*; \
    git clone --depth 1 --branch "${HUGEGRAPH_VERSION}" https://github.com/apache/hugegraph-toolchain.git /src

WORKDIR /src

RUN mvn install -pl hugegraph-client -am -Dmaven.javadoc.skip=true -DskipTests -ntp
RUN cd hugegraph-tools \
    && mvn package -B -ntp -DskipTests -Dmaven.javadoc.skip=true

# Keep the unit-agent implementation in unit-operator. This image adds only
# the Java runtime and HugeGraph Tools that are specific to Hubble 1.3.0.
# The tag is the dual-architecture unit-operator commit that includes Hubble
# backup and restore plus S3-compatible object storage support.
FROM quay.io/upmio/unit-agent:main-f37bb66 AS unit-agent

FROM eclipse-temurin:11-jre-jammy

USER root

RUN set -eux; \
    apt-get -o Acquire::ForceIPv4=true -o Acquire::http::Timeout=30 -o Acquire::Retries=3 update; \
    apt-get install -y --no-install-recommends bash ca-certificates; \
    rm -rf /var/lib/apt/lists/*; \
    groupadd --system --gid 1001 unit-agent; \
    useradd --system --uid 1001 --gid 1001 --create-home --shell /usr/sbin/nologin unit-agent

COPY --from=unit-agent /usr/local/bin/unit-agent /usr/local/bin/unit-agent
COPY --from=unit-agent /opt/unit-agent/config.toml /opt/unit-agent/config.toml
COPY --from=hugegraph-tools-builder /src/hugegraph-tools/apache-hugegraph-tools-incubating-1.3.0/ /opt/hugegraph-tools/

RUN set -eux; \
    chmod 0755 /usr/local/bin/unit-agent /opt/hugegraph-tools/bin/hugegraph; \
    chown -R unit-agent:unit-agent /home/unit-agent /opt/unit-agent /opt/hugegraph-tools

ENV TZ=Asia/Shanghai \
    HUGEGRAPH_TOOLS_HOME=/opt/hugegraph-tools

WORKDIR /home/unit-agent

CMD ["unit-agent", "daemon", "-f", "/opt/unit-agent/config.toml"]

USER unit-agent
EXPOSE 2214
