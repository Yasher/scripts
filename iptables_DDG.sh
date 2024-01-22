#!/bin/bash

list_ip="77.220.207.0/24
45.10.240.0/24
45.10.241.0/24
45.10.242.0/24
186.2.160.0/24
186.2.164.0/24
186.2.167.0/24
186.2.168.0/24
185.178.209.197/32
190.115.30.44/32
188.120.252.0/24
172.16.0.0/12"


for line in $list_ip; do
    iptables -I INPUT -p tcp --dport 80 -s $line -j ACCEPT && iptables -I INPUT -p tcp --dport 443 -s $line -j ACCEPT
done

iptables -A INPUT -p tcp --dport 80 -j DROP
iptables -A INPUT -p tcp --dport 443 -j DROP
