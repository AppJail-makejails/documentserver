#!/bin/sh

set -e

. /scripts/lib.subr

ONLYOFFICE_USE_UNAUTHORIZED_STORAGE="${ONLYOFFICE_USE_UNAUTHORIZED_STORAGE:-false}"

info "Configuring services.CoAuthoring.requestDefaults.rejectUnauthorized -> ${ONLYOFFICE_USE_UNAUTHORIZED_STORAGE}"
put_local -t bool -v "${ONLYOFFICE_USE_UNAUTHORIZED_STORAGE}" services.CoAuthoring.requestDefaults.rejectUnauthorized
