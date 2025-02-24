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
    service firewall restart > /dev/null 2>&1
}

rollback_firewall_rules
