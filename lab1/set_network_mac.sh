#!/bin/bash
# macOS: DHCP или статическая настройка IPv4 (IP/Mask/Gateway/DNS)
# Работает через networksetup. Запускать с sudo.

set -e

if [[ $EUID -ne 0 ]]; then
  echo "Ошибка: запусти от администратора:"
  echo "sudo bash $0"
  exit 1
fi

echo "=============================="
echo "Настройка сетевого интерфейса (macOS)"
echo "1) Получить настройки по DHCP"
echo "2) Ввести вручную (статически)"
echo "3) Показать список интерфейсов (сетевых служб)"
echo "=============================="
read -r -p "Выберите 1, 2 или 3: " choice

show_services() {
  echo
  echo "Доступные сетевые службы (используй точное имя):"
  # Вывод networksetup иногда начинается со строки-заголовка
  networksetup -listallnetworkservices | sed '1{/^\*/d;}'
  echo
  echo "Подсказка: обычно это \"Wi-Fi\" или \"Ethernet\"."
  echo
}

case "$choice" in
  3)
    show_services
    exit 0
    ;;
  1|2)
    ;;
  *)
    echo "Неверный выбор."
    exit 1
    ;;
esac

read -r -p "Введите имя интерфейса (например: Wi-Fi или Ethernet): " service

# Проверим, что такая служба существует
if ! networksetup -listallnetworkservices | sed '1{/^\*/d;}' | grep -Fxq "$service"; then
  echo
  echo "Не найдено сетевой службы с именем: \"$service\""
  echo "Сейчас покажу список — выбери и введи точно так же:"
  show_services
  exit 1
fi

echo
echo "Текущие параметры для \"$service\":"
networksetup -getinfo "$service" || true
echo

if [[ "$choice" == "1" ]]; then
  echo "Переключаю \"$service\" на DHCP..."
  networksetup -setdhcp "$service"
  echo "Готово. Текущие параметры:"
  networksetup -getinfo "$service" || true
  exit 0
fi

# Статические параметры
read -r -p "Введите IPv4-адрес (например 192.168.0.116): " ipaddr
read -r -p "Введите маску (например 255.255.255.0): " mask
read -r -p "Введите шлюз (например 192.168.0.1): " gw
read -r -p "Введите DNS (через пробел, напр. 192.168.0.1 8.8.8.8): " dnsline

# Нормализуем DNS: если пусто — оставим как есть (не трогаем)
dns_arr=()
if [[ -n "$dnsline" ]]; then
  # shellcheck disable=SC2206
  dns_arr=($dnsline)
fi

echo
echo "Применяю статические параметры для \"$service\"..."
# Важно: именно такой порядок у networksetup
networksetup -setmanual "$service" "$ipaddr" "$mask" "$gw"

if [[ ${#dns_arr[@]} -gt 0 ]]; then
  networksetup -setdnsservers "$service" "${dns_arr[@]}"
else
  echo "DNS не введён — DNS не меняю (оставляю как было)."
fi

echo
echo "Готово. Текущие параметры:"
networksetup -getinfo "$service" || true

# echo
# echo "Если интернет пропал — почти всегда причина в неверном шлюзе или DNS."
# echo "Шлюз обычно равен адресу роутера (например 192.168.0.1)."