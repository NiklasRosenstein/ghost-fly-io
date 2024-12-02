FROM alpine AS fetcher
RUN apk add wget tar
RUN arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/ > /tmp/arch

FROM fetcher AS litestream
RUN arch=$(cat /tmp/arch) &&\
    wget https://github.com/benbjohnson/litestream/releases/download/v0.3.13/litestream-v0.3.13-linux-${arch}.tar.gz && \
    tar -xf litestream-v0.3.13-linux-${arch}.tar.gz

FROM fetcher AS geesefs
RUN arch=$(cat /tmp/arch) &&\
    wget https://github.com/yandex-cloud/geesefs/releases/download/v0.41.3/geesefs-linux-${arch} -O geesefs && \
    chmod +x geesefs

FROM ghost:5.96.1-alpine
RUN apk add age fuse jq rsync
COPY --from=litestream /litestream /usr/bin/litestream
COPY --from=ghcr.io/niklasrosenstein/headscale-fly-io:0.4.2-headscale-0.23.0 /etc/headscale/litestream-entrypoint.sh /
COPY --from=minio/mc:RELEASE.2024-10-02T08-27-28Z /usr/bin/mc /usr/bin/mc
COPY --from=geesefs /geesefs /usr/bin/geesefs
COPY entrypoint.sh /

# NOTE: GeeseFS needs to be run and consumed as root (at least on Fly.io) :shrug: Using the --uid option has even root
#       get permission errors.

ENTRYPOINT [ "/bin/sh", "/entrypoint.sh" ]