# Working on the server

Connect privately and enter the project directory:

```sh
ssh youradmin@100.x.y.z
cd /opt/dorm-server
```

## Everyday checks

```sh
sudo docker compose ps
sudo docker compose logs --tail=50 nginx
sudo bash scripts/check.sh
sudo docker stats --no-stream
free -h
df -h
sudo systemctl list-timers 'dorm-*'
```

The check script tests local HTTPS, disk usage below 85%, and a certificate
with at least seven days left. Nginx logs rotate at 10 MB, retaining three files.

Use an external HTTPS monitor for public DNS, routing and server outages.
A local failed check does not notify anyone by itself.

For an optional heartbeat, create a five-minute check with ten minutes of grace
and an alert recipient in your monitoring service. Save its success URL in a
root-only file:

```sh
sudo install -m 600 /dev/null secrets/monitor.env
sudo nano secrets/monitor.env
```

```dotenv
HEALTHCHECK_URL=https://YOUR-MONITOR/SUCCESS-URL
```

The health service loads this URL and calls it only after successful checks.
Test that an overdue heartbeat actually notifies you.

## Change configuration

Edit files on your laptop, commit and push. GitHub Actions validates Compose
and Bash, then starts Nginx with a temporary certificate to check HTTPS. This
runs on a GitHub runner and needs no server credentials.

After CI succeeds, apply the reviewed change over private SSH:

```sh
cd /opt/dorm-server
sudo git pull --ff-only
sudo bash scripts/start.sh
```

The start script validates Nginx before recreating it. Expect a brief HTTPS
interruption. It does not change firewall rules or rerun the Debian installer.

Automation covers certificate renewal, health checks, Debian security updates
and configuration validation. Server configuration changes use the commands
above. There is no application build or deployment pipeline.

For timer edits, rerun `sudo bash scripts/install-timers.sh`. When changing
domains, update DNS and `.env`, rerun `tls.sh issue`, then restart Nginx.

## Updates

Review package updates regularly:

```sh
sudo apt update
apt list --upgradable
sudo apt upgrade
```

Schedule required reboots. Debian security updates do not refresh container
images. Before an Nginx update, record its current image digest:

```sh
sudo docker image inspect nginx:stable-alpine --format '{{index .RepoDigests 0}}'
sudo docker compose pull nginx
sudo bash scripts/start.sh
```

To select a specific version, set Compose's `image:` field to the recorded
`nginx@sha256:...` digest. Keep the previous working configuration off-server.

## Node.js for later

The installer caches `node:24-alpine` and checks its runtime. No Node process
stays running. You can verify the image with:

```sh
sudo docker run --rm --network none node:24-alpine node --version
```

When you eventually add a service, its runtime can run inside Docker and talk
to Nginx over an internal Docker network. Public access continues through 443.
You do not need a separate host Node.js installation for that arrangement.

## Recovery and limits

Keep the Git repository plus a protected off-server copy of `.env`, DNS
credentials, certificate state, SSH settings and your firewall/access policy.
The copy contains private keys and tokens: encrypt it or use protected backup
storage. Keep recovery credentials independent of the server.

Rebuilding means installing Debian, restoring reviewed configuration, restoring
private access, restoring or reissuing HTTPS, and starting Nginx. A single host
has no automatic failover.

Four cores and 8 GB RAM comfortably cover this server foundation. Nginx has a
128 MB memory ceiling and a 0.5 CPU limit, editable in Compose. Future workload
capacity must be measured when something runs on the server. Watch sustained
CPU, available memory, swapping, network latency and disk space; aim to keep
at least 20% disk free. Updates and correct configuration remain necessary
even when only HTTPS is publicly reachable.

## Earlier example files

The previous example is preserved only in the ignored local
`.archive/previous-app-example/` folder. Do not copy it to the server.

If you already installed the earlier example's timers on a real host, disable
them before using this setup:

```sh
sudo systemctl disable --now dorm-deploy.timer dorm-backup.timer
```

Wait for any running old deployment or backup service to finish. Review its
containers and volumes separately to preserve existing data. If you never
installed the earlier version, skip this step.
