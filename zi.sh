#!/bin/bash
# 🚀 ZIVPN HYPERBLAST INSTALLER – AMD64
# 🔥 Created by Zahid Islam | Supercharged by TRONIC-B-21

clear
echo -e "\n🔥 ZIVPN HYPERBLAST – INITIATING FULL THROTTLE INSTALL... 🛠️"

echo -e "\n⏫ Updating server at lightspeed..."
sudo apt-get update -y &> /dev/null && sudo apt-get upgrade -y &> /dev/null

echo -e "🛑 Stopping any running instance..."
systemctl stop udp-zivpn.service &> /dev/null

echo -e "⚡ Fetching ultra-fast binary for AMD64..."
wget -q https://github.com/TRONIC-B-21/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64 -O /usr/local/bin/udp-zivpn
chmod +x /usr/local/bin/udp-zivpn

echo -e "📁 Setting up environment..."
mkdir -p /etc/udp-zivpn
wget -q https://raw.githubusercontent.com/TRONIC-B-21/udp-zivpn/main/config.json -O /etc/udp-zivpn/config.json

echo -e "🔐 Generating powerful SSL certs..."
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
-subj "/C=US/ST=California/L=Los Angeles/O=ZIVPN Hyperdrive/CN=udp-zivpn" \
-keyout "/etc/udp-zivpn/udp-zivpn.key" -out "/etc/udp-zivpn/udp-zivpn.crt"

echo -e "📶 Boosting socket buffers for maximum throughput..."
sysctl -w net.core.rmem_max=16777216 > /dev/null
sysctl -w net.core.wmem_max=16777216 > /dev/null

echo -e "⚙️ Deploying systemd service like a boss..."
cat <<EOF > /etc/systemd/system/udp-zivpn.service
[Unit]
Description=ZIVPN HYPERSPEED UDP SERVER
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

echo -e "\n🔑 ENTER YOUR SUPERSECURE PASSWORDS (Default = zi)"
read -p "💬 Passwords (comma-separated): " input_config
if [ -n "$input_config" ]; then
    IFS=',' read -r -a config <<< "$input_config"
    [ ${#config[@]} -eq 1 ] && config+=("${config[0]}")
else
    config=("zi")
fi

new_config_str="\"config\": [$(printf "\"%s\"," "${config[@]}" | sed 's/,$//')]"
sed -i -E "s/\"config\": ?\[[[:space:]]*\"zi\"[[:space:]]*\]/${new_config_str}/g" /etc/udp-zivpn/config.json

echo -e "🔁 Enabling and launching ZIVPN like a turbo engine..."
systemctl daemon-reexec
systemctl enable udp-zivpn.service
systemctl start udp-zivpn.service

echo -e "🌐 Port redirection & firewall whitelisting..."
iface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
iptables -t nat -A PREROUTING -i "$iface" -p udp --dport 6000:19999 -j DNAT --to-destination :5667
ufw allow 6000:19999/udp
ufw allow 5667/udp

rm -f zi.sh &> /dev/null
echo -e "\n✅ INSTALLATION COMPLETE: ZIVPN IS LIVE AND SCREAMING AT THE SPEED OF UDP 🔥"
