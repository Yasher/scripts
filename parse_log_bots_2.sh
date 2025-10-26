#!/bin/bash
set -euo pipefail

httpd_logs_dir="/var/www/httpd-logs"
nginx_logs_dir="/var/log/nginx"
apache2_logs_dir="/var/log/apache2"
httpd_logs2_dir="/var/log/httpd"
www_root_logs_dirs=(/var/www/*/data/logs)

# ---------- Утилиты ----------
have_cmd() { command -v "$1" >/dev/null 2>&1; }

get_size_bytes() {
  # echo size in bytes or 0 on error
  local f="$1"
  if have_cmd stat; then
    # GNU stat
    stat -c%s "$f" 2>/dev/null && return 0 || true
    # BSD stat (реже в Linux, но вдруг)
    stat -f%z "$f" 2>/dev/null && return 0 || true
  fi
  # Fallback через wc (медленнее, но надёжно)
  wc -c < "$f" 2>/dev/null || echo 0
}

human_size() {
  # печатаем человекочитаемый размер по образцу "2,3M"
  local bytes="$1"
  if have_cmd numfmt; then
    # Превращаем в IEC единицы, убираем i/B, меняем '.' -> ','
    local out
    out=$(numfmt --to=iec --format="%.1f" "$bytes" 2>/dev/null | sed -E 's/iB|B//g; s/\.0$//; s/\./,/')
    echo "${out}"
  else
    # Простейший fallback
    local out unit
    if (( bytes < 1024 )); then
      out="$bytes"; unit="B"
    elif (( bytes < 1024*1024 )); then
      out=$(awk -v b="$bytes" 'BEGIN{printf("%.1f", b/1024)}'); unit="K"
    elif (( bytes < 1024*1024*1024 )); then
      out=$(awk -v b="$bytes" 'BEGIN{printf("%.1f", b/1048576)}'); unit="M"
    else
      out=$(awk -v b="$bytes" 'BEGIN{printf("%.1f", b/1073741824)}'); unit="G"
    fi
    out="${out/./,}"
    out="${out%\,0}"
    echo "${out}${unit}"
  fi
}

# Собираем список файлов из стандартных директорий
collect_logs() {
  local -n _arr=$1
  _arr=()

  while IFS= read -r -d '' f; do _arr+=("$f"); done < <(find "$httpd_logs_dir"  -type f -name "*access.log" -print0 2>/dev/null)
  while IFS= read -r -d '' f; do _arr+=("$f"); done < <(find "$nginx_logs_dir"  -type f -name "*access.log" -print0 2>/dev/null)
  while IFS= read -r -d '' f; do _arr+=("$f"); done < <(find "$apache2_logs_dir" -type f -name "*access.log" -print0 2>/dev/null)
  while IFS= read -r -d '' f; do _arr+=("$f"); done < <(find "$httpd_logs2_dir" -type f -name "*access.log" -print0 2>/dev/null)
}

# Сортировка путей по размеру (DESC) и вывод меню
print_menu_sorted_by_size() {
  local -n _paths=$1
  local -n _sizes_bytes=$2
  local -n _sizes_h=$3

  local tmp_list=() line
  _sizes_bytes=(); _sizes_h=()

  # Строим список "size<TAB>path"
  for p in "${_paths[@]}"; do
    if [ -f "$p" ]; then
      local sz
      sz=$(get_size_bytes "$p" || echo 0)
      tmp_list+=("${sz}\t${p}")
    fi
  done

  # Сортируем по size DESC
  IFS=$'\n' read -r -d '' -a tmp_sorted < <(printf "%b\n" "${tmp_list[@]}" | sort -t$'\t' -k1,1nr && printf '\0')
  unset IFS

  # Перезаписываем _paths в отсортированном виде + заполняем размеры
  _paths=()
  local sz path
  for line in "${tmp_sorted[@]}"; do
    sz="${line%%$'\t'*}"
    path="${line#*$'\t'}"
    _paths+=("$path")
    _sizes_bytes+=("$sz")
    _sizes_h+=("$(human_size "$sz")")
  done

  # Печать пунктов меню
  for i in "${!_paths[@]}"; do
    printf "%3d) %s %s\n" "$i" "${_paths[$i]}" "${_sizes_h[$i]}"
  done
}

# ---------- Главный блок ----------
main_files_raw=()
collect_logs main_files_raw

# Спец-пункты (без размера): директории /var/www/*/data/logs и ручной ввод
special_dir_label="/var/www/*/data/logs"
manual_label="Ввести путь вручную"

# Отдельно держим файлы для сортировки, потом добавим спец-пункты
files_only=("${main_files_raw[@]}")

echo "Найдены следующие лог-файлы (отсортированы по размеру):"
sizes_bytes_main=()
sizes_h_main=()
print_menu_sorted_by_size files_only sizes_bytes_main sizes_h_main

# Индексы для спец-пунктов
idx_special_dir=${#files_only[@]}
idx_manual=$((idx_special_dir + 1))

printf "%3d) %s\n" "$idx_special_dir" "$special_dir_label"
printf "%3d) %s\n" "$idx_manual"      "$manual_label"

echo -n "Введите номер для анализа: "
read main_choice

# Проверка ввода
if ! [[ "$main_choice" =~ ^[0-
