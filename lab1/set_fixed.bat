@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: --- Запуск от администратора ---
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo [!] Нужны права администратора. Открою окно с повышенными правами...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

:: Если файл сохранён в UTF-8, включаем UTF-8 в консоли
chcp 65001 >nul

echo =============================
echo Настройка сетевого интерфейса
echo 1) Получить настройки по DHCP
echo 2) Ввести вручную (статически)
echo 3) Показать список интерфейсов
echo =============================
set /p choice="Выберите 1, 2 или 3: "

if "%choice%"=="3" (
  echo.
  echo Доступные интерфейсы:
  netsh interface show interface
  echo.
  pause
  exit /b
)

set /p interface="Введите имя интерфейса (например: Ethernet или Wi-Fi): "

if "%choice%"=="1" (
  echo.
  echo Получение настроек через DHCP...
  netsh interface ip set address name="%interface%" source=dhcp
  netsh interface ip set dns     name="%interface%" source=dhcp
  goto :SHOW
)

if "%choice%"=="2" (
  echo.
  set /p ipaddr="Введите IP-адрес (например 192.168.1.50): "
  set /p mask="Введите маску (например 255.255.255.0): "
  set /p gw="Введите шлюз (например 192.168.1.1): "
  set /p dns="Введите DNS (например 8.8.8.8): "

  echo.
  echo Применяю статические параметры...
  netsh interface ip set address name="%interface%" static %ipaddr% %mask% %gw% 1
  netsh interface ip set dns     name="%interface%" static %dns% primary
  goto :SHOW
)

echo.
echo Неверный выбор. Запустите скрипт снова.
pause
exit /b

:SHOW
echo.
echo Текущие параметры интерфейса "%interface%":
ipconfig /all
echo.
echo Готово.
pause
endlocal
BAT
