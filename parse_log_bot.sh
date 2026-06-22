#!/bin/bash
while true; do

httpd_logs_dir="/var/www/httpd-logs"
nginx_logs_dir="/var/log/nginx"
apache2_logs_dir="/var/log/apache2"
httpd_logs2_dir="/var/log/httpd"
www_root_logs_dirs=(/var/www/*/data/logs)

# Заполняем список файлов кроме /var/www/*/data/logs
main_files=()
while IFS= read -r -d '' file; do
    main_files+=("$file")
done < <(find "$httpd_logs_dir" -type f -name "*access.log" -print0 2>/dev/null)

while IFS= read -r -d '' file; do
    main_files+=("$file")
done < <(find "$nginx_logs_dir" -type f -name "*access.log" -print0 2>/dev/null)

while IFS= read -r -d '' file; do
    main_files+=("$file")
done < <(find "$apache2_logs_dir" -type f -name "*access.log" -print0 2>/dev/null)

while IFS= read -r -d '' file; do
    main_files+=("$file")
done < <(find "$httpd_logs2_dir" -type f -name "*access.log" -print0 2>/dev/null)

# Добавляем пункт для директорий и ручного ввода
main_files+=("/var/www/*/data/logs")
#main_files+=("n) Ввести путь вручную")

echo "Найдены следующие лог-файлы:"
for i in "${!main_files[@]}"; do
    printf "%3d) %s\n" "$i" "${main_files[$i]}"
done

echo "n) Ввести путь вручную"
echo "q) Выход"
echo -n "Введите номер для анализа: "
read main_choice


if [[ "$main_choice" == "q" ]]; then
    break
fi

if ! [[ "$main_choice" =~ ^[0-9]+$ ]] || [ "$main_choice" -lt 0 ] || [ "$main_choice" -ge "${#main_files[@]}" ]; then
    echo "Неверный номер."
    continue
fi


# --- Новый пункт: ручной ввод пути ---
#if [ "$selected_main" = "Ввести путь вручную" ]; then
if [[ "$main_choice" == "n" ]]; then
    echo -n "Введите полный путь к лог-файлу: "
    read manual_path
    if [ ! -f "$manual_path" ]; then
        echo "Файл не найден: $manual_path"
        continue
    fi
    selected_file="$manual_path"

selected_main="${main_files[$main_choice]}"



# --- Выбор из /var/www/*/data/logs ---
elif [ "$selected_main" = "/var/www/*/data/logs" ]; then
    sub_files_unsorted=()
    for dir in "${www_root_logs_dirs[@]}"; do
        [ -d "$dir" ] || continue
        while IFS= read -r -d '' file; do
            sub_files_unsorted+=("$file")
        done < <(find "$dir" -type f \( -name "*access.log" -o -name "*.access.log*.gz" \) -print0 2>/dev/null)
    done

    # Сортировка natural version
    IFS=$'\n' sorted_files=($(printf "%s\n" "${sub_files_unsorted[@]}" | sort -V))
    unset IFS

    if [ ${#sorted_files[@]} -eq 0 ]; then
        echo "В директориях нет подходящих файлов."
        continue
    fi

    echo
    echo "Файлы в /var/www/*/data/logs (отсортированы):"
    for i in "${!sorted_files[@]}"; do
        printf "%3d) %s\n" "$i" "${sorted_files[$i]}"
    done

    echo -n "Введите номер файла для анализа: "
    read sub_choice

    if ! [[ "$sub_choice" =~ ^[0-9]+$ ]] || [ "$sub_choice" -lt 0 ] || [ "$sub_choice" -ge "${#sorted_files[@]}" ]; then
        echo "Неверный номер."
        continue
    fi

    selected_file="${sorted_files[$sub_choice]}"
else
    selected_file="$selected_main"
fi

echo "Вы выбрали файл: $selected_file"
echo

# Определяем, сжатый ли файл
if [[ "$selected_file" == *.gz ]]; then
    grep_cmd="zgrep"
else
    grep_cmd="grep"
fi

# Команда анализа

if [[ "$selected_file" == *.gz ]]; then
    cmd="zcat \"$selected_file\" \
    | awk '\$9 !~ /^(403|444|410|429)$/' \
    | grep -oiE '\\b[a-zA-Z0-9./;+_-]*(bot|meta|facebook)[a-zA-Z0-9./;+_-]*\\b' \
    | sort | uniq -c | sort -nr | head -n20"
else
    cmd="awk '\$9 !~ /^(403|444|410|429)$/' \"$selected_file\" \
    | grep -oiE '\\b[a-zA-Z0-9./;+_-]*(bot|meta|facebook)[a-zA-Z0-9./;+_-]*\\b' \
    | sort | uniq -c | sort -nr | head -n20"
fi

#cmd="$grep_cmd -oiE '\"[^\"]+\"' \"$selected_file\" | $grep_cmd -oiE '\\b[a-zA-Z0-9./;+_-]*(bot|meta|facebook)[a-zA-Z0-9./;+_-]*\\b' | sort | uniq -c | sort -nr | head -n20"

echo "Будет выполнена команда:"
echo "$cmd"
echo
echo "Результат:"
echo

# Выполняем команду
eval "$cmd"

echo
read -p "Нажмите Enter для возврата в меню..."
clear
done
