# Added validator stage to resolve correct build context
FROM alpine as validator
# Define target platform on versions of Tailscale and Uptime Kuma
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

# Define a Tailscale stage to fetch the latest Tailscale package for the target platform
FROM --platform=${TARGETPLATFORM} tailscale/tailscale:stable as tailscale

# The second stage of multi-stage build
# Define the main build stage Using Uptime Kuma image
FROM --platform=${TARGETPLATFORM} louislam/uptime-kuma:latest
# Install necessary packages and clean up
RUN apt-get update && apt-get install -y ca-certificates iptables \
    && rm -rf /var/lib/apt/lists/*

# Copy Tailscale bins from the Tailscale stage into the container
COPY --from=tailscale /usr/local/bin/tailscaled /usr/local/bin/tailscaled
COPY --from=tailscale /usr/local/bin/tailscale /usr/local/bin/tailscale
# Create necessary directories for Tailscale
RUN mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/tailscale

# Set environment variable for Tailscale hostname
ENV TS_HOSTNAME=TailscaleUptimeKuma

# Expose necessary port for the application
EXPOSE 3001

# Define volume for persistent data
VOLUME ["/app/data"]

# Define health check commands for Uptime Kuma
HEALTHCHECK --interval=60s --timeout=30s --start-period=180s --retries=5 CMD curl --fail http://localhost:3001/healthcheck || exit 1

# Define entrypoint to dumb-init and got rid of start.sh
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Define container startup command 
CMD ["/bin/sh", "-c", "/usr/local/bin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock & /usr/local/bin/tailscale up --authkey=$TS_AUTHKEY --accept-routes --hostname=$TS_HOSTNAME & node server/server.js"]