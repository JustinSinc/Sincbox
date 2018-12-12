#!/usr/bin/env bash
## script to set up a basic wireguard server

# add the wireguard repository
sudo add-apt-repository ppa:wireguard/wireguard

# update packages and install wireguard
sudo apt update && sudo apt install wireguard-dkms wireguard-tools

# generate keys for wireguard server
umask 077
wg genkey | sudo tee /etc/wireguard/privatekey | wg pubkey | sudo tee /etc/wireguard/publickey

# set wan interface name
wan_interface="eth0"

# set wireguard tunnel interface name
tun_interface="wg0"

# set the first three octets of the vpn subnet
subnet="172.21.0"

# set variables for keys
privatekey="$(cat etc/wireguard/privatekey)"

# generate wireguard config file
cat <<EOL >/etc/wireguard/"$tun_interface".conf
[Interface]
PrivateKey = $privatekey
Address = $subnet.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i $tun_interface -j ACCEPT; iptables -t nat -A POSTROUTING -o $wan_interface -j MASQUERADE
PostDown = iptables -D FORWARD -i $tun_interface -j ACCEPT; iptables -t nat -D POSTROUTING -o $wan_interface -j MASQUERADE
EOL

# start wireguard
wg-quick up "$tun_interface"

# restart wireguard on boot
systemctl enable wg-quick@"$tun_interface"
