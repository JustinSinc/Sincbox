#!/usr/bin/env bash

# exit if required variables aren't set
set -o nounset

# return the exit status of the final command before a failure
set -o pipefail

# check for root user
if [ "$EUID" -ne 0 ]
  then echo "Please run as root."
  exit 1
fi

# wireguard interface name
wgdev="wg0"

# wan interface name
wandev="ens3"

# ipv4 address
declare -a addrv4=(
        "10.25.0.1/24"
)

# ipv4 subnet
declare -a netv4=(
        "10.25.0.0/24"
        "192.168.1.0/24"
        "10.100.0.0/24"
        "10.100.1.0/24"
        "10.100.2.0/24"
        "10.100.3.0/24"
        "10.100.4.0/24"
)

# ipv6 address
declare -a addrv6=(
        "fde9:1d0f:2932:3336::1/64"
)

# iptables command to run pre/post
firewall() {
        :
}

# expect one argument
if [ "$#" -ne 1 ]; then
        echo -e "\nUsage: wireguard <up|down>\n";
        exit 1;
fi

# create the wireguard tunnel
if [ "$1" == "up" ]; then
        ip link add "$wgdev" type wireguard
        wg setconf "$wgdev" /etc/wireguard/"$wgdev".conf

        # add ip addresses
        for addressv4 in "${addrv4[@]}"; do
                ip -4 address add "$addressv4" dev "$wgdev"
        done

        for addressv6 in "${addrv6[@]}"; do
                ip -6 address add "$addressv6" dev "$wgdev"
        done

        # set link to up
        ip link set mtu 1420 up dev "$wgdev"

        # add routes
        for subnetv4 in "${netv4[@]}"; do
                ip -4 route add "$subnetv4" dev "$wgdev"
        done

        # add firewall rules
        firewall -A
# destroy the wireguard tunnel
elif [ "$1" == "down" ]; then
        # break down wireguard interface
        ip link delete dev "$wgdev"
        firewall -D
# exit with error
else
        echo -e "\nUsage: wireguard <up|down>\n";
        exit 1;
fi
