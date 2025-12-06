# Настройка zapret v72+ (YouTube, Discord, WA, TG) + Games

Работает ютуб, дискорд, звонки в telegram и whatsapp.

1. Система -> Пакеты -> Обновить списки...
2. В поиске пишем zapret и устанавливаем только `zapret` и `luci-app-zapret`

После установки выйти и заново войти в панель управления роутером.

1. Службы -> Zapret
2. `Включить` и `Запустить`, если отключено

> В настройках нужно изменить только пункты ниже.

### Вкладка "NFQWS options"

**NFQWS_PORTS_UDP**

```
443,50000-50099,1024-65535
```

**NFQWS_OPT**

```
--filter-tcp=80 <HOSTLIST>
--dpi-desync=fake,fakedsplit
--dpi-desync-autottl=2
--dpi-desync-fooling=badsum
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
--new
--filter-udp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fake
--dpi-desync-repeats=11
--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin
--new
--filter-udp=443 <HOSTLIST_NOAUTO>
--dpi-desync=fake
--dpi-desync-repeats=11
--new
--filter-tcp=443 <HOSTLIST>
--dpi-desync=multidisorder
--dpi-desync-split-pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1
--new
--filter-udp=50000-50099
--filter-l7=discord,stun
--dpi-desync=fake
--new
--filter-udp=1024-65535
--dpi-desync=fake
--dpi-desync-cutoff=d2
--dpi-desync-any-protocol=1
--dpi-desync-fake-unknown-udp=/opt/zapret/files/fake/quic_initial_www_google_com.bin
```

### Вкладка "custom.d"

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

### Вкладка "Host list"

User excluded hostname entries файл /opt/zapret/ipset/zapret-hosts-user-exclude.txt

Добавить домены из файла [zapret-hosts-user-exclude.txt](./zapret-hosts-user-exclude.txt)
