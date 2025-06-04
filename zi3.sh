#!/bin/bash
# Zivpn UDP Module installer - ARM64
# Creator: Saunders Tobin

echo -e "Updating server..."
apt-get update && apt-get upgrade -y

echo -e "Stopping existing service (if any)..."
systemctl stop udp-zivpn.service 1> /dev/null 2> /dev/null

echo -e "Downloading ZIVPN UDP binary..."
wget -q https://github.com/TRONIC-B-21/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm64 -O /usr/local/bin/udp-zivpn
chmod +x /usr/local/bin/udp-zivpn

echo -e "Creating config directory..."
mkdir -p /etc/udp-zivpn

echo -e "Downloading default config file..."
wget -q https://raw.githubusercontent.com/TRONIC-B-21/udp-zivpn/main/config.json -O /etc/udp-zivpn/config.json

echo "Generating TLS certificate and key..."
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
  -subj "/C=US/ST=California/L=Los Angeles/O=Example Corp/OU=IT Department/CN=udp-zivpn" \
  -keyout "/etc/udp-zivpn/udp-zivpn.key" -out "/etc/udp-zivpn/udp-zivpn.crt"

# Apply performance tuning
sysctl -w net.core.rmem_max=16777216 > /dev/null
sysctl -w net.core.wmem_max=16777216 > /dev/null

# Create systemd service
cat <<EOF > /etc/systemd/system/udp-zivpn.service
[Unit]
Description=ZIVPN UDP Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/udp-zivpn -c /etc/udp-zivpn/config.json
Restart=always
RestartSec=3
Environment=ZIVPN_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

echo -e "\nZIVPN UDP Passwords Setup"
read -p "Enter passwords separated by commas (or press enter for default 'zi'): " input_config

if [ -n "$input_config" ]; then
    IFS=',' read -r -a config <<< "$input_config"
else
    config=("zi")
fi

# Generate proper JSON password array
new_config_str="\"config\": [$(printf "\"%s\"," "${config[@]}" | sed 's/,$//')]"

# Replace the config line in JSON
sed -i -E "s/\"config\": ?\[[^]]*\]/${new_config_str}/g" /etc/udp-zivpn/config.json

# Enable and start the service
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable udp-zivpn.service
systemctl start udp-zivpn.service

# Setup iptables and UFW rules
iface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
iptables -t nat -A PREROUTING -i "$iface" -p udp --dport 6000:19999 -j DNAT --to-destination :5667

ufw allow 6000:19999/udp
ufw allow 5667/udp

# Cleanup
rm -f zi2.* > /dev/null 2>&1

echo -e "\n✅ ZIVPN Installed Successfully on ARM64"
