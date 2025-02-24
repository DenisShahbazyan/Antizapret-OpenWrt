colored_echo() {
    # Красный: 31                   |   Жёлтый: 33  |   Пурпурный: 35   |   # Белый: 37
    # Зелёный: 32 (по умолчанию)    |   Синий: 34   |   Голубой: 36 
    local text="$1"
    local color="${2:-32}"  
    echo -e "\e[1;${color}m${text}\e[0m"
}

rollback_firewall_rules() {
    for rule in Block_UDP_80 Block_UDP_443; do
        rule_entry=$(uci show firewall | grep "$rule")
        if [ -n "$rule_entry" ]; then
            rule_path=$(echo "$rule_entry" | cut -d'=' -f1)
            colored_echo "Удаляем правило firewall: $rule"
            uci delete "$rule_path"
        else
            colored_echo "Правило firewall $rule не найдено, пропускаем..."
        fi
    done
    uci commit firewall
    service firewall restart
}

rollback_firewall_rules
