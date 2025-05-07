FROM ghcr.io/jqlang/jq:1.7 as jq

FROM rockylinux/rockylinux:9.5.20241118

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

# install jq
ENV JQ_VERSION="1.7"
COPY --from=jq /jq /usr/local/bin/
RUN jq --version

# install grpcul
ARG TARGETPLATFORM
RUN set -ex \
  && case ${TARGETPLATFORM} in \
       "linux/amd64")  TINI_ARCH=x86_64  ;; \
       "linux/arm64")  TINI_ARCH=arm64  ;; \
     esac \
  && curl -sSL "https://github.com/fullstorydev/grpcurl/releases/download/v1.8.7/grpcurl_1.8.7_linux_${TINI_ARCH}.tar.gz" | tar -xz -C /usr/local/bin

COPY toolkit /usr/local/bin/
RUN chmod +x /usr/local/bin/toolkit

ENTRYPOINT ["/usr/local/bin/toolkit"]