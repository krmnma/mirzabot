#!/usr/bin/env bash
set -euo pipefail

export PORT="${PORT:-80}"
sed -i "s/Listen 80/Listen ${PORT}/" /etc/apache2/ports.conf
sed -i "s/<VirtualHost \*:80>/<VirtualHost *:${PORT}>/" /etc/apache2/sites-available/000-default.conf

if [[ "${MIRZABOT_INIT_DB:-true}" == "true" ]]; then
  echo "Waiting for database connection..."
  for i in {1..30}; do
    if MIRZABOT_DB_PROBE=1 php -r 'require "/var/www/html/config.php";' >/dev/null 2>&1; then
      break
    fi
    if [[ "$i" == "30" ]]; then
      echo "Database is not reachable after 30 attempts" >&2
      php -r 'require "/var/www/html/config.php";'
    fi
    sleep 2
  done
  echo "Initializing/updating Mirza database tables..."
  php /var/www/html/table.php
fi

if [[ "${TELEGRAM_SET_WEBHOOK:-false}" == "true" ]]; then
  if [[ -z "${API_KEY:-${BOT_TOKEN:-}}" ]]; then
    echo "TELEGRAM_SET_WEBHOOK=true but API_KEY/BOT_TOKEN is not set" >&2
    exit 1
  fi
  DOMAIN="${DOMAIN_HOSTS:-${DOMAIN_NAME:-${RAILWAY_PUBLIC_DOMAIN:-}}}"
  if [[ -z "$DOMAIN" ]]; then
    echo "TELEGRAM_SET_WEBHOOK=true but DOMAIN_HOSTS/DOMAIN_NAME/RAILWAY_PUBLIC_DOMAIN is not set" >&2
    exit 1
  fi
  TOKEN="${API_KEY:-${BOT_TOKEN:-}}"
  curl -fsS -F "url=https://${DOMAIN}/index.php" "https://api.telegram.org/bot${TOKEN}/setWebhook" >/dev/null
fi

exec "$@"
