#!/bin/sh

CONFIG_DIR="/etc/config"
CONFIG_FILE="youtubeUnblock"
BACKUP_DIR="/root/backup"

TMP_DIR="/root/antizapret"
DPI_NORMAL_ALL_DOMAINS_FILE="$TMP_DIR/dpi_normal_all_domains.txt"
DPI_QUIC_DROP_ALL_DOMAINS_FILE="$TMP_DIR/dpi_quic_drop_all_domains.txt"
DPI_WA_TG_ALL_DOMAINS_FILE="$TMP_DIR/dpi_wa_tg_all_domains.txt"


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
    run_cmd opkg upgrade youtubeUnblock
    run_cmd opkg upgrade luci-app-youtubeUnblock
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

    for file in "$TMP_DIR/$FOLDER_NAME/domains/dpi/normal/"*.txt; do
        cat "$file"
        echo
    done | grep -v '^$' | sort | uniq > "$DPI_NORMAL_ALL_DOMAINS_FILE"

    for file in "$TMP_DIR/$FOLDER_NAME/domains/dpi/quic_drop/"*.txt; do
        cat "$file"
        echo
    done | grep -v '^$' | sort | uniq > "$DPI_QUIC_DROP_ALL_DOMAINS_FILE"

    for file in "$TMP_DIR/$FOLDER_NAME/domains/dpi/calls/"*.txt; do
        cat "$file"
        echo
    done | grep -v '^$' | sort | uniq > "$DPI_WA_TG_ALL_DOMAINS_FILE"

    rm -rf "$TMP_DIR/$FOLDER_NAME"
    rm -f "$TMP_DIR/master.zip"
}


create_config_file_youtubeUnblock() {
    colored_echo "Создание конфигурационного файла youtubeUnblock...\n"

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
    if [ -f "$DPI_QUIC_DROP_ALL_DOMAINS_FILE" ]; then
        while IFS= read -r domain || [ -n "$domain" ]; do
            [ -z "$domain" ] && continue
            echo -e "\tlist sni_domains '$domain'" >> "$output_file"
        done < "$DPI_QUIC_DROP_ALL_DOMAINS_FILE"
    else
        colored_echo "Файл $DPI_QUIC_DROP_ALL_DOMAINS_FILE не найден" red
        exit 1
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
    if [ -f "$DPI_NORMAL_ALL_DOMAINS_FILE" ]; then
        while IFS= read -r domain || [ -n "$domain" ]; do
            [ -z "$domain" ] && continue
            echo -e "\tlist sni_domains '$domain'" >> "$output_file"
        done < "$DPI_NORMAL_ALL_DOMAINS_FILE"
    else
        colored_echo "Файл $DPI_NORMAL_ALL_DOMAINS_FILE не найден" red
        exit 1
    fi

    {
        echo ""
    } >> "$output_file"

    # Четвертая часть: блок для calls (константные строки до списка доменов)
    {
        echo "config section"
        echo -e "\toption name 'calls'"
        echo -e "\toption tls_enabled '0'"
        echo -e "\toption all_domains '0'"
    } >> "$output_file"

    # Подставляем домены из файла dpi_wa_tg_all_domains.txt
    # Подставляем домены из файла dpi_quic_drop_all_domains.txt
    if [ -f "$DPI_WA_TG_ALL_DOMAINS_FILE" ]; then
        while IFS= read -r domain || [ -n "$domain" ]; do
            [ -z "$domain" ] && continue
            echo -e "\tlist sni_domains '$domain'" >> "$output_file"
        done < "$DPI_WA_TG_ALL_DOMAINS_FILE"
    else
        colored_echo "Файл $DPI_WA_TG_ALL_DOMAINS_FILE не найден" red
        exit 1
    fi

    {
        echo -e "\toption sni_detection 'parse'"
        echo -e "\toption quic_drop '0'"
        echo -e "\toption udp_mode 'fake'"
        echo -e "\toption udp_faking_strategy 'none'"
        echo -e "\toption udp_fake_seq_len '6'"
        echo -e "\toption udp_fake_len '64'"
        echo -e "\toption udp_filter_quic 'disabled'"
        echo -e "\toption enabled '1'"
        echo -e "\toption udp_stun_filter '1'"
    } >> "$output_file"
}


delete_tmp_files() {
    colored_echo "Удаление временных файлов...\n"

    rm -rf "$TMP_DIR"
}


restart_service() {
    colored_echo "Перезапуск сервиса youtubeUnblock...\n"

    service youtubeUnblock restart > /dev/null 2>&1
}

update_packages
backup_file
download_list_domains
create_config_file_youtubeUnblock
delete_tmp_files
restart_service

colored_echo "Готово! Конфигурация youtubeUnblock обновлена." cyan
