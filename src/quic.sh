colored_echo() {
    # Красный: 31                   |   Жёлтый: 33  |   Пурпурный: 35   |   # Белый: 37
    # Зелёный: 32 (по умолчанию)    |   Синий: 34   |   Голубой: 36 
    local text="$1"
    local color="${2:-32}"  
    echo -e "\e[1;${color}m${text}\e[0m"
}

restart_firewall() {
    colored_echo "Перезапуск firewall..."

    service firewall restart
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
