#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOMAIN="${DOMAIN:-api.baseball-live.kro.kr}"
BACKEND_URL="${BACKEND_URL:-http://127.0.0.1:17361}"
CERT_NAME="${CERT_NAME:-api.baseball-live.kro.kr}"
CONFIG_NAME="${CONFIG_NAME:-baseball-live-kr-api}"
CONFIG_SOURCE="${ROOT_DIR}/ops/nginx/baseball-live-kr-api.conf"
AVAILABLE_PATH="/etc/nginx/sites-available/${CONFIG_NAME}.conf"
ENABLED_PATH="/etc/nginx/sites-enabled/${CONFIG_NAME}.conf"
CERT_DIR="/etc/letsencrypt/live/${CERT_NAME}"

if ! command -v nginx >/dev/null 2>&1; then
  echo "nginx is not installed. Install it first, then rerun this script." >&2
  exit 1
fi

if ! curl -fsS --max-time 2 "${BACKEND_URL}/v1/health" >/dev/null; then
  echo "backend health check failed: ${BACKEND_URL}/v1/health" >&2
  exit 1
fi

if [[ ! -f "${CERT_DIR}/fullchain.pem" || ! -f "${CERT_DIR}/privkey.pem" ]]; then
  echo "TLS certificate not found: ${CERT_DIR}" >&2
  echo "Create it first, for example: sudo certbot certonly --nginx -d ${DOMAIN}" >&2
  exit 1
fi

tmp_config="$(mktemp)"
sed \
  -e "s/server_name api\\.baseball-live\\.kro\\.kr;/server_name ${DOMAIN};/" \
  -e "s#/etc/letsencrypt/live/api\\.baseball-live\\.kro\\.kr/#/etc/letsencrypt/live/${CERT_NAME}/#" \
  -e "s#proxy_pass http://127\\.0\\.0\\.1:17361;#proxy_pass ${BACKEND_URL};#" \
  "${CONFIG_SOURCE}" > "${tmp_config}"

sudo install -m 0644 "${tmp_config}" "${AVAILABLE_PATH}"
rm -f "${tmp_config}"

sudo ln -sfn "${AVAILABLE_PATH}" "${ENABLED_PATH}"
sudo nginx -t
sudo systemctl reload nginx

curl -fsS --max-time 5 "https://${DOMAIN}/v1/health"
echo
echo "nginx proxy installed: https://${DOMAIN} -> ${BACKEND_URL}"
