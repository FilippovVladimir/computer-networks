@echo off
setlocal EnableExtensions DisableDelayedExpansion

rem --- Force UTF-8 for Russian text (if you see garbled text, change 65001 to 866) ---
chcp 65001 >nul

rem --- Admin check ---
net session >nul 2>&1
if not "%errorlevel%"=="0" (
  echo.
  echo [!] Запустите файл ^"от имени администратора^".
  echo.
  pause
  exit /b 1
)

:MENU
cls
echo =========================================
echo   Настройка сетевого интерфейса (Windows)
echo =========================================
echo 1^) Получить настройки по DHCP
echo 2^) Ввести вручную (статически)
echo 3^) Показать список интерфейсов
echo 0^) Выход
echo =========================================
set "choice="
set /p choice=Выберите 0, 1, 2 или 3: 

if "%choice%"=="1" goto DHCP
if "%choice%"=="2" goto STATIC
if "%choice%"=="3" goto LIST
if "%choice%"=="0" goto END

echo.
echo Неверный выбор. Повторите.
pause
goto MENU

:LIST
cls
echo Список интерфейсов:
echo -------------------
netsh interface show interface
echo -------------------
echo Подсказка: имя берите из столбца ^"Interface Name^".
echo.
pause
goto MENU

:ASKIF
set "iface="
echo.
set /p iface=Введите имя интерфейса (например: Ethernet или Wi-Fi): 
if not defined iface (
  echo Имя интерфейса не может быть пустым.
  goto ASKIF
)
exit /b 0

:DHCP
call :ASKIF
echo.
echo Переключаю ^"%iface%^" на DHCP...
netsh interface ip set address name="%iface%" source=dhcp >nul 2>&1
if errorlevel 1 (
  echo [!] Ошибка: не удалось включить DHCP для IP. Проверьте имя интерфейса.
  pause
  goto MENU
)
netsh interface ip set dns name="%iface%" source=dhcp >nul 2>&1
echo.
echo Обновляю аренду DHCP (ipconfig /renew)...
ipconfig /renew "%iface%" >nul 2>&1
echo Готово.
echo.
pause
goto MENU

rem ---- IPv4 validator ----
:VALIDIP
rem input: %1 ; returns errorlevel 0 if valid else 1
setlocal EnableExtensions DisableDelayedExpansion
set "ip=%~1"
for /f "tokens=1-4 delims=." %%a in ("%ip%") do (
  set "a=%%a" & set "b=%%b" & set "c=%%c" & set "d=%%d"
)
if "%a%"=="" endlocal & exit /b 1
if "%b%"=="" endlocal & exit /b 1
if "%c%"=="" endlocal & exit /b 1
if "%d%"=="" endlocal & exit /b 1

for %%X in (a b c d) do (
  for /f "delims=0123456789" %%z in ("!%%X!") do endlocal & exit /b 1
)

setlocal EnableDelayedExpansion
for %%X in (!a! !b! !c! !d!) do (
  if %%X LSS 0 endlocal & endlocal & exit /b 1
  if %%X GTR 255 endlocal & endlocal & exit /b 1
)
endlocal & endlocal & exit /b 0

:STATIC
call :ASKIF
cls
echo Настройка статических параметров для ^"%iface%^".
echo.

setlocal EnableExtensions DisableDelayedExpansion

:GETIP
set "ipaddr="
set /p ipaddr=Введите IPv4-адрес (например 192.168.0.120): 
if not defined ipaddr goto GETIP
call :VALIDIP "%ipaddr%"
if errorlevel 1 (
  echo [!] Неверный IPv4-адрес. Пример: 192.168.0.120
  goto GETIP
)

:GETMASK
set "mask="
set /p mask=Введите маску (например 255.255.255.0): 
if not defined mask goto GETMASK
call :VALIDIP "%mask%"
if errorlevel 1 (
  echo [!] Неверная маска. Пример: 255.255.255.0
  goto GETMASK
)

:GETGW
set "gw="
set /p gw=Введите шлюз (например 192.168.0.1): 
if not defined gw goto GETGW
call :VALIDIP "%gw%"
if errorlevel 1 (
  echo [!] Неверный шлюз. Пример: 192.168.0.1
  goto GETGW
)

:GETDNS1
set "dns1="
set /p dns1=Введите DNS (например 8.8.8.8 или 192.168.0.1): 
if not defined dns1 goto GETDNS1
call :VALIDIP "%dns1%"
if errorlevel 1 (
  echo [!] Неверный DNS. Пример: 8.8.8.8
  goto GETDNS1
)

:GETDNS2
set "dns2="
set /p dns2=Введите второй DNS (необязательно, Enter чтобы пропустить): 
if defined dns2 (
  call :VALIDIP "%dns2%"
  if errorlevel 1 (
    echo [!] Неверный второй DNS. Пример: 1.1.1.1
    goto GETDNS2
  )
)

echo.
echo Применяю статические параметры...
echo IP:   %ipaddr%
echo MASK: %mask%
echo GW:   %gw%
echo DNS:  %dns1% %dns2%
echo.

rem Apply address (single line, no line breaks!)
netsh interface ip set address name="%iface%" static %ipaddr% %mask% %gw% 1
if errorlevel 1 (
  echo [!] Ошибка при установке IP/маски/шлюза.
  echo     Проверьте имя интерфейса и корректность значений.
  endlocal
  pause
  goto MENU
)

rem Apply DNS
netsh interface ip set dns name="%iface%" static %dns1% primary >nul 2>&1
if defined dns2 (
  netsh interface ip add dns name="%iface%" %dns2% index=2 >nul 2>&1
)

endlocal

echo Готово. Текущие параметры интерфейса:
echo ----------------------------------------
ipconfig | findstr /i /c:"%iface%" /c:"IPv4" /c:"Subnet Mask" /c:"Default Gateway"
echo ----------------------------------------
echo.
echo Если интернет пропал: проверьте, что шлюз и DNS указаны верно.
echo Обычно шлюз = адрес роутера (например 192.168.0.1).
echo.
pause
goto MENU

:END
echo Выход.
endlocal
exit /b 0
