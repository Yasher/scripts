#!/usr/bin/env bash

set -euo pipefail

FILE="/etc/nginx/vhosts-includes/bad_bot.conf"

CONTENT='if ($http_user_agent ~* (PerplexityBot|FriendlyCrawler|GPTBot|AhrefsBot|Amazonbot|PetalBot|SemrushBot|MJ12bot|Riddler|aiHitBot|trovitBot|Detectify|BLEXBot|dotbot|FlipboardProxy|rogerBot|LinkpadBot|Bytespider|Serpstatbot|ClaudeBot|Applebot)) {
    return 410;
}'

if [[ -f "$FILE" ]]; then
    echo "Файл существует. Содержимое:"
    echo "--------------------------------"
    cat "$FILE"
    echo "--------------------------------"
    exit 0
fi

echo "Файл не найден: $FILE"
read -r -p "Создать файл и перезагрузить nginx? [y/N]: " answer

if [[ "$answer" =~ ^[Yy]$ ]]; then
    mkdir -p "$(dirname "$FILE")"

    echo "$CONTENT" > "$FILE"
    echo "Файл создан."

    if nginx -t; then
        echo "Конфигурация nginx корректна. Перезагрузка..."
        systemctl reload nginx
    else
        echo "Ошибка в конфигурации nginx. Перезагрузка отменена."
        exit 1
    fi
else
    echo "Отменено."
    exit 0
fi
