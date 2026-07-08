#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-$HOME/.config/baseball-live-kr/backend-release.env}"

if [[ -f "${CONFIG_FILE}" ]]; then
  set -a
  source "${CONFIG_FILE}"
  set +a
fi

GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
GITHUB_API_VERSION="${GITHUB_API_VERSION:-2026-03-10}"
RELEASE_ASSET_NAME="${RELEASE_ASSET_NAME:-baseball-live-kr-backend-server.tar.gz}"
INSTALL_ROOT="${INSTALL_ROOT:-$HOME/baseball-live-kr-backend}"
SERVICE_NAME="${SERVICE_NAME:-baseball-live-kr-backend}"
PORT="${PORT:-17361}"
HEALTH_URL="${HEALTH_URL:-http://127.0.0.1:${PORT}/v1/health}"

if [[ -z "${GITHUB_REPOSITORY}" ]]; then
  echo "GITHUB_REPOSITORY is required in ${CONFIG_FILE}." >&2
  exit 1
fi

for command_name in curl jq tar npm node systemctl; do
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "${command_name} is required on the remote backend server." >&2
    exit 1
  fi
done

github_json_curl_args=(
  -fsSL
  -H "Accept: application/vnd.github+json"
  -H "X-GitHub-Api-Version: ${GITHUB_API_VERSION}"
)
github_asset_curl_args=(
  -fsSL
  -H "Accept: application/octet-stream"
  -H "X-GitHub-Api-Version: ${GITHUB_API_VERSION}"
)

if [[ -n "${GITHUB_TOKEN}" ]]; then
  github_json_curl_args+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
  github_asset_curl_args+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

release_api_url="https://api.github.com/repos/${GITHUB_REPOSITORY}/releases/latest"
release_json="$(curl "${github_json_curl_args[@]}" "${release_api_url}")"
tag_name="$(jq -r '.tag_name // empty' <<<"${release_json}")"
asset_api_url="$(jq -r --arg name "${RELEASE_ASSET_NAME}" '.assets[]? | select(.name == $name) | .url' <<<"${release_json}" | head -n 1)"

if [[ -z "${tag_name}" ]]; then
  echo "Latest GitHub release did not include tag_name." >&2
  exit 1
fi

if [[ -z "${asset_api_url}" ]]; then
  echo "Release ${tag_name} does not include ${RELEASE_ASSET_NAME}." >&2
  exit 1
fi

current_tag_file="${INSTALL_ROOT}/.release-tag"
current_dir="${INSTALL_ROOT}/current"

if [[ -d "${current_dir}" && -f "${current_tag_file}" && "$(cat "${current_tag_file}")" == "${tag_name}" ]]; then
  echo "Backend release ${tag_name} is already deployed."
  exit 0
fi

safe_tag_name="${tag_name//\//_}"
releases_dir="${INSTALL_ROOT}/releases"
release_dir="${releases_dir}/${safe_tag_name}"
release_tmp="${release_dir}.tmp"
download_dir="$(mktemp -d)"
download_path="${download_dir}/${RELEASE_ASSET_NAME}"

cleanup() {
  rm -rf "${download_dir}" "${release_tmp}"
}
trap cleanup EXIT

mkdir -p "${releases_dir}"

curl "${github_asset_curl_args[@]}" \
  -o "${download_path}" \
  "${asset_api_url}"

rm -rf "${release_tmp}"
mkdir -p "${release_tmp}"
tar -xzf "${download_path}" -C "${release_tmp}"

cd "${release_tmp}"
npm ci --omit=dev
chmod +x run-backend.command

rm -rf "${release_dir}"
mv "${release_tmp}" "${release_dir}"
ln -sfn "${release_dir}" "${current_dir}"

systemctl --user daemon-reload
systemctl --user restart "${SERVICE_NAME}.service"

for _ in {1..30}; do
  if curl -fsS --max-time 2 "${HEALTH_URL}" >/dev/null; then
    printf '%s\n' "${tag_name}" > "${current_tag_file}"
    echo "Deployed backend release ${tag_name}."
    exit 0
  fi
  sleep 1
done

systemctl --user status "${SERVICE_NAME}.service" --no-pager || true
journalctl --user -u "${SERVICE_NAME}.service" -n 120 --no-pager || true
exit 1
