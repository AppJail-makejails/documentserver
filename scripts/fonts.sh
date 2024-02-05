#!/bin/sh

set -e

. /scripts/lib.subr

if [ "${ONLYOFFICE_GENERATE_FONTS:-1}" != "0" ]; then
	info "Generating fonts ..."
	documentserver-generate-allfonts.sh
fi
