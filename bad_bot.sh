#!/usr/bin/env bash

set -euo pipefail

MAP_FILE="/etc/nginx/bx/conf/bad_bot_map.conf"
BITRIX_CONF="/etc/nginx/bx/conf/bitrix.conf"
NGINX_CONF="/etc/nginx/nginx.conf"

MAP_CONTENT='map $http_user_agent $bad_bot {
    default 0;
    ~*(meta-externalagent|facebook|PerplexityBot|FriendlyCrawler|GPTBot|AhrefsBot|Amazonbot|PetalBot|SemrushBot|MJ12bot|Riddler|aiHitBot|trovitBot|Detectify|BLEXBot|dotbot|FlipboardProxy|rogerBot|LinkpadBot|Bytespider|Serpstatbot|ClaudeBot|Applebot) 1;
}'

IF_BLOCK='
if ($bad_bot) {
    return 410;
}
'

# Проверка BitrixVM
if [[ ! -d "/etc/nginx/bx" ]]; then
    echo "Это не BitrixVM окружение"
    exit 1
fi

echo "BitrixVM обнаружен"

# 1. Создание map-файла
if [[ -f "$MAP_FILE" ]]; then
    echo "MAP файл уже существует"
else
    echo "Создаём MAP файл"
    echo "$MAP_CONTENT" > "$MAP_FILE"
fi

# 2. Проверка include в nginx.conf
if grep -q "bad_bot_map.conf" "$NGINX_CONF"; then
    echo "include уже есть в nginx.conf"
else
    echo "Добавляем include в nginx.conf"

    sed -i '/http {/a \    include /etc/nginx/bx/conf/bad_bot_map.conf;' "$NGINX_CONF"
fi

# 3. Добавление правила в bitrix.conf
if grep -q "bad_bot" "$BITRIX_CONF"; then
    echo "Правило уже есть в bitrix.conf"
else
    echo "Добавляем правило в bitrix.conf"
    echo "$IF_BLOCK" >> "$BITRIX_CONF"
fi

# 4. Проверка и reload
if nginx -t; then
    echo "nginx конфиг OK, перезагрузка"
    nginx -s reload || systemctl reload nginx
else
    echo "Ошибка конфигурации nginx"
    exit 1
fi
