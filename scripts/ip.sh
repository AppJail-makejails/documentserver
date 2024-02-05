#!/bin/sh

set -e

. /scripts/lib.subr

ONLYOFFICE_ALLOW_META_IP_ADDRESS="${ONLYOFFICE_ALLOW_META_IP_ADDRESS:-true}"
ONLYOFFICE_ALLOW_PRIVATE_IP_ADDRESS="${ONLYOFFICE_ALLOW_PRIVATE_IP_ADDRESS:-true}"

info "Configuring services.CoAuthoring.request-filtering-agent.allowPrivateIPAddress -> ${ONLYOFFICE_ALLOW_META_IP_ADDRESS}"
put_local -t bool -v "${ONLYOFFICE_ALLOW_META_IP_ADDRESS}" services.CoAuthoring.request-filtering-agent.allowPrivateIPAddress

info "Configuring services.CoAuthoring.request-filtering-agent.allowMetaIPAddress -> ${ONLYOFFICE_ALLOW_PRIVATE_IP_ADDRESS}"
put_local -t bool -v "${ONLYOFFICE_ALLOW_PRIVATE_IP_ADDRESS}" services.CoAuthoring.request-filtering-agent.allowMetaIPAddress
