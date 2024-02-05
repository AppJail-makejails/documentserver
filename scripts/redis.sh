#!/bin/sh

set -e

. /scripts/lib.subr

if [ "${ONLYOFFICE_REDIS_ENABLED:-0}" != "0" ]; then
	ONLYOFFICE_REDIS_HOST="${ONLYOFFICE_REDIS_HOST:-onlyoffice-redis}"
	ONLYOFFICE_REDIS_PORT="${ONLYOFFICE_REDIS_PORT:-6379}"

	info "Configuring services.CoAuthoring.redis.host -> ${ONLYOFFICE_REDIS_HOST}"
	put_local -t string -v "${ONLYOFFICE_REDIS_HOST}" services.CoAuthoring.redis.host

	info "Configuring services.CoAuthoring.redis.port -> ${ONLYOFFICE_REDIS_PORT}"
	put_local -t int -v "${ONLYOFFICE_REDIS_PORT}" services.CoAuthoring.redis.port

	if [ -n "${ONLYOFFICE_REDIS_PASS}" ]; then
		info "Configuring services.CoAuthoring.redis.options.password -> ${ONLYOFFICE_REDIS_PASS}"
		put_local -t string -v "${ONLYOFFICE_REDIS_PASS}" services.CoAuthoring.redis.options.password
	fi
fi
