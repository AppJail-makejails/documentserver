#!/bin/sh

set -e

. /scripts/lib.subr

ONLYOFFICE_WOPI_ENABLED="${ONLYOFFICE_WOPI_ENABLED:-false}"

info "Configuring wopi.enable -> ${ONLYOFFICE_WOPI_ENABLED}"
put_local -t bool -v "${ONLYOFFICE_WOPI_ENABLED}" wopi.enable
