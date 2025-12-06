# Подбробнее о настройке zapret

- [Порядок обработки (важно!)](#порядок-обработки-важно)
- [Что такое `<HOSTLIST>` и `<HOSTLIST_NOAUTO>`](#что-такое-hostlist-и-hostlist_noauto)
- [Что такое `--new`](#что-такое---new)
- [Разбор стратегий по профилям](#разбор-стратегий-по-профилям)
  - [Стратегия 1: HTTP (порт 80)](#стратегия-1-http-порт-80)
  - [Стратегия 2: HTTPS для Google (порт 443)](#стратегия-2-https-для-google-порт-443)
  - [Стратегия 3: QUIC для Google (UDP 443)](#стратегия-3-quic-для-google-udp-443)
  - [Стратегия 4: QUIC для остальных сайтов (UDP 443)](#стратегия-4-quic-для-остальных-сайтов-udp-443)
  - [Стратегия 5: HTTPS для остальных сайтов (порт 443)](#стратегия-5-https-для-остальных-сайтов-порт-443)
  - [Стратегия 6: Discord голосовые чаты (UDP 50000-50099)](#стратегия-6-discord-голосовые-чаты-udp-50000-50099)
  - [Стратегия 7: Универсальный UDP (1024-65535)](#стратегия-7-универсальный-udp-1024-65535)

## Порядок обработки (важно!)

| №   | Протокол        | Порт            | Условие применения            |
| --- | --------------- | --------------- | ----------------------------- |
| 1   | HTTP            | TCP 80          | Домен в HOSTLIST              |
| 2   | HTTPS Google    | TCP 443         | Домен в google.txt            |
| 3   | QUIC Google     | UDP 443         | Домен в google.txt            |
| 4   | QUIC остальные  | UDP 443         | Домен в HOSTLIST              |
| 5   | HTTPS остальные | TCP 443         | Домен в HOSTLIST              |
| 6   | Discord Voice   | UDP 50000-50099 | Протокол discord/stun         |
| 7   | Любой UDP       | UDP 1024-65535  | Fallback для всего остального |

Google-стратегии идут раньше общих, поэтому для Google применяется агрессивная стратегия, а для остальных — более мягкая.

## Что такое `<HOSTLIST>` и `<HOSTLIST_NOAUTO>`

Это **маркеры-плейсхолдеры**, которые система запуска zapret автоматически заменяет на реальные параметры.

### `<HOSTLIST>`

Заменяется на:

```
--hostlist=/opt/zapret/ipset/zapret-hosts-user.txt
--hostlist=/opt/zapret/ipset/zapret-hosts.txt
--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt
--hostlist-auto=/opt/zapret/ipset/zapret-hosts-auto.txt
```

**Включает:**

- Ваш пользовательский список доменов
- Скачанный список РКН
- Исключения
- **Автоматический список** (autohostlist) — домены, которые zapret сам определил как заблокированные

### `<HOSTLIST_NOAUTO>`

То же самое, но **без автоматического добавления** новых доменов в autohostlist.

Используется для QUIC, потому что автодетект блокировок по UDP работает менее надёжно и может давать ложные срабатывания.

## Что такое `--new`

`--new` — это разделитель, который **создаёт новый профиль (стратегию)** в nfqws.

### Как это работает

Без `--new` все параметры применяются к одному профилю. С `--new` можно задать **разные стратегии для разного трафика**:

```
--filter-tcp=80 --dpi-desync=fake        ← Профиль 1 (HTTP)
--new
--filter-tcp=443 --dpi-desync=split      ← Профиль 2 (HTTPS)
--new
--filter-udp=443 --dpi-desync=fake       ← Профиль 3 (QUIC)
```

## Разбор стратегий по профилям

### Стратегия 1: HTTP (порт 80)

```
--filter-tcp=80 <HOSTLIST>
--dpi-desync=fake,fakedsplit
--dpi-desync-autottl=2
--dpi-desync-fooling=badsum
```

**Назначение:** Обход блокировок HTTP-сайтов

### Стратегия 2: HTTPS для Google (порт 443)

```
--new
--filter-tcp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--ip-id=zero
--dpi-desync=fake,fakeddisorder
--dpi-desync-split-pos=10,midsld
--dpi-desync-repeats=11
--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin
--dpi-desync-fake-tls-mod=rnd,dupsid,sni=fonts.google.com
--dpi-desync-fake-tls=0x0F0F0F0F
--dpi-desync-fake-tls-mod=none
--dpi-desync-fakedsplit-pattern=/opt/zapret/files/fake/tls_clienthello_vk_com.bin
--dpi-desync-split-seqovl=336
--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_gosuslugi_ru.bin
--dpi-desync-fooling=badseq,badsum
--dpi-desync-badseq-increment=0
```

**Назначение:** Специальная агрессивная стратегия для сервисов Google (YouTube, Google Search и т.д.)

### Стратегия 3: QUIC для Google (UDP 443)

Эта стратегия у меня не работает, потому что я всегда отключаю QUIC - [Отключение исходящих UDP пакетов QUIC на 80 и 443 портах](https://github.com/DenisShahbazyan/Antizapret-OpenWrt?tab=readme-ov-file#%D0%BE%D1%82%D0%BA%D0%BB%D1%8E%D1%87%D0%B5%D0%BD%D0%B8%D0%B5-%D0%B8%D1%81%D1%85%D0%BE%D0%B4%D1%8F%D1%89%D0%B8%D1%85-udp-%D0%BF%D0%B0%D0%BA%D0%B5%D1%82%D0%BE%D0%B2-quic-%D0%BD%D0%B0-80-%D0%B8-443-%D0%BF%D0%BE%D1%80%D1%82%D0%B0%D1%85)

```
--new
--filter-udp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fake
--dpi-desync-repeats=11
--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin
```

**Назначение:** YouTube и Google-сервисы по протоколу QUIC (HTTP/3)

### Стратегия 4: QUIC для остальных сайтов (UDP 443)

```
--new
--filter-udp=443 <HOSTLIST_NOAUTO>
--dpi-desync=fake
--dpi-desync-repeats=11
```

**Назначение:** QUIC для всех остальных заблокированных сайтов (кроме Google)

### Стратегия 5: HTTPS для остальных сайтов (порт 443)

```
--new
--filter-tcp=443 <HOSTLIST>
--dpi-desync=multidisorder
--dpi-desync-split-pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1
```

**Назначение:** Общая стратегия для всех заблокированных HTTPS-сайтов

### Стратегия 6: Discord голосовые чаты (UDP 50000-50099)

```
--new
--filter-udp=50000-50099
--filter-l7=discord,stun
--dpi-desync=fake
```

**Назначение:** Голосовые/видео звонки Discord

**NFQWS_PORTS_UDP** добавить порты `50000-50099`

**custom.d script #50**

```
# this custom script runs desync to all stun packets
# NOTE: @ih requires nft 1.0.1+ and updated kernel version. it's confirmed to work on 5.15 (openwrt 23) and not work on 5.10 (openwrt 22)

# can override in config :
NFQWS_OPT_DESYNC_STUN="${NFQWS_OPT_DESYNC_STUN:---dpi-desync=fake --dpi-desync-repeats=2}"

alloc_dnum DNUM_STUN4ALL
alloc_qnum QNUM_STUN4ALL

zapret_custom_daemons()
{
	# $1 - 1 - add, 0 - stop

	local opt="--qnum=$QNUM_STUN4ALL $NFQWS_OPT_DESYNC_STUN"
	do_nfqws $1 $DNUM_STUN4ALL "$opt"
}
# size = 156 (8 udp header + 148 payload) && payload starts with 0x01000000
zapret_custom_firewall()
{
        # $1 - 1 - run, 0 - stop

	local f='-p udp -m u32 --u32'
	fw_nfqws_post $1 "$f 0>>22&0x3C@4>>16=28:65535&&0>>22&0x3C@12=0x2112A442&&0>>22&0x3C@8&0xC0000003=0" "$f 44>>16=28:65535&&52=0x2112A442&&48&0xC0000003=0" $QNUM_STUN4ALL
}
zapret_custom_firewall_nft()
{
        # stop logic is not required

	local f="udp length >= 28 @ih,32,32 0x2112A442 @ih,0,2 0 @ih,30,2 0"
	nft_fw_nfqws_post "$f" "$f" $QNUM_STUN4ALL
}
```

### Стратегия 7: Универсальный UDP (1024-65535)

```
--new
--filter-udp=1024-65535
--dpi-desync=fake
--dpi-desync-cutoff=d2
--dpi-desync-any-protocol=1
--dpi-desync-fake-unknown-udp=/opt/zapret/files/fake/quic_initial_www_google_com.bin
```

**Назначение:** Fallback для любого UDP (VPN, игры, мессенджеры и т.д.)

**NFQWS_PORTS_UDP** добавить порты `1024-65535`
