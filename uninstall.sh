#!/bin/bash
# - ZiVPN Remover -
clear
echo -e "Uninstalling ZiVPN ..."
systemctl stop udp-zivpn.service 1> /dev/null 2> /dev/null
systemctl stop udp-zivpn_backfill.service 1> /dev/null 2> /dev/null
systemctl disable udp-zivpn.service 1> /dev/null 2> /dev/null
systemctl disable udp-zivpn_backfill.service 1> /dev/null 2> /dev/null
rm /etc/systemd/system/udp-zivpn.service 1> /dev/null 2> /dev/null
rm /etc/systemd/system/udp-zivpn_backfill.service 1> /dev/null 2> /dev/null
killall udp-zivpn 1> /dev/null 2> /dev/null
rm -rf /etc/udp-zivpn 1> /dev/null 2> /dev/null
rm /usr/local/bin/udp-zivpn 1> /dev/null 2> /dev/null
if pgrep "udp-zivpn" >/dev/null; then
  echo -e "Server Running"
else
  echo -e "Server Stopped"
fi
file="/usr/local/bin/udp-zivpn" 1> /dev/null 2> /dev/null
if [ -e "$file" ] 1> /dev/null 2> /dev/null; then
  echo -e "Files still remaining, try again"
else
  echo -e "Successfully Removed"
fi
echo "Cleaning Cache & Swap"
echo 3 > /proc/sys/vm/drop_caches
sysctl -w vm.drop_caches=3
swapoff -a && swapon -a
echo -e "Done."
