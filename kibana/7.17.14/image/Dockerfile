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

ENV UNIT_APP_VERSION="7.17.14"
ENV KIBANA_BASE_DIR="/usr/local/kibana"

# Download kibana, untar and clean up
ENV SUMMARY="Kibana gives shape to your data and is the extensible user interface" \
    DESCRIPTION="Kibana is a free and open user interface that lets you visualize your Elasticsearch data and navigate the Elastic Stack. Do anything from tracking query load to understanding the way requests flow through your apps."

RUN set -eux; \
  groupadd --system --gid 1001 "kibana"; \
  useradd --system --uid 1001 --gid 1001 --no-create-home -s /sbin/nologin -c "Default Application User" "kibana"

ARG TARGETPLATFORM
RUN set -ex \
    && mkdir -p "${KIBANA_BASE_DIR}" \
    && case ${TARGETPLATFORM} in \
         "linux/amd64")  TINI_ARCH=x86_64  ;; \
         "linux/arm64")  TINI_ARCH=aarch64  ;; \
       esac \
    && curl --retry 8 -s -L --output "/tmp/kibana.tar.gz" "https://artifacts.elastic.co/downloads/kibana/kibana-${UNIT_APP_VERSION}-${OS}-${TINI_ARCH}.tar.gz" \
    && tar -zxf "/tmp/kibana.tar.gz" --strip-components=1 -C "${KIBANA_BASE_DIR}" \
    && chown -R "1001:1001" "${KIBANA_BASE_DIR}" \
    && rm -rf "/tmp/kibana.tar.gz"

ENV PATH="${KIBANA_BASE_DIR}/bin:${PATH}"

LABEL summary="${SUMMARY}" \
  description="${DESCRIPTION}" \
  io.k8s.description="${DESCRIPTION}" \
  io.k8s.display-name="kibana ${UNIT_APP_VERSION}" \
  type="kibana" \
  version="${UNIT_APP_VERSION}" \
  maintainer="upm"

COPY serverMGR.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/serverMGR.sh

COPY supervisord.conf /etc/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
