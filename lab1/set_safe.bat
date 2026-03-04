@echo off
chcp 1251 >nul
setlocal EnableExtensions EnableDelayedExpansion

:: ==============================
::  Safe Network Configurator
::  - Works on Windows 10/11
::  - Prevents "internet fell off" by:
::      * admin check
::      * interface listing
::      * backup of current config
::      * validation of IPv4/mask/gw/dns
::      * warning if IP already in use
:: ==============================

:: --- Admin check ---
net session >nul 2>&1
if not "%errorlevel%"=="0" (
  echo [ОШИБКА] Нужны права администратора.
  echo Запусти файл через: ПКМ ^> "Запуск от имени администратора".
  pause
  exit /b 1
)

:: --- Working folder for logs/backups ---
set "WORKDIR=%~dp0net_backup"
if not exist "%WORKDIR%" mkdir "%WORKDIR%" >nul 2>&1

:: --- Helper: timestamp ---
for /f "tokens=1-3 delims=." %%a in ("%date%") do set "D=%%c-%%b-%%a"
for /f "tokens=1-3 delims=:" %%a in ("%time%") do set "T=%%a-%%b-%%c"
set "STAMP=%D%_%T%"
set "BACKUP=%WORKDIR%\backup_%STAMP%.txt"

:: --- Menu ---
:MENU
cls
echo ============================================
echo  Настройка сетевого интерфейса (SAFE)
echo ============================================
echo 1) Включить DHCP (IP + DNS)  [рекомендуется]
echo 2) Задать статический IP (с проверками)
echo 3) Показать список интерфейсов
echo 4) Показать текущие параметры (ipconfig)
echo 5) Выход
echo ============================================
set /p choice=Выберите 1-5: 

if "%choice%"=="1" goto DHCP
if "%choice%"=="2" goto STATIC
if "%choice%"=="3" goto LIST
if "%choice%"=="4" goto IPCONFIG
if "%choice%"=="5" goto END
echo Неверный выбор.
pause
goto MENU

:LIST
cls
echo ==== Интерфейсы (netsh) ====
netsh interface show interface
echo.
echo Подсказка: имя нужно вводить ТОЧНО как в колонке "Interface Name".
pause
goto MENU

:IPCONFIG
cls
ipconfig /all
echo.
pause
goto MENU

:: --- Backup current configuration ---
:DO_BACKUP
echo ==== Backup (%date% %time%) ====>>"%BACKUP%"
echo [netsh ip show config]>>"%BACKUP%"
netsh interface ipv4 show config name="%IFACE%" >>"%BACKUP%" 2>&1
echo.>>"%BACKUP%"
echo [netsh dns show config]>>"%BACKUP%"
netsh interface ipv4 show dnsservers name="%IFACE%" >>"%BACKUP%" 2>&1
echo.>>"%BACKUP%"
exit /b 0

:DHCP
cls
echo Введите имя интерфейса (например: Ethernet или Wi-Fi)
set /p IFACE=Интерфейс: 
if "%IFACE%"=="" goto MENU

call :DO_BACKUP

echo.
echo Применяю DHCP для "%IFACE%" ...
netsh interface ipv4 set address name="%IFACE%" source=dhcp >nul 2>&1
if not "%errorlevel%"=="0" (
  echo [ОШИБКА] Не удалось включить DHCP для IP. Проверь имя интерфейса.
  echo Попробуй пункт 3) и скопируй имя точно.
  pause
  goto MENU
)

netsh interface ipv4 set dnsservers name="%IFACE%" source=dhcp >nul 2>&1
if not "%errorlevel%"=="0" (
  echo [ПРЕДУПРЕЖДЕНИЕ] DNS через DHCP не применился. Попробую очистить DNS...
  netsh interface ipv4 delete dnsservers name="%IFACE%" all >nul 2>&1
)

ipconfig /renew >nul 2>&1
ipconfig /flushdns >nul 2>&1

echo Готово. Backup сохранён: "%BACKUP%"
echo.
netsh interface ipv4 show config name="%IFACE%"
echo.
pause
goto MENU

:: --- Validators ---
:IS_IPV4
:: input: %1 ; output: sets OK=1/0
set "OK=0"
set "S=%~1"
for /f "tokens=1-4 delims=." %%a in ("%S%") do (
  set "A=%%a" & set "B=%%b" & set "C=%%c" & set "D=%%d"
)
if "%A%"=="" exit /b 0
if "%B%"=="" exit /b 0
if "%C%"=="" exit /b 0
if "%D%"=="" exit /b 0
for %%x in (A B C D) do (
  for /f "delims=0123456789" %%z in ("!%%x!") do exit /b 0
  if !%%x! LSS 0 exit /b 0
  if !%%x! GTR 255 exit /b 0
)
set "OK=1"
exit /b 0

:IS_MASK
:: Accepts dotted mask; checks it's a valid contiguous mask
set "OK=0"
set "M=%~1"
call :IS_IPV4 "%M%"
if not "!OK!"=="1" exit /b 0

:: Convert mask to binary string length 32 and ensure no 01 pattern after first 0
set "BIN="
for /f "tokens=1-4 delims=." %%a in ("%M%") do (
  for %%o in (%%a %%b %%c %%d) do (
    set "O=%%o"
    call :OCT2BIN !O!
    set "BIN=!BIN!!OBIN!"
  )
)
:: must be 32 chars and match 1*0*
echo !BIN!| findstr /r "^[1][1]*[0][0]*$" >nul
if "!errorlevel!"=="0" set "OK=1"
exit /b 0

:OCT2BIN
set "OBIN="
set /a N=%1
for /L %%i in (7,-1,0) do (
  set /a BIT=(N>>%%i) ^& 1
  set "OBIN=!OBIN!!BIT!"
)
exit /b 0

:IP_IN_USE
:: Ping IP once; if replies -> INUSE=1 else 0
set "INUSE=0"
set "PIP=%~1"
ping -n 1 -w 300 "%PIP%" | findstr /i "ttl=" >nul
if "%errorlevel%"=="0" set "INUSE=1"
exit /b 0

:STATIC
cls
echo Введите имя интерфейса (например: Ethernet или Wi-Fi)
set /p IFACE=Интерфейс: 
if "%IFACE%"=="" goto MENU

call :DO_BACKUP

echo.
set /p IPADDR=Введите IP-адрес (например 192.168.0.120): 
call :IS_IPV4 "%IPADDR%"
if not "!OK!"=="1" (
  echo [ОШИБКА] IP-адрес введён неверно.
  pause
  goto MENU
)

set /p MASK=Введите маску (например 255.255.255.0): 
call :IS_MASK "%MASK%"
if not "!OK!"=="1" (
  echo [ОШИБКА] Маска введена неверно (должна быть корректной подсетевой маской).
  pause
  goto MENU
)

set /p GW=Введите шлюз (например 192.168.0.1): 
call :IS_IPV4 "%GW%"
if not "!OK!"=="1" (
  echo [ОШИБКА] Шлюз введён неверно.
  pause
  goto MENU
)

set /p DNS1=Введите DNS1 (например 192.168.0.1 или 8.8.8.8): 
call :IS_IPV4 "%DNS1%"
if not "!OK!"=="1" (
  echo [ОШИБКА] DNS1 введён неверно.
  pause
  goto MENU
)

set /p DNS2=Введите DNS2 (необязательно, Enter чтобы пропустить): 
if not "%DNS2%"=="" (
  call :IS_IPV4 "%DNS2%"
  if not "!OK!"=="1" (
    echo [ОШИБКА] DNS2 введён неверно.
    pause
    goto MENU
  )
)

echo.
echo Проверяю, не занят ли IP %IPADDR% ...
call :IP_IN_USE "%IPADDR%"
if "!INUSE!"=="1" (
  echo [ПРЕДУПРЕЖДЕНИЕ] Похоже, IP %IPADDR% уже отвечает в сети (возможен конфликт).
  echo Лучше выбрать другой IP или включить DHCP.
  set /p CONT=Продолжить всё равно? (y/n): 
  if /i not "!CONT!"=="y" (
    echo Отмена. Ничего не применено.
    pause
    goto MENU
  )
)

echo.
echo Применяю статический IP для "%IFACE%" ...
netsh interface ipv4 set address name="%IFACE%" source=static addr=%IPADDR% mask=%MASK% gateway=%GW% gwmetric=1 >nul 2>&1
if not "%errorlevel%"=="0" (
  echo [ОШИБКА] Не удалось применить статический IP.
  echo Проверь имя интерфейса и введённые значения.
  pause
  goto MENU
)

echo Настраиваю DNS ...
netsh interface ipv4 set dnsservers name="%IFACE%" source=static address=%DNS1% register=primary validate=no >nul 2>&1
if not "%errorlevel%"=="0" (
  echo [ОШИБКА] Не удалось задать DNS1.
  pause
  goto MENU
)

if not "%DNS2%"=="" (
  netsh interface ipv4 add dnsservers name="%IFACE%" address=%DNS2% index=2 validate=no >nul 2>&1
)

ipconfig /flushdns >nul 2>&1

echo.
echo Готово. Backup сохранён: "%BACKUP%"
echo.
netsh interface ipv4 show config name="%IFACE%"
echo.
pause
goto MENU

:END
endlocal
exit /b 0
