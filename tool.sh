#!/bin/bash

if [ -f /usr/local/mgr5/bin/core ]; then
    PANEL="panel "$(/usr/local/mgr5/bin/core -V)
fi

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

#echo $RELEASE


exec 2>/dev/null

DEF='\033[0;39m'       #  ${DEF}
DGRAY='\033[1;30m'     #  ${DGRAY}
LRED='\033[1;31m'       #  ${LRED}
LGREEN='\033[1;32m'     #  ${LGREEN}
LYELLOW='\033[1;33m'     #  ${LYELLOW}
LBLUE='\033[1;34m'     #  ${LBLUE}
LMAGENTA='\033[1;35m'   #  ${LMAGENTA}
LCYAN='\033[1;36m'     #  ${LCYAN}
WHITE='\033[1;37m'     #  ${WHITE}




echo -en "${LGREEN}\n${RELEASE} ${PANEL}\n${DEF}"
script[1]='backup'
script[2]='parse_log'
script[3]='ISP_MENU'
script[4]='BITRIX_MENU'
script[5]='add_move_key'
script[6]='srv_info'
#script[7]='tweaker_mgr5'
script[7]='strace'
script[8]='mysqltuner'
script[9]='others'


for index in ${!script[*]}
do
    printf "%4d: %s\n" $index ${script[$index]}
done


ISP_MENU() {
  MENU() {
    echo -ne "${LGREEN}\n ISP menu:\n${DEF}"
    script_isp[1]='Подложить ключ ISPmanager5'
    script_isp[2]='Составить hosts из webdomain'
    script_isp[3]='Обновить панел'
    script_isp[4]='Установить панель ISPmanager5'
    script_isp[5]='Получить список доменов'
    script_isp[6]='Chown на /var/www/$USER/data/www'
    script_isp[7]='Массовое диганье доменов'

    for index in ${!script_isp[*]}; do
      printf "%4d: %s\n" $index "${script_isp[$index]}"
    done
  }
 # while :
 # do
    MENU
    read -r -p "Choose: " payload
    case $payload in
      1)
        bash <(wget -q -O- saaa.tk/scripts/ispmgr_go.sh) ;;
      2)
        echo -ne "\n"
        echo "Перенос данных выполнен, проверить работу сайтов, не меняя записи ДНС, можно прописав на локальном ПК в файле hosts (C:\Windows\System32\drivers\etc\hosts) следующие данные:"
        # /usr/local/mgr5/sbin/mgrctl -m ispmgr webdomain | awk -F'ipaddr=|name=| ' '{print $NF, $2, "www." $2}'
        for i in `/usr/local/mgr5/sbin/mgrctl -m ispmgr webdomain | awk -F'ipaddr=|name=| ' '{print $NF"::"$2}'`; do idn=$(echo $i|awk -F'::' '{print $2}'|xargs python -c 'import sys;print (sys.argv[1].decode("utf-8").encode("idna"))'); echo "`echo $i | awk -F'::' '{print $1}'` $idn www.$idn"; done
        echo -ne "\n"
        echo "FirstVDS: Подробнее на нашем сайте - https://firstvds.ru/technology/check-after-transfer"
        echo -ne "ISPserver: Подробнее на нашем сайте - https://ispserver.ru/help/proverka-dostupnosti-sayta-posle-perenosa\n\n"
        echo "Если все корректно - смените ДНС записи на ip нового сервера, если не знаете как это сделать сообщите нам, поможем."
        echo
        echo
        ;;
      3)
       /usr/local/mgr5/bin/core -V; /usr/local/mgr5/bin/core ispmgr -V; cat  /usr/local/mgr5/etc/repo.version; /usr/local/mgr5/sbin/licctl info ispmgr|grep Latest
echo -e 'Latest-beta' $(curl http://cdn.ispsystem.com/repo.versions| tail -1)
printf "Обновляем панельку (y/n)?: ";
read STATE;

if ([ $STATE = "y" ] || [ $STATE = "yes" ])
    then
        /usr/local/mgr5/sbin/pkgupgrade.sh ispmanager-lite-common;
    else
        echo "Ну хер с тобой, потом обновим";
        exit 0;
fi
        ;;
      4)
        printf "Ставим панельку (y/n)?: ";
        read response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
            printf "Auto install ISPmanager beta (y/N)? ";
            read response
            if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
                wget https://notes.fvds.ru/share/install.5.sh && sh install.5.sh --silent --ignore-hostname --release beta ispmanager-lite
                echo -ne "${LGREEN}Done${DEF}\n"
            else
                wget https://notes.fvds.ru/share/install.5.sh && sh install.5.sh
                echo -ne "${LGREEN}Done${DEF}\n"
            fi
        else
          echo -ne "${LYELLOW}Cancel${DEF}\n"
        fi
        ;;
      5)
        echo -ne "\n"
        /usr/local/mgr5/sbin/mgrctl -m ispmgr webdomain | awk '{print $1}' | sed -s 's/name=//g'
        ;;
      6)
        read -r -p "Do you really want it? (y/N)?? " response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
            find /var/www/*/data/www/ -maxdepth 1 -type d | awk -F'/' '{print "chown -R "$4":"$4 " /var/www/"$4"/data/www/"}' | uniq | sh
            echo -ne "${LGREEN}Done${DEF}\n"
        else
            echo -ne "${LYELLOW}Cancel${DEF}\n"
        fi
        ;;
      7)
        echo -ne "\n"
        echo "Откуда дигаем? : ";
        echo "1: ns1.firstvds.ru"
        echo "2: ns1.ispvds.com"
        echo "3: 8.8.8.8"
        echo "4: 1.1.1.1"
        read digserver
        
        case $digserver in
          1)
            digserver='ns1.firstvds.ru'
            ;;
          2)
            digserver='ns1.ispvds.com'
            ;;
          3)
            digserver='8.8.8.8'
            ;;     
          4)
            digserver='1.1.1.1'
            ;;
          esac
        echo 
        /usr/local/mgr5/sbin/mgrctl -m ispmgr webdomain | awk '{print $1}' | sed -s 's/name=//g' |while read line ; do echo "###"; echo -n $line " "; dig $line +short @$digserver | tail -n 1  ; done
        echo
        echo "digserver=$digserver ; /usr/local/mgr5/sbin/mgrctl -m ispmgr webdomain | awk '{print \$1}' | sed -s 's/name=//g' |while read line ; do echo \"###\"; echo -n \$line \" \"; dig \$line +short @\$digserver | tail -n 1  ; done"
        ;;
      *)
        echo -ne "${LRED}Unknown choose${DEF}\n" ;;
    esac

#  done
  exit
}



BITRIX_MENU() {
  MENU() {
    echo -ne "${LGREEN}\n BITRIX menu:\n${DEF}"
    script_bitrix[1]='bitrix-GT-admin'
    script_bitrix[2]='bitrix-env-ftp'
    script_bitrix[3]='Скачать default конфиг bitrix gt'
    script_bitrix[4]='Скачать pusti.php'
    script_bitrix[5]='Скачать скрипты для wildcard LE'
    script_bitrix[6]='Скачать restore.php'
    script_bitrix[9]='DDoS смена ip'

    for index in ${!script_bitrix[*]}; do
      printf "%4d: %s\n" $index "${script_bitrix[$index]}"
    done
  }

 # while :
#  do
    MENU
    read -r -p "Choose: " payload
    case $payload in
      1)
        wget -O ./admin.sh https://gitlab.hoztnode.net/admins/scripts/raw/master/admin.sh;
        chmod +x ./admin.sh;
        ./admin.sh
        ;;
      2)
        bash <(wget -q -O- saaa.tk/scripts/bitrix-env-ftp.sh) ;;
      3)
        wget http://rep.fvds.ru/cms/bitrixinstaller.tgz
        echo -ne "${LGREEN}Done${DEF}\\n"
        ;;
      4)
        wget -q http://saaa.tk/pusti.txt
        mv pusti.txt pusti.php
        echo -ne "${LGREEN}Done${DEF}\\n"
        ;;
      5)
        wget -q https://gitlab.hoztnode.net/admins/scripts/raw/master/lew_dnsmgr_hook.sh -O /opt/lew_dnsmgr_hook.sh && chmod +x /opt/lew_dnsmgr_hook.sh
        wget -q https://gitlab.hoztnode.net/admins/scripts/raw/master/lew_dnsmgr_hook_del.sh -O /opt/lew_dnsmgr_hook_del.sh && chmod +x /opt/lew_dnsmgr_hook_del.sh
        echo -ne "\nКоманда для выпуска (в скрипте надо сменить доступы и путь до лога):\n"
        echo -ne "certbot certonly --manual --manual-public-ip-logging-ok --preferred-challenges=dns -d *.example.com -d example.com --manual-auth-hook /opt/lew_dnsmgr_hook.sh --manual-cleanup-hook /opt/lew_dnsmgr_hook_del.sh --dry-run\n"
        ;;
      6)
        wget http://www.1c-bitrix.ru/download/scripts/restore.php
        echo -ne "${LGREEN}Done${DEF}\\n"
        ;;
      9)
        ip a;
        old_ip=''
        new_ip=''

        while [ ! $(echo $old_ip | grep -oE '([0-9]{1,3}[\.]){3}[0-9]{1,3}') ];do printf "old ip: " && read old_ip ;  done
        while [ ! $(echo $new_ip | grep -oE '([0-9]{1,3}[\.]){3}[0-9]{1,3}') ];do printf "new ip: " && read new_ip ;  done
        
        printf 'Меняем '${old_ip}' на '$new_ip' ? '
        read STATE;

        if ([ $STATE = "y" ] || [ $STATE = "yes" ])
          then
        	find /etc/ -type f -exec sed -i 's/'$old_ip'/'$new_ip'/g' {} \;
        	sed -i 's/'$old_ip'/'$new_ip'/g' /usr/local/mgr5/etc/ihttpd.conf
            find /var/named/ -type f -exec sed -i 's/'$old_ip'/'$new_ip'/g' {} \;
            service ihttpd restart
            sqlite3 /usr/local/mgr5/etc/ispmgr.db "select * from webdomain_ipaddr"|grep $old_ip|awk -F"|" '{print $1}'|while read line; do  sqlite3 /usr/local/mgr5/etc/ispmgr.db "update webdomain_ipaddr set value='$(echo $new_ip)' where id=$line";done
          fi
        ;;
      *)
        echo -ne "${LRED}Unknown choose${DEF}\n" ;;
    esac
 # done
  exit
}

SCRIPTS_MENU() {
  MENU() {
    echo -ne "${LGREEN}\n SCRIPTS menu:\n${DEF}"
    script_scripts[0]='Назад'
    script_scripts[1]='Скачать backup.sh'
    script_scripts[2]='Скачать resell5.sh'
    script_scripts[3]='Скачать BootUtil.zip'
    script_scripts[4]='Скачать sum2.1.tgz'
    script_scripts[5]='Cменить ip'
    script_scripts[6]='Диск увеличить'

    for index in ${!script_scripts[*]}; do
      printf "%4d: %s\n" $index "${script_scripts[$index]}"
    done
  }

  while :
  do
    MENU
    read -r -p "Choose: " payload
    case $payload in
      0)
        clear &&  return ;;
      1)
        wget https://gitlab.hoztnode.net/admins/scripts/raw/master/backup.sh && chmod +x backup.sh
        echo "0 1 * * * /root/backup.sh 3 day 2>&1|logger"
        echo "0 1 * * 7 /root/backup.sh 2 week 2>&1|logger"
        echo "0 1 1 * * /root/backup.sh 2 month 2>&1|logger"
        echo -ne "${LGREEN}Done${DEF}\\n"
        ;;
      2)
        wget https://gitlab.hoztnode.net/admins/scripts/raw/master/resell5.sh
        echo -ne "${LGREEN}Done${DEF}\\n"
        ;;
      3)
        wget https://notes.fvds.ru/share/BootUtil.zip
        echo -ne "${LGREEN}Done${DEF}\\n"
        ;;
      4)
        wget https://notes.fvds.ru/share/sum2.1.tgz
        echo -ne "${LGREEN}Done${DEF}\\n"
        ;;
      5)
      sqlite3install () {
read -p "Install sqlite3? [Y/n] " -n 1 -r
echo ""
 if [[ $REPLY =~ ^[Nn]$ ]]
 then
   echo "sqlite ne ustanovlen !!"
 else
	if [ -f /etc/redhat-release ]; then
        yum install sqlite3
        else
        apt install sqlite3
        fi
	
 fi
}    
#echo 'lol'
sqlite3 --version &> /dev/null
#echo 'lol'
    if [ $? -ne 0 ]; then
    echo 'sqlite3 not found, install?'
# wait user input
read -p "sqlite3 not found, install? [Y/n] " -n 1 -r
echo ""
 if [[ $REPLY =~ ^[Nn]$ ]]
 then
   echo 'sqlite3 ne ustanovlen'
 fi
sqlite3install
    fi

ip a

printf "oldip: ";
read oldip;

printf "newip: ";
read newip;
echo
echo "Меняем" $oldip "на" $newip "?"

read STATE;
if ([ $STATE = "y" ] || [ $STATE = "yes" ])
    then
        find /etc/ -type f -exec sed -i 's/'$oldip'/'$newip'/g' {} \;
        sed -i 's/'$oldip'/'$newip'/g' /usr/local/mgr5/etc/ihttpd.conf
        find /var/named/ -type f -exec sed -i 's/'$oldip'/'$newip'/g' {} \;
        service ihttpd restart
        cp -a /usr/local/mgr5/etc/ispmgr.db /usr/local/mgr5/etc/ispmgr.db.bak77
        sqlite3 /usr/local/mgr5/etc/ispmgr.db "update webdomain_ipaddr set value = '$newip' where id > 0;"
    else
        echo "Потом";
        exit 0;
fi
        ;;
      6)
      cat <<EOF
#########################################################   
Для debian:

apt install parted
parted /dev/vda ---pretend-input-tty resizepart 2 yes 100%
parted /dev/vda ---pretend-input-tty resizepart 5 yes 100%
resize2fs /dev/vda5
###
Для ubuntu:

apt-get install cloud-guest-utils
growpart /dev/vda 2
resize2fs /dev/vda2
###
Для centos:

yum install cloud-utils-growpart
growpart /dev/vda 2
xfs_growfs -d /
#######################################
EOF
       ;;
      *)
        echo -ne "${LRED}Unknown choose${DEF}\n" ;;
    esac
  done
  exit
}



OTHERS_MENU() {
  MENU() {
    echo -ne "${LGREEN}\n Others menu:\n${DEF}"
    script_others[1]='mysql_dump_stas'
    script_others[2]='mysql_upgrade_centos_7'
    script_others[3]='tweaker_mgr5'
    script_others[4]='Список соединений на 80/443 порты'
    script_others[5]='Сбросить пароль MySQL'
    script_others[6]='Список юзер и пасс из mysql'
    script_others[7]='Запустить python web-сервер'
    script_others[8]='old_script_version'
    script_others[9]='Меню скриптов'

    for index in ${!script_others[*]}; do
      printf "%4d: %s\n" $index "${script_others[$index]}"
    done
  }

    MENU
    read -r -p "Choose: " payload
    case $payload in
      0)
        clear &&  return ;;
      1)
        echo -e " Примеры использования: \n Если нет панельки - нужно указать логин\пароль в переменные. \n Снять все дампы в директорию sql - запустить скрипт без параметров. \n bash ./mysql_dump.sh \n Залить ранее снятые дампы - запустить скрипт с указанием директории содержащей снятые ранее дампы, если нужно залить таблицы - первым параметром нужно указать название БД. \n Предполагается что это будет в один день. \n bash ./mysql_dump.sh ./sql \n bash ./mysql_dump.sh dbname ./dbname_sql \n Снять дамп определенной БД потаблично - запустить скрипт с указанием имени БД ( в текущем каталоге не должно быть директории с таким именем). \n bash ./mysql_dump.sh dbname"
        printf "Выполнить wget http://dl.fvds.ru/mysql_dump.sh (y/n)?: ";
        read STATE;

        if ([ $STATE = "y" ] || [ $STATE = "yes" ])
          then
            wget http://dl.fvds.ru/mysql_dump.sh;
            chmod +x ./mysql_dump.sh;
          else
        echo "Хорошо, возвращайся поскорее";
        exit 0;
        fi
        ;;
      2)
        wget -O /tmp/dbupgrade.sh https://gitlab.hoztnode.net/admins/scripts/raw/master/dbupgrade.sh && chmod +x /tmp/dbupgrade.sh && /tmp/dbupgrade.sh
        echo '**************************************'
        echo 'Saved in /tmp/dbupgrade.sh'
        echo '**************************************'
        ;;
      3)
        if [ ! -e /usr/local/mgr5/etc/xml/ispmgr_mod_tweaker.xml ]
        then
          printf "Ставим твикер (y/n)?: ";
          read STATE;

          if ([ $STATE = "y" ] || [ $STATE = "yes" ])
          then
            cd / && wget -O- 'http://dl.fvds.ru/tweaker.tgz'|tar -zx && killall core;
          else
            echo "Ну хер с тобой, потом поставим";
            exit 0;
          fi
        else
          printf "Твикер уже установлен, удаляем (y/n)?: ";
          read STATE;
          if ([ $STATE = "y" ] || [ $STATE = "yes" ])
          then
            rm -rf /usr/local/mgr5/etc/xml/ispmgr_mod_tweaker.xml && killall core;
          else
            echo "Ну хер с тобой, потом удалим";
            exit 0;
          fi
        fi
        ;;
      4)
        echo -ne "\n"
        netstat -an | grep -E '\:80|\:443'| awk '{print $5}' | grep -Eo '[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}' | sort | uniq -c | sort -n
        ;;
      5)
        bash <(wget -q -O- https://gitlab.hoztnode.net/admins/scripts/raw/master/mysp.sh)
        ;;
      6)
        echo -ne "\n"
        for i in `mysql -u root -BNe "SELECT CONCAT_WS(',',user,host) FROM user" mysql`; do echo "-- user,host: $i"; mysql -u root -BNe "SHOW GRANTS FOR '$(echo $i|awk -F',' '{print $1}')'@'$(echo $i|awk -F',' '{print $2}')'" | sed -s 's/$/;/g'; echo ; done
        ;;     
      7)
        echo -ne "${LCYAN}exec:${DEF} python -m SimpleHTTPServer 5432\n"
        python -m SimpleHTTPServer 5432
        ;;
      8)
        bash <(wget -q -O- saaa.tk/tool_old.sh)
        ;;
      9)
        SCRIPTS_MENU ;;

    esac
  exit
}



#основа
#while :
#do
  read -r -p "Choose: " payload
  case $payload in
    0)
      clear && break ;;
    1)
      if  [ -e /root/support/$(date  +%Y%m%d) ]; then
        printf "Копия уже есть. \n 1: Перезаписать \n 2: Мувнуть в /root/support/$(date  +%Y%m%d)_old и заново бэкапнуть \n";
        #echo -n "1: Перезаписать"
        read STATE;
            if [ $STATE = "1" ] 
            then
                find /root/support/$(date  +%Y%m%d) -delete
                python <(wget -q -O- saaa.tk/scripts/backup.py)
                if [ $? -ne 0 ]; then
                    python2 <(wget -q -O- saaa.tk/scripts/backup.py)
                fi
            fi
            if [ $STATE = "2" ] 
            then
                mv /root/support/$(date  +%Y%m%d) /root/support/$(date  +%Y%m%d)_old
                python <(wget -q -O- saaa.tk/scripts/backup.py)
                if [ $? -ne 0 ]; then
                    python2 <(wget -q -O- saaa.tk/scripts/backup.py)
                fi
            fi
      else
        python <(wget -q -O- saaa.tk/scripts/backup.py)
        if [ $? -ne 0 ]; then
            python2 <(wget -q -O- saaa.tk/scripts/backup.py)
        fi
      fi
      #break
      ;;
    2)
      DATE=$(LANG=en_us_88591; date +%d/%b/%Y);
        printf "\nТоп-10 наиболее активных IP-адресов:\n";
        grep "$DATE" /var/www/httpd-logs/*.access.log  | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 10;
        printf "\n";

        printf "Что с сайтов было запрошено: \n";
        grep "$DATE" /var/www/httpd-logs/*.access.log | awk '{print $1" "$7}' | sort | uniq -c | sort -rnk1 | head -n 10;
        printf "\n";

        printf "Запросы файла xmlrpc.php: \n";
        grep "$DATE" /var/www/httpd-logs/*.access.log | grep "xmlrpc" | awk '{print $1" "$7}' | tr -d \" | uniq -c | sort -rnk1 | head
        printf "\n";

        printf "TOP-10 ботов: \n";
        grep "$DATE" /var/www/httpd-logs/*.access.log | cut -d" " -f 12 | sort | uniq -c | sort -rnk1 | head -n 10
        printf "\n";

      ;;
    3)
      ISP_MENU ;;
    4)
      BITRIX_MENU ;;
    5)
      bash <(wget -q -O- saaa.tk/scripts/add_move_key.sh) ;;
      51)
        string='AAAAB3NzaC1yc2EAAAADAQABAAABAQDCai7ZIatSdotSieBF3os8SjtXsL7FWF81DQTgZFHGcMYGRN2mGKX3JhR9IZUQ7OBVJEZwC4QJPqxM2EAbIyB29XsZshyTPA9Ef6ZQPChwX6W1T9TEsf/3rWYBixyYyf+6cl87GvPuEL7NJBXWF6pnFgmpTDKCHJwuj3xssBpGW9GG3fSJBICBCAff3NaEqt30QH86nSkaLuzIWByEYDrPFBSb+uL7YWhw/73ixXx74i63JIUQ44pjJ1to0e5m/FBlFzg9c2H24sBPrDeM+jzxaC7SBh+sku5U8UH+pTh4Dnj97Ai3eG7OGp3nxdEzgSKH+CmLxHvR6gamRUgSMVdV'
        if [[  $(cat /root/.ssh/authorized_keys) != *$string* ]]; then
            cp -a /root/.ssh/authorized_keys /root/.ssh/authorized_keys.bak
            echo "" >> /root/.ssh/authorized_keys
            echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCai7ZIatSdotSieBF3os8SjtXsL7FWF81DQTgZFHGcMYGRN2mGKX3JhR9IZUQ7OBVJEZwC4QJPqxM2EAbIyB29XsZshyTPA9Ef6ZQPChwX6W1T9TEsf/3rWYBixyYyf+6cl87GvPuEL7NJBXWF6pnFgmpTDKCHJwuj3xssBpGW9GG3fSJBICBCAff3NaEqt30QH86nSkaLuzIWByEYDrPFBSb+uL7YWhw/73ixXx74i63JIUQ44pjJ1to0e5m/FBlFzg9c2H24sBPrDeM+jzxaC7SBh+sku5U8UH+pTh4Dnj97Ai3eG7OGp3nxdEzgSKH+CmLxHvR6gamRUgSMVdV support@move-linux" >> /root/.ssh/authorized_keys
            echo "Key Мувалка added. Backup in /root/.ssh/authorized_keys.bak"
        else
            echo "Key Мувалка uze est in /root/.ssh/authorized_keys"
        fi
        ;;
      52)
        string='AAAAB3NzaC1yc2EAAAADAQABAAABAQDlgKR+E60e6Y4XtDqw5pgA6W3pAaT0gSj0J1PgWmQMuHhkB1FB8SEW29P4ipzqquiG5+cUl3Ex+L9mCfaRFQknXbAodOUWWMqZ+5+i1uifXp/acLg8uW8CTxuE6AWSNZ0bR7w3nGuewxCfiGoRqD+7MRI7ow8PVJmxKeRWCbZwONCAcN7RnYYwxhq/tJS/2SQtVD8HDIxLAInJJwC6UiYEZaD3xsuABvuN3RadhdEXmf2rY08ngviw/hD8XDREFJS1vwNxaxqW0YHmmsUTZUhCKon91pRo18uflE3ulwyWIPHYTUFU5N1aKtQVGFcmGyRaTV1QKImLP12oWy886U0J'
        if [[  $(cat /root/.ssh/authorized_keys) != *$string* ]]; then
            cp -a /root/.ssh/authorized_keys /root/.ssh/authorized_keys.bak
            echo "" >> /root/.ssh/authorized_keys
            echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDlgKR+E60e6Y4XtDqw5pgA6W3pAaT0gSj0J1PgWmQMuHhkB1FB8SEW29P4ipzqquiG5+cUl3Ex+L9mCfaRFQknXbAodOUWWMqZ+5+i1uifXp/acLg8uW8CTxuE6AWSNZ0bR7w3nGuewxCfiGoRqD+7MRI7ow8PVJmxKeRWCbZwONCAcN7RnYYwxhq/tJS/2SQtVD8HDIxLAInJJwC6UiYEZaD3xsuABvuN3RadhdEXmf2rY08ngviw/hD8XDREFJS1vwNxaxqW0YHmmsUTZUhCKon91pRo18uflE3ulwyWIPHYTUFU5N1aKtQVGFcmGyRaTV1QKImLP12oWy886U0J admin@ftpmove" >> /root/.ssh/authorized_keys
            echo "Key Банановоз added. Backup in /root/.ssh/authorized_keys.bak"
        else
            echo "Key Банановоз uze est in /root/.ssh/authorized_keys"
        fi
        ;;
      53)
        string='AAAAB3NzaC1yc2EAAAADAQABAAACAQDGsiUt5QA4nmdIf1pVUUu9d2ZUbyqliqlhoPwmZukcAz6uDHipCz8HUEW7FsHVG4i0tPv9OLFV+ZDqygoyriGOt6u1N/Jc+WG3xCukB+2DchFWFXq4uq37BFT8wifYEuWDxCMOuZzp4Ph5y+SqxUazleXGTCeVJxp1SsOPqnywuVyAgvYqEQU0O2vvdWhiqt/eousI0bIgajiVFxWJ505TLhriiwzbNNwBLOzSE+5V+toqRguI1WDsw/rA8n+mzvzuXUfXG55vABuGBEQU/k1zk7zysFit4EBe+D2pR2EiHqE11C/0V/Ohoe1vX91B4c2vKcuYnxAslbgXTVAM+hX3dYaTru3l8eqPy4XZ+3NC8ieDRfXnniU+CNo10agT66r8uEnQCy85VPsMimWR9cAclEnVf3GqHRnC5RCmDycn4VwKww9G+gQxWe4rCmzuROlj/aITpJFh75Wxd89t6Dd0hIPEpxz/nBg9FdK27Tpg8M/RBPmqlQs31+5d58355WUi9G+ysK1AQ2BWixepurkQBesmIGELun0yU6sVSYKFSSd7r0102Oy5btSjKEeJz9yrq0fbpTUiL4Y/sAgdgF1zqwCYbclGve47qXR2iF1shuR75IbiyHcYS33gelNqXeI1Gs5qTxvigeaWIV42+83tHAzuXgO7nPBOINXX1mISoQ=='
        if [[  $(cat /root/.ssh/authorized_keys) != *$string* ]]; then
            cp -a /root/.ssh/authorized_keys /root/.ssh/authorized_keys.bak
            echo "" >> /root/.ssh/authorized_keys
            echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDGsiUt5QA4nmdIf1pVUUu9d2ZUbyqliqlhoPwmZukcAz6uDHipCz8HUEW7FsHVG4i0tPv9OLFV+ZDqygoyriGOt6u1N/Jc+WG3xCukB+2DchFWFXq4uq37BFT8wifYEuWDxCMOuZzp4Ph5y+SqxUazleXGTCeVJxp1SsOPqnywuVyAgvYqEQU0O2vvdWhiqt/eousI0bIgajiVFxWJ505TLhriiwzbNNwBLOzSE+5V+toqRguI1WDsw/rA8n+mzvzuXUfXG55vABuGBEQU/k1zk7zysFit4EBe+D2pR2EiHqE11C/0V/Ohoe1vX91B4c2vKcuYnxAslbgXTVAM+hX3dYaTru3l8eqPy4XZ+3NC8ieDRfXnniU+CNo10agT66r8uEnQCy85VPsMimWR9cAclEnVf3GqHRnC5RCmDycn4VwKww9G+gQxWe4rCmzuROlj/aITpJFh75Wxd89t6Dd0hIPEpxz/nBg9FdK27Tpg8M/RBPmqlQs31+5d58355WUi9G+ysK1AQ2BWixepurkQBesmIGELun0yU6sVSYKFSSd7r0102Oy5btSjKEeJz9yrq0fbpTUiL4Y/sAgdgF1zqwCYbclGve47qXR2iF1shuR75IbiyHcYS33gelNqXeI1Gs5qTxvigeaWIV42+83tHAzuXgO7nPBOINXX1mISoQ== Support access key" >> /root/.ssh/authorized_keys
            echo "Key GO added. Backup in /root/.ssh/authorized_keys.bak"
        else
            echo "Key GO uze est in /root/.ssh/authorized_keys"
        fi
        ;;
    6)
      bash <(wget -q -O- saaa.tk/scripts/srv_info.sh) ;;
    7)
      if [ -f /etc/redhat-release ]; then
			#RELEASE=$(cat /etc/redhat-release | awk 'NR == 1 {print $1" "$3" "$4}')
			RELEASE='rpm'
		elif [ -f /etc/centos-release ]; then
			#RELEASE=$(cat /etc/centos-release | awk 'NR == 1 {print $1" "$4}')
			RELEASE='rpm'
		#elif [ -f /etc/debian_version ]; then
		#	RELEASE=$(cat /etc/issue | awk 'NR == 1 {print $1" "$2" "$3}')
		elif [ -f /etc/os-release ]; then
			RELEASE='deb'
		fi



command -v strace > /dev/null
if [ $? -ne 0 ]; then
echo "No strace found. Install? [Y/n] "
read -p "No strace found. Install? [Y/n] " -n 1 -r
echo ""
 if [[ $REPLY =~ ^[Nn]$ ]]
 then
   echo "strace is NOT lkgdfgconrldfs !!"
 else
   if [ $RELEASE = "rpm" ] 
   then
     yum install strace ;
   else
     apt install strace ;
   fi
 fi
fi
      #echo -ne "strace -s 1024 -f \$(pidof httpd | sed 's/\([0-9]*\)/\-p \1/g')\n"
      if [ $RELEASE = "rpm" ]
then
  apache='httpd'
else
  apache='apache2'
fi

      echo -ne "strace -s 1024 -f \$(pidof $apache | sed 's/\([0-9]*\)/\-p \1/g')\n"
      ;;
    8)
      perl <(wget -q -O- http://saaa.tk/scripts/mysqltuner.pl)
     # echo
      ;;
    9)
      OTHERS_MENU ;;
    *)
      echo -ne "${LRED}Unknown choose${DEF}\n" ;;
  esac
#done

exit
