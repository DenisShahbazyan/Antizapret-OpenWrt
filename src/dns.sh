#!/bin/sh

CONFIG_DIR="/etc/config"
CONFIG_FILES="https-dns-proxy
dhcp"
BACKUP_DIR="/root/backup"

TMP_DIR="/root/antizapret-repo"

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

update_packages() {
    colored_echo "Upgrade packages..."

    opkg update
    opkg install unzip
}

backup_files() {
    for file in $CONFIG_FILES
    do
        if [ ! -f "$BACKUP_DIR/$file" ]
        then
            colored_echo "Backup file $file..."
            mkdir -p "$BACKUP_DIR"
            cp -f "$CONFIG_DIR/$file" "$BACKUP_DIR/$file"  
        fi
    done
}

replace_configs() {
    colored_echo "Replace config..."

    URL="https://raw.githubusercontent.com/DenisShahbazyan/Antizapret-OpenWrt/refs/heads/master/configs/https-dns-proxy"

    wget -O "$CONFIG_DIR/https-dns-proxy" "$URL" 
}

activate_https_dns_proxy_service() {
    colored_echo "Activate https-dns-proxy service..."

    service https-dns-proxy enable
    service https-dns-proxy start
}

download_list_domains() {
    colored_echo "Download list domains for dpi..."

    ARCHIVE_URL="https://github.com/DenisShahbazyan/Antizapret-OpenWrt/archive/refs/heads/master.zip"
    FOLDER_NAME="Antizapret-OpenWrt-master"

    rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"
    wget -O "$TMP_DIR/master.zip" "$ARCHIVE_URL"
    unzip "$TMP_DIR/master.zip" -d "$TMP_DIR"

    for file in "$TMP_DIR/$FOLDER_NAME/domains/dns/"*.txt; do
        cat "$file"
        echo
    done | grep -v '^$' | sort | uniq > "$TMP_DIR/dns_all_domains.txt"

    rm -rf "$TMP_DIR/$FOLDER_NAME"
    rm -f "$TMP_DIR/master.zip"
}

add_domains_to_uci() {
    DOMAIN_FILE="$TMP_DIR/dns_all_domains.txt"

    if [ ! -f "$DOMAIN_FILE" ]; then
        colored_echo "Файл $DOMAIN_FILE не найден!"
        return 1
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
            colored_echo "Домен $domain уже добавлен, пропускаем..." 33
        else
            colored_echo "Добавляем домен: $domain"
            uci add_list dhcp.cfg01411c.server="$pattern"
        fi
    done < "$DOMAIN_FILE"

    uci commit dhcp
    colored_echo "Обработка доменов завершена."
}

delete_tmp_files() {
    colored_echo "Delete tmp files..."

    rm -rf /root/antizapret-repo
}

restart_services() {
    colored_echo "Restart services..."

    service https-dns-proxy restart
    service dnsmasq restart
    service odhcpd restart
}

update_packages
backup_files
replace_configs
activate_https_dns_proxy_service
download_list_domains
add_domains_to_uci
delete_tmp_files

restart_services