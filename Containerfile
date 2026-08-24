ARG FREEBSD_RELEASE

FROM ghcr.io/appjail-makejails/core:${FREEBSD_RELEASE}

ARG NO_PKGCLEAN
ARG PYVER

LABEL org.opencontainers.image.title="ONLYOFFICE Document Server" \
    org.opencontainers.image.description="Secure office and productivity apps" \
    org.opencontainers.image.source="https://github.com/AppJail-makejails/documentserver" \
    org.opencontainers.image.url="https://github.com/AppJail-makejails/documentserver" \
    org.opencontainers.image.vendor="DtxdF" \
    org.opencontainers.image.authors="Jesús Daniel Colmenares Oviedo <dtxdf@disroot.org>"

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

ARG COMPANY_NAME=onlyoffice
ARG PRODUCT_NAME=documentserver
ARG PRODUCT_EDITION=

RUN set -xe; \
    \
    umask 0022; \
    \
    pkg update; \
    pkg install \
        onlyoffice-documentserver \
        coreutils \
        bash \
        gawk \
        gsed \
        gnugrep \
        pwgen \
        py${PYVER}-certbot \
        FreeBSD-cron \
        logrotate \
        FreeBSD-bsdconfig \
        xxd; \
    \
    if [ -z "${NO_PKGCLEAN}" ]; then \
        pkg clean -a; \
        rm -rf /var/cache/pkg/*; \
    fi; \
    rm -rf /var/db/pkg/repos/*

RUN set -xe; \
    \
    umask 0022; \
    \
    echo -e "[include]\nfiles = /usr/local/etc/onlyoffice/documentserver/supervisor/*.conf" >> /usr/local/etc/supervisord.conf; \
    \
    cp -a /usr/local/etc/onlyoffice/documentserver/nginx/ds-ssl.conf /usr/local/etc/onlyoffice/documentserver/nginx/ds-ssl.conf.tmpl; \
    cp -a /usr/local/etc/onlyoffice/documentserver/nginx/ds.conf /usr/local/etc/onlyoffice/documentserver/nginx/ds.conf.tmpl

EXPOSE 80 443

ENV COMPANY_NAME=$COMPANY_NAME \
    PRODUCT_NAME=$PRODUCT_NAME \
    PRODUCT_EDITION=$PRODUCT_EDITION \
    DS_PLUGIN_INSTALLATION=false \
    DS_DOCKER_INSTALLATION=true

COPY patch-documentserver-update-securelink.sh.diff /usr/local/bin
COPY patch-documentserver-pluginsmanager.sh.diff /usr/local/bin
COPY patch-documentserver-flush-cache.sh.diff /usr/local/bin

RUN set -xe; \
    \
    cd /usr/local/bin; \
    \
    patch < patch-documentserver-update-securelink.sh.diff; \
    patch < patch-documentserver-pluginsmanager.sh.diff; \
    patch < patch-documentserver-flush-cache.sh.diff; \
    \
    rm -f documentserver-update-securelink.sh.orig; \
    rm -f documentserver-pluginsmanager.sh.orig; \
    rm -f documentserver-flush-cache.sh.orig; \
    \
    chmod 555 documentserver-update-securelink.sh; \
    chmod 555 documentserver-pluginsmanager.sh; \
    chmod 555 documentserver-flush-cache.sh

COPY nginx.conf /usr/local/etc/nginx/nginx.conf

COPY documentserver-letsencrypt.sh /usr/local/bin

VOLUME /var/log/onlyoffice /var/db/onlyoffice /usr/local/www/onlyoffice/Data
ENTRYPOINT ["/run-document-server.sh"]

COPY run-document-server.sh /

RUN chmod +x /run-document-server.sh
