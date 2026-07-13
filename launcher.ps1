param()

$ErrorActionPreference = 'Stop'
$Script:Version = '3.3.3'
$Script:Lang = 'en'

function Detect-Language {
    $candidates = @()

    try { $candidates += (Get-UICulture).Name } catch { }
    try { $candidates += [System.Globalization.CultureInfo]::CurrentUICulture.Name } catch { }
    try { $candidates += (Get-Culture).Name } catch { }
    try { $candidates += $env:LANG } catch { }

    foreach ($candidate in $candidates) {
        if (-not [string]::IsNullOrWhiteSpace([string]$candidate) -and
            ([string]$candidate).Trim().ToLowerInvariant().StartsWith('pt')) {
            $Script:Lang = 'pt'
            return
        }
    }

    $Script:Lang = 'en'
}

$Messages = @{
    pt = @{
        title = 'Minecraft Bedrock - Utilitario oficial'
        menu_title = 'Opcoes disponiveis'
        menu_1 = 'Instalacao de desbloqueio indisponivel'
        menu_2 = 'Remover arquivos de modificacao e restaurar estado oficial'
        menu_3 = 'Abrir Minecraft'
        menu_4 = 'Abrir Minecraft (modo alternativo)'
        menu_5 = 'Verificar status'
        menu_6 = 'Diagnostico do sistema'
        menu_0 = 'Sair'
        choose = 'Escolha uma opcao'
        invalid = 'Opcao invalida.'
        press_enter = 'Pressione ENTER para continuar...'
        exiting = 'Saindo...'
        bypass_disabled_title = 'A instalacao de desbloqueio foi desativada nesta distribuicao.'
        bypass_disabled_reason = 'Os arquivos exigidos nao existem na release e as tentativas anteriores retornaram HTTP 404.'
        bypass_disabled_safe = 'Use uma copia oficial e licenciada do Minecraft.'
        minecraft_opening = 'Abrindo o Minecraft instalado...'
        minecraft_opened = 'Comando para abrir o Minecraft enviado com sucesso.'
        minecraft_failed = 'Nao foi possivel abrir o Minecraft automaticamente.'
        minecraft_manual = 'Abra o Minecraft pelo Menu Iniciar ou pelo aplicativo Xbox.'
        minecraft_not_found = 'Minecraft nao foi localizado neste computador.'
        direct_opening = 'Tentando abrir diretamente o executavel instalado...'
        store_not_opened = 'A Microsoft Store nao sera aberta por esta opcao.'
        status_title = 'Status'
        status_installed = 'Minecraft instalado'
        status_path = 'Caminho'
        status_package = 'Aplicativo registrado'
        status_running = 'Minecraft em execucao'
        yes = 'Sim'
        no = 'Nao'
        diagnostics_title = 'Diagnostico do sistema'
        diag_windows = 'Windows detectado'
        diag_powershell = 'Windows PowerShell disponivel'
        diag_xbox = 'Aplicativo Xbox instalado'
        diag_gaming = 'Gaming Services instalado'
        diag_minecraft = 'Minecraft localizado'
        restore_title = 'Restaurar estado oficial'
        restore_warning = 'Esta opcao remove somente arquivos conhecidos de modificacao da pasta do Minecraft.'
        restore_confirm = 'Digite SIM para continuar'
        restore_cancelled = 'Operacao cancelada.'
        restore_need_admin = 'Execute este arquivo como Administrador para remover arquivos protegidos.'
        restore_none = 'Nenhum arquivo conhecido de modificacao foi encontrado.'
        restore_removed = 'Arquivo removido'
        restore_failed = 'Nao foi possivel remover'
        restore_done = 'Limpeza concluida.'
    }
    en = @{
        title = 'Minecraft Bedrock - Official utility'
        menu_title = 'Available options'
        menu_1 = 'Unlock installation unavailable'
        menu_2 = 'Remove modification files and restore official state'
        menu_3 = 'Open Minecraft'
        menu_4 = 'Open Minecraft (alternative method)'
        menu_5 = 'Check status'
        menu_6 = 'System diagnostics'
        menu_0 = 'Exit'
        choose = 'Choose an option'
        invalid = 'Invalid option.'
        press_enter = 'Press ENTER to continue...'
        exiting = 'Exiting...'
        bypass_disabled_title = 'Unlock installation is disabled in this distribution.'
        bypass_disabled_reason = 'The required files are not present in the release and previous attempts returned HTTP 404.'
        bypass_disabled_safe = 'Use an official, licensed copy of Minecraft.'
        minecraft_opening = 'Opening the installed Minecraft app...'
        minecraft_opened = 'Minecraft launch command sent successfully.'
        minecraft_failed = 'Minecraft could not be opened automatically.'
        minecraft_manual = 'Open Minecraft from the Start menu or the Xbox app.'
        minecraft_not_found = 'Minecraft was not found on this computer.'
        direct_opening = 'Trying to open the installed executable directly...'
        store_not_opened = 'This option will not open Microsoft Store.'
        status_title = 'Status'
        status_installed = 'Minecraft installed'
        status_path = 'Path'
        status_package = 'App registered'
        status_running = 'Minecraft running'
        yes = 'Yes'
        no = 'No'
        diagnostics_title = 'System diagnostics'
        diag_windows = 'Windows detected'
        diag_powershell = 'Windows PowerShell available'
        diag_xbox = 'Xbox app installed'
        diag_gaming = 'Gaming Services installed'
        diag_minecraft = 'Minecraft found'
        restore_title = 'Restore official state'
        restore_warning = 'This option removes only known modification files from the Minecraft folder.'
        restore_confirm = 'Type YES to continue'
        restore_cancelled = 'Operation cancelled.'
        restore_need_admin = 'Run this file as Administrator to remove protected files.'
        restore_none = 'No known modification files were found.'
        restore_removed = 'Removed'
        restore_failed = 'Could not remove'
        restore_done = 'Cleanup completed.'
    }
}

function T {
    param([Parameter(Mandatory = $true)][string]$Key)

    $languageTable = $Messages[$Script:Lang]
    if ($languageTable -and $languageTable.ContainsKey($Key)) {
        return [string]$languageTable[$Key]
    }

    if ($Messages.en.ContainsKey($Key)) {
        return [string]$Messages.en[$Key]
    }

    return $Key
}

function Write-Info {
    param([string]$Text)
    Write-Host "  [*] $Text" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Text)
    Write-Host "  [OK] $Text" -ForegroundColor Green
}

function Write-WarningLine {
    param([string]$Text)
    Write-Host "  [!] $Text" -ForegroundColor Yellow
}

function Write-ErrorLine {
    param([string]$Text)
    Write-Host "  [ERRO] $Text" -ForegroundColor Red
}

function Wait-Enter {
    Write-Host ''
    [void](Read-Host "  $(T 'press_enter')")
}

function Test-Administrator {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

function Get-MinecraftExecutable {
    $candidatePaths = New-Object System.Collections.Generic.List[string]

    foreach ($drive in Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue) {
        if (-not $drive.Root) { continue }

        $candidatePaths.Add((Join-Path $drive.Root 'XboxGames\Minecraft for Windows\Content\Minecraft.Windows.exe'))
        $candidatePaths.Add((Join-Path $drive.Root 'XboxGames\Minecraft Launcher\Content\Minecraft.Windows.exe'))
    }

    try {
        $package = Get-AppxPackage -Name 'MICROSOFT.MINECRAFTUWP' -ErrorAction SilentlyContinue
        if ($package -and $package.InstallLocation) {
            $candidatePaths.Add((Join-Path $package.InstallLocation 'Minecraft.Windows.exe'))
        }
    } catch { }

    foreach ($candidate in $candidatePaths | Select-Object -Unique) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }

    return $null
}

function Get-MinecraftStartApp {
    try {
        $apps = @(Get-StartApps -ErrorAction Stop | Where-Object {
            $_.Name -match 'Minecraft' -and
            $_.AppID -notmatch 'Store|Microsoft\.WindowsStore'
        })

        $preferred = $apps | Where-Object {
            $_.Name -match 'Minecraft for Windows|Minecraft' -and
            $_.Name -notmatch 'Launcher|Preview|Education'
        } | Select-Object -First 1

        if ($preferred) { return $preferred }
        return ($apps | Select-Object -First 1)
    } catch {
        return $null
    }
}

function Test-MinecraftRunning {
    return $null -ne (Get-Process -ErrorAction SilentlyContinue | Where-Object {
        $_.ProcessName -match 'Minecraft|Minecraft\.Windows'
    } | Select-Object -First 1)
}

function Start-MinecraftOfficial {
    param([switch]$DirectFirst)

    Write-Info (T 'minecraft_opening')
    Write-Info (T 'store_not_opened')

    $executable = Get-MinecraftExecutable
    $startApp = Get-MinecraftStartApp

    if ($DirectFirst -and $executable) {
        try {
            Write-Info (T 'direct_opening')
            Start-Process -FilePath $executable -ErrorAction Stop
            Write-Ok (T 'minecraft_opened')
            return $true
        } catch { }
    }

    if ($startApp -and $startApp.AppID) {
        try {
            Start-Process -FilePath 'explorer.exe' -ArgumentList "shell:AppsFolder\$($startApp.AppID)" -ErrorAction Stop
            Write-Ok (T 'minecraft_opened')
            return $true
        } catch { }
    }

    try {
        Start-Process -FilePath 'explorer.exe' -ArgumentList 'minecraft:' -ErrorAction Stop
        Start-Sleep -Seconds 2
        if (Test-MinecraftRunning) {
            Write-Ok (T 'minecraft_opened')
            return $true
        }
    } catch { }

    if ($executable) {
        try {
            Start-Process -FilePath $executable -ErrorAction Stop
            Write-Ok (T 'minecraft_opened')
            return $true
        } catch { }
    }

    Write-ErrorLine (T 'minecraft_failed')
    Write-WarningLine (T 'minecraft_manual')
    return $false
}

function Get-MinecraftContentPath {
    $executable = Get-MinecraftExecutable
    if ($executable) {
        return (Split-Path -Parent $executable)
    }
    return $null
}

function Show-UnlockUnavailable {
    Write-Host ''
    Write-ErrorLine (T 'bypass_disabled_title')
    Write-WarningLine (T 'bypass_disabled_reason')
    Write-Info (T 'bypass_disabled_safe')
    Wait-Enter
}

function Restore-OfficialState {
    Write-Host ''
    Write-Host "  $(T 'restore_title')" -ForegroundColor Cyan
    Write-WarningLine (T 'restore_warning')

    $contentPath = Get-MinecraftContentPath
    if (-not $contentPath) {
        Write-ErrorLine (T 'minecraft_not_found')
        Wait-Enter
        return
    }

    $expectedConfirmation = if ($Script:Lang -eq 'pt') { 'SIM' } else { 'YES' }
    $confirmation = Read-Host "  $(T 'restore_confirm')"

    if ($confirmation.Trim().ToUpperInvariant() -ne $expectedConfirmation) {
        Write-WarningLine (T 'restore_cancelled')
        Wait-Enter
        return
    }

    if (-not (Test-Administrator)) {
        Write-ErrorLine (T 'restore_need_admin')
        Wait-Enter
        return
    }

    $knownFiles = @('winmm.dll', 'OnlineFix64.dll', 'dlllist.txt', 'OnlineFix.ini')
    $found = $false

    foreach ($name in $knownFiles) {
        $path = Join-Path $contentPath $name
        if (-not (Test-Path -LiteralPath $path)) { continue }

        $found = $true
        try {
            Remove-Item -LiteralPath $path -Force -ErrorAction Stop
            Write-Ok "$(T 'restore_removed'): $name"
        } catch {
            Write-ErrorLine "$(T 'restore_failed'): $name - $($_.Exception.Message)"
        }
    }

    if (-not $found) {
        Write-Info (T 'restore_none')
    } else {
        Write-Ok (T 'restore_done')
    }

    Wait-Enter
}

function Show-Status {
    $executable = Get-MinecraftExecutable
    $startApp = Get-MinecraftStartApp
    $running = Test-MinecraftRunning

    Write-Host ''
    Write-Host "  $(T 'status_title')" -ForegroundColor Cyan
    Write-Host '  ------------------------------------------------------------'

    Write-Host "  $(T 'status_installed'): " -NoNewline
    if ($executable -or $startApp) {
        Write-Host (T 'yes') -ForegroundColor Green
    } else {
        Write-Host (T 'no') -ForegroundColor Red
    }

    if ($executable) {
        Write-Host "  $(T 'status_path'): $executable" -ForegroundColor DarkGray
    }

    Write-Host "  $(T 'status_package'): " -NoNewline
    if ($startApp) {
        Write-Host (T 'yes') -ForegroundColor Green
    } else {
        Write-Host (T 'no') -ForegroundColor Yellow
    }

    Write-Host "  $(T 'status_running'): " -NoNewline
    if ($running) {
        Write-Host (T 'yes') -ForegroundColor Green
    } else {
        Write-Host (T 'no') -ForegroundColor DarkGray
    }

    Wait-Enter
}

function Show-Diagnostics {
    $windows = $env:OS -eq 'Windows_NT'
    $powershellAvailable = $null -ne (Get-Command powershell.exe -ErrorAction SilentlyContinue)
    $xboxApp = $null
    $gamingServices = $null

    try { $xboxApp = Get-AppxPackage -Name 'Microsoft.GamingApp' -ErrorAction SilentlyContinue } catch { }
    try { $gamingServices = Get-AppxPackage -Name 'Microsoft.GamingServices' -ErrorAction SilentlyContinue } catch { }

    $minecraftFound = $null -ne (Get-MinecraftExecutable)
    if (-not $minecraftFound) {
        $minecraftFound = $null -ne (Get-MinecraftStartApp)
    }

    $checks = @(
        @{ Name = T 'diag_windows'; Passed = $windows },
        @{ Name = T 'diag_powershell'; Passed = $powershellAvailable },
        @{ Name = T 'diag_xbox'; Passed = $null -ne $xboxApp },
        @{ Name = T 'diag_gaming'; Passed = $null -ne $gamingServices },
        @{ Name = T 'diag_minecraft'; Passed = $minecraftFound }
    )

    Write-Host ''
    Write-Host "  $(T 'diagnostics_title')" -ForegroundColor Cyan
    Write-Host '  ------------------------------------------------------------'

    foreach ($check in $checks) {
        if ($check.Passed) {
            Write-Ok $check.Name
        } else {
            Write-ErrorLine $check.Name
        }
    }

    Wait-Enter
}

function Show-Banner {
    Clear-Host
    Write-Host ''
    Write-Host '  ============================================================' -ForegroundColor Cyan
    Write-Host '   Minecraft Bedrock Utility by CoelhoFZ' -ForegroundColor Cyan
    Write-Host '  ============================================================' -ForegroundColor Cyan
    Write-Host "                         v$Script:Version" -ForegroundColor DarkGray
    Write-Host ''
}

function Show-Menu {
    Write-Host "  $(T 'menu_title')" -ForegroundColor Green
    Write-Host ''
    Write-Host "    [1] $(T 'menu_1')"
    Write-Host "    [2] $(T 'menu_2')"
    Write-Host "    [3] $(T 'menu_3')"
    Write-Host "    [4] $(T 'menu_4')"
    Write-Host "    [5] $(T 'menu_5')"
    Write-Host "    [6] $(T 'menu_6')"
    Write-Host "    [0] $(T 'menu_0')"
    Write-Host ''
}

function Start-MainLoop {
    Detect-Language

    while ($true) {
        Show-Banner
        Show-Menu

        $choice = Read-Host "  $(T 'choose')"

        switch ($choice.Trim()) {
            '1' { Show-UnlockUnavailable }
            '2' { Restore-OfficialState }
            '3' {
                [void](Start-MinecraftOfficial)
                Wait-Enter
            }
            '4' {
                [void](Start-MinecraftOfficial -DirectFirst)
                Wait-Enter
            }
            '5' { Show-Status }
            '6' { Show-Diagnostics }
            '0' {
                Write-Info (T 'exiting')
                return
            }
            default {
                Write-WarningLine (T 'invalid')
                Start-Sleep -Seconds 1
            }
        }
    }
}

try {
    Start-MainLoop
} catch {
    Detect-Language
    Write-Host ''
    Write-ErrorLine $_.Exception.Message
    Wait-Enter
    exit 1
}
