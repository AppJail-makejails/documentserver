#!/bin/sh

set -e

. /scripts/lib.subr

ds_conf_path="/usr/local/etc/onlyoffice/documentserver/nginx"
ds_conf="${ds_conf_path}/ds.conf"
ds_ssl_conf="${ds_conf_path}/ds-ssl.conf"

ONLYOFFICE_NGINX_WORKER_PROCESSES="${ONLYOFFICE_NGINX_WORKER_PROCESSES:-auto}"
ONLYOFFICE_NGINX_WORKER_CONNECTIONS="${ONLYOFFICE_NGINX_WORKER_CONNECTIONS:-1024}"

if [ -z "${ONLYOFFICE_SECURELINK_SECRET}" ]; then
	ONLYOFFICE_SECURELINK_SECRET=`pwgen -s 20`
fi

if [ -n "${ONLYOFFICE_TLS_CERT_PATH}" -a -n "${ONLYOFFICE_TLS_KEY_PATH}" ]; then
	if [ -f "${ONLYOFFICE_TLS_CERT_PATH}" -a -f "${ONLYOFFICE_TLS_KEY_PATH}" ]; then
		info "Enabling TLS ..."

		cp -a "${ds_ssl_conf}" "${ds_conf}"
		
		sed -e 's,{{SSL_CERTIFICATE_PATH}},'"${ONLYOFFICE_TLS_CERT_PATH}"',' -i '' "${ds_conf}"
		sed -e 's,{{SSL_KEY_PATH}},'"${ONLYOFFICE_TLS_KEY_PATH}"',' -i '' "${ds_conf}"
		sed -e 's,\(443 ssl\),\1 http2,' -i '' "${ds_conf}"

		if [ -z "${ONLYOFFICE_TLS_DHPARAM_PATH}" ] && [ -f "${ONLYOFFICE_TLS_DHPARAM_PATH}" ]; then
			sed -e 's,\(\#* *\)\?\(ssl_dhparam \).*\(;\)$,'"\2${ONLYOFFICE_TLS_DHPARAM_PATH}\3"',' -i '' "${ds_conf}"
		else
			sed -e '/ssl_dhparam/d' -i '' "${ds_conf}"
		fi

		sed -e 's,\(ssl_verify_client \).*\(;\)$,'"\1${ONLYOFFICE_TLS_VERIFY_CLIENT:-off}\2"',' -i '' "${ds_conf}"

		if [ -z "${ONLYOFFICE_CA_CERTIFICATES_PATH}" ] && [ -f "${ONLYOFFICE_CA_CERTIFICATES_PATH}" ]; then
			sed -e '/ssl_verify_client/a '"ssl_client_certificate ${ONLYOFFICE_CA_CERTIFICATES_PATH}"';' -i '' "${ds_conf}"
		fi

		if [ "${ONLYOFFICE_HTTPS_HSTS_ENABLED:-0}" != "0" ]; then
			sed -e 's,\(max-age=\).*\(;\)$,'"\1${ONLYOFFICE_HTTPS_HSTS_MAXAGE:-31536000}\2"',' -i '' "${ds_conf}"
		else
			sed -e '/max-age=/d' -i '' "${ds_conf}"
		fi
	fi
fi

info "Setting worker_processes -> ${ONLYOFFICE_NGINX_WORKER_PROCESSES}"
info "Setting worker_connections -> ${ONLYOFFICE_NGINX_WORKER_CONNECTIONS}"

# We use environment variables because documentserver-update-securelink.sh does not
# handle arguments correctly.
env RESTART_CONDITION=false \
    SECURE_LINK_SECRET="${ONLYOFFICE_SECURELINK_SECRET}" \
	documentserver-update-securelink.sh

cat << EOF > /usr/local/etc/nginx/nginx.conf
worker_processes    ${ONLYOFFICE_NGINX_WORKER_PROCESSES};

events {
    worker_connections    ${ONLYOFFICE_NGINX_WORKER_CONNECTIONS};
}

http {
    include              mime.types;
    default_type         application/octet-stream;
    sendfile             on;
    include              "${ds_conf}";
}
EOF
