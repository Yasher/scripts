
#!/bin/bash


ip=$(ss -pant| grep ihttp| awk '{printf $4}'| awk -F : '{printf $1}')

port=$(ss -pant| grep ihttp| awk '{printf $4}'| awk -F : '{printf $2}')

key=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 32)

/usr/local/mgr5/sbin/mgrctl -m ispmgr session.newkey username=root key=$key

url="https://$ip:$port/ispmgr?func=auth&username=root&key=$key&checkcookie=noht"
echo $url
