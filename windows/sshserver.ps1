wsl --exec dbus-launch true sudo /etc/init.d/ssh start
$wsl_ip = (wsl hostname -I).trim()
Write-Host "WSL Machine IP: ""$wsl_ip"""
netsh interface portproxy delete v4tov4 listenport=2222
netsh interface portproxy add v4tov4 listenport=2222 connectport=22 connectaddress=$wsl_ip
