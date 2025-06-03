#!/bin/bash
# ZIVPN UDP & WireGuard Installer - VoltSSH Style
# Maintainer: TRONIC-B-21
# https://github.com/TRONIC-B-21/zivpn

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

clear
echo -e "${GREEN}"
echo "╔════════════════════════════════════════╗"
echo "║           ZIVPN Installer              ║"
echo "║         Maintained by TRONIC-B-21      ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"

# Check if run as root
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}Error: This script must be run as root!${NC}"
  exit 1
fi

# Basic system update
echo -e "${YELLOW}[*] Updating system packages...${NC}"
apt-get update -y && apt-get upgrade -y

# Enable BBR and UDP tuning
echo -e "${YELLOW}[*] Enabling BBR and tuning kernel parameters...${NC}"
modprobe tcp_bbr
echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
sysctl -p
sysctl -w net.core.rmem_max=2500000
sysctl -w net.core.wmem_max=2500000
sysctl -w net.ipv4.ip_forward=1

# Stop any existing services
echo -e "${YELLOW}[*] Stopping existing ZIVPN or WireGuard services if any...${NC}"
systemctl stop zivpn.service 2>/dev/null || true
systemctl stop udp-zivpn.service 2>/dev/null || true
systemctl stop wg-quick@wg0.service 2>/dev/null || true

# Download ZIVPN UDP binary
echo -e "${YELLOW}[*] Downloading ZIVPN UDP binary...${NC}"
curl -L -o /usr/local/bin/udp-zivpn https://github.com/TRONIC-B-21/zivpn/releases/latest/download/udp-zivpn-linux-amd64
chmod +x /usr/local/bin/udp-zivpn

# Setup config directory and default config
echo -e "${YELLOW}[*] Setting up config directory and default config...${NC}"
mkdir -p /etc/zivpn
cat > /etc/zivpn/config.json <<EOF
{
  "listen": ":5667",
  "mtu": 1350,
  "cipher": "chacha20-poly1305",
  "handshake_timeout": 5,
  "idle_timeout": 300,
  "log_level": "info",
  "config": ["zi"]
}
EOF

# Ask user for passwords
read -p "Enter UDP passwords (comma separated, default: zi): " passwords
if [[ -z "$passwords" ]]; then
  passwords="zi"
fi

# Format passwords into JSON array
IFS=',' read -ra arr <<< "$passwords"
pw_json=$(printf "\"%s\"," "${arr[@]}")
pw_json="[${pw_json%,}]"

# Replace config passwords in config.json
sed -i -E "s/\"config\": ?\[[^]]*\]/\"config\": $pw_json/" /etc/zivpn/config.json

# Setup systemd service for ZIVPN UDP
echo -e "${YELLOW}[*] Creating systemd service for ZIVPN UDP...${NC}"
cat > /etc/systemd/system/udp-zivpn.service <<EOF
[Unit]
Description=ZIVPN UDP Server
After=network.target

[Service]
ExecStart=/usr/local/bin/udp-zivpn server -c /etc/zivpn/config.json
Restart=always
RestartSec=3
User=root
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

# Install WireGuard
echo -e "${YELLOW}[*] Installing WireGuard...${NC}"
apt-get install -y wireguard iptables

# Generate WireGuard keys if not exist
if [ ! -f /etc/wireguard/privatekey ]; then
  umask 077
  wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
fi

PRIVATE_KEY=$(cat /etc/wireguard/privatekey)
PUBLIC_KEY=$(cat /etc/wireguard/publickey)

# Configure WireGuard interface
echo -e "${YELLOW}[*] Setting up WireGuard interface wg0...${NC}"
cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
PrivateKey = $PRIVATE_KEY
Address = 10.10.10.1/24
ListenPort = 51820
SaveConfig = true
EOF

# Enable IP masquerading and forwarding for WireGuard
IFACE=$(ip -4 route show default | grep default | awk '{print $5}')

iptables -A FORWARD -i wg0 -j ACCEPT
iptables -A FORWARD -o wg0 -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o $IFACE -j MASQUERADE

# Enable and start WireGuard
systemctl enable wg-quick@wg0
systemctl restart wg-quick@wg0

# Enable and start ZIVPN UDP
systemctl daemon-reload
systemctl enable udp-zivpn
systemctl restart udp-zivpn

# Setup iptables for ZIVPN UDP ports
iptables -t nat -A PREROUTING -i $IFACE -p udp --dport 6000:19999 -j DNAT --to-destination :5667

echo -e "${GREEN}[✔] Installation complete!${NC}"
echo -e "ZIVPN UDP listening on port 5667"
echo -e "WireGuard listening on port 51820"
echo -e "WireGuard public key:\n$PUBLIC_KEY"
