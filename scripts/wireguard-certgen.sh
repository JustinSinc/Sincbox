#!/usr/bin/env bash
## script to generate client wireguard configs as qr codes

# fail in a sane manner
set -euo pipefail

# set the first three octets of the vpn subnet
subnet="172.21.0"

# set wireguard server public ip address
server="208.110.239.222"

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

# set variables for keys
clientpublickey="$(cat $certdir/publickey)"
clientprivatekey="$(cat $certdir/privatekey)"
serverpublickey="$(cat /etc/wireguard/publickey)"

# add peer to wireguard server configuration
cat <<EOL | sudo tee -a /etc/wireguard/"$interface".conf

[Peer]
PublicKey = $clientpublickey
AllowedIPs = $subnet.$ipaddr/32
EOL

# reload wireguard config
wg-quick down wg0
wg-quick up wg0

# generate client configuration
cat <<EOL | tee "$certdir"/client.conf
[Interface]
PrivateKey = $clientprivatekey
Address = $subnet.$ipaddr/32
DNS = $subnet.1

[Peer]
PublicKey = $serverpublickey
Endpoint = $server:51820
AllowedIPs = 0.0.0.0/0
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
