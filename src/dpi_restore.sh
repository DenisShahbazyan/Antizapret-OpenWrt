#!/bin/sh

CONFIG_DIR="/etc/config"
CONFIG_FILE="youtubeUnblock"
BACKUP_DIR="/root/backup"


colored_echo() {
    local text="$1"
    local color_name="${2:-green}"  # по умолчанию зелёный
    local lower_color
    local color_code

    # Приводим имя цвета к нижнему регистру с помощью tr
    lower_color=$(echo "$color_name" | tr '[:upper:]' '[:lower:]')

    case "$lower_color" in
        red)
            color_code=31
            ;;
        green)
            color_code=32
            ;;
        yellow)
            color_code=33
            ;;
        blue)
            color_code=34
            ;;
        purple)
            color_code=35
            ;;
        cyan)
            color_code=36
            ;;
        white)
            color_code=37
            ;;
        *)
            color_code=32  # Если передано неизвестное имя, используем зелёный
            ;;
    esac

    echo -e "\e[1;${color_code}m${text}\e[0m"
}


run_cmd() {
    local output
    output=$("$@" 2>&1)
    local status=$?
    if [ $status -ne 0 ]; then
        colored_echo "$output" red
        exit $status
    fi
}


restore_backup() {
    if [ -f "$BACKUP_DIR/$CONFIG_FILE" ]; then
        colored_echo "Восстановление резервной копии файла конфигурации..."
        cp -f "$BACKUP_DIR/$CONFIG_FILE" "$CONFIG_DIR/$CONFIG_FILE"

        # Проверка, что копирование прошло успешно
        if ! cmp "$BACKUP_DIR/$CONFIG_FILE" "$CONFIG_DIR/$CONFIG_FILE"; then
            colored_echo "Ошибка при копировании файла" red
            exit 1
        else
            colored_echo "Файл $BACKUP_DIR/$CONFIG_FILE успешно скопирован в $CONFIG_DIR/$CONFIG_FILE\n"
        fi
    else
        colored_echo "Резервная копия не найдена! Откат невозможен." red
        exit 1
    fi
}


delete_backup_file() {
    colored_echo "Удаление файла youtubeUnblock из бекапа...\n"

    rm -f "$BACKUP_DIR/$CONFIG_FILE"
}


restart_service() {
    colored_echo "Перезапуск сервиса youtubeUnblock...\n"

    service youtubeUnblock restart > /dev/null 2>&1
}


restore_backup
delete_backup_file
restart_service

colored_echo "Готово! Откат завершён." cyan