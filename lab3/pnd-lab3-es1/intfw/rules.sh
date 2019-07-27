#!/bin/bash

CLIENT_NET="100.64.2.0/24"
DMZ_NET="100.64.6.0/24"
DNS_ADDR="100.64.1.2"
DNS_PORT="53"
INTFW_ADDR="100.64.254.2"
LOG_ADDR="100.64.1.3"
LOG_PORT="514"
NET="100.64.0.0/16"
SERVER_NET="100.64.1.0/24"


## Default policies

iptables -P FORWARD DROP
iptables -P INPUT DROP
iptables -P OUTPUT DROP


## Logging

iptables -I FORWARD -j LOG --log-level 4 --log-prefix "netfilter forward drop: "
iptables -I INPUT -j LOG --log-level 4 --log-prefix "netfilter input drop: "
iptables -I OUTPUT -j LOG --log-level 5 --log-prefix "netfilter output drop: "


## Internal network

# DNS server
iptables -I FORWARD -d $DNS_ADDR -s $CLIENT_NET -p udp --dport $DNS_PORT -j ACCEPT
iptables -I FORWARD -d $DNS_ADDR -s $DMZ_NET -p udp --dport $DNS_PORT -j ACCEPT
iptables -I FORWARD -s $DNS_ADDR -p udp --sport $DNS_PORT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -I FORWARD -d $DNS_ADDR -s $CLIENT_NET -p tcp --dport $DNS_PORT -j ACCEPT
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

iptables -I FORWARD -i eth0 -s $SERVER_NET,$CLIENT_NET,$INTFW_ADDR -j ANTISPOOFING
iptables -I INPUT -i eth0 -s $SERVER_NET,$CLIENT_NET -j ANTISPOOFING
iptables -I FORWARD -i eth1 ! -s $SERVER_NET -j ANTISPOOFING
iptables -I INPUT -i eth1 ! -s $SERVER_NET -j ANTISPOOFING
iptables -I FORWARD -i eth2 ! -s $CLIENT_NET -j ANTISPOOFING
iptables -I INPUT -i eth2 ! -s $CLIENT_NET -j ANTISPOOFING
