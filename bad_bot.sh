#!/usr/bin/env bash

set -euo pipefail

confirm() {
    read -r -p "$1 [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

MAP_CONTENT='map $http_user_agent $bad_bot {
    default 0;
    ~*(PerplexityBot|FriendlyCrawler|GPTBot|AhrefsBot|Amazonbot|PetalBot|SemrushBot|MJ12bot|Riddler|aiHitBot|trovitBot|Detectify|BLEXBot|dotbot|FlipboardProxy|rogerBot|LinkpadBot|Bytespider|Serpstatbot|ClaudeBot|Applebot) 1;
}'

IF_BLOCK='
if ($bad_bot) {
    return 410;
}
'

NGINX_CONF="/etc/nginx/nginx.conf"

# Определение окружения
if [[ -d "/etc/nginx/bx" ]]; then
    PANEL="bitrix"
    MAP_FILE="/etc/nginx/bx/conf/bad_bot_map.conf"
    TARGET_CONF="/etc/nginx/bx/conf/bitrix.conf"

elif [[ -d "/usr/local/mgr5" ]]; then
    PANEL="ispmanager"
    MAP_FILE="/etc/nginx/vhosts-includes/bad_bot_map.conf"
    TARGET_CONF="/etc/nginx/vhosts-includes/bad_bot.conf"

else
    echo "Не удалось определить окружение (BitrixVM / ISPmanager)"
    exit 1
fi

echo "Обнаружено окружение: $PANEL"

# 1. map файл
if [[ -f "$MAP_FILE" ]]; then
    echo "MAP файл уже существует: $MAP_FILE"
else
    if confirm "Создать MAP файл $MAP_FILE?"; then
        mkdir -p "$(dirname "$MAP_FILE")"
        echo "$MAP_CONTENT" > "$MAP_FILE"
        echo "Создано"
    fi
fi

# 2. include в nginx.conf
if grep -q "$(basename "$MAP_FILE")" "$NGINX_CONF"; then
    echo "include уже есть в nginx.conf"
else
    if confirm "Добавить include в nginx.conf?"; then
        sed -i "/http {/a \    include $MAP_FILE;" "$NGINX_CONF"
        echo "Добавлено"
    fi
fi

# 3. применение (if)

if [[ "$PANEL" == "bitrix" ]]; then

    if grep -q "bad_bot" "$TARGET_CONF"; then
        echo "Правило уже есть в $TARGET_CONF"
    else
        if confirm "Добавить правило в $TARGET_CONF?"; then
            echo "$IF_BLOCK" >> "$TARGET_CONF"
            echo "Добавлено"
        fi
    fi

elif [[ "$PANEL" == "ispmanager" ]]; then

    # для ISP — отдельный include-файл
    if [[ -f "$TARGET_CONF" ]]; then
        echo "Файл уже существует: $TARGET_CONF"
    else
        if confirm "Создать файл с правилом $TARGET_CONF?"; then
            echo "$IF_BLOCK" > "$TARGET_CONF"
            echo "Создано"
        fi
    fi

fi

# 4. проверка и reload
if confirm "Проверить конфиг и перезагрузить nginx?"; then
    if nginx -t; then
        echo "OK, перезагрузка"
        nginx -s reload || systemctl reload nginx
    else
        echo "Ошибка конфигурации nginx"
        exit 1
    fi
fi
