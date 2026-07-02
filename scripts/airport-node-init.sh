set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "airport-node-init must run as root on the VPS." >&2
  exit 1
fi

ENV_FILE="${AIRPORT_NODE_ENV:-/etc/airport-node/env}"
CONFIG_FILE="${AIRPORT_NODE_CONFIG:-/etc/airport-node/server.json}"
SERVICE_FILE="${AIRPORT_NODE_SERVICE:-/etc/systemd/system/airport-node.service}"
SUBSCRIPTION_DIR="${AIRPORT_NODE_SUBSCRIPTION_DIR:-/var/lib/airport-node/subscription}"
SUBSCRIPTION_SERVICE_FILE="${AIRPORT_NODE_SUBSCRIPTION_SERVICE:-/etc/systemd/system/airport-node-subscription.service}"

INPUT_NODE_HOST_SET="${NODE_HOST+x}"
INPUT_NODE_PORT_SET="${NODE_PORT+x}"
INPUT_NODE_NAME_SET="${NODE_NAME+x}"
INPUT_SUBSCRIPTION_HOST_SET="${SUBSCRIPTION_HOST+x}"
INPUT_SUBSCRIPTION_SCHEME_SET="${SUBSCRIPTION_SCHEME+x}"
INPUT_SUBSCRIPTION_PORT_SET="${SUBSCRIPTION_PORT+x}"
INPUT_SUBSCRIPTION_PATH_SET="${SUBSCRIPTION_PATH+x}"
INPUT_REALITY_SERVER_NAME_SET="${REALITY_SERVER_NAME+x}"
INPUT_REALITY_FINGERPRINT_SET="${REALITY_FINGERPRINT+x}"
INPUT_VLESS_FLOW_SET="${VLESS_FLOW+x}"
INPUT_NODE_HOST="${NODE_HOST:-}"
INPUT_NODE_PORT="${NODE_PORT:-}"
INPUT_NODE_NAME="${NODE_NAME:-}"
INPUT_SUBSCRIPTION_HOST="${SUBSCRIPTION_HOST:-}"
INPUT_SUBSCRIPTION_SCHEME="${SUBSCRIPTION_SCHEME:-}"
INPUT_SUBSCRIPTION_PORT="${SUBSCRIPTION_PORT:-}"
INPUT_SUBSCRIPTION_PATH="${SUBSCRIPTION_PATH:-}"
INPUT_REALITY_SERVER_NAME="${REALITY_SERVER_NAME:-}"
INPUT_REALITY_FINGERPRINT="${REALITY_FINGERPRINT:-}"
INPUT_VLESS_FLOW="${VLESS_FLOW:-}"

NODE_HOST="${NODE_HOST:-}"
NODE_PORT="${NODE_PORT:-443}"
NODE_NAME="${NODE_NAME:-airport-node}"
SUBSCRIPTION_HOST="${SUBSCRIPTION_HOST:-}"
SUBSCRIPTION_SCHEME="${SUBSCRIPTION_SCHEME:-https}"
SUBSCRIPTION_PORT="${SUBSCRIPTION_PORT:-80}"
SUBSCRIPTION_PATH="${SUBSCRIPTION_PATH:-airport-node}"
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

if [ -n "$INPUT_NODE_HOST_SET" ]; then NODE_HOST="$INPUT_NODE_HOST"; fi
if [ -n "$INPUT_NODE_PORT_SET" ]; then NODE_PORT="$INPUT_NODE_PORT"; fi
if [ -n "$INPUT_NODE_NAME_SET" ]; then NODE_NAME="$INPUT_NODE_NAME"; fi
if [ -n "$INPUT_SUBSCRIPTION_HOST_SET" ]; then SUBSCRIPTION_HOST="$INPUT_SUBSCRIPTION_HOST"; fi
if [ -n "$INPUT_SUBSCRIPTION_SCHEME_SET" ]; then SUBSCRIPTION_SCHEME="$INPUT_SUBSCRIPTION_SCHEME"; fi
if [ -n "$INPUT_SUBSCRIPTION_PORT_SET" ]; then SUBSCRIPTION_PORT="$INPUT_SUBSCRIPTION_PORT"; fi
if [ -n "$INPUT_SUBSCRIPTION_PATH_SET" ]; then SUBSCRIPTION_PATH="$INPUT_SUBSCRIPTION_PATH"; fi
if [ -n "$INPUT_REALITY_SERVER_NAME_SET" ]; then REALITY_SERVER_NAME="$INPUT_REALITY_SERVER_NAME"; fi
if [ -n "$INPUT_REALITY_FINGERPRINT_SET" ]; then REALITY_FINGERPRINT="$INPUT_REALITY_FINGERPRINT"; fi
if [ -n "$INPUT_VLESS_FLOW_SET" ]; then VLESS_FLOW="$INPUT_VLESS_FLOW"; fi

if [ -z "$INPUT_SUBSCRIPTION_PATH_SET" ] && [ "$SUBSCRIPTION_PATH" = "airport-node.txt" ]; then
  SUBSCRIPTION_PATH="airport-node"
fi

SUBSCRIPTION_HOST="${SUBSCRIPTION_HOST:-sub.${NODE_HOST}}"
SUBSCRIPTION_QR_PATH="${SUBSCRIPTION_PATH}.png"
SUBSCRIPTION_BASE64_PATH="${SUBSCRIPTION_PATH}.b64"
SUBSCRIPTION_CLASH_PATH="${SUBSCRIPTION_PATH}.clash.yaml"
SUBSCRIPTION_MIHOMO_PATH="${SUBSCRIPTION_PATH}.mihomo.yaml"
SUBSCRIPTION_SING_BOX_PATH="${SUBSCRIPTION_PATH}.sing-box.json"
SUBSCRIPTION_INDEX_PATH="${SUBSCRIPTION_PATH}.index.txt"
SUBSCRIPTION_BASE64_QR_PATH="${SUBSCRIPTION_BASE64_PATH}.png"
SUBSCRIPTION_CLASH_QR_PATH="${SUBSCRIPTION_CLASH_PATH}.png"
SUBSCRIPTION_MIHOMO_QR_PATH="${SUBSCRIPTION_MIHOMO_PATH}.png"
SUBSCRIPTION_SING_BOX_QR_PATH="${SUBSCRIPTION_SING_BOX_PATH}.png"
SUBSCRIPTION_INDEX_QR_PATH="${SUBSCRIPTION_INDEX_PATH}.png"

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
SUBSCRIPTION_HOST=${SUBSCRIPTION_HOST}
SUBSCRIPTION_SCHEME=${SUBSCRIPTION_SCHEME}
SUBSCRIPTION_PORT=${SUBSCRIPTION_PORT}
SUBSCRIPTION_PATH=${SUBSCRIPTION_PATH}
SUBSCRIPTION_QR_PATH=${SUBSCRIPTION_QR_PATH}
SUBSCRIPTION_BASE64_PATH=${SUBSCRIPTION_BASE64_PATH}
SUBSCRIPTION_CLASH_PATH=${SUBSCRIPTION_CLASH_PATH}
SUBSCRIPTION_MIHOMO_PATH=${SUBSCRIPTION_MIHOMO_PATH}
SUBSCRIPTION_SING_BOX_PATH=${SUBSCRIPTION_SING_BOX_PATH}
SUBSCRIPTION_INDEX_PATH=${SUBSCRIPTION_INDEX_PATH}
SUBSCRIPTION_BASE64_QR_PATH=${SUBSCRIPTION_BASE64_QR_PATH}
SUBSCRIPTION_CLASH_QR_PATH=${SUBSCRIPTION_CLASH_QR_PATH}
SUBSCRIPTION_MIHOMO_QR_PATH=${SUBSCRIPTION_MIHOMO_QR_PATH}
SUBSCRIPTION_SING_BOX_QR_PATH=${SUBSCRIPTION_SING_BOX_QR_PATH}
SUBSCRIPTION_INDEX_QR_PATH=${SUBSCRIPTION_INDEX_QR_PATH}
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

install -d -m 0755 "$SUBSCRIPTION_DIR"
printf '%s\n' "$url" > "${SUBSCRIPTION_DIR}/${SUBSCRIPTION_PATH}"
chmod 0644 "${SUBSCRIPTION_DIR}/${SUBSCRIPTION_PATH}"
printf '%s\n' "$url" | base64 -w 0 > "${SUBSCRIPTION_DIR}/${SUBSCRIPTION_BASE64_PATH}"
printf '\n' >> "${SUBSCRIPTION_DIR}/${SUBSCRIPTION_BASE64_PATH}"
chmod 0644 "${SUBSCRIPTION_DIR}/${SUBSCRIPTION_BASE64_PATH}"

yaml_node_name="$(jq -Rn --arg value "$NODE_NAME" '$value')"
cat > "${SUBSCRIPTION_DIR}/${SUBSCRIPTION_CLASH_PATH}" <<EOF
proxies:
  - name: ${yaml_node_name}
    type: vless
    server: ${NODE_HOST}
    port: ${NODE_PORT}
    uuid: ${NODE_UUID}
    network: tcp
    tls: true
    udp: true
    flow: ${VLESS_FLOW}
    servername: ${REALITY_SERVER_NAME}
    client-fingerprint: ${REALITY_FINGERPRINT}
    reality-opts:
      public-key: ${REALITY_PUBLIC_KEY}
      short-id: ${REALITY_SHORT_ID}

proxy-groups:
  - name: Proxy
    type: select
    proxies:
      - ${yaml_node_name}

rules:
  - MATCH,Proxy
EOF
chmod 0644 "${SUBSCRIPTION_DIR}/${SUBSCRIPTION_CLASH_PATH}"
cp "${SUBSCRIPTION_DIR}/${SUBSCRIPTION_CLASH_PATH}" "${SUBSCRIPTION_DIR}/${SUBSCRIPTION_MIHOMO_PATH}"
chmod 0644 "${SUBSCRIPTION_DIR}/${SUBSCRIPTION_MIHOMO_PATH}"

jq -n \
  --arg tag "$NODE_NAME" \
  --arg server "$NODE_HOST" \
  --arg server_port "$NODE_PORT" \
  --arg uuid "$NODE_UUID" \
  --arg flow "$VLESS_FLOW" \
  --arg server_name "$REALITY_SERVER_NAME" \
  --arg fingerprint "$REALITY_FINGERPRINT" \
  --arg public_key "$REALITY_PUBLIC_KEY" \
  --arg short_id "$REALITY_SHORT_ID" \
  '{
    outbounds: [
      {
        type: "vless",
        tag: $tag,
        server: $server,
        server_port: ($server_port | tonumber),
        uuid: $uuid,
        flow: $flow,
        network: "tcp",
        tls: {
          enabled: true,
          server_name: $server_name,
          utls: {
            enabled: true,
            fingerprint: $fingerprint
          },
          reality: {
            enabled: true,
            public_key: $public_key,
            short_id: $short_id
          }
        }
      }
    ]
  }' > "${SUBSCRIPTION_DIR}/${SUBSCRIPTION_SING_BOX_PATH}"
chmod 0644 "${SUBSCRIPTION_DIR}/${SUBSCRIPTION_SING_BOX_PATH}"

cat > "${SUBSCRIPTION_DIR}/${SUBSCRIPTION_INDEX_PATH}" <<EOF
Raw VLESS:
${subscription_url}

Base64:
${subscription_base64_url}
${subscription_base64_qr_url}

Clash:
${subscription_clash_url}
${subscription_clash_qr_url}

Mihomo:
${subscription_mihomo_url}
${subscription_mihomo_qr_url}

sing-box outbound:
${subscription_sing_box_url}
${subscription_sing_box_qr_url}

Index:
${subscription_index_url}
${subscription_index_qr_url}

QR:
${subscription_qr_url}
EOF
chmod 0644 "${SUBSCRIPTION_DIR}/${SUBSCRIPTION_INDEX_PATH}"

qrencode -o "${SUBSCRIPTION_DIR}/${SUBSCRIPTION_QR_PATH}" "$subscription_url"
qrencode -o "${SUBSCRIPTION_DIR}/${SUBSCRIPTION_BASE64_QR_PATH}" "$subscription_base64_url"
qrencode -o "${SUBSCRIPTION_DIR}/${SUBSCRIPTION_CLASH_QR_PATH}" "$subscription_clash_url"
qrencode -o "${SUBSCRIPTION_DIR}/${SUBSCRIPTION_MIHOMO_QR_PATH}" "$subscription_mihomo_url"
qrencode -o "${SUBSCRIPTION_DIR}/${SUBSCRIPTION_SING_BOX_QR_PATH}" "$subscription_sing_box_url"
qrencode -o "${SUBSCRIPTION_DIR}/${SUBSCRIPTION_INDEX_QR_PATH}" "$subscription_index_url"
chmod 0644 "${SUBSCRIPTION_DIR}/${SUBSCRIPTION_QR_PATH}"
chmod 0644 "${SUBSCRIPTION_DIR}/${SUBSCRIPTION_BASE64_QR_PATH}"
chmod 0644 "${SUBSCRIPTION_DIR}/${SUBSCRIPTION_CLASH_QR_PATH}"
chmod 0644 "${SUBSCRIPTION_DIR}/${SUBSCRIPTION_MIHOMO_QR_PATH}"
chmod 0644 "${SUBSCRIPTION_DIR}/${SUBSCRIPTION_SING_BOX_QR_PATH}"
chmod 0644 "${SUBSCRIPTION_DIR}/${SUBSCRIPTION_INDEX_QR_PATH}"

BUSYBOX_BIN="$(command -v busybox)"
cat > "$SUBSCRIPTION_SERVICE_FILE" <<EOF
[Unit]
Description=Airport node subscription service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=${SUBSCRIPTION_DIR}
ExecStart=${BUSYBOX_BIN} httpd -f -p ${SUBSCRIPTION_PORT} -h ${SUBSCRIPTION_DIR}
Restart=on-failure
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now airport-node-subscription.service

echo "airport-node service installed and started."
echo
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

EOF

print_terminal_qr() {
  label="$1"
  value="$2"

  echo
  echo "${label}:"
  qrencode -t ANSIUTF8 "$value"
}

print_terminal_qr "Subscription QR" "$subscription_url"
print_terminal_qr "Base64 QR" "$subscription_base64_url"
print_terminal_qr "Clash QR" "$subscription_clash_url"
print_terminal_qr "Mihomo QR" "$subscription_mihomo_url"
print_terminal_qr "sing-box QR" "$subscription_sing_box_url"
print_terminal_qr "Index QR" "$subscription_index_url"
