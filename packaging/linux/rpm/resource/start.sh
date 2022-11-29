#!/bin/bash

export NODE_ENV=production
export SERVICE_NAME="<%= service-name %>"
export SERVICE_TAGS="<%= service-tags %>"

# Uncomment to prepare node for creating stack-traces. Can be set via Consul, too.
# export STACKTRACE=true

# Restore config for Envconsul if it does not exist (any more)
if [ ! -e "/opt/seal/etc/envconsul.json" ]; then
  cp "/opt/seal/<%= name %>/envconsul.json.template" "/opt/seal/etc/envconsul.json"
  chmod 664 "/opt/seal/etc/envconsul.json"
fi

# Store log files in /var/log/seal if it exists, in /tmp otherwise
logpath="/tmp"
if [ -d "/var/log/seal" ]; then
  logpath="/var/log/seal"
fi
outFile="${logpath}/<%= name %>.log"

envconsul="/opt/seal/<%= name %>/envconsul"

# Envconsul options
opts="-config \"/opt/seal/etc/envconsul.json\""

# Get prefix options
opts="${opts} -prefix \"dc/home/env/service/any/tag/any/\""
opts="${opts} -prefix \"dc/home/env/service/${SERVICE_NAME}/tag/any/\""

OIFS=${IFS}
IFS=','
for tag in ${SERVICE_TAGS}; do
  opts="${opts} -prefix \"dc/home/env/service/any/tag/${tag}/\""
  opts="${opts} -prefix \"dc/home/env/service/${SERVICE_NAME}/tag/${tag}/\""
done
IFS=${OIFS}

# Let envconsul run the service
opts="${opts} \"/opt/seal/<%= name %>/node\""
if [ -n "${STACKTRACE}" ]; then
  opts="${opts} \"--perf-basic-prof\""
fi
opts="${opts} \"/opt/seal/<%= name %>/bin/app.js\""

eval exec "${envconsul}" ${opts} >>"${outFile}" 2>&1
