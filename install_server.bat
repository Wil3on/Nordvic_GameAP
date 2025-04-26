@echo off
setlocal enabledelayedexpansion

echo MCSManager Steam Server Installer
echo ================================
echo.

REM Set variables
set "INSTANCE_ID={mcsm_instance_id}"
set "WORKSPACE={mcsm_workspace}"
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

REM Check if steamcmd.exe exists
if not exist "%STEAMCMD_DIR%\steamcmd.exe" (
    echo ERROR: steamcmd.exe not found in %STEAMCMD_DIR%
    dir "%STEAMCMD_DIR%"
    exit /b 1
)

REM Change to workspace directory and run steamcmd
cd /d "%WORKSPACE%"
echo Changed to directory: %CD%

"%STEAMCMD_DIR%\steamcmd.exe" +login anonymous +force_install_dir "." +app_update %STEAM_APP_ID% validate +quit

echo.
echo Installation complete.
echo.

echo Server has been installed to: %WORKSPACE%
echo You can now start your server through the MCSManager panel.

exit /b 0
