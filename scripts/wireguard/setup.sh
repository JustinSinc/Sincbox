#!/usr/bin/env bash
## script to set up a basic wireguard server
# must be run as root or with sudo

## Pre-requisites: ##
# install wireguard according to the instructions available at
# https://www.wireguard.com/install/

# fail in a sane manner
set -euo pipefail

# error out if the wireguard kernel module doesn't exist
if $(lsmod | grep wireguard 2>&1 >/dev/null); then
	return
else
	echo -e "\nPlease install the Wireguard kernel module by following the instructions"
	echo -e "available at https://www.wireguard.com/install/ before running this script\n"
	exit 1
fi

# set wan interface name
wan_interface="eth0"

# set wireguard tunnel interface name
tun_interface="wg0"

# set wireguard port
port="51820"

# set the private subnets to be used
subnetv4="10.0.0"
maskv4="24"
subnetv6="fdab:1a11:7de6:5b40"
maskv6="64"

# generate keys for wireguard server
umask 077
wg genkey | tee /etc/wireguard/privatekey | wg pubkey | tee /etc/wireguard/publickey

# store the private key in $privatekey for use in the config file
privatekey="$(cat /etc/wireguard/privatekey)"

# generate wireguard config file
cat <<EOL >/etc/wireguard/"$tun_interface".conf
[Interface]
PrivateKey = $privatekey
Address = $subnetv4.1/$maskv4, $subnetv6::1/$maskv6
ListenPort = $port
PostUp = iptables -A FORWARD -i $tun_interface -j ACCEPT; iptables -t nat -A POSTROUTING -o $wan_interface -j MASQUERADE; ip6tables -A FORWARD -i $tun_interface -j ACCEPT; ip6tables -t nat -A POSTROUTING -o $wan_interface -j MASQUERADE
PostDown = iptables -D FORWARD -i $tun_interface -j ACCEPT; iptables -t nat -D POSTROUTING -o $wan_interface -j MASQUERADE; ip6tables -D FORWARD -i $tun_interface -j ACCEPT; ip6tables -t nat -D POSTROUTING -o $wan_interface -j MASQUERADE
EOL

# start wireguard
wg-quick up "$tun_interface"

# restart wireguard on boot
systemctl enable wg-quick@"$tun_interface"
