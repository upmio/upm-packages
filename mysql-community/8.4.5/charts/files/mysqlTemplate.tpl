[mysql]
prompt='\\u@\\d \\r:\\m:\\s>'
socket={{ getenv "DATA_MOUNT" }}/mysqld.sock
port={{ getenv "MYSQL_PORT" "3306" }}
default-character-set=utf8mb4
no-auto-rehash

[mysqldump]
quick
max_allowed_packet=1073741824

[mysqld]
user=mysql
datadir={{ getenv "DATA_DIR" }}
tmpdir={{ getenv "TMP_DIR" }}
log_error={{ getenv "LOG_MOUNT" }}/mysqld.err
slow_query_log_file={{ getenv "LOG_MOUNT" }}/mysql-slow.log
general_log_file={{ getenv "LOG_MOUNT" }}/mysql-general.log
mysqlx=ON
socket={{ getenv "DATA_MOUNT" }}/mysqld.sock
port={{ getenv "MYSQL_PORT" "3306" }}
mysqlx_port={{ getenv "MYSQLX_PORT" "33060" }}
report_host={{ getenv "POD_NAME" }}.{{ getenv "SERVICE_NAME" }}-headless-svc.{{ getenv "NAMESPACE" }}
report_port={{ getenv "MYSQL_PORT" "3306" }}

default_storage_engine=InnoDB
disabled_storage_engines=MEMORY,BLACKHOLE,MyISAM,CSV,ARCHIVE,FEDERATED
net_read_timeout={{ getv "/mysqld/net_read_timeout" }}
net_write_timeout={{ getv "/mysqld/net_write_timeout" }}
interactive_timeout={{ getv "/mysqld/interactive_timeout" }}
table_open_cache_instances={{ getv "/mysqld/table_open_cache_instances" }}
log_throttle_queries_not_using_indexes={{ getv "/mysqld/log_throttle_queries_not_using_indexes" }}
wait_timeout={{ getv "/mysqld/wait_timeout" }}
min_examined_row_limit={{ getv "/mysqld/min_examined_row_limit" }}
tmp_table_size={{ getv "/mysqld/tmp_table_size" }}
max_heap_table_size={{ getv "/mysqld/max_heap_table_size" }}
sql_mode={{ getv "/mysqld/sql_mode" }}
table_definition_cache={{ getv "/mysqld/table_definition_cache" }}
join_buffer_size={{ getv "/mysqld/join_buffer_size" }}

init_connect = 'SET NAMES utf8mb4'
character_set_server={{ getv "/mysqld/character_set_server" }}
lower_case_table_names={{ getv "/mysqld/lower_case_table_names" }}
open_files_limit={{ getv "/mysqld/open_files_limit" }}
log_slow_admin_statements={{ getv "/mysqld/log_slow_admin_statements" }}
log_queries_not_using_indexes={{ getv "/mysqld/log_queries_not_using_indexes" }}
long_query_time={{ getv "/mysqld/long_query_time" }}
slow_query_log={{ getv "/mysqld/slow_query_log" }}
general_log={{ getv "/mysqld/general_log" }}

max_connections={{ getv "/mysqld/max_connections" }}
max_user_connections={{ getv "/mysqld/max_user_connections" }}
max_connect_errors={{ getv "/mysqld/max_connect_errors" }}
max_allowed_packet={{ getv "/mysqld/max_allowed_packet" }}
connect_timeout={{ getv "/mysqld/connect_timeout" }}
back_log=3000
lock_wait_timeout=31536000
thread_stack=1048576
thread_cache_size={{ getv "/mysqld/thread_cache_size" }}
sort_buffer_size={{ getv "/mysqld/sort_buffer_size" }}

server_id={{add (atoi (getenv "UNIT_SN")) 1}}
log_bin={{ getenv "BIN_LOG_DIR" }}/mysql-bin
relay_log={{ getenv "RELAY_LOG_DIR" }}/relay-bin
relay_log_index={{ getenv "RELAY_LOG_DIR" }}/relay-bin.index
max_binlog_cache_size=18446744073709547520
binlog_cache_size={{ getv "/mysqld/binlog_cache_size" }}
max_binlog_size={{ getv "/mysqld/max_binlog_size" }}
binlog_checksum={{ getv "/mysqld/binlog_checksum" }}
binlog_row_image={{ getv "/mysqld/binlog_row_image" }}
binlog_rows_query_log_events={{ getv "/mysqld/binlog_rows_query_log_events" }}
binlog_expire_logs_seconds={{ getv "/mysqld/binlog_expire_logs_seconds" }}
explicit_defaults_for_timestamp={{ getv "/mysqld/explicit_defaults_for_timestamp" }}
sync_binlog={{ getv "/mysqld/sync_binlog" }}

gtid_mode=ON
enforce_gtid_consistency=ON
relay_log_recovery=ON
skip_replica_start=ON
read_only=ON
super_read_only=ON

innodb_buffer_pool_instances={{ getv "/mysqld/innodb_buffer_pool_instances" }}
innodb_buffer_pool_size={{ mul (div (atoi (getenv "MYSQL_MEMORY_LIMIT")) 4) 3 }}M
innodb_buffer_pool_dump_at_shutdown={{ getv "/mysqld/innodb_buffer_pool_dump_at_shutdown" }}
innodb_buffer_pool_load_at_startup={{ getv "/mysqld/innodb_buffer_pool_load_at_startup" }}
innodb_print_all_deadlocks={{ getv "/mysqld/innodb_print_all_deadlocks" }}
innodb_sort_buffer_size={{ getv "/mysqld/innodb_sort_buffer_size" }}
innodb_buffer_pool_dump_pct={{ getv "/mysqld/innodb_buffer_pool_dump_pct" }}
innodb_deadlock_detect={{ getv "/mysqld/innodb_deadlock_detect" }}
innodb_redo_log_capacity=1500M
innodb_log_buffer_size={{ getv "/mysqld/innodb_log_buffer_size" }}
innodb_flush_log_at_trx_commit={{ getv "/mysqld/innodb_flush_log_at_trx_commit" }}
innodb_max_undo_log_size={{ getv "/mysqld/innodb_max_undo_log_size" }}
innodb_max_dirty_pages_pct={{ getv "/mysqld/innodb_max_dirty_pages_pct" }}
innodb_io_capacity={{ getv "/mysqld/innodb_io_capacity" }}
innodb_io_capacity_max={{ getv "/mysqld/innodb_io_capacity_max" }}
innodb_thread_concurrency={{ getv "/mysqld/innodb_thread_concurrency" }}
innodb_purge_rseg_truncate_frequency={{ getv "/mysqld/innodb_purge_rseg_truncate_frequency" }}
innodb_read_io_threads={{ getv "/mysqld/innodb_read_io_threads" }}
innodb_write_io_threads={{ getv "/mysqld/innodb_write_io_threads" }}
innodb_autoinc_lock_mode={{ getv "/mysqld/innodb_autoinc_lock_mode" }}
innodb_open_files={{ getv "/mysqld/innodb_open_files" }}
innodb_purge_batch_size={{ getv "/mysqld/innodb_purge_batch_size" }}
innodb_flush_method={{ getv "/mysqld/innodb_flush_method" }}
innodb_change_buffering=none
innodb_adaptive_flushing=ON
innodb_old_blocks_time=1000
innodb_stats_on_metadata={{ getv "/mysqld/innodb_stats_on_metadata" }}
innodb_lock_wait_timeout={{ getv "/mysqld/innodb_lock_wait_timeout" }}
innodb_stats_persistent_sample_pages={{ getv "/mysqld/innodb_stats_persistent_sample_pages" }}
innodb_stats_transient_sample_pages={{ getv "/mysqld/innodb_stats_transient_sample_pages" }}
innodb_sync_spin_loops={{ getv "/mysqld/innodb_sync_spin_loops" }}
innodb_rollback_on_timeout={{ getv "/mysqld/innodb_rollback_on_timeout" }}
innodb_online_alter_log_max_size={{ getv "/mysqld/innodb_online_alter_log_max_size" }}
innodb_purge_threads={{ getv "/mysqld/innodb_purge_threads" }}
innodb_flush_neighbors={{ getv "/mysqld/innodb_flush_neighbors" }}
innodb_thread_concurrency={{ getv "/mysqld/innodb_thread_concurrency" }}
innodb_spin_wait_delay={{ getv "/mysqld/innodb_spin_wait_delay" }}
innodb_strict_mode={{ getv "/mysqld/innodb_strict_mode" }}
transaction_isolation={{ getv "/mysqld/transaction_isolation" }}
innodb_undo_directory={{ getenv "DATA_DIR" }}
innodb_data_file_path=ibdata1:1024M:autoextend
innodb_doublewrite={{ getv "/mysqld/innodb_doublewrite" }}
innodb_file_per_table={{ getv "/mysqld/innodb_file_per_table" }}
innodb_temp_data_file_path={{ getv "/mysqld/innodb_temp_data_file_path" }}
innodb_lru_scan_depth={{ getv "/mysqld/innodb_lru_scan_depth" }}
innodb_page_cleaners={{ getv "/mysqld/innodb_page_cleaners" }}
innodb_undo_log_truncate={{ getv "/mysqld/innodb_undo_log_truncate" }}

replica_net_timeout={{ getv "/mysqld/replica_net_timeout" }}
replica_parallel_workers={{ getv "/mysqld/replica_parallel_workers" }}
replica_transaction_retries={{ getv "/mysqld/replica_transaction_retries" }}
replica_preserve_commit_order={{ getv "/mysqld/replica_preserve_commit_order" }}
relay_log_purge={{ getv "/mysqld/relay_log_purge" }}

{{- if or (eq (getenv "ARCH_MODE") "rpl_semi_sync") (eq (getenv "ARCH_MODE") "rpl_async") }}
rpl_semi_sync_source_timeout = 2147483647
rpl_semi_sync_source_trace_level = 32
rpl_semi_sync_source_wait_no_replica = ON
rpl_semi_sync_source_wait_for_replica_count=1
rpl_semi_sync_replica_trace_level = 32
{{- end }}

{{- if contains (getenv "ARCH_MODE") "group_replication" }}
group_replication_group_name={{ getenv "MGR_NAME_UUID" "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" }}
group_replication_start_on_boot=OFF
group_replication_local_address="{{ getenv "POD_NAME" }}.{{ getenv "SERVICE_NAME" }}-headless-svc.{{ getenv "NAMESPACE" }}:33061"
group_replication_bootstrap_group=OFF
group_replication_recovery_get_public_key=ON
group_replication_message_cache_size=1G
{{- end }}
