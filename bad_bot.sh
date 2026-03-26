#!/usr/bin/env bash

set -euo pipefail

FILE="/etc/nginx/vhosts-includes/bad_bot.conf"

confirm() {
    read -r -p "$1 [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

CONTENT='if ($http_user_agent ~* (meta-externalagent|PerplexityBot|FriendlyCrawler|GPTBot|AhrefsBot|Amazonbot|PetalBot|SemrushBot|MJ12bot|Riddler|aiHitBot|trovitBot|Detectify|BLEXBot|dotbot|FlipboardProxy|rogerBot|LinkpadBot|Bytespider|Serpstatbot|ClaudeBot|Applebot)) {
    return 410;
}'

# Проверка ISPmanager
if [[ ! -d "/usr/local/mgr5" ]]; then
    echo "Это не ISPmanager окружение"
    exit 1
fi

echo "Обнаружен ISPmanager"

# Если файл уже есть
if [[ -f "$FILE" ]]; then
    echo "Файл уже существует. Содержимое:"
    echo "--------------------------------"
    cat "$FILE"
    echo "--------------------------------"
    exit 0
fi

# Создание файла
if confirm "Создать файл $FILE?"; then
    mkdir -p "$(dirname "$FILE")"
    echo "$CONTENT" > "$FILE"
    echo "Файл создан"
else
    echo "Отменено"
    exit 0
fi

# Проверка и reload
if confirm "Проверить конфиг и перезагрузить nginx?"; then
    if nginx -t; then
        echo "OK, перезагрузка"
        nginx -s reload || systemctl reload nginx
    else
        echo "Ошибка конфигурации nginx"
        exit 1
    fi
fi
