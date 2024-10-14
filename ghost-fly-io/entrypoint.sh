#!/bin/sh

info() {
  >&2 echo "[$0 |  INFO]:" "$@"
}

info_run() {
  info "$@"
  "$@"
}

mount_s3() {
  if [ "${GEESEFS_ENABLED:-true}" = "true" ]; then
    info "setting up S3 mountpoint"
    GEESEFS_MEMORY_LIMIT=${GEESEFS_MEMORY_LIMIT:-64}
    info_run sudo -E geesefs --memory-limit "$GEESEFS_MEMORY_LIMIT" --endpoint "$AWS_ENDPOINT_URL_S3" "$BUCKET_NAME:data/" /var/lib/ghost/content
  fi
}

main() {
  mount_s3
  export NODE_ENV=development # To be able to use SQlite
  export LITESTREAM_DATABASE_PATH="/db.sqlite"
  export database__connection__filename="$LITESTREAM_DATABASE_PATH"
  export BUCKET_PATH="ghost.db"
  info_run exec /usr/local/bin/docker-entrypoint.sh node current/index.js
}

main "$@"