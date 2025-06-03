#!/bin/bash
# 🚀 ZIVPN UDP Module Installer – ARM64 (Optimized for 1 GB VPS)
# Author: TRONIC-B-21

set -e
clear
echo -e "\e[96m🚀 Installing ZIVPN for ARM64 – Turbo Boost Mode\e[0m"

# 1) Update & upgrade
apt-get update -y && apt-get upgrade -y

# 2) Enable IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# 3) Kernel network tuning
echo "⚙️ Applying kernel network tuning..."
sysctl -w net.core.rmem_max=2500000
sysctl -w net.core.wmem_max=2500000
sysctl -w net.ipv4.udp_mem="65536 131072 262144"
sysctl -w net.ipv4.udp_rmem_min=65536
sysctl -w net.ipv4.udp_wmem_min=65536
sysctl -w net.ipv4.tcp_rmem="4096 87380 2500000"
sysctl -w net.ipv4.tcp_wmem="4096 65536 2500000"
sysctl -w net.core.netdev_max_backlog=50000
sysctl -w net.ipv4.tcp_congestion_control="bbr"
sysctl -w net.ipv4.tcp_fastopen=3
sysctl -w net.ipv4.tcp_max_syn_backlog=4096
sysctl -w net.ipv4.tcp_tw_reuse=1

# 4) Stop any existing ZIVPN service
systemctl stop udp-zivpn.service 2>/dev/null || true

# 5) Download and install the ARM64 binary
echo "⬇️ Downloading ZIVPN binary..."
wget -q --show-progress \
  https://github.com/TRONIC-B-21/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm64 \
  -O /usr/local/bin/udp-zivpn
chmod +x /usr/local/bin/udp-zivpn

# 6) Create config directory and basic config.json with MTU=1350, log_level=warn
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

# 7) Generate 2048‑bit SSL certificates
echo "🔐 Generating SSL certificates..."
openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
  -subj "/C=US/ST=CA/L=LA/O=ZIVPN/OU=CORE/CN=udp-zivpn" \
  -keyout /etc/udp-zivpn/udp-zivpn.key \
  -out    /etc/udp-zivpn/udp-zivpn.crt

# 8) Create systemd service
cat <<EOF > /etc/systemd/system/udp-zivpn.service
[Unit]
Description=ZIVPN UDP Server (ARM64)
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

# 9) Prompt for password(s), override config.json if provided
read -p "🔐 Enter UDP passwords (comma-separated, default 'zi'): " input_config
if [ -n "$input_config" ]; then
  IFS=',' read -ra arr <<< "$input_config"
  new_config_str="\"config\": [$(printf "\"%s\"," "${arr[@]}" | sed 's/,$//')]"
  sed -i -E "s/\"config\": ?\[[^]]*\]/$new_config_str/" /etc/udp-zivpn/config.json
fi

# 10) Enable & start the service
systemctl daemon-reload
systemctl enable udp-zivpn
systemctl restart udp-zivpn

# 11) Apply iptables NAT (no UFW)
iface=$(ip -4 route show default | awk '/default/ {print $5; exit}')
iptables -t nat -C PREROUTING -i "$iface" -p udp --dport 6000:19999 -j DNAT --to-destination :5667 2>/dev/null || \
iptables -t nat -A PREROUTING -i "$iface" -p udp --dport 6000:19999 -j DNAT --to-destination :5667

echo -e "\n✅ ZIVPN ARM64 installed and optimized for 1 GB VPS!\n"
