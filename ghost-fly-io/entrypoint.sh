#!/bin/sh

set -e

#
# Utilities
#

info() {
  >&2 echo "[$0 |  INFO]:" "$@"
}

error() {
  >&2 echo "[$0 | ERROR]:" "$@"
}

info_run() {
  info "$@"
  "$@"
}

maybe_idle() {
  if [ "${ENTRYPOINT_IDLE:-false}" = "true" ]; then
    info "ENTRYPOINT_IDLE=true, entering idle state"
    sleep infinity
  fi
}

on_error() {
  [ $? -eq 0 ] && exit
  error "an unexpected error occurred."
  maybe_idle
}

trap 'on_error' EXIT

#
# Business logic
#

export LITESTREAM_DATABASE_PATH='/db.sqlite'
export BUCKET_PATH="ghost.db"
GHOST_URL="${GHOST_URL:-https://${FLY_APP_NAME}.fly.dev}"

mount_s3() {
  if [ "${GEESEFS_ENABLED:-true}" = "true" ]; then
    info "setting up S3 mountpoint"
    GEESEFS_MEMORY_LIMIT=${GEESEFS_MEMORY_LIMIT:-64}
    info_run geesefs --memory-limit "$GEESEFS_MEMORY_LIMIT" --endpoint "$AWS_ENDPOINT_URL_S3" "$BUCKET_NAME:data/" "$GHOST_INSTALL/content"
  fi
}

init_ghost_content() {
  init_file="$GHOST_INSTALL/content/.initialized"
  if [ ! -f "$init_file" ]; then
    info "initializing ghost content dir"
    rsync -rvL "$GHOST_INSTALL/content.orig/" "$GHOST_INSTALL/content/"
    touch "$init_file"
  fi
}

write_config() {
  CONFIG_FILE=config.production.json

  # See https://ghost.org/docs/config/
  cat <<EOF >$CONFIG_FILE
{
  "database": {
    "client": "sqlite3",
    "connection": {
      "filename": "$LITESTREAM_DATABASE_PATH"
    },
    "useNullAsDefault": true,
    "debug": false
  },
  "server": {
    "host": "0.0.0.0"
  },
EOF

  if [ "${GHOST_ENABLE_SMTP:-false}" = "true" ]; then
    cat <<EOF >>$CONFIG_FILE
  "mail": {
    "transport": "SMTP",
    "options": {
      "host": "${GHOST_SMTP_HOST}",
      "port": ${GHOST_SMTP_PORT:-465},
      "from": "${GHOST_SMTP_FROM}",
      "secure": true,
      "auth": {
        "user": "${GHOST_SMTP_USER}",
        "pass": "${GHOST_SMTP_PASS}"
      }
    }
  },
EOF
  fi

  cat <<EOF >>$CONFIG_FILE
  "paths": {
    "contentPath": "$GHOST_INSTALL/content/"
  },
  "url": "$GHOST_URL"
}
EOF

  # Validate the config.
  if ! jq <$CONFIG_FILE; then
    error "$CONFIG_FILE is invalid"
  fi
}

main() {
  mount_s3
  write_config
  init_ghost_content
  maybe_idle
  info_run exec /litestream-entrypoint.sh "node current/index.js"
}

main "$@"