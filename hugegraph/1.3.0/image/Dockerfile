FROM hugegraph/hugegraph:1.3.0

USER root

RUN set -eux; \
    apt-get -o Acquire::ForceIPv4=true -o Acquire::http::Timeout=30 -o Acquire::Retries=3 update; \
    apt-get install -y --no-install-recommends supervisor curl; \
    rm -rf /var/lib/apt/lists/*; \
    groupadd --system --gid 1001 hugegraph; \
    useradd --system --uid 1001 --gid 1001 --no-create-home --shell /usr/sbin/nologin hugegraph; \
    chown -R hugegraph:hugegraph /hugegraph-server

ENV HUGEGRAPH_HOME=/hugegraph-server \
    LANG=C.UTF-8

COPY service-ctl.sh /usr/local/bin/service-ctl.sh
COPY supervisord.conf /etc/supervisord.conf

RUN set -eux; \
    chmod 0755 /usr/local/bin/service-ctl.sh; \
    chown hugegraph:hugegraph /usr/local/bin/service-ctl.sh /etc/supervisord.conf

LABEL type="hugegraph" \
      version="1.3.0" \
      maintainer="upm"

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

USER hugegraph
