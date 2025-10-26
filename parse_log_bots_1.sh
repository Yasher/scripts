#!/bin/bash

httpd_logs_dir="/var/www/httpd-logs"
nginx_logs_dir="/var/log/nginx"
apache2_logs_dir="/var/log/apache2"
httpd_logs2_dir="/var/log/httpd"
www_root_logs_dirs=(/var/www/*/data/logs)

# ---------- утилиты ----------
# size_bytes -> "2,3M"
human_size() {
    local bytes="$1"
    local unit=""
    local value=0
    local div=1
    if   [ "$bytes" -ge 1152921504606846976 ]; then unit="E"; div=1152921504606846976
    elif [ "$bytes" -ge 1125899906842624 ];   then unit="P"; div=1125899906842624
    elif [ "$bytes" -ge 1099511627776 ];     then unit="T"; div=1099511627776
    elif [ "$bytes" -ge 1073741824 ];        then unit="G"; div=1073741824
    elif [ "$bytes" -ge 1048576 ];           then unit="M"; div=1048576
    elif [ "$bytes" -ge 1024 ];              then unit="K"; div=1024
    else echo "${bytes}B"; return; fi

    # одна цифра после запятой и запятая как разделитель
    value=$(awk -v b="$bytes" -v d="$div" 'BEGIN{printf("%.1f", b/d)}')
    echo "${value/,/.}" | sed 's/\./,/' | sed 's/,\([0]\)$//; s/,0$//' | awk -v u="$unit" '{printf "%s%s", $0, u}'
}

# кроссплатформенный stat размера (Linux/BSD)
file_size_bytes() {
    local f="$1"
    if command -v stat >/dev/null 2>&1; then
        if stat -c%s "$f" >/dev/null 2>&1; then
            stat -c%s "$f"
        elif stat -f%z "$f" >/dev/null 2>&1; then
            stat -f%z "$f"
        else
            echo 0
        fi
    else
        echo 0
    fi
}

# собрать список файлов + размеры -> отсортировать по размеру убыв.
# выводит в stdout строки: "<size_bytes>\t<path>"
collect_and_sort_by_size() {
    local arr=("$@")
    local path
    for path in "${arr[@]}"; do
        [ -f "$path" ] || continue
        local sz
        sz=$(file_size_bytes "$path")
        echo -e "${sz}\t${path}"
    done | sort -nr -k1,1
}

# ---------- сбор главного списка ----------
main_candidates=()

while IFS= read -r -d '' f; do main_candidates+=("$f"); done < <(find "$httpd_logs_dir"  -type f -name "*access.log" -print0 2>/dev/null)
while IFS= read -r -d '' f; do main_candidates+=("$f"); done < <(find "$nginx_logs_dir"  -type f -name "*access.log" -print0 2>/dev/null)
while IFS= read -r -d '' f; do main_candidates+=("$f"); done < <(find "$apache2_logs_dir" -type f -name "*access.log" -print0 2>/dev/null)
while IFS= read -r -d '' f; do main_candidates+=("$f"); done < <(find "$httpd_logs2_dir" -type f -name "*access.log" -print0 2>/dev/null)

# отсортированные файлы по размеру
mapfile -t main_sorted_lines < <(collect_and_sort_by_size "${main_candidates[@]}")

# соберём массивы путей и человеко-размеров для меню
main_files=()
main_sizes=()

for line in "${main_sorted_lines[@]}"; do
    size_bytes="${line%%$'\t'*}"
    path="${line#*$'\t'}"
    main_files+=("$path")
    main_sizes+=("$(human_size "$size_bytes")")
done

# Добавляем спец-пункты (не сортируются среди файлов)
special_dir="/var/www/*/data/logs"
special_manual="Ввести путь вручную"
main_files+=("$special_dir" "$special_manual")
main_sizes+=("" "")  # пустые размеры для спец-пунктов

# ---------- меню ----------
echo "Найдены следующие лог-файлы (по убыванию размера):"
for i in "${!main_files[@]}"; do
    if [ -n "${main_sizes[$i]}" ]; then
        printf "%3d) %s %s\n" "$i" "${main_files[$i]}" "${main_sizes[$i]}"
    else
        printf "%3d) %s\n" "$i" "${main_files[$i]}"
    fi
done

echo -n "Введите номер для анализа: "
read main_choice
if ! [[ "$main_choice" =~ ^[0-9]+$ ]] || [ "$main_choice" -lt 0 ] || [ "$main_choice" -ge "${#main_files[@]}" ]; then
    echo "Неверный номер."
    exit 1
fi

selected_main="${main_files[$main_choice]}"

# ---------- обработка выбора ----------
if [ "$selected_main" = "$special_manual" ]; then
    # ручной путь
    echo -n "Введите полный путь к лог-файлу: "
    read manual_path
    if [ ! -f "$manual_path" ]; then
        echo "Файл не найден: $manual_path"
        exit 1
    fi
    sizeb=$(file_size_bytes "$manual_path")
    sizeh=$(human_size "$sizeb")
    selected_file="$manual_path"
    echo "Вы выбрали файл: $selected_file  $sizeh"
    echo

elif [ "$selected_main" = "$special_dir" ]; then
    # выбор из /var/www/*/data
