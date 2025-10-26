#!/bin/bash
set -euo pipefail

httpd_logs_dir="/var/www/httpd-logs"
nginx_logs_dir="/var/log/nginx"
apache2_logs_dir="/var/log/apache2"
httpd_logs2_dir="/var/log/httpd"
www_root_logs_dirs=(/var/www/*/data/logs)

# ---------- utils ----------
human_size() { # bytes -> '42,6K' / '2,3M' / '0B'
    local bytes="${1:-0}"
    if [[ "${bytes}" == "" || "${bytes}" == "0" ]]; then
        echo "0B"; return
    fi
    if command -v numfmt >/dev/null 2>&1; then
        local out
        out=$(numfmt --to=iec --format="%.1f" "${bytes}")
        out=${out/./,}
        echo "$out"
    else
        awk -v b="${bytes}" '
        function fmt(x,u){printf("%.1f%s",x,u)}
        BEGIN{
          if(b<1024){printf "%dB",b; exit}
          if(b<1048576){fmt(b/1024,"K"); exit}
          if(b<1073741824){fmt(b/1048576,"M"); exit}
          if(b<1099511627776){fmt(b/1073741824,"G"); exit}
          fmt(b/1099511627776,"T")
        }' | sed 's/\./,/'
    fi
}

size_bytes_of() { # path -> bytes
    # сначала пробуем stat -c%s; если вдруг не вышло — wc -c
    stat -c%s -- "$1" 2>/dev/null || wc -c <"$1" 2>/dev/null || echo 0
}

print_menu() {
    echo "Найдены следующие лог-файлы (по убыванию размера):"
    local i=0
    while IFS=$'\t' read -r bytes path; do
        # пропускаем пустые строки безопасно
        [[ -z "${bytes:-}" || -z "${path:-}" ]] && continue
        local hs; hs=$(human_size "$bytes")
        printf " %3d) %s %s\n" "$i" "$path" "$hs"
        ((i++))
    done <<<"$MENU_SORTED"
    printf " %3d) %s\n" "$i" "/var/www/*/data/logs"; ((i++))
    printf " %3d) %s\n" "$i" "Ввести путь вручную"
}

# ---------- собираем основной список логов ----------
collect_dirs=("$httpd_logs_dir" "$nginx_logs_dir" "$apache2_logs_dir" "$httpd_logs2_dir")

declare -a main_candidates=()
for d in "${collect_dirs[@]}"; do
    [[ -d "$d" ]] || continue
    while IFS= read -r -d '' f; do
        main_candidates+=("$f")
    done < <(find "$d" -type f -name "*access.log" -print0 2>/dev/null)
done

# Уникализируем и сортируем по пути (чтобы не плодить дубли)
if ((${#main_candidates[@]})); then
    mapfile -t main_candidates < <(printf "%s\n" "${main_candidates[@]}" | awk 'NF' | sort -u)
fi

# Считаем размеры и готовим к сортировке
MENU_DATA=""
for f in "${main_candidates[@]}"; do
    [[ -f "$f" ]] || continue
    bytes=$(size_bytes_of "$f")
    MENU_DATA+="${bytes}"$'\t'"${f}"$'\n'
done

# Удаляем пустые строки, сортируем по убыванию
MENU_SORTED=$(printf "%s" "$MENU_DATA" | awk 'NF' | LC_ALL=C sort -nr -k1,1 || true)

# ---------- печать меню ----------
print_menu

# ---------- выбор основного пункта ----------
read -r -p "Введите номер для анализа: " main_choice

# количество валидных строк (без пустых)
FILES_COUNT=$(printf "%s" "$MENU_SORTED" | awk 'NF' | sed -n '$=')
IDX_DIR=$FILES_COUNT
IDX_MANUAL=$((FILES_COUNT + 1))

if ! [[ "$main_choice" =~ ^[0-9]+$ ]]; then
    echo "Неверный номер."; exit 1
fi
if (( main_choice < 0 || main_choice > IDX_MANUAL )); then
    echo "Неверный номер."; exit 1
fi

selected_file=""
selected_size_hr=""

if (( main_choice == IDX_DIR )); then
    # --- /var/www/*/data/logs ---
    sub_list=""
    for dir in "${www_root_logs_dirs[@]}"; do
        for real in $dir; do
            [[ -d "$real" ]] || continue
            while IFS= read -r -d '' f; do
                bytes=$(size_bytes_of "$f")
                sub_list+="${bytes}"$'\t'"${f}"$'\n'
            done < <(find "$real" -type f \( -name "*access.log" -o -name "*.access.log.*.gz" \) -print0 2>/dev/null)
        done
    done

    sub_sorted=$(printf "%s" "$sub_list" | awk 'NF' | LC_ALL=C sort -nr -k1,1 || true)
    if [[ -z "$sub_sorted" ]]; then
        echo "В директориях нет подходящих файлов."; exit 1
    fi

    echo
    echo "Файлы в /var/www/*/data/logs (отсортированы по убыванию размера):"
    i=0
    mapfile -t SUB_ROWS < <(printf "%s" "$sub_sorted")
    for row in "${SUB_ROWS[@]}"; do
        sbytes="${row%%$'\t'*}"; spath="${row#*$'\t'}"
        [[ -z "$sbytes" || -z "$spath" ]] && continue
        hs=$(human_size "$sbytes")
        printf " %3d) %s %s\n" "$i" "$spath" "$hs"
        ((i++))
    done

    read -r -p "Введите номер файла для анализа: " sub_choice
    if ! [[ "$sub_choice" =~ ^[0-9]+$ ]] || (( sub_choice < 0 )) || (( sub_choice >= ${#SUB_ROWS[@]} )); then
        echo "Неверный номер."; exit 1
    fi

    row="${SUB_ROWS[$sub_choice]}"
    sbytes="${row%%$'\t'*}"; spath="${row#*$'\t'}"
    selected_file="$spath"
    selected_size_hr=$(human_size "$sbytes")

elif (( main_choice == IDX_MANUAL )); then
    read -r -p "Введите полный путь к лог-файлу: " manual_path
    if [[ ! -f "$manual_path" ]]; then
        echo "Файл не найден: $manual_path"; exit 1
    fi
    selected_file="$manual_path"
    selected_size_hr=$(human_size "$(size_bytes_of "$selected_file")")

else
    # обычный индекс из основного списка
    row=$(printf "%s" "$MENU_SORTED" | sed -n "$((main_choice+1))p")
    bytes="${row%%$'\t'*}"; path="${row#*$'\t'}"
    selected_file="$path"
    selected_size_hr=$(human_size "$bytes")
fi

echo "Вы выбрали файл: $selected_file  $selected_size_hr"
echo

# ---------- выбор grep / zgrep ----------
if [[ "$selected_file" == *.gz ]]; then
    grep_cmd="zgrep"
else
    grep_cmd="grep"
fi

# ---------- команда анализа ----------
cmd="$grep_cmd -oiE '\"[^\"]+\"' \"$selected_file\" \
| $grep_cmd -oiE '\\b[a-zA-Z0-9./;+_-]*bot[a-zA-Z0-9./;+_-]*\\b' \
| sort | uniq -c | sort -nr | head -n20"

echo "Будет выполнена команда:"
echo "$cmd"
echo
echo "Результат:"
echo

# shellcheck disable=SC2086
eval "$cmd"
