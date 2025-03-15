# Ghost on Fly.io

[1]: https://github.com/NiklasRosenstein/headscale-fly-io
[2]: https://github.com/NiklasRosenstein/vaultwarden-fly-io
[Litestream]: https://litestream.io
[GeeseFS]: https://github.com/yandex-cloud/geesefs/
[Ghost]: https://ghost.org/

This repository is inspired by my other projects, [Headscale on Fly.io][1] and [Vaultwarden on Fly.io][2]. The goal is
to create a simple deployment of the [Ghost] blogging platform that gets away without persistent storage or an external
database; just a machine and S3.

It uses an SQlite database replicated to S3 using [Litestream] and the Ghost content folder an S3 bucket mounted via
[GeeseFS].

## Installation

1. Create a Fly app with `fly app create <app>`
2. Create and attach an S3 bucket with `fly storage create -a <app> -n <app>`
3. Create encryption key for the database with `age-keygen` and `fly secrets set AGE_SECRET_KEY=...`
4. Copy and update `fly.example.toml` to `fly.toml`
5. Run `fly deploy`

## Configuration

- `GHOST_URL`: URL of the app (default: `https://${FLY_APP_NAME}.fly.dev`).
- `GHOST_ENABLE_SMTP`: When set to `true`, configure an SMTP server (does not currently support non-standard SMTP
  services like Mailgun)
  - `GHOST_SMTP_HOST`
  - `GHOST_SMTP_PORT` (defaults to 465)
  - `GHOST_SMTP_FROM`
  - `GHOST_SMTP_USER`
  - `GHOST_SMTP_PASS`

### Litestream & GeeseFS

GeeseFS re-uses the same S3-related environment variables as our Litestream configuration. For the variables of that
configuration, see
[litestream-entrypoint.sh](https://github.com/NiklasRosenstein/headscale-fly-io/blob/main/headscale-fly-io/litestream-entrypoint.sh).

### Logs

Ghost's logs can be found under `/var/lib/ghost/content/logs`.
