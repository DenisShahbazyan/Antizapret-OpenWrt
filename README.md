# Antizapret OpenWRT

Данный набор скриптов предназначен для обхода блокировок сайтов на роутерах под управлением OpenWRT. Все скрипты тестировались на роутере Routerich AX 3000 с прошивкой OpenWrt 23.05.5, и теоретически могут работать на любых устройствах, на которые можно установить необходимые приложения и пакеты.

---

#### Какие домены может разблокировать каждый скрипт можно посмотреть:
- Разблокировка через DPI (приложение youtubeUnblock) - [домены](./domains/dpi/)
- Отключение исходящих UDP пакетов QUIC на 80 и 443 портах - чтоб нас не спалили по этому протоколу, вдруг он работает на целевом сайте.
- Разблокировка через https-dns-proxy - [домены](./domains/dns/)
- Разблокировка через привязку IP (DHCP) - [домены](./domains/dhcp/)

Эти списки не конечные, добавил только то что нужно мне и то что вспомнил.

---

<details>
<summary><h3>Разблокировка через DPI (приложение youtubeUnblock)</h3></summary>
<b>Назначение:</b>

Обеспечивает обход блокировок с использованием технологии DPI (Deep Packet Inspection) через приложение youtubeUnblock.

<b>Установка</b>
```sh
wget -O - https://raw.githubusercontent.com/DenisShahbazyan/Antizapret-OpenWrt/refs/heads/master/src/dpi.sh | sh
```
<b>Откат</b>
```sh
wget -O - https://raw.githubusercontent.com/DenisShahbazyan/Antizapret-OpenWrt/refs/heads/master/src/dpi_restore.sh | sh
```
</details>


<details>
<summary><h3>Отключение исходящих UDP пакетов QUIC на 80 и 443 портах</h3></summary>
<b>Назначение:</b>

Блокирует исходящий UDP-трафик, связанный с протоколом QUIC, на портах 80 и 443, предотвращая использование альтернативных методов обхода блокировок.

<b>Установка</b>
```sh
wget -O - https://raw.githubusercontent.com/DenisShahbazyan/Antizapret-OpenWrt/refs/heads/master/src/quic.sh | sh
```
<b>Откат</b>
```sh
wget -O - https://raw.githubusercontent.com/DenisShahbazyan/Antizapret-OpenWrt/refs/heads/master/src/quic_restore.sh | sh
```
</details>


## Ниже нужно выбрать один из скриптов, сразу два скрипта не ставить!!!
**Примечание:** Эти способы нужны только тем, у кого нет VPN и они не гарантируют 100% разблокировку! Лучше использовать Podkop от ITDOG'а, или любой другой VPN.

<details>
<summary><h3>Разблокировка через https-dns-proxy</h3></summary>
<b>Назначение:</b>
Обеспечивает разблокировку сайтов за счёт корректной обработки DNS-запросов через сервис https-dns-proxy.

<b>Установка</b>
```sh
wget -O - https://raw.githubusercontent.com/DenisShahbazyan/Antizapret-OpenWrt/refs/heads/master/src/dns.sh | sh
```
<b>Откат</b>
```sh
wget -O - https://raw.githubusercontent.com/DenisShahbazyan/Antizapret-OpenWrt/refs/heads/master/src/dns_restore.sh | sh
```
<b>Примечание:</b>
Данный метод является альтернативным и не должен использоваться одновременно с методом привязки IP (см. ниже).
</details>


<details>
<summary><h3>Разблокировка через привязку IP (DHCP)</h3></summary>
<b>Назначение:</b>
Реализует обход блокировок путём добавления доменных имён в конфигурацию DHCP, где каждому домену назначается определённый IP-адрес.

<b>Установка</b>
```sh
wget -O - https://raw.githubusercontent.com/DenisShahbazyan/Antizapret-OpenWrt/refs/heads/master/src/dhcp.sh | sh
```
<b>Откат</b>
```sh
wget -O - https://raw.githubusercontent.com/DenisShahbazyan/Antizapret-OpenWrt/refs/heads/master/src/dhcp_restore.sh | sh
```
<b>Примечание:</b>
При выборе этого метода установка скрипта для https-dns-proxy не допускается, чтобы избежать конфликтов в конфигурации.
</details>


## TODO:
Потестить и проверить нужны ли задачи в кроне по перезапуску служб, или по перезапуску скриптов. Перезапуск скриптов более приорететен, так как могут добавится новые домены. Но если пользователь добавлял свои домены, они могут не сохранится - нужно проверить. 