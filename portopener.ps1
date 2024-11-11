# Vérification des privilèges administrateur
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Ce script nécessite des privilèges administrateur." -ForegroundColor Red
    Write-Host "Veuillez relancer le script en tant qu'administrateur." -ForegroundColor Red
    pause
    exit
}

# Variables globales    
$MiniUPnPCPath = "C:\miniupnpc\upnpc-static.exe"
$LocalIP = "192.168.1.115" # À modifier selon votre configuration

# Vérification de l'existence de miniUPnP
if (-not (Test-Path $MiniUPnPCPath)) {
    Write-Host "Erreur : miniUPnP n'est pas trouvé à l'emplacement : $MiniUPnPCPath" -ForegroundColor Red
    Write-Host "Veuillez installer miniUPnP et vérifier le chemin." -ForegroundColor Red
    pause
    exit
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
        $deleteResult = & $MiniUPnPCPath -d $Port $Protocol 2>&1
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
    $ruleName = "Rust Server - $Description ($Protocol)"
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

# Liste des ports à ouvrir via UPnP et dans le Pare-feu Windows
$ports = @(
    @{Port = 27015; Protocol = "UDP"; Description = "Steam Port"},
    @{Port = 22220; Protocol = "UDP"; Description = "Game Port"},
    @{Port = 22220; Protocol = "TCP"; Description = "Game Port"},
    @{Port = 22222; Protocol = "TCP"; Description = "RCON Port"},
    @{Port = 22288; Protocol = "TCP"; Description = "Rust+ Port"},
    @{Port = 22223; Protocol = "TCP"; Description = "Querry Port"},
    @{Port = 28015; Protocol = "UDP"; Description = "Game Port 2"},
    @{Port = 28015; Protocol = "TCP"; Description = "Game Port 2"},
    @{Port = 28016; Protocol = "TCP"; Description = "RCON Port 2"},
    @{Port = 28083; Protocol = "TCP"; Description = "Rust+ Port 2"},
    @{Port = 28017; Protocol = "TCP"; Description = "Querry Port 2"}

)

# Application des configurations UPnP et Pare-feu
Write-Log "Début de la configuration UPnP et Pare-feu des ports..." -Color Yellow
foreach ($portConfig in $ports) {
    # Configuration UPnP
    $upnpResult = Set-UPnPPort $portConfig.Port $portConfig.Protocol $portConfig.Description
    if (-not $upnpResult) {
        Write-Log "Échec de la configuration UPnP pour le port $($portConfig.Port) ($($portConfig.Protocol))" -Color Red
    }

    # Configuration du Pare-feu
    $firewallResult = Set-FirewallRule $portConfig.Port $portConfig.Protocol $portConfig.Description
    if (-not $firewallResult) {
        Write-Log "Échec de la configuration du pare-feu pour le port $($portConfig.Port) ($($portConfig.Protocol))" -Color Red
    }
}

Write-Log "Configuration UPnP et Pare-feu des ports terminée." -Color Green
pause
