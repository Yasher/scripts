#!/bin/bash
#rm -f $0
#export LANG=EN

kern=$(uname -s)
case "${kern}" in
	Linux)
		if [ -f /etc/redhat-release ]; then
			#RELEASE=$(cat /etc/redhat-release | awk 'NR == 1 {print $1" "$3" "$4}')
			RELEASE=$(cat /etc/redhat-release|sed 's/Linux//'|awk '{print $1,$3}' |awk -F "." '{print $1}')
		elif [ -f /etc/centos-release ]; then
			#RELEASE=$(cat /etc/centos-release | awk 'NR == 1 {print $1" "$4}')
			RELEASE=$(cat /etc/centos-release|sed 's/Linux//'|awk '{print $1,$3}' |awk -F "." '{print $1}')
		#elif [ -f /etc/debian_version ]; then
		#	RELEASE=$(cat /etc/issue | awk 'NR == 1 {print $1" "$2" "$3}')
		elif [ -f /etc/os-release ]; then
			RELEASE=$((grep -w ID /etc/os-release| awk -F=  '{ print $2 }' && grep -w VERSION_ID /etc/os-release| awk -F\"  '{ print $2 }')| tr -s '\n' ' ')
		fi
		;;
	FreeBSD)
			OSTYPE=FREEBSD
esac

IPADDR=$(echo "${SSH_CONNECTION}" | awk '{print $3}')
if [ -z "${IPADDR}" ]; then
	if [ "${OSTYPE}" = "FREEBSD" ]; then
		IPADDR=$(ifconfig | awk '$1 ~ /inet/ && $2 !~ /127.0.0|::1|fe80:/ {print $2}' |cut -d/ -f1 | head -1)
	else    
		IPADDR=$(ip addr show | awk '$1 ~ /inet/ && $2 !~ /127.0.0|::1|fe80:/ {print $2}' |cut -d/ -f1 | head -1)
	fi
fi

SPACE_USE=$(df -h /|awk 'NR == 2 {print $3}')
SPACE_FREE=$(df -h /|awk 'NR == 2 {print $4}')

if [ -d /usr/local/mgr5/ ]; then
	PANEL="$(/usr/local/mgr5/bin/core ispmgr -F) $(/usr/local/mgr5/bin/core ispmgr -V | cut -d "-" -f 1)" 
elif [ -d /usr/local/ispmgr/ ]; then
	PANEL="ISPmanager 4"
elif [ -d /usr/local/vesta/ ]; then
	PANEL=VESTA
elif [ -d /usr/local/cpanel/ ]; then
	PANEL=CPANEL
elif [ -s /opt/webdir/bin/bx-sites ]; then
        PANEL="Bitrix Env"
elif [ -d /etc/nginx/bx ]; then
        PANEL="Bitrix GT Turbo"
else
	PANEL="No panel"
fi

OVZ=$(systemd-detect-virt 2> /dev/null) || if [ -e "/proc/vz/veinfo" ] && [ -e "/proc/vz/vestat" ] ; then OVZ=openvz; fi || OVZ=$(dmesg |grep -i "Hypervisor"|awk -F "Hypervisor detected: " '{print $2}')

echo "Сервер:"
echo $IPADDR
portnum=$(echo "${SSH_CONNECTION}" | awk '{print $4}');  if [ $portnum != '22' ]; then echo 'Портик : '$portnum ; fi
if [ $OVZ == 'none' ] ; then echo dedic; elif [ $OVZ != '' ] ; then echo $OVZ; else echo "Eto don't ovz, but luchshe utochni";fi
echo "$RELEASE; $PANEL; use $SPACE_USE; free $SPACE_FREE"
