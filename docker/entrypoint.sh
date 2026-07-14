#!/usr/bin/env bash
set -euo pipefail

export PORT="${PORT:-80}"
sed -i "s/Listen 80/Listen ${PORT}/" /etc/apache2/ports.conf
sed -i "s/<VirtualHost \*:80>/<VirtualHost *:${PORT}>/" /etc/apache2/sites-available/000-default.conf

normalize_webhook_domain() {
  local domain="$1"
  domain="${domain#http://}"
  domain="${domain#https://}"
  domain="${domain%%/*}"

  # Telegram webhooks only accept ports 443, 80, 88, or 8443. Railway public
  # domains are exposed on HTTPS/443, so a value copied with :8080 must be
  # converted back to the public hostname before calling setWebhook.
  if [[ "$domain" =~ ^([^:]+):([0-9]+)$ ]]; then
    local host="${BASH_REMATCH[1]}"
    local port="${BASH_REMATCH[2]}"
    case "$port" in
      443) domain="$host" ;;
      80|88|8443) domain="${host}:${port}" ;;
      *)
        echo "Ignoring unsupported webhook port :${port}; using ${host}." >&2
        domain="$host"
        ;;
    esac
  fi

  printf '%s' "$domain"
}

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
  DOMAIN="$(normalize_webhook_domain "$DOMAIN")"
  TOKEN="${API_KEY:-${BOT_TOKEN:-}}"
  WEBHOOK_URL="https://${DOMAIN}/index.php"
  echo "Registering Telegram webhook: ${WEBHOOK_URL}"
  response_file="$(mktemp)"
  http_code="$(curl -sS -o "$response_file" -w '%{http_code}' -F "url=${WEBHOOK_URL}" "https://api.telegram.org/bot${TOKEN}/setWebhook" || true)"
  if [[ "$http_code" != "200" ]]; then
    echo "Telegram webhook registration failed with HTTP ${http_code}; continuing container startup." >&2
    cat "$response_file" >&2 || true
    echo >&2
  fi
  rm -f "$response_file"
fi

exec "$@"
