#!/bin/zsh

INTFW="pnd-intfw"
MAINFW="pnd-mainfw"

[[ `sudo docker network ls | grep -E "\snetkit_0_DMZ\s"` =~ "^\w*" ]] && DMZ="br-$MATCH"
VBoxManage modifyvm $MAINFW --bridgeadapter2 "$DMZ"
echo -e "DMZ:\t\t$DMZ"

if ! [[ `sudo ip link show br-firewalls 2> /dev/null` ]]; then
    sudo brctl addbr br-firewalls
    sudo ip link set br-firewalls up
fi
VBoxManage modifyvm $INTFW --bridgeadapter1 "br-firewalls"
VBoxManage modifyvm $MAINFW --bridgeadapter3 "br-firewalls"
echo -e "Firewalls:\tbr-firewalls"

[[ `sudo docker network ls | grep -E "\snetkit_0_server\s"` =~ "^\w*" ]] && SERVER="br-$MATCH"
VBoxManage modifyvm $INTFW --bridgeadapter2 "$SERVER"
echo -e "Server:\t\t$SERVER"

[[ `sudo docker network ls | grep -E "\snetkit_0_client\s"` =~ "^\w*" ]] && CLIENT="br-$MATCH"
sudo ip route del 100.64.0.0/16 &> /dev/null
sudo ip address flush dev $CLIENT
sudo ip address add 100.64.2.5/24 dev $CLIENT
sudo ip route add 100.64.0.0/16 via 100.64.2.1
VBoxManage modifyvm $INTFW --bridgeadapter3 $CLIENT
echo -e "Client:\t\t$CLIENT"

VBoxManage startvm "$INTFW"
VBoxManage startvm "$MAINFW"
