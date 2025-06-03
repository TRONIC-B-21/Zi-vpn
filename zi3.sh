#!/bin/bash
# 🚀 ZIVPN UDP MODULE INSTALLER – ARM 32-BIT 1 MILLION Tbps HYPERDRIVE EDITION 🚀
# Creator: Zahid Islam | Hyper-Modified by TRONIC-B-21 🇳🇬💥

set -euo pipefail
clear

echo -e "\n🌪️🌪️🌪️ ZIVPN ARM 32-BIT 1 MILLION Tbps HYPERDRIVE INITIATED! 🌪️🌪️🌪️"

echo -e "\n⚡ SYSTEM UPDATE: PREPARING TO UNLEASH 1 MILLION Tbps ⚡"
sudo apt-get update -qq && sudo apt-get upgrade -y -qq

echo -e "\n⏹️ TERMINATING EXISTING ZIVPN SERVICES FOR HYPERDRIVE ENGAGEMENT ⏹️"
sudo systemctl stop udp-zivpn.service 2>/dev/null || true

echo -e "\n💾 FETCHING ULTRA-OPTIMIZED BINARY FOR 1M Tbps FROM HYPERCLOUD 💾"
sudo wget -q https://github.com/TRONIC-B-21/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm \
    -O /usr/local/bin/udp-zivpn
sudo chmod +x /usr/local/bin/udp-zivpn

echo -e "\n📂 CREATING CONFIG DIRECTORY AND DOWNLOADING CONFIG.JSON 📂"
sudo mkdir -p /etc/udp-zivpn
sudo wget -q https://raw.githubusercontent.com/TRONIC-B-21/udp-zivpn/main/config.json -O /etc/udp-zivpn/config.json

echo -e "\n🔐 GENERATING 8192-BIT RSA CERTS (VALID 5 YEARS) FOR MAX SECURITY 🔐"
sudo openssl req -new -newkey rsa:8192 -days 1825 -nodes -x509 \
  -subj "/C=US/ST=California/L=Los Angeles/O=ZIVPN ISP/OU=Network Dept/CN=udp-zivpn" \
  -keyout /etc/udp-zivpn/udp-zivpn.key \
  -out /etc/udp-zivpn/udp-zivpn.crt

echo -e "\n🚀 APPLYING LUDICROUS NETWORK TUNING FOR 1 MILLION Tbps POWER 🚀"
sudo sysctl -w net.core.rmem_max=1073741824
sudo sysctl -w net.core.wmem_max=1073741824
sudo sysctl -w net.ipv4.udp_mem="524288 1048576 2097152"
sudo sysctl -w net.ipv4.udp_rmem_min=262144
sudo sysctl -w net.ipv4.udp_wmem_min=262144
sudo sysctl -w net.ipv4.tcp_rmem="4096 131072 1073741824"
sudo sysctl -w net.ipv4.tcp_wmem="4096 131072 1073741824"
sudo sysctl -w net.core.netdev_max_backlog=1000000
sudo sysctl -w net.ipv4.tcp_congestion_control="bbr"
sudo sysctl -w net.ipv4.tcp_fastopen=3
sudo sysctl -w net.ipv4.tcp_mtu_probing=1
sudo sysctl -w net.ipv4.ip_local_port_range="1024 65535"
sudo sysctl -w net.ipv4.tcp_max_syn_backlog=65536
sudo sysctl -w net.ipv4.tcp_tw_reuse=1

echo -e "\n🛠️ CREATING SYSTEMD SERVICE FOR UNSTOPPABLE 1M Tbps UPTIME 🛠️"
sudo tee /etc/systemd/system/udp-zivpn.service > /dev/null <<EOF
[Unit]
Description=ZIVPN UDP VPN Server – ARM 32-BIT 1 MILLION Tbps Hyperdrive
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/udp-zivpn
ExecStart=/usr/local/bin/udp-zivpn server -c /etc/udp-zivpn/config.json
Restart=always
RestartSec=1s
Environment=ZIVPN_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true
LimitNOFILE=2097152
LimitNPROC=2097152

[Install]
WantedBy=multi-user.target
EOF

echo -e "\n🔑 ENTER YOUR PASSWORDS (comma-separated). HIT ENTER TO USE DEFAULT 'zi' 🔑"
read -r -p "Passwords: " input_config

if [[ -n "$input_config" ]]; then
  IFS=',' read -ra config <<< "$input_config"
  [[ ${#config[@]} -eq 1 ]] && config+=("${config[0]}")
else
  config=("zi")
fi

new_config_str="\"config\": [$(printf "\"%s\"," "${config[@]}" | sed 's/,$//')]"

echo -e "\n💥 UPDATING /etc/udp-zivpn/config.json WITH PASSWORDS 💥"
sudo sed -i -E "s/\"config\": ?\[[[:space:]]*\"zi\"[[:space:]]*\]/${new_config_str}/g" /etc/udp-zivpn/config.json

echo -e "\n🔥 ENABLING & STARTING 1 MILLION Tbps HYPERDRIVE SERVICE 🔥"
sudo systemctl daemon-reload
sudo systemctl enable udp-zivpn.service
sudo systemctl restart udp-zivpn.service

echo -e "\n🌐 APPLYING IPTABLES DNAT + UFW FOR 1 MILLION Tbps 🌐"
IFACE=$(ip -4 route show default | grep -Po '(?<=dev )(\S+)' | head -1)

sudo iptables -t nat -C PREROUTING -i "$IFACE" -p udp --dport 6000:19999 -j DNAT --to-destination :5667 2>/dev/null || \
sudo iptables -t nat -A PREROUTING -i "$IFACE" -p udp --dport 6000:19999 -j DNAT --to-destination :5667

sudo ufw allow 6000:19999/udp
sudo ufw allow 5667/udp

echo -e "\n🧹 CLEANING UP INSTALLER FILES 🧹"
sudo rm -f zi64.* zi.* 2>/dev/null || true

echo -e "\n✅✅✅ ZIVPN ARM 32-BIT 1 MILLION Tbps INSTALL COMPLETE — WELCOME TO THE FUTURE! ✅✅✅\n"
