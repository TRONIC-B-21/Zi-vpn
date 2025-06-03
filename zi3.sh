#!/bin/bash
# 🚀 ZIVPN UDP MODULE INSTALLER – ARM32 10Tbps Hyperdrop Edition 🚀
# Creator: Zahid Islam | Hyper-Modified by TRONIC-B-21 🇳🇬💥

set -euo pipefail
clear

echo -e "\n🔥🔥🔥 ZIVPN ARM32 10Tbps HYPERDROP – FULL THROTTLE ENGAGED! 🔥🔥🔥"

echo -e "\n⚡ UPDATING SYSTEM (SILENT MODE) FOR MAX PERFORMANCE ⚡"
sudo apt-get update -qq && sudo apt-get upgrade -y -qq

echo -e "\n⏹️ STOP ANY RUNNING ZIVPN SERVICE – STAND CLEAR! ⏹️"
sudo systemctl stop udp-zivpn.service 2>/dev/null || true

echo -e "\n💾 DOWNLOADING ULTRAFAST ARM32 BINARY FROM HYPERCLOUD 💾"
sudo wget -q https://github.com/TRONIC-B-21/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm \
    -O /usr/local/bin/udp-zivpn
sudo chmod +x /usr/local/bin/udp-zivpn

echo -e "\n📂 CREATING CONFIG DIRECTORY & FETCHING CONFIG.JSON 📂"
sudo mkdir -p /etc/udp-zivpn
sudo wget -q https://raw.githubusercontent.com/TRONIC-B-21/udp-zivpn/main/config.json \
    -O /etc/udp-zivpn/config.json

echo -e "\n🔐 GENERATING 4096-BIT RSA CERTS (VALID 2 YEARS) 🔐"
sudo openssl req -new -newkey rsa:4096 -days 730 -nodes -x509 \
    -subj "/C=US/ST=California/L=Los Angeles/O=ZIVPN ISP/OU=Network Dept/CN=udp-zivpn" \
    -keyout /etc/udp-zivpn/udp-zivpn.key \
    -out    /etc/udp-zivpn/udp-zivpn.crt

echo -e "\n🚀 TUNING KERNEL NETWORK PARAMETERS FOR PURE 10Tbps POWER 🚀"
sudo sysctl -w net.core.rmem_max=33554432      # 32 MB recv buffer
sudo sysctl -w net.core.wmem_max=33554432      # 32 MB send buffer
sudo sysctl -w net.ipv4.udp_mem="65536 131072 262144"
sudo sysctl -w net.ipv4.udp_rmem_min=65536
sudo sysctl -w net.ipv4.udp_wmem_min=65536
sudo sysctl -w net.ipv4.tcp_rmem="4096 87380 33554432"
sudo sysctl -w net.ipv4.tcp_wmem="4096 65536 33554432"
sudo sysctl -w net.core.netdev_max_backlog=50000
sudo sysctl -w net.ipv4.tcp_congestion_control="bbr"
sudo sysctl -w net.ipv4.tcp_fastopen=3
sudo sysctl -w net.ipv4.tcp_mtu_probing=1
sudo sysctl -w net.ipv4.ip_local_port_range="1024 65535"
sudo sysctl -w net.ipv4.tcp_max_syn_backlog=8192
sudo sysctl -w net.ipv4.tcp_tw_reuse=1

echo -e "\n🛠️ CREATING SYSTEMD SERVICE FOR 24/7/365 UPTIME 🛠️"
sudo tee /etc/systemd/system/udp-zivpn.service > /dev/null <<EOF
[Unit]
Description=ZIVPN UDP VPN Server – ARM32 10Tbps Hyperdrop
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
LimitNOFILE=1048576
LimitNPROC=1048576

[Install]
WantedBy=multi-user.target
EOF

echo -e "\n🔑 ENTER YOUR SUPER-STRONG PASSWORDS (comma-separated)\n   Default if ENTER: 'zi' 🔑"
read -r -p "Passwords: " input_config

if [[ -n "$input_config" ]]; then
  IFS=',' read -ra config <<< "$input_config"
  [[ ${#config[@]} -eq 1 ]] && config+=("${config[0]}")
else
  config=("zi")
fi

new_config_str="\"config\": [$(printf "\"%s\"," "${config[@]}" | sed 's/,$//')]"

echo -e "\n💥 UPDATING /etc/udp-zivpn/config.json WITH PASSWORDS 💥"
sudo sed -i -E "s/\"config\": ?\[[[:space:]]*\"zi\"[[:space:]]*\]/${new_config_str}/g" \
  /etc/udp-zivpn/config.json

echo -e "\n🔥 ENABLING & STARTING UDP-ZIVPN SERVICE 🔥"
sudo systemctl daemon-reload
sudo systemctl enable udp-zivpn.service
sudo systemctl restart udp-zivpn.service

echo -e "\n🌐 APPLYING IPTABLES DNAT + UFW RULES FOR MAX UDP THROUGHPUT 🌐"
IFACE=$(ip -4 route show default | grep -Po '(?<=dev )(\S+)' | head -1)

# Add DNAT only if not already present
sudo iptables -t nat -C PREROUTING -i "$IFACE" -p udp --dport 6000:19999 -j DNAT --to-destination :5667 \
  2>/dev/null || \
sudo iptables -t nat -A PREROUTING -i "$IFACE" -p udp --dport 6000:19999 -j DNAT --to-destination :5667

sudo ufw allow 6000:19999/udp
sudo ufw allow 5667/udp

echo -e "\n🧹 CLEANING UP INSTALLER FILES 🧹"
sudo rm -f zi32.* zi.* 2>/dev/null || true

echo -e "\n✅✅✅ ZIVPN ARM32 10Tbps INSTALL COMPLETE — UNLEASH HYPERFAST SPEEDS! ✅✅✅\n"
