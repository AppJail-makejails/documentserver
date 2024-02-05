#!/bin/sh

set -e

. /scripts/lib.subr

if [ -n "${ONLYOFFICE_DS_LOG_LEVEL}" ]; then
	info "Configuring categories.default.level -> ${ONLYOFFICE_DS_LOG_LEVEL}"
	put_log4js -t string -v "${ONLYOFFICE_DS_LOG_LEVEL}" categories.default.level
fi
