# Uptime Kuma with Tailscale Dockerfile (AMD64/ARM64/ARM(v7))

**Work in progress - Though the dockerfile builds and runs fine at its current state**

This Dockerfile is your ticket to building a docker image for [Uptime Kuma](https://github.com/louislam/uptime-kuma) with [Tailscale](https://tailscale.com) support; Uptime Kuma is a self-hosted monitoring tool, and Tailscale is a zero config VPN, making this combination a pretty useful one.

The Dockerfile provided always fetches the latest version of each image during the build, I'm still working on pinning a working version. (fallback for when the "latest" build fails)

## Getting Started

**1. Clone the Repository**

Grab this repository by running:

```bash
git clone https://github.com/SGprooo/Uptime-Kuma-Tailscale-Docker.git
```

**2. Build the Docker Image**

Navigate to the directory with the Dockerfile and start the build:

```bash
docker build -t uptime-kuma-tailscale-docker .
```

**3. Fire Up the Docker Container**

Launch the Docker container with this command:

```bash
docker run -d --restart=always -p 3001:3001 --device /dev/net/tun:/dev/net/tun --cap-add=NET_ADMIN -v uptime-kuma:/app/data --name uptime-kuma -e TSKEY=YOUR_TAILSACLE_API_KEY -e TS_HOSTNAME=YOUR_HOSTNAME uptime-kuma-tailscale
```
**Replace** `YOUR_TAILSACLE_API_KEY` and `YOUR_HOSTNAME` with your Tailscale API key and desired hostname respectively. The hostname defaults to `TailscaleUptimeKuma` if not specified. You can generate a API key [here](https://login.tailscale.com/admin/settings/keys).

## Docker Container Configurations

**Environment Variables**
- `TSKEY`: Your Tailscale API key.
- `TS_HOSTNAME`: The hostname for your Tailscale node. Defaults to `TailscaleUptimeKuma`.

**Volumes**
- `/app/data`: This is where Uptime Kuma stores its data.

**Exposed Ports**
- Uptime Kuma's web interface is accessible at port 3001. If you need to map this port elsewhere, use `-p 3002:3001` in your `docker run` command. (You can also access this web interface from other devices on the same Tailent)

## Credit

This Dockerfile was revised from a dockerfile in discussion under [this issue](https://github.com/louislam/uptime-kuma/issues/1981). As of the time of writing this, the build works fine with Tailscale 1.40.1 and Uptime Kuma 1.21.3. If you have any improvements, feel free to create a pull requests.

And heads up, I'm still figuring out how to integrate Tailscale ping with Uptime Kuma instead of using its default ICMP pings. I'll pull Uptime Kuma in the future.

Written with ❤️ to Tailscale
