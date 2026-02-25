<#
.SYNOPSIS
    Minecraft Bedrock Unlocker - PowerShell Script
    
.DESCRIPTION
    Complete PowerShell-based Minecraft Bedrock Unlocker.
    Downloads OnlineFix DLLs directly from GitHub and installs them.
    No EXE needed - runs entirely in PowerShell.
    
    Usage: irm https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/main/install.ps1 | iex
    
.NOTES
    Author: CoelhoFZ
    Version: 2.5.0
    Repository: https://github.com/CoelhoFZ/MinecraftBedrockUnlocker
#>

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'  # Speed up downloads

# ============================================================================
# Configuration
# ============================================================================
$Script:Version = "2.5.0"
$Script:RepoOwner = "CoelhoFZ"
$Script:RepoName = "MinecraftBedrockUnlocker"
$Script:RepoBranch = "main"
$Script:BaseUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$RepoBranch"
$Script:DiscordUrl = "https://discord.gg/bfFdyJ3gEj"

# DLL files info (SHA256 hashes for integrity verification)
$Script:OnlineFixFiles = @(
    @{ Name = "winmm.dll";        Hash = "cb8baaa2054a11628b96e474e1428a430c95321f8ac3b89764255cbd6628a9d6" },
    @{ Name = "OnlineFix64.dll";  Hash = "52cb3902999034e01bae63c6a06612d1798b0e0addc1bd4ce7680891b0229953" },
    @{ Name = "dlllist.txt";      Hash = "fc0befb4aae4b7f0eeb1c398fccea03cc795590e09db6628974520091fcfc516" },
    @{ Name = "OnlineFix.ini";    Hash = "d13a4c53389c6a35616ccbe2c09912a43369d904a52b461d734f4ebec212ddfc" }
)

# ============================================================================
# Language Detection
# ============================================================================
$Script:Lang = "en"

function Detect-Language {
    try {
        $culture = (Get-Culture).Name
        switch -Wildcard ($culture) {
            "pt-BR" { $Script:Lang = "pt" }
            "pt-*"  { $Script:Lang = "pt" }
            "es-*"  { $Script:Lang = "es" }
            "fr-*"  { $Script:Lang = "fr" }
            "de-*"  { $Script:Lang = "de" }
            "zh-*"  { $Script:Lang = "zh" }
            "ru-*"  { $Script:Lang = "ru" }
            default  { $Script:Lang = "en" }
        }
    } catch {
        $Script:Lang = "en"
    }
}

function T {
    param([string]$Key)
    
    $translations = @{
        "admin_required" = @{
            en = "Administrator privileges required!"
            pt = "Privilegios de Administrador necessarios!"
            es = "Se requieren privilegios de Administrador!"
        }
        "admin_elevating" = @{
            en = "Requesting elevation..."
            pt = "Solicitando elevacao..."
            es = "Solicitando elevacion..."
        }
        "admin_ok" = @{
            en = "Running with Administrator privileges"
            pt = "Executando com privilegios de Administrador"
            es = "Ejecutando con privilegios de Administrador"
        }
        "menu_title" = @{
            en = "Available Options"
            pt = "Opcoes Disponiveis"
            es = "Opciones Disponibles"
        }
        "menu_1" = @{
            en = "Install Mod (Unlock Game)"
            pt = "Instalar Mod (Desbloquear Jogo)"
            es = "Instalar Mod (Desbloquear Juego)"
        }
        "menu_2" = @{
            en = "Restore Original (Back to Trial)"
            pt = "Restaurar Original (Voltar ao Trial)"
            es = "Restaurar Original (Volver a Trial)"
        }
        "menu_3" = @{
            en = "Open Minecraft"
            pt = "Abrir Minecraft"
            es = "Abrir Minecraft"
        }
        "menu_4" = @{
            en = "Install Minecraft (Xbox App)"
            pt = "Instalar Minecraft (Xbox App)"
            es = "Instalar Minecraft (Xbox App)"
        }
        "menu_5" = @{
            en = "Check Status"
            pt = "Verificar Status"
            es = "Verificar Estado"
        }
        "menu_6" = @{
            en = "System Diagnostics"
            pt = "Diagnostico do Sistema"
            es = "Diagnostico del Sistema"
        }
        "menu_0" = @{
            en = "Exit"
            pt = "Sair"
            es = "Salir"
        }
        "choose" = @{
            en = "Choose an option"
            pt = "Escolha uma opcao"
            es = "Elija una opcion"
        }
        "invalid" = @{
            en = "Invalid option!"
            pt = "Opcao invalida!"
            es = "Opcion invalida!"
        }
        "mc_not_found" = @{
            en = "Minecraft NOT FOUND!"
            pt = "Minecraft NAO ENCONTRADO!"
            es = "Minecraft NO ENCONTRADO!"
        }
        "mc_found" = @{
            en = "Minecraft found"
            pt = "Minecraft encontrado"
            es = "Minecraft encontrado"
        }
        "mc_path" = @{
            en = "Path"
            pt = "Caminho"
            es = "Ruta"
        }
        "installing" = @{
            en = "Installing bypass..."
            pt = "Instalando bypass..."
            es = "Instalando bypass..."
        }
        "adding_exclusions" = @{
            en = "Adding antivirus exclusions..."
            pt = "Adicionando exclusoes de antivirus..."
            es = "Agregando exclusiones de antivirus..."
        }
        "exclusion_added" = @{
            en = "Windows Defender exclusion added"
            pt = "Exclusao do Windows Defender adicionada"
            es = "Exclusion de Windows Defender agregada"
        }
        "exclusion_failed" = @{
            en = "Could not add exclusion (may need manual setup)"
            pt = "Nao foi possivel adicionar exclusao (pode precisar configurar manualmente)"
            es = "No se pudo agregar exclusion (puede necesitar configuracion manual)"
        }
        "downloading" = @{
            en = "Downloading"
            pt = "Baixando"
            es = "Descargando"
        }
        "download_ok" = @{
            en = "Downloaded successfully"
            pt = "Baixado com sucesso"
            es = "Descargado exitosamente"
        }
        "download_fail" = @{
            en = "Download FAILED"
            pt = "Download FALHOU"
            es = "Descarga FALLO"
        }
        "hash_ok" = @{
            en = "Integrity verified"
            pt = "Integridade verificada"
            es = "Integridad verificada"
        }
        "hash_fail" = @{
            en = "INTEGRITY CHECK FAILED! File may be corrupted."
            pt = "VERIFICACAO DE INTEGRIDADE FALHOU! Arquivo pode estar corrompido."
            es = "VERIFICACION DE INTEGRIDAD FALLO! Archivo puede estar corrupto."
        }
        "install_ok" = @{
            en = "Bypass installed successfully!"
            pt = "Bypass instalado com sucesso!"
            es = "Bypass instalado exitosamente!"
        }
        "install_fail" = @{
            en = "Installation failed"
            pt = "Instalacao falhou"
            es = "Instalacion fallo"
        }
        "verifying" = @{
            en = "Verifying installation..."
            pt = "Verificando instalacao..."
            es = "Verificando instalacion..."
        }
        "files_ok" = @{
            en = "All files present and verified!"
            pt = "Todos os arquivos presentes e verificados!"
            es = "Todos los archivos presentes y verificados!"
        }
        "files_missing" = @{
            en = "FILES WERE DELETED BY ANTIVIRUS!"
            pt = "ARQUIVOS FORAM DELETADOS PELO ANTIVIRUS!"
            es = "ARCHIVOS FUERON ELIMINADOS POR EL ANTIVIRUS!"
        }
        "retry_install" = @{
            en = "Retrying installation..."
            pt = "Tentando novamente..."
            es = "Reintentando instalacion..."
        }
        "av_disable" = @{
            en = "PLEASE DISABLE YOUR ANTIVIRUS TEMPORARILY:"
            pt = "POR FAVOR DESATIVE SEU ANTIVIRUS TEMPORARIAMENTE:"
            es = "POR FAVOR DESACTIVE SU ANTIVIRUS TEMPORALMENTE:"
        }
        "av_step1" = @{
            en = "1. Open Windows Security"
            pt = "1. Abra Seguranca do Windows"
            es = "1. Abra Seguridad de Windows"
        }
        "av_step2" = @{
            en = "2. Go to Virus & threat protection"
            pt = "2. Va em Protecao contra virus e ameacas"
            es = "2. Vaya a Proteccion contra virus y amenazas"
        }
        "av_step3" = @{
            en = "3. Click 'Manage settings'"
            pt = "3. Clique em 'Gerenciar configuracoes'"
            es = "3. Haga clic en 'Administrar configuracion'"
        }
        "av_step4" = @{
            en = "4. Turn OFF Real-time protection"
            pt = "4. Desative a Protecao em tempo real"
            es = "4. Desactive la Proteccion en tiempo real"
        }
        "av_step5" = @{
            en = "5. Run this script again"
            pt = "5. Execute este script novamente"
            es = "5. Ejecute este script nuevamente"
        }
        "av_folder" = @{
            en = "OR add this folder to exclusions:"
            pt = "OU adicione esta pasta as exclusoes:"
            es = "O agregue esta carpeta a las exclusiones:"
        }
        "removing" = @{
            en = "Removing bypass files..."
            pt = "Removendo arquivos do bypass..."
            es = "Eliminando archivos del bypass..."
        }
        "removed_ok" = @{
            en = "Bypass removed successfully! Game restored to Trial."
            pt = "Bypass removido com sucesso! Jogo restaurado para Trial."
            es = "Bypass eliminado exitosamente! Juego restaurado a Trial."
        }
        "opening_mc" = @{
            en = "Opening Minecraft..."
            pt = "Abrindo Minecraft..."
            es = "Abriendo Minecraft..."
        }
        "mc_opened" = @{
            en = "Minecraft should open shortly"
            pt = "Minecraft deve abrir em breve"
            es = "Minecraft deberia abrirse pronto"
        }
        "opening_xbox" = @{
            en = "Opening Xbox App / Minecraft page..."
            pt = "Abrindo Xbox App / pagina do Minecraft..."
            es = "Abriendo Xbox App / pagina de Minecraft..."
        }
        "status_title" = @{
            en = "SYSTEM STATUS"
            pt = "STATUS DO SISTEMA"
            es = "ESTADO DEL SISTEMA"
        }
        "status_mc" = @{
            en = "Minecraft Installed"
            pt = "Minecraft Instalado"
            es = "Minecraft Instalado"
        }
        "status_type" = @{
            en = "Installation Type"
            pt = "Tipo de Instalacao"
            es = "Tipo de Instalacion"
        }
        "status_xbox" = @{
            en = "Xbox App (GDK) - Compatible"
            pt = "Xbox App (GDK) - Compativel"
            es = "Xbox App (GDK) - Compatible"
        }
        "status_store" = @{
            en = "Microsoft Store (UWP) - NOT COMPATIBLE!"
            pt = "Microsoft Store (UWP) - NAO COMPATIVEL!"
            es = "Microsoft Store (UWP) - NO COMPATIBLE!"
        }
        "status_bypass" = @{
            en = "Bypass Status"
            pt = "Status do Bypass"
            es = "Estado del Bypass"
        }
        "status_installed" = @{
            en = "INSTALLED"
            pt = "INSTALADO"
            es = "INSTALADO"
        }
        "status_not_installed" = @{
            en = "NOT INSTALLED"
            pt = "NAO INSTALADO"
            es = "NO INSTALADO"
        }
        "status_partial" = @{
            en = "PARTIAL (files missing - antivirus deleted them?)"
            pt = "PARCIAL (arquivos faltando - antivirus deletou?)"
            es = "PARCIAL (archivos faltantes - antivirus los elimino?)"
        }
        "status_av" = @{
            en = "Antivirus"
            pt = "Antivirus"
            es = "Antivirus"
        }
        "status_defender_on" = @{
            en = "Windows Defender (ACTIVE)"
            pt = "Windows Defender (ATIVO)"
            es = "Windows Defender (ACTIVO)"
        }
        "status_defender_off" = @{
            en = "Windows Defender (Disabled)"
            pt = "Windows Defender (Desativado)"
            es = "Windows Defender (Desactivado)"
        }
        "status_gaming" = @{
            en = "Gaming Services"
            pt = "Servicos de Jogos"
            es = "Servicios de Juegos"
        }
        "status_running" = @{
            en = "Running"
            pt = "Rodando"
            es = "Ejecutandose"
        }
        "status_stopped" = @{
            en = "Stopped"
            pt = "Parado"
            es = "Detenido"
        }
        "diag_title" = @{
            en = "SYSTEM DIAGNOSTICS"
            pt = "DIAGNOSTICO DO SISTEMA"
            es = "DIAGNOSTICO DEL SISTEMA"
        }
        "diag_xbox_app" = @{
            en = "Xbox App"
            pt = "Xbox App"
            es = "Xbox App"
        }
        "diag_mc_install" = @{
            en = "Minecraft Installation"
            pt = "Instalacao do Minecraft"
            es = "Instalacion de Minecraft"
        }
        "diag_type" = @{
            en = "Installation Type"
            pt = "Tipo de Instalacao"
            es = "Tipo de Instalacion"
        }
        "diag_permissions" = @{
            en = "Folder Permissions"
            pt = "Permissoes de Pasta"
            es = "Permisos de Carpeta"
        }
        "diag_gaming" = @{
            en = "Gaming Services"
            pt = "Servicos de Jogos"
            es = "Servicios de Juegos"
        }
        "diag_integrity" = @{
            en = "Game Integrity"
            pt = "Integridade do Jogo"
            es = "Integridad del Juego"
        }
        "diag_bypass" = @{
            en = "Bypass Files"
            pt = "Arquivos do Bypass"
            es = "Archivos del Bypass"
        }
        "diag_all_ok" = @{
            en = "All checks passed! System is ready."
            pt = "Todas as verificacoes passaram! Sistema pronto."
            es = "Todas las verificaciones pasaron! Sistema listo."
        }
        "yes" = @{ en = "Yes"; pt = "Sim"; es = "Si" }
        "no" = @{ en = "No"; pt = "Nao"; es = "No" }
        "ok" = @{ en = "OK"; pt = "OK"; es = "OK" }
        "found" = @{ en = "Found"; pt = "Encontrado"; es = "Encontrado" }
        "not_found" = @{ en = "Not Found"; pt = "Nao encontrado"; es = "No encontrado" }
        "writable" = @{ en = "Writable"; pt = "Gravavel"; es = "Escribible" }
        "no_write" = @{ en = "No write access"; pt = "Sem acesso de escrita"; es = "Sin acceso de escritura" }
        "open_now" = @{
            en = "You can now open Minecraft from the Start Menu!"
            pt = "Agora voce pode abrir o Minecraft pelo Menu Iniciar!"
            es = "Ahora puede abrir Minecraft desde el Menu Inicio!"
        }
        "mc_running" = @{
            en = "Minecraft is running. Closing it first..."
            pt = "Minecraft esta rodando. Fechando primeiro..."
            es = "Minecraft esta ejecutandose. Cerrando primero..."
        }
        "press_enter" = @{
            en = "Press Enter to continue..."
            pt = "Pressione Enter para continuar..."
            es = "Presione Enter para continuar..."
        }
        "exiting" = @{
            en = "Exiting... Goodbye!"
            pt = "Saindo... Ate mais!"
            es = "Saliendo... Hasta luego!"
        }
        "start_gaming" = @{
            en = "Starting Gaming Services..."
            pt = "Iniciando Gaming Services..."
            es = "Iniciando Gaming Services..."
        }
        "install_xbox_hint" = @{
            en = "Install Minecraft Trial from Xbox App (NOT Microsoft Store!)"
            pt = "Instale o Minecraft Trial pelo Xbox App (NAO Microsoft Store!)"
            es = "Instale Minecraft Trial desde Xbox App (NO Microsoft Store!)"
        }
        "repair_hint" = @{
            en = "Repair or reinstall Minecraft from Xbox App"
            pt = "Repare ou reinstale o Minecraft pelo Xbox App"
            es = "Repare o reinstale Minecraft desde Xbox App"
        }
        "run_admin_hint" = @{
            en = "Run this script as Administrator"
            pt = "Execute este script como Administrador"
            es = "Ejecute este script como Administrador"
        }
        "restart_gaming_hint" = @{
            en = "Restart Gaming Services or reinstall Xbox App"
            pt = "Reinicie os Servicos de Jogos ou reinstale o Xbox App"
            es = "Reinicie los Servicios de Juegos o reinstale Xbox App"
        }
    }
    
    $entry = $translations[$Key]
    if ($entry -and $entry[$Script:Lang]) {
        return $entry[$Script:Lang]
    } elseif ($entry -and $entry["en"]) {
        return $entry["en"]
    }
    return $Key
}

# ============================================================================
# UI Functions
# ============================================================================

function Write-C {
    param([string]$Text, [ConsoleColor]$Color = 'White', [switch]$NoNewline)
    if ($NoNewline) {
        Write-Host $Text -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $Text -ForegroundColor $Color
    }
}

function Write-OK     { param([string]$Msg)  Write-C "  [OK] $Msg" Green }
function Write-Err    { param([string]$Msg)  Write-C "  [ERROR] $Msg" Red }
function Write-Warn   { param([string]$Msg)  Write-C "  [!] $Msg" Yellow }
function Write-Info   { param([string]$Msg)  Write-C "  [*] $Msg" Cyan }
function Write-Line   { Write-C "  ============================================================" DarkGray }

function Show-Banner {
    Clear-Host
    Write-C ""
    Write-C "  ============================================================" Cyan
    Write-C "   __  __ _                            __ _   " Cyan
    Write-C "  |  \/  (_)_ __   ___  ___ _ __ __ _ / _| |_ " Cyan
    Write-C "  | |\/| | | '_ \ / _ \/ __| '__/ _' | |_| __|" Cyan
    Write-C "  | |  | | | | | |  __/ (__| | | (_| |  _| |_ " Cyan
    Write-C "  |_|  |_|_|_| |_|\___|\___|_|  \__,_|_|  \__|" Cyan
    Write-C "     ____           _                 _        " Cyan
    Write-C "    | __ )  ___  __| |_ __ ___   ___| | __    " Cyan
    Write-C "    |  _ \ / _ \/ _' | '__/ _ \ / __| |/ /    " Cyan
    Write-C "    | |_) |  __/ (_| | | | (_) | (__|   <     " Cyan
    Write-C "    |____/ \___|\__,_|_|  \___/ \___|_|\_\    " Cyan
    Write-C "                     Unlocker by CoelhoFZ      " Cyan
    Write-C "  ============================================================" Cyan
    Write-C "                         v$Script:Version (PowerShell)" DarkGray
    Write-C ""
}

function Show-Menu {
    Write-C ""
    Write-C "              $(T 'menu_title')" Green
    Write-C ""
    Write-C "              " -NoNewline; Write-C "[1]" Green -NoNewline; Write-C " $(T 'menu_1')"
    Write-C "              " -NoNewline; Write-C "[2]" Green -NoNewline; Write-C " $(T 'menu_2')"
    Write-C "              " -NoNewline; Write-C "[3]" Green -NoNewline; Write-C " $(T 'menu_3')"
    Write-C "              " -NoNewline; Write-C "[4]" Yellow -NoNewline; Write-C " $(T 'menu_4')"
    Write-C "              " -NoNewline; Write-C "[5]" Cyan -NoNewline; Write-C " $(T 'menu_5')"
    Write-C "              " -NoNewline; Write-C "[6]" Cyan -NoNewline; Write-C " $(T 'menu_6')"
    Write-C "              " -NoNewline; Write-C "[0]" Red -NoNewline; Write-C " $(T 'menu_0')"
    Write-C ""
    Write-Line
    Write-C ""
}

function Wait-Enter {
    Write-C ""
    Write-C "  $(T 'press_enter')" DarkGray
    $null = Read-Host
}

# ============================================================================
# Core Functions
# ============================================================================

function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Request-Elevation {
    Write-Warn (T 'admin_required')
    Write-Info (T 'admin_elevating')
    
    try {
        $scriptUrl = "$Script:BaseUrl/install.ps1"
        $cmd = "Set-ExecutionPolicy Bypass -Scope Process -Force; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iex (irm '$scriptUrl')"
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$cmd`"" -Verb RunAs
        # Close this (non-admin) window automatically after 2 seconds
        Write-OK "Elevated window opened. This window will close..."
        Start-Sleep -Seconds 2
        exit
    }
    catch {
        Write-Err "Failed to elevate. Please run PowerShell as Administrator."
        Write-Warn "  Right-click PowerShell -> Run as administrator"
        Wait-Enter
    }
}

function Find-MinecraftPath {
    # Priority 1: XboxGames on all drives (GDK install - compatible)
    $drives = @("C") + @((Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[D-Z]:\\$' }).Name)
    foreach ($driveLetter in $drives) {
        $path = "${driveLetter}:\XboxGames\Minecraft for Windows\Content"
        if (Test-Path $path) { return $path }
    }

    # Priority 2: WindowsApps (UWP - not recommended but detect it)
    $programFiles = $env:ProgramFiles
    if (-not $programFiles) { $programFiles = "C:\Program Files" }
    $windowsApps = Join-Path $programFiles "WindowsApps"
    
    if (Test-Path $windowsApps) {
        try {
            $mcFolders = Get-ChildItem $windowsApps -Directory -ErrorAction SilentlyContinue | 
                         Where-Object { $_.Name -like "Microsoft.Minecraft*8wekyb3d8bbwe*" }
            foreach ($folder in $mcFolders) {
                $contentPath = Join-Path $folder.FullName "Content"
                if (Test-Path $contentPath) { return $contentPath }
            }
        } catch { }
    }

    return $null
}

function Test-MinecraftRunning {
    $processes = Get-Process -Name "Minecraft.Windows" -ErrorAction SilentlyContinue
    return ($null -ne $processes)
}

function Stop-Minecraft {
    Write-Warn (T 'mc_running')
    Get-Process -Name "Minecraft.Windows" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 3
}

function Test-DefenderActive {
    try {
        $status = Get-MpComputerStatus -ErrorAction SilentlyContinue
        return $status.RealTimeProtectionEnabled
    } catch {
        return $false
    }
}

function Add-DefenderExclusion {
    param([string]$Path)
    
    Write-Info (T 'adding_exclusions')
    
    try {
        # Add folder exclusion
        Add-MpPreference -ExclusionPath $Path -ErrorAction SilentlyContinue
        
        # Also add individual file exclusions for the DLLs
        $dllFiles = @("winmm.dll", "OnlineFix64.dll")
        foreach ($dll in $dllFiles) {
            $dllPath = Join-Path $Path $dll
            Add-MpPreference -ExclusionPath $dllPath -ErrorAction SilentlyContinue
        }
        
        # Also add process exclusion
        Add-MpPreference -ExclusionProcess "Minecraft.Windows.exe" -ErrorAction SilentlyContinue
        
        Write-OK (T 'exclusion_added')
        return $true
    }
    catch {
        Write-Warn (T 'exclusion_failed')
        return $false
    }
}

function Download-OnlineFixFile {
    param([string]$FileName, [string]$DestPath, [string]$ExpectedHash)
    
    $url = "$Script:BaseUrl/dlls/OnlineFix/$FileName"
    $destFile = Join-Path $DestPath $FileName
    
    Write-Info "$(T 'downloading') $FileName..."
    
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $url -OutFile $destFile -UseBasicParsing -TimeoutSec 120
        
        if (-not (Test-Path $destFile)) {
            Write-Err "$(T 'download_fail'): $FileName"
            return $false
        }
        
        # Verify hash
        $actualHash = (Get-FileHash -Path $destFile -Algorithm SHA256).Hash.ToLower()
        if ($actualHash -ne $ExpectedHash) {
            Write-Warn "$(T 'hash_fail') ($FileName)"
            Write-Warn "  Expected: $ExpectedHash"
            Write-Warn "  Got:      $actualHash"
        } else {
            Write-OK "$(T 'hash_ok'): $FileName"
        }
        
        Write-OK "$(T 'download_ok'): $FileName"
        return $true
    }
    catch {
        Write-Err "$(T 'download_fail'): $FileName - $_"
        return $false
    }
}

function Verify-Installation {
    param([string]$ContentPath)
    
    $allPresent = $true
    $missing = @()
    
    foreach ($file in $Script:OnlineFixFiles) {
        $filePath = Join-Path $ContentPath $file.Name
        if (-not (Test-Path $filePath)) {
            $allPresent = $false
            $missing += $file.Name
        }
    }
    
    return @{
        AllPresent = $allPresent
        Missing = $missing
    }
}

# Legacy bypass file names from older versions (OpenFix, FakeGDK, etc.)
$Script:LegacyBypassFiles = @(
    "OpenFix.ini", "OpenFix64.dll", "OpenFix.log",
    "winmm_orig.dll", "FakeGDK.log", "FullBypass.log",
    "DirectHook.log", "Monitor.log", "VPMon.log", "XStore.log"
)

function Test-LegacyBypass {
    param([string]$ContentPath)
    
    $found = @()
    foreach ($file in $Script:LegacyBypassFiles) {
        $filePath = Join-Path $ContentPath $file
        if (Test-Path $filePath) {
            $found += $file
        }
    }
    return $found
}

function Remove-LegacyBypass {
    param([string]$ContentPath)
    
    $legacy = Test-LegacyBypass -ContentPath $ContentPath
    if ($legacy.Count -gt 0) {
        Write-Warn "Legacy bypass detected! Cleaning $($legacy.Count) old files..."
        foreach ($file in $legacy) {
            $filePath = Join-Path $ContentPath $file
            try {
                Remove-Item -Path $filePath -Force
                Write-OK "Removed legacy: $file"
            } catch {
                Write-Warn "Failed to remove: $file"
            }
        }
        Write-C ""
        return $true
    }
    return $false
}

function Test-GamingServices {
    try {
        $service = Get-Service -Name GamingServices -ErrorAction SilentlyContinue
        return ($service -and $service.Status -eq 'Running')
    } catch {
        return $false
    }
}

function Start-GamingServices {
    Write-Info (T 'start_gaming')
    try {
        Start-Service GamingServices -ErrorAction SilentlyContinue
    } catch { }
}

# ============================================================================
# Menu Actions
# ============================================================================

function Install-Bypass {
    $mcPath = Find-MinecraftPath
    
    if (-not $mcPath) {
        Write-Err (T 'mc_not_found')
        Write-C ""
        Write-Warn (T 'install_xbox_hint')
        Write-C ""
        Write-Info "Xbox App: https://www.xbox.com/games/store/minecraft-for-windows/9NBLGGH2JHXJ"
        Wait-Enter
        return
    }
    
    Write-OK "$(T 'mc_found'): $mcPath"
    Write-C ""
    
    # Check installation type
    if ($mcPath -like "*WindowsApps*") {
        Write-Err (T 'status_store')
        Write-Warn "This version is NOT compatible. Uninstall and reinstall from Xbox App."
        Wait-Enter
        return
    }
    
    # Check if MC is running
    if (Test-MinecraftRunning) {
        Stop-Minecraft
    }
    
    # Detect and remove legacy bypass (OpenFix, FakeGDK, etc.)
    Remove-LegacyBypass -ContentPath $mcPath
    
    # Add antivirus exclusions FIRST
    if (Test-DefenderActive) {
        Add-DefenderExclusion -Path $mcPath
    }
    
    # Small delay for exclusions to take effect
    Start-Sleep -Milliseconds 500
    
    Write-C ""
    Write-Info (T 'installing')
    Write-C ""
    
    # Download all OnlineFix files
    $allSuccess = $true
    foreach ($file in $Script:OnlineFixFiles) {
        $result = Download-OnlineFixFile -FileName $file.Name -DestPath $mcPath -ExpectedHash $file.Hash
        if (-not $result) { $allSuccess = $false }
    }
    
    if (-not $allSuccess) {
        Write-C ""
        Write-Err (T 'install_fail')
        Wait-Enter
        return
    }
    
    # Wait and verify
    Write-C ""
    Write-Info (T 'verifying')
    Start-Sleep -Seconds 3
    
    $verification = Verify-Installation -ContentPath $mcPath
    
    if ($verification.AllPresent) {
        Write-C ""
        Write-OK (T 'files_ok')
        Write-C ""
        Write-OK (T 'install_ok')
        Write-C ""
        Write-Info (T 'open_now')
    }
    else {
        Write-C ""
        Write-Err (T 'files_missing')
        foreach ($f in $verification.Missing) {
            Write-Warn "    - $f"
        }
        Write-C ""
        
        # Retry once
        Write-Info (T 'retry_install')
        Start-Sleep -Seconds 1
        
        foreach ($file in $Script:OnlineFixFiles) {
            $filePath = Join-Path $mcPath $file.Name
            if (-not (Test-Path $filePath)) {
                $null = Download-OnlineFixFile -FileName $file.Name -DestPath $mcPath -ExpectedHash $file.Hash
            }
        }
        
        Start-Sleep -Seconds 3
        $verification2 = Verify-Installation -ContentPath $mcPath
        
        if ($verification2.AllPresent) {
            Write-OK (T 'install_ok')
        }
        else {
            Write-C ""
            Write-Err (T 'av_disable')
            Write-C ""
            Write-Warn "  $(T 'av_step1')"
            Write-Warn "  $(T 'av_step2')"
            Write-Warn "  $(T 'av_step3')"
            Write-Warn "  $(T 'av_step4')"
            Write-Warn "  $(T 'av_step5')"
            Write-C ""
            Write-Info "$(T 'av_folder')"
            Write-C "    $mcPath" Yellow
        }
    }
    
    Wait-Enter
}

function Restore-Original {
    $mcPath = Find-MinecraftPath
    
    if (-not $mcPath) {
        Write-Err (T 'mc_not_found')
        Wait-Enter
        return
    }
    
    if (Test-MinecraftRunning) {
        Stop-Minecraft
    }
    
    Write-Info (T 'removing')
    Write-C ""
    
    # Current OnlineFix files + legacy OpenFix/bypass file names
    $filesToRemove = @(
        # Current OnlineFix
        "winmm.dll", "OnlineFix64.dll", "dlllist.txt", "OnlineFix.ini",
        # Legacy OpenFix (older bypass versions)
        "OpenFix.ini", "OpenFix64.dll", "OpenFix.log",
        # Legacy backup/logs
        "winmm_orig.dll", "FakeGDK.log", "FullBypass.log",
        "DirectHook.log", "Monitor.log", "VPMon.log", "XStore.log"
    )
    
    $removedCount = 0
    foreach ($file in $filesToRemove) {
        $filePath = Join-Path $mcPath $file
        if (Test-Path $filePath) {
            try {
                Remove-Item -Path $filePath -Force
                Write-OK "Removed: $file"
                $removedCount++
            }
            catch {
                Write-Warn "Failed to remove: $file - $_"
            }
        }
    }
    
    if ($removedCount -eq 0) {
        Write-Info "No bypass files found to remove."
    }
    
    Write-C ""
    Write-OK (T 'removed_ok')
    Wait-Enter
}

function Open-Minecraft {
    $mcPath = Find-MinecraftPath
    
    # Health check before opening
    if ($mcPath) {
        $verification = Verify-Installation -ContentPath $mcPath
        if (-not $verification.AllPresent -and $verification.Missing.Count -lt 4) {
            Write-Warn "$(T 'files_missing') Auto-repair..."
            if (Test-DefenderActive) {
                Add-DefenderExclusion -Path $mcPath
                Start-Sleep -Milliseconds 500
            }
            foreach ($file in $Script:OnlineFixFiles) {
                $filePath = Join-Path $mcPath $file.Name
                if (-not (Test-Path $filePath)) {
                    $null = Download-OnlineFixFile -FileName $file.Name -DestPath $mcPath -ExpectedHash $file.Hash
                }
            }
        }
    }
    
    # Check Gaming Services
    if (-not (Test-GamingServices)) {
        Start-GamingServices
        Start-Sleep -Seconds 2
    }
    
    Write-Info (T 'opening_mc')
    try {
        Start-Process "minecraft:" -ErrorAction SilentlyContinue
        Write-OK (T 'mc_opened')
    } catch {
        Write-Warn "Could not open via protocol. Trying shell:AppsFolder..."
        try {
            Start-Process "shell:AppsFolder\Microsoft.MinecraftUWP_8wekyb3d8bbwe!App" -ErrorAction SilentlyContinue
            Write-OK (T 'mc_opened')
        } catch {
            Write-Err "Failed to open Minecraft. Please open manually."
        }
    }
    Wait-Enter
}

function Open-XboxApp {
    Write-Info (T 'opening_xbox')
    try {
        Start-Process "ms-windows-store://pdp?productId=9NBLGGH2JHXJ" -ErrorAction SilentlyContinue
    } catch {
        Start-Process "https://www.xbox.com/games/store/minecraft-for-windows/9NBLGGH2JHXJ"
    }
    Wait-Enter
}

function Show-Status {
    $mcPath = Find-MinecraftPath
    
    Write-Line
    Write-C "                    $(T 'status_title')" Cyan
    Write-Line
    Write-C ""
    
    # Minecraft installed?
    Write-C "  $(T 'status_mc'):   " -NoNewline
    if ($mcPath) {
        Write-C (T 'yes') Green
        Write-C "  $(T 'mc_path'): $mcPath" DarkGray
        
        # Installation type
        Write-C "  $(T 'status_type'):  " -NoNewline
        if ($mcPath -like "*XboxGames*") {
            Write-C (T 'status_xbox') Green
        } elseif ($mcPath -like "*WindowsApps*") {
            Write-C (T 'status_store') Red
        } else {
            Write-C "Unknown" Yellow
        }
    }
    else {
        Write-C (T 'no') Red
    }
    
    Write-C ""
    
    # Bypass status
    Write-C "  $(T 'status_bypass'):  " -NoNewline
    if ($mcPath) {
        $verification = Verify-Installation -ContentPath $mcPath
        $legacy = Test-LegacyBypass -ContentPath $mcPath
        if ($verification.AllPresent) {
            Write-C (T 'status_installed') Green
        } elseif ($verification.Missing.Count -lt 4) {
            Write-C (T 'status_partial') Yellow
            foreach ($f in $verification.Missing) {
                Write-C "    - $f" Yellow
            }
        } else {
            Write-C (T 'status_not_installed') Red
        }
        # Show legacy bypass warning
        if ($legacy.Count -gt 0) {
            Write-C "" 
            Write-C "  [!] Legacy bypass detected:" Yellow
            foreach ($f in $legacy) {
                Write-C "    - $f" Yellow
            }
            Write-C "    -> Use [2] Restore to clean, then [1] Install" Yellow
        }
    } else {
        Write-C "N/A" DarkGray
    }
    
    Write-C ""
    
    # Antivirus
    Write-C "  $(T 'status_av'):      " -NoNewline
    if (Test-DefenderActive) {
        Write-C (T 'status_defender_on') Yellow
    } else {
        Write-C (T 'status_defender_off') Green
    }
    
    # Gaming Services
    Write-C "  $(T 'status_gaming'):   " -NoNewline
    if (Test-GamingServices) {
        Write-C (T 'status_running') Green
    } else {
        Write-C (T 'status_stopped') Red
    }
    
    Write-C ""
    Write-Line
    Wait-Enter
}

function Show-Diagnostics {
    $mcPath = Find-MinecraftPath
    
    Write-Line
    Write-C "                    $(T 'diag_title')" Cyan
    Write-Line
    Write-C ""
    
    $checks = @()
    
    # 1. Xbox App
    $xboxApp = $null
    try {
        $xboxApp = Get-AppxPackage -Name Microsoft.GamingApp -ErrorAction SilentlyContinue
    } catch { }
    $xboxInstalled = ($null -ne $xboxApp)
    $checks += @{
        Name = T 'diag_xbox_app'
        Passed = $xboxInstalled
        Message = if ($xboxInstalled) { T 'found' } else { T 'not_found' }
        Hint = if (-not $xboxInstalled) { "Install Xbox App from Microsoft Store" } else { $null }
    }
    
    # 2. Minecraft Installation
    $mcInstalled = ($null -ne $mcPath)
    $checks += @{
        Name = T 'diag_mc_install'
        Passed = $mcInstalled
        Message = if ($mcInstalled) { "$(T 'found'): $mcPath" } else { T 'not_found' }
        Hint = if (-not $mcInstalled) { T 'install_xbox_hint' } else { $null }
    }
    
    # 3. Installation Type
    $isGDK = $mcPath -and ($mcPath -like "*XboxGames*")
    $checks += @{
        Name = T 'diag_type'
        Passed = $isGDK
        Message = if ($isGDK) { "Xbox App (GDK) - Compatible" } elseif ($mcPath) { "Microsoft Store (UWP) - NOT COMPATIBLE!" } else { "N/A" }
        Hint = if ($mcPath -and -not $isGDK) { "Uninstall and reinstall from Xbox App (NOT Microsoft Store!)" } else { $null }
    }
    
    # 4. Folder Permissions
    $canWrite = $false
    if ($mcPath) {
        try {
            $testFile = Join-Path $mcPath ".permission_test"
            Set-Content -Path $testFile -Value "test" -ErrorAction Stop
            Remove-Item $testFile -Force
            $canWrite = $true
        } catch { }
    }
    $checks += @{
        Name = T 'diag_permissions'
        Passed = $canWrite
        Message = if ($canWrite) { T 'writable' } elseif ($mcPath) { T 'no_write' } else { "N/A" }
        Hint = if ($mcPath -and -not $canWrite) { T 'run_admin_hint' } else { $null }
    }
    
    # 5. Gaming Services
    $gamingOk = Test-GamingServices
    $checks += @{
        Name = T 'diag_gaming'
        Passed = $gamingOk
        Message = if ($gamingOk) { T 'status_running' } else { T 'status_stopped' }
        Hint = if (-not $gamingOk) { T 'restart_gaming_hint' } else { $null }
    }
    
    # 6. Game Integrity
    $gameExeOk = $false
    if ($mcPath) {
        $gameExeOk = Test-Path (Join-Path $mcPath "Minecraft.Windows.exe")
        if (-not $gameExeOk) {
            $parent = Split-Path $mcPath -Parent
            $gameExeOk = Test-Path (Join-Path $parent "Minecraft.Windows.exe")
        }
    }
    $checks += @{
        Name = T 'diag_integrity'
        Passed = $gameExeOk
        Message = if ($gameExeOk) { T 'ok' } else { "Possibly corrupted" }
        Hint = if (-not $gameExeOk -and $mcPath) { T 'repair_hint' } else { $null }
    }
    
    # 7. Bypass Files
    $bypassOk = $false
    $bypassMsg = "N/A"
    if ($mcPath) {
        $v = Verify-Installation -ContentPath $mcPath
        $bypassOk = $v.AllPresent
        if ($v.AllPresent) {
            $bypassMsg = "All files present"
        } elseif ($v.Missing.Count -lt 4) {
            $bypassMsg = "Missing: $($v.Missing -join ', ')"
        } else {
            $bypassMsg = "Not installed"
            $bypassOk = $true  # Not installed is OK, just informational
        }
    }
    $checks += @{
        Name = T 'diag_bypass'
        Passed = $bypassOk
        Message = $bypassMsg
        Hint = if (-not $bypassOk) { "Antivirus likely deleted files! Add exclusion and use [1]." } else { $null }
    }
    
    # 8. Legacy Bypass Detection
    $legacyOk = $true
    $legacyMsg = "None found"
    if ($mcPath) {
        $legacy = Test-LegacyBypass -ContentPath $mcPath
        if ($legacy.Count -gt 0) {
            $legacyOk = $false
            $legacyMsg = "FOUND $($legacy.Count) old files: $($legacy -join ', ')"
        }
    }
    $checks += @{
        Name = "Legacy Bypass"
        Passed = $legacyOk
        Message = $legacyMsg
        Hint = if (-not $legacyOk) { "Use [2] Restore to remove old bypass, then [1] Install for new version" } else { $null }
    }
    
    # Print results
    $passed = 0
    $total = $checks.Count
    
    foreach ($check in $checks) {
        $icon = if ($check.Passed) { "[OK]" } else { "[!!]" }
        $color = if ($check.Passed) { "Green" } else { "Red" }
        
        Write-C "  " -NoNewline; Write-C $icon $color -NoNewline; Write-C " $($check.Name) - $($check.Message)"
        
        if ($check.Hint) {
            Write-C "       -> $($check.Hint)" Yellow
        }
        
        if ($check.Passed) { $passed++ }
    }
    
    Write-C ""
    if ($passed -eq $total) {
        Write-OK (T 'diag_all_ok')
    } else {
        Write-Warn "$($total - $passed)/$total issues found"
    }
    
    Write-C ""
    Write-Line
    Wait-Enter
}

# ============================================================================
# Main Loop
# ============================================================================

function Start-MainLoop {
    Detect-Language
    Show-Banner
    
    # Check admin
    if (-not (Test-Admin)) {
        Request-Elevation
        return
    }
    
    Write-OK (T 'admin_ok')
    
    while ($true) {
        Show-Menu
        
        Write-C "  $(T 'choose'): " Cyan -NoNewline
        $choice = Read-Host
        
        Show-Banner
        
        switch ($choice.Trim()) {
            "1" { Install-Bypass }
            "2" { Restore-Original }
            "3" { Open-Minecraft }
            "4" { Open-XboxApp }
            "5" { Show-Status }
            "6" { Show-Diagnostics }
            "0" {
                Write-C ""
                Write-Info (T 'exiting')
                Start-Sleep -Seconds 1
                return
            }
            default { Write-Warn (T 'invalid') }
        }
    }
}

# ============================================================================
# Entry Point
# ============================================================================
Start-MainLoop
