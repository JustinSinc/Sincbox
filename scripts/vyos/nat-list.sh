#!/bin/vbash

if [ "$#" -gt 0 ]; then
        echo "Usage: nat-list"
        exit
fi

source /opt/vyatta/etc/functions/script-template
echo -e "\nRule | Description\n------------------"
run show configuration commands | grep "WAN_IN" | grep "rule" | grep "description" | awk '{ print $6,$8 }'
echo -e "\n"
exit
