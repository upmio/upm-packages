FROM fullstorydev/grpcurl:v1.8.9 AS grpcurl

FROM quay.io/upmio/redis:7.0.14

ENV GRPCURL_VERSION="v1.8.9"
COPY --from=grpcurl /bin/grpcurl /usr/local/bin/
RUN grpcurl -version

COPY sentinelReconfig.sh /usr/local/bin/
RUN chown 1001:1001 /usr/local/bin/sentinelReconfig.sh && chmod +x /usr/local/bin/sentinelReconfig.sh

COPY supervisord.conf /etc/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
