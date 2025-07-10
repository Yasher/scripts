#!/bin/bash

# Функция для анализа по ботам
analyze_bots() {
    echo "Запущен анализ логов по ботам..."
    # Здесь вставляем твой скрипт, например:
    /root/scripts/analyze_bots.sh
}

# Функция для анализа по IP
analyze_ips() {
    echo "Запущен анализ логов по IP..."
    # Здесь свой скрипт или логика
    /root/scripts/analyze_ips.sh
}

# Функция для анализа ошибок
analyze_errors() {
    echo "Запущен анализ ошибок (error.log)..."
    # Здесь свой скрипт или логика
    /root/scripts/analyze_errors.sh
}

while true; do
    echo
    echo "============================"
    echo "      МЕНЮ ВЫБОРА СКРИПТОВ"
    echo "============================"
    echo "1) Анализ логов по ботам"
    echo "2) Анализ логов по IP"
    echo "3) Анализ ошибок (error.log)"
    echo "4) Выход"
    echo -n "Выберите вариант: "
    read choice

    case $choice in
        1)
            analyze_bots
            ;;
        2)
            analyze_ips
            ;;
        3)
            analyze_errors
            ;;
        4)
            echo "Выход из программы."
            break
            ;;
        *)
            echo "Неверный выбор, попробуйте снова."
            ;;
    esac
done
