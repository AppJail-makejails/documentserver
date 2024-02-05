#!/bin/sh

set -e

. /scripts/lib.subr

ONLYOFFICE_JWT_ENABLED="${ONLYOFFICE_JWT_ENABLED:-false}"
ONLYOFFICE_JWT_SECRET="${ONLYOFFICE_JWT_SECRET:-secret}"
ONLYOFFICE_JWT_HEADER="${ONLYOFFICE_JWT_HEADER:-Authorization}"
ONLYOFFICE_JWT_IN_BODY="${ONLYOFFICE_JWT_IN_BODY:-false}"

for key in browser request.inbox request.outbox; do
	info "Configuring services.CoAuthoring.token.enable.${key} -> ${ONLYOFFICE_JWT_ENABLED}"
	put_local -t bool -v "${ONLYOFFICE_JWT_ENABLED}" services.CoAuthoring.token.enable.${key}
done

for key in inbox outbox session; do
	info "Configuring services.CoAuthoring.secret.${key}.string -> ${ONLYOFFICE_JWT_SECRET}"
	put_local -t string -v "${ONLYOFFICE_JWT_SECRET}" services.CoAuthoring.secret.${key}.string
done

for key in inbox outbox; do
	info "Configuring services.CoAuthoring.token.${key}.header -> ${ONLYOFFICE_JWT_HEADER}"
	put_local -t string -v "${ONLYOFFICE_JWT_HEADER}" services.CoAuthoring.token.${key}.header
done

for key in inbox outbox; do
	info "Configuring services.CoAuthoring.token.${key}.inBody -> ${ONLYOFFICE_JWT_IN_BODY}"
	put_local -t bool -v "${ONLYOFFICE_JWT_IN_BODY}" services.CoAuthoring.token.${key}.inBody
done
