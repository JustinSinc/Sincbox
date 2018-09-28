#!/bin/vbash

if [ "$#" -lt 5 ]; then
        echo "Usage: nat-forward <internal ip> <external port> <internal port> <tcp|udp> <desc>"
        exit
fi

next_rule="$(echo $(($(grep "rule" /config/config.boot | cut -d" " -f10 | sort -n | tail -n1) + 10 )))"

/bin/vbash << EOF
source /opt/vyatta/etc/functions/script-template
configure
set firewall name STATEFUL rule "$next_rule" description "$5"
set firewall name STATEFUL rule "$next_rule" action 'accept'
set firewall name STATEFUL rule "$next_rule" destination address "$1"
set firewall name STATEFUL rule "$next_rule" destination port "$3"
set firewall name STATEFUL rule "$next_rule" protocol "$4"
set nat destination rule "$next_rule" description "$5"
set nat destination rule "$next_rule" destination port "$2"
set nat destination rule "$next_rule" inbound-interface 'eth1'
set nat destination rule "$next_rule" protocol "$4"
set nat destination rule "$next_rule" translation address "$1"
set nat destination rule "$next_rule" translation port "$3"
commit
save
EOF

echo -e "\nForwarded port "$4"/"$2" to port "$4"/"$3" on host "$1".\n"
