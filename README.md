# Nordvic
Nordvic Game Servers

> [!WARNING]
> **Startup Command for Linux servers** <img src="https://github.com/user-attachments/assets/d8466b51-0c36-412d-acd1-fb0a26b13e83" width="16" alt="image">
```
./ArmaReforgerServer -bindIP {ip} -bindPort {port} -a2sIpAddress {ip} -a2sPort {query_port} -logStats {logStatsInSec} -gproj ./addons/data/ArmaReforger.gproj -config ./config.json -profile ./profile -backendlog -nothrow -listScenarios -maxFPS {setMaxFps} -autoreload {autoreload} -loadSessionSave {loadSessionSave}
```
> **Startup Command for Linux servers CLEAN** <img src="https://github.com/user-attachments/assets/d8466b51-0c36-412d-acd1-fb0a26b13e83" width="16" alt="image">
```
./ArmaReforgerServer -gproj ./addons/data/ArmaReforger.gproj -config ./config.json -profile ./profile -maxFPS 100 -freezeCheck 25 -freezeCheckMode kill -autoreload 10 -logStats 60000 -logFS -backendlog -nothrow -addonsRepair
```
> **Startup Command for Windows servers** <img src="https://github.com/user-attachments/assets/36bc22b3-4da2-451d-8d1f-1117a0d1daec" width="16" alt="image">
```
ArmaReforgerServer.exe -bindIP {ip} -bindPort {port} -a2sIpAddress {ip} -a2sPort {query_port} -logStats {logStatsInSec} -config .\config.json -profile .\profile -backendlog -nothrow -maxFPS {setMaxFps} -autoreload {autoreload} -loadSessionSave {loadSessionSave}
```
> **Startup Command for Windows servers CLEAN** <img src="https://github.com/user-attachments/assets/36bc22b3-4da2-451d-8d1f-1117a0d1daec" width="16" alt="image">
```
ArmaReforgerServer.exe -config .\config.json -profile .\profile -maxFPS 100 -freezeCheck 25 -freezeCheckMode kill -autoreload 30 -logStats 60000 -AILimit 120 -logFS -addonsVerify -addonsRepair -backendlog -nothrow
```
**Add following Vars**
| Var | Default | Info |
| :---:   | :---: | :---: |
| setMaxFps | 60 | sets max FPS limit - useful for a server, or to force a client's max FPS. |
| autoreload | 60 | reloads the scenario when the session ends after the provided delay, without shutting down the server. Value is in seconds |
| loadSessionSave | mysavename | allows the game to load a previous game session. It can be used alone to load the latest save, or with a specific save file name. Leave it empty if load autosave |
| logStatsInSec | 90000 | allows to log performance statistics every (optionally) defined interval (in milliseconds). |
*** 
> [!NOTE]
>**DEV Version GameAP v3.2.0**
>- Completely new UI
>- Everything is done in a single application using Vue
>- Bootstrap has been replaced with Tailwind
>- Design has been updated
>- Working with game servers is now much more convenient, and the load on the web server is reduced.
> The update is coming very soon, but you can already test the new version now. To do this, you can install the develop version

To avoid npm error

`
Building styles ...
failed to build styles: failed to install dependencies: exec: "npm": executable file not found in $PATH
`

Run command:
```
sudo apt install nodejs npm
```

**Install develop VERSION**
```
bash <(curl -s https://gameap.com/install.sh) \
  --github \
  --branch=develop
```
**Enable the Service: Run the following command to configure the service to start automatically on boot:**
```
sudo systemctl enable gameap-daemon
```
**To check service status:**
```
sudo systemctl status gameap-daemon
```
*** 
> [!NOTE]
> GameAP tips & tricks: gameapctl. GameAP Control. Gameapctrl is a tool for managing GameAP environment parts. You can easily install or upgrade GameAP using this utily.

> [!WARNING]
> **Install complete set (API+Daemon) using GameAP Control:**
```
gameapctl panel install \
  --path=/var/www/gameap \
  --web-server=nginx \
  --database=mysql \
  --host=http://127.0.0.1 \
  --port=80 \
  --with-daemon
```
***
> [!WARNING]
> **Upgrade GameAP to the latest version:**
```
gameapctl panel upgrade
```
> [!WARNING]
> **Upgrade GameAP Daemon to the latest version:**
```
gameapctl daemon upgrade
```
***
> [!WARNING]
> **To daemon control you can use following commands:**
```
gameapctl daemon start
gameapctl daemon restart
gameapctl daemon stop
```
***
> [!WARNING]
> **Web UI**
```
gameapctl ui
```
**Access to UI**

URL1: http://localhost:17080

URL2: http://127.0.0.1:17080

Check port, it may be different

Add new host and ip, EX:
```
gameapctl ui --host localhost --port 17081
```
***
> [!WARNING]
> **Install GameAP Control**
> Use following commands to install gameapctl on Linux x86-64:
```
curl -OL https://github.com/gameap/gameapctl/releases/download/v0.10.0/gameapctl-v0.10.0-linux-amd64.tar.gz
```
```
tar -xvf gameapctl-v0.10.0-linux-amd64.tar.gz -C /usr/local/bin
```
> [!TIP]
> For Windows you can manually download from Github: https://github.com/gameap/gameapctl/releases
