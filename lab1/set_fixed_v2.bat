@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: Force Russian-friendly console (Windows-1251). If your system uses UTF-8, you may change to 65001.
chcp 1251 >nul

:: --- Admin check ---
net session >nul 2>&1
if not "%errorlevel%"=="0" (
  echo [ОШИБКА] Запустите файл от имени администратора.
  echo Подсказка: ПКМ по .bat ^> "Запуск от имени администратора"
  pause
  exit /b 1
)

:MENU
cls
echo =============================
echo Настройка сетевого интерфейса
echo 1) Получить настройки по DHCP
echo 2) Ввести вручную (статически)
echo 3) Показать список интерфейсов
echo 0) Выход
echo =============================
set /p choice="Выберите 0, 1, 2 или 3: "

if "%choice%"=="0" exit /b 0

if "%choice%"=="3" (
  echo.
  echo Доступные интерфейсы:
  netsh interface show interface
  echo.
  pause
  goto :MENU
)

set /p interface="Введите имя интерфейса (например: Ethernet или Wi-Fi): "

:: Trim quotes if user typed them
set "interface=%interface:"=%"

if "%choice%"=="1" (
  echo.
  echo [*] Включаю DHCP для IP и DNS на "%interface%" ...
  netsh interface ipv4 set address name="%interface%" source=dhcp
  netsh interface ipv4 set dnsservers name="%interface%" source=dhcp
  goto :SHOW
)

if "%choice%"=="2" (
  echo.
  set /p ipaddr="Введите IP-адрес (пример 192.168.0.120): "
  set /p mask="Введите маску (пример 255.255.255.0): "
  set /p gw="Введите шлюз (пример 192.168.0.1): "
  set /p dns="Введите DNS (пример 8.8.8.8 или 192.168.0.1): "

  :: Remove possible spaces
  for %%V in (ipaddr mask gw dns) do (
    for /f "tokens=* delims= " %%A in ("!%%V!") do set "%%V=%%A"
  )

  echo.
  echo [*] Применяю статические параметры...
  echo     IP  = !ipaddr!
  echo     MSK = !mask!
  echo     GW  = !gw!
  echo     DNS = !dns!
  echo.

  :: IMPORTANT: must be ONE LINE, otherwise netsh treats next line as new command.
  netsh interface ipv4 set address name="%interface%" source=static address=!ipaddr! mask=!mask! gateway=!gw! gwmetric=1
  if not "!errorlevel!"=="0" (
    echo.
    echo [ОШИБКА] Не удалось установить IP. Проверьте:
    echo  - имя интерфейса (пункт 3 показывает точное имя),
    echo  - что IP/маска/шлюз введены корректно,
    echo  - что IP не конфликтует с другим устройством.
    echo.
    pause
    goto :SHOW
  )

  netsh interface ipv4 set dnsservers name="%interface%" source=static address=!dns! validate=no
  if not "!errorlevel!"=="0" (
    echo.
    echo [ПРЕДУПРЕЖДЕНИЕ] DNS мог не примениться. Попробуйте ввести другой DNS.
    echo.
  )
  goto :SHOW
)

echo.
echo Неверный выбор. Попробуйте снова.
pause
goto :MENU

:SHOW
echo.
echo =============================
echo Текущие параметры (ipconfig):
echo =============================
ipconfig /all | more
echo.
pause
goto :MENU
