#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SSH_TARGET="${SSH_TARGET:-}"
DOMAIN="${DOMAIN:-api.baseball-live.kro.kr}"
BACKEND_URL="${BACKEND_URL:-http://127.0.0.1:17361}"
CERT_NAME="${CERT_NAME:-api.baseball-live.kro.kr}"
CONFIG_NAME="${CONFIG_NAME:-baseball-live-kr-api}"
CONFIG_SOURCE="${ROOT_DIR}/ops/nginx/baseball-live-kr-api.conf"

if [[ -z "${SSH_TARGET}" ]]; then
  echo "SSH_TARGET is required." >&2
  exit 1
fi

tmp_config="$(mktemp)"
sed \
  -e "s/server_name api\\.baseball-live\\.kro\\.kr;/server_name ${DOMAIN};/" \
  -e "s#/etc/letsencrypt/live/api\\.baseball-live\\.kro\\.kr/#/etc/letsencrypt/live/${CERT_NAME}/#" \
  -e "s#proxy_pass http://127\\.0\\.0\\.1:17361;#proxy_pass ${BACKEND_URL};#" \
  "${CONFIG_SOURCE}" > "${tmp_config}"

remote_tmp="/tmp/${CONFIG_NAME}.conf"
scp "${tmp_config}" "${SSH_TARGET}:${remote_tmp}"
rm -f "${tmp_config}"

ssh "${SSH_TARGET}" \
  "DOMAIN='${DOMAIN}' BACKEND_URL='${BACKEND_URL}' CERT_NAME='${CERT_NAME}' CONFIG_NAME='${CONFIG_NAME}' REMOTE_CONFIG='${remote_tmp}' bash -s" <<'REMOTE'
set -euo pipefail

available_path="/etc/nginx/sites-available/${CONFIG_NAME}.conf"
enabled_path="/etc/nginx/sites-enabled/${CONFIG_NAME}.conf"
cert_dir="/etc/letsencrypt/live/${CERT_NAME}"

if ! command -v nginx >/dev/null 2>&1; then
  echo "nginx is not installed. Install it first: sudo apt-get update && sudo apt-get install -y nginx" >&2
  exit 1
fi

if ! curl -fsS --max-time 2 "${BACKEND_URL}/v1/health" >/dev/null; then
  echo "backend health check failed: ${BACKEND_URL}/v1/health" >&2
  exit 1
fi

if [[ ! -f "${cert_dir}/fullchain.pem" || ! -f "${cert_dir}/privkey.pem" ]]; then
  echo "TLS certificate not found: ${cert_dir}" >&2
  echo "Create it first: sudo certbot certonly --nginx -d ${DOMAIN}" >&2
  exit 1
fi

sudo install -m 0644 "${REMOTE_CONFIG}" "${available_path}"
rm -f "${REMOTE_CONFIG}"
sudo ln -sfn "${available_path}" "${enabled_path}"
sudo nginx -t
sudo systemctl reload nginx
curl -fsS --max-time 5 "https://${DOMAIN}/v1/health"
echo
echo "nginx proxy installed: https://${DOMAIN} -> ${BACKEND_URL}"
REMOTE
