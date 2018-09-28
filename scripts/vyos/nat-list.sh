#!/bin/vbash

if [ "$#" -gt 0 ]; then
        echo "Usage: nat-list"
        exit
fi

source /opt/vyatta/etc/functions/script-template
echo -e "\nRule | Description\n------------------"
run show configuration commands | grep "STATEFUL" | grep "description" | awk '{ print $6,$8 }'
echo -e "\n"
exit
