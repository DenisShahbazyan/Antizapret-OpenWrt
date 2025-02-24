# Antizapret OpenWRT

Тестировал на роутере Routerich AX 3000 прошивка OpenWrt 23.05.5 r24106-10cc5fcd00

### Разблокировка сайтов с помощью DPI
Установка
```sh
wget -O - https://raw.githubusercontent.com/DenisShahbazyan/Antizapret-OpenWrt/refs/heads/master/src/dpi.sh | sh
```
Откат
```sh
wget -O - https://raw.githubusercontent.com/DenisShahbazyan/Antizapret-OpenWrt/refs/heads/master/src/dpi_restore.sh | sh
```

### Отключение исходящих пакетов quic на 80 и 443 портах
Установка
```sh
wget -O - https://raw.githubusercontent.com/DenisShahbazyan/Antizapret-OpenWrt/refs/heads/master/src/quic.sh | sh
```
Откат
```sh
wget -O - https://raw.githubusercontent.com/DenisShahbazyan/Antizapret-OpenWrt/refs/heads/master/src/quic_restore.sh | sh
```


### Разблокировка сайтов с помощью https-dns-proxy
Установка
```sh
wget -O - https://raw.githubusercontent.com/DenisShahbazyan/Antizapret-OpenWrt/refs/heads/master/src/dns.sh | sh
```
Откат
```sh
wget -O - https://raw.githubusercontent.com/DenisShahbazyan/Antizapret-OpenWrt/refs/heads/master/src/dns_restore.sh | sh
```

Потестить и проверить нужны ли задачи в кроне по перезапуску служб, или по перезапуску скриптов.