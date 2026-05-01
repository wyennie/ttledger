# infra

Source-of-truth for the deploy host's external config. Everything here lives
on the droplet at a known path; this directory exists so a fresh server can
be rebuilt by copying these files into place.

## Contents

- `nginx/ttledger.willyennie.dev.conf` — Nginx vhost reverse-proxying
  `ttledger.willyennie.dev` to the docker-compose `web` container at
  `127.0.0.1:3001`. Includes a `/cable` block for ActionCable / Turbo Streams.

## Deploying changes

These files aren't pulled by the GitHub Actions deploy workflow (it only
restarts the app container). To apply changes to the nginx vhost:

```bash
ssh deploy@<droplet>
cd /var/www/ttledger
git pull
sudo cp infra/nginx/ttledger.willyennie.dev.conf /etc/nginx/sites-available/
sudo nginx -t && sudo systemctl reload nginx
```

Certbot may have rewritten the on-disk version in place to add SSL — diff
before overwriting if you've run certbot since the last sync.
