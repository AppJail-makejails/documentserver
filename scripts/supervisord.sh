#!/bin/sh

set -e

cat << EOF >> /usr/local/etc/supervisord.conf
[include]
files = /usr/local/etc/onlyoffice/documentserver/supervisor/*.conf
EOF
