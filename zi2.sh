#!/bin/bash
# ZIVPN UDP Installer - ARM64 Edition
# Maintainer: TRONIC-B-21 (https://github.com/TRONIC-B-21)

echo -e "\e[1;34m[*] Updating server packages...\e[0m"
apt-get update && apt-get upgrade -y

echo -e "\e[1;34m[*] Stopping any existing ZIVPN service...\e[0m"
systemctl stop zivpn.service 2>/dev/null

echo -e "\e[1;34m[*] Downloading ZIVPN binary for ARM64...\e[0m"
wget https://github.com/TRONIC-B-21/zivpn/releases/latest/download/udp-zivpn-linux-arm64 -O /usr/local/bin/zivpn
chmod +x /usr/local/bin/zivpn

echo -e "\e[1;34m[*] Preparing config directory...\e[0m"
mkdir -p /etc/zivpn
wget https://raw.githubusercontent.com/TRONIC-B-21/zivpn/main/config.json -O /etc/zivpn/config.json

echo -e "\e[1;34m[*] Generating TLS certificate...\e[0m"
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
  -subj "/C=US/ST=California/L=Los Angeles/O=ZIVPN/CN=zivpn" \
  -keyout "/etc/zivpn/zivpn.key" -out "/etc/zivpn/zivpn.crt"

echo -e "\e[1;34m[*] Tuning system buffers for UDP performance...\e[0m"
sysctl -w net.core.rmem_max=16777216
sysctl -w net.core.wmem_max=16777216

echo -e "\e[1;34m[*] Creating systemd service...\e[0m"
cat <<EOF > /etc/systemd/system/zivpn.service
[Unit]
Description=ZIVPN UDP Server (ARM64)
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/zivpn server -c /etc/zivpn/config.json
WorkingDirectory=/etc/zivpn
Restart=always
RestartSec=3
User=root
Environment=ZIVPN_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

echo -e "\e[1;34m[*] Enter ZIVPN UDP passwords:\e[0m"
read -p "Enter passwords separated by commas (default: zi): " input_config

if [[ -z "$input_config" ]]; then
  input_config="zi"
fi

IFS=',' read -ra config <<< "$input_config"
passwords_json=$(printf "\"%s\"," "${config[@]}" | sed 's/,$//')
sed -i -E "s/\"config\": ?\[[^]]*\]/\"config\": [${passwords_json}]/" /etc/zivpn/config.json

echo -e "\e[1;34m[*] Enabling and starting ZIVPN service...\e[0m"
systemctl daemon-reload
systemctl enable zivpn
systemctl start zivpn

echo -e "\e[1;34m[*] Configuring firewall and UDP port forwarding...\e[0m"
IFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
iptables -t nat -A PREROUTING -i $IFACE -p udp --dport 6000:19999 -j DNAT --to-destination :5667
ufw allow 6000:19999/udp
ufw allow 5667/udp

rm -f zi2.sh 2>/dev/null

echo -e "\e[1;32m[✓] ZIVPN UDP (ARM64) successfully installed and running!\e[0m"
