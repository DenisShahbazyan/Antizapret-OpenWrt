#!/bin/sh

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

restart_firewall() {
    colored_echo "Перезапуск firewall..."

    service firewall restart > /dev/null 2>&1
}

add_firewall_rule_for_block_udp_80() {
    nameRule80="option name 'Block_UDP_80'"
    if ! grep -qi "$nameRule80" /etc/config/firewall; then
        colored_echo "Добавляем правило для блокировки UDP на порт 80..."
        uci add firewall rule
        uci set firewall.@rule[-1].name='Block_UDP_80'
        uci add_list firewall.@rule[-1].proto='udp'
        uci set firewall.@rule[-1].src='lan'
        uci set firewall.@rule[-1].dest='wan'
        uci set firewall.@rule[-1].dest_port='80'
        uci set firewall.@rule[-1].target='REJECT'
        uci commit firewall
        return 0
    fi
    return 1
}

add_firewall_rule_for_block_udp_443() {
    nameRule443="option name 'Block_UDP_443'"
    if ! grep -qi "$nameRule443" /etc/config/firewall; then
        colored_echo "Добавляем правило для блокировки UDP на порт 443..."
        uci add firewall rule
        uci set firewall.@rule[-1].name='Block_UDP_443'
        uci add_list firewall.@rule[-1].proto='udp'
        uci set firewall.@rule[-1].src='lan'
        uci set firewall.@rule[-1].dest='wan'
        uci set firewall.@rule[-1].dest_port='443'
        uci set firewall.@rule[-1].target='REJECT'
        uci commit firewall
        return 0
    fi
    return 1
}

add_firewall_rules() {
    changes=0
    add_firewall_rule_for_block_udp_80 && changes=1
    add_firewall_rule_for_block_udp_443 && changes=1

    [ $changes -eq 1 ] && restart_firewall
}

add_firewall_rules
