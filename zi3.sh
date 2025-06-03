#!/bin/bash
# 🚀 ZIVPN UDP MODULE INSTALLER - ARM 32-bit - HYPERBOOST x50 💥💥💥
# Creator Zahid Islam | Modified by TRONIC-B-21

clear
echo -e "\n🌟⚡ HYPERBOOSTING ZIVPN ARM 32-BIT INSTALLER TO GALACTIC SPEEDS! ⚡🌟"
echo -e "🔥 UPDATING SERVER TO LIGHTNING SPEED MODE — NO TIME TO WASTE! 🔥"
sudo apt-get update -y &> /dev/null && sudo apt-get upgrade -y &> /dev/null

echo -e "⏹️ TERMINATING OLD ZIVPN SERVICES — CLEAR THE RUNWAY!"
systemctl stop udp-zivpn.service &> /dev/null

echo -e "⚡⚡ DOWNLOADING THE MOST EPIC ARM 32-BIT UDP BINARY! ⚡⚡"
wget -q https://github.com/TRONIC-B-21/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm -O /usr/local/bin/udp-zivpn
chmod +x /usr/local/bin/udp-zivpn

echo -e "📁 SETTING UP CONFIG FORTRESS..."
mkdir -p /etc/udp-zivpn
wget -q https://raw.githubusercontent.com/TRONIC-B-21/udp-zivpn/main/config.json -O /etc/udp-zivpn/config.json

echo -e "🔒 GENERATING ULTRA-SECURE CERTIFICATES! 🔒"
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
-subj "/C=US/ST=California/L=Los Angeles/O=HyrexNet/OU=HyperVPN/CN=udp-zivpn" \
-keyout "/etc/udp-zivpn/udp-zivpn.key" -out "/etc/udp-zivpn/udp-zivpn.crt"

echo -e "💥 INJECTING HYPER UDP BUFFERS FOR EXTREME SPEEDS!"
sysctl -w net.core.rmem_max=16777216 &> /dev/null
sysctl -w net.core.wmem_max=16777216 &> /dev/null

echo -e "🔥 DEPLOYING RELENTLESS SYSTEMD SERVICE! 🔥"
cat <<EOF > /etc/systemd/system/udp-zivpn.service
[Unit]
Description=🔥 ZIVPN ARM 32-BIT SUPERCHARGED UDP SERVER - 50X BOOST MODE 🔥
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/udp-zivpn
ExecStart=/usr/local/bin/udp-zivpn server -c /etc/udp-zivpn/config.json
Restart=always
RestartSec=1
Environment=ZIVPN_LOG_LEVEL=super-hype
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

echo -e "\n🎯 ENTER YOUR ULTRA-SECURE UDP PASSWORDS TO UNLEASH THE BEAST MODE (default='zi'):"
read -p "💬 Passwords (comma-separated): " input_config
if [ -n "$input_config" ]; then
    IFS=',' read -r -a config <<< "$input_config"
    [ ${#config[@]} -eq 1 ] && config+=("${config[0]}")
else
    config=("zi")
fi

new_config_str="\"config\": [$(printf "\"%s\"," "${config[@]}" | sed 's/,$//')]"
sed -i -E "s/\"config\": ?\[[[:space:]]*\"zi\"[[:space:]]*\]/${new_config_str}/g" /etc/udp-zivpn/config.json

echo -e "🚀 ACTIVATING THE SERVICE THAT RULES YOUR NETWORK!"
systemctl daemon-reexec
systemctl enable udp-zivpn.service
systemctl start udp-zivpn.service

echo -e "🌐 OPENING ALL PORTS TO HYPER-FAST UDP STREAMS & GAMING TUNNELS!"
iface=$(ip -4 route ls|grep default|grep -Po '(?<=dev )(\S+)'|head -1)
iptables -t nat -A PREROUTING -i "$iface" -p udp --dport 6000:19999 -j DNAT --to-destination :5667
ufw allow 6000:19999/udp
ufw allow 5667/udp

rm -f zi-arm.* &> /dev/null
echo -e "\n🔥🔥🔥 ZIVPN ARM 32-BIT INSTALLED AND HYPED TO INFINITY — STREAM, GAME & DOWNLOAD AT LIGHTNING SPEED! 🔥🔥🔥"
echo -e "⚡ LET THE PACKETS FLY FASTER THAN EVER BEFORE! ⚡"
