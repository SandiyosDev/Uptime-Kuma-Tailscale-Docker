# Dockerfile
FROM alpine:latest as tailscale
WORKDIR /app
RUN apk add --no-cache curl tar jq \
    && response=$(curl -s "https://api.github.com/repos/tailscale/tailscale/releases/latest") \
    && version=$(echo "$response" | jq -r '.tag_name') \
    && echo "Version: $version" \
    && wget "https://pkgs.tailscale.com/stable/tailscale_${version#v}_arm64.tgz" \
    && tar xzf "tailscale_${version#v}_arm64.tgz" --strip-components=1 \
    && rm "tailscale_${version#v}_arm64.tgz" \
    && ls /app


FROM louislam/uptime-kuma:1
RUN apt-get update && apt-get install -y ca-certificates iptables \
    && rm -rf /var/lib/apt/lists/*

COPY ./start.sh /app/start.sh
COPY --from=tailscale /app/tailscaled /app/tailscaled
COPY --from=tailscale /app/tailscale /app/tailscale
RUN mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/tailscale

ENV TS_HOSTNAME=TailscaleUptimeKuma

EXPOSE 3001
VOLUME ["/app/data"]
HEALTHCHECK --interval=60s --timeout=30s --start-period=180s --retries=5 CMD curl --fail http://localhost:3001/healthcheck || exit 1
ENTRYPOINT ["/usr/bin/dumb-init", "--", "/app/extra/entrypoint.sh"]
CMD ["/app/start.sh"]
