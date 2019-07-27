#!/bin/bash

CLIENT_NET="100.64.2.0/24"
DMZ_NET="100.64.6.0/24"
DNS_ADDR="100.64.1.2"
DNS_PORT="53"


## Default policies

iptables -P FORWARD DROP
iptables -P INPUT DROP
iptables -P OUTPUT DROP


## Logging

iptables -I FORWARD -j LOG --log-level 4 --log-prefix "netfilter forward drop: "
iptables -I INPUT -j LOG --log-level 4 --log-prefix "netfilter input drop: "
iptables -I OUTPUT -j LOG --log-level 5 --log-prefix "netfilter output drop: "


## Internal network

# Client network
iptables -I FORWARD -s 100.64.2.0/24 ! -d 100.64.0.0/16 -j ACCEPT
iptables -I FORWARD -d 100.64.2.0/24 ! -s 100.64.0.0/16 -m state --state ESTABLISHED,RELATED -j ACCEPT

# DNS server
iptables -I FORWARD -d $DNS_ADDR -s $CLIENT_NET -p udp --dport $DNS_PORT -j ACCEPT
iptables -I FORWARD -d $DNS_ADDR -s $DMZ_NET -p udp --dport $DNS_PORT -j ACCEPT
iptables -I FORWARD -s $DNS_ADDR -p udp --sport $DNS_PORT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -I FORWARD -d $DNS_ADDR -s $CLIENT_NET -p tcp --dport $DNS_PORT -j ACCEPT
iptables -I FORWARD -d $DNS_ADDR -s $DMZ_NET -p tcp --dport $DNS_PORT -j ACCEPT
iptables -I FORWARD -s $DNS_ADDR -p tcp --sport $DNS_PORT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Log server
iptables -I FORWARD -d 100.64.1.3 -s 100.64.0.0/16 -p udp --dport 514 -j ACCEPT
iptables -I OUTPUT -d 100.64.1.3 -p udp --dport 514 -j ACCEPT


## SSH

iptables -I FORWARD -s 100.64.2.0/24 -p tcp --dport 22 -j ACCEPT
iptables -I FORWARD -d 100.64.2.0/24 -p tcp --sport 22 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -I INPUT -s 100.64.2.0/24 -p tcp --dport 22 -j ACCEPT
iptables -I OUTPUT -d 100.64.2.0/24 -p tcp --sport 22 -m state --state ESTABLISHED,RELATED -j ACCEPT


## Spoofing

iptables -N ANTISPOOFING
iptables -P ANTISPOOFING DROP
iptables -I ANTISPOOFING -j LOG --log-level 3 --log-prefix "netfilter anti-spoofing: "

iptables -I FORWARD -i eth0 -s 100.64.1.0/24,100.64.2.0/24,100.64.254.2 -j ANTISPOOFING
iptables -I INPUT -i eth0 -s 100.64.1.0/24,100.64.2.0/24 -j ANTISPOOFING
iptables -I FORWARD -i eth1 ! -s 100.64.1.0/24 -j ANTISPOOFING
iptables -I INPUT -i eth1 ! -s 100.64.1.0/24 -j ANTISPOOFING
iptables -I FORWARD -i eth2 ! -s 100.64.2.0/24 -j ANTISPOOFING
iptables -I INPUT -i eth2 ! -s 100.64.2.0/24 -j ANTISPOOFING
