# start.sh
#!/bin/sh

/app/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &
/app/tailscale up --authkey=$TS_AUTHKEY --accept-routes --hostname=$TS_HOSTNAME

# start uptime kuma
node server/server.js
