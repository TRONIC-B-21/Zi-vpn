#!/bin/bash
# 🚀 ZIVPN + WireGuard Installer – AMD64 Optimized (1 GB VPS Edition)
# Author: TRONIC-B-21

set -e
clear
echo -e "\e[92m🚀 Installing ZIVPN + WireGuard – Ultimate Performance Mode\e[0m"

# 1) Update & upgrade
apt-get update -y && apt-get upgrade -y

# 2) Enable IP forwarding
cat <<EOF >> /etc/sysctl.conf
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
EOF
sysctl -p

# 3) Kernel tuning
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

# 4) Stop existing ZIVPN
systemctl stop udp-zivpn.service 2>/dev/null || true

# 5) Download ZIVPN AMD64
wget -q --show-progress \
  https://github.com/TRONIC-B-21/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64 \
  -O /usr/local/bin/udp-zivpn
chmod +x /usr/local/bin/udp-zivpn

# 6) Setup ZIVPN config
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

# 7) SSL for ZIVPN
openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
  -subj "/C=US/ST=CA/L=LA/O=ZIVPN/OU=CORE/CN=udp-zivpn" \
  -keyout /etc/udp-zivpn/udp-zivpn.key \
  -out    /etc/udp-zivpn/udp-zivpn.crt

# 8) Create ZIVPN systemd service
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

# 9) Configure ZIVPN passwords
read -p "🔐 Enter UDP passwords (comma-separated, default 'zi'): " input_config
if [ -n "$input_config" ]; then
  IFS=',' read -ra arr <<< "$input_config"
  new_config_str="\"config\": [$(printf '\"%s\",' "${arr[@]}" | sed 's/,\$//')]"
  sed -i -E "s/\"config\": ?\[[^]]*\]/$new_config_str/" /etc/udp-zivpn/config.json
fi

# 10) Enable and start ZIVPN
systemctl daemon-reload
systemctl enable udp-zivpn
systemctl restart udp-zivpn

# 11) NAT firewall rules
iface=$(ip -4 route show default | awk '/default/ {print $5; exit}')
iptables -t nat -C PREROUTING -i "$iface" -p udp --dport 6000:19999 -j DNAT --to-destination :5667 2>/dev/null || \
iptables -t nat -A PREROUTING -i "$iface" -p udp --dport 6000:19999 -j DNAT --to-destination :5667

# ========== WIREGUARD CONFIGURATION ==========

echo -e "\n⚙️ Installing WireGuard..."
apt-get install -y wireguard qrencode

mkdir -p /etc/wireguard
cd /etc/wireguard

# Generate private/public key pair
wg genkey | tee privatekey | wg pubkey > publickey

# Create basic wg0.conf
cat <<EOF > /etc/wireguard/wg0.conf
[Interface]
PrivateKey = $(cat privatekey)
Address = 10.66.66.1/24
ListenPort = 51820
SaveConfig = true

PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $iface -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $iface -j MASQUERADE
EOF

chmod 600 wg0.conf
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

# Show public key to user
echo -e "\n✅ WireGuard is active. Server public key:\n$(cat publickey)"
echo -e "\n➡️ Add clients manually using \e[1mwg set\e[0m or \e[1mnano /etc/wireguard/wg0.conf\e[0m."
echo -e "\n✅ ZIVPN + WireGuard successfully installed with hyped BBR and performance tweaks!\n"
