# Ghost on Fly.io

  [1]: https://github.com/NiklasRosenstein/headscale-fly-io
  [2]: https://github.com/NiklasRosenstein/vaultwarden-fly-io
  [GeeseFS]: https://github.com/yandex-cloud/geesefs/

This repository is inspired by my other projects, [Headscale on Fly.io][1] and [Vaultwarden on Fly.io][2], although I
actually run this particular variant on Kubernetes (works just as well!). Instead of using a persistent volume, this
container mounts an S3 bucket using [GeeseFS] to store all Ghost content in S3 (not just media files as is the case
with the Ghost Amazon S3 integration).

## Configuration

### Litestream & GeeseFS

GeeseFS re-uses the same S3-related environment variables as our Litestream configuration. For the variables of that
configuration, see [litestream-entrypoint.sh](https://github.com/NiklasRosenstein/headscale-fly-io/blob/main/headscale-fly-io/litestream-entrypoint.sh).
