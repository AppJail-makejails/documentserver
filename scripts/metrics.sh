#!/bin/sh

set -e

. /scripts/lib.subr

ONLYOFFICE_METRICS_ENABLED="${ONLYOFFICE_METRICS_ENABLED:-false}"

info "Configuring statsd.useMetrics -> ${ONLYOFFICE_METRICS_ENABLED}"
put_local -t bool -v "${ONLYOFFICE_METRICS_ENABLED}" statsd.useMetrics
