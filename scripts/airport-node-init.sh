set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "airport-node-init must run as root on the VPS." >&2
  exit 1
fi

ENV_FILE="${AIRPORT_NODE_ENV:-/etc/airport-node/env}"
CONFIG_FILE="${AIRPORT_NODE_CONFIG:-/etc/airport-node/server.json}"
SERVICE_FILE="${AIRPORT_NODE_SERVICE:-/etc/systemd/system/airport-node.service}"

NODE_HOST="${NODE_HOST:-}"
NODE_PORT="${NODE_PORT:-443}"
NODE_NAME="${NODE_NAME:-airport-node}"
REALITY_SERVER_NAME="${REALITY_SERVER_NAME:-www.microsoft.com}"
REALITY_FINGERPRINT="${REALITY_FINGERPRINT:-chrome}"
VLESS_FLOW="${VLESS_FLOW:-xtls-rprx-vision}"

if [ -z "$NODE_HOST" ]; then
  echo "Set NODE_HOST to the VPS domain or public IP, for example:" >&2
  echo "  NODE_HOST=node.example.com nix run .#airport-node-init" >&2
  exit 1
fi

install -d -m 0755 "$(dirname "$ENV_FILE")"

if [ -r "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  . "$ENV_FILE"
fi

NODE_UUID="${NODE_UUID:-$(sing-box generate uuid)}"
REALITY_KEYS="$(sing-box generate reality-keypair)"
REALITY_PRIVATE_KEY="${REALITY_PRIVATE_KEY:-$(printf '%s\n' "$REALITY_KEYS" | awk -F': ' '/PrivateKey/ {print $2; exit}')}"
REALITY_PUBLIC_KEY="${REALITY_PUBLIC_KEY:-$(printf '%s\n' "$REALITY_KEYS" | awk -F': ' '/PublicKey/ {print $2; exit}')}"
REALITY_SHORT_ID="${REALITY_SHORT_ID:-$(openssl rand -hex 8)}"

if [ -z "$REALITY_PRIVATE_KEY" ] || [ -z "$REALITY_PUBLIC_KEY" ]; then
  echo "Failed to generate Reality keypair with sing-box." >&2
  exit 1
fi

umask 077
cat > "$ENV_FILE" <<EOF
NODE_NAME=${NODE_NAME}
NODE_HOST=${NODE_HOST}
NODE_PORT=${NODE_PORT}
NODE_UUID=${NODE_UUID}
VLESS_FLOW=${VLESS_FLOW}
REALITY_SERVER_NAME=${REALITY_SERVER_NAME}
REALITY_FINGERPRINT=${REALITY_FINGERPRINT}
REALITY_PRIVATE_KEY=${REALITY_PRIVATE_KEY}
REALITY_PUBLIC_KEY=${REALITY_PUBLIC_KEY}
REALITY_SHORT_ID=${REALITY_SHORT_ID}
EOF

jq -n \
  --arg listen_port "$NODE_PORT" \
  --arg uuid "$NODE_UUID" \
  --arg flow "$VLESS_FLOW" \
  --arg server_name "$REALITY_SERVER_NAME" \
  --arg private_key "$REALITY_PRIVATE_KEY" \
  --arg short_id "$REALITY_SHORT_ID" \
  '{
    log: {
      level: "info",
      timestamp: true
    },
    inbounds: [
      {
        type: "vless",
        tag: "vless-reality-in",
        listen: "::",
        listen_port: ($listen_port | tonumber),
        users: [
          {
            uuid: $uuid,
            flow: $flow
          }
        ],
        tls: {
          enabled: true,
          server_name: $server_name,
          reality: {
            enabled: true,
            handshake: {
              server: $server_name,
              server_port: 443
            },
            private_key: $private_key,
            short_id: [
              $short_id
            ]
          }
        }
      }
    ],
    outbounds: [
      {
        type: "direct",
        tag: "direct"
      }
    ]
  }' > "$CONFIG_FILE"
chmod 0600 "$CONFIG_FILE"

SING_BOX_BIN="$(command -v sing-box)"
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Airport node sing-box service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=${SING_BOX_BIN} run -c ${CONFIG_FILE}
Restart=on-failure
RestartSec=3s
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now airport-node.service

echo "airport-node service installed and started."
echo
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
