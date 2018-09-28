#!/bin/vbash

if [ "$#" -lt 4 ]; then
        echo "Usage: nat-create <internal ip> <hostname> <download bandwidth in mbits> <upload bandwidth in mbits>"
        exit
fi

next_rule="$(echo $(($(grep "rule" /config/config.boot | cut -d" " -f10 | sort -n | tail -n1) + 10 )))"
next_port="$(echo $(($(grep "port " /config/config.boot | sed 's/^ *//g' | sort -n | tail -n1 | cut -d" " -f2) + 1)))"

/bin/vbash << EOF
source /opt/vyatta/etc/functions/script-template
configure
set firewall name STATEFUL rule "$next_rule" description "$2"-SSH
set firewall name STATEFUL rule "$next_rule" action 'accept'
set firewall name STATEFUL rule "$next_rule" destination address "$1"
set firewall name STATEFUL rule "$next_rule" destination port "22"
set firewall name STATEFUL rule "$next_rule" protocol "tcp"
set nat destination rule "$next_rule" description "$2"
set nat destination rule "$next_rule" destination port "$next_port"
set nat destination rule "$next_rule" inbound-interface 'eth1'
set nat destination rule "$next_rule" protocol "tcp"
set nat destination rule "$next_rule" translation address "$1"
set nat destination rule "$next_rule" translation port "22"
set traffic-policy shaper SHAPER_DOWNLOAD class "$next_rule" bandwidth "$3"mbit
set traffic-policy shaper SHAPER_DOWNLOAD class "$next_rule" description "$2"-DOWNLOAD
set traffic-policy shaper SHAPER_DOWNLOAD class "$next_rule" match "$2" ip destination address "$1"/32
set traffic-policy shaper SHAPER_UPLOAD class "$next_rule" bandwidth "$4"mbit
set traffic-policy shaper SHAPER_UPLOAD class "$next_rule" description "$2"-UPLOAD
set traffic-policy shaper SHAPER_UPLOAD class "$next_rule" match "$2" ip source address "$1"/32
commit
save
EOF

echo -e "\nForwarded port "$next_port" to SSH for host "$1" and restricted bandwidth to "$3"mbps by "$4"mbps.\n"
