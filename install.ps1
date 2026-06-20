<#
.SYNOPSIS
    Minecraft Bedrock Unlocker - PowerShell bootstrap.

.DESCRIPTION
    Small first-stage launcher for the release-hosted PowerShell installer.
    It asks the user to temporarily disable antivirus protection before the
    full payload is downloaded and executed.

    Usage: $u='https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest/download/install.ps1'; $h=@{'Cache-Control'='no-cache, no-store, max-age=0';'Pragma'='no-cache';'Expires'='0';'User-Agent'='MinecraftBedrockUnlocker'}; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $s=$null; 1..3|%{if([string]::IsNullOrWhiteSpace($s)){try{$r=irm -UseBasicParsing -Headers $h -Uri "${u}?cb=$([guid]::NewGuid())" -MaximumRedirection 5; $s=($r | Out-String)}catch{Start-Sleep -Seconds 1}}}; $t=if($s){$s.TrimStart()}else{''}; if([string]::IsNullOrWhiteSpace($s) -or $t.StartsWith('<!DOCTYPE',[StringComparison]::OrdinalIgnoreCase) -or $t.StartsWith('<html',[StringComparison]::OrdinalIgnoreCase)){throw 'install.ps1 download failed or returned invalid content'}; iex $s

.NOTES
    Author: CoelhoFZ
    Version: 3.1.11
    Repository: https://github.com/CoelhoFZ/MinecraftBedrockUnlocker
#>

param([string]$ResourceDir)  # Set by EXE launcher when running self-contained

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Detect system language for error messages (top 7 worldwide, OS culture-based)
$Script:BootstrapLang = 'en'
try {
    $culture = (Get-Culture).Name
    switch -Wildcard ($culture) {
        'zh-*' { $Script:BootstrapLang = 'zh' }
        'hi-*' { $Script:BootstrapLang = 'hi' }
        'es-*' { $Script:BootstrapLang = 'es' }
        'fr-*' { $Script:BootstrapLang = 'fr' }
        'ar-*' { $Script:BootstrapLang = 'ar' }
        'ru-*' { $Script:BootstrapLang = 'ru' }
        'pt-*' { $Script:BootstrapLang = 'pt' }
        default { $Script:BootstrapLang = 'en' }
    }
} catch { }

$Script:BootMsg = @{
    en = @{
        errTitle    = 'BOOTSTRAP ERROR:'
        errGeneric  = 'The installer bootstrap failed.'
        avHint      = 'If your antivirus caused this: disable it temporarily and run again.'
        pressEnter  = 'Press ENTER to exit'
        pressEnterPt = 'Pressione ENTER para sair'
    }
    zh = @{
        errTitle    = '引导程序错误:'
        errGeneric  = '安装程序引导失败。'
        avHint      = '如果是杀毒软件导致的:请暂时禁用它,然后重新运行。'
        pressEnter  = '按回车退出'
        pressEnterPt = '按回车退出'
    }
    hi = @{
        errTitle    = 'बूटस्ट्रैप त्रुटि:'
        errGeneric  = 'इंस्टॉलर बूटस्ट्रैप विफल।'
        avHint      = 'यदि यह आपके एंटीवायरस के कारण है: इसे अस्थायी रूप से अक्षम करें और फिर से चलाएँ।'
        pressEnter  = 'बाहर निकलने के लिए एंटर दबाएँ'
        pressEnterPt = 'बाहर निकलने के लिए एंटर दबाएँ'
    }
    es = @{
        errTitle    = 'ERROR DE ARRANQUE:'
        errGeneric  = 'El arranque del instalador falló.'
        avHint      = 'Si fue su antivirus: desactívelo temporalmente y vuelva a ejecutar.'
        pressEnter  = 'Pulse ENTER para salir'
        pressEnterPt = 'Pulse ENTER para salir'
    }
    fr = @{
        errTitle    = 'ERREUR DE DÉMARRAGE :'
        errGeneric  = "Le démarrage de l'installateur a échoué."
        avHint      = "Si c'est votre antivirus : désactivez-le temporairement et réexécutez."
        pressEnter  = 'Appuyez sur ENTRÉE pour quitter'
        pressEnterPt = 'Appuyez sur ENTRÉE pour quitter'
    }
    ar = @{
        errTitle    = 'خطأ في المُحمِّل:'
        errGeneric  = 'فشل مُحمِّل المُثبِّت.'
        avHint      = 'إذا كان السبب برنامج مكافحة الفيروسات: قم بتعطيله مؤقتاً وأعد التشغيل.'
        pressEnter  = 'اضغط مفتاح الإدخال للخروج'
        pressEnterPt = 'اضغط مفتاح الإدخال للخروج'
    }
    ru = @{
        errTitle    = 'ОШИБКА ЗАГРУЗЧИКА:'
        errGeneric  = 'Сбой загрузчика установщика.'
        avHint      = 'Если это вызвано антивирусом: временно отключите его и запустите снова.'
        pressEnter  = 'Нажмите ВВОД для выхода'
        pressEnterPt = 'Нажмите ВВОД для выхода'
    }
}

trap {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Red
    # Defensive: $Script:BootMsg / $Script:BootstrapLang may be null if trap fires before initialization
    $errTitle = if ($null -ne $Script:BootMsg -and $null -ne $Script:BootstrapLang -and $Script:BootMsg.ContainsKey($Script:BootstrapLang)) { $Script:BootMsg[$Script:BootstrapLang].errTitle } else { '[MBU v3.2.1] BOOTSTRAP ERROR:' }
    Write-Host $errTitle $_.Exception.Message -ForegroundColor Red
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host ''
    try {
        if ($Script:BootstrapLang -eq 'pt') {
            Write-Host 'O bootstrap do instalador falhou.' -ForegroundColor Yellow
            Write-Host 'Se foi o antivirus: desative-o temporariamente e execute novamente.' -ForegroundColor Yellow
        } elseif ($null -ne $Script:BootMsg -and $null -ne $Script:BootstrapLang -and $Script:BootMsg.ContainsKey($Script:BootstrapLang)) {
            Write-Host $Script:BootMsg[$Script:BootstrapLang].errGeneric -ForegroundColor Yellow
            Write-Host 'If your antivirus caused this: disable it temporarily and run again.' -ForegroundColor Yellow
        } else {
            Write-Host 'The installer bootstrap failed.' -ForegroundColor Yellow
            Write-Host 'If your antivirus caused this: disable it temporarily and run again.' -ForegroundColor Yellow
        }
    } catch {
        Write-Host 'The installer bootstrap failed.' -ForegroundColor Yellow
    }
    Write-Host ''
    try {
        if ($Script:BootstrapLang -eq 'pt') {
            Read-Host 'Pressione ENTER para sair' | Out-Null
        } elseif ($null -ne $Script:BootMsg -and $null -ne $Script:BootstrapLang -and $Script:BootMsg.ContainsKey($Script:BootstrapLang)) {
            Read-Host $Script:BootMsg[$Script:BootstrapLang].pressEnter | Out-Null
        } else {
            Read-Host 'Press ENTER to exit' | Out-Null
        }
    } catch {
        Read-Host 'Press ENTER to exit' | Out-Null
    }
    break
}

$Script:Version = '3.2.1'
$Script:RepoOwner = 'CoelhoFZ'
$Script:RepoName = 'MinecraftBedrockUnlocker'
$Script:BaseUrl = "https://github.com/$($Script:RepoOwner)/$($Script:RepoName)/releases/latest/download"
$Script:PayloadUrl = "$($Script:BaseUrl)/unlocker.ps1"
# Fallback to main branch (avoids dependency on a v3.2.1 tag that may not exist yet)
$Script:RawPayloadUrl = "https://raw.githubusercontent.com/$($Script:RepoOwner)/$($Script:RepoName)/main/unlocker.ps1"
# unlocker.ps1 hash post-BOM-strip (v3.3.0)
$Script:PayloadSha256 = '80771efadeac262bda790459201b355182150bdf9dad388fc3975d2a8bafa790'

function Write-Status {
    param(
        [string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::White
    )

    try {
        Write-Host $Message -ForegroundColor $Color
    } catch {
        Write-Output $Message
    }
}

function Wait-AnyKey {
    Write-Status ''
        if ($Script:BootstrapLang -eq 'pt') {
        Write-Status 'Desabilite o seu antivirus antes de executar, quando desabilitar, pressione qualquer tecla para continuar' ([ConsoleColor]::Yellow)
    } else {
        Write-Status 'Disable your antivirus before running, then press any key to continue' ([ConsoleColor]::Yellow)
    }
    Write-Status ''

    try {
        if ($Host -and $Host.UI -and $Host.UI.RawUI) {
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            return
        }
    } catch { }

    $null = Read-Host 'Pressione ENTER para continuar'
}

function New-CacheBustedUrl {
    param([Parameter(Mandatory=$true)][string]$Url)

    $separator = if ($Url.Contains('?')) { '&' } else { '?' }
    return ('{0}{1}cb={2}' -f $Url, $separator, [guid]::NewGuid().ToString('N'))
}

function Set-NetworkDefaults {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls13
    } catch { }
    [Net.ServicePointManager]::Expect100Continue = $false
}

function Get-NoCacheHeaders {
    return @{
        'Cache-Control' = 'no-cache, no-store, max-age=0'
        'Pragma' = 'no-cache'
        'Expires' = '0'
        'User-Agent' = "MinecraftBedrockUnlocker/$($Script:Version)"
        'Accept' = 'text/plain,*/*'
    }
}

function Get-PayloadCandidateUrls {
    return @(
        $Script:PayloadUrl,
        $Script:RawPayloadUrl
    )
}

function Test-PayloadFile {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path $Path)) {
        throw 'Payload file was not created.'
    }

    $payloadSize = (Get-Item $Path).Length
    if ($payloadSize -lt 100000) {
        throw "Payload download looks incomplete: $payloadSize bytes"
    }

    $payloadHead = Get-Content -Path $Path -TotalCount 40 -ErrorAction Stop | Out-String
    $payloadHeadTrimmed = $payloadHead.TrimStart()
    if ($payloadHeadTrimmed.StartsWith('<!DOCTYPE', [StringComparison]::OrdinalIgnoreCase) -or $payloadHeadTrimmed.StartsWith('<html', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Downloaded payload is an HTML error page.'
    }
    if ($payloadHead -notmatch 'Minecraft Bedrock Unlocker') {
        throw 'Downloaded payload is not the expected installer.'
    }

    if ($Script:PayloadSha256) {
        $actualHash = (Get-FileHash -Algorithm SHA256 -Path $Path -ErrorAction Stop).Hash.ToLowerInvariant()
        if ($actualHash -ne $Script:PayloadSha256.ToLowerInvariant()) {
            throw "Downloaded payload hash mismatch: $actualHash"
        }
    }

    return $true
}

function Invoke-FileDownload {
    param(
        [Parameter(Mandatory=$true)][string]$Url,
        [Parameter(Mandatory=$true)][string]$Destination
    )

    Set-NetworkDefaults
    $tmpPath = "$Destination.tmp"
    Remove-Item -Path $tmpPath -Force -ErrorAction SilentlyContinue
    $headers = Get-NoCacheHeaders
    $attemptErrors = New-Object System.Collections.Generic.List[string]

    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            Invoke-WebRequest -Uri (New-CacheBustedUrl $Url) -OutFile $tmpPath -UseBasicParsing -Headers $headers -MaximumRedirection 5 -DisableKeepAlive -ErrorAction Stop
            Test-PayloadFile -Path $tmpPath | Out-Null
            Move-Item -Path $tmpPath -Destination $Destination -Force
            return $true
        } catch {
            $attemptErrors.Add("Invoke-WebRequest#${attempt}: $($_.Exception.Message)") | Out-Null
            Remove-Item -Path $tmpPath -Force -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds (250 * $attempt)
        }
    }

    $client = $null
    try {
        $client = New-Object System.Net.WebClient
        foreach ($header in $headers.GetEnumerator()) { $client.Headers[$header.Key] = $header.Value }
        $client.DownloadFile((New-CacheBustedUrl $Url), $tmpPath)
        Test-PayloadFile -Path $tmpPath | Out-Null
        Move-Item -Path $tmpPath -Destination $Destination -Force
        return $true
    } catch {
        $attemptErrors.Add("WebClient: $($_.Exception.Message)") | Out-Null
        Remove-Item -Path $tmpPath -Force -ErrorAction SilentlyContinue
    } finally {
        if ($client) { $client.Dispose() }
    }

    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if ($curl -and $curl.Source) {
        try {
            & $curl.Source -fL -sS --retry 4 --retry-delay 2 --connect-timeout 15 --max-time 180 `
                -H 'Cache-Control: no-cache, no-store, max-age=0' `
                -H 'Pragma: no-cache' `
                -H "User-Agent: MinecraftBedrockUnlocker/$($Script:Version)" `
                -o $tmpPath (New-CacheBustedUrl $Url)
            if ($LASTEXITCODE -ne 0) { throw "curl.exe exited with code $LASTEXITCODE" }
            Test-PayloadFile -Path $tmpPath | Out-Null
            Move-Item -Path $tmpPath -Destination $Destination -Force
            return $true
        } catch {
            $attemptErrors.Add("curl.exe: $($_.Exception.Message)") | Out-Null
            Remove-Item -Path $tmpPath -Force -ErrorAction SilentlyContinue
        }
    } else {
        $attemptErrors.Add('curl.exe: not found') | Out-Null
    }

    throw ($attemptErrors -join ' | ')
}

function Get-PowerShellExe {
    $cmd = Get-Command powershell.exe -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) {
        return $cmd.Source
    }

    $windowsPowerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    if (Test-Path $windowsPowerShell) {
        return $windowsPowerShell
    }

    throw 'powershell.exe not found.'
}

function Download-Payload {
    $tempRoot = Join-Path (Join-Path ([System.IO.Path]::GetTempPath()) 'MinecraftBedrockUnlocker') ([guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

    $payloadPath = Join-Path $tempRoot "unlocker-$($Script:Version).ps1"
    $errors = New-Object System.Collections.Generic.List[string]

    foreach ($url in (Get-PayloadCandidateUrls)) {
        try {
            Invoke-FileDownload -Url $url -Destination $payloadPath | Out-Null
            return $payloadPath
        } catch {
            $errors.Add("$url => $($_.Exception.Message)") | Out-Null
            Remove-Item -Path $payloadPath -Force -ErrorAction SilentlyContinue
        }
    }

    throw "Payload download failed. $($errors -join ' || ')"
}

function Start-Bootstrap {
    Clear-Host -ErrorAction SilentlyContinue
    Write-Status '============================================================' ([ConsoleColor]::Cyan)
    Write-Status ' Minecraft Bedrock Unlocker' ([ConsoleColor]::Cyan)
    Write-Status " v$($Script:Version) bootstrap" ([ConsoleColor]::DarkGray)
    Write-Status '============================================================' ([ConsoleColor]::Cyan)

    Wait-AnyKey

    if ($ResourceDir -and (Test-Path (Join-Path $ResourceDir 'unlocker.ps1'))) {
        # Self-contained mode: unlocker.ps1 and DLLs are already embedded in the EXE
        Write-Status ''
        Write-Status 'Executando instalador self-contained...' ([ConsoleColor]::Cyan)
        Write-Status ''
        $payloadPath = Join-Path $ResourceDir 'unlocker.ps1'
    } else {
        Write-Status ''
        Write-Status 'Baixando instalador completo...' ([ConsoleColor]::Cyan)
        $payloadPath = Download-Payload
        Write-Status 'Instalador baixado. Iniciando...' ([ConsoleColor]::Green)
        Write-Status ''
    }

    $powershellExe = Get-PowerShellExe
    $exitCode = 1
    try {
        if ($ResourceDir) {
            & $powershellExe -NoProfile -ExecutionPolicy Bypass -File $payloadPath -ResourceDir $ResourceDir
        } else {
            & $powershellExe -NoProfile -ExecutionPolicy Bypass -File $payloadPath
        }
        $exitCode = if ($LASTEXITCODE -is [int]) { $LASTEXITCODE } else { 0 }
        if ($exitCode -ne 0) {
            Write-Status "unlocker exited with code $exitCode" ([ConsoleColor]::Red)
            Write-Status ""
            if ($Script:BootstrapLang -eq 'pt') {
                Write-Status "O unlocker encontrou um erro. Veja a mensagem acima." ([ConsoleColor]::Yellow)
                Write-Status "Se foi o antivirus: desative-o temporariamente e execute novamente." ([ConsoleColor]::Yellow)
            } else {
                Write-Status "The unlocker encountered an error. Check the message above." ([ConsoleColor]::Yellow)
                Write-Status "If your antivirus caused this: disable it temporarily and run again." ([ConsoleColor]::Yellow)
            }
            Write-Status ""
            if ($Script:BootstrapLang -eq 'pt') {
                Read-Host "Pressione ENTER para fechar esta janela"
            } else {
                Read-Host "Press ENTER to close this window"
            }
        }
    } finally {
        $payloadDir = Split-Path -Parent $payloadPath
        # Only clean up downloaded payload, not resource dir (EXE handles that)
        if (-not $ResourceDir) {
            Remove-Item -Path $payloadDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    exit $exitCode
}

Start-Bootstrap
