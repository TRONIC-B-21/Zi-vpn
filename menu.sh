#!/bin/bash
# Hyper - Tronic

IP=$(curl -s4 icanhazip.com)
distribution=$(lsb_release -ds 2>/dev/null || cat /etc/*release | head -n1)
Network=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)

# Replace netstat with ss to get UDP ports
if command -v ss >/dev/null 2>&1; then
  ports=$(ss -tunlp | grep udp-zivpn | awk '{print $5}' | cut -d: -f2 | tr '\n' ' ')
else
  echo "Error: ss command not found. Please install iproute2 package."
  ports="N/A"
fi

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
GRAY='\033[1;37m'
RESET='\033[0m'

# Ensure root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}Run this script as root!${RESET}"
  exit 1
fi

# Install V1
installv1() {
  local yesno
  echo -e "${RED} ────────────── /// ─────────────── "
  echo -e "${YELLOW}This will install ZIVPN V1 with UDP ports 20000:50000 redirected to 5667"
  read -p "${YELLOW}Continue? [Y/N]: " yesno
  [[ "$yesno" =~ ^[yYsS]$ ]] && bash <(curl -fsSL https://raw.githubusercontent.com/TRONIC-B-21/udp-zivpn/main/zi.sh)
}

# Install V2 AMD
installv2() {
  local yesno
  echo -e "${RED} ────────────── /// ─────────────── "
  echo -e "${YELLOW}This will install ZIVPN V2 (AMD) with UDP ports 6000:19999 redirected to 5667"
  read -p "${YELLOW}Continue? [Y/N]: " yesno
  [[ "$yesno" =~ ^[yYsS]$ ]] && bash <(curl -fsSL https://raw.githubusercontent.com/TRONIC-B-21/udp-zivpn/main/zi2.sh)
}

# Install V2 ARM
installv3() {
  local yesno
  echo -e "${RED} ────────────── /// ─────────────── "
  echo -e "${YELLOW}This will install ZIVPN V2 (ARM) with UDP ports 6000:19999 redirected to 5667"
  read -p "${YELLOW}Continue? [Y/N]: " yesno
  [[ "$yesno" =~ ^[yYsS]$ ]] && bash <(curl -fsSL https://raw.githubusercontent.com/TRONIC-B-21/udp-zivpn/main/zi3.sh)
}

# Uninstall
uninstall() {
  local yesno
  echo -e "${RED} ────────────── /// ─────────────── "
  echo -e "${YELLOW}This will uninstall all ZIVPN services"
  read -p "${YELLOW}Continue? [Y/N]: " yesno
  [[ "$yesno" =~ ^[yYsS]$ ]] && bash <(curl -fsSL https://raw.githubusercontent.com/TRONIC-B-21/udp-zivpn/main/uninstall.sh)
}

# Start Services
startudp-zivpn() {
  local yesno
  echo -e "${RED} ────────────── /// ─────────────── "
  echo -e "${YELLOW}Start ZIVPN server?"
  read -p "${YELLOW}[Y/N]: " yesno
  if [[ "$yesno" =~ ^[yYsS]$ ]]; then
    [[ -f /etc/systemd/system/udp-zivpn.service ]] && systemctl start udp-zivpn.service
    [[ -f /etc/systemd/system/udp-zivpn_backfill.service ]] && systemctl start udp-zivpn_backfill.service
    echo -e "${GREEN}ZIVPN services started.${RESET}"
  fi
}

# Stop Services
stopudp-zivpn() {
  local yesno
  echo -e "${RED} ────────────── /// ─────────────── "
  echo -e "${YELLOW}Stop ZIVPN server?"
  read -p "${YELLOW}[Y/N]: " yesno
  if [[ "$yesno" =~ ^[yYsS]$ ]]; then
    [[ -f /etc/systemd/system/udp-zivpn.service ]] && systemctl stop udp-zivpn.service
    [[ -f /etc/systemd/system/udp-zivpn_backfill.service ]] && systemctl stop udp-zivpn_backfill.service
    echo -e "${GREEN}ZIVPN services stopped.${RESET}"
  fi
}

# Restart Services
restartudp-zivpn() {
  local yesno
  echo -e "${RED} ────────────── /// ─────────────── "
  echo -e "${YELLOW}Restart ZIVPN server?"
  read -p "${YELLOW}[Y/N]: " yesno
  if [[ "$yesno" =~ ^[yYsS]$ ]]; then
    [[ -f /etc/systemd/system/udp-zivpn.service ]] && systemctl restart udp-zivpn.service
    [[ -f /etc/systemd/system/udp-zivpn_backfill.service ]] && systemctl restart udp-zivpn_backfill.service
    echo -e "${GREEN}ZIVPN services restarted.${RESET}"
  fi
}

# Menu
while true; do
  clear && printf '\e[3J'
  echo -e "${GRAY}[${RED}-${GRAY}]${RED} ────────────── /// ─────────────── "
  echo -e "${YELLOW}   【          ${RED}ZIVPN MANAGER           ${YELLOW}】 "
  echo -e "${YELLOW} › ${WHITE}Linux Dist:${GREEN} $distribution"
  echo -e "${YELLOW} › ${WHITE}IP:         ${GREEN} $IP"
  echo -e "${YELLOW} › ${WHITE}Network:    ${GREEN} $Network"
  echo -e "${YELLOW} › ${WHITE}Running:    ${GREEN} $ports"
  echo -e "${GRAY}[${RED}-${GRAY}]${RED} ────────────── /// ─────────────── "
  echo -e "${YELLOW}[${GREEN}1${YELLOW}] ${RED} › ${WHITE} INSTALL ZIVPN V1 (5666) [Recommended]"
  echo -e "${YELLOW}[${GREEN}2${YELLOW}] ${RED} › ${WHITE} INSTALL ZIVPN V2 AMD (5667) [Recommended]"
  echo -e "${YELLOW}[${GREEN}3${YELLOW}] ${RED} › ${WHITE} INSTALL ZIVPN V2 ARM (5667)"
  echo -e "${YELLOW}[${GREEN}4${YELLOW}] ${RED} › ${WHITE} UNINSTALL ZIVPN"
  echo -e "${YELLOW}[${GREEN}5${YELLOW}] ${RED} › ${WHITE} START ZIVPN"
  echo -e "${YELLOW}[${GREEN}6${YELLOW}] ${RED} › ${WHITE} STOP ZIVPN"
  echo -e "${YELLOW}[${GREEN}7${YELLOW}] ${RED} › ${WHITE} RESTART ZIVPN"
  echo -e "${YELLOW}[${GREEN}0${YELLOW}] ${RED} › ${WHITE} EXIT"
  echo -e "${GRAY}[${RED}-${GRAY}]${RED} ────────────── /// ─────────────── "
  read -p "${YELLOW} Δ CHOOSE AN OPTION: ${RESET}" option
  tput cuu1 && tput dl1

  case $option in
    1|01) installv1 ;;
    2|02) installv2 ;;
    3|03) installv3 ;;
    4|04) uninstall ;;
    5|05) startudp-zivpn ;;
    6|06) stopudp-zivpn ;;
    7|07) restartudp-zivpn ;;
    0) clear; exit ;;
    *) echo -e "${RED}Invalid option.${RESET}" ;;
  esac
done
