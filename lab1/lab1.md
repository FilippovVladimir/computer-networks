# Практическая работа №1  
## Консольные средства настройки сетевых компонентов в ОС Windows (Windows 10)

## 1. Проверка компонентов сетевого подключения

Открытие окна сетевых подключений:
`Win + R → ncpa.cpl → Enter → ПКМ по активному подключению → Свойства`

Проверены компоненты:

- Клиент для сетей Microsoft  
- Служба доступа к файлам и принтерам Microsoft  
- Протокол Интернета версии 4 (TCP/IPv4)

![Свойства подключения](01_properties.png)

### Запрет доступа по SMB

Отключена служба:
- «Служба доступа к файлам и принтерам Microsoft»

![Отключение SMB](02_disable_smb.png)

## 2. Использование утилиты ping

Выполненные команды:

```
ping google.com
```

![Ping обычный](03_ping_default.png)

```
ping -n 5 google.com
```

![Ping -n 5](04_ping_n5.png)

```
ping -l 1000 google.com
```

![Ping -l](05_ping_size.png)

```
ping -t google.com
```

![Ping -t](06_ping_t.png)

```
ping -n 5 google.com > C:\ping_results.txt
```

![Ping в файл](07_ping_saved_file.png)

## 3. Использование утилиты tracert

```
tracert google.com
```

![Tracert обычный](08_tracert_default.png)

```
tracert -h 10 google.com
```

![Tracert -h](09_tracert_h.png)

```
tracert -w 2000 google.com
```

![Tracert -w](10_tracert_w.png)

## 4. Использование ipconfig

```
ipconfig
```

![ipconfig](11_ipconfig_basic.png)

```
ipconfig /all
```

![ipconfig all](12_ipconfig_all.png)

```
ipconfig /flushdns
```

![flushdns](13_ipconfig_flushdns.png)

```
ipconfig /release
```

![release](14_ipconfig_release.png)

```
ipconfig /renew
```

![renew](15_ipconfig_renew.png)

## 5. Использование команды net

```
net view
```

![net view](16_net_view.png)

```
net share
```

![net share](17_net_share.png)

```
net user
```

![net user](18_net_user.png)

```
net localgroup
```

![net localgroup](19_net_localgroup.png)

```
net statistics workstation
```

![net statistics](20_net_statistics.png)

```
net use R: \SRV\TEST
```

![net use](21_net_use.png)

## 6. Использование netsh

```
netsh interface show interface
```

![netsh show](22_netsh_show.png)

### Режим DHCP

```
netsh interface ip set address name="Ethernet" source=dhcp
netsh interface ip set dns name="Ethernet" source=dhcp
```

![После DHCP](23_after_dhcp.png)

### Статический IP

```
netsh interface ip set address name="Ethernet" static 192.168.0.111 255.255.255.0 192.168.0.1
netsh interface ip set dns name="Ethernet" static 192.168.0.1
```

![После static](24_after_static.png)

---

# Ответы на вопросы

## Как запретить доступ через GUI?
Снять галочку «Служба доступа к файлам и принтерам Microsoft» в свойствах сетевого подключения.

## Как запретить доступ к ресурсам других ПК?
Снять галочку «Клиент для сетей Microsoft».

## Как узнать DNS?
Команда:
```
ipconfig /all
```

## Назначение net use
Подключение сетевых ресурсов:
```
net use R: \SRV\TEST
```

## Переименование интерфейса в PowerShell
```
Rename-NetAdapter -Name "Ethernet" -NewName "MyNet"
```

## Режимы duplex
- Half-duplex — передача или прием по очереди  
- Full-duplex — одновременная передача и прием  

## Вывод

В ходе работы были изучены консольные утилиты Windows для диагностики и настройки сети, выполнены проверки доступности узлов, определён маршрут передачи пакетов, исследованы параметры IP-конфигурации и произведена настройка интерфейса в режимах DHCP и статической адресации.
