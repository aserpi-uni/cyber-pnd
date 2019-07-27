## Logging

-I FORWARD -j LOG --log-level 4 --log-prefix "netfilter forward drop: "
-I INPUT -j LOG --log-level 4 --log-prefix "netfilter input drop: "
-I OUTPUT -j LOG --log-level 3 --log-prefix "netfilter output drop: "


## DMZ

# FTP server
-t nat -I PREROUTING -i eth0 -p tcp -m multiport --dports $FTP_PORTS -j DNAT --to-destination $FTP_ADDR
-I FORWARD -d $FTP_ADDR -p tcp -m multiport --dports $FTP_PORTS -j ACCEPT
-I FORWARD -s $FTP_ADDR -p tcp -m multiport --sports $FTP_PORTS -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Web server
-I FORWARD -i eth0 -d $WEB_ADDR -p tcp --dport $WEB_PORT -j ACCEPT
-I FORWARD -o eth0 -s $WEB_ADDR -p tcp --sport $WEB_PORT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
-t nat -I PREROUTING -i eth0 -p tcp --dport $WEB_PORT -j DNAT --to-destination $WEB_ADDR


## Internal network

# DNS server
-I FORWARD -d $DNS_ADDR -s $DMZ_NET -p udp --dport $DNS_PORT -j ACCEPT
-I FORWARD -s $DNS_ADDR -p udp --sport $DNS_PORT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
-I FORWARD -d $DNS_ADDR -s $DMZ_NET -p tcp --dport $DNS_PORT -j ACCEPT
-I FORWARD -s $DNS_ADDR -p tcp --sport $DNS_PORT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Log server
-I FORWARD -d $LOG_ADDR -s $NET -p udp --dport $LOG_PORT -j ACCEPT
-I OUTPUT -d $LOG_ADDR -p udp --dport $LOG_PORT -j ACCEPT


## SSH

-I FORWARD -s $CLIENT_NET -p tcp --dport $SSH_PORT -j ACCEPT
-I FORWARD -d $CLIENT_NET -p tcp --sport $SSH_PORT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
-I INPUT -s $CLIENT_NET -p tcp --dport $SSH_PORT -j ACCEPT
-I OUTPUT -d $CLIENT_NET -p tcp --sport $SSH_PORT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT


## Spoofing

-N ANTISPOOFING
-P ANTISPOOFING DROP
-I ANTISPOOFING -j LOG --log-level 3 --log-prefix "netfilter anti-spoofing: "

-I FORWARD -i eth0 -s $NET -j ANTISPOOFING
-I INPUT -i eth0 -s $NET -j ANTISPOOFING
-I FORWARD -i eth1 ! -s $DMZ_NET -j ANTISPOOFING
-I INPUT -i eth1 ! -s $DMZ_NET -j ANTISPOOFING
-I FORWARD -i eth2 -s $DMZ_NET -j ANTISPOOFING
-I INPUT -i eth2 -s $DMZ_NET -j ANTISPOOFING
-I FORWARD -i eth2 -s $MAINFW_ADDR -j ANTISPOOFING
-I INPUT -i eth2 - $MAINFW_ADDR -j ANTISPOOFING
