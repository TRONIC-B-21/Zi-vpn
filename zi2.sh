#!/bin/bash
# ZIVPN UDP Module installer & optimizer - ARM64
# Creator: SAUNDERS | Modified by TRONIC-B-21 | Enhanced by Terry's Assistant

set -euo pipefail
IFS=$'\n\t'

# Identify primary network interface
IFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )\S+' | head -1)

echo -e "\n🔄 Updating server and dependencies"
sudo apt-get update && sudo apt-get upgrade -y

echo -e "\n⏹️ Stopping existing UDP service (if any)"
sudo systemctl stop udp-zivpn.service 2> /dev/null || true

# Download and install ARM binary
echo -e "\n⬇️ Downloading ARM64 UDP Service"
sudo wget -q https://github.com/TRONIC-B-21/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm64 \
    -O /usr/local/bin/udp-zivpn
sudo chmod +x /usr/local/bin/udp-zivpn

# Configuration directory and default config
sudo mkdir -p /etc/udp-zivpn
echo -e "\n⬇️ Fetching default config"
sudo wget -q https://raw.githubusercontent.com/TRONIC-B-21/udp-zivpn/main/config.json \
    -O /etc/udp-zivpn/config.json

# Generate TLS certificates
echo -e "\n🔐 Generating certificate"
sudo openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=US/ST=California/L=Los Angeles/O=Example Corp/OU=IT Department/CN=udp-zivpn" \
    -keyout "/etc/udp-zivpn/udp-zivpn.key" \
    -out "/etc/udp-zivpn/udp-zivpn.crt"

# Enable fastest BBR variant and system tuning
echo -e "\n⚙️ Applying sysctl network optimizations for 1Gbps & ultra-low latency"
sudo tee /etc/sysctl.d/99-udp-zivpn.conf > /dev/null <<EOF
net.core.rmem_max=33554432
net.core.wmem_max=33554432
net.ipv4.tcp_rmem=4096 87380 33554432
net.ipv4.tcp_wmem=4096 65536 33554432
net.ipv4.tcp_congestion_control=bbr2
net.core.default_qdisc=fq
net.ipv4.tcp_fastopen=3
net.netfilter.nf_conntrack_max=262144
EOF
sudo sysctl --system 1> /dev/null

# Install and configure traffic shaping with cake qdisc for streaming and fair-queuing
echo -e "\n🚦 Configuring traffic control (cake) on $IFACE for 1Gbps bandwidth"
sudo apt-get install -y iproute2
sudo tc qdisc replace dev $IFACE root cake bandwidth 1gbps nat dual-srchost

# Create systemd service file
echo -e "\n⚙️ Creating systemd service"
sudo tee /etc/systemd/system/udp-zivpn.service > /dev/null <<EOF
[Unit]
Description=ZIVPN UDP VPN Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/udp-zivpn
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

# Prompt for UDP passwords and update config
read -p "\n🔑 Enter UDP passwords (comma-separated, default 'zi'): " input_config || true
if [ -n "${input_config// /}" ]; then
    IFS=',' read -r -a config <<< "$input_config"
    [ ${#config[@]} -eq 1 ] && config+=(${config[0]})
else
    config=("zi")
fi
new_config_str="\"config\": [$(printf '\"%s\",' "${config[@]}" | sed 's/,$//')]"
sudo sed -i -E "s/\"config\": ?\[[^\]]*\]/${new_config_str}/g" /etc/udp-zivpn/config.json

# Enable and start service
echo -e "\n📡 Enabling and starting udp-zivpn.service"
sudo systemctl daemon-reload
sudo systemctl enable udp-zivpn.service
sudo systemctl start udp-zivpn.service

# Firewall rules
echo -e "\n🛡️ Configuring firewall"
sudo iptables -t nat -A PREROUTING -i $IFACE -p udp --dport 6000:19999 -j DNAT --to-destination :5667
sudo ufw allow 6000:19999/udp
sudo ufw allow 5667/udp

echo -e "\n✅ ZIVPN UDP Installed & Optimized for 1Gbps with BBR2 and Cake Qdisc!"
