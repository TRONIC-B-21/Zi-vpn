#!/bin/bash

# Define colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
RESET='\033[0m'

# Get system info
distribution=$(awk -F= '/^NAME/{print $2}' /etc/os-release | tr -d '"')
IP=$(curl -s ifconfig.me)
Network=$(ip -o -4 route show to default | awk '{print $5}')
ports=$(ss -tuln | grep 566 | awk '{print $5}' | cut -d: -f2 | sort -u | paste -sd "," -)

# Menu functions
installv1() {
  echo -e "${GREEN}Installing ZIVPN V1...${RESET}"
  # Your installation logic here
  sleep 1
}
installv2() {
  echo -e "${GREEN}Installing ZIVPN V2 AMD...${RESET}"
  # Your installation logic here
  sleep 1
}
installv3() {
  echo -e "${GREEN}Installing ZIVPN V2 ARM...${RESET}"
  # Your installation logic here
  sleep 1
}
uninstall() {
  echo -e "${RED}Uninstalling ZIVPN...${RESET}"
  # Your uninstall logic here
  sleep 1
}
startudp-zivpn() {
  echo -e "${GREEN}Starting ZIVPN...${RESET}"
  # Your start logic here
  sleep 1
}
stopudp-zivpn() {
  echo -e "${RED}Stopping ZIVPN...${RESET}"
  # Your stop logic here
  sleep 1
}
restartudp-zivpn() {
  echo -e "${CYAN}Restarting ZIVPN...${RESET}"
  # Your restart logic here
  sleep 1
}

# Main menu loop
while true; do
  clear && printf '\e[3J'
  echo -e "${MAGENTA}[${CYAN}-${MAGENTA}]${CYAN} ────────────── ✦ ZIVPN ✦ ─────────────── ${MAGENTA}[${CYAN}-${MAGENTA}]"
  echo -e "${YELLOW}        ⚙️  ${BLUE}ZIVPN MANAGER by TRONIC-B-21 ⚙️"
  echo -e "${CYAN} › ${WHITE}Linux Dist: ${GREEN}$distribution"
  echo -e "${CYAN} › ${WHITE}IP Address: ${GREEN}$IP"
  echo -e "${CYAN} › ${WHITE}Network:    ${GREEN}$Network"
  echo -e "${CYAN} › ${WHITE}Running:    ${GREEN}$ports"
  echo -e "${MAGENTA}[${CYAN}-${MAGENTA}]${CYAN} ────────────────────────────────────────────── ${MAGENTA}[${CYAN}-${MAGENTA}]"
  echo -e "${YELLOW}[${GREEN}1${YELLOW}] ${WHITE}Install ${CYAN}ZIVPN V1 (Port 5666) ${MAGENTA}[Recommended]"
  echo -e "${YELLOW}[${GREEN}2${YELLOW}] ${WHITE}Install ${CYAN}ZIVPN V2 AMD (Port 5667) ${MAGENTA}[Recommended]"
  echo -e "${YELLOW}[${GREEN}3${YELLOW}] ${WHITE}Install ${CYAN}ZIVPN V2 ARM (Port 5667)"
  echo -e "${YELLOW}[${GREEN}4${YELLOW}] ${WHITE}Uninstall ${RED}ZIVPN"
  echo -e "${YELLOW}[${GREEN}5${YELLOW}] ${WHITE}Start ${GREEN}ZIVPN"
  echo -e "${YELLOW}[${GREEN}6${YELLOW}] ${WHITE}Stop ${RED}ZIVPN"
  echo -e "${YELLOW}[${GREEN}7${YELLOW}] ${WHITE}Restart ${CYAN}ZIVPN"
  echo -e "${YELLOW}[${GREEN}0${YELLOW}] ${WHITE}Exit"
  echo -e "${MAGENTA}[${CYAN}-${MAGENTA}]${CYAN} ────────────────────────────────────────────── ${MAGENTA}[${CYAN}-${MAGENTA}]"

  echo -e "\n${BLUE}CHOOSE AN OPTION:${RESET}"
  read option
  tput cuu1 && tput dl1

  case $option in
    1 | 01 ) installv1 ;;
    2 | 02 ) installv2 ;;
    3 | 03 ) installv3 ;;
    4 | 04 ) uninstall ;;
    5 | 05 ) startudp-zivpn ;;
    6 | 06 ) stopudp-zivpn ;;
    7 | 07 ) restartudp-zivpn ;;
    0 ) clear; exit ;;
    * ) echo -e "${RED}Invalid option! Please try again.${RESET}"; sleep 1 ;;
  esac
done
