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
SUBSCRIPTION_HOST="${SUBSCRIPTION_HOST:-sub.${NODE_HOST}}"
SUBSCRIPTION_SCHEME="${SUBSCRIPTION_SCHEME:-https}"
SUBSCRIPTION_PORT="${SUBSCRIPTION_PORT:-80}"
SUBSCRIPTION_PATH="${SUBSCRIPTION_PATH:-airport-node}"
if [ "${SUBSCRIPTION_PATH}" = "airport-node.txt" ]; then
  SUBSCRIPTION_PATH="airport-node"
fi
SUBSCRIPTION_QR_PATH="${SUBSCRIPTION_QR_PATH:-${SUBSCRIPTION_PATH}.png}"
SUBSCRIPTION_BASE64_PATH="${SUBSCRIPTION_BASE64_PATH:-${SUBSCRIPTION_PATH}.b64}"
SUBSCRIPTION_CLASH_PATH="${SUBSCRIPTION_CLASH_PATH:-${SUBSCRIPTION_PATH}.clash.yaml}"
SUBSCRIPTION_MIHOMO_PATH="${SUBSCRIPTION_MIHOMO_PATH:-${SUBSCRIPTION_PATH}.mihomo.yaml}"
SUBSCRIPTION_SING_BOX_PATH="${SUBSCRIPTION_SING_BOX_PATH:-${SUBSCRIPTION_PATH}.sing-box.json}"
SUBSCRIPTION_INDEX_PATH="${SUBSCRIPTION_INDEX_PATH:-${SUBSCRIPTION_PATH}.index.txt}"
SUBSCRIPTION_BASE64_QR_PATH="${SUBSCRIPTION_BASE64_QR_PATH:-${SUBSCRIPTION_BASE64_PATH}.png}"
SUBSCRIPTION_CLASH_QR_PATH="${SUBSCRIPTION_CLASH_QR_PATH:-${SUBSCRIPTION_CLASH_PATH}.png}"
SUBSCRIPTION_MIHOMO_QR_PATH="${SUBSCRIPTION_MIHOMO_QR_PATH:-${SUBSCRIPTION_MIHOMO_PATH}.png}"
SUBSCRIPTION_SING_BOX_QR_PATH="${SUBSCRIPTION_SING_BOX_QR_PATH:-${SUBSCRIPTION_SING_BOX_PATH}.png}"
SUBSCRIPTION_INDEX_QR_PATH="${SUBSCRIPTION_INDEX_QR_PATH:-${SUBSCRIPTION_INDEX_PATH}.png}"
REALITY_FINGERPRINT="${REALITY_FINGERPRINT:-chrome}"
VLESS_FLOW="${VLESS_FLOW:-xtls-rprx-vision}"

url="vless://${NODE_UUID}@${NODE_HOST}:${NODE_PORT}?encryption=none&flow=${VLESS_FLOW}&security=reality&sni=${REALITY_SERVER_NAME}&fp=${REALITY_FINGERPRINT}&pbk=${REALITY_PUBLIC_KEY}&sid=${REALITY_SHORT_ID}&type=tcp#${NODE_NAME}"
subscription_url="${SUBSCRIPTION_SCHEME}://${SUBSCRIPTION_HOST}/${SUBSCRIPTION_PATH}"
subscription_qr_url="${SUBSCRIPTION_SCHEME}://${SUBSCRIPTION_HOST}/${SUBSCRIPTION_QR_PATH}"
subscription_base64_url="${SUBSCRIPTION_SCHEME}://${SUBSCRIPTION_HOST}/${SUBSCRIPTION_BASE64_PATH}"
subscription_clash_url="${SUBSCRIPTION_SCHEME}://${SUBSCRIPTION_HOST}/${SUBSCRIPTION_CLASH_PATH}"
subscription_mihomo_url="${SUBSCRIPTION_SCHEME}://${SUBSCRIPTION_HOST}/${SUBSCRIPTION_MIHOMO_PATH}"
subscription_sing_box_url="${SUBSCRIPTION_SCHEME}://${SUBSCRIPTION_HOST}/${SUBSCRIPTION_SING_BOX_PATH}"
subscription_index_url="${SUBSCRIPTION_SCHEME}://${SUBSCRIPTION_HOST}/${SUBSCRIPTION_INDEX_PATH}"
subscription_base64_qr_url="${SUBSCRIPTION_SCHEME}://${SUBSCRIPTION_HOST}/${SUBSCRIPTION_BASE64_QR_PATH}"
subscription_clash_qr_url="${SUBSCRIPTION_SCHEME}://${SUBSCRIPTION_HOST}/${SUBSCRIPTION_CLASH_QR_PATH}"
subscription_mihomo_qr_url="${SUBSCRIPTION_SCHEME}://${SUBSCRIPTION_HOST}/${SUBSCRIPTION_MIHOMO_QR_PATH}"
subscription_sing_box_qr_url="${SUBSCRIPTION_SCHEME}://${SUBSCRIPTION_HOST}/${SUBSCRIPTION_SING_BOX_QR_PATH}"
subscription_index_qr_url="${SUBSCRIPTION_SCHEME}://${SUBSCRIPTION_HOST}/${SUBSCRIPTION_INDEX_QR_PATH}"

cat <<EOF
Node: ${NODE_NAME}
Host: ${NODE_HOST}
Port: ${NODE_PORT}
Protocol: VLESS Reality over TCP

Subscription:
${subscription_url}

Subscription QR URL:
${subscription_qr_url}

Base64 Subscription:
${subscription_base64_url}
Base64 QR:
${subscription_base64_qr_url}

Clash Subscription:
${subscription_clash_url}
Clash QR:
${subscription_clash_qr_url}

Mihomo Subscription:
${subscription_mihomo_url}
Mihomo QR:
${subscription_mihomo_qr_url}

sing-box outbound:
${subscription_sing_box_url}
sing-box QR:
${subscription_sing_box_qr_url}

Subscription Index:
${subscription_index_url}
Index QR:
${subscription_index_qr_url}

Node URL:
${url}

Subscription QR:
EOF

qrencode -t ANSIUTF8 "$subscription_url"
