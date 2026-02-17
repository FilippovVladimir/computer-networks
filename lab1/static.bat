netsh interface ip set address name="Ethernet" static 192.168.0.111 255.255.255.0 192.168.0.1
netsh interface ip set dns name="Ethernet" static 192.168.0.1
ipconfig /all
pause