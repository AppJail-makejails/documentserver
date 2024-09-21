# Document Server

OnlyOffice is a free software office suite and ecosystem of collaborative applications. It features online editors for text documents, spreadsheets, presentations, forms and PDFs, and the room-based collaborative platform. 

wikipedia.org/wiki/OnlyOffice

<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/6/64/ONLYOFFICE_logo_%28default%29.svg/1024px-ONLYOFFICE_logo_%28default%29.svg.png" width="80%" height="auto">

## How to use this Makejail

### Standalone

```sh
appjail makejail \
    -j documentserver \
    -f gh+AppJail-makejails/documentserver \
    -o virtualnet=":<random> default" \
    -o nat \
    -o expose=80
```

> [!IMPORTANT]  
> Note that this Makejail uses some default values. Please read [#environment](#environment) and [#deploy-using-appjail-director](#deploy-using-appjail-director) for more details.

### Deploy using appjail-director

**appjail-director.yml**:

```yaml
options:
  - virtualnet: ':<random> default'
  - nat:

services:
  documentserver:
    name: documentserver
    makejail: gh+AppJail-makejails/documentserver
    options:
      - expose: 80
    environment:
      - ONLYOFFICE_REDIS_ENABLED: '1'
      - ONLYOFFICE_SECURELINK_SECRET: 'verysecretstring'
      - ONLYOFFICE_JWT_ENABLED: 'true'
      - ONLYOFFICE_DB_TYPE: 'mariadb'
    volumes:
      - ds-data: documentserver-data
      - ds-db: documentserver-db
      - ds-log: documentserver-log

  db:
    name: onlyoffice-db
    makejail: gh+AppJail-makejails/mariadb
    arguments:
      - mariadb_user: 'onlyoffice'
      - mariadb_password: 'onlyoffice'
      - mariadb_database: 'onlyoffice'
      - mariadb_root_password: 'onlyoffice-rt'
    volumes:
      - mariadb-db: mariadb-db
      - mariadb-done: mariadb-done
    priority: 98

  cache:
    name: onlyoffice-redis
    makejail: gh+AppJail-makejails/redis
    priority: 98

  amqp:
    name: onlyoffice-amqp
    makejail: ./rabbitmq.makejail
    volumes:
      - rabbitmq-db: rabbitmq-db
      - rabbitmq-log: rabbitmq-log
    priority: 98

default_volume_type: '<volumefs>'

volumes:
  ds-data:
    device: .volumes/ds/data
  ds-db:
    device: .volumes/ds/db
  ds-log:
    device: .volumes/ds/log
  mariadb-db:
    device: .volumes/mariadb/db
  mariadb-done:
    device: .volumes/mariadb/done
  rabbitmq-db:
    device: .volumes/rabbitmq/db
  rabbitmq-log:
    device: .volumes/rabbitmq/log
```

**rabbitmq.makejail**:

```
INCLUDE gh+AppJail-makejails/rabbitmq

RAW if ! appjail cmd jexec "${APPJAIL_JAILNAME}" [ -f "/var/db/rabbitmq/.erlang.cookie" ] || ! appjail cmd jexec "${APPJAIL_JAILNAME}" rabbitmqctl --erlang-cookie `appjail cmd jexec "${APPJAIL_JAILNAME}" cat /var/db/rabbitmq/.erlang.cookie` list_users | cut -d$'\t' -f1 | tail -n +3 | grep -qFw "onlyoffice"; then
	CMD rabbitmqctl --erlang-cookie `cat /var/db/rabbitmq/.erlang.cookie` add_user onlyoffice onlyoffice
	CMD rabbitmqctl --erlang-cookie `cat /var/db/rabbitmq/.erlang.cookie` set_user_tags onlyoffice administrator
	CMD rabbitmqctl --erlang-cookie `cat /var/db/rabbitmq/.erlang.cookie` set_permissions -p / onlyoffice ".*" ".*" ".*"
RAW fi
```

**.env**:

```
DIRECTOR_PROJECT=onlyoffice
```

Run `appjail-director up` and wait until the project finishes. In just a few minutes you have **ONLYOFFICE** DocumentServer deployed. If you want to redeploy, execute the following commands:

```sh
appjail-director down -d && 
    appjail-director up
```

### Arguments

* `documentserver_tag` (default: `13.4`): See [#tags](#tags).

### Environment

* `ONLYOFFICE_AMQP_TYPE` (default: `rabbitmq`): Queue server to be used. Valid values: `rabbitmq`, `activemq`.
* `ONLYOFFICE_AMQP_PROTO` (default: `amqp`): Queue protocol. For `activemq` you can use `amqp+ssl` or `amqps` to activate `tls`.
* `ONLYOFFICE_AMQP_HOST` (default: `onlyoffice-amqp`): Queue server host.
* `ONLYOFFICE_AMQP_PORT` (default: `5672`): Queue server port.
* `ONLYOFFICE_AMQP_USER` (default: `onlyoffice`): User name for the queue server.
* `ONLYOFFICE_AMQP_PASS` (default: `onlyoffice`): Password for the queue server.
* `ONLYOFFICE_DB_TYPE` (default: `postgres`): Database backend to be used. Valid values: `postgres`, `mariadb`, `mysql`.
* `ONLYOFFICE_DB_HOST` (default: `onlyoffice-db`): Database server host (host name or IP address).
* `ONLYOFFICE_DB_PORT` (default: `5432` or `3306`): Database server port. When this environment variable is not defined and `ONLYOFFICE_AMQP_TYPE` is `postgres`, this value is `5432` or `3306` if the queue type is `postgres`.
* `ONLYOFFICE_DB_USER` (default: `onlyoffice`): User name with superuser permissions for the database account.
* `ONLYOFFICE_DB_PASS` (default: `onlyoffice`): Password for the database account.
* `ONLYOFFICE_DB_NAME` (default: `onlyoffice`): Name of a database to be used.
* `ONLYOFFICE_GENERATE_FONTS` (default: `1`): Run `document-generate-allfonts.sh` when this value is other than `0`.
* `ONLYOFFICE_ALLOW_META_IP_ADDRESS` (default: `true`): Defines if it is allowed to connect meta IP address or not. Meta address can be `0.0.0.0` (IPv4) or `::` (IPv6) - a meta address that routing another address.
* `ONLYOFFICE_ALLOW_PRIVATE_IP_ADDRESS` (default: `true`): Defines if it is allowed to connect private IP address or not. This includes private IP addresses and reserved IP addresses.
* `ONLYOFFICE_JWT_ENABLED` (default: `true`): Defines if a token in is enabled or not.
* `ONLYOFFICE_JWT_SECRET` (default: `secret`): Defines the secret key used by the JWT.
* `ONLYOFFICE_JWT_HEADER` (default: `Authorization`): Defines the HTTP header that will be used to send the token.
* `ONLYOFFICE_JWT_IN_BODY` (default: `false`): Defines if a token is enabled in the request body or not.
* `ONLYOFFICE_DS_LOG_LEVEL` (optional): DocService log level.
* `ONLYOFFICE_METRICS_ENABLED` (default: `false`): Defines if the StatsD metrics are enabled for ONLYOFFICE Docs or not.
* `ONLYOFFICE_NGINX_WORKER_PROCESSES` (default: `auto`): See [worker\_processes](https://nginx.org/en/docs/ngx_core_module.html#worker_processes).
* `ONLYOFFICE_NGINX_WORKER_CONNECTIONS` (default: `1024`): See [worker\_connections](https://nginx.org/en/docs/ngx_core_module.html#worker_connections).
* `ONLYOFFICE_SECURELINK_SECRET` (optional): See [Securing URLs with the Secure Link Module in NGINX and NGINX Plus](https://www.nginx.com/blog/securing-urls-secure-link-module-nginx-plus/) for details. A random string is used by default, but it is recommended to configure this environment variable explicitly.
* `ONLYOFFICE_TLS_CERT_PATH` (optional): Path to a TLS certificate file inside the jail. This enables TLS, so you need to expose `443` to take effect. You should also set 'ONLYOFFICE_TLS_KEY_PATH' and both should exist.
* `ONLYOFFICE_TLS_KEY_PATH` (optional): Path to a TLS key file inside the jail.
* `ONLYOFFICE_TLS_DHPARAM_PATH` (optional): Specifies a file inside the jail with DH parameters for DHE ciphers. See [ssl_dhparam](https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_dhparam).
* `ONLYOFFICE_TLS_VERIFY_CLIENT` (default: `off`): See [ssl_verify_client](https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_verify_client).
* `ONLYOFFICE_CA_CERTIFICATES_PATH` (optional): Specifies a file with trusted CA certificates in the PEM format used to verify client certificates and OCSP responses if ssl_stapling is enabled. See [ssl_client_certificate](https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_client_certificate).
* `ONLYOFFICE_HTTPS_HSTS_ENABLED` (default: `0`): Enables HSTS when this value is other than 0.
* `ONLYOFFICE_HTTPS_HSTS_MAXAGE` (default: `31536000`): The time, in seconds, that the browser should remember that this site is only to be accessed using HTTPS.
* `ONLYOFFICE_PLUGINS_ENABLED` (default: `0`): Install plugins.
* `ONLYOFFICE_PLUGINS` (default: `highlightcode;macros;mendeley;ocr;photoeditor;speech;thesaurus;translator;youtube;zotero`): List of plugins to install separated by semicolons.
* `ONLYOFFICE_REDIS_ENABLED` (default: `0`): Enables Redis.
* `ONLYOFFICE_REDIS_HOST` (default: `onlyoffice-redis`): Redis server host (host name or IP address).
* `ONLYOFFICE_REDIS_PORT` (default: `6379`): Redis server port.
* `ONLYOFFICE_REDIS_PASS` (optional): Password for the Redis account.
* `ONLYOFFICE_USE_UNAUTHORIZED_STORAGE` (default: `false`): Defines if the certificates will be verified by the Document Server or not.
* `ONLYOFFICE_WOPI_ENABLED` (default: `false`): Defines if WOPI is enabled or not.

### Volumes

| Name                | Owner | Group | Perm | Type | Mountpoint                     |
| ------------------- | ----- | ----- | ---- | ---- | ------------------------------ |
| documentserver-db   | 303   | 303   |  -   |  -   | /var/db/onlyoffice             |
| documentserver-data | 303   | 303   |  -   |  -   | /usr/local/www/onlyoffice/Data |
| documentserver-log  | 303   | 303   |  -   |  -   | /var/log/onlyoffice            |

## Tags

| Tag     | Arch    | Version        | Type   |
| ------- | ------- | -------------- | ------ |
| `13.4`  | `amd64` | `13.4-RELEASE` | `thin` |
| `14.1`  | `amd64` | `14.1-RELEASE` | `thin` |

## Notes

* In testing, this Makejail successfully deploy Document Server without problems in the use cases: `HTTP + NO JWT`, `HTTP + JWT`, `HTTPS + NO JWT`, but when `HTTPS + JWT` simply cannot be configured in Nextcloud. A self-signed certificate is used. If you can test this case with a self-signed certificate and/or a certificate signed by a CA, please inform me.
