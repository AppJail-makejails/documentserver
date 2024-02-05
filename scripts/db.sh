#!/bin/sh

set -e

. /scripts/lib.subr

ONLYOFFICE_DB_TYPE="${ONLYOFFICE_DB_TYPE:-postgres}"

case "${ONLYOFFICE_DB_TYPE}" in
	postgres) ;;
	mariadb|mysql) ;;
	*) err "Unknown database type."; exit 1 ;;
esac

ONLYOFFICE_DB_HOST="${ONLYOFFICE_DB_HOST:-onlyoffice-db}"

if [ -z "${ONLYOFFICE_DB_PORT}" ]; then
	case "${ONLYOFFICE_DB_TYPE}" in
		postgres) ONLYOFFICE_DB_PORT="5432" ;;
		mariadb|mysql) ONLYOFFICE_DB_PORT="3306" ;;
	esac
fi

ONLYOFFICE_DB_USER="${ONLYOFFICE_DB_USER:-onlyoffice}"
ONLYOFFICE_DB_PASS="${ONLYOFFICE_DB_PASS:-onlyoffice}"
ONLYOFFICE_DB_NAME="${ONLYOFFICE_DB_NAME:-onlyoffice}"

info "Configuring services.CoAuthoring.sql.type -> ${ONLYOFFICE_DB_TYPE}"
put_local -t string -v "${ONLYOFFICE_DB_TYPE}" services.CoAuthoring.sql.type

info "Configuring services.CoAuthoring.sql.dbHost -> ${ONLYOFFICE_DB_HOST}"
put_local -t string -v "${ONLYOFFICE_DB_HOST}" services.CoAuthoring.sql.dbHost

info "Configuring services.CoAuthoring.sql.dbPort -> ${ONLYOFFICE_DB_PORT}"
put_local -t int -v "${ONLYOFFICE_DB_PORT}" services.CoAuthoring.sql.dbPort

info "Configuring services.CoAuthoring.sql.dbUser -> ${ONLYOFFICE_DB_USER}"
put_local -t string -v "${ONLYOFFICE_DB_USER}" services.CoAuthoring.sql.dbUser

info "Configuring services.CoAuthoring.sql.dbPass -> ${ONLYOFFICE_DB_PASS}"
put_local -t string -v "${ONLYOFFICE_DB_PASS}" services.CoAuthoring.sql.dbPass

info "Configuring services.CoAuthoring.sql.dbName -> ${ONLYOFFICE_DB_NAME}"
put_local -t string -v "${ONLYOFFICE_DB_NAME}" services.CoAuthoring.sql.dbName

for sql_file in removetbl createdb; do
	info "Executing ${sql_file}.sql ..."

	case "${ONLYOFFICE_DB_TYPE}" in
		postgres)
			export PGPASSWORD="${ONLYOFFICE_DB_PASS}"

			psql \
				-qw \
				-h "${ONLYOFFICE_DB_HOST}" \
				-p "${ONLYOFFICE_DB_PORT}" \
				-U "${ONLYOFFICE_DB_USER}" \
				-d "${ONLYOFFICE_DB_NAME}" \
				-f /usr/local/www/onlyoffice/documentserver/server/schema/postgresql/${sql_file}.sql
			;;
		mariadb|mysql)
			mysql \
				-w \
				-h"${ONLYOFFICE_DB_HOST}" \
				-P"${ONLYOFFICE_DB_PORT}" \
				-u"${ONLYOFFICE_DB_USER}" \
				-p"${ONLYOFFICE_DB_PASS}" \
				-D"${ONLYOFFICE_DB_NAME}" < /usr/local/www/onlyoffice/documentserver/server/schema/mysql/${sql_file}.sql
			;;
	esac
done
