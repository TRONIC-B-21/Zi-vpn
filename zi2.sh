#!/bin/bash
# Zivpn UDP Module installer - ARM
# Creator: SAUNDERS | Modified by TRONIC-B-21

set -euo pipefail

echo "⏫ Updating system and installing required packages..."
sudo apt-get update -y >/dev/null
sudo apt-get install -y openssl ufw wget curl >/dev/null

echo "⏹️  Stopping existing service..."
systemctl stop udp-zivpn.service 2>/dev/null || true

echo "📥 Downloading binaries..."
wget https://github.com/TRONIC-B-21/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm64 -O /usr/local/bin/udp-zivpn >/dev/null 2>&1 &
mkdir -p /etc/udp-zivpn
wget https://raw.githubusercontent.com/TRONIC-B-21/udp-zivpn/main/config.json -O /etc/udp-zivpn/config.json >/dev/null 2>&1 &
wait
chmod +x /usr/local/bin/udp-zivpn

echo "🔐 Generating certificate..."
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
  -subj "/C=US/ST=California/L=Los Angeles/O=ZIVPN/OU=Network/CN=udp-zivpn" \
  -keyout "/etc/udp-zivpn/udp-zivpn.key" -out "/etc/udp-zivpn/udp-zivpn.crt"

echo "🔧 Optimizing kernel buffers..."
sysctl -w net.core.rmem_max=16777216 net.core.wmem_max=16777216 >/dev/null

echo "⚙️  Creating systemd service..."
cat <<EOF > /etc/systemd/system/udp-zivpn.service
[Unit]
Description=ZIVPN VPN Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/zivpn
ExecStart=/usr/local/bin/udp-zivpn server -c /etc/udp-zivpn/config.json
Restart=always
RestartSec=3
Environment=ZIVPN_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

echo "🔑 Setting ZIVPN passwords..."
read -p "Enter passwords (comma-separated), or press Enter for default [zi]: " input_config
if [ -n "$input_config" ]; then
    IFS=',' read -r -a config <<< "$input_config"
    if [ ${#config[@]} -eq 1 ]; then config+=(${config[0]}); fi
else
    config=("zi")
fi
new_config_str="\"config\": [$(printf "\"%s\"," "${config[@]}" | sed 's/,$//')]"
sed -i -E "s/\"config\": ?\[[[:space:]]*\"zi\"[[:space:]]*\]/${new_config_str}/g" /etc/udp-zivpn/config.json

echo "🚀 Enabling and starting service..."
systemctl enable udp-zivpn.service
systemctl start udp-zivpn.service

echo "🌐 Setting up firewall rules..."
iface=$(ip -4 route ls|grep default|grep -Po '(?<=dev )(\S+)'|head -1)
iptables -t nat -A PREROUTING -i $iface -p udp --dport 6000:19999 -j DNAT --to-destination :5667
ufw allow 6000:19999/udp >/dev/null
ufw allow 5667/udp >/dev/null

rm zi2.* 2>/dev/null || true

sleep 1
if systemctl is-active --quiet udp-zivpn.service; then
  echo -e "\n✅ ZIVPN Installed and Running"
else
  echo -e "\n❌ ZIVPN failed to start. Check logs using: journalctl -u udp-zivpn.service"
fi
