#!/bin/sh

CONFIG_DIR="/etc/config"
CONFIG_FILE="dhcp"
BACKUP_DIR="/root/backup"

TMP_DIR="/root/antizapret"
DHCP_ALL_DOMAINS_FILE="$TMP_DIR/dhcp_all_domains.txt"


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


update_packages() {
    colored_echo "Обновление пакетов..."

    run_cmd opkg update
    run_cmd opkg install unzip

    colored_echo "Все пакеты обновлены успешно.\n"
}


backup_file() {
    if [ ! -f "$BACKUP_DIR/$CONFIG_FILE" ]
    then
        colored_echo "Бекап файла $CONFIG_DIR/$CONFIG_FILE..."

        mkdir -p "$BACKUP_DIR"
        cp -f "$CONFIG_DIR/$CONFIG_FILE" "$BACKUP_DIR/$CONFIG_FILE" 

        # Проверка, что копирование прошло успешно
        if ! cmp -s "$CONFIG_DIR/$CONFIG_FILE" "$BACKUP_DIR/$CONFIG_FILE"; then
            colored_echo "Ошибка при копировании файла" red
            exit 1
        else
            colored_echo "Файл $CONFIG_DIR/$CONFIG_FILE успешно скопирован в $BACKUP_DIR/$CONFIG_FILE\n"
        fi
    fi
}


download_list_domains() {
    colored_echo "Скачивание репозитория со списком доменов...\n"

    ARCHIVE_URL="https://github.com/DenisShahbazyan/Antizapret-OpenWrt/archive/refs/heads/master.zip"
    FOLDER_NAME="Antizapret-OpenWrt-master"

    rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"
    run_cmd wget -O "$TMP_DIR/master.zip" "$ARCHIVE_URL"
    run_cmd unzip "$TMP_DIR/master.zip" -d "$TMP_DIR"

    for file in "$TMP_DIR/$FOLDER_NAME/domains/vpn/"*.txt; do
        cat "$file"
        echo
    done | grep -v '^$' | sort | uniq > "$DHCP_ALL_DOMAINS_FILE"

    rm -rf "$TMP_DIR/$FOLDER_NAME"
    rm -f "$TMP_DIR/master.zip"
}


get_actual_ip() {
    local domain="$1"
    
    local dns_server="83.220.169.155"

    # Запускаем nslookup и ищем IPv4-адреса
    ip=$(nslookup "$domain" "$dns_server" 2>/dev/null | awk '/^Address: / { print $2 }' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | tail -n1)

    local default_ip="94.131.119.85"

    # Если IP найден, выводим его, иначе ставим $default_ip
    if [ -z "$ip" ]; then
        echo "$default_ip"
    else
        echo "$ip"
    fi
}


check_and_add_domain_permanent_name() {
    local domain="$1"
    local ip="$2"
    local nameRule="option name '$domain'"

    # Проверяем наличие домена в конфигурационном файле
    if grep -iq "$nameRule" /etc/config/dhcp; then
        colored_echo "\t\tДомен '$domain' уже существует, пропускаем..." yellow
    else
        uci add dhcp domain > /dev/null 2>&1
        uci set dhcp.@domain[-1].name="$domain"
        uci set dhcp.@domain[-1].ip="$ip"
        colored_echo "\tДомен '$domain' добавлен с IP $ip" purple
    fi
}


add_domains_to_uci() {
    colored_echo "Добавляем домены в конфиг..."

    if [ ! -f "$DHCP_ALL_DOMAINS_FILE" ]; then
        colored_echo "Файл $DHCP_ALL_DOMAINS_FILE не найден!"
        exit 1
    fi

    while IFS= read -r domain; do
        # Удаляем лишние пробелы
        domain=$(echo "$domain" | xargs)
        [ -z "$domain" ] && continue

        local current_ip=$(get_actual_ip "$domain")
        check_and_add_domain_permanent_name "$domain" "$current_ip"
    done < "$DHCP_ALL_DOMAINS_FILE"

    uci commit dhcp

    colored_echo "Обработка доменов завершена.\n"
}


delete_tmp_files() {
    colored_echo "Удаление временных файлов...\n"

    rm -rf "$TMP_DIR"
}


restart_service() {
    colored_echo "Перезапуск сервисов...\n"

    service dnsmasq restart > /dev/null 2>&1
    service odhcpd restart > /dev/null 2>&1
}


update_packages
backup_file
download_list_domains
add_domains_to_uci
delete_tmp_files
restart_service

colored_echo "Готово! Конфигурация dhcp обновлена." cyan
