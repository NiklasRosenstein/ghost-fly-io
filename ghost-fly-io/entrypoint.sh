#!/bin/sh

#
# Utilities
#

info() {
  >&2 echo "[$0 |  INFO]:" "$@"
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

mount_s3() {
  if [ "${GEESEFS_ENABLED:-true}" = "true" ]; then
    info "setting up S3 mountpoint"
    GEESEFS_MEMORY_LIMIT=${GEESEFS_MEMORY_LIMIT:-64}
    info_run sudo -E geesefs --memory-limit "$GEESEFS_MEMORY_LIMIT" --endpoint "$AWS_ENDPOINT_URL_S3" "$BUCKET_NAME:data/" /var/lib/ghost/content
  fi
}

init_ghost_content() {
  # Copied from Ghost's docker-entrypoint.sh
  info "initializing ghost content dir"
  baseDir="$GHOST_INSTALL/content.orig"
  for src in "$baseDir"/*/ "$baseDir"/themes/*; do
    src="${src%/}"
    target="$GHOST_CONTENT/${src#$baseDir/}"
    mkdir -p "$(dirname "$target")"
    if [ ! -e "$target" ]; then
      tar -cC "$(dirname "$src")" "$(basename "$src")" | tar -xC "$(dirname "$target")"
    fi
  done
}

main() {
  mount_s3
  export NODE_ENV=development # To be able to use SQlite
  export LITESTREAM_DATABASE_PATH="/db.sqlite"
  export database__connection__filename="$LITESTREAM_DATABASE_PATH"
  export BUCKET_PATH="ghost.db"
  init_ghost_content
  maybe_idle
  info_run exec litestream-entrypoint.sh "node current/index.js"
}

main "$@"