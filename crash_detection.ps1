# Script to monitor Arma Reforger server, detect crashes, and display FPS from logs in the window title.

# --- Configuration ---
# Server and Paths
$serverExePath     = "C:\servers\delta\ArmaReforgerServer.exe"
$serverWorkingDir  = "C:\gameap\servers\9e9903fc-4af0-4647-a343-3cf8f98f3a69"
# !! IMPORTANT: Verify this is the correct user profile name !!
$logDirectory      = "C:\gameap\servers\9e9903fc-4af0-4647-a343-3cf8f98f3a69\profile\logs"
$updateIntervalSec = 30 # How often to check the logs and process status (in seconds)

# Incident Logging
$incidentLogPath = Join-Path -Path $serverWorkingDir -ChildPath "incident.json" # Log file in the server directory
$pidFilePath = Join-Path -Path $serverWorkingDir -ChildPath "server.pid" # PID file in the server directory

# --- NEW: Server Data Logging Configuration ---
$serverDataLogFolder = "server_data_logs" # Subfolder name within $serverWorkingDir for server data logs
$serverDataLogIntervalHours = 24 # How often to create a NEW server data log file (in hours)
$statsLogIntervalSec = 60 # How often to WRITE a line to the CURRENT server data log (in seconds)
# --- End Server Data Logging Configuration ---

$crashKeywords   = @(
    "Application crashed!",
    "FATAL ERROR",
    "Exception Code:", # Add more specific keywords or patterns if needed
    "Segmentation fault",
    "Terminating connection."
)

# --- Incident Logging Function ---
function Log-Incident {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("Startup", "Crash", "Shutdown")]
        [string]$IncidentType,

        # Optional keyword for crash details
        [string]$Keyword = $null,

        # Optional uptime for Crash/Shutdown incidents (Allow $null)
        [System.Nullable[TimeSpan]]$ProcessUptime = $null
    )

    $timestamp = Get-Date
    $formattedTimestamp = $timestamp.ToString("dd/MM/yyyy HH:mm") # Use this for the log entry

    # Define Incident Type String based on IncidentType
    $incidentTypeString = switch ($IncidentType) {
        "Startup"  { "Server startup initiated" }
        "Crash"    { "Server crash detected, keyword has been found in recent logs" } # Specific string for crash
        "Shutdown" { "Server shutdown detected" }
        default    { "Unknown incident" }
    }

    # --- Read existing log data first ---
    $incidentData = @() # Start with an empty array
    if (Test-Path $incidentLogPath -PathType Leaf) {
        $fileInfo = Get-Item $incidentLogPath -ErrorAction SilentlyContinue
        if ($fileInfo -and $fileInfo.Length -gt 0) { # Check if file exists and is not empty
            try {
                # Read the raw content
                $existingJson = Get-Content -Path $incidentLogPath -Raw -ErrorAction Stop

                # Attempt to parse the JSON content
                $parsedData = $existingJson | ConvertFrom-Json -ErrorAction SilentlyContinue

                if ($null -ne $parsedData) {
                    # SUCCESSFUL PARSE: Ensure we always work with an array
                    if ($parsedData -is [array]) {
                        $incidentData = $parsedData # Use the parsed array directly
                    } else {
                        # If the file somehow contained a single JSON object (not an array),
                        # wrap it in an array to maintain consistency. This shouldn't happen
                        # with our write logic but adds robustness.
                        $incidentData = @($parsedData)
                        Write-Warning "[$formattedTimestamp] Note: '$incidentLogPath' contained a single JSON object, not an array. Treating as a single-element array. Please check the file." -ForegroundColor Yellow
                    }
                } else {
                    # PARSE FAILED: JSON was invalid/corrupted
                    Write-Warning "--------------------------------------------------------------------" -ForegroundColor Red
                    Write-Warning "CRITICAL: Could not parse '$incidentLogPath' as valid JSON." -ForegroundColor Red
                    Write-Warning "This usually means the file is corrupted or was manually edited incorrectly." -ForegroundColor Yellow
                    Write-Warning "ACTION: Starting a NEW incident log. Previous history (if any) in that file is lost." -ForegroundColor Yellow
                    Write-Warning "CHECK: Please verify the contents of '$incidentLogPath' if this happens repeatedly." -ForegroundColor Yellow
                    Write-Warning "--------------------------------------------------------------------" -ForegroundColor Red
                    # $incidentData remains @() - starting fresh
                }
            } catch {
                # READ FAILED: Error during Get-Content
                Write-Warning "[$formattedTimestamp] Error reading '$incidentLogPath'. Initializing new log. Error: $($_.Exception.Message)"
                # $incidentData remains @() - starting fresh
            }
        } else {
             # FILE IS EMPTY: Treat as a new log
             if ($fileInfo) { # Check if $fileInfo is not null (meaning file exists but is empty)
                 Write-Host "[$formattedTimestamp] Existing incident log '$incidentLogPath' is empty. Initializing new log." -ForegroundColor DarkGray
             }
             # $incidentData remains @() - starting fresh
        }
    }
    # If the file didn't exist at all, $incidentData also remains @()

    # --- Calculate the next sequential ID ---
    $nextId = 1 # Default to 1 if no existing data or IDs
    if ($incidentData.Count -gt 0) {
        # Find the maximum existing ID (convert to integer for comparison)
        # Use -ErrorAction SilentlyContinue to handle entries that might lack the ID or have non-numeric values
        $maxId = ($incidentData.'Incident ID' | ForEach-Object { [int]$_ -as [int] } | Measure-Object -Maximum -ErrorAction SilentlyContinue).Maximum
        if ($null -ne $maxId) {
            $nextId = $maxId + 1
        }
        # Fallback if max couldn't be determined (e.g., all entries lacked ID), just use count + 1
        elseif ($incidentData.Count -gt 0) {
            $nextId = $incidentData.Count + 1
        }
    }

    # --- Create the log entry with the sequential ID ---
    $logEntry = [ordered]@{ # Using [ordered] for consistent key order in JSON
        "Incident ID"        = $nextId.ToString() # Store as string to match example
        "Incident Timestamp" = $formattedTimestamp
        "Incident Type"      = $incidentTypeString
    }

    # Add optional fields
    if ($Keyword) {
        $logEntry.Keyword = $Keyword
    }
    if ($ProcessUptime -ne $null) {
        # Format TimeSpan for better readability in JSON (e.g., "Xd HH:MM:SS")
        $formattedUptimeString = "{0}d {1:00}h:{2:00}m:{3:00}s" -f $ProcessUptime.Days, $ProcessUptime.Hours, $ProcessUptime.Minutes, $ProcessUptime.Seconds
        $logEntry.Uptime = $formattedUptimeString
    }

    # --- Append and Write back ---
    # Add the new entry
    $incidentData += $logEntry

    # Write back to the file
    try {
        ConvertTo-Json -InputObject $incidentData -Depth 5 | Out-File -FilePath $incidentLogPath -Encoding UTF8 -ErrorAction Stop
        Write-Host "[$formattedTimestamp] Logged incident: '$incidentTypeString' (ID: $nextId)" -ForegroundColor DarkGray
        if ($IncidentType -eq "Crash" -and $Keyword) {
             Write-Host "  -> Keyword: '$Keyword'" -ForegroundColor DarkGray
        }
    } catch {
        Write-Error "[$formattedTimestamp] Failed to write to incident log '$incidentLogPath': $($_.Exception.Message)"
    }
}
# --- End Incident Logging Function ---

# --- Function to Determine Current Server Data Log Path ---
function Get-CurrentServerDataLogPath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogDirectoryPath # The dedicated folder for these logs
    )

    $todayDateStr = Get-Date -Format 'dd.MM.yyyy'
    $baseFileName = "server_data-$todayDateStr"
    $filter = "$baseFileName`_ID-*.txt" # Use backtick to escape underscore if needed in filter

    # Find existing files for today to determine the next ID
    $existingFiles = Get-ChildItem -Path $LogDirectoryPath -Filter $filter -File -ErrorAction SilentlyContinue

    $maxId = 0
    if ($existingFiles) {
        foreach ($file in $existingFiles) {
            # Extract ID using regex for robustness (handles ID numbers)
            if ($file.Name -match '_ID-(\d+)\.txt$') {
                $currentId = [int]$matches[1]
                if ($currentId -gt $maxId) {
                    $maxId = $currentId
                }
            }
        }
    }

    $nextId = $maxId + 1
    $newFileName = "$baseFileName`_ID-$nextId.txt"
    $fullPath = Join-Path -Path $LogDirectoryPath -ChildPath $newFileName
    return $fullPath
}
# --- End Log Path Function ---


# --- Stats Logging Function (Modified) ---
function Write-StatsLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TargetPath, # The full path to the current log file

        [Parameter(Mandatory=$true)]
        [string]$FPS,

        [Parameter(Mandatory=$true)]
        [string]$Players
    )

    $timestamp = Get-Date -Format "dd/MM/yyyy HH:mm:ss" # Added seconds for more granularity
    $logLine = "[$timestamp] Server FPS: $FPS | Players: $Players"

    try {
        # Ensure the directory exists just in case (should be created earlier, but good practice)
        $targetDir = Split-Path -Path $TargetPath -Parent
        if (-not (Test-Path $targetDir -PathType Container)) {
            New-Item -Path $targetDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }

        Add-Content -Path $TargetPath -Value $logLine -Encoding UTF8 -ErrorAction Stop
        Write-Verbose "Stats logged to $TargetPath"
    } catch {
        Write-Warning "Failed to write to server data log '$TargetPath': $($_.Exception.Message)"
    }
}
# --- End Stats Logging Function ---


# Store the original window title
$originalTitle = $Host.UI.RawUI.WindowTitle

# --- Create Server Data Log Directory ---
$fullServerDataLogPath = Join-Path -Path $serverWorkingDir -ChildPath $serverDataLogFolder
if (-not (Test-Path $fullServerDataLogPath -PathType Container)) {
    try {
        Write-Host "Creating server data log directory: '$fullServerDataLogPath'" -ForegroundColor Cyan
        New-Item -Path $fullServerDataLogPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
    } catch {
        Write-Error "FATAL: Could not create server data log directory '$fullServerDataLogPath'. Exiting. Error: $($_.Exception.Message)"
        exit 1 # Exit if we can't create the log directory
    }
} else {
    Write-Host "Server data log directory found: '$fullServerDataLogPath'" -ForegroundColor DarkGray
}
# --- End Directory Creation ---

# --- Check for Existing Server Processes ---
Write-Host "Checking for existing ArmaReforgerServer processes..." -ForegroundColor Yellow
$existingServers = Get-Process -Name "ArmaReforgerServer" -ErrorAction SilentlyContinue
if ($existingServers) {
    Write-Host "Found $($existingServers.Count) existing ArmaReforgerServer process(es)." -ForegroundColor Green
    # Use the first existing process
    $serverProcess = $existingServers[0]
    Write-Host "Using existing server process with ID: $($serverProcess.Id)" -ForegroundColor Green

    # Write PID to file if it doesn't exist
    if (-not (Test-Path $pidFilePath)) {
        try {
            Write-Verbose "Writing existing PID $($serverProcess.Id) to $pidFilePath"
            Set-Content -Path $pidFilePath -Value $serverProcess.Id -Encoding ASCII -Force -ErrorAction Stop
        } catch {
            Write-Warning "Failed to write PID file '$pidFilePath': $($_.Exception.Message). Server is running but PID management might be affected."
        }
    }
} else {
    Write-Host "No existing ArmaReforgerServer processes found. Will monitor for new processes." -ForegroundColor Yellow
    $serverProcess = $null
}
# --- End Process Check ---

# --- Log Monitoring Loop ---
$lastFpsValue = "N/A" # Store the last known FPS
$lastPlayerCount = "N/A" # Store the last known player count
$memUsageMB = "N/A"
$formattedUptime = "N/A" # For formatted uptime string
$lastStatsLogTime = [DateTime]::MinValue # Initialize last stats log time (force first log)

# Variables for managing periodic server data log files
$currentServerDataLogPath = $null # Holds the path to the currently active data log file
$nextServerDataLogCreationTime = [DateTime]::MinValue # Initialize to ensure first check creates a file

try {
    while ($true) {
        $currentTime = [DateTime]::Now # Get current time once per loop iteration

        # --- Determine/Update Current Server Data Log File ---
        if ($null -eq $currentServerDataLogPath -or $currentTime -ge $nextServerDataLogCreationTime) {
            $previousLogPath = $currentServerDataLogPath
            $currentServerDataLogPath = Get-CurrentServerDataLogPath -LogDirectoryPath $fullServerDataLogPath

            if ($currentServerDataLogPath -ne $previousLogPath) {
                 Write-Host "[$($currentTime.ToString('dd/MM/yyyy HH:mm'))] Using new server data log file: '$($currentServerDataLogPath | Split-Path -Leaf)'" -ForegroundColor Cyan
                 # Set the time for the *next* file creation based on the *start* of this interval
                 $nextServerDataLogCreationTime = $currentTime.AddHours($serverDataLogIntervalHours)
                 Write-Host "  -> Next new log file scheduled around: $($nextServerDataLogCreationTime.ToString('dd/MM/yyyy HH:mm'))" -ForegroundColor DarkGray
            }
        }

        # --- Get Latest Log Directory and Path (for crash/FPS check) ---
        $latestLogSubDir = Get-ChildItem -Path $logDirectory -Directory | Sort-Object CreationTime -Descending | Select-Object -First 1
        $consoleLogPath = $null # Reset in case directory disappears
        if ($latestLogSubDir -and (Test-Path $latestLogSubDir.FullName)) {
            $consoleLogPath = Join-Path -Path $latestLogSubDir.FullName -ChildPath "console.log"
        }

        # --- Check for Server Process if not already tracking one ---
        if ($null -eq $serverProcess) {
            $existingServers = Get-Process -Name "ArmaReforgerServer" -ErrorAction SilentlyContinue
            if ($existingServers) {
                $serverProcess = $existingServers[0]
                Write-Host "Found ArmaReforgerServer process with ID: $($serverProcess.Id)" -ForegroundColor Green

                # Write PID to file
                try {
                    Write-Verbose "Writing PID $($serverProcess.Id) to $pidFilePath"
                    Set-Content -Path $pidFilePath -Value $serverProcess.Id -Encoding ASCII -Force -ErrorAction Stop
                } catch {
                    Write-Warning "Failed to write PID file '$pidFilePath': $($_.Exception.Message)"
                }
            }
        }

        # --- Check Server Process Status ---
        $serverProcessInfo = $null
        if ($serverProcess) {
            try {
                $serverProcessInfo = Get-Process -Id $serverProcess.Id -ErrorAction Stop

                # --- Get Process Info (Memory, Uptime) ---
                $memUsageMB = [Math]::Round($serverProcessInfo.WorkingSet / 1MB, 0)
                # Calculate uptime TimeSpan
                $uptime = $currentTime - $serverProcessInfo.StartTime # Use $currentTime for consistency
                # Format uptime
                if ($uptime.TotalSeconds -lt 60) {
                    $formattedUptime = "{0:0}s" -f $uptime.TotalSeconds # Show only seconds
                } elseif ($uptime.TotalHours -lt 1) {
                    $formattedUptime = "{0:0}m:{1:00}s" -f $uptime.Minutes, $uptime.Seconds # Show minutes and seconds
                } else {
                    # Include days if uptime is long
                    $formattedUptime = "{0}d {1:00}h:{2:00}m:{3:00}s" -f $uptime.Days, $uptime.Hours, $uptime.Minutes, $uptime.Seconds
                }
            } catch {
                Write-Warning "Server process (Last Known PID: $($serverProcess.Id)) not found."
                $serverProcess = $null
                $memUsageMB = "N/A"
                $formattedUptime = "N/A"

                # Clean up PID file for the stopped process
                if (Test-Path $pidFilePath) {
                    Write-Verbose "Removing PID file for stopped process: $pidFilePath"
                    Remove-Item $pidFilePath -Force -ErrorAction SilentlyContinue
                }
            }
        }

        $currentFps = $lastFpsValue # Default to last known value
        $currentPlayerCount = $lastPlayerCount # Default to last known value
        $statusMessage = if ($serverProcess) { "Running" } else { "No Server" } # Default status

        try {
            # Get the latest log file (for crash/FPS check)
            if ($latestLogSubDir) {
                if ($consoleLogPath -and (Test-Path $consoleLogPath -PathType Leaf)) {
                    # Read the content of the console.log file
                    # Use -Tail 100 to get more context
                    $logContent = Get-Content -Path $consoleLogPath -Tail 100 -ErrorAction SilentlyContinue

                    if ($logContent) {
                        # --- Crash Detection Check ---
                        $crashDetected = $false
                        foreach ($keyword in $crashKeywords) {
                            # Use -SimpleMatch for literal strings, or remove it if keywords are regex patterns
                            if ($logContent | Select-String -Pattern $keyword -SimpleMatch -Quiet) {
                                Write-Warning "CRASH DETECTED! Keyword found: '$keyword' in recent logs."
                                Write-Host "Server has crashed, crash related words '$keyword' have been found. Terminating server process." -ForegroundColor Red
                                $Host.UI.RawUI.WindowTitle = "Arma Reforger Server | Status: CRASHED!"

                                # Calculate uptime before logging
                                $crashUptime = $null
                                if ($serverProcess -and $serverProcess.StartTime) { # Check if we have StartTime
                                     try {
                                         $crashUptime = $currentTime - $serverProcess.StartTime # Use $currentTime
                                     } catch { Write-Warning "Could not calculate uptime for crash log." }
                                }

                                Log-Incident -IncidentType "Crash" -Keyword $keyword -ProcessUptime $crashUptime

                                # Attempt to forcefully terminate the process only if it exists
                                if ($serverProcess) {
                                    Write-Host "Attempting to terminate crashed process (PID: $($serverProcess.Id))..." -ForegroundColor Yellow
                                    Stop-Process -Id $serverProcess.Id -Force -ErrorAction SilentlyContinue
                                    $serverProcess = $null # Clear the server process reference
                                }

                                # Clean up PID file for the crashed process
                                if (Test-Path $pidFilePath) {
                                    Write-Verbose "Removing PID file for crashed process: $pidFilePath"
                                    Remove-Item $pidFilePath -Force -ErrorAction SilentlyContinue
                                }

                                # Rename the problematic log file to prevent immediate re-detection
                                if ($consoleLogPath -and (Test-Path $consoleLogPath -PathType Leaf)) {
                                    $crashedLogName = "console_crashed_$(Get-Date -Format 'yyyyMMddHHmmss').log"
                                    try {
                                        Rename-Item -Path $consoleLogPath -NewName $crashedLogName -ErrorAction Stop
                                        Write-Host "Renamed problematic log file '$($latestLogSubDir.Name)\console.log' to '$crashedLogName'." -ForegroundColor Cyan
                                    } catch {
                                        Write-Warning "Failed to rename crashed log file '$consoleLogPath': $($_.Exception.Message)"
                                    }
                                } else {
                                     Write-Warning "Could not find console log path '$consoleLogPath' to rename."
                                }

                                # Mark server as killed but continue script execution
                                Write-Host "Server process terminated due to crash detection. Script will continue monitoring." -ForegroundColor Yellow
                                $crashDetected = $true
                                break # Exit keyword loop once a crash is detected
                            }
                        }

                        # If crash was detected and handled, skip regular parsing
                        if ($crashDetected) {
                            Start-Sleep -Seconds $updateIntervalSec # Still wait before next loop iteration
                            continue # Go to the top of the main 'while' loop
                        }

                        # --- Regular Log Parsing (FPS, Players) ---
                        # Only parse logs if we have a server process
                        if ($serverProcess) {
                            # Use Select-String to find the LAST line matching the pattern and extract FPS and Player count
                            # Pattern: DEFAULT...FPS: (capture fps)...Player: (capture players)
                            $pattern = 'DEFAULT\s+:\s+FPS:\s+([\d.]+).*?Player:\s+(\d+)' # Group 1: FPS, Group 2: Players
                            $matchInfo = $logContent | Select-String -Pattern $pattern | Select-Object -Last 1

                            if ($matchInfo -and $matchInfo.Matches[0].Groups[1].Success -and $matchInfo.Matches[0].Groups[2].Success) {
                                $currentFps = $matchInfo.Matches[0].Groups[1].Value
                                $currentPlayerCount = $matchInfo.Matches[0].Groups[2].Value
                                $timestampStr = $currentTime.ToString("dd/MM/yyyy HH:mm") # Use consistent timestamp
                                Write-Host "[$timestampStr] Server FPS: $currentFps | Players: $currentPlayerCount" -ForegroundColor Green
                                $lastFpsValue = $currentFps # Update last known good value
                                $lastPlayerCount = $currentPlayerCount # Update last known good value
                                $statusMessage = "OK"

                                # --- Check if it's time to log stats to the CURRENT data file ---
                                if (($currentTime - $lastStatsLogTime).TotalSeconds -ge $statsLogIntervalSec) {
                                    if ($null -ne $currentServerDataLogPath) { # Ensure we have a valid path
                                        Write-StatsLog -TargetPath $currentServerDataLogPath -FPS $currentFps -Players $currentPlayerCount
                                        $lastStatsLogTime = $currentTime # Update time of last STATS WRITE
                                    } else {
                                        Write-Warning "Cannot write stats log, current server data log path is not set."
                                    }
                                }
                            } # End if ($matchInfo...)
                        } # End if ($serverProcess)
                    } # End if ($logContent)
                } # End if ($consoleLogPath...)
            } # End if ($latestLogSubDir)
        } catch {
            $statusMessage = "LogReadErr: $($_.Exception.Message.Split([Environment]::NewLine)[0])" # General error during log check
            Write-Warning "Error during log processing: $statusMessage"
        }

        # Update window title with info
        if ($serverProcess) {
            $Host.UI.RawUI.WindowTitle = "Arma Reforger Server | FPS: $currentFps | Players: $currentPlayerCount | Uptime: $formattedUptime | Mem: ${memUsageMB}MB | PID: $($serverProcess.Id)"
        } else {
            $Host.UI.RawUI.WindowTitle = "Arma Reforger Server | Status: No Server Running | Last FPS: $lastFpsValue | Last Players: $lastPlayerCount"
        }

        # Wait before next check
        Start-Sleep -Seconds $updateIntervalSec
    } # End while ($true)
}
finally {
    # Restore the original title when the script exits (normally or via error/Ctrl+C)
    $Host.UI.RawUI.WindowTitle = $originalTitle
    Write-Host "Script finished. Restored original window title."

    # Clean up PID file on script exit / termination
    if (Test-Path $pidFilePath) {
        Write-Verbose "Removing PID file on script exit: $pidFilePath"
        Remove-Item $pidFilePath -Force -ErrorAction SilentlyContinue
    }

    # Log shutdown if we were monitoring a server
    if ($serverProcess -and $serverProcess.Id -ne $null) { # Check if we have a valid process ID
        # Attempt to refresh process info one last time before logging shutdown
         $finalProcessInfo = Get-Process -Id $serverProcess.Id -ErrorAction SilentlyContinue
         if ($finalProcessInfo -and (-not $finalProcessInfo.HasExited)) {
             $shutdownUptime = $null
             try {
                 $shutdownUptime = [datetime]::Now - $finalProcessInfo.StartTime
             } catch { }
             Log-Incident -IncidentType "Shutdown" -ProcessUptime $shutdownUptime
             Write-Host "Logged server shutdown." -ForegroundColor DarkGray
         }
    }
}
