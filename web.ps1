# Vérification des privilèges administrateur
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Ce script nécessite des privilèges administrateur." -ForegroundColor Red
    Write-Host "Veuillez relancer le script en tant qu'administrateur." -ForegroundColor Red
    pause
    exit
}

# Variables globales
$port = 8080
$MiniUPnPCPath = "C:\miniupnpc\upnpc-static.exe"
$LocalIP = "192.168.1.115"  # Votre adresse IP locale
$WebDir = "C:\web"          # Dossier à partager

# Vérification de l'existence de miniUPnP
if (-not (Test-Path $MiniUPnPCPath)) {
    Write-Host "Erreur : miniUPnP n'est pas trouvé à l'emplacement : $MiniUPnPCPath" -ForegroundColor Red
    Write-Host "Veuillez installer miniUPnP et vérifier le chemin." -ForegroundColor Red
    pause
    exit
}

# Création du dossier web si nécessaire
if (-not (Test-Path $WebDir)) {
    New-Item -ItemType Directory -Path $WebDir -Force | Out-Null
    Write-Host "Dossier créé : $WebDir" -ForegroundColor Green
}

# Fonction de journalisation
function Write-Log {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message" -ForegroundColor $Color
}

# Fonction de configuration UPnP
function Set-UPnPPort {
    param (
        [int]$Port,
        [string]$Protocol,
        [string]$Description
    )
    Write-Log "Configuration UPnP : $Description - Port $Port ($Protocol)" -Color Cyan
    try {
        # Suppression du mapping existant (ignorer les erreurs)
        & $MiniUPnPCPath -d $Port $Protocol 2>&1 | Out-Null
        # Création du nouveau mapping
        $addResult = & $MiniUPnPCPath -a $LocalIP $Port $Port $Protocol 2>&1
        if ($addResult -match "is redirected to internal") {
            Write-Log "Mappage UPnP réussi pour le port $Port ($Protocol)" -Color Green
            return $true
        } else {
            Write-Log "Échec du mappage UPnP pour le port $Port ($Protocol)" -Color Red
            Write-Log "Résultat: $addResult" -Color Red
            return $false
        }
    }
    catch {
        Write-Log "Erreur lors du mappage UPnP: $_" -Color Red
        return $false
    }
}

# Fonction de configuration du pare-feu
function Set-FirewallRule {
    param (
        [int]$Port,
        [string]$Protocol,
        [string]$Description
    )
    $ruleName = "Web Server - $Description ($Protocol)"
    try {
        # Vérification de l'existence de la règle
        $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
        if ($existingRule) {
            Write-Log "Mise à jour de la règle pare-feu existante: $ruleName" -Color Yellow
            Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction Stop
        }
        # Création de la nouvelle règle
        New-NetFirewallRule -DisplayName $ruleName `
            -Direction Inbound `
            -Protocol $Protocol `
            -LocalPort $Port `
            -Action Allow `
            -Profile Any `
            -ErrorAction Stop
        Write-Log "Règle pare-feu créée/mise à jour: $ruleName" -Color Green
        return $true
    }
    catch {
        Write-Log "Erreur lors de la configuration du pare-feu: $_" -Color Red
        return $false
    }
}

# Configuration du port 8080
Write -Log "Début de la configuration du serveur web sur le port $port..." -Color Yellow

# Configuration UPnP
$upnpResult = Set-UPnPPort $port "TCP" "HTTP Port"
if (-not $upnpResult) {
    Write-Log "Échec de la configuration UPnP pour le port $port" -Color Red
}

# Configuration du pare-feu
$firewallResult = Set-FirewallRule $port "TCP" "HTTP Port"
if (-not $firewallResult) {
    Write-Log "Échec de la configuration du pare-feu pour le port $port" -Color Red
}

# Lancement du serveur web
Write-Log "Lancement du serveur web sur le port $port..." -Color Yellow
Set-Location $WebDir
python -m http.server $port