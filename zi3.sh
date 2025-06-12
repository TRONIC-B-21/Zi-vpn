#!/bin/bash
# ZIVPN UDP Module installer & optimizer - ARM64
# Creator: Saunders Tobin | Enhanced by Terry's Assistant

set -euo pipefail
IFS=$'\n\t'

# Identify primary network interface
IFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )\S+' | head -1)

echo -e "\n🔄 Updating server and dependencies"
apt-get update && apt-get upgrade -y

echo -e "\n⏹️ Stopping existing service (if any)"
systemctl stop udp-zivpn.service 2> /dev/null || true

echo -e "\n⬇️ Downloading ZIVPN UDP binary (ARM64)"
wget -q https://github.com/TRONIC-B-21/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm64 -O /usr/local/bin/udp-zivpn
chmod +x /usr/local/bin/udp-zivpn

echo -e "\n📂 Creating config directory and fetching default config"
mkdir -p /etc/udp-zivpn
download_url="https://raw.githubusercontent.com/TRONIC-B-21/udp-zivpn/main/config.json"
wget -q "$download_url" -O /etc/udp-zivpn/config.json

echo -e "\n🔐 Generating TLS certificate and key"
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=US/ST=California/L=Los Angeles/O=Example Corp/OU=IT Department/CN=udp-zivpn" \
    -keyout "/etc/udp-zivpn/udp-zivpn.key" \
    -out "/etc/udp-zivpn/udp-zivpn.crt"

echo -e "\n⚙️ Applying sysctl network optimizations for 1Gbps & low latency"
cat <<EOF > /etc/sysctl.d/99-udp-zivpn.conf
net.core.rmem_max=33554432
net.core.wmem_max=33554432
net.ipv4.tcp_rmem=4096 87380 33554432
net.ipv4.tcp_wmem=4096 65536 33554432
net.ipv4.tcp_congestion_control=bbr2
net.core.default_qdisc=fq
net.ipv4.tcp_fastopen=3
net.netfilter.nf_conntrack_max=262144
EOF
sysctl --system 1> /dev/null

echo -e "\n🚦 Installing iproute2 & configuring cake qdisc on $IFACE for 1Gbps bandwidth"
apt-get install -y iproute2
tc qdisc replace dev "$IFACE" root cake bandwidth 1gbps nat dual-srchost

echo -e "\n⚙️ Creating systemd service file"
cat <<EOF > /etc/systemd/system/udp-zivpn.service
[Unit]
Description=ZIVPN UDP Server
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

# Password setup prompt
echo -e "\n🔑 ZIVPN UDP Passwords Setup"
read -p "Enter passwords comma-separated (default 'zi'): " input_config || true
if [[ -n "${input_config// /}" ]]; then
    IFS=',' read -r -a config <<< "$input_config"
    [[ ${#config[@]} -eq 1 ]] && config+=(${config[0]})
else
    config=("zi")
fi
new_config_str="\"config\": [$(printf '\"%s\",' "${config[@]}" | sed 's/,$//')]"
sed -i -E "s/\"config\": ?\[[^]]*\]/${new_config_str}/g" /etc/udp-zivpn/config.json

echo -e "\n📡 Enabling and starting udp-zivpn.service"
systemctl daemon-reload
device="udp-zivpn.service"
systemctl enable "$device"
systemctl start "$device"

echo -e "\n🛡️ Configuring firewall rules"
iptables -t nat -A PREROUTING -i "$IFACE" -p udp --dport 6000:19999 -j DNAT --to-destination :5667
ufw allow 6000:19999/udp
ufw allow 5667/udp

echo -e "\n✅ ZIVPN Installed & Optimized for 1Gbps with BBR2 and Cake Qdisc!"
