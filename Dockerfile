# THIS DOCKERFILE IS STILL WORK-IN-PROGRESS

# Added validator to try and resolve build context
FROM alpine as validator
# Argument for the platform on which the Docker image will be built and run
ARG TARGETPLATFORM
ARG TAILSCALE_VERSION=latest
ARG UPTIME_KUMA_VERSION=latest

# Validate the target platform and convert user-specified platform to a standard format
# Exit if the platform is not detected or unsupported
RUN SUPPORTED_ARCHITECTURES='AMD64, ARM64, ARM(v7)' \
    && SUPPORTED_MESSAGE="This Dockerfile supports ${SUPPORTED_ARCHITECTURES} architectures that Uptime Kuma supports. Please specify one of the supported architectures in your build command with --platform=" \
    && if [ -z "${TARGETPLATFORM}" ]; then echo "Target platform could not be detected. ${SUPPORTED_MESSAGE} AMD64, ARM64, or ARM." ; exit 1 ; fi \
    && TARGETPLATFORM=$(echo ${TARGETPLATFORM} | tr '[:upper:]' '[:lower:]' | tr -d '()') \
    && case ${TARGETPLATFORM} in \
      'amd64') export TARGETPLATFORM='linux/amd64' ;; \
      'arm64') export TARGETPLATFORM='linux/arm64' ;; \
      'arm'|'armv7'|'arm7') export TARGETPLATFORM='linux/arm/v7' ;; \
      *) echo "You specified an unsupported platform: ${TARGETPLATFORM}. ${SUPPORTED_MESSAGE}" ; exit 1 ;; \
    esac

# The first stage of multi-stage build
# Using Alpine Linux image
FROM --platform=${TARGETPLATFORM} alpine:latest as tailscale
WORKDIR /app
#  Download and Install the latest Tailscale package for the target platform
RUN set -e \
    && apk add --no-cache curl tar jq \
    && curl -LO "https://pkgs.tailscale.com/stable/latest_${TARGETPLATFORM#*/}.tgz" \
    && tar xzf "latest_${TARGETPLATFORM#*/}.tgz" --strip-components=1 \
    && rm "latest_${TARGETPLATFORM#*/}.tgz" \
    && ls /app

# The second stage of multi-stage build
# Using Uptime Kuma image
FROM --platform=${TARGETPLATFORM} louislam/uptime-kuma:latest
# Install necessary packages and clean up
RUN apt-get update && apt-get install -y ca-certificates iptables \
    && rm -rf /var/lib/apt/lists/*

# Copy Tailscale files from the first stage to the container
COPY --from=tailscale /app/tailscaled /app/tailscaled
COPY --from=tailscale /app/tailscale /app/tailscale
# Create necessary directories for Tailscale
RUN mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/tailscale

# Set environment variable for Tailscale hostname
ENV TS_HOSTNAME=TailscaleUptimeKuma

# Expose necessary port for the application
EXPOSE 3001
# Define volume for persistent data
VOLUME ["/app/data"]
# Define health check for the application
HEALTHCHECK --interval=60s --timeout=30s --start-period=180s --retries=5 CMD curl --fail http://localhost:3001/healthcheck || exit 1
# Define the entrypoint script and got rid of start.sh
ENTRYPOINT ["/usr/bin/dumb-init", "--", "/app/extra/entrypoint.sh", "/app/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &", "/app/tailscale up --authkey=$TS_AUTHKEY --accept-routes --hostname=$TS_HOSTNAME", "node server/server.js"]