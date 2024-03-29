#!/bin/bash

CLIENT_NET="100.64.2.0/24"
DMZ_NET="100.64.6.0/24"
DNS_ADDR="100.64.1.2"
DNS_PORT="53"
FTP_ADDR="100.64.6.3"
FTP_PORTS="20,21"
LOG_ADDR="100.64.1.3"
LOG_PORT="514"
MAINFW_ADDR="100.64.254.1"
NET="100.64.0.0/16"
SSH_PORT="22"
WEB_ADDR="100.64.6.2"
WEB_PORT="80"


## Default policies

iptables -P FORWARD DROP
iptables -P INPUT DROP
iptables -P OUTPUT DROP


## Logging

iptables -I FORWARD -j LOG --log-level 4 --log-prefix "netfilter forward drop: "
iptables -I INPUT -j LOG --log-level 4 --log-prefix "netfilter input drop: "
iptables -I OUTPUT -j LOG --log-level 3 --log-prefix "netfilter output drop: "


## DMZ

# FTP server
iptables -t nat -I PREROUTING -i eth0 -p tcp -m multiport --dports $FTP_PORTS -j DNAT --to-destination $FTP_ADDR
iptables -I FORWARD -d $FTP_ADDR -p tcp -m multiport --dports $FTP_PORTS -j ACCEPT
iptables -I FORWARD -s $FTP_ADDR -p tcp -m multiport --sports $FTP_PORTS -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Web server
iptables -I FORWARD -i eth0 -d $WEB_ADDR -p tcp --dport $WEB_PORT -j ACCEPT
iptables -I FORWARD -o eth0 -s $WEB_ADDR -p tcp --sport $WEB_PORT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -t nat -I PREROUTING -i eth0 -p tcp --dport $WEB_PORT -j DNAT --to-destination $WEB_ADDR


## Internal network

# DNS server
iptables -I FORWARD -d $DNS_ADDR -s $DMZ_NET -p udp --dport $DNS_PORT -j ACCEPT
iptables -I FORWARD -s $DNS_ADDR -p udp --sport $DNS_PORT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -I FORWARD -d $DNS_ADDR -s $DMZ_NET -p tcp --dport $DNS_PORT -j ACCEPT
iptables -I FORWARD -s $DNS_ADDR -p tcp --sport $DNS_PORT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Log server
iptables -I FORWARD -d $LOG_ADDR -s $NET -p udp --dport $LOG_PORT -j ACCEPT
iptables -I OUTPUT -d $LOG_ADDR -p udp --dport $LOG_PORT -j ACCEPT


## SSH

iptables -I FORWARD -s $CLIENT_NET -d $NET -p tcp --dport $SSH_PORT -j ACCEPT
iptables -I FORWARD -d $CLIENT_NET -s $NET -p tcp --sport $SSH_PORT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -I INPUT -s $CLIENT_NET -p tcp --dport $SSH_PORT -j ACCEPT
iptables -I OUTPUT -d $CLIENT_NET -p tcp --sport $SSH_PORT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT


## Spoofing

iptables -N ANTISPOOFING
iptables -P ANTISPOOFING DROP
iptables -I ANTISPOOFING -j LOG --log-level 3 --log-prefix "netfilter anti-spoofing: "

iptables -I FORWARD -i eth0 -s $NET -j ANTISPOOFING
iptables -I INPUT -i eth0 -s $NET -j ANTISPOOFING
iptables -I FORWARD -i eth1 ! -s $DMZ_NET -j ANTISPOOFING
iptables -I INPUT -i eth1 ! -s $DMZ_NET -j ANTISPOOFING
iptables -I FORWARD -i eth2 -s $DMZ_NET -j ANTISPOOFING
iptables -I INPUT -i eth2 -s $DMZ_NET -j ANTISPOOFING
iptables -I FORWARD -i eth2 -s $MAINFW_ADDR -j ANTISPOOFING
iptables -I INPUT -i eth2 - $MAINFW_ADDR -j ANTISPOOFING
