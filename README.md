# Airport Node Helper

这个仓库提供一组 Nix app，用来把普通 Linux VPS 配置成一个
`sing-box` VLESS Reality 节点。VPS 不需要是 NixOS。

生成出来的密钥和节点信息会保存在 VPS 的 `/etc/airport-node/env`，不会写进
git。

## 可用命令

- `airport-node-init`：生成密钥，写入 sing-box 配置，安装 systemd 服务，启动
  节点和订阅服务，并输出订阅地址、节点 URL 和订阅二维码。
- `airport-node-info`：读取 `/etc/airport-node/env`，重新输出订阅地址、节点 URL
  和订阅二维码。

## VPS 使用方式

下面的命令在 VPS 上执行，不要在本机执行。把 `node.example.com` 换成 VPS 的
域名或公网 IP。

### 方式一：直接从 GitHub 运行

```bash
sudo -i
nix profile install github:zerokaze420/nhms-lightos#airport-node-runtime
NODE_HOST=node.example.com nix run github:zerokaze420/nhms-lightos#airport-node-init
```

之后如果只是想重新输出订阅地址和二维码：

```bash
sudo AIRPORT_NODE_ENV=/etc/airport-node/env nix run github:zerokaze420/nhms-lightos#airport-node-info
```

### 方式二：clone 到本地后运行

```bash
sudo -i
git clone https://github.com/zerokaze420/nhms-lightos.git
cd nhms-lightos
nix profile install .#airport-node-runtime
NODE_HOST=node.example.com nix run .#airport-node-init
```

之后如果只是想重新输出订阅地址和二维码：

```bash
sudo AIRPORT_NODE_ENV=/etc/airport-node/env nix run .#airport-node-info
```

## 配置项

`airport-node-init` 支持通过环境变量配置：

- `NODE_HOST`：必填，客户端连接用的域名或公网 IP。
- `NODE_PORT`：监听端口，默认 `443`。
- `NODE_NAME`：连接 URL 里的显示名称，默认 `airport-node`。
- `SUBSCRIPTION_PORT`：订阅服务监听端口，默认 `80`，订阅地址默认使用
  `http://NODE_HOST/SUBSCRIPTION_PATH`，不额外显示端口。
- `SUBSCRIPTION_PATH`：订阅路径，默认 `airport-node.txt`。
- `REALITY_SERVER_NAME`：Reality 握手目标，默认 `www.microsoft.com`。
- `REALITY_FINGERPRINT`：客户端指纹，默认 `chrome`。
- `VLESS_FLOW`：默认 `xtls-rprx-vision`。
- `AIRPORT_NODE_ENV`：环境文件路径，默认 `/etc/airport-node/env`。
- `AIRPORT_NODE_CONFIG`：sing-box 配置路径，默认
  `/etc/airport-node/server.json`。
- `AIRPORT_NODE_SERVICE`：systemd unit 路径，默认
  `/etc/systemd/system/airport-node.service`。

示例：

```bash
NODE_HOST=node.example.com \
NODE_PORT=443 \
NODE_NAME=my-vps \
REALITY_SERVER_NAME=www.microsoft.com \
nix run .#airport-node-init
```

## 防火墙

需要在 VPS 厂商控制台和系统防火墙里放行对应 TCP 端口。例如 UFW：

```bash
ufw allow 443/tcp
ufw allow 80/tcp
```

## 注意事项

生成的 systemd unit 会指向执行 `airport-node-init` 时能找到的 `sing-box` 二进制
路径。建议先把 `airport-node-runtime` 安装到 root profile，这样路径在后续 shell
会话里更稳定。
