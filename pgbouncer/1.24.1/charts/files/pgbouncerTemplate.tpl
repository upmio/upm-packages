[databases]
* = host={{ index (jsonArray (getv "/service_postgresql_array")) 0 }}-replication-readwrite port={{ getv "/postgresql_postgresql_port" }} auth_user={{ getenv "ADM_USER" }}
[pgbouncer]
listen_addr = *
listen_port = {{getenv "PGBOUNCER_PORT" }}
logfile = {{getenv "LOG_MOUNT"}}/pgbouncer.log
pidfile = {{getenv "DATA_MOUNT"}}/pgbouncer.pid
unix_socket_dir = {{getenv "DATA_MOUNT"}}
unix_socket_mode = 0777
auth_type = md5
auth_query = SELECT rolname, CASE WHEN rolvaliduntil < now() THEN NULL ELSE rolpassword END FROM pg_authid WHERE rolname=$1 AND rolcanlogin
auth_file = {{getenv "DATA_MOUNT"}}/userlist.txt
admin_users = {{ getenv "ADM_USER" }}
pool_mode = {{ getv "/pgbouncer/pool_mode" }}
min_pool_size = {{ getv "/pgbouncer/min_pool_size" }}
default_pool_size = {{ getv "/pgbouncer/default_pool_size" }}
max_client_conn = {{ getv "/pgbouncer/max_client_conn" }}
max_db_connections = {{ getv "/pgbouncer/max_db_connections" }}
max_user_connections = {{ getv "/pgbouncer/max_user_connections" }}