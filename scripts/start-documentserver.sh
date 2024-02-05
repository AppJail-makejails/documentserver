#!/bin/sh

set -e

. /scripts/lib.subr

info "Starting supervisord ..."
service supervisord start

info "Starting nginx ..."
service nginx start
