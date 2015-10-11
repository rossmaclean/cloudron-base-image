#!/bin/bash

set -eu

# change data ownership
[[ -d "/app/data" ]] && chown -R ${CLOUDRON_UID} /app/data

# http://veithen.github.io/2014/11/16/sigterm-propagation.html
exec sudo -u "${CLOUDRON_UID}" -E "$@"

