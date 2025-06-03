#!/bin/bash
# 🚀 ZIVPN UDP Module Installer – AMD64 (Optimized for 1 GB RAM VPS)
# Author: TRONIC-B-21

set -e
clear
echo -e "\e[92m🚀 Installing ZIVPN for AMD64 – Ultimate Performance Mode\e[0m"

# 1. Update & upgrade
apt-get update -y && apt-get upgrade -y

# 2. Stop any existing service
systemctl stop udp-zivpn.service 2>/dev/null || true

# 3. Download and install the AMD64 binary
wget -q --show-progress \
  https://github.com/TRONIC-B-21/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64 \
  -O /usr/local/bin/udp-zivpn
chmod +x /usr/local/bin/udp-zivpn

# 4. Create config directory and fetch default config
mkdir -p /etc/udp-zivpn
wget -q \
  https://raw.githubusercontent.com/TRONIC-B-21/udp-zivpn/main/config.json \
  -O /etc/udp-zivpn/config.json

# 5. Generate 2048‑bit SSL certificates (faster on small VPS)
echo "🔐 Generating SSL certificates..."
openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
  -subj "/C=US/ST=CA/L=LA/O=ZIVPN/OU=CORE/CN=udp-zivpn" \
  -keyout /etc/udp-zivpn/udp-zivpn.key \
  -out    /etc/udp-zivpn/udp-zivpn.crt

# 6. Kernel optimizations for UDP
echo "⚙️ Applying kernel tweaks..."
sysctl -w net.core.rmem_max=33554432
sysctl -w net.core.wmem_max=33554432

# 7. Create systemd service
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

# 8. Prompt for password(s)
read -p "🔐 Enter UDP passwords (comma-separated, default 'zi'): " input_config
if [ -n "$input_config" ]; then
  IFS=',' read -ra config <<< "$input_config"
else
  config=("zi")
fi

new_config_str="\"config\": [$(printf "\"%s\"," "${config[@]}" | sed 's/,$//')]"
sed -i -E "s/\"config\": ?\[[^]]*\]/${new_config_str}/" /etc/udp-zivpn/config.json

# 9. Enable & start the service
systemctl daemon-reexec
systemctl enable udp-zivpn
systemctl restart udp-zivpn

# 10. Firewall & port forwarding
iface=$(ip -4 route ls | grep default | awk '{print $5}' | head -n1)
iptables -t nat -A PREROUTING -i "$iface" -p udp --dport 6000:19999 -j DNAT --to-destination :5667
ufw allow 6000:19999/udp
ufw allow 5667/udp

# 11. Cleanup
rm -f zi.sh 2>/dev/null || true

clear
echo -e "\e[92m✅ ZIVPN AMD64 installed and running at full performance!\e[0m"
