#!/usr/bin/env bash

set -euo pipefail

FILE="/etc/nginx/vhosts-includes/bad_bot.conf"

# Если файл уже существует — вывести и выйти
if [[ -f "$FILE" ]]; then
    echo "Файл уже существует. Содержимое:"
    echo "--------------------------------"
    cat "$FILE"
    echo "--------------------------------"
    exit 0
fi

# Создаём директорию при необходимости
mkdir -p "$(dirname "$FILE")"

# Записываем содержимое
cat > "$FILE" <<'EOF'
if ($http_user_agent ~* (PerplexityBot|FriendlyCrawler|GPTBot|AhrefsBot|Amazonbot|PetalBot|SemrushBot|MJ12bot|Riddler|aiHitBot|trovitBot|Detectify|BLEXBot|dotbot|FlipboardProxy|rogerBot|LinkpadBot|Bytespider|Serpstatbot|ClaudeBot|Applebot)) {
    return 410;
}
EOF

echo "Файл создан: $FILE"

# Проверка конфигурации nginx перед перезагрузкой
if nginx -t; then
    echo "Конфигурация nginx корректна. Перезагрузка..."
    systemctl reload nginx
else
    echo "Ошибка в конфигурации nginx. Перезагрузка отменена."
    exit 1
fi
