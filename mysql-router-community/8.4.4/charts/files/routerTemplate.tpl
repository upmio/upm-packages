[DEFAULT]
name={{ getenv "SERVICE_GROUP_NAME" }}
user=mysql-router
logging_folder={{ getenv "LOG_MOUNT" }}
runtime_folder={{ getenv "DATA_DIR" }}/run
data_folder={{ getenv "DATA_DIR" }}/data
keyring_path={{ getenv "DATA_DIR" }}/data/keyring
master_key_path={{ getenv "DATA_DIR" }}/mysqlrouter.key
max_total_connections={{ getv "/default/max_total_connections" }}
connect_timeout={{ getv "/default/connect_timeout" }}
read_timeout={{ getv "/default/read_timeout" }}
dynamic_state={{ getenv "DATA_DIR" }}/data/state.json
client_ssl_cert={{ getenv "DATA_DIR" }}/data/router-cert.pem
client_ssl_key={{ getenv "DATA_DIR" }}/data/router-key.pem
client_ssl_mode=PREFERRED
server_ssl_mode=PREFERRED
server_ssl_verify=DISABLED
unknown_config_option={{ getv "/default/unknown_config_option" }}
max_idle_server_connections={{ getv "/default/max_idle_server_connections" }}
router_require_enforce=1

[logger]
level={{ getv "/logger/level" }}

[metadata_cache:{{ getenv "SERVICE_GROUP_NAME" }}]
cluster_type=gr
router_id={{add (atoi (getenv "UNIT_SN")) 1}}
user={{ getenv "PROV_USER" }}
metadata_cluster=mycluster
ttl=0.5
auth_cache_ttl=-1
auth_cache_refresh_interval=2
use_gr_notifications=0

[routing:{{ getenv "SERVICE_GROUP_NAME" }}_rw]
bind_address=0.0.0.0
bind_port={{ getenv "MYSQL-ROUTER_PORT" }}
destinations=metadata-cache://mycluster/?role=PRIMARY
routing_strategy=first-available
protocol=classic

[routing:{{ getenv "SERVICE_GROUP_NAME" }}_x_rw]
bind_address=0.0.0.0
bind_port={{ getenv "MYSQLX-ROUTER_PORT" }}
destinations=metadata-cache://testCluster/?role=PRIMARY
routing_strategy=first-available
protocol=x
router_require_enforce=0

[http_server]
port={{ getenv "HTTP_PORT" }}
ssl=0

[http_auth_realm:default_auth_realm]
backend=default_auth_backend
method=basic
name=default_realm

[rest_router]
require_realm=default_auth_realm

[rest_api]

[http_auth_backend:default_auth_backend]
backend=metadata_cache

[rest_routing]
require_realm=default_auth_realm

[rest_metadata_cache]
require_realm=default_auth_realm
