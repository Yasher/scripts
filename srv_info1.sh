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
        PANEL=Bitrix
elif [ -d /etc/nginx/bx ]; then
        PANEL="Bitrix GT Turbo"
else
	PANEL="No panel"
fi

OVZ=$(systemd-detect-virt 2> /dev/null) || if [ -e "/proc/vz/veinfo" ] && [ -e "/proc/vz/vestat" ] ; then OVZ=openvz; fi || OVZ=$(dmesg |grep -i "Hypervisor"|awk -F "Hypervisor detected: " '{print $2}')

##if [ $(systemd-detect-virt) == 'openvz' ]; then 
##	OVZ=openvz
##elif [ -e "/proc/vz/veinfo" ] && [ -e "/proc/vz/vestat" ] ; then 
##	OVZ=;

##fi
#if [ -e "/proc/vz/veinfo" ] && [ -e "/proc/vz/vestat" ] ; then OVZ=ISOVZ; fi

#IP=$(ip route get 8.8.8.8 | grep src | awk '{print $NF}')

#echo "goplus$IPADDR; $RELEASE; $PANEL; занято: $SPACE_USE, свободно: $SPACE_FREE;"
echo "Сервер : $IPADDR"
portnum=$(echo "${SSH_CONNECTION}" | awk '{print $4}');  if [ $portnum != '22' ]; then echo 'Портик : '$portnum ; fi
#ovz_detect#if [ $OVZ == 'openvz' ] ; then echo $OVZ; fi 2> /dev/null
#if [ $OVZ != '' ] ; then echo $OVZ; elif [ $OVZ == 'none' ] ; then echo dedic; else echo 'non kvm or ovz'; fi 2> /dev/null
if [ $OVZ == 'none' ] ; then echo dedic; elif [ $OVZ != '' ] ; then echo $OVZ; else echo "Eto don't ovz, but luchshe utochni";fi
php -v|grep PHP|grep -v Copyright|awk '{print $1,$2,"native"}'
find /opt/php*/bin/php |while read line; do $line -v|grep PHP|grep -v Copyright|awk '{print $1,$2}'; done
echo "$RELEASE; $PANEL; use $SPACE_USE; free $SPACE_FREE"
#php -v|grep PHP|grep -v Copyright|awk '{print $1,$2,"native"}'
#find /opt/php*/bin/php |while read line; do $line -v|grep PHP|grep -v Copyright|awk '{print $1,$2}'; done
#echo
#echo "$OVZ+777$RELEASE; $PANEL; use: $SPACE_USE; free: $SPACE_FREE;777"
