#!/bin/vbash

if [ "$#" -lt 1 ]; then
        echo "Usage: nat-delete <rule>"
        exit
fi

/bin/vbash << EOF
source /opt/vyatta/etc/functions/script-template
configure
delete firewall name STATEFUL rule "$1"
delete nat destination rule "$1"
delete traffic-policy shaper SHAPER_DOWNLOAD class "$1"
delete traffic-policy shaper SHAPER_UPLOAD class "$1"
commit
save
EOF

echo -e "\nRemoved host mapping rule "$1".\n"
