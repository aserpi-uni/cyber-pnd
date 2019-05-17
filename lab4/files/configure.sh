#!/bin/zsh

[[ `docker network ls | grep -E "\snetkit_0_DMZ\s"` =~ "^\w*" ]] && echo -e "DMZ:\t\tbr-$MATCH"
if ! [[ `ip link show br-firewalls 2> /dev/null` ]]; then
    brctl addbr br-firewalls
    ip link set br-firewalls up
fi
echo -e "Firewalls:\tbr-firewalls"

[[ `sudo docker network ls | grep -E "\snetkit_0_server\s"` =~ "^\w*" ]] && echo -e "Server:\t\tbr-$MATCH"

[[ `sudo docker network ls | grep -E "\snetkit_0_client\s"` =~ "^\w*" ]] && CLIENT="br-$MATCH"
ip route del 100.64.0.0/16 &> /dev/null
ip address flush dev $CLIENT
ip address add 100.64.2.5/24 dev $CLIENT
ip route add 100.64.0.0/16 via 100.64.2.1
echo -e "Client:\t\t$CLIENT"
