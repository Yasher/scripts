#!/bin/bash

DB="/opt/autobackup/journal.db"

printf "del < date (YYYY-MM-DD): "
read -r DATE_MIN

sqlite3 "$DB" "DELETE FROM backups WHERE dtime < '$DATE_MIN 00:00:00';"
echo "Удалено < $DATE_MIN"

printf "del > date (YYYY-MM-DD): "
read -r DATE_MAX

sqlite3 "$DB" "DELETE FROM backups WHERE dtime > '$DATE_MAX 23:59:59';"
echo "Удалено > $DATE_MAX"
