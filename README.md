# ONLYOFFICE Document Server

ONLYOFFICE Document Server is an online office suite comprising viewers and editors for texts, spreadsheets and presentations, fully compatible with Office Open XML formats: .docx, .xlsx, .pptx and enabling collaborative editing in real time.

wikipedia.org/wiki/OnlyOffice

<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/6/64/ONLYOFFICE_logo_%28default%29.svg/1280px-ONLYOFFICE_logo_%28default%29.svg.png" width="30%" height="auto" alt="ONLYOFFICE Document Server logo">

## How to use this Makejail

### Standalone

All the data are stored in the specially-designated directories, **data volumes**, at the following location:

* **/var/log/onlyoffice** for ONLYOFFICE Document Server logs
* **/usr/local/www/onlyoffice/Data** for certificates
* **/var/db/onlyoffice** for file cache

To get access to your data from outside the container, you need to mount the volumes. It can be done by specifying the `-o fstab` option in the `appjail oci run` command.

```console
$ mkdir -p /var/appjail-volumes/documentserver/data
$ mkdir -p /var/appjail-volumes/documentserver/log
$ mkdir -p /var/appjail-volumes/documentserver/db
$ appjail oci run -Pd \
    -o overwrite=force \
    -o virtualnet=":<random> default" \
    -o nat \
    -o expose=80 \
    -o fstab="/var/appjail-volumes/documentserver/data /usr/local/www/onlyoffice/Data" \
    -o fstab="/var/appjail-volumes/documentserver/log /var/log/onlyoffice" \
    -o fstab="/var/appjail-volumes/documentserver/db /var/db/onlyoffice" \
    ghcr.io/appjail-makejails/documentserver documentserver
```

### Running ONLYOFFICE Document Server on Different Port

To change the port, use the `-o expose`. E.g.: to make your portal accessible for external hosts via port `8080` execute the following command:

```console
$ appjail oci run -Pd \
    -o overwrite=force \
    -o virtualnet=":<random> default" \
    -o nat \
    -o expose=8080:80 \
    -o fstab="/var/appjail-volumes/documentserver/data /usr/local/www/onlyoffice/Data" \
    -o fstab="/var/appjail-volumes/documentserver/log /var/log/onlyoffice" \
    -o fstab="/var/appjail-volumes/documentserver/db /var/db/onlyoffice" \
    ghcr.io/appjail-makejails/documentserver documentserver
```

### Running ONLYOFFICE Document Server using HTTPS

Access to the ONLYOFFICE application can be secured using TLS so as to prevent unauthorized access. While a CA certified TLS certificate allows for verification of trust via the CA, a self-signed certificate can also provide an equal level of trust verification as long as each client takes some additional steps to verify the identity of your website. Below the instructions on achieving this are provided.

To secure the application via TLS basically two things are needed:

* **Private key (.key)**
* **TLS certificate (.crt)**

So you need to create and install the following files:

* `/usr/local/www/onlyoffice/documentserver/Data/certs/tls.key`
* `/usr/local/www/onlyoffice/documentserver/Data/certs/tls.crt`

When using CA certified certificates (e.g. [Let's Encrypt](https://letsencrypt.org/)), these files are provided to you by the CA. If you are using self-signed certificates you need to generate these files [yourself](#generation-of-self-signed-certificates).

#### Using the automatically generated Let's Encrypt TLS Certificates

```console
$ appjail oci run -Pd \
    -o overwrite=force \
    -o virtualnet=":<random> default" \
    -o nat \
    -o expose=80 \
    -o expose=443 \
    -o fstab="/var/appjail-volumes/documentserver/data /usr/local/www/onlyoffice/Data" \
    -o fstab="/var/appjail-volumes/documentserver/log /var/log/onlyoffice" \
    -o fstab="/var/appjail-volumes/documentserver/db /var/db/onlyoffice" \
    -e LETS_ENCRYPT_DOMAIN=your_domain \
    -e LETS_ENCRYPT_MAIL=your_mail \
    ghcr.io/appjail-makejails/documentserver documentserver
```

#### Generation of Self Signed Certificates

**STEP 1**: Create the server private key

```console
$ openssl genrsa 2048 | appjail secrets create documentserver/tls.key
```

**STEP 2**: Create the certificate signing request (CSR)

```console
$ appjail secrets cat documentserver/tls.key | openssl req -new -key /dev/stdin -subj "/CN=documentserver.ajnet.appjail" | appjail secrets create documentserver/tls.csr
```

**STEP 3**: Sign the certificate using the private key and CSR

```console
$ mkfifo -m 0600 tls.csr.fifo tls.key.fifo
$ appjail secrets cat documentserver/tls.csr > tls.csr.fifo &
$ appjail secrets cat documentserver/tls.key > tls.key.fifo &
$ openssl x509 -req -days 365 -in tls.csr.fifo -signkey tls.key.fifo | appjail secrets create documentserver/tls.crt
$ rm -f tls.csr.fifo tls.key.fifo
```

You have now generated a TLS certificate that's valid for 365 days.

#### Strengthening the server security

This section provides you with instructions to [strengthen your server security](https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html). To achieve this you need to generate stronger DHE parameters.

```console
$ openssl dhparam 2048 | appjail secrets create documentserver/dhparam.pem
```

#### Installation of the TLS Certificates

Out of the four files generated above, you need to install the `tls.key`, `tls.crt` and `dhparam.pem` files at the ONLYOFFICE server. The CSR file is not needed, but do make sure you safely backup the file (in case you ever need it again).

The default path that the ONLYOFFICE application is configured to look for the TLS certificates is at `/usr/local/www/onlyoffice/Data/certs`, this can however be changed using the `SSL_KEY_PATH`, `SSL_CERTIFICATE_PATH` and `SSL_DHPARAM_PATH` configuration options. Since we have used [AppJail Secrets](https://appjail.readthedocs.io/en/latest/secrets/) to store the certificate, key, and dhparam files, we must use the environment variables mentioned above.

You are now just one step away from having our application secured.

#### Using self-signed certificates with AppJail secrets

```console
$ appjail oci run -Pd \
    -o overwrite=force \
    -o virtualnet=":<random> default" \
    -o nat \
    -o expose=80 \
    -o expose=443 \
    -o fstab="/var/appjail-volumes/documentserver/data /usr/local/www/onlyoffice/Data" \
    -o fstab="/var/appjail-volumes/documentserver/log /var/log/onlyoffice" \
    -o fstab="/var/appjail-volumes/documentserver/db /var/db/onlyoffice" \
    -o secret="documentserver" \
    -e SSL_CERTIFICATE_PATH="/secrets/documentserver/tls.crt" \
    -e SSL_KEY_PATH="/secrets/documentserver/tls.key" \
    -e SSL_DHPARAM_PATH="/secrets/documentserver/dhparam.pem" \
    ghcr.io/appjail-makejails/documentserver documentserver
```

### Available Configuration Parameters

Below is the complete list of parameters that can be set using environment variables.

* **ONLYOFFICE_HTTPS_HSTS_ENABLED**: Advanced configuration option for turning off the HSTS configuration. Applicable only when SSL is in use. Defaults to `true`.
* **ONLYOFFICE_HTTPS_HSTS_MAXAGE**: Advanced configuration option for setting the HSTS max-age in the ONLYOFFICE nginx vHost configuration. Applicable only when SSL is in use. Defaults to `31536000`.
* **SSL_CERTIFICATE_PATH**: The path to the SSL certificate to use. Defaults to `/usr/local/www/onlyoffice/Data/certs/tls.crt`.
* **SSL_KEY_PATH**: The path to the SSL certificate's private key. Defaults to `/usr/local/www/onlyoffice/Data/certs/tls.key`.
* **SSL_DHPARAM_PATH**: The path to the Diffie-Hellman parameter. Defaults to `/usr/local/www/onlyoffice/Data/certs/dhparam.pem`.
* **SSL_VERIFY_CLIENT**: Enable verification of client certificates using the `CA_CERTIFICATES_PATH` file. Defaults to `false`
* **NODE_EXTRA_CA_CERTS**: The [NODE_EXTRA_CA_CERTS](https://nodejs.org/api/cli.html#node_extra_ca_certsfile "Node.js documentation") to extend CAs with the extra certificates for Node.js. Defaults to `/usr/local/www/onlyoffice/Data/certs/extra-ca-certs.pem`.
* **NGINX_WORKER_PROCESSES**: Defines the number of nginx worker processes.
* **NGINX_WORKER_CONNECTIONS**: Sets the maximum number of simultaneous connections that can be opened by a nginx worker process. Defaults to the soft limit from `ulimit -n`.
* **NGINX_ACCESS_LOG**: Defines whether access logging is enabled. Defaults to `false`.
* **SECURE_LINK_SECRET**: Defines secret for the nginx config directive [secure_link_md5](https://nginx.org/en/docs/http/ngx_http_secure_link_module.html#secure_link_md5). Defaults to `random string`.
* **JWT_ENABLED**: Specifies the enabling the JSON Web Token validation by the ONLYOFFICE Document Server. Defaults to `true`.
* **JWT_SECRET**: Defines the secret key to validate the JSON Web Token in the request to the ONLYOFFICE Document Server. Defaults to random value.
* **JWT_HEADER**: Defines the http header that will be used to send the JSON Web Token. Defaults to `Authorization`.
* **JWT_IN_BODY**: Specifies the enabling the token validation in the request body to the ONLYOFFICE Document Server. Defaults to `false`.
* **WOPI_ENABLED**: Specifies the enabling the wopi handlers. Defaults to `false`.
* **ALLOW_META_IP_ADDRESS**: Defines if it is allowed to connect meta IP address or not. Defaults to `false`.
* **ALLOW_PRIVATE_IP_ADDRESS**: Defines if it is allowed to connect private IP address or not. Defaults to `false`.
* **USE_UNAUTHORIZED_STORAGE**: Set to `true` if using self-signed certificates for your storage server e.g. Nextcloud. Defaults to `false`
* **GENERATE_FONTS**: When 'true' regenerates fonts list and the fonts thumbnails etc. at each start. Defaults to `true`
* **EXAMPLE_ENABLED**: Enables example service autostart. Defaults to `false`.
* **METRICS_ENABLED**: Specifies the enabling StatsD for ONLYOFFICE Document Server. Defaults to `false`.
* **METRICS_HOST**: Defines StatsD listening host. Defaults to `localhost`.
* **METRICS_PORT**: Defines StatsD listening port. Defaults to `8125`.
* **METRICS_PREFIX**: Defines StatsD metrics prefix for backend services. Defaults to `ds.`.
* **LETS_ENCRYPT_DOMAIN**: Defines the domain for Let's Encrypt certificate.
* **LETS_ENCRYPT_MAIL**: Defines the domain administrator mail address for Let's Encrypt certificate.
* **PLUGINS_ENABLED**: Defines whether to enable default plugins. Defaults to `true`.

### Installing ONLYOFFICE Document Server using AppJail Director

You can also install ONLYOFFICE Document Server using [appjail-director](https://github.com/DtxdF/director#installation).

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
      - secret: documentserver
      - container: 'args:--pull'
    oci:
      environment:
        # Enable JSON Web Token validation:
        - JWT_ENABLED: 'true'
        - JWT_SECRET: !ENV '${JWT_SECRET:verysecurestring}'
        - JWT_HEADER: Authorization
        - JWT_IN_BODY: 'true'
        # Enable TLS.
        - SSL_CERTIFICATE_PATH: /secrets/documentserver/tls.crt
        - SSL_KEY_PATH: /secrets/documentserver/tls.key
        - SSL_DHPARAM_PATH: /secrets/documentserver/dhparam.pem
        # Uncomment if you plan to use self-signed certificates with a service
        # like Nextcloud in a trusted network (e.g. the host).
        #- NODE_TLS_REJECT_UNAUTHORIZED: 0
        #- USE_UNAUTHORIZED_STORAGE: 'true'
    volumes:
      - ds-data: /usr/local/www/onlyoffice/Data
      - ds-log: /var/log/onlyoffice
      - ds-db: /var/db/onlyoffice

volumes:
  ds-data:
    device: '/var/appjail-volumes/documentserver/data'
  ds-log:
    device: '/var/appjail-volumes/documentserver/log'
  ds-db:
    device: '/var/appjail-volumes/documentserver/db'
```

**.env**:

```dotenv
DIRECTOR_PROJECT=documentserver
# Use 'openssl rand -base64 32' to get a valid JWT secret.
JWT_SECRET=D3gIWZ2Awqcn5ezvgCNdq8xOZZ6GeprJpm1PeFrysTo=
```

**Profit!**:

```console
$ appjail-director up
```

### Arguments (stage: build)

* `documentserver_from` (default: `ghcr.io/appjail-makejails/documentserver`): Location of OCI image. See also [OCI Configuration](#oci-configuration).
* `documentserver_tag` (default: `latest`): OCI image tag. See also [OCI Configuration](#oci-configuration).


### Volumes

| Name | Owner | Group | Perm | Type | Mountpoint |
| --- | --- | --- | --- | --- | --- |
| appjail-46163c6bf3-var_db_onlyoffice | `${PUID}` | `${PGID}` | - | - | /var/db/onlyoffice |
| appjail-4f2f8e1e76-usr_local_www_onlyoffice_Data | `${PUID}` | `${PGID}` | - | - | /usr/local/www/onlyoffice/Data |
| appjail-7274b415ea-var_log_onlyoffice | `${PUID}` | `${PGID}` | - | - | /var/log/onlyoffice |

## OCI Configuration

```yaml
build:
  variants:
    - tag: 15.1
      containerfile: Containerfile
      aliases: ["latest"]
      default: true
      args:
        FREEBSD_RELEASE: "15.1"
        PYVER: "312"
        NO_PKGCLEAN: "1"
      cache_dirs: ["pkgcache0:/var/cache/pkg"]
```

## Notes

1. The ideas present in the Docker image of Document Server are taken into account for users who are familiar with it.
2. Unlike upstream that implement a Dockerfile for the three editions, community, enterprise and developer, the first one is the one that makes sense since the port is based on that edition.
