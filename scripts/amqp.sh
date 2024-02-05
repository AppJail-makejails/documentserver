#!/bin/sh

set -e

. /scripts/lib.subr

ONLYOFFICE_AMQP_TYPE="${ONLYOFFICE_AMQP_TYPE:-rabbitmq}"

case "${ONLYOFFICE_AMQP_TYPE}" in
	rabbitmq) ;;
	activemq) ;;
	*) err "Unknown queue type."; exit 1 ;;
esac

if [ -z "${ONLYOFFICE_AMQP_PROTO}" ]; then
	case "${ONLYOFFICE_AMQP_TYPE}" in
		rabbitmq) ONLYOFFICE_AMQP_PROTO="amqp" ;;
	esac
fi

ONLYOFFICE_AMQP_HOST="${ONLYOFFICE_AMQP_HOST:-onlyoffice-amqp}"
ONLYOFFICE_AMQP_PORT="${ONLYOFFICE_AMQP_PORT:-5672}"
ONLYOFFICE_AMQP_USER="${ONLYOFFICE_AMQP_USER:-onlyoffice}"
ONLYOFFICE_AMQP_PASS="${ONLYOFFICE_AMQP_PASS:-onlyoffice}"

info "Configuring queue.type -> ${ONLYOFFICE_AMQP_TYPE}"
put_local -t string -v "${ONLYOFFICE_AMQP_TYPE}" queue.type

if [ "${ONLYOFFICE_AMQP_TYPE}" = "rabbitmq" ]; then
	ONLYOFFICE_AMQP_URI="${ONLYOFFICE_AMQP_PROTO}://${ONLYOFFICE_AMQP_USER}:${ONLYOFFICE_AMQP_PASS}@${ONLYOFFICE_AMQP_HOST}:${ONLYOFFICE_AMQP_PORT}"

	info "Configuring rabbitmq.url -> ${ONLYOFFICE_AMQP_URI}"
	put_local -t string -v "${ONLYOFFICE_AMQP_URI}" rabbitmq.url
elif [ "${ONLYOFFICE_AMQP_TYPE}" = "activemq" ]; then
	info "Configuring activemq.connectOptions.host -> ${ONLYOFFICE_AMQP_HOST}"
	put_local -t string -v "${ONLYOFFICE_AMQP_HOST}" activemq.connectOptions.host

	info "Configuring  activemq.connectOptions.port -> ${ONLYOFFICE_AMQP_PORT}"
	put_local -t int -v "${ONLYOFFICE_AMQP_PORT}" activemq.connectOptions.port

	info "Configuring activemq.connectOptions.username -> ${ONLYOFFICE_AMQP_USER}"
	put_local -t string -v "${ONLYOFFICE_AMQP_USER}" activemq.connectOptions.username

	info "Configuring activemq.connectOptions.password -> ${ONLYOFFICE_AMQP_PASS}"
	put_local -t string -v "${ONLYOFFICE_AMQP_PASS}" activemq.connectOptions.password

	case "${ONLYOFFICE_AMQP_PROTO}" in
		amqp+ssl|amqps)
			info "Configuring activemq.connectOptions.transport -> tls"
			put_local -t string -v "tls" activemq.connectOptions.transport
			;;
	esac
fi
