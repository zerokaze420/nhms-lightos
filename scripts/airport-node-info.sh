set -euo pipefail

ENV_FILE="${AIRPORT_NODE_ENV:-/etc/airport-node/env}"

if [ ! -r "$ENV_FILE" ]; then
  echo "Cannot read $ENV_FILE" >&2
  echo "Run airport-node-init on the VPS first, or set AIRPORT_NODE_ENV." >&2
  exit 1
fi

# shellcheck disable=SC1090
. "$ENV_FILE"

required_vars="NODE_HOST NODE_PORT NODE_UUID REALITY_PUBLIC_KEY REALITY_SHORT_ID REALITY_SERVER_NAME"
for name in $required_vars; do
  if [ -z "${!name:-}" ]; then
    echo "Missing $name in $ENV_FILE" >&2
    exit 1
  fi
done

NODE_NAME="${NODE_NAME:-airport-node}"
REALITY_FINGERPRINT="${REALITY_FINGERPRINT:-chrome}"
VLESS_FLOW="${VLESS_FLOW:-xtls-rprx-vision}"

url="vless://${NODE_UUID}@${NODE_HOST}:${NODE_PORT}?encryption=none&flow=${VLESS_FLOW}&security=reality&sni=${REALITY_SERVER_NAME}&fp=${REALITY_FINGERPRINT}&pbk=${REALITY_PUBLIC_KEY}&sid=${REALITY_SHORT_ID}&type=tcp#${NODE_NAME}"

cat <<EOF
Node: ${NODE_NAME}
Host: ${NODE_HOST}
Port: ${NODE_PORT}
Protocol: VLESS Reality over TCP

URL:
${url}

QR:
EOF

qrencode -t ANSIUTF8 "$url"
