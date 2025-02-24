#!/bin/sh

CONFIG_DIR="/etc/config"
CONFIG_FILES="https-dns-proxy dhcp"
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


restore_configs() {
    for file in $CONFIG_FILES; do
        if [ -f "$BACKUP_DIR/$file" ]; then
            colored_echo "Восстанавливаем конфигурационный файл $file..."
            cp -f "$BACKUP_DIR/$file" "$CONFIG_DIR/$file"

            # Проверка, что копирование прошло успешно
            if ! cmp "$BACKUP_DIR/$file" "$CONFIG_DIR/$file"; then
                colored_echo "Ошибка при копировании файла" red
                exit 1
            else
                colored_echo "Файл $BACKUP_DIR/$file успешно скопирован в $CONFIG_DIR/$file\n"
            fi  
        else
            colored_echo "Резервная копия файла $file не найдена! Откат невозможен." red
            exit 1
        fi
    done
}


delete_backup_files() {
    for file in $CONFIG_FILES; do
        if [ -f "$BACKUP_DIR/$file" ]; then
            colored_echo "Удаляем бекап файл $file..."
            rm -f "$BACKUP_DIR/$file"
        fi
    done
    colored_echo "\n"
}


restart_services() {
    colored_echo "Перезапуск сервисов...\n"

    service https-dns-proxy stop > /dev/null 2>&1
    service https-dns-proxy disable > /dev/null 2>&1
    service dnsmasq restart > /dev/null 2>&1
    service odhcpd restart > /dev/null 2>&1
}


restore_configs
delete_backup_files
restart_services

colored_echo "Готово! Откат завершён." cyan
