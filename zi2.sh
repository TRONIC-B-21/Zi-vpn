#!/bin/bash
# 🛠️ ZIVPN + WireGuard Hybrid Installer - ARM (32-bit)
# Maintainer: TRONIC-B-21

set -e
clear
echo -e "\e[96m🚀 Installing ZIVPN + WireGuard on ARM (32-bit) with Hyped BBR!\e[0m"

# 1) Update system
apt-get update && apt-get upgrade -y

# 2) Enable IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# 3) Kernel & Buffer tuning
echo "⚙️ Tuning kernel for UDP & WireGuard performance..."
sysctl -w net.core.rmem_max=2500000
sysctl -w net.core.wmem_max=2500000
sysctl -w net.ipv4.tcp_congestion_control="bbr"
sysctl -w net.core.netdev_max_backlog=25000
sysctl -w net.ipv4.udp_rmem_min=65536
sysctl -w net.ipv4.udp_wmem_min=65536

# 4) Stop existing services
systemctl stop zivpn.service 2>/dev/null || true
systemctl stop wg-quick@zivwg.service 2>/dev/null || true

# 5) Install dependencies
apt install -y wireguard-tools iptables curl wget openssl

# 6) ZIVPN binary download
echo "⬇️ Downloading ZIVPN binary..."
wget -q --show-progress \
  https://github.com/TRONIC-B-21/zivpn/releases/latest/download/udp-zivpn-linux-arm \
  -O /usr/local/bin/zivpn
chmod +x /usr/local/bin/zivpn

# 7) ZIVPN Config
mkdir -p /etc/zivpn
cat <<EOF > /etc/zivpn/config.json
{
  "listen": ":5667",
  "mtu": 1350,
  "cipher": "chacha20-poly1305",
  "handshake_timeout": 5,
  "idle_timeout": 300,
  "log_level": "warn",
  "config": ["zi"]
}
EOF

# 8) Self-signed certs
echo "🔐 Generating TLS cert for ZIVPN..."
openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
  -subj "/C=XX/ST=NA/L=Anywhere/O=ZIVPN/CN=zivpn" \
  -keyout /etc/zivpn/zivpn.key -out /etc/zivpn/zivpn.crt

# 9) Systemd: ZIVPN
cat <<EOF > /etc/systemd/system/zivpn.service
[Unit]
Description=ZIVPN UDP Server (ARM)
After=network.target

[Service]
ExecStart=/usr/local/bin/zivpn server -c /etc/zivpn/config.json
Restart=always
RestartSec=2
User=root
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

# 10) WireGuard: Setup (auto keys & local-only)
WG_DIR="/etc/wireguard"
mkdir -p \$WG_DIR
umask 077
wg genkey | tee \$WG_DIR/privatekey | wg pubkey > \$WG_DIR/publickey

PRIVATE_KEY=\$(cat \$WG_DIR/privatekey)

cat <<EOF > \$WG_DIR/zivwg.conf
[Interface]
Address = 10.7.0.1/24
ListenPort = 51820
PrivateKey = \$PRIVATE_KEY
PostUp = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

EOF

# 11) Systemd: WireGuard
systemctl enable wg-quick@zivwg
systemctl start wg-quick@zivwg

# 12) Prompt password(s)
read -p "🔐 Enter UDP passwords (comma-separated, default 'zi'): " input_config
if [[ -n "$input_config" ]]; then
  IFS=',' read -ra config <<< "$input_config"
  passwords_json=$(printf "\"%s\"," "${config[@]}" | sed 's/,$//')
  sed -i -E "s/\"config\": ?\[[^]]*\]/\"config\": [${passwords_json}]/" /etc/zivpn/config.json
fi

# 13) Start ZIVPN service
systemctl daemon-reload
systemctl enable zivpn
systemctl restart zivpn

# 14) Firewall rules
iface=$(ip -4 route show default | awk '/default/ {print $5; exit}')
iptables -t nat -A PREROUTING -i "$iface" -p udp --dport 6000:19999 -j DNAT --to-destination :5667
ufw allow 5667/udp
ufw allow 51820/udp
ufw allow 6000:19999/udp

echo -e "\n✅ \e[92mZIVPN + WireGuard (ARM) Installed & Optimized with Hyped BBR!\e[0m"
