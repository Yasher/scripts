#!/bin/bash
# Скрипт собирает всех отправителей из заголовков "From:" Exim'а
# и выводит их, отсортированных по количеству

# Папка, где лежат письма в очереди (обычно /var/spool/exim/input)
QUEUE_DIR="/var/spool/exim/input"

# Извлекаем заголовки From из всех писем в очереди
find "$QUEUE_DIR" -type f -name '*-H' -print0 |
  xargs -0 grep -h '^F' |             # строка FFrom: (Exim хранит с префиксом F)
  sed -E 's/^F[[:space:]]*From:[[:space:]]*//' |  # чистим префикс
  sed -E 's/.*<([^>]+)>.*/\1/' |     # достаём e-mail из угловых скобок
  sed -E 's/[[:space:]]+$//' |       # убираем пробелы в конце
  sort | uniq -c | sort -nr          # группируем и сортируем по количеству
