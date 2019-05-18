#!/usr/bin/env bash
## script to generate client wireguard configs as qr codes
# requires package `qrencode` from the repos

# fail in a sane manner
set -euo pipefail

# set the private subnets to be used
subnetv4="10.0.0"
maskv4="24"
subnetv6="fdab:1a11:7de6:5b40"
maskv6="64"

# set wireguard server public ip address and listen port
server="<server public ip>"
port="51820"

# set wireguard tunnel interface name
interface="wg0"

# make sure the correct number of arguments are passed; if not, output syntax and exit
if [ "$#" -ne 3 ]; then
        echo -e "\nUsage: wireguard-certgen <access|site> <client name> <last octet of ip address>\n"
        exit 1
fi

# set the default routes according to the specified vpn type
# `access` generates a remote access config (all traffic is routed over tunnel)
# `site` generates a site-to-site config (only vpn subnets are routed over tunnel)
if [ "$1" = "access" ]; then
        routev4="0.0.0.0/0"
        routev6="::/0"
elif [ "$1" = "site" ]; then
        routev4="$subnetv4.0/$maskv4"
        routev6="$subnetv6::/$maskv6"
else
        echo "Connection type must be either access or site."
        exit 1
fi

# assign arguments to variables
client="$2"
ipaddr="$3"

# set imagebuilder directory
certdir="$HOME/wireguard/$client"

# set logfile location
logfile="$certdir/build.log"

# delete any old builds if they exist
if [ -d "$certdir" ]; then
        echo -e "\nRemoving old wireguard keys..." >> "$logfile" 2>&1
        rm -rf "$certdir"
fi

# create base directory for account
mkdir -p "$certdir"

# display log location
echo -e "\nLogging all build output to $logfile\n"

# prepend timestamp to logfile
echo -e "\nBuild began at $(date +%Y/%m/%d-%H:%M)." >> "$logfile" 2>&1

# wrap the script into a function for logging purposes
{

# generate public and private keys for the client
umask 077
wg genkey | tee "$certdir"/privatekey | wg pubkey > "$certdir"/publickey

# generate preshared key for the client
presharedkey="$(wg genpsk)"

# set variables for keys
clientpublickey="$(cat $certdir/publickey)"
clientprivatekey="$(cat $certdir/privatekey)"
serverpublickey="$(sudo cat /etc/wireguard/publickey)"

# add peer to wireguard server configuration
cat <<EOL | sudo tee -a /etc/wireguard/"$interface".conf

[Peer]
PublicKey = $clientpublickey
PresharedKey = $presharedkey
AllowedIPs = $subnetv4.$ipaddr/32, $subnetv6::$ipaddr/128
EOL

# reload wireguard config
wg-quick down "$interface"
wg-quick up "$interface"

# generate client configuration
cat <<EOL | tee "$certdir"/client.conf
[Interface]
PrivateKey = $clientprivatekey
Address = $subnetv4.$ipaddr/32, $subnetv6::$ipaddr/128
DNS = $subnetv4.1, $subnetv6::1

[Peer]
PublicKey = $serverpublickey
PresharedKey = $presharedkey
Endpoint = $server:$port
AllowedIPs = $routev4, $routev6
PersistentKeepalive = 25
EOL

# prepend a space before the qr code for easier scanning
echo -e "\n"

# generate qr encoding of client configuration
qrencode -t ansiutf8 < "$certdir"/client.conf | tee "$certdir"/qrcode.conf

# end function
} 2>&1 | tee -a "$logfile" >/dev/null

# append timestamp to logfile
echo -e "\nFinished generating Wireguard certs.\n\nCertificate generation finished at $(date +%Y/%m/%d-%H:%M).\n" >> "$logfile"

# display client config as qr code
echo -e "\n$(cat "$certdir"/qrcode.conf)\n"
