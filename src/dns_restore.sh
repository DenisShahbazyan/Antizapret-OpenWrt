#!/bin/sh

CONFIG_DIR="/etc/config"
CONFIG_FILES="https-dns-proxy dhcp"
BACKUP_DIR="/root/backup"

colored_echo() {
    # Красный: 31                   |   Жёлтый: 33  |   Пурпурный: 35   |   # Белый: 37
    # Зелёный: 32 (по умолчанию)    |   Синий: 34   |   Голубой: 36 
    local text="$1"
    local color="${2:-32}"  
    echo -e "\e[1;${color}m${text}\e[0m"
}

restore_configs() {
    for file in $CONFIG_FILES; do
        if [ -f "$BACKUP_DIR/$file" ]; then
            colored_echo "Восстанавливаем конфигурационный файл $file..."
            cp -f "$BACKUP_DIR/$file" "$CONFIG_DIR/$file"
        else
            colored_echo "Резервная копия файла $file не найдена в $BACKUP_DIR!" 31
        fi
    done
}


rollback_services() {
    service https-dns-proxy stop
    service dnsmasq restart
    service odhcpd restart
}

rollback_cleanup() {
    colored_echo "Удаляем временные файлы (если они существуют)..."
    rm -rf /root/antizapret-repo
}


colored_echo "Начинаем откат изменений..."
restore_configs
rollback_cleanup
rollback_services
colored_echo "Откат завершён."

