@echo off
setlocal enabledelayedexpansion

echo MCSManager Steam Server Installer
echo ================================
echo.

REM Set variables
set "INSTANCE_ID=%1"
REM Use current directory as workspace instead of relying on {mcsm_workspace} variable
set "WORKSPACE=%CD%"
set "STEAM_APP_ID=1874900"
set "STEAMCMD_URL=https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip"
set "STEAMCMD_ZIP=%WORKSPACE%\steamcmd.zip"
set "STEAMCMD_DIR=%WORKSPACE%\steamcmd"

echo Instance ID: %INSTANCE_ID%
echo Workspace: %WORKSPACE%
echo Steam App ID: %STEAM_APP_ID%
echo.

REM Create steamcmd directory if it doesn't exist
echo Creating SteamCMD directory...
if not exist "%STEAMCMD_DIR%" mkdir "%STEAMCMD_DIR%"
echo.

REM Download SteamCMD
echo Downloading SteamCMD from %STEAMCMD_URL%...
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%STEAMCMD_URL%', '%STEAMCMD_ZIP%')"
if %ERRORLEVEL% neq 0 (
    echo Failed to download SteamCMD.
    exit /b 1
)
echo Download complete.
echo.

REM Extract SteamCMD
echo Extracting SteamCMD...
powershell -Command "Expand-Archive -Path '%STEAMCMD_ZIP%' -DestinationPath '%STEAMCMD_DIR%' -Force"
if %ERRORLEVEL% neq 0 (
    echo Failed to extract SteamCMD.
    exit /b 1
)
echo Extraction complete.
echo.

REM Clean up zip file
del "%STEAMCMD_ZIP%"

REM Install server
echo Starting server installation...
echo This may take some time depending on the server and your internet connection.
echo.

REM Run SteamCMD to install the server
echo Current directory: %CD%
echo SteamCMD directory: %STEAMCMD_DIR%

REM Verify the steamcmd directory was created properly
if exist "%STEAMCMD_DIR%" (
    echo SteamCMD directory exists
    dir "%STEAMCMD_DIR%"
) else (
    echo ERROR: SteamCMD directory was not created properly
    exit /b 1
)

REM Check for steamcmd.exe directly or in possible subfolders
if exist "%STEAMCMD_DIR%\steamcmd.exe" (
    set "STEAMCMD_EXE=%STEAMCMD_DIR%\steamcmd.exe"
) else if exist "%STEAMCMD_DIR%\Steam\steamcmd.exe" (
    set "STEAMCMD_EXE=%STEAMCMD_DIR%\Steam\steamcmd.exe"
) else (
    echo ERROR: Could not find steamcmd.exe in any expected location
    dir "%STEAMCMD_DIR%" /s
    exit /b 1
)

echo Found SteamCMD at: %STEAMCMD_EXE%

"%STEAMCMD_EXE%" +login anonymous +force_install_dir "%WORKSPACE%" +app_update %STEAM_APP_ID% validate +quit

echo.
echo Installation complete.
echo.

REM Create default config.json file
echo Creating default config.json file...

@echo { > "%WORKSPACE%\config.json"
@echo 	"bindAddress": "localip", >> "%WORKSPACE%\config.json"
@echo 	"bindPort": 2001, >> "%WORKSPACE%\config.json"
@echo 	"publicAddress": "publicip", >> "%WORKSPACE%\config.json"
@echo 	"publicPort": 2001, >> "%WORKSPACE%\config.json"
@echo 	"a2s": { >> "%WORKSPACE%\config.json"
@echo 		"address": "localip", >> "%WORKSPACE%\config.json"
@echo 		"port": 17777 >> "%WORKSPACE%\config.json"
@echo 	}, >> "%WORKSPACE%\config.json"
@echo 	"rcon": { >> "%WORKSPACE%\config.json"
@echo 		"address": "localip", >> "%WORKSPACE%\config.json"
@echo 		"port": 19999, >> "%WORKSPACE%\config.json"
@echo 		"password": "MyPassRcon", >> "%WORKSPACE%\config.json"
@echo 		"permission": "monitor", >> "%WORKSPACE%\config.json"
@echo 		"blacklist": [], >> "%WORKSPACE%\config.json"
@echo 		"whitelist": [] >> "%WORKSPACE%\config.json"
@echo 	}, >> "%WORKSPACE%\config.json"
@echo 	"game": { >> "%WORKSPACE%\config.json"
@echo   		"name":"GameAP Server", >> "%WORKSPACE%\config.json"
@echo 		"password": "", >> "%WORKSPACE%\config.json"
@echo 		"passwordAdmin": "MyPass", >> "%WORKSPACE%\config.json"
@echo 		"admins" : [ >> "%WORKSPACE%\config.json"
@echo 			"66561199094966237" >> "%WORKSPACE%\config.json"
@echo 		], >> "%WORKSPACE%\config.json"
@echo 		"scenarioId": "{ECC61978EDCC2B5A}Missions/23_Campaign.conf", >> "%WORKSPACE%\config.json"
@echo 		"maxPlayers": 128, >> "%WORKSPACE%\config.json"
@echo 		"visible": true, >> "%WORKSPACE%\config.json"
@echo 		"crossPlatform": true, >> "%WORKSPACE%\config.json"
@echo 		"supportedPlatforms": [ >> "%WORKSPACE%\config.json"
@echo 			"PLATFORM_PC", >> "%WORKSPACE%\config.json"
@echo 			"PLATFORM_XBL" >> "%WORKSPACE%\config.json"
@echo 		], >> "%WORKSPACE%\config.json"
@echo 		"gameProperties": { >> "%WORKSPACE%\config.json"
@echo 			"serverMaxViewDistance": 2500, >> "%WORKSPACE%\config.json"
@echo 			"serverMinGrassDistance": 50, >> "%WORKSPACE%\config.json"
@echo 			"networkViewDistance": 1000, >> "%WORKSPACE%\config.json"
@echo 			"disableThirdPerson": true, >> "%WORKSPACE%\config.json"
@echo 			"fastValidation": true, >> "%WORKSPACE%\config.json"
@echo 			"battlEye": true, >> "%WORKSPACE%\config.json"
@echo 			"VONDisableUI": false, >> "%WORKSPACE%\config.json"
@echo 			"VONDisableDirectSpeechUI": false, >> "%WORKSPACE%\config.json"
@echo 			"missionHeader": { >> "%WORKSPACE%\config.json"
@echo 				"m_iPlayerCount": 40, >> "%WORKSPACE%\config.json"
@echo 				"m_eEditableGameFlags": 6, >> "%WORKSPACE%\config.json"
@echo 				"m_eDefaultGameFlags": 6, >> "%WORKSPACE%\config.json"
@echo 				"other": "values" >> "%WORKSPACE%\config.json"
@echo 			} >> "%WORKSPACE%\config.json"
@echo 		}, >> "%WORKSPACE%\config.json"
@echo 		"mods": [ >> "%WORKSPACE%\config.json"
@echo { >> "%WORKSPACE%\config.json"
@echo   "modId": "5AAAC70D754245DD", >> "%WORKSPACE%\config.json"
@echo   "name": "Server Admin Tools", >> "%WORKSPACE%\config.json"
@echo   "version": "" >> "%WORKSPACE%\config.json"
@echo } >> "%WORKSPACE%\config.json"
@echo 		] >> "%WORKSPACE%\config.json"
@echo 	}, >> "%WORKSPACE%\config.json"
@echo     "operating": { >> "%WORKSPACE%\config.json"
@echo         "playerSaveTime": 420, >> "%WORKSPACE%\config.json"
@echo         "slotReservationTimeout": 60, >> "%WORKSPACE%\config.json"
@echo         "disableServerShutdown": false, >> "%WORKSPACE%\config.json"
@echo         "lobbyPlayerSynchronise": true, >> "%WORKSPACE%\config.json"
@echo         "joinQueue": { >> "%WORKSPACE%\config.json"
@echo             "maxSize": 50 >> "%WORKSPACE%\config.json"
@echo         }, >> "%WORKSPACE%\config.json"
@echo         "disableNavmeshStreaming": [] >> "%WORKSPACE%\config.json"
@echo     } >> "%WORKSPACE%\config.json"
@echo } >> "%WORKSPACE%\config.json"

echo Config file created at: %WORKSPACE%\config.json
echo.

echo Server has been installed to: %WORKSPACE%
echo You can now start your server through the MCSManager panel.

exit /b 0
