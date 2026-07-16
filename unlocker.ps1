<#
.SYNOPSIS
    Minecraft Bedrock Unlocker compatibility bootstrap.

.DESCRIPTION
    Loads the maintained unlocker core, applies runtime-state compatibility,
    and adds automatic official-install diagnostics before user actions.
#>

param(
    [string]$ResourceDir,
    [string]$MinecraftPath
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Get-MbuUtf8Text {
    param([Parameter(Mandatory = $true)][byte[]]$Bytes)

    $utf8 = New-Object System.Text.UTF8Encoding -ArgumentList $false, $true
    $text = $utf8.GetString($Bytes)
    return $text.TrimStart([char]0xFEFF, [char]0x200B, [char]0x200C, [char]0x200D)
}

function Get-MbuCoreContent {
    if ($ResourceDir) {
        $embeddedPath = Join-Path $ResourceDir 'unlocker.ps1'
        if (Test-Path -LiteralPath $embeddedPath) {
            try {
                $embedded = Get-Item -LiteralPath $embeddedPath -Force -ErrorAction Stop
                if ($embedded.Length -gt 100000) {
                    return Get-MbuUtf8Text -Bytes ([System.IO.File]::ReadAllBytes($embeddedPath))
                }
            } catch { }
        }
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try {
        [Net.ServicePointManager]::SecurityProtocol =
            [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls13
    } catch { }

    $headers = @{
        'Cache-Control' = 'no-cache, no-store, max-age=0'
        'Pragma'        = 'no-cache'
        'Expires'       = '0'
        'User-Agent'    = 'MinecraftBedrockUnlocker/compat'
    }

    $urls = @(
        'https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/main/runtime/unlocker-core.ps1',
        'https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest/download/unlocker.ps1'
    )

    $errors = New-Object System.Collections.Generic.List[string]
    foreach ($url in $urls) {
        for ($attempt = 1; $attempt -le 3; $attempt++) {
            $client = $null
            try {
                $client = New-Object System.Net.WebClient
                foreach ($header in $headers.GetEnumerator()) {
                    $client.Headers[$header.Key] = [string]$header.Value
                }

                $separator = if ($url.Contains('?')) { '&' } else { '?' }
                $downloadUrl = '{0}{1}cb={2}' -f $url, $separator, [guid]::NewGuid().ToString('N')
                $content = Get-MbuUtf8Text -Bytes ($client.DownloadData($downloadUrl))

                if ([string]::IsNullOrWhiteSpace($content) -or
                    $content -notmatch 'Minecraft Bedrock Unlocker' -or
                    $content -notmatch '(?m)^\s*function\s+Start-MainLoop\b') {
                    throw 'Downloaded content is not the expected unlocker core.'
                }

                return $content
            } catch {
                $errors.Add("$url attempt $attempt => $($_.Exception.Message)") | Out-Null
                Start-Sleep -Milliseconds (250 * $attempt)
            } finally {
                if ($client) { $client.Dispose() }
            }
        }
    }

    throw "Unable to load unlocker core. $($errors -join ' | ')"
}

function Set-MbuRuntimeStateCompatibility {
    param([Parameter(Mandatory = $true)][string]$Content)

    $text = $Content.Replace("`r`n", "`n")

    $oldProtectedFiles = '    $files = @("winmm.dll", (Get-DiskName -SourceName "OnlineFix64.dll"), "dlllist.txt", "OnlineFix.ini")'
    $newProtectedFiles = @'
    $files = @("winmm.dll", (Get-DiskName -SourceName "OnlineFix64.dll"), "dlllist.txt")

    # OnlineFix.ini stores runtime state. Keep it writable so first-run state
    # and other settings can be persisted normally.
    $iniPath = Join-Path $ContentPath "OnlineFix.ini"
    if (Test-Path $iniPath) {
        try {
            $iniFile = Get-Item $iniPath -Force -ErrorAction Stop
            $iniFile.Attributes = [System.IO.FileAttributes]::Normal
        } catch {
            try { $null = cmd /c "attrib -R -S -H `"$iniPath`"" 2>$null } catch { }
        }
    }
'@

    if ($text.Contains($oldProtectedFiles)) {
        $text = $text.Replace($oldProtectedFiles, $newProtectedFiles.TrimEnd())
    } elseif ($text -notmatch 'OnlineFix\.ini stores runtime state') {
        throw 'The expected installed-file protection block was not found.'
    }

    $oldBackupLoop = @'
    # Save encrypted copies of each file
    $manifest = @()
    foreach ($file in $Script:OnlineFixFiles) {
        $diskName = Get-DiskName -SourceName $file.Name
'@
    $newBackupLoop = @'
    # Save encrypted copies of static runtime files only. OnlineFix.ini is
    # intentionally excluded so runtime state is never rolled back at logon.
    $manifest = @()
    foreach ($file in $Script:OnlineFixFiles) {
        if ($file.Name -eq "OnlineFix.ini") { continue }
        $diskName = Get-DiskName -SourceName $file.Name
'@

    if ($text.Contains($oldBackupLoop.TrimEnd())) {
        $text = $text.Replace($oldBackupLoop.TrimEnd(), $newBackupLoop.TrimEnd())
    } elseif ($text -notmatch 'runtime state is never rolled back at logon') {
        throw 'The expected persistence backup block was not found.'
    }

    return $text
}

function Set-MbuAutomaticDiagnostics {
    param([Parameter(Mandatory = $true)][string]$Content)

    $text = $Content.Replace("`r`n", "`n")
    $mainMarker = @'
# ============================================================================
# Main Loop
# ============================================================================
'@

    $upgradeBlock = @'
function Get-MbuOfficialMinecraftHealth {
    param([switch]$AttemptRepair)

    $issues = @()
    $warnings = @()
    $repairs = @()
    $mcPath = Find-MinecraftPath
    $exePath = $null
    $pt = ($Script:Lang -eq 'pt')

    if (-not $mcPath) {
        $issues += [pscustomobject]@{
            Reason = if ($pt) { 'O Minecraft for Windows nao foi encontrado.' } else { 'Minecraft for Windows was not found.' }
            Path = $null
            Solution = if ($pt) { 'Instale o Minecraft for Windows pelo aplicativo Xbox e execute o script novamente.' } else { 'Install Minecraft for Windows through the Xbox app, then run the script again.' }
            OpenXbox = $true
        }
    } elseif (-not (Test-Path -LiteralPath $mcPath -PathType Container)) {
        $issues += [pscustomobject]@{
            Reason = if ($pt) { 'O Windows registrou uma pasta do Minecraft que nao existe mais.' } else { 'Windows points to a Minecraft folder that no longer exists.' }
            Path = $mcPath
            Solution = if ($pt) { 'Abra o aplicativo Xbox, desinstale a entrada quebrada e instale o jogo novamente.' } else { 'Open the Xbox app, remove the broken installation entry, and install the game again.' }
            OpenXbox = $true
        }
    } elseif (Test-UwpMinecraftPath -Path $mcPath) {
        $issues += [pscustomobject]@{
            Reason = if ($pt) { 'Foi encontrada a versao Microsoft Store/UWP, que nao e compativel.' } else { 'The Microsoft Store/UWP version was found and is not compatible.' }
            Path = $mcPath
            Solution = if ($pt) { 'Desinstale essa versao e instale o Minecraft for Windows pelo aplicativo Xbox.' } else { 'Uninstall this version and install Minecraft for Windows through the Xbox app.' }
            OpenXbox = $true
        }
    }

    if ($mcPath -and (Test-Path -LiteralPath $mcPath -PathType Container)) {
        $candidateDirs = New-Object System.Collections.Generic.List[string]
        foreach ($candidateDir in @($mcPath, (Split-Path -Parent $mcPath), (Join-Path $mcPath 'Content'))) {
            if ($candidateDir -and $candidateDir -notin $candidateDirs) {
                $candidateDirs.Add($candidateDir) | Out-Null
            }
        }

        foreach ($candidateDir in $candidateDirs) {
            $candidateExe = Join-Path $candidateDir 'Minecraft.Windows.exe'
            if (Test-Path -LiteralPath $candidateExe -PathType Leaf) {
                $exePath = $candidateExe
                break
            }
        }

        if (-not $exePath) {
            $expected = Join-Path $mcPath 'Minecraft.Windows.exe'
            $issues += [pscustomobject]@{
                Reason = if ($pt) { 'O arquivo principal Minecraft.Windows.exe esta faltando.' } else { 'The main Minecraft.Windows.exe file is missing.' }
                Path = $expected
                Solution = if ($pt) { 'No aplicativo Xbox, abra Minecraft for Windows > Gerenciar > Arquivos e use Verificar e reparar. Se a opcao nao aparecer, reinstale o jogo.' } else { 'In the Xbox app, open Minecraft for Windows > Manage > Files and use Verify and repair. If that option is unavailable, reinstall the game.' }
                OpenXbox = $true
            }
        } else {
            try {
                $exeItem = Get-Item -LiteralPath $exePath -Force -ErrorAction Stop
                if ($exeItem.Length -le 0) {
                    $issues += [pscustomobject]@{
                        Reason = if ($pt) { 'Minecraft.Windows.exe existe, mas esta vazio.' } else { 'Minecraft.Windows.exe exists but is empty.' }
                        Path = $exePath
                        Solution = if ($pt) { 'Use Verificar e reparar no aplicativo Xbox ou reinstale o jogo.' } else { 'Use Verify and repair in the Xbox app or reinstall the game.' }
                        OpenXbox = $true
                    }
                } elseif ($exeItem.Length -lt 1MB) {
                    $issues += [pscustomobject]@{
                        Reason = if ($pt) { 'Minecraft.Windows.exe esta incompleto: o tamanho do arquivo e anormalmente pequeno.' } else { 'Minecraft.Windows.exe is incomplete: the file is abnormally small.' }
                        Path = "$exePath ($($exeItem.Length) bytes)"
                        Solution = if ($pt) { 'Use Verificar e reparar no aplicativo Xbox. Se continuar, reinstale o jogo.' } else { 'Use Verify and repair in the Xbox app. Reinstall the game if the problem continues.' }
                        OpenXbox = $true
                    }
                } elseif (-not (Test-PE64File -Path $exePath)) {
                    $issues += [pscustomobject]@{
                        Reason = if ($pt) { 'Minecraft.Windows.exe nao possui uma estrutura executavel PE64 valida e provavelmente esta corrompido.' } else { 'Minecraft.Windows.exe does not have a valid PE64 executable structure and is probably corrupted.' }
                        Path = $exePath
                        Solution = if ($pt) { 'Use Verificar e reparar no aplicativo Xbox ou reinstale o jogo.' } else { 'Use Verify and repair in the Xbox app or reinstall the game.' }
                        OpenXbox = $true
                    }
                }

                try {
                    $stream = [System.IO.File]::Open($exePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
                    $probe = New-Object byte[] 2
                    $read = $stream.Read($probe, 0, 2)
                    $stream.Dispose()
                    if ($read -ne 2) { throw 'Unable to read the executable header.' }
                } catch {
                    $issues += [pscustomobject]@{
                        Reason = if ($pt) { 'O arquivo principal do Minecraft existe, mas nao pode ser lido.' } else { 'The main Minecraft file exists but cannot be read.' }
                        Path = $exePath
                        Solution = if ($pt) { 'Feche o Minecraft e o aplicativo Xbox, execute o script como administrador e tente novamente. Se persistir, repare o jogo.' } else { 'Close Minecraft and the Xbox app, run the script as administrator, and try again. Repair the game if it continues.' }
                        OpenXbox = $false
                    }
                }

                try {
                    $signature = Get-AuthenticodeSignature -LiteralPath $exePath -ErrorAction Stop
                    if ($signature.Status -ne [System.Management.Automation.SignatureStatus]::Valid) {
                        $warnings += [pscustomobject]@{
                            Reason = if ($pt) { "A assinatura do executavel nao foi validada pelo PowerShell: $($signature.Status)." } else { "PowerShell did not validate the executable signature: $($signature.Status)." }
                            Path = $exePath
                            Solution = if ($pt) { 'Isso pode ser assinatura por catalogo. Repare o jogo apenas se ele tambem nao abrir ou apresentar outros erros.' } else { 'This may be catalog signing. Repair the game only if it also fails to open or shows other errors.' }
                        }
                    }
                } catch {
                    $warnings += [pscustomobject]@{
                        Reason = if ($pt) { 'Nao foi possivel consultar a assinatura do executavel.' } else { 'The executable signature could not be checked.' }
                        Path = $exePath
                        Solution = if ($pt) { 'Nenhuma acao e necessaria se o jogo abre normalmente.' } else { 'No action is needed if the game opens normally.' }
                    }
                }
            } catch {
                $issues += [pscustomobject]@{
                    Reason = if ($pt) { 'O script nao conseguiu inspecionar Minecraft.Windows.exe.' } else { 'The script could not inspect Minecraft.Windows.exe.' }
                    Path = $exePath
                    Solution = if ($pt) { 'Feche o jogo e o aplicativo Xbox, execute como administrador e tente novamente.' } else { 'Close the game and Xbox app, run as administrator, and try again.' }
                    OpenXbox = $false
                }
            }
        }

        $manifestCandidates = @()
        foreach ($base in @($mcPath, (Split-Path -Parent $mcPath))) {
            if ($base) {
                $manifestCandidates += (Join-Path $base 'MicrosoftGame.config')
                $manifestCandidates += (Join-Path $base 'MicrosoftGame.Config')
                $manifestCandidates += (Join-Path $base 'AppxManifest.xml')
            }
        }
        $manifestPath = $manifestCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
        if (-not $manifestPath) {
            $warnings += [pscustomobject]@{
                Reason = if ($pt) { 'Nenhum manifesto principal do jogo foi encontrado nos locais esperados.' } else { 'No main game manifest was found in the expected locations.' }
                Path = ($manifestCandidates | Select-Object -Unique) -join '; '
                Solution = if ($pt) { 'Use Verificar e reparar no aplicativo Xbox se o jogo nao abrir.' } else { 'Use Verify and repair in the Xbox app if the game does not open.' }
            }
        } else {
            try {
                $manifestItem = Get-Item -LiteralPath $manifestPath -Force -ErrorAction Stop
                if ($manifestItem.Length -le 0) { throw 'The manifest is empty.' }
                $manifestText = [System.IO.File]::ReadAllText($manifestPath)
                $null = [xml]$manifestText
            } catch {
                $issues += [pscustomobject]@{
                    Reason = if ($pt) { 'O manifesto principal do Minecraft esta vazio, ilegivel ou possui XML invalido.' } else { 'The main Minecraft manifest is empty, unreadable, or contains invalid XML.' }
                    Path = $manifestPath
                    Solution = if ($pt) { 'Use Verificar e reparar no aplicativo Xbox ou reinstale o jogo.' } else { 'Use Verify and repair in the Xbox app or reinstall the game.' }
                    OpenXbox = $true
                }
            }
        }

        try {
            $permissionProbe = Join-Path $mcPath ('.mbu-health-' + [guid]::NewGuid().ToString('N') + '.tmp')
            [System.IO.File]::WriteAllText($permissionProbe, 'test')
            Remove-Item -LiteralPath $permissionProbe -Force -ErrorAction Stop
        } catch {
            $issues += [pscustomobject]@{
                Reason = if ($pt) { 'A pasta do Minecraft nao permite gravacao.' } else { 'The Minecraft folder is not writable.' }
                Path = $mcPath
                Solution = if ($pt) { 'Execute o script como administrador. Se continuar, repare as permissoes pelo aplicativo Xbox ou reinstale o jogo.' } else { 'Run the script as administrator. If it continues, repair permissions through the Xbox app or reinstall the game.' }
                OpenXbox = $false
            }
        }
    }

    $serviceProblems = @()
    foreach ($serviceName in @('GamingServices', 'GamingServicesNet')) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if (-not $service) {
            $serviceProblems += if ($pt) { "O servico $serviceName nao esta instalado." } else { "The $serviceName service is not installed." }
            continue
        }
        if ($service.Status -ne 'Running' -and $AttemptRepair) {
            try {
                Start-Service -Name $serviceName -ErrorAction Stop
                Start-Sleep -Milliseconds 500
                $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                if ($service -and $service.Status -eq 'Running') {
                    $repairs += if ($pt) { "O servico $serviceName foi iniciado automaticamente." } else { "The $serviceName service was started automatically." }
                }
            } catch { }
        }
        if (-not $service -or $service.Status -ne 'Running') {
            $serviceProblems += if ($pt) { "O servico $serviceName esta parado." } else { "The $serviceName service is stopped." }
        }
    }
    if ($serviceProblems.Count -gt 0) {
        $issues += [pscustomobject]@{
            Reason = ($serviceProblems -join ' ')
            Path = $null
            Solution = if ($pt) { 'Abra Configuracoes do Windows > Aplicativos > Gaming Services > Opcoes avancadas e use Reparar. Depois reinicie o PC.' } else { 'Open Windows Settings > Apps > Gaming Services > Advanced options and choose Repair, then restart the PC.' }
            OpenXbox = $false
        }
    }

    try {
        $registeredLocations = @(Get-AppxPackage -AllUsers -Name 'MICROSOFT.MINECRAFTUWP' -ErrorAction SilentlyContinue | Where-Object { $_.InstallLocation } | ForEach-Object { $_.InstallLocation.TrimEnd('\') } | Select-Object -Unique)
        if ($registeredLocations.Count -gt 1) {
            $warnings += [pscustomobject]@{
                Reason = if ($pt) { 'Mais de uma instalacao registrada do Minecraft foi encontrada.' } else { 'More than one registered Minecraft installation was found.' }
                Path = ($registeredLocations -join '; ')
                Solution = if ($pt) { 'Remova instalacoes antigas pelo aplicativo Xbox para evitar que arquivos sejam enviados para a versao errada.' } else { 'Remove old installations through the Xbox app to avoid files being sent to the wrong version.' }
            }
        }
    } catch { }

    if ($AttemptRepair -and ($issues | Where-Object { $_.OpenXbox } | Select-Object -First 1)) {
        try {
            Start-Process 'ms-windows-store://pdp?productId=9NBLGGH2JHXJ' -ErrorAction SilentlyContinue | Out-Null
            $repairs += if ($pt) { 'O aplicativo Xbox/loja foi aberto na pagina do Minecraft para facilitar o reparo.' } else { 'The Xbox app/store was opened on the Minecraft page to make repair easier.' }
        } catch { }
    }

    return [pscustomobject]@{
        Healthy = ($issues.Count -eq 0)
        MinecraftPath = $mcPath
        ExecutablePath = $exePath
        Issues = @($issues)
        Warnings = @($warnings)
        Repairs = @($repairs)
    }
}

function Show-MbuOfficialMinecraftHealth {
    param([switch]$AttemptRepair, [switch]$Compact)

    $report = Get-MbuOfficialMinecraftHealth -AttemptRepair:$AttemptRepair
    $pt = ($Script:Lang -eq 'pt')

    Write-C ''
    Write-Line
    Write-C $(if ($pt) { '  VERIFICACAO AUTOMATICA DO MINECRAFT' } else { '  AUTOMATIC MINECRAFT CHECK' }) Cyan
    Write-Line
    Write-C ''

    foreach ($repair in $report.Repairs) { Write-OK $repair }

    if ($report.Healthy) {
        Write-OK $(if ($pt) { 'A instalacao oficial do Minecraft esta pronta.' } else { 'The official Minecraft installation is ready.' })
    } else {
        foreach ($issue in $report.Issues) {
            Write-Err $(if ($pt) { "Motivo: $($issue.Reason)" } else { "Reason: $($issue.Reason)" })
            if ($issue.Path) {
                Write-C $(if ($pt) { "  Arquivo/local verificado: $($issue.Path)" } else { "  Checked file/location: $($issue.Path)" }) Yellow
            }
            Write-C $(if ($pt) { "  Solucao: $($issue.Solution)" } else { "  Solution: $($issue.Solution)" }) White
            Write-C ''
        }
    }

    if (-not $Compact) {
        foreach ($warning in $report.Warnings) {
            Write-Warn $warning.Reason
            if ($warning.Path) {
                Write-C $(if ($pt) { "  Arquivo/local verificado: $($warning.Path)" } else { "  Checked file/location: $($warning.Path)" }) DarkGray
            }
            Write-C $(if ($pt) { "  Orientacao: $($warning.Solution)" } else { "  Guidance: $($warning.Solution)" }) Yellow
        }
    }

    Write-C ''
    return $report
}

function Get-MbuActionState {
    $mcPath = Find-MinecraftPath
    if (-not $mcPath -or (Test-UwpMinecraftPath -Path $mcPath)) {
        return [pscustomobject]@{ Mode = 'install'; Path = $mcPath; Verification = $null }
    }

    Initialize-SafeDllNames -ContentPath $mcPath
    $verification = Verify-Installation -ContentPath $mcPath
    $legacy = Test-LegacyBypass -ContentPath $mcPath

    if ($verification.AllPresent) {
        return [pscustomobject]@{ Mode = 'restore'; Path = $mcPath; Verification = $verification }
    }
    if ($verification.Invalid.Count -gt 0 -or $verification.Missing.Count -lt $Script:OnlineFixFiles.Count -or $legacy.Count -gt 0) {
        return [pscustomobject]@{ Mode = 'partial'; Path = $mcPath; Verification = $verification }
    }
    return [pscustomobject]@{ Mode = 'install'; Path = $mcPath; Verification = $verification }
}

function Show-MbuDynamicMenu {
    $state = Get-MbuActionState
    $pt = ($Script:Lang -eq 'pt')

    Write-Line
    Write-C $(if ($pt) { '  ACOES DISPONIVEIS' } else { '  AVAILABLE ACTIONS' }) Cyan
    Write-Line
    Write-C ''

    switch ($state.Mode) {
        'restore' {
            Write-C $(if ($pt) { '  [2] Restaurar original (voltar para Trial)' } else { '  [2] Restore original (return to Trial)' }) Green
        }
        'partial' {
            Write-Warn $(if ($pt) { 'Uma instalacao incompleta foi detectada.' } else { 'An incomplete installation was detected.' })
            Write-C $(if ($pt) { '  [1] Reparar/reinstalar automaticamente' } else { '  [1] Repair/reinstall automatically' }) Green
            Write-C $(if ($pt) { '  [2] Restaurar original e remover os arquivos incompletos' } else { '  [2] Restore original and remove incomplete files' }) Yellow
        }
        default {
            Write-C $(if ($pt) { '  [1] Instalar' } else { '  [1] Install' }) Green
        }
    }

    Write-C $(if ($pt) { '  [0] Sair' } else { '  [0] Exit' }) DarkGray
    Write-C ''
    return $state
}

function Show-MbuPostInstallResult {
    $pt = ($Script:Lang -eq 'pt')
    $state = Get-MbuActionState
    Write-C ''
    Write-Line
    Write-C $(if ($pt) { '  VERIFICACAO FINAL AUTOMATICA' } else { '  AUTOMATIC FINAL CHECK' }) Cyan
    Write-Line
    Write-C ''

    if ($state.Mode -eq 'restore') {
        Write-OK $(if ($pt) { 'Todos os arquivos instalados pelo script estao presentes e validos.' } else { 'All files installed by the script are present and valid.' })
        Write-Info $(if ($pt) { 'Abra o Minecraft e confirme se a tela Trial desapareceu.' } else { 'Open Minecraft and confirm that the Trial screen is gone.' })
    } elseif ($state.Verification) {
        Write-Err $(if ($pt) { 'A instalacao nao ficou completa.' } else { 'The installation is incomplete.' })
        foreach ($file in $state.Verification.Missing) {
            Write-C $(if ($pt) { "  Arquivo faltando: $file" } else { "  Missing file: $file" }) Yellow
        }
        foreach ($file in $state.Verification.Invalid) {
            Write-C $(if ($pt) { "  Arquivo invalido ou corrompido: $file" } else { "  Invalid or corrupted file: $file" }) Yellow
        }
        Write-C $(if ($pt) { '  Solucao: execute a instalacao novamente. Se o arquivo desaparecer, verifique o historico do antivirus.' } else { '  Solution: run the installation again. If the file disappears, check antivirus history.' }) White
    }
    Write-C ''
}

function Show-MbuRestoreResult {
    $pt = ($Script:Lang -eq 'pt')
    $mcPath = Find-MinecraftPath
    if (-not $mcPath) { return }

    $leftovers = @()
    foreach ($name in (Get-BypassFileNames -Path $mcPath)) {
        $filePath = Join-Path $mcPath $name
        if (Test-Path -LiteralPath $filePath) { $leftovers += $name }
    }

    Write-C ''
    Write-Line
    Write-C $(if ($pt) { '  VERIFICACAO DA RESTAURACAO' } else { '  RESTORE CHECK' }) Cyan
    Write-Line
    Write-C ''

    if ($leftovers.Count -eq 0) {
        Write-OK $(if ($pt) { 'Estado original restaurado: nenhum arquivo do script permaneceu na pasta do jogo.' } else { 'Original state restored: no script files remain in the game folder.' })
    } else {
        Write-Err $(if ($pt) { 'A restauracao nao conseguiu remover todos os arquivos.' } else { 'Restore could not remove every file.' })
        foreach ($file in $leftovers) {
            Write-C $(if ($pt) { "  Arquivo restante: $file" } else { "  Remaining file: $file" }) Yellow
        }
        Write-C $(if ($pt) { '  Solucao: reinicie o PC e execute Restaurar original novamente como administrador.' } else { '  Solution: restart the PC and run Restore original again as administrator.' }) White
    }
    Write-C ''
}
'@

    if ($text -notmatch '(?m)^function Get-MbuOfficialMinecraftHealth\b') {
        if (-not $text.Contains($mainMarker.Trim())) {
            throw 'The main-loop marker was not found in the unlocker core.'
        }
        $text = $text.Replace($mainMarker.Trim(), $upgradeBlock.TrimEnd() + "`n`n" + $mainMarker.Trim())
    }

    $newMainLoop = @'
function Start-MainLoop {
    Detect-Language
    Set-ConsoleAppearance
    Show-Banner

    if (-not (Test-Admin)) {
        Request-Elevation
        return
    }

    Write-OK (T 'admin_ok')

    while ($true) {
        $menuState = Show-MbuDynamicMenu
        Write-C "  $(T 'choose'): " Cyan -NoNewline
        $choice = Read-Host
        Show-Banner

        switch ($choice.Trim()) {
            '1' {
                if ($menuState.Mode -notin @('install', 'partial')) {
                    Write-Warn $(if ($Script:Lang -eq 'pt') { 'A instalacao ja esta completa. Use a opcao 2 para restaurar o original.' } else { 'The installation is already complete. Use option 2 to restore the original.' })
                    continue
                }

                try {
                    $health = Show-MbuOfficialMinecraftHealth -AttemptRepair
                    if (-not $health.Healthy) {
                        Write-Warn $(if ($Script:Lang -eq 'pt') { 'A instalacao foi interrompida para evitar alterar um Minecraft incompleto ou corrompido.' } else { 'Installation was stopped to avoid modifying an incomplete or corrupted Minecraft installation.' })
                        Wait-Enter
                        continue
                    }
                    Install-Bypass
                    Show-MbuPostInstallResult
                } catch {
                    Write-C ''
                    Write-Err "$($_.Exception.Message)"
                    Write-C ''
                    Read-Host "  $(if ($Script:Lang -eq 'pt') { 'Pressione ENTER para continuar' } else { 'Press ENTER to continue' })"
                }
            }
            '2' {
                if ($menuState.Mode -notin @('restore', 'partial')) {
                    Write-Warn $(if ($Script:Lang -eq 'pt') { 'Nenhuma instalacao do script foi detectada para restaurar.' } else { 'No script installation was detected to restore.' })
                    continue
                }

                try {
                    Restore-Original
                    Show-MbuRestoreResult
                } catch {
                    Write-C ''
                    Write-Err "$($_.Exception.Message)"
                    Write-C ''
                    Read-Host "  $(if ($Script:Lang -eq 'pt') { 'Pressione ENTER para continuar' } else { 'Press ENTER to continue' })"
                }
            }
            '0' {
                Write-C ''
                Write-Info (T 'exiting')
                Start-Sleep -Seconds 1
                return
            }
            default { Write-Warn (T 'invalid') }
        }
    }
}
'@

    $pattern = 'function Start-MainLoop\s*\{.*?(?=\n# ============================================================================\n# Entry Point)'
    $regex = New-Object System.Text.RegularExpressions.Regex($pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if ($regex.Matches($text).Count -ne 1) {
        throw 'The Start-MainLoop block could not be replaced safely.'
    }
    $replacementText = $newMainLoop.TrimEnd()
    $evaluator = [System.Text.RegularExpressions.MatchEvaluator]{ param($match) $replacementText }
    $text = $regex.Replace($text, $evaluator, 1)

    return $text
}

$coreContent = Get-MbuCoreContent
$patchedContent = Set-MbuRuntimeStateCompatibility -Content $coreContent
$patchedContent = Set-MbuAutomaticDiagnostics -Content $patchedContent

$tokens = $null
$parseErrors = $null
[System.Management.Automation.Language.Parser]::ParseInput($patchedContent, [ref]$tokens, [ref]$parseErrors) | Out-Null

if ($parseErrors -and $parseErrors.Count -gt 0) {
    $messages = ($parseErrors | ForEach-Object { $_.Message }) -join ' | '
    throw "Patched unlocker failed PowerShell syntax validation: $messages"
}

$Script:MBUContent = $patchedContent
$scriptBlock = [ScriptBlock]::Create($patchedContent)
$parameters = @{}
if ($ResourceDir) { $parameters['ResourceDir'] = $ResourceDir }
if ($MinecraftPath) { $parameters['MinecraftPath'] = $MinecraftPath }

& $scriptBlock @parameters
