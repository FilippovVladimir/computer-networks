@echo off
chcp 65001 >nul
title Настройка сети (DHCP / STATIC)

:: Проверка прав администратора
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo Запустите файл ОТ ИМЕНИ АДМИНИСТРАТОРА.
    pause
    exit /b
)

:menu
cls
echo ================================
echo  Настройка сетевого интерфейса
echo ================================
echo 1 - Включить DHCP
echo 2 - Задать статический IPv4
echo 3 - Показать интерфейсы
echo 0 - Выход
echo ================================
set choice=
set /p choice=Выберите пункт: 

if "%choice%"=="1" goto dhcp
if "%choice%"=="2" goto static
if "%choice%"=="3" goto list
if "%choice%"=="0" exit

goto menu


:list
cls
echo Список сетевых интерфейсов:
echo ----------------------------
netsh interface show interface
echo ----------------------------
pause
goto menu


:askiface
set iface=
set /p iface=Введите имя интерфейса (например Ethernet или Wi-Fi): 

:: очистка кавычек и пробелов
set iface=%iface:"=%
set iface=%iface: =%

if "%iface%"=="" goto askiface
exit /b


:dhcp
call :askiface
echo.
echo Переключаю %iface% на DHCP...
netsh interface ip set address name="%iface%" source=dhcp
netsh interface ip set dns name="%iface%" source=dhcp
ipconfig /renew "%iface%"
echo Готово.
pause
goto menu


:static
call :askiface
cls
echo Настройка статического IP для %iface%
echo.

set ip=
set mask=
set gw=
set dns=

set /p ip=Введите IPv4 адрес: 
set ip=%ip:"=%
set ip=%ip: =%

set /p mask=Введите маску: 
set mask=%mask:"=%
set mask=%mask: =%

set /p gw=Введите шлюз: 
set gw=%gw:"=%
set gw=%gw: =%

set /p dns=Введите DNS: 
set dns=%dns:"=%
set dns=%dns: =%

echo.
echo Применяю настройки...
echo IP=%ip%
echo MASK=%mask%
echo GW=%gw%
echo DNS=%dns%
echo.

netsh interface ip set address name="%iface%" static %ip% %mask% %gw% 1
netsh interface ip set dns name="%iface%" static %dns% primary

echo.
echo Настройки применены.
ipconfig | findstr /i "%iface%"
pause
goto menu
