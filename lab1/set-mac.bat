@echo off
chcp 1251 > nul
Setlocal EnableDelayedExpansion
echo =============================
echo Настройка сетевого интерфейса
echo 1) Получить настройки по DHCP
echo 2) Ввести вручную (статически)
echo =============================
set /p choice="Выберите 1 или 2: "
set /p interface="Введите имя интерфейса (например: Ethernet):
"
if "%choice%"=="1" (
echo Получение настроек через DHCP...
netsh interface ip set address name="!interface!" source=dhcp
netsh interface ip set dns name="!interface!" source=dhcp
goto :END
)
if "%choice%"=="2" (
set /p ipaddr="Введите IP-адрес: "
set /p mask="Введите маску: "
set /p gw="Введите шлюз: "
set /p dns="Введите DNS: "
netsh interface ip set address name="!interface!" static !ipaddr!
!mask! !gw! 1
netsh interface ip set dns name="!interface!" static !dns!
goto :END
)
echo Неверный выбор. Попробуйте снова.
:END
echo Настройка завершена.
pause