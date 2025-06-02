#!/bin/bash
# ZIVPN UDP Module Installer
# Maintainer: TRONIC-B-21 (https://github.com/TRONIC-B-21)

echo -e "\e[1;34m[*] Updating server packages...\e[0m"
apt-get update && apt-get upgrade -y

echo -e "\e[1;34m[*] Stopping any existing ZIVPN service...\e[0m"
systemctl stop zivpn.service 2>/dev/null

echo -e "\e[1;34m[*] Downloading latest ZIVPN binary...\e[0m"
ARCH=$(uname -m)
case $ARCH in
  x86_64) ARCH="amd64" ;;
  armv7l) ARCH="arm" ;;
  aarch64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH" && exit 1 ;;
esac

BIN_URL="https://github.com/TRONIC-B-21/zivpn/releases/latest/download/udp-zivpn-linux-${ARCH}"
wget "$BIN_URL" -O /usr/local/bin/zivpn
chmod +x /usr/local/bin/zivpn

echo -e "\e[1;34m[*] Setting up configuration directory...\e[0m"
mkdir -p /etc/zivpn
wget https://raw.githubusercontent.com/TRONIC-B-21/zivpn/main/config.json -O /etc/zivpn/config.json

echo -e "\e[1;34m[*] Generating self-signed TLS certificate...\e[0m"
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
  -subj "/C=US/ST=California/L=Los Angeles/O=ZIVPN/CN=zivpn" \
  -keyout "/etc/zivpn/zivpn.key" -out "/etc/zivpn/zivpn.crt"

echo -e "\e[1;34m[*] Optimizing system buffers for UDP...\e[0m"
sysctl -w net.core.rmem_max=16777216
sysctl -w net.core.wmem_max=16777216

echo -e "\e[1;34m[*] Creating systemd service...\e[0m"
cat <<EOF > /etc/systemd/system/zivpn.service
[Unit]
Description=ZIVPN UDP Server
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

echo -e "\e[1;34m[*] Configure passwords:\e[0m"
read -p "Enter passwords separated by commas (default: zi): " input_pass

if [[ -z "$input_pass" ]]; then
  input_pass="zi"
fi

IFS=',' read -ra pass_array <<< "$input_pass"
pass_json=$(printf "\"%s\"," "${pass_array[@]}" | sed 's/,$//')
sed -i -E "s/\"config\": ?\[[^]]*\]/\"config\": [${pass_json}]/" /etc/zivpn/config.json

echo -e "\e[1;34m[*] Enabling and starting ZIVPN service...\e[0m"
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable zivpn
systemctl start zivpn

echo -e "\e[1;34m[*] Setting up UDP port forwarding and firewall rules...\e[0m"
IFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
iptables -t nat -A PREROUTING -i $IFACE -p udp --dport 6000:19999 -j DNAT --to-destination :5667
ufw allow 6000:19999/udp
ufw allow 5667/udp

rm -f zi.sh zi2.sh 2>/dev/null

echo -e "\e[1;32m[✓] ZIVPN UDP successfully installed and running!\e[0m"
