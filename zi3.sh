#!/bin/bash
# 🚀 ZIVPN UDP MODULE INSTALLER – ARM FLAME EDITION
# ⚒️ Created by Zahid Islam | 🔥 Modified and Supercharged by TRONIC-B-21

clear
echo -e "\n🚀 INITIATING ZIVPN ARM MODULE DEPLOYMENT..."

echo -e "📦 Updating packages at lightning pace..."
sudo apt-get update -y &> /dev/null && sudo apt-get upgrade -y &> /dev/null

echo -e "🛑 Stopping any old ZIVPN process..."
systemctl stop udp-zivpn.service &> /dev/null

echo -e "⬇️ Fetching latest ARM build from the ZIVPN source core..."
wget -q https://github.com/TRONIC-B-21/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm -O /usr/local/bin/udp-zivpn
chmod +x /usr/local/bin/udp-zivpn

echo -e "📂 Setting up config directory..."
mkdir -p /etc/udp-zivpn
wget -q https://raw.githubusercontent.com/TRONIC-B-21/udp-zivpn/main/config.json -O /etc/udp-zivpn/config.json

echo -e "🔐 Generating ultra-secure certs..."
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
-subj "/C=UG/ST=ZIVPN/L=Kampala/O=HyrexNet/CN=udp-zivpn" \
-keyout "/etc/udp-zivpn/udp-zivpn.key" -out "/etc/udp-zivpn/udp-zivpn.crt"

echo -e "🧠 Turbocharging system UDP buffers..."
sysctl -w net.core.rmem_max=16777216 &> /dev/null
sysctl -w net.core.wmem_max=16777216 &> /dev/null

echo -e "🛠️ Deploying systemd service configuration..."
cat <<EOF > /etc/systemd/system/udp-zivpn.service
[Unit]
Description=ZIVPN ARM Hyper UDP Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/udp-zivpn
ExecStart=/usr/local/bin/udp-zivpn server -c /etc/udp-zivpn/config.json
Restart=always
RestartSec=2
Environment=ZIVPN_LOG_LEVEL=warp
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

echo -e "\n🔑 Enter UDP Access Passwords (Default = 'zi')"
read -p "💬 Passwords (comma-separated): " input_config
if [ -n "$input_config" ]; then
    IFS=',' read -r -a config <<< "$input_config"
    [ ${#config[@]} -eq 1 ] && config+=("${config[0]}")
else
    config=("zi")
fi

new_config_str="\"config\": [$(printf "\"%s\"," "${config[@]}" | sed 's/,$//')]"
sed -i -E "s/\"config\": ?\[[[:space:]]*\"zi\"[[:space:]]*\]/${new_config_str}/g" /etc/udp-zivpn/config.json

echo -e "🔁 Enabling & launching service..."
systemctl daemon-reexec
systemctl enable udp-zivpn.service
systemctl start udp-zivpn.service

echo -e "🌍 Opening UDP portals through firewall & NAT..."
iface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
iptables -t nat -A PREROUTING -i "$iface" -p udp --dport 6000:19999 -j DNAT --to-destination :5667
ufw allow 6000:19999/udp
ufw allow 5667/udp

rm -f zi3.* &> /dev/null
echo -e "\n✅ ZIVPN (ARM) INSTALLATION COMPLETE — YOU’RE TUNNELING IN BEAST MODE 💪🌪️"
