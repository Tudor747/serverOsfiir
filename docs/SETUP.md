# Set up the Debian server

Run these commands in **Bash on a fresh Debian 13 server**. This Windows project
contains the setup files; it has not changed your real server.

You need a server administrator account with sudo, a recovery console, a public
IP reachable on TCP 443, and a domain you control. On a campus network, ask its
administrator for the routing/firewall rule. DNS alone cannot expose a private IP.

## 1. Copy the project and install packages

Keep this project in a GitHub repository. If this folder is not yet a repository,
create an empty one on GitHub, then run these commands on your laptop:

```sh
git init -b main
git add .
git diff --cached --stat
git commit -m "Add Debian server setup"
git remote add origin https://github.com/YOUR-OWNER/YOUR-REPO.git
git push -u origin main
```

Check staged files before committing. The local archive and secrets are ignored.
For an existing repository, use its existing Git workflow.

From the Debian console, for a public repository:

```sh
sudo apt update
sudo apt install git
sudo git clone https://github.com/YOUR-OWNER/YOUR-REPO.git /opt/dorm-server
cd /opt/dorm-server
less scripts/install-debian.sh
sudo bash scripts/install-debian.sh
sudo apt upgrade
sudo timedatectl set-timezone Europe/Bucharest
timedatectl status
```

For a private repository, use a read-only deploy key or transfer the files over
an existing private connection. Do not put tokens in clone URLs.

The installer adds Docker Engine/Compose, Tailscale, OpenSSH, UFW, Certbot and
security-update tooling. It downloads Node.js 24 as a Docker image and checks
its version. Nginx will run inside Docker.

It uses the official [Docker Debian repository](https://docs.docker.com/engine/install/debian/)
and [Tailscale Debian repository](https://pkgs.tailscale.com/stable/#debian-trixie).
It does not change your SSH authentication or firewall rules.

If time synchronization is absent, enable your installed time service. For a
fresh server without one:

```sh
sudo apt install systemd-timesyncd
sudo timedatectl set-ntp true
```

## 2. Verify private SSH before closing public access

On Debian:

```sh
sudo tailscale up
tailscale ip -4
```

Follow the login URL. Install Tailscale on your laptop and join the same tailnet.
Protect administrator accounts with MFA.

Restrict access in the Tailscale admin console to your administrators and this
server's TCP 22. Example for a new dedicated tailnet; replace the email and
assign the server the tag shown:

```json
{
  "groups": {"group:admins": ["admin@example.com"]},
  "tagOwners": {"tag:dorm-server": ["group:admins"]},
  "grants": [
    {"src": ["group:admins"], "dst": ["tag:dorm-server"], "ip": ["tcp:22"]}
  ]
}
```

Remove any default allow-everything rule. On an existing university tailnet,
have its administrator incorporate this restriction into the existing policy.
This uses ordinary SSH over a private network.

Install your laptop's SSH public key for your server account. In a second
laptop terminal, verify key-based login using the actual private address:

```sh
ssh youradmin@100.x.y.z
```

Set these lines in `/etc/ssh/sshd_config.d/10-server.conf`:

```text
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
```

Validate, reload, and check the effective settings:

```sh
sudo sshd -t
sudo systemctl reload ssh
sudo sshd -T
```

Verify another new login. Keep the recovery console and your current session
open. Tailscale can relay traffic over outbound connections without a public
SSH or VPN port. [Tailscale firewall documentation](https://tailscale.com/docs/reference/faq/firewall-ports)

## 3. Allow only public TCP 443

At your provider firewall or campus router, allow inbound TCP 443 and deny
other unsolicited TCP/UDP traffic on **IPv4 and IPv6**. Keep replies to outbound
connections and essential ICMP/ICMPv6 working. Remove temporary public SSH access
only after the private connection works.

On the fresh host:

```sh
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow in on tailscale0 to any port 22 proto tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status verbose
```

Review any old broad rules. Enable IPv6 filtering in `/etc/default/ufw` when
the host has IPv6. Test private SSH again.

The upstream firewall enforces the one-port rule: Docker-published ports can
bypass UFW, and Tailscale manages some rules itself. Compose publishes only 443.
[Docker firewall explanation](https://docs.docker.com/engine/network/packet-filtering-firewalls/)

Outbound DNS, updates, time synchronization and private networking still work.
Port 80 is closed, so share full HTTPS links; HTTP will not redirect.

## 4. Configure your DNS names

At Cloudflare DNS, create an A record pointing your hostname to the server's
public IPv4. Use **DNS only**, with the proxy disabled. Optionally create a
second name pointing to the same IP. Both use the same Nginx and port 443.
There is no DNS server to install or port 53 to open.

Do not publish AAAA records until IPv6 HTTPS and firewall behavior are tested.
An absent AAAA record does not protect a public IPv6 address.

```sh
cd /opt/dorm-server
sudo cp .env.example .env
sudo chmod 600 .env
sudo nano .env
```

Fill in:

```dotenv
SERVER_DOMAIN=server.your-domain.com
SECOND_DOMAIN=second.your-domain.com
LE_EMAIL=you@your-domain.com
```

Leave `SECOND_DOMAIN=` empty for one name.

## 5. Get HTTPS using DNS validation

Create a Cloudflare API token with `Zone:DNS:Edit` restricted to the DNS zone
containing your hostnames. [Certbot Cloudflare instructions](https://certbot-dns-cloudflare.readthedocs.io/en/stable/)

```sh
sudo install -d -m 700 secrets
sudo install -m 600 /dev/null secrets/cloudflare.ini
sudo nano secrets/cloudflare.ini
```

Put this line in the file:

```ini
dns_cloudflare_api_token = YOUR-RESTRICTED-TOKEN
```

Issue the certificate and test renewal:

```sh
sudo bash scripts/tls.sh issue
sudo bash scripts/tls.sh test
```

Certificates go in `state/letsencrypt/live/server/`. Keep that directory and
credentials out of Git. Another DNS provider requires changing the Certbot
plugin and credential arguments in `scripts/tls.sh`.
[DNS validation works without port 80](https://letsencrypt.org/docs/challenge-types/)

## 6. Start Nginx and enable automation

```sh
sudo bash scripts/start.sh
sudo bash scripts/check.sh
sudo bash scripts/install-timers.sh
sudo systemctl list-timers 'dorm-*'
sudo dpkg-reconfigure -plow unattended-upgrades
sudo systemctl status apt-daily-upgrade.timer
```

Select automatic security updates. Schedule any required reboot yourself.
Container images are updated separately.

Open `https://YOUR-SERVER-DOMAIN/`: it returns `Server is ready.`.
The `/healthz` endpoint returns `ok`. Renewal is checked twice daily and
server health every five minutes.

From an outside network, verify HTTPS for each name. Scan only your own IP:

```sh
nmap -Pn -p 22,80,443,3000,5432 YOUR-PUBLIC-IP
```

Only 443 should be open. A full TCP scan and firewall review give broader
coverage. Test IPv6 too when assigned. Reboot once during setup and check that
private SSH, Nginx and the timers come back.

See [OPERATIONS.md](OPERATIONS.md) for working on the server.
