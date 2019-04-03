#!/bin/bash

[[ `sudo docker network ls | grep -E [[:space:]]netkit_0_DMZ` =~ ^[[:alnum:]]* ]] && echo -e "DMZ:\t\tbr-${BASH_REMATCH[0]}"

if [[ `ip link show br-firewalls` = 'Device "br-firewalls" does not exist.' ]]; then
    brctl addbr br-firewalls
    ip link set br-firewalls up
fi
echo -e "Firewalls:\tbr-firewalls"

[[ `sudo docker network ls | grep -E [[:space:]]netkit_0_server` =~ ^[[:alnum:]]* ]] && echo -e "Server:\t\tbr-${BASH_REMATCH[0]}"

[[ `sudo docker network ls | grep -E [[:space:]]netkit_0_client` =~ ^[[:alnum:]]* ]] && CLIENT="br-${BASH_REMATCH[0]}"
ip route del 100.64.0.0/16 &> /dev/null
ip address flush dev $CLIENT
ip address add 100.64.2.5/24 dev $CLIENT
ip route add 100.64.0.0/16 via 100.64.2.1
echo -e "Client:\t\t$CLIENT"

