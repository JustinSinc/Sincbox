#!/usr/bin/env bash
## script to generate client wireguard configs as qr codes
# requires package `qrencode` from the repos

# fail in a sane manner
set -euo pipefail

# set the subnets to be used
subnetv4="172.0.0"
subnetv6="fddf:562f:958e:5a4d"

# set wireguard server public ip address
server="<public ip>"

# set wireguard port
port="51820"

# set wireguard tunnel interface name
interface="wg0"

# make sure the correct number of arguments are passed; if not, output syntax and exit
if [ "$#" -ne 2 ]; then
        echo -e "\nUsage: wireguard-certgen <client> <last octet of ip address>\n"
        exit 1
fi

# assign arguments to variables
client="$1"
ipaddr="$2"

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
wg-quick down wg0
wg-quick up wg0

# generate client configuration
cat <<EOL | tee "$certdir"/client.conf
[Interface]
PrivateKey = $clientprivatekey
Address = $subnetv4.$ipaddr/32, $subnetv6::$ipaddr/128
DNS = 1.1.1.1, 2606:4700:4700::1111

[Peer]
PublicKey = $serverpublickey
PresharedKey = $presharedkey
Endpoint = $server:$port
AllowedIPs = 0.0.0.0/0, ::/0
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
