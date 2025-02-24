#!/bin/sh

CONFIG_DIR="/etc/config"
CONFIG_FILE="youtubeUnblock"
BACKUP_DIR="/root/backup"


colored_echo() {
    # Красный: 31                   |   Жёлтый: 33  |   Пурпурный: 35   |   # Белый: 37
    # Зелёный: 32 (по умолчанию)    |   Синий: 34   |   Голубой: 36 
    local text="$1"
    local color="${2:-32}"  
    echo -e "\e[1;${color}m${text}\e[0m"
}

update_packages() {
    colored_echo "Upgrade packages..."

    opkg update
    opkg upgrade youtubeUnblock
    opkg upgrade luci-app-youtubeUnblock
    opkg install unzip
}

backup_file() {
    if [ ! -f "$BACKUP_DIR/$CONFIG_FILE" ]
    then
        colored_echo "Backup file..."
        mkdir -p "$BACKUP_DIR"
        cp -f "$CONFIG_DIR/$CONFIG_FILE" "$BACKUP_DIR/$CONFIG_FILE"  
    fi
}

download_list_domains() {
    colored_echo "Download list domains for dpi..."

    TMP_DIR="/root/antizapret-repo"
    ARCHIVE_URL="https://github.com/DenisShahbazyan/Antizapret-OpenWrt/archive/refs/heads/master.zip"
    FOLDER_NAME="Antizapret-OpenWrt-master"

    rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"
    wget -O "$TMP_DIR/master.zip" "$ARCHIVE_URL"
    unzip "$TMP_DIR/master.zip" -d "$TMP_DIR"

    for file in "$TMP_DIR/$FOLDER_NAME/domains/dpi/normal/"*.txt; do
        cat "$file"
        echo
    done | grep -v '^$' | sort | uniq > "$TMP_DIR/dpi_normal_all_domains.txt"

    for file in "$TMP_DIR/$FOLDER_NAME/domains/dpi/quic_drop/"*.txt; do
        cat "$file"
        echo
    done | grep -v '^$' | sort | uniq > "$TMP_DIR/dpi_quic_drop_all_domains.txt"

    rm -rf "$TMP_DIR/$FOLDER_NAME"
    rm -f "$TMP_DIR/master.zip"
}

create_config_file_youtubeUnblock() {
    colored_echo "Create config file youtubeUnblock..."

    rm -f "$CONFIG_DIR/$CONFIG_FILE"
    output_file="$CONFIG_DIR/$CONFIG_FILE"

    # Первая часть: константное содержимое
    {
        echo "config youtubeUnblock 'youtubeUnblock'"
        echo -e "\toption conf_strat 'ui_flags'"
        echo -e "\toption packet_mark '32768'"
        echo -e "\toption queue_num '537'"
        echo -e "\toption silent '1'"
        echo -e "\toption no_ipv6 '1'"
        echo ""
    } > "$output_file"

    # Вторая часть: блок для youtube (константные строки до списка доменов)
    {
        echo "config section"
        echo -e "\toption name 'youtube'"
        echo -e "\toption enabled '1'"
        echo -e "\toption tls_enabled '1'"
        echo -e "\toption fake_sni '1'"
        echo -e "\toption faking_strategy 'pastseq'"
        echo -e "\toption fake_sni_seq_len '1'"
        echo -e "\toption fake_sni_type 'default'"
        echo -e "\toption frag 'tcp'"
        echo -e "\toption frag_sni_reverse '1'"
        echo -e "\toption frag_sni_faked '0'"
        echo -e "\toption frag_middle_sni '1'"
        echo -e "\toption frag_sni_pos '1'"
        echo -e "\toption seg2delay '0'"
        echo -e "\toption fk_winsize '0'"
        echo -e "\toption synfake '0'"
        echo -e "\toption sni_detection 'parse'"
        echo -e "\toption all_domains '0'"
    } >> "$output_file"

    # Подставляем домены из файла dpi_quic_drop_all_domains.txt
    if [ -f /root/antizapret-repo/dpi_quic_drop_all_domains.txt ]; then
        while IFS= read -r domain || [ -n "$domain" ]; do
            [ -z "$domain" ] && continue
            echo -e "\tlist sni_domains '$domain'" >> "$output_file"
        done < /root/antizapret-repo/dpi_quic_drop_all_domains.txt
    else
        echo "Файл /root/antizapret-repo/dpi_quic_drop_all_domains.txt не найден" >&2
    fi

    {
        echo -e "\toption quic_drop '1'"
        echo ""
    } >> "$output_file"

    # Третья часть: блок для other_zapret (константные строки до списка доменов)
    {
        echo "config section"
        echo -e "\toption name 'other_zapret'"
        echo -e "\toption tls_enabled '1'"
        echo -e "\toption fake_sni '1'"
        echo -e "\toption faking_strategy 'pastseq'"
        echo -e "\toption fake_sni_seq_len '1'"
        echo -e "\toption fake_sni_type 'default'"
        echo -e "\toption frag 'tcp'"
        echo -e "\toption frag_sni_reverse '1'"
        echo -e "\toption frag_sni_faked '0'"
        echo -e "\toption frag_middle_sni '1'"
        echo -e "\toption frag_sni_pos '1'"
        echo -e "\toption seg2delay '0'"
        echo -e "\toption fk_winsize '0'"
        echo -e "\toption synfake '0'"
        echo -e "\toption all_domains '0'"
        echo -e "\toption sni_detection 'parse'"
        echo -e "\toption quic_drop '0'"
        echo -e "\toption udp_mode 'fake'"
        echo -e "\toption udp_faking_strategy 'none'"
        echo -e "\toption udp_fake_seq_len '6'"
        echo -e "\toption udp_fake_len '64'"
        echo -e "\tlist udp_dport_filter '50000-50100 '"
        echo -e "\toption udp_filter_quic 'disabled'"
        echo -e "\toption enabled '1'"
    } >> "$output_file"

    # Подставляем домены из файла dpi_normal_all_domains.txt
    if [ -f /root/antizapret-repo/dpi_normal_all_domains.txt ]; then
        while IFS= read -r domain || [ -n "$domain" ]; do
            [ -z "$domain" ] && continue
            echo -e "\tlist sni_domains '$domain'" >> "$output_file"
        done < /root/antizapret-repo/dpi_normal_all_domains.txt
    else
        echo "Файл /root/antizapret-repo/dpi_normal_all_domains.txt не найден" >&2
    fi
}

delete_tmp_files() {
    colored_echo "Delete tmp files..."

    rm -rf /root/antizapret-repo
}

restart_service() {
    colored_echo "Restart service..."

    service youtubeUnblock restart
}

update_packages
backup_file
download_list_domains
create_config_file_youtubeUnblock
delete_tmp_files
restart_service
