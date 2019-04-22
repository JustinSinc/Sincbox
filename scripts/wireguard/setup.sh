#!/usr/bin/env bash
## script to set up a basic wireguard server
# must be run as root or with sudo

# set wan interface name
wan_interface="eth0"

# set wireguard tunnel interface name
tun_interface="wg0"

# set wireguard port
port="51820"

# set the vpn subnets
subnetv4="172.0.0"
maskv4="/24"
subnetv6="fddf:562f:958e:5a4d"
maskv6="/64"

# install prerequisites
apt update && apt install software-properties-common

# add the wireguard repository
add-apt-repository ppa:wireguard/wireguard

# update packages and install wireguard
apt update && apt install wireguard wireguard-dkms wireguard-tools

# generate keys for wireguard server
umask 077
wg genkey | tee /etc/wireguard/privatekey | wg pubkey | tee /etc/wireguard/publickey

# store the private key in $privatekey for use in the config file
privatekey="$(cat /etc/wireguard/privatekey)"

# generate wireguard config file
cat <<EOL >/etc/wireguard/"$tun_interface".conf
[Interface]
PrivateKey = $privatekey
Address = $subnetv4.1$maskv4, $subnetv6::1$maskv6
ListenPort = $port
PostUp = iptables -A FORWARD -i $tun_interface -j ACCEPT; iptables -t nat -A POSTROUTING -o $wan_interface -j MASQUERADE; ip6tables -A FORWARD -i $tun_interface -j ACCEPT; ip6tables -t nat -A POSTROUTING -o $wan_interface -j MASQUERADE
PostDown = iptables -D FORWARD -i $tun_interface -j ACCEPT; iptables -t nat -D POSTROUTING -o $wan_interface -j MASQUERADE; ip6tables -D FORWARD -i $tun_interface -j ACCEPT; ip6tables -t nat -D POSTROUTING -o $wan_interface -j MASQUERADE
EOL

# start wireguard
wg-quick up "$tun_interface"

# restart wireguard on boot
systemctl enable wg-quick@"$tun_interface"
