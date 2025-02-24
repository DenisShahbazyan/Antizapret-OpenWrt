#!/bin/sh

CONFIG_DIR="/etc/config"
CONFIG_FILE="youtubeUnblock"
BACKUP_DIR="/root/backup"


colored_echo() {
    # Красный: 31
    # Зелёный: 32
    # Жёлтый: 33
    # Синий: 34
    # Пурпурный (Магента): 35
    # Голубой (Циан): 36
    # Белый: 37

    local text="$1"
    local color="${2:-32}"  # По умолчанию зелёный (код 32)
    echo -e "\e[1;${color}m${text}\e[0m"
}

restore_backup() {
    if [ -f "$BACKUP_DIR/$CONFIG_FILE" ]; then
        colored_echo "Восстановление резервной копии файла конфигурации..."
        cp -f "$BACKUP_DIR/$CONFIG_FILE" "$CONFIG_DIR/$CONFIG_FILE"
        rm -rf "$BACKUP_DIR/$CONFIG_FILE"
        colored_echo "Файл конфигурации восстановлен." 32
    else
        colored_echo "Резервная копия не найдена! Откат невозможен." 31
        exit 1
    fi
}

restart_service() {
    colored_echo "Перезапуск сервиса youtubeUnblock..."
    service youtubeUnblock restart
}

colored_echo "Начало процесса отката..." 36
restore_backup
restart_service
colored_echo "Откат завершён." 36