#!/bin/bash

# Проверка наличия iperf3
check_iperf3() {
    if command -v iperf3 &> /dev/null; then
        echo "iperf3 уже установлен."
        return 0
    else
        echo "iperf3 не найден."
        return 1
    fi
}

# Установка iperf3
install_iperf3() {
    echo "Хотите установить iperf3? (y/n)"
    read -r choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        # Определяем ОС
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            case "$ID" in
                ubuntu|debian)
                    echo "Установка iperf3 на Debian/Ubuntu..."
                    apt update && apt install -y iperf3
                    ;;
                centos|rhel|fedora)
                    echo "Установка iperf3 на CentOS/RHEL/Fedora..."
                    yum install -y iperf3 || dnf install -y iperf3
                    ;;
                *)
                    echo "Неизвестная ОС. Установите iperf3 вручную."
                    exit 1
                    ;;
            esac
        else
            echo "Не удалось определить ОС. Установите iperf3 вручную."
            exit 1
        fi
    else
        echo "Тест скорости отменён."
        exit 1
    fi
}

# Выбор сервера для теста
choose_server() {
    echo "Выберите сервер для теста скорости:"
    echo "1) Использовать дефолтный сервер"
    echo "2) Ввести IP-адрес вручную"
    read -r choice

    case "$choice" in
        1)
            server_ip="94.250.249.223"
            ;;
        2)
            echo "Введите IP адрес удалённого сервера для теста скорости:"
            read -r server_ip
            ;;
        *)
            echo "Тест скорости отменён."
            exit 1
    esac
}

# Запуск теста скорости
run_speed_test() {
    choose_server

    echo "Запуск теста скорости с использованием iperf3..."

    # Тестируем скорость загрузки (download)
    echo "Тестируем скорость загрузки, обожди 10 сек"
    download_result=$(iperf3 -c "$server_ip" -R | grep -E 'sender|receiver' | tail -n 2)

    # Тестируем скорость выгрузки (upload)
    echo "Тестируем скорость выгрузки, обожди 10 сек"
    upload_result=$(iperf3 -c "$server_ip" | grep -E 'sender|receiver' | tail -n 2)

    # Выводим итоги теста
    echo "Итоги теста:"
    echo -e "Скорость загрузки\n$download_result"
    echo -e "Скорость выгрузки\n$upload_result"
}

# Основной процесс
main() {
    if ! check_iperf3; then
        install_iperf3
    fi

    run_speed_test
}

main
