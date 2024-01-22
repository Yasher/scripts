#!/bin/bash

#подложить список ip в файл list_ip
file_path=./list_ip

for line in $(cat "$file_path"); do
    iptables -I INPUT -p tcp --dport 80 -s $line -j ACCEPT
done
