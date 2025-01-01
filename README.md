# Nordvic
Nordvic Game Servers

Startup Command for Linux servers
```
./ArmaReforgerServer -bindIP {ip} -bindPort {port} -a2sIpAddress {ip} -a2sPort {query_port} -logStats {logStatsInSec} -gproj ./addons/data/ArmaReforger.gproj -config ./config.json -profile ./profile -backendlog -nothrow -listScenarios -maxFPS {setMaxFps}
```


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
