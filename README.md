# Nordvic
Nordvic Game Servers

> [!WARNING]
> **Startup Command for Linux servers**

```
./ArmaReforgerServer -bindIP {ip} -bindPort {port} -a2sIpAddress {ip} -a2sPort {query_port} -logStats {logStatsInSec} -gproj ./addons/data/ArmaReforger.gproj -config ./config.json -profile ./profile -backendlog -nothrow -listScenarios -maxFPS {setMaxFps}
```

*** 
> [!NOTE]
>DEV Version GameAP v3.2.0
>- Completely new UI
>- Everything is done in a single application using Vue
>- Bootstrap has been replaced with Tailwind
>- Design has been updated
>- Working with game servers is now much more convenient, and the load on the web server is reduced.
> The update is coming very soon, but you can already test the new version now. To do this, you can install the develop version
```
bash <(curl -s https://gameap.com/install.sh) \
  --github \
  --branch=develop
```
*** 
> [!NOTE]
> GameAP tips & tricks: gameapctl
> GameAP Control
> gameapctrl is a tool for managing GameAP environment parts. You can easily install or upgrade GameAP using this utily.

> [!WARNING]
> Install complete set (API+Daemon) using GameAP Control:
```
gameapctl panel install \
  --path=/var/www/gameap \
  --web-server=nginx \
  --database=mysql \
  --host=http://127.0.0.1 \
  --port=80 \
  --with-daemon
```
> [!WARNING]
> Upgrade GameAP to the latest version:
```
gameapctl panel upgrade
```
> [!WARNING]
> Upgrade GameAP Daemon to the latest version:
```
gameapctl daemon upgrade
```
> [!WARNING]
> To daemon control you can use following commands:
```
gameapctl daemon start
gameapctl daemon restart
gameapctl daemon stop
Install GameAP Control
```
> [!WARNING]
> Use following commands to install gameapctl on Linux x86-64:
```
curl -OL https://github.com/gameap/gameapctl/releases/download/v0.9.4/gameapctl-v0.9.4-linux-amd64.tar.gz
```
```
tar -xvf gameapctl-v0.9.4-linux-amd64.tar.gz -C /usr/local/bin
```
> [!TIP]
> For Windows you can manually download from Github: https://github.com/gameap/gameapctl/releases
