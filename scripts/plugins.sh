#!/bin/sh

set -e

. /scripts/lib.subr

if [ "${ONLYOFFICE_PLUGINS_ENABLED:-0}" != "0" ]; then
	IFS=\;

	for plugin in ${ONLYOFFICE_PLUGINS:-highlightcode;macros;mendeley;ocr;photoeditor;speech;thesaurus;translator;youtube;zotero}; do
		info "Installing plugin '${plugin}'"

		documentserver-pluginsmanager.sh --install="${plugin}"
	done

	unset IFS
fi
