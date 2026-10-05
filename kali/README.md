# Test the server inside a Kali VM

This folder is a separate local version of the server foundation. It starts
**one Nginx container**, with HTTPS and a server-ready response. It needs no
public domain, Cloudflare account or Tailscale connection.

## Start

Copy this `kali` folder into the VM, preferably into your home directory rather
than a shared Windows folder. Open a terminal **inside Kali** and run:

```bash
cd ~/kali
sudo bash install.sh
sudo bash start.sh
```

Replace `~/kali` with the actual folder location. If you copied the entire
project, enter its `kali` subfolder. Do not run the Debian installer for this test.

The first command installs the required packages and enables Docker. The second
creates a local certificate, checks the Nginx configuration, starts Nginx, and
checks HTTPS. Internet access is needed for package and image downloads.

In the **Kali browser**, visit:

```text
https://localhost
```

Expect a browser warning because the certificate is self-signed. For this local
test, use the browser's option to accept the certificate for this site. Do not
disable certificate checks globally. The response should be:

```text
Kali test server is ready.
```

The command-line check trusts only the generated certificate:

```bash
sudo bash check.sh
```

Expected output includes `ok` and `Local HTTPS check passed.`

## What changes in the VM

- Installs Docker/Compose from Kali packages when they are needed, plus curl,
  OpenSSL, Python and CA certificates.
- Enables the Docker service, including at boot.
- Downloads a Node.js 24 image and prints its version; no Node service remains running.
- Starts Nginx on **127.0.0.1:443 inside the VM**. It restarts with Docker until
  you stop/remove it using the command below.
- Stores the local certificate and private key in `state/tls/`, excluded from Git.

There are no app or database services. The scripts do not configure SSH,
Tailscale, UFW, public DNS, host security updates or scheduled certificate renewal.
The Debian production files are independent of this folder.

The installer reuses a working Docker/Compose installation. If Docker CE is
already installed without Compose, it stops and asks you to complete that
installation instead of replacing it with Kali's Docker packages.

Package references: [Kali's Docker instructions](https://www.kali.org/docs/containers/installing-docker-on-kali/)
and [Kali's Compose v2 package](https://pkg.kali.org/news/683210/docker-compose-2403-2-imported-into-kali-rolling/).

## Normal commands

Run from this folder:

```bash
sudo docker compose ps
sudo docker compose logs --tail=50 nginx
sudo docker stats --no-stream
sudo bash check.sh
sudo bash stop.sh
```

`stop.sh` removes only this test stack's container and network. Docker and the
downloaded images remain installed; the certificate is kept for the next start.
Run `sudo bash start.sh` to start again.

Edit `nginx/default.conf` to experiment with Nginx. Run `start.sh` again to
validate and apply your changes. It briefly restarts the container.

## If port 443 is already in use

Create a local settings file:

```bash
cp .env.example .env
nano .env
```

Set `HTTPS_PORT=8443`, then rerun `sudo bash start.sh` and open
`https://localhost:8443` **inside Kali**. Only the selected port is published.

## VM access and limitations

- A normal Kali VM with internet access is sufficient; this server test does not
  need nested virtualization. Docker uses the VM's Linux kernel.
- The listener is bound to the VM's loopback address. Opening `localhost` in your
  Windows browser reaches Windows, not Kali. Use the browser inside Kali for
  these instructions; no VM/router port forwarding is required.
- Nginx has a 128 MB memory ceiling and a 0.5 CPU limit. These limits apply to the
  container, not the entire Kali desktop.
- The local certificate lasts 365 days and browsers do not trust it by default.
  To replace it, run `sudo bash make-cert.sh --renew`, then `sudo bash start.sh`.
- This checks Docker, Nginx and local HTTPS. It does not test public DNS, the
  production firewall, private administration or Let's Encrypt renewal.

The included GitHub workflow checks this folder's Nginx/HTTPS configuration on
a Linux runner. Actual Kali package installation must be exercised in your VM.
