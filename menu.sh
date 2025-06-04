#!/bin/bash
# Hyper - Tronic | Styled ZIVPN Manager

# Define colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
GRAY='\033[1;90m'
RESET='\033[0m'

# Get system info
IP=$(curl -s4 icanhazip.com)
distribution=$(lsb_release -ds 2>/dev/null || cat /etc/*release | head -n1)
Network=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)

# Replace netstat with ss to get UDP ports
if command -v ss >/dev/null 2>&1; then
  ports=$(ss -tunlp | grep udp-zivpn | awk '{print $5}' | cut -d: -f2 | tr '\n' ' ')
else
  echo -e "${RED}Error: ss command not found. Please install iproute2 package.${RESET}"
  ports="N/A"
fi

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}Run this script as root!${RESET}"
  exit 1
fi

# ─── Menu Functions ──────────────────────────────────────────────────────────

installv1() {
  echo -e "${MAGENTA}[ Installing ZIVPN V1 (UDP 20000–50000 ➔ 5667) ]${RESET}"
  read -p "${YELLOW}Continue? [Y/N]: ${RESET}" yesno
  if [[ "$yesno" =~ ^[yYsS]$ ]]; then
    bash <(curl -fsSL https://raw.githubusercontent.com/TRONIC-B-21/udp-zivpn/main/zi.sh)
  fi
}

installv2() {
  echo -e "${MAGENTA}[ Installing ZIVPN V2 AMD (UDP 6000–19999 ➔ 5667) ]${RESET}"
  read -p "${YELLOW}Continue? [Y/N]: ${RESET}" yesno
  if [[ "$yesno" =~ ^[yYsS]$ ]]; then
    bash <(curl -fsSL https://raw.githubusercontent.com/TRONIC-B-21/udp-zivpn/main/zi2.sh)
  fi
}

installv3() {
  echo -e "${MAGENTA}[ Installing ZIVPN V2 ARM (UDP 6000–19999 ➔ 5667) ]${RESET}"
  read -p "${YELLOW}Continue? [Y/N]: ${RESET}" yesno
  if [[ "$yesno" =~ ^[yYsS]$ ]]; then
    bash <(curl -fsSL https://raw.githubusercontent.com/TRONIC-B-21/udp-zivpn/main/zi3.sh)
  fi
}

uninstall() {
  echo -e "${MAGENTA}[ Uninstalling All ZIVPN Services ]${RESET}"
  read -p "${YELLOW}Continue? [Y/N]: ${RESET}" yesno
  if [[ "$yesno" =~ ^[yYsS]$ ]]; then
    bash <(curl -fsSL https://raw.githubusercontent.com/TRONIC-B-21/udp-zivpn/main/uninstall.sh)
  fi
}

startudp-zivpn() {
  echo -e "${MAGENTA}[ Starting ZIVPN Service ]${RESET}"
  read -p "${YELLOW}Continue? [Y/N]: ${RESET}" yesno
  if [[ "$yesno" =~ ^[yYsS]$ ]]; then
    [[ -f /etc/systemd/system/udp-zivpn.service ]] && systemctl start udp-zivpn.service
    [[ -f /etc/systemd/system/udp-zivpn_backfill.service ]] && systemctl start udp-zivpn_backfill.service
    echo -e "${GREEN}ZIVPN services started.${RESET}"
  fi
}

stopudp-zivpn() {
  echo -e "${MAGENTA}[ Stopping ZIVPN Service ]${RESET}"
  read -p "${YELLOW}Continue? [Y/N]: ${RESET}" yesno
  if [[ "$yesno" =~ ^[yYsS]$ ]]; then
    [[ -f /etc/systemd/system/udp-zivpn.service ]] && systemctl stop udp-zivpn.service
    [[ -f /etc/systemd/system/udp-zivpn_backfill.service ]] && systemctl stop udp-zivpn_backfill.service
    echo -e "${GREEN}ZIVPN services stopped.${RESET}"
  fi
}

restartudp-zivpn() {
  echo -e "${MAGENTA}[ Restarting ZIVPN Service ]${RESET}"
  read -p "${YELLOW}Continue? [Y/N]: ${RESET}" yesno
  if [[ "$yesno" =~ ^[yYsS]$ ]]; then
    [[ -f /etc/systemd/system/udp-zivpn.service ]] && systemctl restart udp-zivpn.service
    [[ -f /etc/systemd/system/udp-zivpn_backfill.service ]] && systemctl restart udp-zivpn_backfill.service
    echo -e "${GREEN}ZIVPN services restarted.${RESET}"
  fi
}

# ─── Main Menu Loop ───────────────────────────────────────────────────────────

while true; do
  clear && printf '\e[3J'
  echo -e "${GRAY}[${RED}-${GRAY}]${RED} ─────────────────────────────────────────────────────── ${GRAY}[${RED}-${GRAY}]"
  echo -e "${YELLOW}             ⚙️  ${BLUE}ZIVPN MANAGER by TRONIC-B-21 ⚙️"
  echo -e "${GRAY}────────────────────────────────────────────────────────${GRAY}"
  echo -e "${CYAN} › ${WHITE}Linux Distro : ${GREEN}$distribution"
  echo -e "${CYAN} › ${WHITE}Public IP     : ${GREEN}$IP"
  echo -e "${CYAN} › ${WHITE}Network IF    : ${GREEN}$Network"
  echo -e "${CYAN} › ${WHITE}Active Ports  : ${GREEN}$ports"
  echo -e "${GRAY}────────────────────────────────────────────────────────"

  echo -e "${YELLOW}[${GREEN}1${YELLOW}] ${WHITE}Install ${CYAN}ZIVPN V1${WHITE} (UDP 20000–50000 ➜ 5667)"
  echo -e "${YELLOW}[${GREEN}2${YELLOW}] ${WHITE}Install ${CYAN}ZIVPN V2 AMD${WHITE} (UDP 6000–19999 ➜ 5667)"
  echo -e "${YELLOW}[${GREEN}3${YELLOW}] ${WHITE}Install ${CYAN}ZIVPN V2 ARM${WHITE} (UDP 6000–19999 ➜ 5667)"
  echo -e "${YELLOW}[${GREEN}4${YELLOW}] ${WHITE}Uninstall ${RED}ZIVPN"
  echo -e "${YELLOW}[${GREEN}5${YELLOW}] ${WHITE}Start ${GREEN}ZIVPN"
  echo -e "${YELLOW}[${GREEN}6${YELLOW}] ${WHITE}Stop ${RED}ZIVPN"
  echo -e "${YELLOW}[${GREEN}7${YELLOW}] ${WHITE}Restart ${CYAN}ZIVPN"
  echo -e "${YELLOW}[${GREEN}0${YELLOW}] ${WHITE}Exit"
  echo -e "${GRAY}────────────────────────────────────────────────────────${RESET}"

  # Prompt in bold blue, allow inline choice like CHOOSE AN OPTION:2
  read -p $'\n\033[1;34mCHOOSE AN OPTION:\033[0m' raw_option
  tput cuu1 && tput dl1

  # If user typed something like "2" or "CHOOSE AN OPTION:2", extract the number
  option=$(echo "$raw_option" | awk -F':' '{print $NF}')

  case "$option" in
    1|01) installv1 ;;
    2|02) installv2 ;;
    3|03) installv3 ;;
    4|04) uninstall ;;
    5|05) startudp-zivpn ;;
    6|06) stopudp-zivpn ;;
    7|07) restartudp-zivpn ;;
    0|00) clear; exit ;;
    *) echo -e "${RED}Invalid option! Please try again.${RESET}" && sleep 1 ;;
  esac
done
