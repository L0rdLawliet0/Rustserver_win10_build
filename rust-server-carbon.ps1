# Administrator privileges check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires administrator privileges." -ForegroundColor Red
    Write-Host "Please restart the script as an administrator." -ForegroundColor Red
    pause
    exit
}

# Global Variables    
$ServerDir = "C:\rust_server"
$SteamCmdDir = "$ServerDir\steamcmd"
$SteamAppId = "258550"
$CarbonZipPath = "C:\Users\akex\Documents\Rustserver_win10_build-main\Carbon.Windows.Release.zip"  # Local path to Carbon file
$MiniUPnPCPath = "C:\miniupnpc\upnpc-static.exe"
$LocalIP = "192.168.1.115" # Adjust to your configuration

# Check for miniUPnP existence
if (-not (Test-Path $MiniUPnPCPath)) {
    Write-Host "Error: miniUPnP not found at location: $MiniUPnPCPath" -ForegroundColor Red
    Write-Host "Please install miniUPnP and verify the path." -ForegroundColor Red
    pause
    exit
}

# Logging function
function Write-Log {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message" -ForegroundColor $Color
}

# UPnP Configuration Function
function Set-UPnPPort {
    param (
        [int]$Port,
        [string]$Protocol,
        [string]$Description
    )
    Write-Log "Configuring UPnP: $Description - Port $Port ($Protocol)" -Color Cyan
    try {
        # Remove existing mapping (ignore errors)
        $deleteResult = & $MiniUPnPCPath -d $Port $Protocol 2>&1
        # Create new mapping
        $addResult = & $MiniUPnPCPath -a $LocalIP $Port $Port $Protocol 2>&1
        if ($addResult -match "is redirected to internal") {
            Write-Log "UPnP mapping successful for port $Port ($Protocol)" -Color Green
            return $true
        } else {
            Write-Log "Failed UPnP mapping for port $Port ($Protocol)" -Color Red
            Write-Log "Result: $addResult" -Color Red
            return $false
        }
    }
    catch {
        Write-Log "Error in UPnP mapping: $_" -Color Red
        return $false
    }
}

# Firewall Configuration Function
function Set-FirewallRule {
    param (
        [int]$Port,
        [string]$Protocol,
        [string]$Description
    )
    $ruleName = "Rust Server - $Description ($Protocol)"
    try {
        # Check if rule exists
        $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
        if ($existingRule) {
            Write-Log "Updating existing firewall rule: $ruleName" -Color Yellow
            Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction Stop
        }
        # Create new rule
        New-NetFirewallRule -DisplayName $ruleName `
            -Direction Inbound `
            -Protocol $Protocol `
            -LocalPort $Port `
            -Action Allow `
            -Profile Any `
            -ErrorAction Stop
        Write-Log "Firewall rule created/updated: $ruleName" -Color Green
        return $true
    }
    catch {
        Write-Log "Error configuring firewall: $_" -Color Red
        return $false
    }
}

# Required Ports Configuration
$ports = @(
    @{Port = 22220; Protocol = "UDP"; Description = "Game Port"},
    @{Port = 22220; Protocol = "TCP"; Description = "Game Port"},
    @{Port = 22222; Protocol = "TCP"; Description = "RCON Port"},
    @{Port = 27015; Protocol = "UDP"; Description = "Steam Port"},
    @{Port = 22288; Protocol = "TCP"; Description = "Rust+ Port"}
)

# Network Configuration
Write-Log "Starting network configuration..." -Color Yellow
foreach ($portConfig in $ports) {
    # UPnP Configuration
    $upnpResult = Set-UPnPPort $portConfig.Port $portConfig.Protocol $portConfig.Description
    if (-not $upnpResult) {
        Write-Log "Failed UPnP configuration for port $($portConfig.Port) ($($portConfig.Protocol))" -Color Red
    }

    # Firewall Configuration
    $firewallResult = Set-FirewallRule $portConfig.Port $portConfig.Protocol $portConfig.Description
    if (-not $firewallResult) {
        Write-Log "Failed firewall configuration for port $($portConfig.Port) ($($portConfig.Protocol))" -Color Red
    }
}

# Create Server Directory
Write-Log "Creating server directory..." -Color Yellow
New-Item -ItemType Directory -Path $ServerDir -Force | Out-Null

# SteamCMD Installation
Write-Log "Installing SteamCMD..." -Color Yellow
try {
    Invoke-WebRequest -Uri "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip" -OutFile "$ServerDir\steamcmd.zip"
    Expand-Archive -Path "$ServerDir\steamcmd.zip" -DestinationPath $SteamCmdDir -Force
    Remove-Item "$ServerDir\steamcmd.zip"
    Write-Log "SteamCMD installed successfully" -Color Green
}
catch {
    Write-Log "Error installing SteamCMD: $_" -Color Red
    pause
    exit
}

# Rust Server Installation
Write-Log "Installing Rust Server..." -Color Yellow
try {
    & "$SteamCmdDir\steamcmd.exe" +force_install_dir $ServerDir +login anonymous +app_update $SteamAppId validate +quit
    if (-not (Test-Path "$ServerDir\RustDedicated.exe")) {
        throw "RustDedicated.exe not found after installation"
    }
    Write-Log "Rust Server installed successfully" -Color Green
}
catch {
    Write-Log "Error installing Rust Server: $_" -Color Red
    pause
    exit
}

# Carbon Installation
Write-Log "Installing Carbon..." -Color Yellow
try {
    if (-not (Test-Path $CarbonZipPath)) {
        throw "Carbon.zip file not found at location: $CarbonZipPath"
    }
    Expand-Archive -Path $CarbonZipPath -DestinationPath $ServerDir -Force
    Write-Log "Carbon installed successfully" -Color Green
}
catch {
    Write-Log "Error installing Carbon: $_" -Color Red
    pause
    exit
}

# Create Start Script
$startScript = @"
@echo off
:start
RustDedicated.exe -batchmode ^
+server.port 22220 ^
+server.hostname "SnakeLand x3 alpha" ^
+server.identity "rust_server" ^
+server.level "Procedural Map" ^
+server.seed 1234 ^
+server.worldsize 3000 ^
+server.maxplayers 100 ^
+server.description "server test" ^
+server.saveinterval 300 ^
+rcon.port 22222 ^
+rcon.password "7G8Ba8xyK2C3iq" ^
+app.port 22288
goto start
"@
Set-Content -Path "$ServerDir\start_server.bat" -Value $startScript -Encoding ASCII

# Final Information
$PublicIP = (Invoke-WebRequest -Uri "https://api.ipify.org").Content
Write-Log "Installation completed! Server configuration:" -Color Green
Write-Log "Public IP Address: $PublicIP" -Color Green
Write-Log "Configured Ports:" -Color Green
Write-Log " - Game Port: 22220" -Color Green
Write-Log " - RCON Port: 22222" -Color Green
Write-Log " - Steam Port: 27015" -Color Green
Write-Log " - Rust+ Port: 22288" -Color Green
Write-Log "End of build." -Color Yellow
