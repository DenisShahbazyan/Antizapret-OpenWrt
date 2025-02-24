#!/bin/sh

CONFIG_DIR="/etc/config"
CONFIG_FILES="https-dns-proxy dhcp"
BACKUP_DIR="/root/backup"

TMP_DIR="/root/antizapret"
DNS_ALL_DOMAINS_FILE="$TMP_DIR/dns_all_domains.txt"


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


backup_files() {
    for file in $CONFIG_FILES
    do
        if [ ! -f "$BACKUP_DIR/$file" ]
        then
            colored_echo "Бекап файла $BACKUP_DIR/$file..."

            mkdir -p "$BACKUP_DIR"
            cp -f "$CONFIG_DIR/$file" "$BACKUP_DIR/$file"  

            # Проверка, что копирование прошло успешно
            if ! cmp -s "$CONFIG_DIR/$file" "$BACKUP_DIR/$file"; then
                colored_echo "Ошибка при копировании файла" red
                exit 1
            else
                colored_echo "Файл $CONFIG_DIR/$file успешно скопирован в $BACKUP_DIR/$file\n"
            fi
        fi
    done
}


replace_configs() {
    colored_echo "Замена конфига https-dns-proxy...\n"

    URL="https://raw.githubusercontent.com/DenisShahbazyan/Antizapret-OpenWrt/refs/heads/master/configs/https-dns-proxy"

    run_cmd wget -O "$CONFIG_DIR/https-dns-proxy" "$URL" 
}


activate_https_dns_proxy_service() {
    colored_echo "Активация сервиса https-dns-proxy...\n"

    service https-dns-proxy enable > /dev/null 2>&1
    service https-dns-proxy start > /dev/null 2>&1
}


download_list_domains() {
    colored_echo "Скачивание репозитория со списком доменов...\n"

    ARCHIVE_URL="https://github.com/DenisShahbazyan/Antizapret-OpenWrt/archive/refs/heads/master.zip"
    FOLDER_NAME="Antizapret-OpenWrt-master"

    rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"
    run_cmd wget -O "$TMP_DIR/master.zip" "$ARCHIVE_URL"
    run_cmd unzip "$TMP_DIR/master.zip" -d "$TMP_DIR"

    for file in "$TMP_DIR/$FOLDER_NAME/domains/dns/"*.txt; do
        cat "$file"
        echo
    done | grep -v '^$' | sort | uniq > "$DNS_ALL_DOMAINS_FILE"

    rm -rf "$TMP_DIR/$FOLDER_NAME"
    rm -f "$TMP_DIR/master.zip"
}


add_domains_to_uci() {
    colored_echo "Добавляем домены в конфиг..."

    if [ ! -f "$DNS_ALL_DOMAINS_FILE" ]; then
        colored_echo "Файл $DNS_ALL_DOMAINS_FILE не найден!"
        exit 1
    fi

    uci set dhcp.cfg01411c.strictorder='1'
    uci set dhcp.cfg01411c.filter_aaaa='1'
    uci add_list dhcp.cfg01411c.server='127.0.0.1#5053'
    uci add_list dhcp.cfg01411c.server='127.0.0.1#5054'
    uci add_list dhcp.cfg01411c.server='127.0.0.1#5055'
    uci add_list dhcp.cfg01411c.server='127.0.0.1#5056'

    while IFS= read -r domain; do
        domain=$(echo "$domain" | xargs)
        [ -z "$domain" ] && continue

        # Формируем строку, которую будем добавлять
        pattern="/$domain/127.0.0.1#5056"

        # Проверяем, есть ли уже такое правило в /etc/config/dhcp
        if grep -qF "$pattern" /etc/config/dhcp; then
            colored_echo "\t\tДомен $domain уже добавлен, пропускаем..." yellow
        else
            colored_echo "\tДобавляем домен: $domain" purple
            uci add_list dhcp.cfg01411c.server="$pattern"
        fi
    done < "$DNS_ALL_DOMAINS_FILE"

    uci commit dhcp
    colored_echo "Обработка доменов завершена.\n"
}


delete_tmp_files() {
    colored_echo "Удаление временных файлов...\n"

    rm -rf "$TMP_DIR"
}


restart_services() {
    colored_echo "Перезапуск сервисов...\n"

    service https-dns-proxy restart > /dev/null 2>&1
    service dnsmasq restart > /dev/null 2>&1
    service odhcpd restart > /dev/null 2>&1
}


update_packages
backup_files
replace_configs
activate_https_dns_proxy_service
download_list_domains
add_domains_to_uci
delete_tmp_files
restart_services

colored_echo "Готово! Конфигурация DNS обновлена." cyan