#!/bin/bash
# exim-from-stats.sh — считает отправителей по очереди Exim

set -euo pipefail

# Достаём message-id из exim -bp (он в виде 1v8MIG-00038F-Sh и т.п.)
exim -bp \
| awk '{
    for (i=1; i<=NF; i++) {
        if ($i ~ /^[0-9A-Za-z-]{10,}$/ && $i ~ /-/) { print $i; break }
    }
}' \
| xargs -r -n1 -P "$(nproc)" exim -Mvh \
| awk 'BEGIN{IGNORECASE=1}
    # Ловим как обычный "From:", так и экзимовский "054F From:"
    match($0,/^([0-9]+F[ \t]*)?From:/) {
        s=$0
        sub(/^([0-9]+F[ \t]*)?From:[ \t]*/,"",s)
        # 1) email внутри <...>
        if (match(s,/<([^>]+)>/,m)) { print tolower(m[1]); next }
        # 2) иначе первая похожая на email строка
        if (match(s,/[[:alnum:]._%+-]+@[[:alnum:].-]+\.[A-Za-z]{2,}/,m)) { print tolower(m[0]); next }
    }
    # Фолбэк: если From пуст, пробуем Sender:
    match($0,/^([0-9]+S[ \t]*)?Sender:/) {
        s=$0
        sub(/^([0-9]+S[ \t]*)?Sender:[ \t]*/,"",s)
        if (match(s,/<([^>]+)>/,m)) { print tolower(m[1]); next }
        if (match(s,/[[:alnum:]._%+-]+@[[:alnum:].-]+\.[A-Za-z]{2,}/,m)) { print tolower(m[0]); next }
    }
' \
| sed '/^$/d' \
| sort \
| uniq -c \
| sort -nr \
| column -t
