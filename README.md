# Debian server foundation

A simple server setup for **Debian 13, 4 CPU cores and 8 GB RAM**.

The running stack contains **Nginx only**. It listens on HTTPS port **443** and
returns a small server-ready response. The setup prepares Docker, private SSH,
certificates, security updates and health checks. Node.js is available as a
Docker image for later use.

```text
Internet -- TCP 443 --> Nginx on Debian
Administrator -- private Tailscale connection --> SSH
DNS provider -- DNS records --> server public IP
```

Start with **[the setup guide](docs/SETUP.md)**. Then use
**[the operations guide](docs/OPERATIONS.md)** for updates and daily commands.

For a local trial inside a Kali VM, use **[the separate Kali guide](kali/README.md)**.
That folder uses a self-signed certificate and needs no public DNS or DNS token.

| File | Purpose |
| --- | --- |
| `scripts/install-debian.sh` | Install server packages on fresh Debian 13 |
| `.env.example` | Your hostname, optional second hostname and certificate email |
| `compose.yaml` | One Nginx container; only port 443 published |
| `nginx/default.conf.template` | Editable HTTPS configuration |
| `scripts/tls.sh` | Issue, test and renew certificates using DNS validation |
| `scripts/start.sh` | Validate and start/recreate Nginx |
| `scripts/check.sh` | Check HTTPS, disk space and certificate expiry |
| `systemd/` | Automatic renewal and health-check timers |
| `.github/workflows/ci.yml` | Validate the server configuration on GitHub |

Cloudflare DNS and Tailscale are the concrete choices in the guide. DNS validation
lets port 80 stay closed. The provider/router firewall must allow only public
TCP 443; SSH runs over the private connection.
[DNS validation](https://letsencrypt.org/docs/challenge-types/)

There is no application, database, registry publishing or application deployment
in the active setup. The earlier example is preserved locally under
`.archive/previous-app-example/`, excluded from Git and all active configuration.

Your hardware is ample for this server foundation. Future application capacity
depends on the actual workload. Keep at least 20% of disk free, monitor memory
and CPU, and expect a single-server outage during host failure or maintenance.

These files prepare the setup; **nothing has been installed on your real Debian
machine from this Windows workspace**. You need server access, a domain and a DNS
API token to follow the guide. Local checks cover Compose and shell syntax;
Docker startup and real certificate issuance need a running Docker engine and
your actual server.
