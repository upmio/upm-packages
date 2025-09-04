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

[metadata_cache:mycluster]
cluster_type=gr
router_id={{add (atoi (getenv "UNIT_SN")) 1}}
user={{ getenv "PROV_USER" }}
metadata_cluster=mycluster
ttl=0.5
auth_cache_ttl=-1
auth_cache_refresh_interval=2
use_gr_notifications=0

[routing:mysql_rw]
bind_address=0.0.0.0
bind_port={{ getenv "MYSQL_ROUTER_PORT" "6446" }}
destinations=metadata-cache://mycluster/?role=PRIMARY
routing_strategy=first-available
protocol=classic

[routing:mysqlx_rw]
bind_address=0.0.0.0
bind_port={{ getenv "MYSQLX_ROUTER_PORT" "6447" }}
destinations=metadata-cache://mycluster/?role=PRIMARY
routing_strategy=first-available
protocol=x
router_require_enforce=0

[http_server]
port={{ getenv "HTTP_PORT" "8081" }}
ssl=0

# Exposes /api/20190715/swagger.json
[rest_api]

# Exposes /api/20190715/router/status
[rest_router]
require_realm=realmauth

# Exposes /api/20190715/routes/*
[rest_routing]
require_realm=realmauth

# Exposes /api/20190715/metadata/*
[rest_metadata_cache]
require_realm=realmauth

# Define our realm
[http_auth_realm:realmauth]
backend=filebackend
method=basic
name=Real Authentication

# Define our backend; this file must exist and be a password file generated with mysqlrouter_passwd (more on this below)
[http_auth_backend:filebackend]
backend=file
filename={{ getenv "DATA_MOUNT" }}/.mysqlrouter.pwd
