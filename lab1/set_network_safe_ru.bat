@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: --- Кодировка консоли (чтобы русский текст отображался нормально) ---
:: Если у вас "кракозябры", замените 65001 на 866 или 1251 и сохраните файл в той же кодировке.
chcp 65001 >nul
title Настройка сети (DHCP / Статический IPv4)

:: --- Проверка прав администратора ---
net session >nul 2>&1
if not "%errorlevel%"=="0" (
  echo [ОШИБКА] Нужны права администратора.
  echo Запустите .bat через: ПКМ ^> "Запуск от имени администратора".
  echo.
  pause
  exit /b 1
)

:MENU
cls
echo ==========================================
echo   Настройка сетевого интерфейса Windows
echo ==========================================
echo 1) Получить настройки по DHCP
echo 2) Ввести вручную (статический IPv4)
echo 3) Показать список интерфейсов
echo 4) Показать текущие параметры интерфейса
echo 0) Выход
echo ------------------------------------------
set "choice="
set /p choice=Выберите пункт (0-4): 

if "%choice%"=="1" goto DHCP
if "%choice%"=="2" goto STATIC
if "%choice%"=="3" goto LIST
if "%choice%"=="4" goto SHOWCFG
if "%choice%"=="0" goto END
echo.
echo Неверный выбор. Повторите.
pause
goto MENU

:ASKIF
echo.
echo Введите имя интерфейса ТОЧНО как в системе (например: Ethernet или Wi-Fi).
echo Подсказка: пункт меню 3 покажет список имен.
set "ifname="
set /p ifname=Интерфейс: 
if not defined ifname (
  echo Имя не введено.
  goto ASKIF
)
exit /b 0

:LIST
cls
echo ===== Список интерфейсов =====
netsh interface show interface
echo.
echo (Если нужно точное имя: оно в колонке "Interface Name")
echo.
pause
goto MENU

:SHOWCFG
call :ASKIF
cls
echo ===== Текущие параметры: "%ifname%" =====
echo.
ipconfig /all | findstr /i /c:"adapter %ifname%" /c:"Description" /c:"Physical Address" /c:"DHCP Enabled" /c:"IPv4 Address" /c:"Subnet Mask" /c:"Default Gateway" /c:"DNS Servers"
echo.
echo (Если вывод неполный, используйте просто: ipconfig /all)
echo.
pause
goto MENU

:DHCP
call :ASKIF
cls
echo ===== Переключаю "%ifname%" на DHCP =====
echo.
echo Применяю DHCP для IP...
netsh interface ipv4 set address name="%ifname%" source=dhcp >nul 2>&1
if errorlevel 1 (
  echo [ОШИБКА] Не удалось включить DHCP для IP на "%ifname%".
  echo Проверьте имя интерфейса и права администратора.
  echo.
  pause
  goto MENU
)

echo Применяю DHCP для DNS...
netsh interface ipv4 set dnsservers name="%ifname%" source=dhcp >nul 2>&1
if errorlevel 1 (
  echo [ПРЕДУПРЕЖДЕНИЕ] Не удалось включить DHCP для DNS на "%ifname%".
  echo.
)

echo Обновляю аренду DHCP (может занять пару секунд)...
ipconfig /renew "%ifname%" >nul 2>&1

echo.
echo Готово. Проверить можно командой: ipconfig /all
echo.
pause
goto MENU

:STATIC
call :ASKIF
cls
echo ===== Статическая настройка IPv4: "%ifname%" =====
echo.
set "ipaddr="
set "mask="
set "gw="
set "dns1="
set "dns2="

set /p ipaddr=Введите IPv4-адрес (пример 192.168.0.120): 
call :VALIDATE_IP "%ipaddr%" ok
if /i not "!ok!"=="1" (
  echo [ОШИБКА] Неверный IPv4-адрес.
  pause
  goto MENU
)

set /p mask=Введите маску (пример 255.255.255.0): 
call :VALIDATE_IP "%mask%" ok
if /i not "!ok!"=="1" (
  echo [ОШИБКА] Неверная маска (должна быть IPv4 формата).
  pause
  goto MENU
)

set /p gw=Введите шлюз (пример 192.168.0.1): 
call :VALIDATE_IP "%gw%" ok
if /i not "!ok!"=="1" (
  echo [ОШИБКА] Неверный шлюз.
  pause
  goto MENU
)

set /p dns1=Введите DNS 1 (пример 8.8.8.8 или 192.168.0.1): 
call :VALIDATE_IP "%dns1%" ok
if /i not "!ok!"=="1" (
  echo [ОШИБКА] Неверный DNS 1.
  pause
  goto MENU
)

set /p dns2=Введите DNS 2 (необязательно, Enter чтобы пропустить): 
if defined dns2 (
  call :VALIDATE_IP "%dns2%" ok
  if /i not "!ok!"=="1" (
    echo [ОШИБКА] Неверный DNS 2.
    pause
    goto MENU
  )
)

echo.
echo Вы ввели:
echo   Интерфейс: %ifname%
echo   IP:        %ipaddr%
echo   Маска:     %mask%
echo   Шлюз:      %gw%
echo   DNS1:      %dns1%
if defined dns2 (
  echo   DNS2:      %dns2%
) else (
  echo   DNS2:      ^(не задан^)
)
echo.
set "confirm="
set /p confirm=Применить? (y/n): 
if /i not "%confirm%"=="y" (
  echo Отменено.
  pause
  goto MENU
)

echo.
echo Применяю статический IP...
netsh interface ipv4 set address name="%ifname%" source=static addr=%ipaddr% mask=%mask% gateway=%gw% gwmetric=1 >nul 2>&1
if errorlevel 1 (
  echo [ОШИБКА] Не удалось установить IP/маску/шлюз.
  echo Проверьте имя интерфейса и корректность значений.
  echo.
  pause
  goto MENU
)

echo Применяю DNS...
netsh interface ipv4 set dnsservers name="%ifname%" source=static address=%dns1% validate=no >nul 2>&1
if errorlevel 1 (
  echo [ОШИБКА] Не удалось установить DNS1.
  echo.
  pause
  goto MENU
)

if defined dns2 (
  netsh interface ipv4 add dnsservers name="%ifname%" address=%dns2% index=2 validate=no >nul 2>&1
)

echo.
echo Готово. Чтобы проверить:
echo   ipconfig /all
echo   ping 8.8.8.8
echo   ping ya.ru
echo.
pause
goto MENU

:: ---- Функция: проверка IPv4 формата (4 октета 0-255) ----
:VALIDATE_IP
setlocal EnableExtensions
set "ip=%~1"
set "ok=1"

for /f "tokens=1-4 delims=." %%a in ("%ip%") do (
  set "a=%%a" & set "b=%%b" & set "c=%%c" & set "d=%%d"
)

:: должно быть ровно 4 части
if "%a%"=="" set "ok=0"
if "%b%"=="" set "ok=0"
if "%c%"=="" set "ok=0"
if "%d%"=="" set "ok=0"

:: проверка: только цифры
for %%x in (a b c d) do (
  for /f "delims=0123456789" %%z in ("!%%x!") do set "ok=0"
)

:: проверка диапазона 0-255
for %%x in (a b c d) do (
  if "!%%x!"=="" set "ok=0"
  if "!ok!"=="1" (
    if !%%x! LSS 0 set "ok=0"
    if !%%x! GTR 255 set "ok=0"
  )
)

endlocal & set "%~2=%ok%"
exit /b 0

:END
echo Выход.
endlocal
exit /b 0
