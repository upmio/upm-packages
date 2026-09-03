restserver.url=http://0.0.0.0:{{ getenv "HUGEGRAPH_PORT" "8080" }}
graphs={{ getenv "CONF_DIR" }}/graphs
batch.max_write_ratio={{ getv "/server/batch_max_write_ratio" }}
batch.max_write_threads={{ getv "/server/batch_max_write_threads" }}
log.slow_query_threshold={{ getv "/server/slow_query_threshold" }}
