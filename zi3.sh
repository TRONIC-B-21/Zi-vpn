#!/bin/bash
# 🚀 Enhanced ZIVPN + WireGuard Installer – AMD64 (Real Data Simulation + BBR)
# Author: TRONIC-B-21

set -e
clear
echo -e "\e[92m🚀 Installing Enhanced ZIVPN for AMD64 with WireGuard + Real Data Simulation\e[0m"

# 1) Update & upgrade
apt-get update -y && apt-get upgrade -y

# 2) Enable IP forwarding & BBR
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.tcp_congestion_control=bbr
sysctl -w net.ipv4.tcp_fastopen=3

# 3) Kernel network tuning for UDP performance & buffers
echo "⚙️ Applying kernel network tuning..."
sysctl -w net.core.rmem_max=2500000
sysctl -w net.core.wmem_max=2500000
sysctl -w net.ipv4.udp_mem="65536 131072 262144"
sysctl -w net.ipv4.udp_rmem_min=65536
sysctl -w net.ipv4.udp_wmem_min=65536
sysctl -w net.ipv4.tcp_rmem="4096 87380 2500000"
sysctl -w net.ipv4.tcp_wmem="4096 65536 2500000"
sysctl -w net.core.netdev_max_backlog=50000
sysctl -w net.ipv4.tcp_max_syn_backlog=4096
sysctl -w net.ipv4.tcp_tw_reuse=1

# 4) Stop existing services
systemctl stop udp-zivpn.service 2>/dev/null || true
systemctl stop wg-quick@wg0.service 2>/dev/null || true

# 5) Download ZIVPN binary
echo "⬇️ Downloading ZIVPN binary..."
wget -q --show-progress \
  https://github.com/TRONIC-B-21/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64 \
  -O /usr/local/bin/udp-zivpn
chmod +x /usr/local/bin/udp-zivpn

# 6) Install WireGuard tools (if not present)
if ! command -v wg >/dev/null 2>&1; then
  echo "⬇️ Installing WireGuard tools..."
  apt-get install -y wireguard
fi

# 7) Prepare config directory and default config for ZIVPN
mkdir -p /etc/udp-zivpn
cat <<EOF > /etc/udp-zivpn/config.json
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

# 8) Generate ephemeral SSL certificates for ZIVPN (needed internally)
echo "🔐 Generating ephemeral SSL certificates..."
openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
  -subj "/C=US/ST=CA/L=LA/O=ZIVPN/OU=CORE/CN=udp-zivpn" \
  -keyout /etc/udp-zivpn/udp-zivpn.key \
  -out    /etc/udp-zivpn/udp-zivpn.crt

# 9) Create systemd service for ZIVPN
cat <<EOF > /etc/systemd/system/udp-zivpn.service
[Unit]
Description=ZIVPN UDP Server (AMD64)
After=network.target

[Service]
ExecStart=/usr/local/bin/udp-zivpn server -c /etc/udp-zivpn/config.json
Restart=always
RestartSec=2
User=root
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

# 10) Setup WireGuard config (no external file pulls, simple free config)
WG_CONF=/etc/wireguard/wg0.conf
mkdir -p /etc/wireguard
if [ ! -f "$WG_CONF" ]; then
  echo "🔧 Generating WireGuard config..."
  PRIVATE_KEY=$(wg genkey)
  PUBLIC_KEY=$(echo "$PRIVATE_KEY" | wg pubkey)

  cat <<WGCONF > $WG_CONF
[Interface]
Address = 10.66.66.1/24
ListenPort = 51820
PrivateKey = $PRIVATE_KEY
SaveConfig = false

# Dummy peer for testing (replace as needed)
[Peer]
PublicKey = $PUBLIC_KEY
AllowedIPs = 10.66.66.2/32
WGCONF

  chmod 600 $WG_CONF
fi

# 11) Enable IP forwarding for WireGuard (already enabled above)
# 12) Start WireGuard interface
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

# 13) Prompt for UDP passwords (ZIVPN)
read -p "🔐 Enter ZIVPN UDP passwords (comma-separated, default 'zi'): " input_config
if [ -n "$input_config" ]; then
  IFS=',' read -ra arr <<< "$input_config"
  new_config_str="\"config\": [$(printf "\"%s\"," "${arr[@]}" | sed 's/,$//')]"
  sed -i -E "s/\"config\": ?\[[^]]*\]/$new_config_str/" /etc/udp-zivpn/config.json
fi

# 14) Reload and start ZIVPN service
systemctl daemon-reload
systemctl enable udp-zivpn
systemctl restart udp-zivpn

# 15) IPTABLES rules with obfuscation & forwarding for ZIVPN + WireGuard
iface=$(ip -4 route show default | awk '/default/ {print $5; exit}')
iptables -t nat -C PREROUTING -i "$iface" -p udp --dport 6000:19999 -j DNAT --to-destination :5667 2>/dev/null || \
iptables -t nat -A PREROUTING -i "$iface" -p udp --dport 6000:19999 -j DNAT --to-destination :5667

iptables -t nat -C POSTROUTING -o "$iface" -j MASQUERADE 2>/dev/null || \
iptables -t nat -A POSTROUTING -o "$iface" -j MASQUERADE

ufw allow 6000:19999/udp
ufw allow 5667/udp
ufw allow 51820/udp  # WireGuard

# 16) Background DNS traffic simulation (fake queries every 30s)
(
  while true; do
    dig google.com > /dev/null 2>&1
    sleep 30
  done
) &

# 17) Fake TLS handshake simulation on port 443 (using socat)
if ! pgrep -f "socat TCP-LISTEN:443" > /dev/null; then
  nohup socat TCP-LISTEN:443,fork EXEC:"echo -e 'HTTP/1.1 200 OK\r\n\r\n'" >/dev/null 2>&1 &
fi

echo -e "\n✅ Enhanced ZIVPN + WireGuard installed and running with real data simulation!\n"
echo "WireGuard interface: wg0 on port 51820"
echo "ZIVPN UDP port: 5667 (UDP ports 6000-19999 forwarded)"
