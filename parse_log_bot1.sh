#!/bin/bash

httpd_logs_dir="/var/www/httpd-logs"
nginx_logs_dir="/var/log/nginx"
apache2_logs_dir="/var/log/apache2"
httpd_logs2_dir="/var/log/httpd"
www_root_logs_dirs=(/var/www/*/data/logs)

# Функция для получения размера файла в человекочитаемом формате
get_file_size() {
    local file="$1"
    if [[ -f "$file" ]]; then
        # Получаем размер в байтах
        size=$(stat -f %z "$file" 2>/dev/null || stat -c %s "$file" 2>/dev/null)
        # Преобразуем в человекочитаемый формат
        if [[ $size -ge 1073741824 ]]; then
            echo "$(bc <<< "scale=2; $size/1073741824") GB"
        elif [[ $size -ge 1048576 ]]; then
            echo "$(bc <<< "scale=2; $size/1048576") MB"
        elif [[ $size -ge 1024 ]]; then
            echo "$(bc <<< "scale=2; $size/1024") KB"
        else
            echo "$size B"
        fi
    else
        echo "N/A"
    fi
}

# Собираем файлы логов с их размерами
declare -A main_files_sizes
main_files=()
while IFS= read -r -d '' file; do
    main_files+=("$file")
    main_files_sizes["$file"]=$(get_file_size "$file")
done < <(find "$httpd_logs_dir" -type f -name "*.access.log" -print0 2>/dev/null)

while IFS= read -r -d '' file; do
    main_files+=("$file")
    main_files_sizes["$file"]=$(get_file_size "$file")
done < <(find "$nginx_logs_dir" -type f -name "*.access.log" -print0 2>/dev/null)

while IFS= read -r -d '' file; do
    main_files+=("$file")
    main_files_sizes["$file"]=$(get_file_size "$file")
done < <(find "$apache2_logs_dir" -type f -name "*.access.log" -print0 2>/dev/null)

while IFS= read -r -d '' file; do
    main_files+=("$file")
    main_files_sizes["$file"]=$(get_file_size "$file")
done < <(find "$httpd_logs2_dir" -type f -name "*.access.log" -print0 2>/dev/null)

# Добавляем пункт для директорий /var/www/*/data/logs
main_files+=("/var/www/*/data/logs")
main_files_sizes["/var/www/*/data/logs"]="N/A"

# Сортируем файлы по размеру (для файлов, не директорий)
sorted_main_files=()
while IFS= read -r line; do
    file=$(echo "$line" | cut -d$'\t' -f2)
    sorted_main_files+=("$file")
done < <(for file in "${main_files[@]}"; do
    if [[ "$file" != "/var/www/*/data/logs" ]]; then
        size=$(stat -f %z "$file" 2>/dev/null || stat -c %s "$file" 2>/dev/null || echo 0)
        echo -e "$size\t$file"
    else
        echo -e "0\t$file"
    fi
done | sort -nr)

echo "Найдено следующие лог-файлы (отсортированы по размеру):"
for i in "${!sorted_main_files[@]}"; do
    printf "%3d) %s (%s)\n" "$i" "${sorted_main_files[$i]}" "${main_files_sizes[${sorted_main_files[$i]}]}"
done

echo -n "Введите номер для анализа: "
read main_choice

if ! [[ "$main_choice" =~ ^[0-9]+$ ]] || [ "$main_choice" -lt 0 ] || [ "$main_choice" -ge "${#sorted_main_files[@]}" ]; then
    echo "Неверный номер."
    exit 1
fi

selected_main="${sorted_main_files[$main_choice]}"

# Проверяем, выбрана ли "директория"
if [ "$selected_main" = "/var/www/*/data/logs" ]; then
    sub_files_unsorted=()
    declare -A sub_files_sizes
    for dir in "${www_root_logs_dirs[@]}"; do
        [ -d "$dir" ] || continue
        while IFS= read -r -d '' file; do
            sub_files_unsorted+=("$file")
            sub_files_sizes["$file"]=$(get_file_size "$file")
        done < <(find "$dir" -type f \( -name "*.access.log" -o -name "*.access.log.*.gz" \) -print0 2>/dev/null)
    done

    # Сортируем файлы по размеру
    sorted_files=()
    while IFS= read -r line; do
        file=$(echo "$line" | cut -d$'\t' -f2)
        sorted_files+=("$file")
    done < <(for file in "${sub_files_unsorted[@]}"; do
        size=$(stat -f %z "$file" 2>/dev/null || stat -c %s "$file" 2>/dev/null || echo 0)
        echo -e "$size\t$file"
    done | sort -nr)

    if [ ${#sorted_files[@]} -eq 0 ]; then
        echo "В директориях нет подходящих файлов."
        exit 1
    fi

    echo
    echo "Файлы в /var/www/*/data/logs (отсортированы по размеру):"
    for i in "${!sorted_files[@]}"; do
        printf "%3d) %s (%s)\n" "$i" "${sorted_files[$i]}" "${sub_files_sizes[${sorted_files[$i]}]}"
    done

    echo -n "Введите номер файла для анализа: "
    read sub_choice

    if ! [[ "$sub_choice" =~ ^[0-9]+$ ]] || [ "$sub_choice" -lt 0 ] || [ "$sub_choice" -ge "${#sorted_files[@]}" ]; then
        echo "Неверный номер."
        exit 1
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

# Команда
cmd="$grep_cmd -oiE '\"[^\"]+\"' \"$selected_file\" | $grep_cmd -oiE '\\b[a-zA-Z0-9./;+_-]*bot[a-zA-Z0-9./;+_-]*\\b' | sort | uniq -c | sort -nr | head -n20"

echo "Будет выполнена команда:"
echo "$cmd"
echo
echo "Результат:"
echo

# Выполняем команду
eval "$cmd"
