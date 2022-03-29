#!/usr/bin/python
# -*- coding: utf-8 -*-

#hello. it's ne virus, it just a kopirivarie konfigov for vsyakii pojarny.
# on kopiruet v support/ data segodnashnaya/ otdelnye diri for /etc/, usr/local/mgr/etc/ and crontabs.
# posle 4ego udalyaet sebya because it mojet visvat voprosi
# If you have zamechania, or predlojenia, go play dota 2.
# haters gonna hate.
# Version 1.04 (19.02) - rabotaet, do not trogay.
import os
import time
import sys
os.system('clear')

print '''\033[94m  

/  ___|          | |                            | |
\ `--. _   _  ___| |__    _ __   __ _ _ __   ___| |
 `--. \ | | |/ __| '_ \  | '_ \ / _` | '_ \ / _ \ |
/\__/ / |_| | (__| | | | | |_) | (_| | | | |  __/ |
\____/ \__,_|\___|_| |_| | .__/ \__,_|_| |_|\___|_|
                         | |                       
                         |_|                       

─────────▄──────────────▄────
────────▌▒█───────────▄▀▒▌───
────────▌▒▒▀▄───────▄▀▒▒▒▐───
───────▐▄▀▒▒▀▀▀▀▄▄▄▀▒▒▒▒▒▐───
─────▄▄▀▒▒▒▒▒▒▒▒▒▒▒█▒▒▄█▒▐───
───▄▀▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▀██▀▒▌───
──▐▒▒▒▄▄▄▒▒▒▒▒▒▒▒▒▒▒▒▒▀▄▒▒▌──
──▌▒▒▐▄█▀▒▒▒▒▄▀█▄▒▒▒▒▒▒▒█▒▐──
─▐▒▒▒▒▒▒▒▒▒▒▒▌██▀▒▒▒▒▒▒▒▒▀▄▌─
─▌▒▀▄██▄▒▒▒▒▒▒▒▒▒▒▒░░░░▒▒▒▒▌─
─▌▀▐▄█▄█▌▄▒▀▒▒▒▒▒▒░░░░░░▒▒▒▐─
▐▒▀▐▀▐▀▒▒▄▄▒▄▒▒▒▒▒░░░░░░▒▒▒▒▌
▐▒▒▒▀▀▄▄▒▒▒▄▒▒▒▒▒▒░░░░░░▒▒▒▐─
─▌▒▒▒▒▒▒▀▀▀▒▒▒▒▒▒▒▒░░░░▒▒▒▒▌─
─▐▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▐──
──▀▄▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▄▒▒▒▒▌──
────▀▄▒▒▒▒▒▒▒▒▒▒▄▄▄▀▒▒▒▒▄▀───
───▐▀▒▀▄▄▄▄▄▄▀▀▀▒▒▒▒▒▄▄▀─────
──▐▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▀▀────────

 _____                         _           _      
/  ___|                       | |         | |     
\ `--.  ___     _____  ___ __ | | ___   __| | ___ 
 `--. \/ _ \   / _ \ \/ / '_ \| |/ _ \ / _` |/ _ \
/\__/ / (_) | |  __/>  <| |_) | | (_) | (_| |  __/
\____/ \___/   \___/_/\_\ .__/|_|\___/ \__,_|\_____
                        | |                       
                        |_|       

\033[0m'''


source = '/etc'
target = '/root/support/' + time.strftime('%Y%m%d') + '/etc/'
support = 'mkdir /root/support >> /dev/null 2>&1 '
dira = "mkdir /root/support/" +time.strftime('%Y%m%d') + ">> /dev/null 2>&1"
delete = 'rm -f  messiah.py*'
print '\033[94mHello, bratan. I am messiah.py - I ni4ego ne umeu delat, tolko backup konfigs. But it could save your ass and not yours millions\033[0m'
print '\033[94mnow just podojdi...\033[0m'

os.system(support) 
os.system(delete)
#os.system(dira) 


path = "/root/support/" + time.strftime('%Y%m%d')
created = False
is_error_17 = False

try:
   os.makedirs(path)
   created = True
except OSError as e:
  if e.errno == 17:
     raw_input ('\033[91mKopia za segodnya est. If you znaesh what do you delaesh, type lubaya button. Everything will be perepisano...\033[0m ')
     os.system(delete)    
     is_error_17 = True

process = 'cp -Rp {1} {0}'.format(target,source)
if os.system(process) == 0:
        print "\033[92mbackup /etc sdelan in {0}\033[0m".format(target)
else:
        print "\033[91something wrong. pishi to pochta\033[0m"


source = '/usr/local/mgr5/etc/'
target = '/root/support/' + time.strftime('%Y%m%d') + '/mgr/'
process = 'cp -Rp {1} {0} >> /dev/null 2>&1' .format(target,source)

if os.system(process) == 0:
        print "\033[92mbackup /etc paneli sdelan in {0}\033[0m".format(target)
else:
        print "\033[91mbackup MGR5 ne sdelan, because there is no panel!\033[0m"

source = '/var/spool/cron'
target = '/root/support/' + time.strftime('%Y%m%d') + '/cron/'
process = 'cp -Rp {1} {0}'.format(target,source)
if os.system(process) == 0:
        print "\033[92mcrontabs toje scopirovany in da {0}\033[0m".format(target)
	os.system(delete)
	print "\033[91mI sdelal vse. Now I delete myself. Bye\033[0m"
else:
        print "\033[91mvse ploho\033[0m"
