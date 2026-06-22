
#!/bin/bash


rawtarget=$(xclip -o)

ip=$rawtarget

key=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 32)

/usr/local/mgr5/sbin/mgrctl -m ispmgr session.newkey username=root key=$key

url="https://$ip:1500/ispmgr?func=auth&username=root&key=$key&checkcookie=noht"
echo $url
