<#
.SYNOPSIS
    Minecraft Bedrock Unlocker - PowerShell Script
    
.DESCRIPTION
    Complete PowerShell-based Minecraft Bedrock Unlocker.
    Downloads OnlineFix runtime files from the release OnlineFix.zip and installs them.
    No EXE needed - runs entirely in PowerShell.
    
    Usage: $u='https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest/download/install.ps1'; $h=@{'Cache-Control'='no-cache, no-store, max-age=0';'Pragma'='no-cache';'Expires'='0';'User-Agent'='MinecraftBedrockUnlocker'}; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $s=$null; 1..3|%{if([string]::IsNullOrWhiteSpace($s)){try{$r=irm -UseBasicParsing -Headers $h -Uri "${u}?cb=$([guid]::NewGuid())" -MaximumRedirection 5; $s=($r | Out-String)}catch{Start-Sleep -Seconds 1}}}; $t=if($s){$s.TrimStart()}else{''}; if([string]::IsNullOrWhiteSpace($s) -or $t.StartsWith('<!DOCTYPE',[StringComparison]::OrdinalIgnoreCase) -or $t.StartsWith('<html',[StringComparison]::OrdinalIgnoreCase)){throw 'install.ps1 download failed or returned invalid content'}; iex $s
    
.NOTES
    Author: CoelhoFZ
    Version: 3.3.3
    Repository: https://github.com/CoelhoFZ/MinecraftBedrockUnlocker
#>

param(
    [string]$ResourceDir,    # Set by EXE launcher when running self-contained
    [string]$MinecraftPath    # Optional: explicit Minecraft Content folder (e.g. F:\XboxGames\Minecraft for Windows\Content)
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Off  # override any inherited StrictMode (e.g. from e.ps1 via iex)
$ProgressPreference = 'SilentlyContinue'  # Speed up downloads

function Resolve-MbuLanguage {
    $candidates = New-Object System.Collections.Generic.List[string]

    try { if ($env:MBU_LANG) { $candidates.Add([string]$env:MBU_LANG) } } catch { }
    try { $candidates.Add((Get-UICulture).Name) } catch { }
    try { $candidates.Add((Get-Culture).Name) } catch { }
    try {
        $userLanguages = Get-WinUserLanguageList -ErrorAction SilentlyContinue
        foreach ($language in $userLanguages) {
            try { if ($language.LanguageTag) { $candidates.Add([string]$language.LanguageTag) } } catch { }
            try { if ($language.EnglishName) { $candidates.Add([string]$language.EnglishName) } } catch { }
            try { if ($language.NativeName) { $candidates.Add([string]$language.NativeName) } } catch { }
        }
    } catch { }
    foreach ($regPath in @('HKCU:\Control Panel\International', 'HKCU:\Control Panel\Desktop', 'HKLM:\SYSTEM\CurrentControlSet\Control\Nls\Language')) {
        try {
            $props = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
            foreach ($prop in @('LocaleName', 'sLanguage', 'Locale', 'PreferredUILanguages')) {
                $value = $props.$prop
                if ($value -is [array]) {
                    foreach ($item in $value) { if ($item) { $candidates.Add([string]$item) } }
                } elseif ($value) {
                    $candidates.Add([string]$value)
                }
            }
        } catch { }
    }

    foreach ($candidate in $candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
        $value = $candidate.Trim().ToLowerInvariant()
        switch -Wildcard ($value) {
            'pt*' { return 'pt' }
            '*portugu*' { return 'pt' }
            '*brasil*' { return 'pt' }
            '*brazil*' { return 'pt' }
            'zh*' { return 'zh' }
            '*chinese*' { return 'zh' }
            'hi*' { return 'hi' }
            '*hindi*' { return 'hi' }
            'es*' { return 'es' }
            '*spanish*' { return 'es' }
            '*espanol*' { return 'es' }
            '*español*' { return 'es' }
            'fr*' { return 'fr' }
            '*french*' { return 'fr' }
            '*francais*' { return 'fr' }
            '*français*' { return 'fr' }
            'ar*' { return 'ar' }
            '*arabic*' { return 'ar' }
            'ru*' { return 'ru' }
            '*russian*' { return 'ru' }
        }
    }

    return 'en'
}

$Script:Lang = Resolve-MbuLanguage
$env:MBU_LANG = $Script:Lang

trap {
    Write-Host ''
    Write-Host '  ============================================================' -ForegroundColor Red
    Write-Host ''
    if ($Script:Lang -eq 'pt') {
        Write-Host "  ERRO CRITICO: $($_.Exception.Message)" -ForegroundColor Red
    } else {
        Write-Host "  CRITICAL ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ''
    if ($Script:Lang -eq 'pt') {
        Write-Host '  O script encontrou um erro inesperado.' -ForegroundColor Yellow
        Write-Host '  Por favor, tire um print desta tela e reporte o erro.' -ForegroundColor Yellow
        Write-Host '  Se foi o antivirus: execute novamente apos desativa-lo.' -ForegroundColor Yellow
    } else {
        Write-Host '  The script encountered an unexpected error.' -ForegroundColor Yellow
        Write-Host '  Please take a screenshot and report this error.' -ForegroundColor Yellow
        Write-Host '  If your antivirus caused this: disable it and run again.' -ForegroundColor Yellow
    }
    Write-Host ''
    Write-Host '  ============================================================' -ForegroundColor Red
    Write-Host ''
    if ($Script:Lang -eq 'pt') {
        Read-Host '  Pressione ENTER para sair'
    } else {
        Read-Host '  Press ENTER to exit'
    }
    break
}

# ============================================================================
# Configuration
# ============================================================================
$Script:Version = "3.3.3"
$Script:RepoOwner = "CoelhoFZ"
$Script:RepoName = "MinecraftBedrockUnlocker"
$Script:RepoBranch = "main"
$Script:BaseUrl = "https://github.com/$($Script:RepoOwner)/$($Script:RepoName)/releases/latest/download"

$Script:RawBaseUrl = "https://raw.githubusercontent.com/$($Script:RepoOwner)/$($Script:RepoName)/main"
$Script:OnlineFixZipUrl = "$($Script:BaseUrl)/OnlineFix.zip"
$Script:OnlineFixZipBytes = $null
$Script:ResourceDir = $ResourceDir
$Script:IsSelfContained = ($ResourceDir -and (Test-Path (Join-Path $ResourceDir "OnlineFix64.dll")))
$Script:DiscordUrl = "https://discord.gg/byDkXzhvuZ"
$Script:RawScriptUrl = "https://raw.githubusercontent.com/$($Script:RepoOwner)/$($Script:RepoName)/main/unlocker.ps1"

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
        'Accept' = 'application/octet-stream,text/plain,*/*'
    }
}


function Test-GitHubAssetAvailable {
    # Lightweight HEAD probe: returns $true if the release asset exists.
    # Used to diagnose missing release assets before the fallback chain runs.
    param([Parameter(Mandatory=$true)][string]$Url)
    try {
        $req = [System.Net.HttpWebRequest]::Create((New-CacheBustedUrl $Url))
        $req.Method = 'HEAD'
        $req.UserAgent = "MinecraftBedrockUnlocker/$($Script:Version)"
        $req.Timeout = 10000
        $req.AllowAutoRedirect = $true
        $req.Headers.Add('Cache-Control', 'no-cache, no-store, max-age=0')
        $resp = $req.GetResponse()
        $code = [int]$resp.StatusCode
        $resp.Close()
        return ($code -ge 200 -and $code -lt 400)
    } catch {
        $code = $null
        try { $code = [int]$_.Exception.Response.StatusCode } catch { }
        return ($code -ne 404 -and $code -ne 410)
    }
}

function Test-SelfProtectionError {
    # self-protection failed Error: 4 is usually one of:
    #   - Gaming Services broken
    #   - OnlineFix64.dll signature mismatch after MC update
    #   - Minecraft for Windows reinstalled (Content folder reset)
    # We do not patch OnlineFix binaries; we print a remediation hint only.
    param([string]$ContentDir)
    if (-not $ContentDir -or -not (Test-Path -LiteralPath $ContentDir)) { return }
    $dllList = Join-Path $ContentDir 'dlllist.txt'
    if (-not (Test-Path -LiteralPath $dllList)) { return }
    $entry = Get-Content -LiteralPath $dllList -TotalCount 1 -ErrorAction SilentlyContinue
    if ($entry) {
        $dllPath = Join-Path $ContentDir $entry.Trim()
        if (-not (Test-Path -LiteralPath $dllPath)) {
            Write-Warn "self-protection failed Error: 4 likely cause: bypass DLL '$($entry.Trim())' missing."
            Write-Warn "  Auto-fix: re-installing bypass now..."
            try { Install-Bypass } catch { Write-Warn "  Auto-fix failed. Manual fix: re-run Option 1." ; Write-Warn "  If persists: repair Xbox Game Services in Windows Settings." }
            Write-Warn "  If error persists: repair Xbox Game Services via Settings > Apps > Optional features."
        }
    }
}

function Invoke-DownloadBytes {
    param(
        [Parameter(Mandatory=$true)][string[]]$Urls,
        [int]$MinBytes = 1
    )

    Set-NetworkDefaults
    $headers = Get-NoCacheHeaders
    $errors = New-Object System.Collections.Generic.List[string]

    foreach ($url in $Urls) {
        for ($attempt = 1; $attempt -le 3; $attempt++) {
            $client = $null
            try {
                $client = New-Object System.Net.WebClient
                foreach ($header in $headers.GetEnumerator()) { $client.Headers[$header.Key] = $header.Value }
                $bytes = $client.DownloadData((New-CacheBustedUrl $url))
                if ($bytes -and $bytes.Length -ge $MinBytes) { return $bytes }
                $length = if ($bytes) { $bytes.Length } else { 0 }
                throw "empty or short response ($length bytes)"
            } catch {
                $errors.Add("WebClient#$attempt $url => $($_.Exception.Message)") | Out-Null
                Start-Sleep -Milliseconds (250 * $attempt)
            } finally {
                if ($client) { $client.Dispose() }
            }
        }

        try {
            Add-Type -AssemblyName System.Net.Http -ErrorAction SilentlyContinue
            $handler = New-Object System.Net.Http.HttpClientHandler
            $handler.AllowAutoRedirect = $true
            $httpClient = New-Object System.Net.Http.HttpClient($handler)
            $httpClient.Timeout = [TimeSpan]::FromSeconds(120)
            foreach ($header in $headers.GetEnumerator()) {
                if ($header.Key -ne 'Accept') { $httpClient.DefaultRequestHeaders.TryAddWithoutValidation($header.Key, [string]$header.Value) | Out-Null }
            }
            $httpClient.DefaultRequestHeaders.TryAddWithoutValidation('Accept', [string]$headers['Accept']) | Out-Null
            $response = $httpClient.GetAsync((New-CacheBustedUrl $url)).Result
            if (-not $response.IsSuccessStatusCode) { throw "HTTP $([int]$response.StatusCode)" }
            $bytes = $response.Content.ReadAsByteArrayAsync().Result
            if ($bytes -and $bytes.Length -ge $MinBytes) { return $bytes }
            $length = if ($bytes) { $bytes.Length } else { 0 }
            throw "empty or short response ($length bytes)"
        } catch {
            $errors.Add("HttpClient $url => $($_.Exception.Message)") | Out-Null
        } finally {
            if ($response) { $response.Dispose() }
            if ($httpClient) { $httpClient.Dispose() }
            if ($handler) { $handler.Dispose() }
        }

        $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
        if ($curl -and $curl.Source) {
            $tmpPath = Join-Path ([System.IO.Path]::GetTempPath()) ("mbu-download-{0}.tmp" -f [guid]::NewGuid().ToString('N'))
            try {
                & $curl.Source -fL -sS --retry 4 --retry-delay 2 --connect-timeout 15 --max-time 180 `
                    -H 'Cache-Control: no-cache, no-store, max-age=0' `
                    -H 'Pragma: no-cache' `
                    -H "User-Agent: MinecraftBedrockUnlocker/$($Script:Version)" `
                    -o $tmpPath (New-CacheBustedUrl $url)
                if ($LASTEXITCODE -ne 0) { throw "curl.exe exited with code $LASTEXITCODE" }
                if (-not (Test-Path $tmpPath)) { throw 'curl.exe did not create output file' }
                $bytes = [System.IO.File]::ReadAllBytes($tmpPath)
                if ($bytes -and $bytes.Length -ge $MinBytes) { return $bytes }
                $length = if ($bytes) { $bytes.Length } else { 0 }
                throw "empty or short response ($length bytes)"
            } catch {
                $errors.Add("curl.exe $url => $($_.Exception.Message)") | Out-Null
            } finally {
                Remove-Item -Path $tmpPath -Force -ErrorAction SilentlyContinue
            }
        } else {
            $errors.Add("curl.exe $url => not found") | Out-Null
        }
    }

    $Script:LastDownloadError = ($errors -join ' | ')

    $has404 = ($errors | Where-Object { $_ -match '404|Not Found|HTTP 404' })
    if ($has404) {
        Write-Warn ''
        if ($Script:Lang -eq 'pt') {
            Write-Warn '[v3.3.3] Um endpoint retornou HTTP 404. O instalador tentara usar OnlineFix.zip da release.'
        } else {
            Write-Warn '[v3.3.3] One endpoint returned HTTP 404. The installer will use the release OnlineFix.zip.'
        }
        Write-Warn ''
    }
    return $null
}

function Test-ScriptPayloadText {
    param([string]$Content)

    if ([string]::IsNullOrWhiteSpace($Content)) { return $false }
    $trimmedContent = $Content.TrimStart()
    if ($trimmedContent.StartsWith('<!DOCTYPE', [StringComparison]::OrdinalIgnoreCase) -or $trimmedContent.StartsWith('<html', [StringComparison]::OrdinalIgnoreCase)) { return $false }
    return ($Content -match 'Minecraft Bedrock Unlocker' -and $Content -match 'Start-MainLoop')
}

# DLL files info (SHA256 hashes for integrity verification)
# DiskName: when set, the file is written to disk with this name instead of Name.
# This prevents AV from matching well-known filenames like OnlineFix64.dll.
$Script:OnlineFixFiles = @(
    @{ Name = "winmm.dll";        Hash = "cb8baaa2054a11628b96e474e1428a430c95321f8ac3b89764255cbd6628a9d6"; DiskName = $null },
    @{ Name = "OnlineFix64.dll";  Hash = "52cb3902999034e01bae63c6a06612d1798b0e0addc1bd4ce7680891b0229953"; DiskName = $null },
    @{ Name = "dlllist.txt";      Hash = "fc0befb4aae4b7f0eeb1c398fccea03cc795590e09db6628974520091fcfc516"; DiskName = $null },
    @{ Name = "OnlineFix.ini";    Hash = "d13a4c53389c6a35616ccbe2c09912a43369d904a52b461d734f4ebec212ddfc"; DiskName = $null }
)

function Test-SafeDllName {
    param([string]$Name)

    if ([string]::IsNullOrWhiteSpace($Name)) { return $false }
    $leaf = [System.IO.Path]::GetFileName($Name.Trim())
    return ($leaf -eq $Name.Trim() -and $leaf -match '^[A-Za-z0-9_.-]+\.dll$')
}

function Initialize-SafeDllNames {
    <#
    .DESCRIPTION
        Generates a random innocuous-looking DLL filename to replace OnlineFix64.dll
        on disk. Also updates the OnlineFixFiles entries so all functions use
        the safe name. If a previous installation exists, reads the existing
        dlllist.txt to reuse the same name (avoids orphan files).
    #>
    param([string]$ContentPath)
    
    $safeName = $null
    
    # Check if previous install exists with a custom name
    if ($ContentPath) {
        $existingDllList = Join-Path $ContentPath "dlllist.txt"
        if (Test-Path $existingDllList) {
            $content = (Get-Content $existingDllList -ErrorAction SilentlyContinue | Where-Object { $_.Trim() }) | Select-Object -First 1
            $candidate = if ($content) { $content.Trim() } else { $null }
            if ($candidate -and $candidate -ne "OnlineFix64.dll" -and (Test-SafeDllName -Name $candidate)) {
                $safeName = $candidate
            }
        }
    }
    
    # Generate new random name if no existing custom name found
    if (-not $safeName) {
        $prefixes = @("mcruntime", "xgbridge", "gxcore", "mcsvc", "dxhelper", "xblcore", "wgihost", "gameinput")
        $prefix = $prefixes[(Get-Random -Maximum $prefixes.Count)]
        $suffix = -join ((0..3) | ForEach-Object { [char](Get-Random -Minimum 97 -Maximum 123) })
        $safeName = "${prefix}_${suffix}64.dll"
    }
    
    $Script:SafeDllName = $safeName
    
    # Update OnlineFixFiles entries with disk names
    foreach ($f in $Script:OnlineFixFiles) {
        if ($f.Name -eq "OnlineFix64.dll") {
            $f.DiskName = $null   # v3.3.1: keep original name
            $Script:SafeDllName = "OnlineFix64.dll"   # also keep dlllist.txt referencing the original name to avoid winmm.dll loading error 126
        }
    }
}

# ============================================================================
# Language Detection
# ============================================================================
# Detection uses Windows UI culture first, never IP geolocation.
function Detect-Language {
    $Script:Lang = Resolve-MbuLanguage
    $env:MBU_LANG = $Script:Lang
}

function T {
    param([string]$Key)
    
    $translations = @{
        "admin_required" = @{
            en = "Administrator privileges required!"
            zh = "需要管理员权限!"
            hi = "व्यवस्थापक विशेषाधिकार आवश्यक हैं!"
            es = "¡Se requieren privilegios de Administrador!"
            fr = "Privilèges d'administrateur requis !"
            ar = "صلاحيات المسؤول مطلوبة!"
            ru = "Требуются права администратора!"
        }
        "admin_elevating" = @{
            en = "Requesting elevation..."
            zh = "正在请求提权..."
            hi = "विशेषाधिकार का अनुरोध किया जा रहा है..."
            es = "Solicitando elevación..."
            fr = "Demande d'élévation..."
            ar = "جارٍ طلب رفع الصلاحيات..."
            ru = "Запрос повышения прав..."
        }
        "admin_ok" = @{
            en = "Running with Administrator privileges"
            zh = "已以管理员权限运行"
            hi = "व्यवस्थापक विशेषाधिकार के साथ चल रहा है"
            es = "Ejecutando con privilegios de Administrador"
            fr = "Exécution avec les privilèges d'administrateur"
            ar = "يعمل بصلاحيات المسؤول"
            ru = "Выполняется с правами администратора"
        }
        "menu_title" = @{
            en = "Available Options"
            zh = "可用选项"
            hi = "उपलब्ध विकल्प"
            es = "Opciones disponibles"
            fr = "Options disponibles"
            ar = "الخيارات المتاحة"
            ru = "Доступные параметры"
        }
        "menu_1" = @{
            en = "Install Mod (Unlock Game)"
            zh = "安装模组 (解锁游戏)"
            hi = "मॉड स्थापित करें (गेम अनलॉक करें)"
            es = "Instalar mod (desbloquear juego)"
            fr = "Installer le mod (déverrouiller le jeu)"
            ar = "تثبيت التعديل (فتح اللعبة)"
            ru = "Установить мод (разблокировать игру)"
        }
        "menu_2" = @{
            en = "Restore Original (Back to Trial)"
            zh = "还原原始状态 (恢复试用版)"
            hi = "मूल स्थिति पुनर्स्थापित करें (ट्रायल पर वापस)"
            es = "Restaurar original (volver a prueba)"
            fr = "Restaurer l'original (revenir à l'essai)"
            ar = "استعادة الأصلي (العودة إلى النسخة التجريبية)"
            ru = "Восстановить оригинал (вернуться к пробной версии)"
        }
        "menu_3" = @{
            en = "Open Minecraft"
            zh = "打开 Minecraft"
            hi = "Minecraft खोलें"
            es = "Abrir Minecraft"
            fr = "Ouvrir Minecraft"
            ar = "فتح Minecraft"
            ru = "Открыть Minecraft"
        }
        "menu_4" = @{
            en = "Install Minecraft (Xbox App)"
            zh = "安装 Minecraft (Xbox 应用)"
            hi = "Minecraft स्थापित करें (Xbox ऐप)"
            es = "Instalar Minecraft (app de Xbox)"
            fr = "Installer Minecraft (application Xbox)"
            ar = "تثبيت Minecraft (تطبيق Xbox)"
            ru = "Установить Minecraft (приложение Xbox)"
        }
        "menu_5" = @{
            en = "Check Status"
            zh = "检查状态"
            hi = "स्थिति जाँचें"
            es = "Comprobar estado"
            fr = "Vérifier l'état"
            ar = "فحص الحالة"
            ru = "Проверить состояние"
        }
        "menu_6" = @{
            en = "System Diagnostics"
            zh = "系统诊断"
            hi = "सिस्टम निदान"
            es = "Diagnóstico del sistema"
            fr = "Diagnostic système"
            ar = "تشخيص النظام"
            ru = "Диагностика системы"
        }
        "menu_0" = @{
            en = "Exit"
            zh = "退出"
            hi = "बाहर"
            es = "Salir"
            fr = "Quitter"
            ar = "خروج"
            ru = "Выход"
        }
        "choose" = @{
            en = "Choose an option"
            zh = "请选择"
            hi = "एक विकल्प चुनें"
            es = "Elija una opción"
            fr = "Choisissez une option"
            ar = "اختر خياراً"
            ru = "Выберите параметр"
        }
        "invalid" = @{
            en = "Invalid option!"
            zh = "无效的选项!"
            hi = "अमान्य विकल्प!"
            es = "¡Opción inválida!"
            fr = "Option invalide !"
            ar = "خيار غير صالح!"
            ru = "Неверный параметр!"
        }
        "mc_not_found" = @{
            en = "Minecraft NOT FOUND!"
            zh = "未找到 Minecraft!"
            hi = "Minecraft नहीं मिला!"
            es = "¡Minecraft NO ENCONTRADO!"
            fr = "Minecraft INTROUVABLE !"
            ar = "Minecraft غير موجود!"
            ru = "Minecraft НЕ НАЙДЕН!"
        }
        "mc_found" = @{
            en = "Minecraft found"
            zh = "已找到 Minecraft"
            hi = "Minecraft मिला"
            es = "Minecraft encontrado"
            fr = "Minecraft trouvé"
            ar = "تم العثور على Minecraft"
            ru = "Minecraft найден"
        }
        "mc_path" = @{
            en = "Path"
            zh = "路径"
            hi = "पथ"
            es = "Ruta"
            fr = "Chemin"
            ar = "المسار"
            ru = "Путь"
        }
        "installing" = @{
            en = "Installing bypass..."
            zh = "正在安装旁路..."
            hi = "बाईपास स्थापित किया जा रहा है..."
            es = "Instalando bypass..."
            fr = "Installation du bypass..."
            ar = "جارٍ تثبيت التجاوز..."
            ru = "Установка обхода..."
        }
        "adding_exclusions" = @{
            en = "Adding antivirus exclusions..."
            zh = "正在添加杀毒软件排除项..."
            hi = "एंटीवायरस अपवाद जोड़े जा रहे हैं..."
            es = "Añadiendo exclusiones de antivirus..."
            fr = "Ajout des exclusions antivirus..."
            ar = "جارٍ إضافة استثناءات مكافحة الفيروسات..."
            ru = "Добавление исключений антивируса..."
        }
        "exclusion_added" = @{
            en = "Windows Defender exclusion added"
            zh = "已添加 Windows Defender 排除项"
            hi = "Windows Defender अपवाद जोड़ा गया"
            es = "Exclusión de Windows Defender añadida"
            fr = "Exclusion Windows Defender ajoutée"
            ar = "تمت إضافة استثناء Windows Defender"
            ru = "Исключение Windows Defender добавлено"
        }
        "exclusion_failed" = @{
            en = "Could not add exclusion (may need manual setup)"
            zh = "无法添加排除项 (可能需要手动设置)"
            hi = "अपवाद नहीं जोड़ा जा सका (मैन्युअल सेटअप आवश्यक हो सकता है)"
            es = "No se pudo añadir la exclusión (puede requerir configuración manual)"
            fr = "Impossible d'ajouter l'exclusion (configuration manuelle peut être nécessaire)"
            ar = "تعذرت إضافة الاستثناء (قد يلزم إعداد يدوي)"
            ru = "Не удалось добавить исключение (может потребоваться ручная настройка)"
        }
        "downloading" = @{
            en = "Downloading"
            zh = "下载中"
            hi = "डाउनलोड हो रहा है"
            es = "Descargando"
            fr = "Téléchargement"
            ar = "جارٍ التنزيل"
            ru = "Загрузка"
        }
        "download_ok" = @{
            en = "Downloaded successfully"
            zh = "下载成功"
            hi = "सफलतापूर्वक डाउनलोड हुआ"
            es = "Descargado correctamente"
            fr = "Téléchargé avec succès"
            ar = "تم التنزيل بنجاح"
            ru = "Успешно загружено"
        }
        "download_fail" = @{
            en = "Download FAILED"
            zh = "下载失败"
            hi = "डाउनलोड विफल"
            es = "DESCARGA FALLIDA"
            fr = "ÉCHEC DU TÉLÉCHARGEMENT"
            ar = "فشل التنزيل"
            ru = "ОШИБКА ЗАГРУЗКИ"
        }
        "hash_ok" = @{
            en = "Integrity verified"
            zh = "完整性验证通过"
            hi = "अखंडता सत्यापित"
            es = "Integridad verificada"
            fr = "Intégrité vérifiée"
            ar = "تم التحقق من السلامة"
            ru = "Целостность проверена"
        }
        "hash_fail" = @{
            en = "INTEGRITY CHECK FAILED! File may be corrupted."
            zh = "完整性校验失败! 文件可能已损坏。"
            hi = "अखंडता जाँच विफल! फ़ाइल दूषित हो सकती है।"
            es = "¡VERIFICACIÓN DE INTEGRIDAD FALLIDA! El archivo puede estar dañado."
            fr = "ÉCHEC DE LA VÉRIFICATION D'INTÉGRITÉ ! Le fichier peut être corrompu."
            ar = "فشل التحقق من السلامة! قد يكون الملف تالفاً."
            ru = "ОШИБКА ПРОВЕРКИ ЦЕЛОСТНОСТИ! Возможно, файл поврежден."
        }
        "install_ok" = @{
            en = "Bypass installed successfully!"
            zh = "旁路安装成功!"
            hi = "बाईपास सफलतापूर्वक स्थापित!"
            es = "¡Bypass instalado correctamente!"
            fr = "Bypass installé avec succès !"
            ar = "تم تثبيت التجاوز بنجاح!"
            ru = "Обход успешно установлен!"
        }
        "install_fail" = @{
            en = "Installation failed"
            zh = "安装失败"
            hi = "स्थापना विफल"
            es = "Instalación fallida"
            fr = "Installation échouée"
            ar = "فشل التثبيت"
            ru = "Установка не удалась"
        }
        "verifying" = @{
            en = "Verifying installation..."
            zh = "正在验证安装..."
            hi = "स्थापना सत्यापित की जा रही है..."
            es = "Verificando instalación..."
            fr = "Vérification de l'installation..."
            ar = "جارٍ التحقق من التثبيت..."
            ru = "Проверка установки..."
        }
        "files_ok" = @{
            en = "All files present and verified!"
            zh = "所有文件已就位并验证通过!"
            hi = "सभी फाइलें मौजूद हैं और सत्यापित हैं!"
            es = "¡Todos los archivos están presentes y verificados!"
            fr = "Tous les fichiers sont présents et vérifiés !"
            ar = "جميع الملفات موجودة وتم التحقق منها!"
            ru = "Все файлы на месте и проверены!"
        }
        "files_missing" = @{
            en = "FILES WERE DELETED BY ANTIVIRUS!"
            zh = "文件已被杀毒软件删除!"
            hi = "फाइलें एंटीवायरस द्वारा हटा दी गई हैं!"
            es = "¡LOS ARCHIVOS FUERON ELIMINADOS POR EL ANTIVIRUS!"
            fr = "LES FICHIERS ONT ÉTÉ SUPPRIMÉS PAR L'ANTIVIRUS !"
            ar = "تم حذف الملفات بواسطة مكافحة الفيروسات!"
            ru = "ФАЙЛЫ БЫЛИ УДАЛЕНЫ АНТИВИРУСОМ!"
        }
        "retry_install" = @{
            en = "Retrying installation..."
            zh = "正在重试安装..."
            hi = "स्थापना का पुनः प्रयास..."
            es = "Reintentando instalación..."
            fr = "Nouvelle tentative d'installation..."
            ar = "جارٍ إعادة محاولة التثبيت..."
            ru = "Повторная попытка установки..."
        }
        "av_disable" = @{
            en = "PLEASE DISABLE YOUR ANTIVIRUS TEMPORARILY:"
            zh = "请暂时禁用杀毒软件:"
            hi = "कृपया अस्थायी रूप से अपना एंटीवायरस अक्षम करें:"
            es = "DESACTIVE SU ANTIVIRUS TEMPORALMENTE:"
            fr = "VEUILLEZ DÉSACTIVER VOTRE ANTIVIRUS TEMPORAIREMENT :"
            ar = "يرجى تعطيل برنامج مكافحة الفيروسات مؤقتاً:"
            ru = "ПОЖАЛУЙСТА, ВРЕМЕННО ОТКЛЮЧИТЕ ВАШ АНТИВИРУС:"
        }
        "av_step1" = @{
            en = "1. Open Windows Security"
            zh = "1. 打开 Windows 安全中心"
            hi = "1. Windows सुरक्षा खोलें"
            es = "1. Abra Seguridad de Windows"
            fr = "1. Ouvrez Sécurité Windows"
            ar = "1. افتح أمان Windows"
            ru = "1. Откройте Безопасность Windows"
        }
        "av_step2" = @{
            en = "2. Go to Virus & threat protection"
            zh = "2. 进入 病毒和威胁防护"
            hi = "2. वायरस और खतरे से सुरक्षा पर जाएँ"
            es = "2. Vaya a Protección contra virus y amenazas"
            fr = "2. Allez à Protection contre les virus et menaces"
            ar = "2. انتقل إلى الحماية من الفيروسات والتهديدات"
            ru = "2. Перейдите в Защита от вирусов и угроз"
        }
        "av_step3" = @{
            en = "3. Click 'Manage settings'"
            zh = "3. 点击 '管理设置'"
            hi = "3. 'सेटिंग्स प्रबंधित करें' पर क्लिक करें"
            es = "3. Haga clic en 'Administrar configuración'"
            fr = "3. Cliquez sur 'Gérer les paramètres'"
            ar = "3. انقر فوق 'إدارة الإعدادات'"
            ru = "3. Нажмите 'Управление настройками'"
        }
        "av_step4" = @{
            en = "4. Turn OFF Real-time protection"
            zh = "4. 关闭 实时保护"
            hi = "4. रियल-टाइम सुरक्षा बंद करें"
            es = "4. DESACTIVE la protección en tiempo real"
            fr = "4. DÉSACTIVEZ la protection en temps réel"
            ar = "4. أوقف تشغيل الحماية في الوقت الفعلي"
            ru = "4. ВЫКЛЮЧИТЕ защиту в реальном времени"
        }
        "av_step5" = @{
            en = "5. Run this script again"
            zh = "5. 重新运行本脚本"
            hi = "5. इस स्क्रिप्ट को फिर से चलाएँ"
            es = "5. Ejecute este script de nuevo"
            fr = "5. Exécutez ce script à nouveau"
            ar = "5. أعد تشغيل هذا البرنامج النصي"
            ru = "5. Запустите этот скрипт снова"
        }
        "av_folder" = @{
            en = "OR add this folder to exclusions:"
            zh = "或者将此文件夹添加到排除项:"
            hi = "या इस फ़ोल्डर को अपवादों में जोड़ें:"
            es = "O añada esta carpeta a las exclusiones:"
            fr = "OU ajoutez ce dossier aux exclusions :"
            ar = "أو أضف هذا المجلد إلى الاستثناءات:"
            ru = "ИЛИ добавьте эту папку в исключения:"
        }
        "av_detected_blocking" = @{
            en = "Your antivirus DELETED the file after download!"
            zh = "杀毒软件已在下载后删除了文件!"
            hi = "आपके एंटीवायरस ने डाउनलोड के बाद फ़ाइल हटा दी!"
            es = "¡Su antivirus ELIMINÓ el archivo después de la descarga!"
            fr = "Votre antivirus A SUPPRIMÉ le fichier après le téléchargement !"
            ar = "حذف برنامج مكافحة الفيروسات الملف بعد التنزيل!"
            ru = "Ваш антивирус УДАЛИЛ файл после загрузки!"
        }
        "av_need_disable" = @{
            en = "You need to TEMPORARILY DISABLE your antivirus protection."
            zh = "您需要暂时禁用杀毒软件保护。"
            hi = "आपको अस्थायी रूप से अपनी एंटीवायरस सुरक्षा अक्षम करनी होगी।"
            es = "Necesita DESACTIVAR TEMPORALMENTE la protección de su antivirus."
            fr = "Vous devez DÉSACTIVER TEMPORAIREMENT la protection de votre antivirus."
            ar = "تحتاج إلى تعطيل حماية برنامج مكافحة الفيروسات مؤقتاً."
            ru = "Вам необходимо ВРЕМЕННО ОТКЛЮЧИТЬ защиту антивируса."
        }
        "av_press_enter" = @{
            en = "After disabling your antivirus, press ENTER to continue..."
            zh = "禁用杀毒软件后,按 ENTER 键继续..."
            hi = "एंटीवायरस अक्षम करने के बाद, जारी रखने के लिए ENTER दबाएँ..."
            es = "Después de desactivar su antivirus, pulse ENTER para continuar..."
            fr = "Après avoir désactivé votre antivirus, appuyez sur ENTRÉE pour continuer..."
            ar = "بعد تعطيل برنامج مكافحة الفيروسات، اضغط ENTER للمتابعة..."
            ru = "После отключения антивируса нажмите ВВОД для продолжения..."
        }
        "av_retrying_after_disable" = @{
            en = "Retrying download (antivirus should be disabled now)..."
            zh = "正在重试下载 (杀毒软件现在应已禁用)..."
            hi = "डाउनलोड का पुनः प्रयास (एंटीवायरस अब अक्षम होना चाहिए)..."
            es = "Reintentando descarga (el antivirus debería estar desactivado)..."
            fr = "Nouvelle tentative de téléchargement (l'antivirus devrait être désactivé)..."
            ar = "جارٍ إعادة محاولة التنزيل (يجب أن تكون الحماية معطلة الآن)..."
            ru = "Повторная загрузка (антивирус теперь должен быть отключен)..."
        }
        "av_still_blocking" = @{
            en = "Files are STILL being blocked! Make sure your antivirus is fully disabled."
            zh = "文件仍然被拦截! 请确保杀毒软件已完全禁用。"
            hi = "फाइलें अभी भी अवरुद्ध हैं! सुनिश्चित करें कि आपका एंटीवायरस पूरी तरह अक्षम है।"
            es = "¡Los archivos SIGUEN bloqueados! Asegúrese de que su antivirus esté completamente desactivado."
            fr = "Les fichiers sont TOUJOURS bloqués ! Assurez-vous que votre antivirus est complètement désactivé."
            ar = "الملفات لا تزال محظورة! تأكد من تعطيل برنامج مكافحة الفيروسات بالكامل."
            ru = "Файлы ВСЁ ЕЩЁ заблокированы! Убедитесь, что антивирус полностью отключен."
        }
        "av_reenable" = @{
            en = "You can now re-enable your antivirus protection."
            zh = "您现在可以重新启用杀毒软件保护。"
            hi = "अब आप अपनी एंटीवायरस सुरक्षा फिर से सक्षम कर सकते हैं।"
            es = "Ahora puede volver a activar la protección de su antivirus."
            fr = "Vous pouvez maintenant réactiver la protection de votre antivirus."
            ar = "يمكنك الآن إعادة تمكين حماية برنامج مكافحة الفيروسات."
            ru = "Теперь вы можете снова включить защиту антивируса."
        }
        "removing" = @{
            en = "Removing bypass files..."
            zh = "正在移除旁路文件..."
            hi = "बाईपास फाइलें हटाई जा रही हैं..."
            es = "Eliminando archivos de bypass..."
            fr = "Suppression des fichiers de bypass..."
            ar = "جارٍ إزالة ملفات التجاوز..."
            ru = "Удаление файлов обхода..."
        }
        "removed_ok" = @{
            en = "Bypass removed successfully! Game restored to Trial."
            zh = "旁路已成功移除! 游戏已恢复为试用版。"
            hi = "बाईपास सफलतापूर्वक हटाया गया! गेम ट्रायल पर पुनर्स्थापित।"
            es = "¡Bypass eliminado correctamente! Juego restaurado al modo Prueba."
            fr = "Bypass supprimé avec succès ! Jeu restauré en mode Essai."
            ar = "تمت إزالة التجاوز بنجاح! تمت استعادة اللعبة إلى الوضع التجريبي."
            ru = "Обход успешно удалён! Игра восстановлена до пробной версии."
        }
        "resetting_license" = @{
            en = "Resetting Windows Store / Gaming Services license cache..."
            zh = "正在重置 Windows 应用商店 / 游戏服务许可证缓存..."
            hi = "Windows Store / Gaming Services लाइसेंस कैश रीसेट हो रहा है..."
            es = "Restableciendo caché de licencia de Windows Store / Gaming Services..."
            fr = "Réinitialisation du cache de licence Windows Store / Gaming Services..."
            ar = "جارٍ إعادة تعيين ذاكرة التخزين المؤقت لترخيص Windows Store / Gaming Services..."
            ru = "Сброс кэша лицензии Windows Store / Gaming Services..."
        }
        "license_reset_partial" = @{
            en = "Could not fully reset license cache. You may need to restart your PC."
            zh = "无法完全重置许可证缓存。 您可能需要重启电脑。"
            hi = "लाइसेंस कैश पूरी तरह रीसेट नहीं हो सका। आपको PC पुनः आरंभ करने की आवश्यकता हो सकती है।"
            es = "No se pudo restablecer completamente la caché de licencia. Puede que necesite reiniciar su PC."
            fr = "Impossible de réinitialiser complètement le cache de licence. Vous devrez peut-être redémarrer votre PC."
            ar = "تعذرت إعادة تعيين ذاكرة التخزين المؤقت للترخيص بالكامل. قد تحتاج إلى إعادة تشغيل جهاز الكمبيوتر."
            ru = "Не удалось полностью сбросить кэш лицензии. Возможно, потребуется перезагрузить компьютер."
        }
        "restore_reopen_note" = @{
            en = "IMPORTANT: Open Minecraft again to verify it returned to Trial mode. If still showing as Paid, restart your PC."
            zh = "重要: 再次打开 Minecraft 以验证已恢复为试用版。 如果仍显示为付费版,请重启电脑。"
            hi = "महत्वपूर्ण: यह सत्यापित करने के लिए Minecraft को फिर से खोलें कि वह ट्रायल मोड पर वापस आ गया है। यदि अभी भी Paid के रूप में दिख रहा है, तो PC पुनः आरंभ करें।"
            es = "IMPORTANTE: Abra Minecraft de nuevo para verificar que volvió al modo Prueba. Si sigue mostrando como Pagado, reinicie su PC."
            fr = "IMPORTANT : Ouvrez Minecraft à nouveau pour vérifier qu'il est revenu en mode Essai. S'il s'affiche toujours comme Payé, redémarrez votre PC."
            ar = "هام: افتح Minecraft مرة أخرى للتحقق من أنه عاد إلى الوضع التجريبي. إذا استمر في العرض كمدفوع، فأعد تشغيل الكمبيوتر."
            ru = "ВАЖНО: Откройте Minecraft снова, чтобы убедиться, что он вернулся в пробный режим. Если по-прежнему отображается как платная версия, перезагрузите компьютер."
        }
        "resetting_app" = @{
            en = "Resetting Minecraft app data (clearing license cache)..."
            zh = "正在重置 Minecraft 应用数据 (清除许可证缓存)..."
            hi = "Minecraft ऐप डेटा रीसेट हो रहा है (लाइसेंस कैश साफ़ किया जा रहा है)..."
            es = "Restableciendo datos de la app de Minecraft (vaciando caché de licencia)..."
            fr = "Réinitialisation des données d'application Minecraft (vidage du cache de licence)..."
            ar = "جارٍ إعادة تعيين بيانات تطبيق Minecraft (مسح ذاكرة التخزين المؤقت للترخيص)..."
            ru = "Сброс данных приложения Minecraft (очистка кэша лицензии)..."
        }
        "app_reset_ok" = @{
            en = "Minecraft app data reset successfully! License cache cleared."
            zh = "Minecraft 应用数据重置成功! 许可证缓存已清除。"
            hi = "Minecraft ऐप डेटा सफलतापूर्वक रीसेट! लाइसेंस कैश साफ़।"
            es = "¡Datos de la app de Minecraft restablecidos! Caché de licencia vaciada."
            fr = "Données d'application Minecraft réinitialisées ! Cache de licence vidé."
            ar = "تمت إعادة تعيين بيانات تطبيق Minecraft بنجاح! تم مسح ذاكرة التخزين المؤقت للترخيص."
            ru = "Данные приложения Minecraft успешно сброшены! Кэш лицензии очищен."
        }
        "app_reset_fallback" = @{
            en = "Reset-AppxPackage not available. Trying manual cleanup..."
            zh = "Reset-AppxPackage 不可用。 正在尝试手动清理..."
            hi = "Reset-AppxPackage उपलब्ध नहीं है। मैन्युअल सफ़ाई का प्रयास..."
            es = "Reset-AppxPackage no disponible. Intentando limpieza manual..."
            fr = "Reset-AppxPackage indisponible. Tentative de nettoyage manuel..."
            ar = "Reset-AppxPackage غير متوفر. جارٍ محاولة التنظيف اليدوي..."
            ru = "Reset-AppxPackage недоступен. Попытка ручной очистки..."
        }
        "app_data_cleared" = @{
            en = "Minecraft app data manually cleared."
            zh = "Minecraft 应用数据已手动清除。"
            hi = "Minecraft ऐप डेटा मैन्युअल रूप से साफ़ किया गया।"
            es = "Datos de la app de Minecraft limpiados manualmente."
            fr = "Données d'application Minecraft nettoyées manuellement."
            ar = "تم مسح بيانات تطبيق Minecraft يدوياً."
            ru = "Данные приложения Minecraft очищены вручную."
        }
        "reregistering_mc" = @{
            en = "Re-registering Minecraft package (force license re-validation)..."
            zh = "正在重新注册 Minecraft 包 (强制许可证重新验证)..."
            hi = "Minecraft पैकेज पुनः पंजीकृत किया जा रहा है (लाइसेंस पुनः सत्यापन के लिए)..."
            es = "Volviendo a registrar el paquete de Minecraft (forzando revalidación de licencia)..."
            fr = "Réenregistrement du package Minecraft (forçage de la revalidation de licence)..."
            ar = "جارٍ إعادة تسجيل حزمة Minecraft (فرض إعادة التحقق من الترخيص)..."
            ru = "Повторная регистрация пакета Minecraft (принудительная повторная проверка лицензии)..."
        }
        "reregister_ok" = @{
            en = "Minecraft package re-registered successfully."
            zh = "Minecraft 包已成功重新注册。"
            hi = "Minecraft पैकेज सफलतापूर्वक पुनः पंजीकृत।"
            es = "Paquete de Minecraft re-registrado correctamente."
            fr = "Package Minecraft réenregistré avec succès."
            ar = "تمت إعادة تسجيل حزمة Minecraft بنجاح."
            ru = "Пакет Minecraft успешно зарегистрирован повторно."
        }
        "clearing_app_cache" = @{
            en = "Clearing Minecraft app cache and settings..."
            zh = "正在清除 Minecraft 应用缓存和设置..."
            hi = "Minecraft ऐप कैश और सेटिंग्स साफ़ की जा रही हैं..."
            es = "Vaciando caché y configuración de la app de Minecraft..."
            fr = "Vidage du cache et des paramètres de l'application Minecraft..."
            ar = "جارٍ مسح ذاكرة التخزين المؤقت وإعدادات تطبيق Minecraft..."
            ru = "Очистка кэша и настроек приложения Minecraft..."
        }
        "cache_cleared" = @{
            en = "App cache and settings cleared."
            zh = "应用缓存和设置已清除。"
            hi = "ऐप कैश और सेटिंग्स साफ़।"
            es = "Caché y configuración de la app vaciadas."
            fr = "Cache et paramètres de l'application vidés."
            ar = "تم مسح ذاكرة التخزين المؤقت وإعدادات التطبيق."
            ru = "Кэш и настройки приложения очищены."
        }
        "opening_mc" = @{
            en = "Opening Minecraft..."
            zh = "正在打开 Minecraft..."
            hi = "Minecraft खोला जा रहा है..."
            es = "Abriendo Minecraft..."
            fr = "Ouverture de Minecraft..."
            ar = "جارٍ فتح Minecraft..."
            ru = "Открытие Minecraft..."
        }
        "mc_opened" = @{
            en = "Minecraft should open shortly"
            zh = "Minecraft 应很快打开"
            hi = "Minecraft जल्द ही खुलेगा"
            es = "Minecraft debería abrirse en breve"
            fr = "Minecraft devrait s'ouvrir sous peu"
            ar = "يجب أن يفتح Minecraft قريباً"
            ru = "Minecraft скоро откроется"
        }
        "opening_xbox" = @{
            en = "Opening Xbox App / Minecraft page..."
            zh = "正在打开 Xbox 应用 / Minecraft 页面..."
            hi = "Xbox ऐप / Minecraft पृष्ठ खोला जा रहा है..."
            es = "Abriendo app de Xbox / página de Minecraft..."
            fr = "Ouverture de l'application Xbox / page Minecraft..."
            ar = "جارٍ فتح تطبيق Xbox / صفحة Minecraft..."
            ru = "Открытие приложения Xbox / страницы Minecraft..."
        }
        "status_title" = @{
            en = "SYSTEM STATUS"
            zh = "系统状态"
            hi = "सिस्टम स्थिति"
            es = "ESTADO DEL SISTEMA"
            fr = "ÉTAT DU SYSTÈME"
            ar = "حالة النظام"
            ru = "СОСТОЯНИЕ СИСТЕМЫ"
        }
        "status_mc" = @{
            en = "Minecraft Installed"
            zh = "Minecraft 已安装"
            hi = "Minecraft स्थापित"
            es = "Minecraft instalado"
            fr = "Minecraft installé"
            ar = "Minecraft مثبت"
            ru = "Minecraft установлен"
        }
        "status_type" = @{
            en = "Installation Type"
            zh = "安装类型"
            hi = "स्थापना प्रकार"
            es = "Tipo de instalación"
            fr = "Type d'installation"
            ar = "نوع التثبيت"
            ru = "Тип установки"
        }
        "status_xbox" = @{
            en = "Xbox App (GDK) - Compatible"
            zh = "Xbox 应用 (GDK) - 兼容"
            hi = "Xbox ऐप (GDK) - संगत"
            es = "App de Xbox (GDK) - Compatible"
            fr = "Application Xbox (GDK) - Compatible"
            ar = "تطبيق Xbox (GDK) - متوافق"
            ru = "Приложение Xbox (GDK) - совместимо"
        }
        "status_store" = @{
            en = "Microsoft Store (UWP) - NOT COMPATIBLE!"
            zh = "Microsoft 应用商店 (UWP) - 不兼容!"
            hi = "Microsoft Store (UWP) - असंगत!"
            es = "Microsoft Store (UWP) - ¡NO COMPATIBLE!"
            fr = "Microsoft Store (UWP) - NON COMPATIBLE !"
            ar = "Microsoft Store (UWP) - غير متوافق!"
            ru = "Microsoft Store (UWP) - НЕ СОВМЕСТИМО!"
        }
        "status_bypass" = @{
            en = "Bypass Status"
            zh = "旁路状态"
            hi = "बाईपास स्थिति"
            es = "Estado del bypass"
            fr = "État du bypass"
            ar = "حالة التجاوز"
            ru = "Состояние обхода"
        }
        "status_installed" = @{
            en = "INSTALLED"
            zh = "已安装"
            hi = "स्थापित"
            es = "INSTALADO"
            fr = "INSTALLÉ"
            ar = "مثبت"
            ru = "УСТАНОВЛЕНО"
        }
        "status_not_installed" = @{
            en = "NOT INSTALLED"
            zh = "未安装"
            hi = "स्थापित नहीं"
            es = "NO INSTALADO"
            fr = "NON INSTALLÉ"
            ar = "غير مثبت"
            ru = "НЕ УСТАНОВЛЕНО"
        }
        "status_partial" = @{
            en = "PARTIAL (files missing - antivirus deleted them?)"
            zh = "部分安装 (文件丢失 - 杀毒软件删除了?)"
            hi = "आंशिक (फाइलें गायब - एंटीवायरस ने हटा दी?)"
            es = "PARCIAL (archivos faltantes - ¿el antivirus los eliminó?)"
            fr = "PARTIEL (fichiers manquants - l'antivirus les a supprimés ?)"
            ar = "جزئي (الملفات مفقودة - هل حذفها برنامج مكافحة الفيروسات؟)"
            ru = "ЧАСТИЧНО (файлы отсутствуют - антивирус их удалил?)"
        }
        "status_av" = @{
            en = "Antivirus"
            zh = "杀毒软件"
            hi = "एंटीवायरस"
            es = "Antivirus"
            fr = "Antivirus"
            ar = "مكافحة الفيروسات"
            ru = "Антивирус"
        }
        "status_defender_on" = @{
            en = "Active"
            zh = "已启用"
            hi = "सक्रिय"
            es = "Activo"
            fr = "Actif"
            ar = "نشط"
            ru = "Активен"
        }
        "status_defender_off" = @{
            en = "Not detected"
            zh = "未检测到"
            hi = "पता नहीं चला"
            es = "No detectado"
            fr = "Non détecté"
            ar = "غير مكتشف"
            ru = "Не обнаружен"
        }
        "persistence_ok" = @{
            en = "Reboot protection enabled (files auto-restore after restart)"
            zh = "重启保护已启用 (重启后文件自动恢复)"
            hi = "रीबूट सुरक्षा सक्षम (रीस्टार्ट के बाद फ़ाइलें स्वतः पुनर्स्थापित)"
            es = "Protección de reinicio activada (los archivos se restauran automáticamente tras reiniciar)"
            fr = "Protection au redémarrage activée (les fichiers se restaurent automatiquement après redémarrage)"
            ar = "تم تمكين حماية إعادة التشغيل (تتم استعادة الملفات تلقائياً بعد إعادة التشغيل)"
            ru = "Защита при перезагрузке включена (файлы автоматически восстанавливаются после перезагрузки)"
        }
        "persistence_fail" = @{
            en = "Could not enable reboot protection (Scheduled Task failed)"
            zh = "无法启用重启保护 (计划任务失败)"
            hi = "रीबूट सुरक्षा सक्षम नहीं हो सकी (शेड्यूल्ड टास्क विफल)"
            es = "No se pudo activar la protección de reinicio (tarea programada fallida)"
            fr = "Impossible d'activer la protection au redémarrage (tâche planifiée échouée)"
            ar = "تعذر تمكين حماية إعادة التشغيل (فشلت المهمة المجدولة)"
            ru = "Не удалось включить защиту при перезагрузке (задача расписания не выполнена)"
        }
        "persistence_removed" = @{
            en = "Reboot protection removed"
            zh = "重启保护已移除"
            hi = "रीबूट सुरक्षा हटाई गई"
            es = "Protección de reinicio eliminada"
            fr = "Protection au redémarrage supprimée"
            ar = "تمت إزالة حماية إعادة التشغيل"
            ru = "Защита при перезагрузке удалена"
        }
        "status_persistence" = @{
            en = "Reboot Protection"
            zh = "重启保护"
            hi = "रीबूट सुरक्षा"
            es = "Protección de reinicio"
            fr = "Protection au redémarrage"
            ar = "حماية إعادة التشغيل"
            ru = "Защита при перезагрузке"
        }
        "status_gaming" = @{
            en = "Gaming Services"
            zh = "游戏服务"
            hi = "गेमिंग सेवाएँ"
            es = "Gaming Services"
            fr = "Gaming Services"
            ar = "Gaming Services"
            ru = "Игровые службы"
        }
        "status_running" = @{
            en = "Running"
            zh = "运行中"
            hi = "चल रही है"
            es = "En ejecución"
            fr = "En cours d'exécution"
            ar = "قيد التشغيل"
            ru = "Выполняется"
        }
        "status_stopped" = @{
            en = "Stopped"
            zh = "已停止"
            hi = "रुकी हुई"
            es = "Detenido"
            fr = "Arrêté"
            ar = "متوقف"
            ru = "Остановлено"
        }
        "diag_title" = @{
            en = "SYSTEM DIAGNOSTICS"
            zh = "系统诊断"
            hi = "सिस्टम निदान"
            es = "DIAGNÓSTICO DEL SISTEMA"
            fr = "DIAGNOSTIC SYSTÈME"
            ar = "تشخيص النظام"
            ru = "ДИАГНОСТИКА СИСТЕМЫ"
        }
        "diag_xbox_app" = @{
            en = "Xbox App"
            zh = "Xbox 应用"
            hi = "Xbox ऐप"
            es = "App de Xbox"
            fr = "Application Xbox"
            ar = "تطبيق Xbox"
            ru = "Приложение Xbox"
        }
        "diag_mc_install" = @{
            en = "Minecraft Installation"
            zh = "Minecraft 安装"
            hi = "Minecraft स्थापना"
            es = "Instalación de Minecraft"
            fr = "Installation de Minecraft"
            ar = "تثبيت Minecraft"
            ru = "Установка Minecraft"
        }
        "diag_type" = @{
            en = "Installation Type"
            zh = "安装类型"
            hi = "स्थापना प्रकार"
            es = "Tipo de instalación"
            fr = "Type d'installation"
            ar = "نوع التثبيت"
            ru = "Тип установки"
        }
        "diag_permissions" = @{
            en = "Folder Permissions"
            zh = "文件夹权限"
            hi = "फ़ोल्डर अनुमतियाँ"
            es = "Permisos de carpeta"
            fr = "Autorisations du dossier"
            ar = "صلاحيات المجلد"
            ru = "Разрешения папки"
        }
        "diag_gaming" = @{
            en = "Gaming Services"
            zh = "游戏服务"
            hi = "गेमिंग सेवाएँ"
            es = "Gaming Services"
            fr = "Gaming Services"
            ar = "Gaming Services"
            ru = "Игровые службы"
        }
        "diag_integrity" = @{
            en = "Game Integrity"
            zh = "游戏完整性"
            hi = "गेम अखंडता"
            es = "Integridad del juego"
            fr = "Intégrité du jeu"
            ar = "سلامة اللعبة"
            ru = "Целостность игры"
        }
        "diag_bypass" = @{
            en = "Bypass Files"
            zh = "旁路文件"
            hi = "बाईपास फ़ाइलें"
            es = "Archivos de bypass"
            fr = "Fichiers de bypass"
            ar = "ملفات التجاوز"
            ru = "Файлы обхода"
        }
        "diag_all_ok" = @{
            en = "All checks passed! System is ready."
            zh = "所有检查通过! 系统已就绪。"
            hi = "सभी जाँचें पास! सिस्टम तैयार है।"
            es = "¡Todas las comprobaciones pasaron! El sistema está listo."
            fr = "Toutes les vérifications ont réussi ! Le système est prêt."
            ar = "جميع الفحوصات ناجحة! النظام جاهز."
            ru = "Все проверки пройдены! Система готова."
        }
        "yes" = @{
            en = "Yes"
            zh = "是"
            hi = "हाँ"
            es = "Sí"
            fr = "Oui"
            ar = "نعم"
            ru = "Да"
        }
        "no" = @{
            en = "No"
            zh = "否"
            hi = "नहीं"
            es = "No"
            fr = "Non"
            ar = "لا"
            ru = "Нет"
        }
        "ok" = @{
            en = "OK"
            zh = "确定"
            hi = "ठीक है"
            es = "OK"
            fr = "OK"
            ar = "موافق"
            ru = "ОК"
        }
        "found" = @{
            en = "Found"
            zh = "已找到"
            hi = "मिला"
            es = "Encontrado"
            fr = "Trouvé"
            ar = "موجود"
            ru = "Найдено"
        }
        "not_found" = @{
            en = "Not Found"
            zh = "未找到"
            hi = "नहीं मिला"
            es = "No encontrado"
            fr = "Introuvable"
            ar = "غير موجود"
            ru = "Не найдено"
        }
        "writable" = @{
            en = "Writable"
            zh = "可写"
            hi = "लिखने योग्य"
            es = "Escribible"
            fr = "Inscriptible"
            ar = "قابل للكتابة"
            ru = "Доступно для записи"
        }
        "no_write" = @{
            en = "No write access"
            zh = "无写入权限"
            hi = "लिखने की अनुमति नहीं"
            es = "Sin acceso de escritura"
            fr = "Aucun accès en écriture"
            ar = "لا توجد صلاحية للكتابة"
            ru = "Нет доступа на запись"
        }
        "open_now" = @{
            en = "You can now open Minecraft from the Start Menu!"
            zh = "您现在可以从开始菜单打开 Minecraft!"
            hi = "अब आप Minecraft को स्टार्ट मेनू से खोल सकते हैं!"
            es = "¡Ya puede abrir Minecraft desde el menú Inicio!"
            fr = "Vous pouvez maintenant ouvrir Minecraft depuis le menu Démarrer !"
            ar = "يمكنك الآن فتح Minecraft من قائمة ابدأ!"
            ru = "Теперь вы можете открыть Minecraft из меню «Пуск»!"
        }
        "mc_running" = @{
            en = "Minecraft is running. Closing it first..."
            zh = "Minecraft 正在运行。 正在先关闭它..."
            hi = "Minecraft चल रहा है। पहले इसे बंद किया जा रहा है..."
            es = "Minecraft está en ejecución. Cerrándolo primero..."
            fr = "Minecraft est en cours d'exécution. Fermeture en cours..."
            ar = "Minecraft قيد التشغيل. جارٍ إغلاقه أولاً..."
            ru = "Minecraft запущен. Сначала закрываю его..."
        }
        "press_enter" = @{
            en = "Press Enter to continue..."
            zh = "按 Enter 键继续..."
            hi = "जारी रखने के लिए Enter दबाएँ..."
            es = "Pulse Enter para continuar..."
            fr = "Appuyez sur Entrée pour continuer..."
            ar = "اضغط Enter للمتابعة..."
            ru = "Нажмите Enter для продолжения..."
        }
        "exiting" = @{
            en = "Exiting... Goodbye!"
            zh = "正在退出... 再见!"
            hi = "बाहर हो रहा है... अलविदा!"
            es = "Saliendo... ¡Adiós!"
            fr = "Sortie... Au revoir !"
            ar = "جارٍ الخروج... وداعاً!"
            ru = "Выход... До свидания!"
        }
        "start_gaming" = @{
            en = "Starting Gaming Services..."
            zh = "正在启动游戏服务..."
            hi = "गेमिंग सेवाएँ शुरू की जा रही हैं..."
            es = "Iniciando Gaming Services..."
            fr = "Démarrage de Gaming Services..."
            ar = "جارٍ بدء Gaming Services..."
            ru = "Запуск игровых служб..."
        }
        "install_xbox_hint" = @{
            en = "Install Minecraft Trial from Xbox App (NOT Microsoft Store!)"
            zh = "从 Xbox 应用安装 Minecraft 试用版 (不是 Microsoft 应用商店!)"
            hi = "Xbox ऐप से Minecraft Trial स्थापित करें (Microsoft Store नहीं!)"
            es = "Instale Minecraft Trial desde la app de Xbox (¡NO Microsoft Store!)"
            fr = "Installez Minecraft Trial depuis l'application Xbox (PAS Microsoft Store !)"
            ar = "ثبّت Minecraft Trial من تطبيق Xbox (ليس Microsoft Store!)"
            ru = "Установите Minecraft Trial из приложения Xbox (НЕ Microsoft Store!)"
        }
        "repair_hint" = @{
            en = "Repair or reinstall Minecraft from Xbox App"
            zh = "从 Xbox 应用修复或重新安装 Minecraft"
            hi = "Xbox ऐप से Minecraft की मरम्मत या पुनः स्थापित करें"
            es = "Reparar o reinstalar Minecraft desde la app de Xbox"
            fr = "Réparer ou réinstaller Minecraft depuis l'application Xbox"
            ar = "أصلح أو أعد تثبيت Minecraft من تطبيق Xbox"
            ru = "Восстановите или переустановите Minecraft из приложения Xbox"
        }
        "run_admin_hint" = @{
            en = "Run this script as Administrator"
            zh = "以管理员身份运行本脚本"
            hi = "इस स्क्रिप्ट को व्यवस्थापक के रूप में चलाएँ"
            es = "Ejecute este script como Administrador"
            fr = "Exécutez ce script en tant qu'administrateur"
            ar = "شغّل هذا البرنامج النصي كمسؤول"
            ru = "Запустите этот скрипт от имени администратора"
        }
        "restart_gaming_hint" = @{
            en = "Restart Gaming Services or reinstall Xbox App"
            zh = "重启游戏服务或重新安装 Xbox 应用"
            hi = "गेमिंग सेवाएँ पुनः आरंभ करें या Xbox ऐप पुनः स्थापित करें"
            es = "Reinicie Gaming Services o reinstale la app de Xbox"
            fr = "Redémarrez Gaming Services ou réinstallez l'application Xbox"
            ar = "أعد تشغيل Gaming Services أو أعد تثبيت تطبيق Xbox"
            ru = "Перезапустите игровые службы или переустановите приложение Xbox"
        }
        "bd_suspending" = @{
            en = "Antivirus detected - trying to pause protection automatically..."
            zh = "检测到杀毒软件 - 正在尝试自动暂停保护..."
            hi = "एंटीवायरस पता चला - स्वतः सुरक्षा रोकने का प्रयास..."
            es = "Antivirus detectado - intentando pausar la protección automáticamente..."
            fr = "Antivirus détecté - tentative de mise en pause automatique de la protection..."
            ar = "تم اكتشاف برنامج مكافحة الفيروسات - جارٍ محاولة إيقاف الحماية تلقائياً..."
            ru = "Обнаружен антивирус - попытка автоматически приостановить защиту..."
        }
        "bd_suspended" = @{
            en = "Antivirus paused! Installing files now..."
            zh = "杀毒软件已暂停! 正在安装文件..."
            hi = "एंटीवायरस रुका! अब फाइलें स्थापित हो रही हैं..."
            es = "¡Antivirus pausado! Instalando archivos ahora..."
            fr = "Antivirus mis en pause ! Installation des fichiers en cours..."
            ar = "تم إيقاف برنامج مكافحة الفيروسات! جارٍ تثبيت الملفات الآن..."
            ru = "Антивирус приостановлен! Устанавливаю файлы..."
        }
        "bd_resumed" = @{
            en = "Antivirus protection restored."
            zh = "杀毒软件保护已恢复。"
            hi = "एंटीवायरस सुरक्षा पुनर्स्थापित।"
            es = "Protección del antivirus restaurada."
            fr = "Protection antivirus restaurée."
            ar = "تمت استعادة حماية مكافحة الفيروسات."
            ru = "Защита антивируса восстановлена."
        }
        "bd_suspend_failed" = @{
            en = "Could not pause automatically. Please follow the instructions:"
            zh = "无法自动暂停。 请按照说明操作:"
            hi = "स्वतः नहीं रुक सका। कृपया निर्देशों का पालन करें:"
            es = "No se pudo pausar automáticamente. Siga las instrucciones:"
            fr = "Impossible de mettre en pause automatiquement. Veuillez suivre les instructions :"
            ar = "تعذر الإيقاف تلقائياً. يرجى اتباع الإرشادات:"
            ru = "Не удалось приостановить автоматически. Следуйте инструкциям:"
        }
        "bd_onaccess_title" = @{
            en = "BITDEFENDER - RECOMMENDED: ADD EXCLUSION FOR EXTRA SAFETY"
            zh = "BITDEFENDER - 建议: 添加排除项以确保安全"
            hi = "BITDEFENDER - सिफारिश: अतिरिक्त सुरक्षा के लिए अपवाद जोड़ें"
            es = "BITDEFENDER - RECOMENDADO: AÑADA EXCLUSIÓN PARA MAYOR SEGURIDAD"
            fr = "BITDEFENDER - RECOMMANDÉ : AJOUTEZ UNE EXCLUSION POUR PLUS DE SÉCURITÉ"
            ar = "BITDEFENDER - موصى به: أضف استثناء لمزيد من الأمان"
            ru = "BITDEFENDER - РЕКОМЕНДУЕТСЯ: ДОБАВЬТЕ ИСКЛЮЧЕНИЕ ДЛЯ ДОПОЛНИТЕЛЬНОЙ БЕЗОПАСНОСТИ"
        }
        "bd_onaccess_reason" = @{
            en = "Bitdefender Free MAY block the mod files in the future."
            zh = "Bitdefender Free 可能会在将来阻止模组文件。"
            hi = "Bitdefender Free भविष्य में मॉड फ़ाइलों को अवरुद्ध कर सकता है।"
            es = "Bitdefender Free PUEDE bloquear los archivos del mod en el futuro."
            fr = "Bitdefender Free PEUT bloquer les fichiers de mod à l'avenir."
            ar = "قد يقوم Bitdefender Free بحظر ملفات التعديل في المستقبل."
            ru = "Bitdefender Free МОЖЕТ заблокировать файлы мода в будущем."
        }
        "bd_onaccess_cannot_autofix" = @{
            en = "Adding the exclusion prevents Bitdefender from interfering later."
            zh = "添加排除项可防止 Bitdefender 以后干扰。"
            hi = "अपवाद जोड़ने से Bitdefender को बाद में हस्तक्षेप करने से रोका जाता है।"
            es = "Añadir la exclusión evita que Bitdefender interfiera más adelante."
            fr = "L'ajout de l'exclusion empêche Bitdefender d'interférer plus tard."
            ar = "إضافة الاستثناء تمنع Bitdefender من التدخل لاحقاً."
            ru = "Добавление исключения предотвращает вмешательство Bitdefender в дальнейшем."
        }
        "bd_onaccess_clipboard" = @{
            en = ">> Path COPIED to clipboard - just press Ctrl+V in Bitdefender!"
            zh = ">> 路径已复制到剪贴板 - 在 Bitdefender 中按 Ctrl+V 即可!"
            hi = ">> पथ क्लिपबोर्ड पर कॉपी किया गया - Bitdefender में बस Ctrl+V दबाएँ!"
            es = ">> Ruta COPIADA al portapapeles - ¡simplemente pulse Ctrl+V en Bitdefender!"
            fr = ">> Chemin COPIÉ dans le presse-papier - appuyez simplement sur Ctrl+V dans Bitdefender !"
            ar = ">> تم نسخ المسار إلى الحافظة - فقط اضغط Ctrl+V في Bitdefender!"
            ru = ">> Путь СКОПИРОВАН в буфер обмена - просто нажмите Ctrl+V в Bitdefender!"
        }
        "bd_onaccess_wait" = @{
            en = "After adding the exclusion in Bitdefender, press ENTER here to continue..."
            zh = "在 Bitdefender 中添加排除项后,在此处按 ENTER 键继续..."
            hi = "Bitdefender में अपवाद जोड़ने के बाद, यहाँ जारी रखने के लिए ENTER दबाएँ..."
            es = "Después de añadir la exclusión en Bitdefender, pulse ENTER aquí para continuar..."
            fr = "Après avoir ajouté l'exclusion dans Bitdefender, appuyez sur ENTRÉE ici pour continuer..."
            ar = "بعد إضافة الاستثناء في Bitdefender، اضغط ENTER هنا للمتابعة..."
            ru = "После добавления исключения в Bitdefender нажмите ВВОД здесь для продолжения..."
        }
        "bd_onaccess_verified" = @{
            en = "Exclusion confirmed in Bitdefender! Minecraft will work correctly now."
            zh = "已在 Bitdefender 中确认排除项! Minecraft 现在将正常工作。"
            hi = "Bitdefender में अपवाद पुष्ट! Minecraft अब सही से काम करेगा।"
            es = "¡Exclusión confirmada en Bitdefender! Minecraft funcionará correctamente ahora."
            fr = "Exclusion confirmée dans Bitdefender ! Minecraft fonctionnera correctement maintenant."
            ar = "تم تأكيد الاستثناء في Bitdefender! سيعمل Minecraft بشكل صحيح الآن."
            ru = "Исключение подтверждено в Bitdefender! Minecraft теперь будет работать правильно."
        }
        "bd_onaccess_not_detected" = @{
            en = "Exclusion NOT detected yet. Please follow the steps again."
            zh = "尚未检测到排除项。 请再次按照步骤操作。"
            hi = "अपवाद अभी तक नहीं मिला। कृपया फिर से चरणों का पालन करें।"
            es = "Exclusión aún NO detectada. Siga los pasos de nuevo."
            fr = "Exclusion NON détectée pour le moment. Veuillez suivre à nouveau les étapes."
            ar = "لم يتم اكتشاف الاستثناء بعد. يرجى اتباع الخطوات مرة أخرى."
            ru = "Исключение пока НЕ обнаружено. Пожалуйста, повторите шаги."
        }
        "bd_onaccess_skipped" = @{
            en = "Exclusion not configured. If Minecraft has issues later, see TROUBLESHOOTING.md."
            zh = "未配置排除项。 如果以后 Minecraft 出现问题,请参阅 TROUBLESHOOTING.md。"
            hi = "अपवाद कॉन्फ़िगर नहीं किया गया। यदि Minecraft में बाद में समस्याएँ हों, तो TROUBLESHOOTING.md देखें।"
            es = "Exclusión no configurada. Si Minecraft tiene problemas más tarde, consulte TROUBLESHOOTING.md."
            fr = "Exclusion non configurée. Si Minecraft a des problèmes plus tard, consultez TROUBLESHOOTING.md."
            ar = "لم يتم تكوين الاستثناء. إذا واجه Minecraft مشاكل لاحقاً، راجع TROUBLESHOOTING.md."
            ru = "Исключение не настроено. Если у Minecraft возникнут проблемы позже, см. TROUBLESHOOTING.md."
        }
        "bd_onaccess_attempt" = @{
            en = "Attempt"
            zh = "尝试"
            hi = "प्रयास"
            es = "Intento"
            fr = "Tentative"
            ar = "محاولة"
            ru = "Попытка"
        }
    }
    
    $ptOverrides = @{
        'admin_required' = 'Privilegios de Administrador necessarios!'
        'admin_elevating' = 'Solicitando elevacao...'
        'admin_ok' = 'Executando com privilegios de Administrador'
        'menu_title' = 'Opcoes disponiveis'
        'menu_1' = 'Instalar mod (desbloquear jogo)'
        'menu_2' = 'Restaurar original (voltar para Trial)'
        'menu_3' = 'Abrir Minecraft'
        'menu_4' = 'Instalar Minecraft (Xbox App)'
        'menu_5' = 'Verificar status'
        'menu_6' = 'Diagnostico do sistema'
        'menu_0' = 'Sair'
        'choose' = 'Escolha uma opcao'
        'invalid' = 'Opcao invalida!'
        'mc_not_found' = 'Minecraft NAO ENCONTRADO!'
        'mc_found' = 'Minecraft encontrado'
        'mc_path' = 'Caminho'
        'installing' = 'Instalando bypass...'
        'adding_exclusions' = 'Adicionando exclusoes no antivirus...'
        'exclusion_added' = 'Exclusao adicionada no Windows Defender'
        'exclusion_failed' = 'Nao foi possivel adicionar a exclusao (pode exigir configuracao manual)'
        'downloading' = 'Baixando'
        'download_ok' = 'Baixado com sucesso'
        'download_fail' = 'Download FALHOU'
        'hash_ok' = 'Integridade verificada'
        'hash_fail' = 'FALHA NA VERIFICACAO DE INTEGRIDADE! O arquivo pode estar corrompido.'
        'install_ok' = 'Bypass instalado com sucesso!'
        'install_fail' = 'Instalacao falhou'
        'verifying' = 'Verificando instalacao...'
        'files_ok' = 'Todos os arquivos presentes e verificados!'
        'files_missing' = 'OS ARQUIVOS FORAM APAGADOS PELO ANTIVIRUS!'
        'retry_install' = 'Tentando instalar novamente...'
        'av_disable' = 'DESATIVE TEMPORARIAMENTE O SEU ANTIVIRUS:'
        'av_step1' = '1. Abra a Seguranca do Windows'
        'av_step2' = '2. Va em Protecao contra virus e ameacas'
        'av_step3' = '3. Clique em Gerenciar configuracoes'
        'av_step4' = '4. Desative a Protecao em tempo real'
        'av_step5' = '5. Execute este script novamente'
        'av_folder' = 'OU adicione esta pasta nas exclusoes:'
        'av_detected_blocking' = 'Seu antivirus APAGOU o arquivo apos o download!'
        'av_need_disable' = 'Voce precisa DESATIVAR TEMPORARIAMENTE a protecao do antivirus.'
        'av_press_enter' = 'Depois de desativar o antivirus, pressione ENTER para continuar...'
        'av_retrying_after_disable' = 'Tentando baixar novamente (o antivirus deve estar desativado agora)...'
        'av_still_blocking' = 'Os arquivos AINDA estao sendo bloqueados! Verifique se o antivirus esta totalmente desativado.'
        'av_reenable' = 'Voce ja pode reativar a protecao do antivirus.'
        'removing' = 'Removendo arquivos do bypass...'
        'removed_ok' = 'Bypass removido com sucesso! O jogo voltou para Trial.'
        'resetting_license' = 'Redefinindo cache de licenca da Windows Store / Gaming Services...'
        'license_reset_partial' = 'Nao foi possivel redefinir totalmente o cache de licenca. Talvez seja necessario reiniciar o PC.'
        'restore_reopen_note' = 'IMPORTANTE: Abra o Minecraft novamente para verificar se voltou ao modo Trial. Se ainda aparecer como Pago, reinicie o PC.'
        'resetting_app' = 'Redefinindo dados do app Minecraft (limpando cache de licenca)...'
        'app_reset_ok' = 'Dados do app Minecraft redefinidos com sucesso! Cache de licenca limpo.'
        'app_reset_fallback' = 'Reset-AppxPackage indisponivel. Tentando limpeza manual...'
        'app_data_cleared' = 'Dados do app Minecraft limpos manualmente.'
        'reregistering_mc' = 'Registrando novamente o pacote do Minecraft (forcar revalidacao de licenca)...'
        'reregister_ok' = 'Pacote do Minecraft registrado novamente com sucesso.'
        'clearing_app_cache' = 'Limpando cache e configuracoes do app Minecraft...'
        'cache_cleared' = 'Cache e configuracoes do app limpos.'
        'opening_mc' = 'Abrindo Minecraft...'
        'mc_opened' = 'Minecraft deve abrir em instantes'
        'opening_xbox' = 'Abrindo Xbox App / pagina do Minecraft...'
        'status_title' = 'STATUS DO SISTEMA'
        'status_mc' = 'Minecraft instalado'
        'status_type' = 'Tipo de instalacao'
        'status_xbox' = 'Xbox App (GDK) - Compativel'
        'status_store' = 'Microsoft Store (UWP) - NAO COMPATIVEL!'
        'status_bypass' = 'Status do bypass'
        'status_installed' = 'INSTALADO'
        'status_not_installed' = 'NAO INSTALADO'
        'status_partial' = 'PARCIAL (arquivos ausentes - antivirus apagou?)'
        'status_av' = 'Antivirus'
        'status_defender_on' = 'Ativo'
        'status_defender_off' = 'Nao detectado'
        'persistence_ok' = 'Protecao apos reinicio ativada (arquivos restauram automaticamente)'
        'persistence_fail' = 'Nao foi possivel ativar protecao apos reinicio (falha na Tarefa Agendada)'
        'persistence_removed' = 'Protecao apos reinicio removida'
        'status_persistence' = 'Protecao apos reinicio'
        'status_gaming' = 'Gaming Services'
        'status_running' = 'Em execucao'
        'status_stopped' = 'Parado'
        'diag_title' = 'DIAGNOSTICO DO SISTEMA'
        'diag_xbox_app' = 'Xbox App'
        'diag_mc_install' = 'Instalacao do Minecraft'
        'diag_type' = 'Tipo de instalacao'
        'diag_permissions' = 'Permissoes da pasta'
        'diag_gaming' = 'Gaming Services'
        'diag_integrity' = 'Integridade do jogo'
        'diag_bypass' = 'Arquivos do bypass'
        'diag_all_ok' = 'Todas as verificacoes passaram! O sistema esta pronto.'
        'yes' = 'Sim'
        'no' = 'Nao'
        'ok' = 'OK'
        'found' = 'Encontrado'
        'not_found' = 'Nao encontrado'
        'writable' = 'Gravavel'
        'no_write' = 'Sem permissao de escrita'
        'open_now' = 'Agora voce pode abrir o Minecraft pelo Menu Iniciar!'
        'mc_running' = 'Minecraft esta em execucao. Fechando primeiro...'
        'press_enter' = 'Pressione Enter para continuar...'
        'exiting' = 'Saindo...'
        'start_gaming' = 'Iniciando Gaming Services...'
        'install_xbox_hint' = 'Instale o Minecraft Trial pelo Xbox App (NAO pela Microsoft Store!)'
        'repair_hint' = 'Repare ou reinstale o Minecraft pelo Xbox App'
        'run_admin_hint' = 'Execute este script como Administrador'
        'restart_gaming_hint' = 'Reinicie o Gaming Services ou reinstale o Xbox App'
        'bd_suspending' = 'Antivirus detectado - tentando pausar a protecao automaticamente...'
        'bd_suspended' = 'Antivirus pausado! Instalando arquivos agora...'
        'bd_resumed' = 'Protecao do antivirus restaurada.'
        'bd_suspend_failed' = 'Nao foi possivel pausar automaticamente. Siga as instrucoes:'
        'bd_onaccess_title' = 'BITDEFENDER - RECOMENDADO: ADICIONE EXCLUSAO PARA MAIOR SEGURANCA'
        'bd_onaccess_reason' = 'O Bitdefender Free PODE bloquear os arquivos do mod no futuro.'
        'bd_onaccess_cannot_autofix' = 'Adicionar a exclusao impede que o Bitdefender interfira depois.'
        'bd_onaccess_clipboard' = '>> Caminho COPIADO para a area de transferencia - pressione Ctrl+V no Bitdefender!'
        'bd_onaccess_wait' = 'Depois de adicionar a exclusao no Bitdefender, pressione ENTER aqui para continuar...'
        'bd_onaccess_verified' = 'Exclusao confirmada no Bitdefender! O Minecraft deve funcionar corretamente agora.'
        'bd_onaccess_not_detected' = 'Exclusao ainda NAO detectada. Siga os passos novamente.'
        'bd_onaccess_skipped' = 'Exclusao nao configurada. Se o Minecraft tiver problemas depois, veja TROUBLESHOOTING.md.'
        'bd_onaccess_attempt' = 'Tentativa'
    }
    if ($Script:Lang -eq 'pt' -and $ptOverrides.ContainsKey($Key)) {
        return $ptOverrides[$Key]
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
# Console Appearance
# ============================================================================

function Set-ConsoleAppearance {
    try {
        $Host.UI.RawUI.BackgroundColor = 'Black'
        $Host.UI.RawUI.ForegroundColor = 'Gray'
        $Host.UI.RawUI.WindowTitle = "Minecraft Bedrock Unlocker v$Script:Version"

        # Detect screen resolution to size window proportionally
        $screenW = 1920
        $screenH = 1080
        try {
            Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
            $screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
            $screenW = $screen.Width
            $screenH = $screen.Height
        } catch { }

        # Estimate console columns/rows from screen pixels
        # Typical conhost char: ~8x16px. Target ~85% of screen width, ~80% height.
        $targetWidth  = [Math]::Max(80,  [Math]::Min(130, [int]($screenW * 0.85 / 8)))
        $targetHeight = [Math]::Max(28,  [Math]::Min(50,  [int]($screenH * 0.80 / 16)))

        $maxSize = $Host.UI.RawUI.MaxPhysicalWindowSize
        $w = [Math]::Min($targetWidth,  $maxSize.Width)
        $h = [Math]::Min($targetHeight, $maxSize.Height)

        $curBuf = $Host.UI.RawUI.BufferSize
        $newBuf = New-Object System.Management.Automation.Host.Size($w, 1000)
        $newWin = New-Object System.Management.Automation.Host.Size($w, $h)

        if ($curBuf.Width -gt $w) {
            $Host.UI.RawUI.WindowSize = $newWin
            $Host.UI.RawUI.BufferSize = $newBuf
        } else {
            $Host.UI.RawUI.BufferSize = $newBuf
            $Host.UI.RawUI.WindowSize = $newWin
        }

        # Center window on screen
        try {
            Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
            $charW = 8; $charH = 16
            $winPixW = $w * $charW
            $winPixH = $h * $charH
            $posX = [Math]::Max(0, [int](($screenW - $winPixW) / 2))
            $posY = [Math]::Max(0, [int](($screenH - $winPixH) / 2))
            $Host.UI.RawUI.WindowPosition = New-Object System.Management.Automation.Host.Coordinates($posX / $charW, 0)
        } catch { }

        Clear-Host
    } catch {
        try { Clear-Host } catch { }
    }
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
    Write-C "    $(T 'menu_title')" Green
    Write-C ""
    Write-C "    " -NoNewline; Write-C "[1]" Green -NoNewline; Write-C " $(T 'menu_1')"
    Write-C "    " -NoNewline; Write-C "[2]" Green -NoNewline; Write-C " $(T 'menu_2')"
    Write-C "    " -NoNewline; Write-C "[3]" Green -NoNewline; Write-C " $(T 'menu_3')"
    Write-C "    " -NoNewline; Write-C "[4]" Yellow -NoNewline; Write-C " $(T 'menu_4')"
    Write-C "    " -NoNewline; Write-C "[5]" Cyan -NoNewline; Write-C " $(T 'menu_5')"
    Write-C "    " -NoNewline; Write-C "[6]" Cyan -NoNewline; Write-C " $(T 'menu_6')"
    Write-C "    " -NoNewline; Write-C "[0]" Red -NoNewline; Write-C " $(T 'menu_0')"
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

    $ps = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
    if (-not (Test-Path $ps)) { $ps = 'powershell.exe' }

    try {
        # ── Branch A: script was launched as a .ps1 file ──────────────────
        $localScriptPath = $null
        if ($PSCommandPath -and (Test-Path $PSCommandPath)) {
            $localScriptPath = $PSCommandPath
        } elseif ($MyInvocation.MyCommand.Path -and (Test-Path $MyInvocation.MyCommand.Path)) {
            $localScriptPath = $MyInvocation.MyCommand.Path
        }

        if ($localScriptPath) {
            $extraArgs = if ($Script:IsSelfContained) { @('-ResourceDir', $Script:ResourceDir) } else { @() }
            Start-Process $ps -ArgumentList (@('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$localScriptPath`"") + $extraArgs) -Verb RunAs
            Write-OK "Elevated window opened. This window will close..."
            Start-Sleep -Seconds 1
            exit
        }

        # ── Branch B: running via irm|iex (no file on disk) ───────────────
        # Use already-downloaded content stored by e.ps1 ($Script:MBUContent).
        # If not available, fall back to a fresh download.
        $scriptContent = $null
        if (-not [string]::IsNullOrWhiteSpace($Script:MBUContent) -and
            $Script:MBUContent -match 'Start-MainLoop') {
            $scriptContent = $Script:MBUContent
        } else {
            $headers = Get-NoCacheHeaders
            foreach ($dlUrl in @((New-CacheBustedUrl $Script:RawScriptUrl),
                                  (New-CacheBustedUrl "$Script:BaseUrl/unlocker.ps1"))) {
                try {
                    $r = Invoke-RestMethod -UseBasicParsing -Headers $headers -Uri $dlUrl `
                                          -MaximumRedirection 5 -ErrorAction Stop
                    $r = [string]$r
                    if (-not [string]::IsNullOrWhiteSpace($r) -and $r -match 'Start-MainLoop') {
                        $scriptContent = $r; break
                    }
                } catch { }
            }
        }

        if ([string]::IsNullOrWhiteSpace($scriptContent)) {
            throw 'Could not obtain script content for elevation (no cached copy and download failed).'
        }

        $tempScript = Join-Path ([System.IO.Path]::GetTempPath()) `
                                 "mbu_elevated_$([guid]::NewGuid().ToString('N')).ps1"
        [System.IO.File]::WriteAllText($tempScript, [string]$scriptContent, (New-Object System.Text.UTF8Encoding $true))
        Start-Process $ps -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$tempScript`"") -Verb RunAs
        Write-OK "Elevated window opened. This window will close..."
        Start-Sleep -Seconds 1
        exit
    }
    catch {
        Write-Err "Failed to elevate. Please run PowerShell as Administrator."
        Write-Warn "  Right-click PowerShell -> Run as administrator"
        Wait-Enter
    }
}
function Find-MinecraftPath {
    # Priority 0: explicit -MinecraftPath param (issue #23)
    if ($MinecraftPath) {
        $p = $MinecraftPath.Trim('"').Trim("'")
        if (Test-Path -LiteralPath $p) { return $p }
        # if user passed the parent (Minecraft for Windows) instead of Content, descend
        $child = Join-Path $p 'Content'
        if (Test-Path -LiteralPath $child) { return $child }
        Write-Warn "MinecraftPath argument '$p' not found; falling back to auto-detection."
    }

    # Priority 1: known XboxGames path on all drives (GDK install - compatible)
    $drives = @("C") + @((Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[D-Z]:\\$' }).Name)
    foreach ($driveLetter in $drives) {
        $path = "${driveLetter}:\XboxGames\Minecraft for Windows\Content"
        if (Test-Path $path) { return $path }
    }

    # Priority 2: custom Xbox App library folders under XboxGames
    foreach ($driveLetter in $drives) {
        $xboxRoot = "${driveLetter}:\XboxGames"
        if (-not (Test-Path $xboxRoot)) { continue }
        try {
            $contentDirs = Get-ChildItem -Path $xboxRoot -Directory -ErrorAction SilentlyContinue |
                ForEach-Object { Join-Path $_.FullName 'Content' } |
                Where-Object { Test-Path $_ }
            foreach ($contentPath in $contentDirs) {
                $exePath = Join-Path $contentPath 'Minecraft.Windows.exe'
                $manifestPath = Join-Path $contentPath 'appxmanifest.xml'
                if ((Test-Path $exePath) -or (Test-Path $manifestPath)) { return $contentPath }
            }
        } catch { }
    }

    # Priority 3: UWP / Microsoft Store install - resolve via Get-AppxPackage.
    # InstallLocation works regardless of drive (issue #23: install on F: instead of C:).
    try {
        $pkg = Get-AppxPackage -Name 'MICROSOFT.MINECRAFTUWP' -ErrorAction SilentlyContinue
        if ($pkg -and $pkg.InstallLocation) {
            $contentPath = Join-Path $pkg.InstallLocation 'Content'
            if (Test-Path -LiteralPath $contentPath) { return $contentPath }
            # fallback: InstallLocation itself sometimes IS the Content folder
            if (Test-Path -LiteralPath (Join-Path $pkg.InstallLocation 'Minecraft.Windows.exe')) { return $pkg.InstallLocation }
        }
    } catch { }

    # Priority 4: legacy WindowsApps scan under any ProgramFiles drive (kept for parity)
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

    # Priority 5: interactive fallback - ask the user to paste the Content folder
    if (-not $Script:Headless) {
        Write-Host ''
        Write-Host '  Minecraft was not found automatically.' -ForegroundColor Yellow
        Write-Host '  Please paste the full path to your Minecraft "Content" folder.' -ForegroundColor Yellow
        Write-Host '  Example: F:\XboxGames\Minecraft for Windows\Content' -ForegroundColor Gray
        for ($i = 0; $i -lt 3; $i++) {
            $typed = Read-Host '  Content path (or press Enter to give up)'
            if ([string]::IsNullOrWhiteSpace($typed)) { break }
            $typed = $typed.Trim('"').Trim("'")
            if (Test-Path -LiteralPath $typed) { return $typed }
            $child = Join-Path $typed 'Content'
            if (Test-Path -LiteralPath $child) { return $child }
            Write-Warn "Path '$typed' does not exist. Try again."
        }
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

# ============================================================================
# Antivirus Detection & Management (Multi-AV Support)
# ============================================================================

function Detect-Antivirus {
    <#
    .DESCRIPTION
        Detects ALL installed/active antivirus products on the system.
        Returns an array of hashtables with Name, Type, Active status.
    #>
    $detected = @()
    
    # Method 1: WMI/CIM (works for most registered AV products)
    try {
        $avProducts = Get-CimInstance -Namespace "root/SecurityCenter2" -ClassName "AntiVirusProduct" -ErrorAction SilentlyContinue
        foreach ($av in $avProducts) {
            $name = $av.displayName
            $state = $av.productState
            # Bit 12 (4096) = enabled/active
            $isActive = (($state -band 0x1000) -ne 0)
            
            $type = "unknown"
            if ($name -match "Bitdefender") {
                if ($name -match "Antivirus Free" -or (Test-Path "HKLM:\SOFTWARE\Bitdefender\Bitdefender Antivirus Free")) {
                    $type = "bitdefender_free"
                } else {
                    $type = "bitdefender"
                }
            }
            elseif ($name -match "Kaspersky")  { $type = "kaspersky" }
            elseif ($name -match "Avast")      { $type = "avast" }
            elseif ($name -match "AVG")        { $type = "avg" }
            elseif ($name -match "Norton")     { $type = "norton" }
            elseif ($name -match "McAfee")     { $type = "mcafee" }
            elseif ($name -match "ESET")       { $type = "eset" }
            elseif ($name -match "Malwarebytes") { $type = "malwarebytes" }
            elseif ($name -match "Defender")   { $type = "defender" }
            elseif ($name -match "Trend.?Micro") { $type = "trendmicro" }
            
            $detected += @{ Name = $name; Type = $type; Active = $isActive }
        }
    } catch { }
    
    # Method 2: Fallback path-based detection if WMI returns nothing useful
    if ($detected.Count -eq 0) {
        $bdType = if (Test-Path "HKLM:\SOFTWARE\Bitdefender\Bitdefender Antivirus Free") { "bitdefender_free" } else { "bitdefender" }
        $pathChecks = @(
            @{ Path = "$env:ProgramFiles\Bitdefender*"; Type = $bdType; Name = "Bitdefender" },
            @{ Path = "${env:ProgramFiles(x86)}\Bitdefender*"; Type = $bdType; Name = "Bitdefender" },
            @{ Path = "$env:ProgramFiles\Kaspersky Lab*"; Type = "kaspersky"; Name = "Kaspersky" },
            @{ Path = "$env:ProgramFiles\Avast Software*"; Type = "avast"; Name = "Avast" },
            @{ Path = "$env:ProgramFiles\AVG*"; Type = "avg"; Name = "AVG" },
            @{ Path = "$env:ProgramFiles\Norton*"; Type = "norton"; Name = "Norton" },
            @{ Path = "$env:ProgramFiles\McAfee*"; Type = "mcafee"; Name = "McAfee" },
            @{ Path = "$env:ProgramFiles\ESET*"; Type = "eset"; Name = "ESET" },
            @{ Path = "$env:ProgramFiles\Malwarebytes*"; Type = "malwarebytes"; Name = "Malwarebytes" }
        )
        foreach ($check in $pathChecks) {
            if (Get-Item $check.Path -ErrorAction SilentlyContinue) {
                $detected += @{ Name = $check.Name; Type = $check.Type; Active = $true }
            }
        }
        # Always check Defender separately
        if (Test-DefenderActive) {
            $detected += @{ Name = "Windows Defender"; Type = "defender"; Active = $true }
        }
    }
    
    return $detected
}

function Get-AVExclusionInstructions {
    param([string]$AVType, [string]$AVName, [string]$FolderPath)
    
    $lang = $Script:Lang
    
    switch ($AVType) {
        "bitdefender_free" {
            if ($lang -eq "pt") {
                return @(
                    "=== BITDEFENDER FREE - EXCECAO OBRIGATORIA ==="
                    ""
                    "  ATENCAO: Desativar o Shield NAO resolve o problema!"
                    "  O Bitdefender bloqueia os arquivos ao CARREGAR (durante o jogo)."
                    "  Voce PRECISA adicionar a pasta como EXCECAO permanente."
                    ""
                    "  PASSO A PASSO (o Bitdefender ja esta aberto):"
                    "  1. Na janela do Bitdefender, clique em 'Protecao' (icone de escudo no menu lateral)"
                    "  2. Clique em 'Antivirus'"
                    "  3. Clique na aba 'Configuracoes' (icone de engrenagem)"
                    "  4. Role para baixo e clique em 'Gerenciar Excecoes'"
                    "  5. Clique em '+ Adicionar uma Excecao'"
                    "  6. COLE (Ctrl+V) o caminho - ja foi copiado automaticamente:"
                    "     ===> $FolderPath"
                    "  7. MARQUE TODAS as opcoes (Verificacao em tempo real, Sob demanda, ATD)"
                    "  8. Clique em 'Salvar'"
                    "  9. Volte aqui e pressione ENTER"
                )
            } else {
                return @(
                    "=== BITDEFENDER FREE - MANDATORY EXCLUSION ==="
                    ""
                    "  WARNING: Disabling the Shield does NOT fix this!"
                    "  Bitdefender blocks files at LOAD TIME (while the game runs)."
                    "  You MUST add the folder as a permanent EXCLUSION."
                    ""
                    "  STEP BY STEP (Bitdefender is already open):"
                    "  1. In the Bitdefender window, click 'Protection' (shield icon in left menu)"
                    "  2. Click 'Antivirus'"
                    "  3. Click the 'Settings' tab (gear icon)"
                    "  4. Scroll down and click 'Manage Exceptions'"
                    "  5. Click '+ Add an Exception'"
                    "  6. PASTE (Ctrl+V) the path - already copied automatically:"
                    "     ===> $FolderPath"
                    "  7. CHECK ALL options (On-access scan, On-demand scan, ATC)"
                    "  8. Click 'Save'"
                    "  9. Come back here and press ENTER"
                )
            }
        }
        "bitdefender" {
            if ($lang -eq "pt") {
                return @(
                    "=== SEU ANTIVIRUS - Instrucoes para adicionar exclusao ==="
                    ""
                    "METODO RAPIDO (Recomendado):"
                    "  1. Clique no icone do seu antivirus na bandeja do sistema (ao lado do relogio)"
                    "  2. Clique em 'Protecao' (icone de escudo)"
                    "  3. Em 'Antivirus', clique em 'Configuracoes'"
                    "  4. Va em 'Gerenciar Exclusoes' ou 'Exclusoes'"
                    "  5. Clique em 'Adicionar' > 'Pasta'"
                    "  6. Selecione: $FolderPath"
                    "  7. Marque TODAS as opcoes (On-Access, On-Demand, etc.)"
                    "  8. Clique em 'Salvar' e execute este script novamente"
                    ""
                    "METODO ALTERNATIVO (Desativar temporariamente):"
                    "  1. Clique no icone do seu antivirus na bandeja"
                    "  2. Va em 'Protecao' > 'Antivirus'"
                    "  3. Desative o 'Shield' (protecao em tempo real) por 15 minutos"
                    "  4. Execute este script novamente"
                    "  5. Reative seu antivirus depois"
                )
            } else {
                return @(
                    "=== YOUR ANTIVIRUS - How to add exclusion ==="
                    ""
                    "QUICK METHOD (Recommended):"
                    "  1. Click your antivirus icon in the system tray (near clock)"
                    "  2. Click 'Protection' (shield icon)"
                    "  3. Under 'Antivirus', click 'Settings'"
                    "  4. Go to 'Manage Exclusions' or 'Exclusions'"
                    "  5. Click 'Add' > 'Folder'"
                    "  6. Select: $FolderPath"
                    "  7. Check ALL options (On-Access, On-Demand, etc.)"
                    "  8. Click 'Save' and run this script again"
                    ""
                    "ALTERNATIVE (Temporarily disable):"
                    "  1. Click your antivirus tray icon"
                    "  2. Go to 'Protection' > 'Antivirus'"
                    "  3. Disable 'Shield' (real-time protection) for 15 minutes"
                    "  4. Run this script again"
                    "  5. Re-enable your antivirus afterward"
                )
            }
        }
        "kaspersky" {
            if ($lang -eq "pt") {
                return @(
                    "=== SEU ANTIVIRUS ==="
                    "  1. Abra seu antivirus"
                    "  2. Configuracoes > Ameacas e Exclusoes"
                    "  3. Gerenciar Exclusoes > Adicionar"
                    "  4. Adicione: $FolderPath"
                )
            } else {
                return @(
                    "=== YOUR ANTIVIRUS ==="
                    "  1. Open your antivirus"
                    "  2. Settings > Threats and Exclusions"
                    "  3. Manage Exclusions > Add"
                    "  4. Add: $FolderPath"
                )
            }
        }
        "avast" {
            return @(
                "=== YOUR ANTIVIRUS ==="
                "  Settings > General > Exceptions > Add Exception"
                "  Add: $FolderPath"
            )
        }
        "avg" {
            return @(
                "=== YOUR ANTIVIRUS ==="
                "  Menu > Settings > General > Exceptions > Add Exception"
                "  Add: $FolderPath"
            )
        }
        "norton" {
            return @(
                "=== YOUR ANTIVIRUS ==="
                "  Settings > Antivirus > Scans and Risks > Items to Exclude"
                "  Add: $FolderPath"
            )
        }
        "eset" {
            return @(
                "=== YOUR ANTIVIRUS ==="
                "  Setup > Advanced Setup > Detection Engine > Exclusions"
                "  Add: $FolderPath"
            )
        }
        "mcafee" {
            return @(
                "=== YOUR ANTIVIRUS ==="
                "  PC Security > Real-Time Scanning > Excluded Files"
                "  Add: $FolderPath"
            )
        }
        "defender" {
            if ($lang -eq "pt") {
                return @(
                    "=== SEU ANTIVIRUS ==="
                    "  1. Abra 'Seguranca do Windows'"
                    "  2. Protecao contra virus e ameacas"
                    "  3. Gerenciar configuracoes"
                    "  4. Exclusoes > Adicionar exclusao > Pasta"
                    "  5. Selecione: $FolderPath"
                )
            } else {
                return @(
                    "=== YOUR ANTIVIRUS ==="
                    "  1. Open 'Windows Security'"
                    "  2. Virus & threat protection"
                    "  3. Manage settings"
                    "  4. Exclusions > Add exclusion > Folder"
                    "  5. Select: $FolderPath"
                )
            }
        }
        default {
            if ($lang -eq "pt") {
                return @(
                    "=== SEU ANTIVIRUS ==="
                    "  Procure por 'Exclusoes' ou 'Excecoes' nas configuracoes"
                    "  Adicione esta pasta: $FolderPath"
                )
            } else {
                return @(
                    "=== YOUR ANTIVIRUS ==="
                    "  Look for 'Exclusions' or 'Exceptions' in settings"
                    "  Add this folder: $FolderPath"
                )
            }
        }
    }
}

function Add-AllAVExclusions {
    param([string]$Path)
    
    Write-Info (T 'adding_exclusions')
    $avList = Detect-Antivirus
    $anyAdded = $false
    
    # Show detected antivirus products (only active ones)
    $activeAVs = @($avList | Where-Object { $_.Active })
    if ($activeAVs.Count -gt 0) {
        foreach ($av in $activeAVs) {
            Write-Info "  Antivirus: $($av.Name)"
        }
    } else {
        if ($Script:Lang -eq "pt") {
            Write-Info "  Nenhum antivirus detectado."
        } else {
            Write-Info "  No antivirus detected."
        }
    }
    
    foreach ($av in $avList) {
        # Skip inactive antivirus products entirely
        if (-not $av.Active) { continue }
        
        switch ($av.Type) {
            "defender" {
                try {
                    Add-MpPreference -ExclusionPath $Path -ErrorAction Stop
                    # Individual DLL exclusions
                    foreach ($dll in @("winmm.dll", (Get-DiskName -SourceName "OnlineFix64.dll"))) {
                        Add-MpPreference -ExclusionPath (Join-Path $Path $dll) -ErrorAction SilentlyContinue
                    }
                    Add-MpPreference -ExclusionProcess "Minecraft.Windows.exe" -ErrorAction SilentlyContinue
                    Write-OK "Windows Defender: $(T 'exclusion_added')"
                    $anyAdded = $true
                } catch {
                    # Defender not functional or not installed - skip silently
                }
            }
            "bitdefender_free" {
                # BD Free: Technique 5 handles file writing silently, no action needed here
            }
            "bitdefender" {
                $bdCmd = $null
                $bdPaths = @(
                    "$env:ProgramFiles\Bitdefender\Bitdefender Security\product.console.exe",
                    "$env:ProgramFiles\Bitdefender\Endpoint Security\product.console.exe",
                    "$env:ProgramFiles\Bitdefender Agent\ProductAgentService.exe"
                )
                foreach ($p in $bdPaths) {
                    if (Test-Path $p) { $bdCmd = $p; break }
                }
                if ($bdCmd) {
                    try {
                        & $bdCmd /c SetExclusion path="$Path" -ErrorAction SilentlyContinue
                        Write-OK "Bitdefender: $(T 'exclusion_added')"
                        $anyAdded = $true
                    } catch {
                        if ($Script:Lang -eq "pt") {
                            Write-Warn "Bitdefender: Nao foi possivel adicionar exclusao automaticamente."
                        } else {
                            Write-Warn "Bitdefender: Could not add exclusion automatically."
                        }
                    }
                } else {
                    if ($Script:Lang -eq "pt") {
                        Write-Warn "Bitdefender: Nao foi possivel adicionar exclusao automaticamente."
                    } else {
                        Write-Warn "Bitdefender: Could not add exclusion automatically."
                    }
                }
            }
            default {
                if ($av.Active) {
                    if ($Script:Lang -eq "pt") {
                        Write-Warn "$($av.Name): Nao foi possivel adicionar exclusao automaticamente."
                        Write-Warn "  Adicione esta pasta nas exclusoes do seu antivirus: $Path"
                    } else {
                        Write-Warn "$($av.Name): Could not add exclusion automatically."
                        Write-Warn "  Add this folder to your antivirus exclusions: $Path"
                    }
                }
            }
        }
    }
    
    return @{ AVList = $avList; AnyAdded = $anyAdded }
}

function Open-AVSettings {
    param([string]$AVType)
    
    switch ($AVType) {
        "bitdefender_free" {
            # Bitdefender Free UI is in 'Bitdefender Security App' folder
            $bdFreePaths = @(
                "$env:ProgramFiles\Bitdefender\Bitdefender Security App\bdagent.exe",
                "$env:ProgramFiles\Bitdefender\Bitdefender Security\bdagent.exe",
                "${env:ProgramFiles(x86)}\Bitdefender\Bitdefender Security App\bdagent.exe"
            )
            foreach ($p in $bdFreePaths) {
                if (Test-Path $p) {
                    try { Start-Process $p -ErrorAction SilentlyContinue; return $true } catch { }
                }
            }
            # Fallback: Start Menu shortcut
            try {
                $shortcut = Get-ChildItem "$env:ProgramData\Microsoft\Windows\Start Menu\Programs" -Recurse -Filter "*Bitdefender*" -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($shortcut) {
                    Start-Process $shortcut.FullName -ErrorAction SilentlyContinue
                    return $true
                }
            } catch { }
        }
        "bitdefender" {
            # Try to open Bitdefender UI
            $bdUIPaths = @(
                "$env:ProgramFiles\Bitdefender\Bitdefender Security\bdagent.exe",
                "$env:ProgramFiles\Bitdefender\Bitdefender Security\bdui.exe",
                "${env:ProgramFiles(x86)}\Bitdefender\Bitdefender Security\bdagent.exe"
            )
            foreach ($p in $bdUIPaths) {
                if (Test-Path $p) {
                    try { Start-Process $p -ErrorAction SilentlyContinue; return $true } catch { }
                }
            }
            # Try via Start Menu shortcut
            try {
                $shortcut = Get-ChildItem "$env:ProgramData\Microsoft\Windows\Start Menu\Programs" -Recurse -Filter "*Bitdefender*" -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($shortcut) {
                    Start-Process $shortcut.FullName -ErrorAction SilentlyContinue
                    return $true
                }
            } catch { }
        }
        "kaspersky" {
            try { Start-Process "avp.exe" -ErrorAction SilentlyContinue; return $true } catch { }
        }
        "avast" {
            $avastPath = "$env:ProgramFiles\Avast Software\Avast\AvastUI.exe"
            if (Test-Path $avastPath) {
                try { Start-Process $avastPath -ErrorAction SilentlyContinue; return $true } catch { }
            }
        }
        "avg" {
            $avgPath = "$env:ProgramFiles\AVG\Antivirus\AVGUI.exe"
            if (Test-Path $avgPath) {
                try { Start-Process $avgPath -ErrorAction SilentlyContinue; return $true } catch { }
            }
        }
        "defender" {
            try { Start-Process "windowsdefender://threatsettings" -ErrorAction SilentlyContinue; return $true } catch { }
        }
    }
    return $false
}

function Test-BDFreeExclusion {
    <#
    .DESCRIPTION
        Checks if the given path is listed in Bitdefender Free's ExcludeMgr settings.
        Returns $true if the exclusion exists with on-access flag (bit 0).
    #>
    param([string]$FolderPath)
    
    try {
        $settingsDir = Join-Path $env:ProgramData 'Bitdefender\Desktop\.settings\data'
        if (-not (Test-Path $settingsDir)) { return $false }
        
        $dataDir = Get-ChildItem $settingsDir -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne '00000000-0000-0000-0000-000000000000' } |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        
        if (-not $dataDir) { return $false }
        
        $dataFile = Join-Path $dataDir.FullName '.data'
        if (-not (Test-Path $dataFile)) { return $false }
        
        $json = [IO.File]::ReadAllText($dataFile)
        $settings = $json | ConvertFrom-Json
        
        $normalizedTarget = $FolderPath.ToLower().TrimEnd('\')
        
        foreach ($entry in $settings.settings.ExcludeMgr.Settings) {
            $normalizedEntry = $entry.path.ToLower().TrimEnd('\')
            # Check path matches with any exclusion type (on-access, on-demand, online threat, etc.)
            if ($normalizedEntry -eq $normalizedTarget) {
                return $true
            }
        }
        return $false
    } catch {
        return $false
    }
}

function Request-BDFreeOnAccessExclusion {
    <#
    .DESCRIPTION
        Guides the user to add a Bitdefender Free on-access exclusion,
        which is required for the mod DLLs to load at runtime.
        Opens BD UI, copies path to clipboard, shows instructions, verifies.
    #>
    param([string]$ContentPath)
    
    # Check if exclusion already exists
    if (Test-BDFreeExclusion -FolderPath $ContentPath) {
        Write-OK (T 'bd_onaccess_verified')
        return $true
    }
    
    Write-C ""
    Write-C "  ================================================================" Yellow
    Write-C "  $(T 'bd_onaccess_title')" Red
    Write-C "  ================================================================" Yellow
    Write-C ""
    Write-C "  $(T 'bd_onaccess_reason')" Yellow
    Write-C "  $(T 'bd_onaccess_cannot_autofix')" Yellow
    Write-C ""
    
    # Open BD UI
    $null = Open-AVSettings -AVType 'bitdefender_free'
    Start-Sleep -Seconds 2
    
    # Copy path to clipboard
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
        [System.Windows.Forms.Clipboard]::SetText($ContentPath)
        Write-OK (T 'bd_onaccess_clipboard')
    } catch { }
    
    Write-C ""
    
    # Show step-by-step instructions
    $instructions = Get-AVExclusionInstructions -AVType 'bitdefender_free' -AVName 'Bitdefender' -FolderPath $ContentPath
    foreach ($line in $instructions) {
        if ($line -match '^===') { Write-C "  $line" Cyan }
        elseif ($line -match '^\s*$') { Write-C "" }
        elseif ($line -match 'ATENCAO:|WARNING:|PRECISA|MUST') { Write-C "  $line" Red }
        elseif ($line -match '===>') { Write-C "  $line" Cyan }
        else { Write-C "  $line" Yellow }
    }
    Write-C ""
    
    # Wait for user and verify up to 3 times
    $maxAttempts = 3
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        Write-C "  >> $(T 'bd_onaccess_wait')" White
        Read-Host
        Write-C ""
        
        if (Test-BDFreeExclusion -FolderPath $ContentPath) {
            Write-OK (T 'bd_onaccess_verified')
            Write-C ""
            return $true
        } elseif ($attempt -lt $maxAttempts) {
            Write-Warn "$(T 'bd_onaccess_not_detected') ($(T 'bd_onaccess_attempt') $attempt/$maxAttempts)"
            Write-C ""
            Write-C "  ----------------------------------------------------------------" DarkGray
            if ($Script:Lang -eq 'pt') {
                Write-C "  Certifique-se de seguir TODOS os passos, especialmente:" Yellow
                Write-C "  - Clicar em '+ Adicionar uma Excecao' (nao apenas em 'Gerenciar Excecoes')" Yellow
                Write-C "  - Marcar TODAS as opcoes de verificacao" Yellow
                Write-C "  - Clicar em 'Salvar' ao final" Yellow
            } else {
                Write-C "  Make sure to follow ALL steps, especially:" Yellow
                Write-C "  - Click '+ Add an Exception' (not just 'Manage Exceptions')" Yellow
                Write-C "  - CHECK ALL scan options" Yellow
                Write-C "  - Click 'Save' at the end" Yellow
            }
            Write-C "  ----------------------------------------------------------------" DarkGray
            Write-C ""
        } else {
            Write-Warn (T 'bd_onaccess_not_detected')
            Write-C ""
            Write-Warn (T 'bd_onaccess_skipped')
            Write-C ""
            return $false
        }
    }
    return $false
}

function Try-BitdefenderExclusion {
    <#
    .DESCRIPTION
        Attempts to add a folder exclusion in Bitdefender via multiple methods.
        Returns $true if any method succeeded.
    #>
    param([string]$FolderPath)
    
    $success = $false
    
    # Method 1: Bitdefender product.console.exe CLI (paid versions)
    $bdConsolePaths = @(
        "$env:ProgramFiles\Bitdefender\Bitdefender Security\product.console.exe",
        "$env:ProgramFiles\Bitdefender\Endpoint Security\product.console.exe",
        "$env:ProgramFiles\Bitdefender Agent\product.console.exe",
        "${env:ProgramFiles(x86)}\Bitdefender\Bitdefender Security\product.console.exe"
    )
    foreach ($p in $bdConsolePaths) {
        if (Test-Path $p) {
            try {
                $proc = Start-Process -FilePath $p -ArgumentList "/c SetExclusion path=`"$FolderPath`"" -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
                if ($proc.ExitCode -eq 0) { $success = $true; break }
            } catch { }
            try {
                $proc = Start-Process -FilePath $p -ArgumentList "/c AddExclusion path=`"$FolderPath`"" -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
                if ($proc.ExitCode -eq 0) { $success = $true; break }
            } catch { }
        }
    }
    
    # Method 2: bduitool.exe
    if (-not $success) {
        $bduiPaths = @(
            "$env:ProgramFiles\Bitdefender\Bitdefender Security\bduitool.exe",
            "${env:ProgramFiles(x86)}\Bitdefender\Bitdefender Security\bduitool.exe"
        )
        foreach ($p in $bduiPaths) {
            if (Test-Path $p) {
                try {
                    & $p /addExclusion "$FolderPath" 2>$null
                    $success = $true; break
                } catch { }
            }
        }
    }
    
    # Method 3: Registry-based exclusion (works for some BD versions)
    if (-not $success) {
        $regPaths = @(
            "HKLM:\SOFTWARE\Bitdefender\Bitdefender Security\Antivirus\Exclusions\Paths",
            "HKLM:\SOFTWARE\Bitdefender\Bitdefender Antivirus\Antivirus\Exclusions\Paths",
            "HKLM:\SOFTWARE\Bitdefender\Bitdefender Antivirus Free\Antivirus\Exclusions\Paths"
        )
        foreach ($regPath in $regPaths) {
            try {
                if (-not (Test-Path $regPath)) {
                    New-Item -Path $regPath -Force -ErrorAction SilentlyContinue | Out-Null
                }
                Set-ItemProperty -Path $regPath -Name $FolderPath -Value 0 -Type DWord -ErrorAction Stop
                $success = $true; break
            } catch { }
        }
    }
    
    # Method 4: Try adding individual file exclusions via registry
    if (-not $success) {
        $fileRegPaths = @(
            "HKLM:\SOFTWARE\Bitdefender\Bitdefender Security\Antivirus\Exclusions\Extensions",
            "HKLM:\SOFTWARE\Bitdefender\Bitdefender Antivirus Free\Antivirus\Exclusions\Extensions"
        )
        foreach ($regPath in $fileRegPaths) {
            try {
                if (-not (Test-Path $regPath)) {
                    New-Item -Path $regPath -Force -ErrorAction SilentlyContinue | Out-Null
                }
                foreach ($dll in @("winmm.dll", (Get-DiskName -SourceName "OnlineFix64.dll"))) {
                    $fullPath = Join-Path $FolderPath $dll
                    Set-ItemProperty -Path $regPath -Name $fullPath -Value 0 -Type DWord -ErrorAction SilentlyContinue
                }
                $success = $true; break
            } catch { }
        }
    }
    
    return $success
}

function Suspend-Bitdefender {
    <#
    .DESCRIPTION
        Aggressively suspends Bitdefender real-time protection using multiple
        techniques. Returns $true if protection was successfully disabled.
        Always pair with Resume-Bitdefender afterward.
    #>
    $suspended = $false

    # Method 1: product.console.exe PauseProtection (paid versions)
    $bdConsolePaths = @(
        "$env:ProgramFiles\Bitdefender\Bitdefender Security\product.console.exe",
        "$env:ProgramFiles\Bitdefender\Endpoint Security\product.console.exe",
        "${env:ProgramFiles(x86)}\Bitdefender\Bitdefender Security\product.console.exe"
    )
    foreach ($p in $bdConsolePaths) {
        if (Test-Path $p) {
            try {
                Start-Process -FilePath $p -ArgumentList "/c PauseProtection secs=180" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
                $suspended = $true
            } catch { }
            break
        }
    }

    # Method 2: Unload BD minifilter drivers (blocks file scanning at kernel level)
    $bdFilters = @("bdsfltr", "bdfwfpf", "trufos", "avc3", "atc3", "edrsensor", "bdsandbox", "bdfndisf")
    foreach ($filter in $bdFilters) {
        try {
            $result = & fltmc unload $filter 2>&1
            if ($LASTEXITCODE -eq 0) { $suspended = $true }
        } catch { }
    }

    # Method 3: Force-kill BD processes (bypasses self-protection in some versions)
    $bdProcesses = @("vsserv", "bdagent", "bdservicehost", "seccenter", "bdredline", "bdntwrk", "updatesrv")
    foreach ($proc in $bdProcesses) {
        try {
            $running = Get-Process -Name $proc -ErrorAction SilentlyContinue
            if ($running) {
                & taskkill /F /IM "${proc}.exe" 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) { $suspended = $true }
            }
        } catch { }
    }

    # Method 4: Disable and stop BD services
    $bdServices = @("VSSERV", "BDAuxSrv", "bdredline", "bdagent", "EPProtectedService", "EPRedline", "BDSandBox")
    foreach ($svcName in $bdServices) {
        try {
            $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
            if ($svc -and $svc.Status -eq 'Running') {
                & sc.exe config $svcName start=disabled 2>&1 | Out-Null
                Stop-Service -Name $svcName -Force -ErrorAction Stop
                $suspended = $true
            }
        } catch { }
    }

    # Method 5: Disable BD Active Threat Control via registry
    $bdRegPaths = @(
        "HKLM:\SOFTWARE\Bitdefender\Bitdefender Antivirus Free Edition",
        "HKLM:\SOFTWARE\Bitdefender\Bitdefender Security\Active Virus Control",
        "HKLM:\SOFTWARE\Bitdefender\Bitdefender Antivirus\Active Virus Control"
    )
    foreach ($rp in $bdRegPaths) {
        try {
            if (Test-Path $rp) {
                Set-ItemProperty -Path $rp -Name "Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                $suspended = $true
            }
        } catch { }
    }
    # Also try shield key
    try {
        $shieldPaths = @(
            "HKLM:\SOFTWARE\Bitdefender\Bitdefender Antivirus Free Edition\Shield",
            "HKLM:\SOFTWARE\Bitdefender\Bitdefender Security\Shield"
        )
        foreach ($sp in $shieldPaths) {
            if (Test-Path $sp) {
                Set-ItemProperty -Path $sp -Name "Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                $suspended = $true
            }
        }
    } catch { }

    if ($suspended) { Start-Sleep -Seconds 3 }
    return $suspended
}

function Resume-Bitdefender {
    <#
    .DESCRIPTION
        Restarts Bitdefender real-time protection services after file installation.
    #>
    $bdServices = @("VSSERV", "BDAuxSrv", "bdredline", "bdagent", "EPProtectedService", "EPRedline", "BDSandBox")

    # Re-enable services
    foreach ($svcName in $bdServices) {
        try {
            & sc.exe config $svcName start=auto 2>&1 | Out-Null
            $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
            if ($svc -and $svc.Status -ne 'Running') {
                Start-Service -Name $svcName -ErrorAction SilentlyContinue
            }
        } catch { }
    }

    # Re-enable registry settings
    $bdRegPaths = @(
        "HKLM:\SOFTWARE\Bitdefender\Bitdefender Antivirus Free Edition",
        "HKLM:\SOFTWARE\Bitdefender\Bitdefender Security\Active Virus Control",
        "HKLM:\SOFTWARE\Bitdefender\Bitdefender Antivirus\Active Virus Control"
    )
    foreach ($rp in $bdRegPaths) {
        try {
            if (Test-Path $rp) {
                Set-ItemProperty -Path $rp -Name "Enabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            }
        } catch { }
    }
    try {
        $shieldPaths = @(
            "HKLM:\SOFTWARE\Bitdefender\Bitdefender Antivirus Free Edition\Shield",
            "HKLM:\SOFTWARE\Bitdefender\Bitdefender Security\Shield"
        )
        foreach ($sp in $shieldPaths) {
            if (Test-Path $sp) {
                Set-ItemProperty -Path $sp -Name "Enabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            }
        }
    } catch { }

    # Reload BD minifilter drivers
    $bdFilters = @("bdsfltr", "bdfwfpf", "trufos", "avc3", "atc3", "edrsensor")
    foreach ($filter in $bdFilters) {
        try { & fltmc load $filter 2>&1 | Out-Null } catch { }
    }

    # ResumeProtection via console
    $bdConsolePaths = @(
        "$env:ProgramFiles\Bitdefender\Bitdefender Security\product.console.exe",
        "$env:ProgramFiles\Bitdefender\Endpoint Security\product.console.exe",
        "${env:ProgramFiles(x86)}\Bitdefender\Bitdefender Security\product.console.exe"
    )
    foreach ($p in $bdConsolePaths) {
        if (Test-Path $p) {
            try { Start-Process -FilePath $p -ArgumentList "/c ResumeProtection" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue } catch { }
            break
        }
    }
}

function Protect-InstalledFiles {
    <#
    .DESCRIPTION
        Sets file attributes and permissions to protect bypass files from AV deletion.
        Uses ReadOnly+System attributes and restrictive ACLs.
    #>
    param([string]$ContentPath)
    
    $files = @("winmm.dll", (Get-DiskName -SourceName "OnlineFix64.dll"), "dlllist.txt", "OnlineFix.ini")
    
    foreach ($fileName in $files) {
        $filePath = Join-Path $ContentPath $fileName
        if (Test-Path $filePath) {
            # Set ReadOnly + System attributes (some AV products respect these)
            try {
                $file = Get-Item $filePath -Force
                $file.Attributes = [System.IO.FileAttributes]::ReadOnly -bor [System.IO.FileAttributes]::System
            } catch { }
            
            # Remove Zone.Identifier ADS (marks file as "from internet" - triggers extra AV scanning)
            try {
                Remove-Item -Path "${filePath}:Zone.Identifier" -Force -ErrorAction SilentlyContinue
            } catch { }
            
            # Apply deny-delete ACL on DLL files (prevents AV quarantine)
            if ($fileName -match '\.dll$') {
                Lock-FileFromDeletion -FilePath $filePath
            }
        }
    }
}

function Unprotect-InstalledFiles {
    <#
    .DESCRIPTION
        Removes protection attributes and ACLs before re-writing files.
    #>
    param([string]$ContentPath)
    
    foreach ($fileName in @("winmm.dll", (Get-DiskName -SourceName "OnlineFix64.dll"), "dlllist.txt", "OnlineFix.ini")) {
        $filePath = Join-Path $ContentPath $fileName
        if (Test-Path $filePath) {
            # Restore permissive ACL first (undo deny-delete)
            try {
                $acl = New-Object System.Security.AccessControl.FileSecurity
                $acl.SetAccessRuleProtection($true, $false)
                $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
                    (New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')),
                    'FullControl', 'Allow')))
                $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
                    (New-Object System.Security.Principal.SecurityIdentifier('S-1-1-0')),
                    'FullControl', 'Allow')))
                [System.IO.File]::SetAccessControl($filePath, $acl)
            } catch { }
            try {
                $file = Get-Item $filePath -Force
                $file.Attributes = [System.IO.FileAttributes]::Normal
            } catch {
                try { $null = cmd /c "attrib -R -S -H `"$filePath`"" 2>$null } catch { }
            }
        }
    }
}

function Remove-FileRobust {
    <#
    .DESCRIPTION
        Removes a file even when attributes, ownership or ACLs were hardened.
        Returns $true only if the file is actually gone at the end.
    #>
    param([string]$FilePath)

    $Script:LastRemovePendingReboot = $false
    if (-not (Test-Path $FilePath)) { return $true }

    # Reset ACL first (undo deny-delete protection)
    try {
        $acl = New-Object System.Security.AccessControl.FileSecurity
        $acl.SetAccessRuleProtection($true, $false)
        $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
            (New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')),
            'FullControl', 'Allow')))
        $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
            (New-Object System.Security.Principal.SecurityIdentifier('S-1-1-0')),
            'FullControl', 'Allow')))
        [System.IO.File]::SetAccessControl($FilePath, $acl)
    } catch { }

    try {
        $item = Get-Item $FilePath -Force -ErrorAction SilentlyContinue
        if ($item) { $item.Attributes = [System.IO.FileAttributes]::Normal }
    } catch { }

    try { $null = cmd /c "attrib -R -S -H `"$FilePath`"" 2>$null } catch { }

    try {
        Remove-Item -LiteralPath $FilePath -Force -ErrorAction Stop
    } catch { }

    if (-not (Test-Path $FilePath)) { return $true }

    try {
        $null = cmd /c "takeown /F `"$FilePath`" /A" 2>$null
        $null = cmd /c "icacls `"$FilePath`" /grant *S-1-5-32-544:F /C" 2>$null
        $null = cmd /c "attrib -R -S -H `"$FilePath`"" 2>$null
        $null = cmd /c "del /F /Q `"$FilePath`"" 2>$null
    } catch { }

    if (-not (Test-Path $FilePath)) { return $true }

    try {
        [System.IO.File]::Delete($FilePath)
    } catch { }

    if (-not (Test-Path $FilePath)) { return $true }

    try {
        Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class MBUFileOps {
    [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    public static extern bool MoveFileEx(string existingFileName, string newFileName, int flags);
}
"@ -ErrorAction SilentlyContinue

        # MOVEFILE_DELAY_UNTIL_REBOOT = 0x4
        if ([MBUFileOps]::MoveFileEx($FilePath, $null, 0x4)) {
            $Script:LastRemovePendingReboot = $true
        }
    } catch { }

    return (-not (Test-Path $FilePath))
}

function Watch-InstalledFiles {
    <#
    .DESCRIPTION
        Monitors bypass files for a specified duration. If any file is deleted by
        antivirus, immediately re-writes it from the in-memory cache.
        Returns $true if no files were deleted during monitoring.
    #>
    param(
        [string]$ContentPath,
        [int]$DurationSeconds = 15
    )
    
    if (-not $Script:BytesCache -or $Script:BytesCache.Count -eq 0) { return $true }
    
    $endTime = (Get-Date).AddSeconds($DurationSeconds)
    $rewroteFiles = @()
    $checkInterval = 1
    
    if ($Script:Lang -eq "pt") {
        Write-Info "Verificando por ${DurationSeconds}s se o antivirus remove arquivos logo apos a instalacao..."
    } else {
        Write-Info "Checking for ${DurationSeconds}s whether antivirus removes files right after install..."
    }
    
    while ((Get-Date) -lt $endTime) {
        foreach ($file in $Script:OnlineFixFiles) {
            $diskName = Get-DiskName -SourceName $file.Name
            $filePath = Join-Path $ContentPath $diskName
            if (-not (Test-Path $filePath)) {
                $bytes = $Script:BytesCache[$file.Name]
                if ($bytes -and $bytes.Length -gt 0) {
                    try {
                        # For dlllist.txt: patch content with safe name
                        $writeBytes = $bytes
                        if ($file.Name -eq "dlllist.txt" -and $Script:SafeDllName) {
                            $textContent = [System.Text.Encoding]::UTF8.GetString($bytes)
                            $textContent = $textContent -replace 'OnlineFix64\.dll', $Script:SafeDllName
                            $writeBytes = [System.Text.Encoding]::UTF8.GetBytes($textContent)
                        }
                        # Use full Write-FileToDisk for AV evasion (not plain WriteAllBytes)
                        $result = Write-FileToDisk -FileName $diskName -DestFile $filePath -Bytes $writeBytes
                        if ($result -ne $true) {
                            # Fallback: direct write
                            [System.IO.File]::WriteAllBytes($filePath, $writeBytes)
                        }
                        # Re-protect the file
                        Protect-SingleFile -FilePath $filePath
                        if ($diskName -match '\.dll$') {
                            Lock-FileFromDeletion -FilePath $filePath
                        }
                        
                        if ($diskName -notin $rewroteFiles) {
                            $rewroteFiles += $diskName
                            if ($Script:Lang -eq "pt") {
                                Write-Warn "  $diskName foi deletado pelo antivirus - restaurado automaticamente!"
                            } else {
                                Write-Warn "  $diskName was deleted by antivirus - automatically restored!"
                            }
                        }
                    } catch { }
                }
            }
        }
        Start-Sleep -Seconds $checkInterval
    }
    
    if ($rewroteFiles.Count -gt 0) {
        Write-C ""
        if ($Script:Lang -eq "pt") {
            Write-Warn "Antivirus tentou deletar $($rewroteFiles.Count) arquivo(s) - foram restaurados!"
            Write-C ""
            Write-C "  IMPORTANTE: Adicione a exclusao no seu antivirus para evitar" Yellow
            Write-C "  que isso aconteca toda vez que o Minecraft for aberto!" Yellow
            Write-C "  Pasta: $ContentPath" Cyan
        } else {
            Write-Warn "Antivirus tried to delete $($rewroteFiles.Count) file(s) - restored!"
            Write-C ""
            Write-C "  IMPORTANT: Add the exclusion in your antivirus to prevent" Yellow
            Write-C "  this from happening every time Minecraft is opened!" Yellow
            Write-C "  Folder: $ContentPath" Cyan
        }
        return $false
    } else {
        if ($Script:Lang -eq "pt") {
            Write-OK "Arquivos estaveis - nenhuma exclusao pelo antivirus detectada!"
        } else {
            Write-OK "Files stable - no antivirus deletion detected!"
        }
        return $true
    }
}

function Request-AVDisable {
    param(
        [array]$DetectedAV,
        [string]$FolderPath,
        [string[]]$BlockedFiles
    )
    
    Write-C ""
    Write-C "  ============================================================" Red
    Write-C ""
    
    # Detect if primary AV is BD Free (blocked write, not deleted)
    $primaryAV = $DetectedAV | Where-Object { $_.Active -and $_.Type -ne "defender" } | Select-Object -First 1
    if (-not $primaryAV) {
        $primaryAV = $DetectedAV | Where-Object { $_.Active } | Select-Object -First 1
    }
    $isBDFree = $primaryAV -and $primaryAV.Type -eq "bitdefender_free"
    
    # Show which files were blocked
    if ($Script:Lang -eq "pt") {
        if ($isBDFree) {
            Write-Err "SEU ANTIVIRUS BLOQUEOU A GRAVACAO DO ARQUIVO!"
        } else {
            Write-Err "SEU ANTIVIRUS DELETOU ARQUIVOS APOS O DOWNLOAD!"
        }
        Write-C ""
        foreach ($f in $BlockedFiles) {
            Write-Warn "    Bloqueado: $f"
        }
        Write-C ""
        if ($isBDFree) {
            Write-C "  Seu antivirus BLOQUEOU a gravacao do arquivo (acesso negado)." Yellow
            Write-C "  Desativar o 'Shield' NAO e suficiente - e preciso adicionar EXCECAO de pasta." White
        } else {
            Write-C "  O download funcionou e a integridade foi verificada, mas seu" Yellow
            Write-C "  antivirus DELETOU o arquivo imediatamente apos ser salvo no disco." Yellow
            Write-C ""
            Write-C "  Voce precisa DESATIVAR TEMPORARIAMENTE a protecao do seu antivirus" White
            Write-C "  para que a instalacao funcione. Apos instalar, pode reativar." White
        }
    } else {
        if ($isBDFree) {
            Write-Err "YOUR ANTIVIRUS BLOCKED THE FILE WRITE!"
        } else {
            Write-Err "YOUR ANTIVIRUS DELETED FILES AFTER DOWNLOAD!"
        }
        Write-C ""
        foreach ($f in $BlockedFiles) {
            Write-Warn "    Blocked: $f"
        }
        Write-C ""
        if ($isBDFree) {
            Write-C "  Your antivirus BLOCKED the file write (access denied)." Yellow
            Write-C "  Disabling 'Shield' is NOT enough - you must add a folder EXCEPTION." White
        } else {
            Write-C "  The download worked and integrity was verified, but your" Yellow
            Write-C "  antivirus DELETED the file immediately after it was saved to disk." Yellow
            Write-C ""
            Write-C "  You need to TEMPORARILY DISABLE your antivirus protection" White
            Write-C "  for the installation to work. You can re-enable it after." White
        }
    }
    
    Write-C ""
    Write-C "  ------------------------------------------------------------" DarkGray
    Write-C ""
    
    # Show specific instructions for the primary AV
    # ($primaryAV e $isBDFree already computed above)
    
    if ($primaryAV) {
        $instructions = Get-AVExclusionInstructions -AVType $primaryAV.Type -AVName $primaryAV.Name -FolderPath $FolderPath
        foreach ($line in $instructions) {
            if ($line -match "^\s*===") {
                Write-C "  $line" Cyan
            } elseif ($line -match "^\s*$") {
                Write-C ""
            } elseif ($line -match "ATENCAO:|WARNING:") {
                Write-C "  $line" Red
            } elseif ($line -match "^  METODO ALTERNATIVO|^  ALTERNATIVE") {
                Write-C "  $line" Green
            } else {
                Write-C "  $line" Yellow
            }
        }
        Write-C ""
        
        # Try to open AV settings automatically
        $opened = Open-AVSettings -AVType $primaryAV.Type
        if ($opened) {
            if ($Script:Lang -eq "pt") {
                Write-OK "Janela do seu antivirus aberta automaticamente!"
            } else {
                Write-OK "Your antivirus window opened automatically!"
            }
            Write-C ""
        }
    }
    
    Write-C "  ------------------------------------------------------------" DarkGray
    Write-C ""
    
    if ($Script:Lang -eq "pt") {
        if ($isBDFree) {
            Write-C "  >> Adicione a excecao de pasta e pressione ENTER para continuar..." White
        } else {
            Write-C "  >> Desative a protecao do antivirus e pressione ENTER para continuar..." White
        }
    } else {
        if ($isBDFree) {
            Write-C "  >> Add the folder exception and press ENTER to continue..." White
        } else {
            Write-C "  >> Disable your antivirus protection and press ENTER to continue..." White
        }
    }
    
    Write-C "  ============================================================" Red
    Write-C ""
    
    # Wait for user to press Enter
    Read-Host
}

function Get-DiskName {
    <# Returns the on-disk filename for a given source file name #>
    param([string]$SourceName)
    $entry = $Script:OnlineFixFiles | Where-Object { $_.Name -eq $SourceName } | Select-Object -First 1
    if ($entry -and $entry.DiskName) { return $entry.DiskName }
    return $SourceName
}

function Get-BytesSha256Hex {
    param([byte[]]$Bytes)
    if (-not $Bytes) { return $null }

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $sha256.ComputeHash($Bytes)
        return (-join ($hashBytes | ForEach-Object { $_.ToString("x2") }))
    } finally {
        if ($sha256) { $sha256.Dispose() }
    }
}

function Get-FileSha256Hex {
    param([string]$Path)
    try {
        if (-not (Test-Path $Path)) { return $null }
        return (Get-FileHash -Algorithm SHA256 -Path $Path -ErrorAction Stop).Hash.ToLowerInvariant()
    } catch {
        return $null
    }
}

function Test-PE64File {
    param([string]$Path)

    try {
        if (-not (Test-Path $Path)) { return $false }
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        if (-not $bytes -or $bytes.Length -lt 0x100) { return $false }
        if ($bytes[0] -ne 0x4D -or $bytes[1] -ne 0x5A) { return $false }
        $lfanew = [BitConverter]::ToInt32($bytes, 0x3C)
        if ($lfanew -lt 0x40 -or $lfanew -gt ($bytes.Length - 0x108)) { return $false }
        if ($bytes[$lfanew] -ne 0x50 -or $bytes[$lfanew + 1] -ne 0x45 -or $bytes[$lfanew + 2] -ne 0x00 -or $bytes[$lfanew + 3] -ne 0x00) { return $false }
        $machine = [BitConverter]::ToUInt16($bytes, $lfanew + 4)
        $magic = [BitConverter]::ToUInt16($bytes, $lfanew + 24)
        return ($machine -eq 0x8664 -and $magic -eq 0x20B)
    } catch {
        return $false
    }
}

function Test-FileMatchesBytes {
    param(
        [string]$FilePath,
        [string]$ExpectedHash,
        [int64]$ExpectedLength
    )

    try {
        if (-not (Test-Path $FilePath)) { return $false }
        $item = Get-Item -Path $FilePath -Force -ErrorAction Stop
        if ($item.Length -ne $ExpectedLength) { return $false }
        $actualHash = Get-FileSha256Hex -Path $FilePath
        return ($actualHash -and $ExpectedHash -and $actualHash -eq $ExpectedHash)
    } catch {
        return $false
    }
}

function Test-InstalledFileIntegrity {
    param(
        [string]$SourceName,
        [string]$FilePath,
        [string]$ExpectedHash
    )

    try {
        if (-not (Test-Path $FilePath)) { return $false }
        $item = Get-Item -Path $FilePath -Force -ErrorAction Stop
        if ($item.Length -le 0) { return $false }

        if ($SourceName -eq 'dlllist.txt') {
            $dllListEntry = (Get-Content $FilePath -ErrorAction Stop | Where-Object { $_.Trim() } | Select-Object -First 1)
            if (-not $dllListEntry) { return $false }
            $dllListEntry = $dllListEntry.Trim()
            $expectedDllName = Get-DiskName -SourceName 'OnlineFix64.dll'
            return ($dllListEntry -eq $expectedDllName -and (Test-SafeDllName -Name $dllListEntry))
        }

        if ($SourceName -match '\.dll$' -and -not (Test-PE64File -Path $FilePath)) { return $false }

        if ($ExpectedHash) {
            $actualHash = Get-FileSha256Hex -Path $FilePath
            if (-not $actualHash -or $actualHash -ne $ExpectedHash.ToLowerInvariant()) { return $false }
        }

        return $true
    } catch {
        return $false
    }
}

function Get-OnlineFixZipBytes {
    if ($Script:OnlineFixZipBytes -and $Script:OnlineFixZipBytes.Length -gt 0) {
        return $Script:OnlineFixZipBytes
    }

    Write-Info "$(T 'downloading') OnlineFix.zip..."
    $bytes = Invoke-DownloadBytes -Urls @($Script:OnlineFixZipUrl) -MinBytes 1024
    if (-not $bytes -or $bytes.Length -le 0) {
        return $null
    }

    $Script:OnlineFixZipBytes = $bytes
    return $Script:OnlineFixZipBytes
}

function Get-OnlineFixFileBytesFromZip {
    param([Parameter(Mandatory=$true)][string]$FileName)

    $zipBytes = Get-OnlineFixZipBytes
    if (-not $zipBytes -or $zipBytes.Length -le 0) { return $null }

    $memoryStream = $null
    $archive = $null
    $entryStream = $null
    $outputStream = $null
    try {
        Add-Type -AssemblyName System.IO.Compression -ErrorAction SilentlyContinue
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue

        $memoryStream = New-Object System.IO.MemoryStream
        $memoryStream.Write($zipBytes, 0, $zipBytes.Length)
        $memoryStream.Position = 0
        $archive = New-Object System.IO.Compression.ZipArchive($memoryStream, [System.IO.Compression.ZipArchiveMode]::Read, $false)
        $entry = $archive.Entries | Where-Object { -not [string]::IsNullOrWhiteSpace($_.Name) -and $_.Name -ieq $FileName } | Select-Object -First 1
        if (-not $entry) {
            $Script:LastDownloadError = "OnlineFix.zip does not contain $FileName"
            return $null
        }

        $entryStream = $entry.Open()
        $outputStream = New-Object System.IO.MemoryStream
        $entryStream.CopyTo($outputStream)
        $bytes = $outputStream.ToArray()
        if (-not $bytes -or $bytes.Length -le 0) {
            $Script:LastDownloadError = "OnlineFix.zip entry is empty: $FileName"
            return $null
        }
        return $bytes
    } catch {
        $Script:LastDownloadError = "OnlineFix.zip extraction failed for $FileName => $($_.Exception.Message)"
        return $null
    } finally {
        if ($outputStream) { $outputStream.Dispose() }
        if ($entryStream) { $entryStream.Dispose() }
        if ($archive) { $archive.Dispose() }
        if ($memoryStream) { $memoryStream.Dispose() }
    }
}

function Download-OnlineFixFile {
    param(
        [string]$FileName,
        [string]$DestPath,
        [string]$ExpectedHash
    )
    
    $url = "$Script:RawBaseUrl/$FileName"
    $diskName = Get-DiskName -SourceName $FileName
    $destFile = Join-Path $DestPath $diskName
    
    Write-Info "$(T 'downloading') $diskName..."
    # ============================================================
    # Self-contained mode - use embedded resource instead of downloading
    # ============================================================
    if ($Script:IsSelfContained) {
        $resourcePath = Join-Path $Script:ResourceDir $FileName
        if (Test-Path $resourcePath) {
            try {
                $bytes = [System.IO.File]::ReadAllBytes($resourcePath)
                if (-not $bytes -or $bytes.Length -eq 0) {
                    Write-Err "Embedded resource is empty: $FileName"
                    return "resource_empty"
                }
            } catch {
                Write-Err "Failed to read embedded resource: $FileName"
                return "resource_failed"
            }
        } else {
            Write-Err "Embedded resource not found: $FileName"
            return "resource_not_found"
        }
        
        # Cache bytes for potential retry later (so we don't re-download)
        if (-not $Script:BytesCache) { $Script:BytesCache = @{} }
        $Script:BytesCache[$FileName] = $bytes
        
        # For dlllist.txt: replace OnlineFix64.dll reference with safe name
        if ($FileName -eq "dlllist.txt" -and $Script:SafeDllName) {
            $textContent = [System.Text.Encoding]::UTF8.GetString($bytes)
            $textContent = $textContent -replace 'OnlineFix64\.dll', $Script:SafeDllName
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($textContent)
        }
        
        # Write to disk (self-contained mode)
        $writeResult = Write-FileToDisk -FileName $diskName -DestFile $destFile -Bytes $bytes
        if ($writeResult -eq $true) {
            Write-OK "$(T 'download_ok'): $diskName (embedded)"
        }
        return $writeResult
    } else {
    
    # ============================================================
    # STEP 1: Load bytes from the release OnlineFix.zip, then fall back to raw/main
    # ============================================================
    $bytes = Get-OnlineFixFileBytesFromZip -FileName $FileName
    if (-not $bytes -or $bytes.Length -eq 0) {
        $bytes = Invoke-DownloadBytes -Urls @($url) -MinBytes 1
    }
    
    if (-not $bytes -or $bytes.Length -eq 0) {
        Write-Err "$(T 'download_fail'): $diskName"
        if ($Script:Lang -eq "pt") {
            Write-Warn "  URL: $Script:OnlineFixZipUrl"
            Write-Warn "  Verifique sua conexao ou se o OnlineFix.zip da release contem este arquivo."
        } else {
            Write-Warn "  URL: $Script:OnlineFixZipUrl"
            Write-Warn "  Check your connection or whether the release OnlineFix.zip contains this file."
        }
        if ($Script:LastDownloadError) { Write-Warn "  $($Script:LastDownloadError)" }
        return "download_failed"
    }
    
    # ============================================================
    # STEP 2: Verify integrity in memory (before touching disk)
    # ============================================================
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $sha256.ComputeHash($bytes)
    $actualHash = -join ($hashBytes | ForEach-Object { $_.ToString("x2") })
    
    $hashOK = ($actualHash -eq $ExpectedHash)
    if (-not $hashOK) {
        Write-Warn "$(T 'hash_fail') ($FileName)"
        Write-Warn "  Expected: $ExpectedHash"
        Write-Warn "  Actual:   $actualHash"
        return "hash_failed"
    }
    
    # Cache bytes for potential retry later (so we don't re-download)
    if (-not $Script:BytesCache) { $Script:BytesCache = @{} }
    $Script:BytesCache[$FileName] = $bytes
    
    # For dlllist.txt: replace OnlineFix64.dll reference with safe name
    if ($FileName -eq "dlllist.txt" -and $Script:SafeDllName) {
        $textContent = [System.Text.Encoding]::UTF8.GetString($bytes)
        $textContent = $textContent -replace 'OnlineFix64\.dll', $Script:SafeDllName
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($textContent)
    }
    
    # ============================================================
    # STEP 3: Write to disk (this is where AV can block)
    # ============================================================
    $writeResult = Write-FileToDisk -FileName $diskName -DestFile $destFile -Bytes $bytes
    if ($writeResult -eq $true) {
        Write-OK "$(T 'download_ok'): $diskName"
    }
    return $writeResult
}
}

function Write-FileToDisk {
    param(
        [string]$FileName,
        [string]$DestFile,
        [byte[]]$Bytes
    )

    $expectedHash = Get-BytesSha256Hex -Bytes $Bytes
    $expectedLength = if ($Bytes) { [int64]$Bytes.Length } else { 0 }
    if (-not $expectedHash -or $expectedLength -le 0) { return "hash_failed" }

    # Remove existing file first (unprotect if needed)
    if (Test-Path $DestFile) {
        try {
            $existing = Get-Item $DestFile -Force -ErrorAction SilentlyContinue
            if ($existing) { $existing.Attributes = [System.IO.FileAttributes]::Normal }
            Remove-Item -Path $DestFile -Force -ErrorAction Stop
        } catch { }
    }
    
    # ============================================================
    # Technique 1: Direct WriteAllBytes (works if AV is paused)
    # ============================================================
    try {
        [System.IO.File]::WriteAllBytes($DestFile, $Bytes)
        if (Test-Path $DestFile) {
            Protect-SingleFile -FilePath $DestFile
            Start-Sleep -Milliseconds 500
            if (Test-FileMatchesBytes -FilePath $DestFile -ExpectedHash $expectedHash -ExpectedLength $expectedLength) { return $true }
        }
    } catch { }
    
    # Clean up if file was deleted
    if (Test-Path $DestFile) {
        try { Remove-Item $DestFile -Force -ErrorAction SilentlyContinue } catch { }
    }
    
    # ============================================================
    # Technique 2: Memory-mapped file (bypasses some minifilter hooks)
    # ============================================================
    try {
        # Create empty file of correct size
        $fs = [System.IO.File]::Create($DestFile)
        $fs.SetLength($Bytes.Length)
        $fs.Close()
        $fs.Dispose()
        
        # Write via memory-mapped file (goes through Mm, not Io path)
        Add-Type -AssemblyName System.IO.MemoryMappedFiles -ErrorAction SilentlyContinue
        $mmf = [System.IO.MemoryMappedFiles.MemoryMappedFile]::CreateFromFile(
            $DestFile,
            [System.IO.FileMode]::Open,
            $null,
            $Bytes.Length,
            [System.IO.MemoryMappedFiles.MemoryMappedFileAccess]::ReadWrite
        )
        $accessor = $mmf.CreateViewAccessor(0, $Bytes.Length)
        $accessor.WriteArray([long]0, $Bytes, 0, $Bytes.Length)
        $accessor.Flush()
        $accessor.Dispose()
        $mmf.Dispose()
        
        if (Test-Path $DestFile) {
            Protect-SingleFile -FilePath $DestFile
            Start-Sleep -Milliseconds 500
            if (Test-FileMatchesBytes -FilePath $DestFile -ExpectedHash $expectedHash -ExpectedLength $expectedLength) { return $true }
        }
    } catch { }
    
    # Clean up
    if (Test-Path $DestFile) {
        try { Remove-Item $DestFile -Force -ErrorAction SilentlyContinue } catch { }
    }
    
    # ============================================================
    # Technique 3: Write with restrictive ACL (deny SYSTEM read before close)
    # ============================================================
    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent().Name
        
        # Create file with FileStream
        $fs = New-Object System.IO.FileStream(
            $DestFile,
            [System.IO.FileMode]::Create,
            [System.IO.FileAccess]::ReadWrite,
            [System.IO.FileShare]::None
        )
        $fs.Write($Bytes, 0, $Bytes.Length)
        $fs.Flush()
        $fs.Close()
        $fs.Dispose()
        
        # Immediately restrict access (deny SYSTEM - BD's scanning account)
        try {
            $acl = New-Object System.Security.AccessControl.FileSecurity
            $acl.SetAccessRuleProtection($true, $false)
            $ownerRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $currentUser, 'FullControl', 'Allow'
            )
            $acl.AddAccessRule($ownerRule)
            # Deny SYSTEM read access (prevents BD from scanning)
            $denySystem = New-Object System.Security.AccessControl.FileSystemAccessRule(
                'NT AUTHORITY\SYSTEM', 'Read', 'Deny'
            )
            $acl.AddAccessRule($denySystem)
            [System.IO.File]::SetAccessControl($DestFile, $acl)
        } catch { }
        
        Start-Sleep -Milliseconds 500
        
        if (Test-Path $DestFile) {
            # Restore normal ACL so Minecraft can load the DLL
            try {
                $normalAcl = New-Object System.Security.AccessControl.FileSecurity
                $normalAcl.SetAccessRuleProtection($true, $false)
                $normalAcl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
                    $currentUser, 'FullControl', 'Allow'
                )))
                $normalAcl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
                    'BUILTIN\Users', 'ReadAndExecute', 'Allow'
                )))
                [System.IO.File]::SetAccessControl($DestFile, $normalAcl)
            } catch { }
            
            Protect-SingleFile -FilePath $DestFile
            Start-Sleep -Milliseconds 300
            if (Test-FileMatchesBytes -FilePath $DestFile -ExpectedHash $expectedHash -ExpectedLength $expectedLength) { return $true }
        }
    } catch { }
    
    # Clean up
    if (Test-Path $DestFile) {
        try { Remove-Item $DestFile -Force -ErrorAction SilentlyContinue } catch { }
    }
    
    # ============================================================
    # Technique 4: Write XOR-encoded then decode in-place via FileStream
    # ============================================================
    try {
        # XOR-encode with 32-byte key
        $xorKey = [System.Text.Encoding]::ASCII.GetBytes("Mc_Unl0ck3r_Byp@ss!xK9#pL7`$mN3v")
        $encoded = New-Object byte[] $Bytes.Length
        for ($i = 0; $i -lt $Bytes.Length; $i++) {
            $encoded[$i] = $Bytes[$i] -bxor $xorKey[$i % $xorKey.Length]
        }
        
        # Write encoded content (passes AV scan)
        [System.IO.File]::WriteAllBytes($DestFile, $encoded)
        
        Start-Sleep -Milliseconds 200
        
        if (Test-Path $DestFile) {
            # Now decode in-place: open file, overwrite with decoded bytes
            $fs = New-Object System.IO.FileStream(
                $DestFile,
                [System.IO.FileMode]::Open,
                [System.IO.FileAccess]::Write,
                [System.IO.FileShare]::None
            )
            $fs.Write($Bytes, 0, $Bytes.Length)
            $fs.Flush()
            $fs.Close()
            $fs.Dispose()
            
            Protect-SingleFile -FilePath $DestFile
            Start-Sleep -Milliseconds 500
            if (Test-FileMatchesBytes -FilePath $DestFile -ExpectedHash $expectedHash -ExpectedLength $expectedLength) { return $true }
        }
    } catch { }
    
    # Clean up
    if (Test-Path $DestFile) {
        try { Remove-Item $DestFile -Force -ErrorAction SilentlyContinue } catch { }
    }
    
    # ============================================================
    # Technique 5: safe temp name + hard link + ACL lock
    # Keep bytes exact. Mutating PE headers or section bytes can make Windows
    # reject the DLL with Bad Image / 0xc0e90007.
    # ============================================================
    try {
        $dir = [System.IO.Path]::GetDirectoryName($DestFile)
        $safeName = "gf_" + [Guid]::NewGuid().ToString("N").Substring(0, 8) + ".tmp"
        $safePath = Join-Path $dir $safeName

        [System.IO.File]::WriteAllBytes($safePath, $Bytes)
        Start-Sleep -Milliseconds 500

        if (Test-FileMatchesBytes -FilePath $safePath -ExpectedHash $expectedHash -ExpectedLength $expectedLength) {
            if (Test-Path $DestFile) {
                try { Remove-Item $DestFile -Force -ErrorAction SilentlyContinue } catch { }
            }

            $null = cmd /c "mklink /H `"$DestFile`" `"$safePath`"" 2>&1

            if (Test-FileMatchesBytes -FilePath $DestFile -ExpectedHash $expectedHash -ExpectedLength $expectedLength) {
                Remove-Item $safePath -Force -ErrorAction SilentlyContinue
                Protect-SingleFile -FilePath $DestFile
                Lock-FileFromDeletion -FilePath $DestFile
                Start-Sleep -Milliseconds 500
                if (Test-FileMatchesBytes -FilePath $DestFile -ExpectedHash $expectedHash -ExpectedLength $expectedLength) { return $true }
            }

            Remove-Item $safePath -Force -ErrorAction SilentlyContinue
        }
    } catch { }

    # All techniques failed
    return "av_blocked"
}

function Protect-SingleFile {
    param([string]$FilePath)
    try {
        $f = Get-Item $FilePath -Force -ErrorAction SilentlyContinue
        if ($f) {
            $f.Attributes = [System.IO.FileAttributes]::ReadOnly -bor [System.IO.FileAttributes]::System
        }
        Remove-Item -Path "${FilePath}:Zone.Identifier" -Force -ErrorAction SilentlyContinue
    } catch { }
}

function Lock-FileFromDeletion {
    <#
    .DESCRIPTION
        Sets deny-delete ACL on a file to prevent antivirus from quarantining it.
        Allows Administrators full control and Users read+execute (for Minecraft).
        Denies SYSTEM and Local Service the ability to delete, move, or change permissions.
    #>
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return }
    try {
        $acl = New-Object System.Security.AccessControl.FileSecurity
        $acl.SetAccessRuleProtection($true, $false)
        # Allow Administrators full control (SID-based for locale safety)
        $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
            (New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')),
            'FullControl', 'Allow')))
        # Allow Users read & execute (so Minecraft can load the DLL)
        $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
            (New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-545')),
            'ReadAndExecute', 'Allow')))
        # Deny Everyone delete permission (blocks AV quarantine/rename/move)
        # Only deny Delete - not ChangePermissions, so our script can undo this for restore
        $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
            (New-Object System.Security.Principal.SecurityIdentifier('S-1-1-0')),
            'Delete', 'Deny')))
        [System.IO.File]::SetAccessControl($FilePath, $acl)
    } catch { }
}

function Start-FileGuard {
    <#
    .DESCRIPTION
        Starts a hidden background PowerShell process that holds read handles on
        DLL files while Minecraft starts. Normal delete/rename attempts fail
        while the handles are open, but on-access blocking can still happen.
        Handles are shared for ReadWrite so Minecraft can still load the DLLs.
    #>
    param([string]$ContentPath)
    
    # Kill previous guard if running
    try {
        $existingGuard = Join-Path $env:TEMP "mbu_guard.pid"
        if (Test-Path $existingGuard) {
            $oldPid = [int](Get-Content $existingGuard -ErrorAction SilentlyContinue)
            if ($oldPid) { Stop-Process -Id $oldPid -Force -ErrorAction SilentlyContinue }
            Remove-Item $existingGuard -Force -ErrorAction SilentlyContinue
        }
    } catch { }
    
    $dll1 = (Join-Path $ContentPath (Get-DiskName -SourceName "OnlineFix64.dll")) -replace "'", "''"
    $dll2 = (Join-Path $ContentPath "winmm.dll") -replace "'", "''"
    
    $guardScript = @"
`$pid | Set-Content '$($existingGuard -replace "'", "''")' -Force
`$handles = @()
foreach (`$f in @('$dll1', '$dll2')) {
    if (Test-Path `$f) {
        try {
            `$fs = [System.IO.FileStream]::new(
                `$f, [System.IO.FileMode]::Open,
                [System.IO.FileAccess]::Read,
                [System.IO.FileShare]::ReadWrite)
            `$handles += `$fs
        } catch { }
    }
}
if (`$handles.Count -eq 0) { exit }
`$end = (Get-Date).AddHours(3)
while ((Get-Date) -lt `$end) {
    Start-Sleep -Seconds 30
    `$mc = Get-Process -Name 'Minecraft.Windows' -ErrorAction SilentlyContinue
    if (`$mc) {
        `$mc | Wait-Process -ErrorAction SilentlyContinue
        break
    }
}
foreach (`$h in `$handles) { try { `$h.Dispose() } catch { } }
Remove-Item '$($existingGuard -replace "'", "''")' -Force -ErrorAction SilentlyContinue
"@
    
    $scriptPath = Join-Path $env:TEMP "mbu_guard.ps1"
    [System.IO.File]::WriteAllText($scriptPath, $guardScript)
    Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass",
        "-WindowStyle", "Hidden", "-File", $scriptPath -WindowStyle Hidden
}

# ============================================================================
# Reboot Persistence: Survives AV cleanup on reboot
# ============================================================================

function Get-PersistencePath {
    return Join-Path $env:LOCALAPPDATA "MCBridge"
}

function Save-EncryptedBackup {
    <#
    .DESCRIPTION
        Saves XOR-encrypted copies of all bypass files to a hidden local folder.
        The encryption prevents AV from scanning the backup content.
        Uses $Script:BytesCache (in-memory download cache) to avoid file access conflicts.
    #>
    param([string]$ContentPath)
    
    $persistDir = Get-PersistencePath
    if (-not (Test-Path $persistDir)) {
        New-Item -Path $persistDir -ItemType Directory -Force | Out-Null
        # Hide the folder
        (Get-Item $persistDir -Force).Attributes = 'Hidden','Directory'
    }
    
    # Generate random XOR key
    $key = [byte[]]::new(64)
    [System.Security.Cryptography.RNGCryptoServiceProvider]::new().GetBytes($key)
    [System.IO.File]::WriteAllBytes((Join-Path $persistDir "bridge.key"), $key)
    
    # Save encrypted copies of each file
    $manifest = @()
    foreach ($file in $Script:OnlineFixFiles) {
        $diskName = Get-DiskName -SourceName $file.Name
        $bytes = $null
        $srcPath = Join-Path $ContentPath $diskName
        
        # For DLL files: ALWAYS read from disk (has PE mutations applied)
        # BytesCache has pre-mutation bytes that BD would detect instantly
        if ($diskName -match '\.dll$' -and (Test-Path $srcPath)) {
            try {
                $fs = [System.IO.FileStream]::new($srcPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
                $bytes = [byte[]]::new($fs.Length)
                $null = $fs.Read($bytes, 0, $bytes.Length)
                $fs.Dispose()
            } catch {
                # Fallback to BytesCache if disk read fails
                if ($Script:BytesCache -and $Script:BytesCache[$file.Name]) {
                    $bytes = [byte[]]$Script:BytesCache[$file.Name]
                }
            }
        }
        # For non-DLL files: use memory cache (faster, no mutation needed)
        elseif ($Script:BytesCache -and $Script:BytesCache[$file.Name]) {
            $bytes = [byte[]]$Script:BytesCache[$file.Name]
            # For dlllist.txt: patch content with safe name
            if ($file.Name -eq "dlllist.txt" -and $Script:SafeDllName) {
                $textContent = [System.Text.Encoding]::UTF8.GetString($bytes)
                $textContent = $textContent -replace 'OnlineFix64\.dll', $Script:SafeDllName
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($textContent)
            }
        }
        # Last resort: read from disk
        elseif (Test-Path $srcPath) {
            try {
                $fs = [System.IO.FileStream]::new($srcPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
                $bytes = [byte[]]::new($fs.Length)
                $null = $fs.Read($bytes, 0, $bytes.Length)
                $fs.Dispose()
            } catch { continue }
        }
        
        if ($bytes -and $bytes.Length -gt 0) {
            # XOR encrypt using Int64 blocks for speed
            $encrypted = [byte[]]::new($bytes.Length)
            [System.Array]::Copy($bytes, $encrypted, $bytes.Length)
            $expandedKey = [byte[]]::new($encrypted.Length)
            $kl = $key.Length
            for ($j = 0; $j -lt $encrypted.Length; $j++) { $expandedKey[$j] = $key[$j % $kl] }
            $blocks = [Math]::Floor($encrypted.Length / 8)
            for ($bi = 0; $bi -lt $blocks; $bi++) {
                $off = $bi * 8
                $dVal = [BitConverter]::ToInt64($encrypted, $off)
                $kVal = [BitConverter]::ToInt64($expandedKey, $off)
                [BitConverter]::GetBytes($dVal -bxor $kVal).CopyTo($encrypted, $off)
            }
            for ($bi = $blocks * 8; $bi -lt $encrypted.Length; $bi++) {
                $encrypted[$bi] = $encrypted[$bi] -bxor $expandedKey[$bi]
            }
            $bakName = "$($diskName).bak"
            [System.IO.File]::WriteAllBytes((Join-Path $persistDir $bakName), $encrypted)
            $manifest += "$diskName|$bakName"
        }
    }
    
    # Save manifest (maps disk names to backup names)
    [System.IO.File]::WriteAllLines((Join-Path $persistDir "bridge.dat"), $manifest)
    
    # Save the content path
    [System.IO.File]::WriteAllText((Join-Path $persistDir "target.dat"), $ContentPath)
}

function Install-Persistence {
    <#
    .DESCRIPTION
        Creates a Scheduled Task that runs at user logon to restore bypass files
        if they were removed during reboot (e.g., by AV boot-time cleanup).
        Also saves encrypted backups of the files for instant restore.
    #>
    param([string]$ContentPath)
    
    try {
        # Save encrypted backups first
        Save-EncryptedBackup -ContentPath $ContentPath
    } catch { }
    
    $persistDir = Get-PersistencePath
    
    # Create the restore script (self-contained, no external dependencies)
    # Strategy: For DLLs, write XOR-scrambled content first (passes AV scan),
    # then apply ACL + open handle, THEN decode in-place. This prevents BD
    # from quarantining during the vulnerable write window.
    $restoreScript = @'
$ErrorActionPreference = 'SilentlyContinue'
$persistDir = Join-Path $env:LOCALAPPDATA "MCBridge"
$logFile = Join-Path $persistDir "restore.log"

function Write-Log { param($msg) Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg" }

# Fast XOR using Int64 blocks (8 bytes at a time) - ~10x faster than byte loop
function Fast-Xor {
    param([byte[]]$Data, [byte[]]$Key)
    # Expand key to match data length (repeat key pattern)
    $expandedKey = [byte[]]::new($Data.Length)
    $kl = $Key.Length
    for ($j = 0; $j -lt $Data.Length; $j++) { $expandedKey[$j] = $Key[$j % $kl] }
    # XOR in 8-byte blocks using Int64
    $blocks = [Math]::Floor($Data.Length / 8)
    for ($i = 0; $i -lt $blocks; $i++) {
        $off = $i * 8
        $dVal = [BitConverter]::ToInt64($Data, $off)
        $kVal = [BitConverter]::ToInt64($expandedKey, $off)
        [BitConverter]::GetBytes($dVal -bxor $kVal).CopyTo($Data, $off)
    }
    # Handle remaining bytes
    for ($i = $blocks * 8; $i -lt $Data.Length; $i++) {
        $Data[$i] = $Data[$i] -bxor $expandedKey[$i]
    }
}

# Verify persistence data exists
if (-not (Test-Path (Join-Path $persistDir "bridge.key"))) { exit }
if (-not (Test-Path (Join-Path $persistDir "bridge.dat"))) { exit }
if (-not (Test-Path (Join-Path $persistDir "target.dat"))) { exit }

$targetPath = [System.IO.File]::ReadAllText((Join-Path $persistDir "target.dat")).Trim()
if (-not (Test-Path $targetPath)) { Write-Log "Target path not found: $targetPath"; exit }

# Read manifest
$manifest = [System.IO.File]::ReadAllLines((Join-Path $persistDir "bridge.dat"))
if ($manifest.Count -eq 0) { exit }

# Check if any files are missing
$needRestore = $false
foreach ($line in $manifest) {
    $parts = $line.Split('|')
    if ($parts.Count -lt 2) { continue }
    $filePath = Join-Path $targetPath $parts[0]
    if (-not (Test-Path $filePath)) { $needRestore = $true; break }
}

if (-not $needRestore) { Write-Log "All files present, no restore needed"; exit }

Write-Log "Files missing - starting restore..."

# Wait a bit for system to settle after boot
Start-Sleep -Seconds 10

# Load backup XOR key
$key = [System.IO.File]::ReadAllBytes((Join-Path $persistDir "bridge.key"))

# Generate a second random XOR key for the write-scramble technique
$writeKey = [byte[]]::new(32)
[System.Security.Cryptography.RNGCryptoServiceProvider]::new().GetBytes($writeKey)

$restoredCount = 0
$dllHandles = @()

foreach ($line in $manifest) {
    $parts = $line.Split('|')
    if ($parts.Count -lt 2) { continue }
    $diskName = $parts[0]
    $bakName = $parts[1]
    $filePath = Join-Path $targetPath $diskName
    $bakPath = Join-Path $persistDir $bakName

    if ((Test-Path $filePath) -and (Get-Item $filePath -Force).Length -gt 0) { continue }
    if (-not (Test-Path $bakPath)) { Write-Log "Backup missing: $bakName"; continue }

    # Decrypt from backup using fast XOR
    $bytes = [System.IO.File]::ReadAllBytes($bakPath)
    Fast-Xor -Data $bytes -Key $key

    $isDll = $diskName -match '\.dll$'

    try {
        if ($isDll) {
            # === DLL: Write scrambled → ACL → handle → decode in-place ===
            # Step 1: Write XOR-scrambled content (AV sees garbage, not a PE)
            $scrambled = [byte[]]::new($bytes.Length)
            [System.Array]::Copy($bytes, $scrambled, $bytes.Length)
            Fast-Xor -Data $scrambled -Key $writeKey
            [System.IO.File]::WriteAllBytes($filePath, $scrambled)
            $scrambled = $null

            # Step 2: Immediately apply deny-delete ACL (before BD can quarantine)
            [System.IO.File]::SetAttributes($filePath, [System.IO.FileAttributes]::ReadOnly -bor [System.IO.FileAttributes]::System)
            $adsPath = "${filePath}:Zone.Identifier"
            cmd /c "del `"$adsPath`"" 2>$null
            $acl = New-Object System.Security.AccessControl.FileSecurity
            $acl.SetAccessRuleProtection($true, $false)
            $adminSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
            $usersSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-545")
            $everyoneSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-1-0")
            $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($adminSid, "FullControl", "Allow")))
            $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($usersSid, "ReadAndExecute", "Allow")))
            $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($everyoneSid, "Delete", "Deny")))
            [System.IO.File]::SetAccessControl($filePath, $acl)

            # Step 3: Open a read handle (file guard - prevents deletion)
            $guard = [System.IO.FileStream]::new($filePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
            $dllHandles += $guard

            # Step 4: Decode in-place (overwrite scrambled with real content)
            [System.IO.File]::SetAttributes($filePath, [System.IO.FileAttributes]::Normal)
            $wfs = [System.IO.FileStream]::new($filePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Write, [System.IO.FileShare]::ReadWrite)
            $wfs.Write($bytes, 0, $bytes.Length)
            $wfs.Flush($true)
            $wfs.Dispose()
            [System.IO.File]::SetAttributes($filePath, [System.IO.FileAttributes]::ReadOnly -bor [System.IO.FileAttributes]::System)

            Write-Log "Restored+Protected: $diskName ($($bytes.Length) bytes)"
        } else {
            # === Non-DLL: simple write (text files, AV doesn't care) ===
            $fs = [System.IO.FileStream]::new($filePath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
            $fs.Write($bytes, 0, $bytes.Length)
            $fs.Flush($true)
            $fs.Dispose()
            Write-Log "Restored: $diskName ($($bytes.Length) bytes)"
        }
        $restoredCount++
    } catch {
        Write-Log "Failed to restore $diskName : $_"
    }
}

if ($restoredCount -gt 0) {
    Write-Log "Restored $restoredCount files."
}

# Hold DLL handles open for 3 hours (file guard)
if ($dllHandles.Count -gt 0) {
    Write-Log "File guard active for $($dllHandles.Count) DLLs"
    $end = (Get-Date).AddHours(3)
    while ((Get-Date) -lt $end) {
        Start-Sleep -Seconds 30
        $mc = Get-Process -Name 'Minecraft.Windows' -ErrorAction SilentlyContinue
        if ($mc) { $mc | Wait-Process -ErrorAction SilentlyContinue; break }
    }
    foreach ($h in $dllHandles) { try { $h.Dispose() } catch { } }
}

Write-Log "Restore complete"
'@
    
    $scriptPath = Join-Path $persistDir "GameConfigSync.ps1"
    [System.IO.File]::WriteAllText($scriptPath, $restoreScript)
    
    # Create Scheduled Task
    $taskName = "MCContentBridge"
    
    # Remove existing task if present
    try { Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue } catch { }
    
    try {
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
        $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 4)
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest -LogonType Interactive
        
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null
        
        return $true
    } catch {
        return $false
    }
}

function Remove-Persistence {
    <#
    .DESCRIPTION
        Removes the scheduled task and all persistence files.
        Called during Restore-Original (uninstall).
    #>
    
    # Remove scheduled task
    $taskName = "MCContentBridge"
    try { Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue } catch { }
    
    # Remove persistence directory
    $persistDir = Get-PersistencePath
    if (Test-Path $persistDir) {
        try {
            Remove-Item $persistDir -Recurse -Force -ErrorAction SilentlyContinue
        } catch { }
    }
}

function Test-Persistence {
    <#
    .DESCRIPTION
        Checks if the reboot persistence mechanism is installed.
    #>
    $taskName = "MCContentBridge"
    try {
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        return ($null -ne $task)
    } catch {
        return $false
    }
}

function Retry-CachedFiles {
    <#
    .DESCRIPTION
        Re-writes cached bytes to disk for files that were previously blocked by AV.
        Uses already-downloaded and verified bytes from memory cache.
        Returns $true if all missing files were written successfully.
    #>
    param([string]$DestPath)
    
    if (-not $Script:BytesCache -or $Script:BytesCache.Count -eq 0) { return $false }
    
    $allOK = $true
    
    foreach ($file in $Script:OnlineFixFiles) {
        $diskName = Get-DiskName -SourceName $file.Name
        $filePath = Join-Path $DestPath $diskName
        if (-not (Test-Path $filePath)) {
            $bytes = $Script:BytesCache[$file.Name]
            if ($bytes -and $bytes.Length -gt 0) {
                # For dlllist.txt: patch content with safe name
                $writeBytes = $bytes
                if ($file.Name -eq "dlllist.txt" -and $Script:SafeDllName) {
                    $textContent = [System.Text.Encoding]::UTF8.GetString($bytes)
                    $textContent = $textContent -replace 'OnlineFix64\.dll', $Script:SafeDllName
                    $writeBytes = [System.Text.Encoding]::UTF8.GetBytes($textContent)
                }
                Write-Info "$(T 'downloading') $diskName..."
                $result = Write-FileToDisk -FileName $diskName -DestFile $filePath -Bytes $writeBytes
                if ($result -eq $true) {
                    Write-OK "$(T 'download_ok'): $diskName"
                } else {
                    $allOK = $false
                }
            } else {
                # Need to re-download (wasn't cached)
                $result = Download-OnlineFixFile -FileName $file.Name -DestPath $DestPath -ExpectedHash $file.Hash
                if ($result -ne $true) { $allOK = $false }
            }
        }
    }
    
    return $allOK
}

function Verify-Installation {
    param([string]$ContentPath)
    
    $allPresent = $true
    $missing = @()
    $invalid = @()
    
    foreach ($file in $Script:OnlineFixFiles) {
        $diskName = Get-DiskName -SourceName $file.Name
        $filePath = Join-Path $ContentPath $diskName
        if (-not (Test-Path $filePath)) {
            $allPresent = $false
            $missing += $diskName
            continue
        }

        try {
            $item = Get-Item -Path $filePath -Force -ErrorAction Stop
            if ($item.Length -le 0) {
                $allPresent = $false
                $invalid += $diskName
                continue
            }

            if (-not (Test-InstalledFileIntegrity -SourceName $file.Name -FilePath $filePath -ExpectedHash $file.Hash)) {
                $allPresent = $false
                $invalid += $diskName
            }
        } catch {
            $allPresent = $false
            $invalid += $diskName
        }
    }
    
    return @{
        AllPresent = $allPresent
        Missing = @($missing | Select-Object -Unique)
        Invalid = @($invalid | Select-Object -Unique)
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
            if (Remove-FileRobust -FilePath $filePath) {
                Write-OK "Removed legacy: $file"
            } else {
                Write-Warn "Failed to remove: $file"
            }
        }
        Write-C ""
        return $true
    }
    return $false
}

function Test-GamingServices {
    $serviceNames = @('GamingServices', 'GamingServicesNet')
    foreach ($serviceName in $serviceNames) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if (-not $service -or $service.Status -ne 'Running') { return $false }
    }
    return $true
}

function Start-GamingServices {
    Write-Info (T 'start_gaming')
    foreach ($serviceName in @('GamingServices', 'GamingServicesNet')) {
        try {
            Start-Service -Name $serviceName -ErrorAction SilentlyContinue
        } catch { }
    }
}

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
    $null = Remove-LegacyBypass -ContentPath $mcPath
    
    # Generate safe DLL name (avoids AV filename-based detection)
    Initialize-SafeDllNames -ContentPath $mcPath
    
    # Detect ALL antivirus and add exclusions
    $avResult = Add-AllAVExclusions -Path $mcPath
    
    # Self-contained mode: exclude parent temp dir (persistent, covers all future runs)
    if ($Script:IsSelfContained) {
        $tempParent = Join-Path ([System.IO.Path]::GetTempPath()) "MinecraftBedrockUnlocker"
        try { Add-MpPreference -ExclusionPath $tempParent -ErrorAction SilentlyContinue } catch { }
    }
    $detectedAV = $avResult.AVList
    $anyExclusionAdded = $avResult.AnyAdded
    
    # BITDEFENDER PROACTIVE HANDLING: For BD Free, always suspend (registry exclusions don't work)
    $hasBitdefender = $detectedAV | Where-Object { $_.Type -match "bitdefender" -and $_.Active }
    $bdWasSuspended = $false
    if ($hasBitdefender) {
        $primaryBD = $hasBitdefender | Select-Object -First 1
        $isBDFree = ($primaryBD.Type -eq "bitdefender_free")

        # For BD paid, try exclusion first; for BD Free, skip (registry doesn't work)
        $bdExclusionOK = $false
        if (-not $isBDFree) {
            $bdExclusionOK = Try-BitdefenderExclusion -FolderPath $mcPath
            if ($bdExclusionOK) {
                Write-OK (T 'exclusion_added')
                $anyExclusionAdded = $true
            }
        }

        # BD Free: skip suspension entirely - Technique 5 (PE evasion + hardlink)
        # handles file writing without needing to disable protection.
        if ($isBDFree) {
            if ($Script:Lang -eq "pt") {
                Write-Info "Antivirus detectado - usando metodo de escrita avancado..."
            } else {
                Write-Info "Antivirus detected - using advanced write method..."
            }

        # BD Paid without exclusion: try suspension
        } elseif (-not $bdExclusionOK) {
            Write-Info (T 'bd_suspending')
            $bdWasSuspended = Suspend-Bitdefender
            if ($bdWasSuspended) {
                Write-OK (T 'bd_suspended')
            } else {
                # Auto-pause failed - write test file to check if protection is actually down
                $testPath = Join-Path $mcPath "__bd_test__.tmp"
                try {
                    [System.IO.File]::WriteAllBytes($testPath, [byte[]](0..255))
                    Remove-Item $testPath -Force -ErrorAction SilentlyContinue
                    # Write succeeded - protection might actually be paused
                    $bdWasSuspended = $true
                    Write-OK (T 'bd_suspended')
                } catch {
                    # Protection is definitely still active - manual fallback
                    $instructions = Get-AVExclusionInstructions -AVType $primaryBD.Type -AVName $primaryBD.Name -FolderPath $mcPath

                    Write-C ""
                    Write-C "  ============================================================" Yellow
                    Write-C "  $(T 'bd_suspend_failed')" Red
                    Write-C ""
                    foreach ($line in $instructions) {
                        if ($line -match "^\s*===") { Write-C "  $line" Cyan }
                        elseif ($line -match "^\s*$") { Write-C "" }
                        elseif ($line -match "ATENCAO:|WARNING:") { Write-C "  $line" Red }
                        else { Write-C "  $line" Yellow }
                    }
                    Write-C ""

                    $opened = Open-AVSettings -AVType $primaryBD.Type
                    if ($opened) {
                        if ($Script:Lang -eq "pt") { Write-OK "Janela do seu antivirus aberta!" }
                        else { Write-OK "Your antivirus window opened!" }
                    }

                    Write-C ""
                    if ($Script:Lang -eq "pt") {
                        Write-C "  >> Adicione a exclusao e pressione ENTER para continuar..." White
                    } else {
                        Write-C "  >> Add the exclusion and press ENTER to continue..." White
                    }
                    Write-C "  ============================================================" Yellow
                    Read-Host
                    Write-C ""

                    $null = Try-BitdefenderExclusion -FolderPath $mcPath
                }
            }
        }
    }
    
    # Wait for exclusions to propagate (only if any were added)
    if ($anyExclusionAdded) {
        Start-Sleep -Seconds 3
    }
    
    # Try to disable Defender real-time if it's actually active and functional
    $defenderDisabledByUs = $false
    $hasActiveDefender = $detectedAV | Where-Object { $_.Type -eq "defender" -and $_.Active }
    if ($hasActiveDefender -and (Test-DefenderActive)) {
        try {
            Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction Stop
            $defenderDisabledByUs = $true
        } catch { }
    }
    
    Write-C ""
    Write-Info (T 'installing')
    Write-C ""

    # Remove previous read-only/ACL protection so a corrupted safe DLL can be replaced.
    Unprotect-InstalledFiles -ContentPath $mcPath
    
    # Initialize bytes cache for potential retry
    $Script:BytesCache = @{}
    
    # ============================================================
    # PASS 1: Download all files (detect AV blocking)
    # ============================================================
    $avBlockedFiles = @()
    $failedFiles = @()
    $downloadSuccessCount = 0
    
    foreach ($file in $Script:OnlineFixFiles) {
        $result = Download-OnlineFixFile -FileName $file.Name -DestPath $mcPath -ExpectedHash $file.Hash
        if ($result -eq "av_blocked") {
            $avBlockedFiles += $file.Name
        } elseif ($result -eq "download_failed" -or $result -eq "hash_failed") {
            $failedFiles += $file.Name
        } elseif ($result -eq $true) {
            $downloadSuccessCount++
        }
    }
    
    # NOTE: Defender/Bitdefender stay disabled until after verification to prevent
    # deletion of freshly written files during the verify wait period.
    # They are re-enabled after the protection+verify cycle below.

    # ============================================================
    # EARLY EXIT: If ALL downloads failed, don't pretend it worked
    # ============================================================
    if ($failedFiles.Count -eq $Script:OnlineFixFiles.Count) {
        Write-C ""
        Write-C "  ============================================================" Red
        if ($Script:Lang -eq "pt") {
            Write-Err "TODOS OS DOWNLOADS FALHARAM!"
            Write-C ""
            Write-C "  Nenhum arquivo foi baixado com sucesso." Yellow
            Write-C "  Possiveis causas:" Yellow
            Write-C "  1. Sem conexao com a internet" White
            Write-C "  2. GitHub esta bloqueado pela sua rede/ISP" White
            Write-C "  3. Os arquivos nao existem no release do GitHub" White
            Write-C ""
            Write-C "  Verifique se este arquivo abre no navegador:" Cyan
            Write-C "  $Script:OnlineFixZipUrl" White
            Write-C ""
            Write-C "  Depois execute novamente o install.bat da release." Cyan
        } else {
            Write-Err "ALL DOWNLOADS FAILED!"
            Write-C ""
            Write-C "  No files were downloaded successfully." Yellow
            Write-C "  Possible causes:" Yellow
            Write-C "  1. No internet connection" White
            Write-C "  2. GitHub is blocked by your network/ISP" White
            Write-C "  3. Files don't exist in the GitHub release" White
            Write-C ""
            Write-C "  Check whether this file opens in your browser:" Cyan
            Write-C "  $Script:OnlineFixZipUrl" White
            Write-C ""
            Write-C "  Then run the release install.bat again." Cyan
        }
        Write-C "  ============================================================" Red
        Write-C ""
        Write-Info "Discord: $Script:DiscordUrl"
        Wait-Enter
        return
    }

    # If some downloads failed but not all, show partial warning
    if ($failedFiles.Count -gt 0) {
        Write-C ""
        if ($Script:Lang -eq "pt") {
            Write-Warn "$($failedFiles.Count) de $($Script:OnlineFixFiles.Count) downloads falharam:"
        } else {
            Write-Warn "$($failedFiles.Count) of $($Script:OnlineFixFiles.Count) downloads failed:"
        }
        foreach ($f in $failedFiles) {
            $dn = Get-DiskName -SourceName $f
            Write-Warn "    - $dn"
        }
        Write-C ""
    }

    # Protect files immediately after writing (attributes to resist AV deletion)
    Protect-InstalledFiles -ContentPath $mcPath
    
    # Quick verify (AV might delete files after a delay - wait longer for Bitdefender)
    $verifyWait = if ($hasBitdefender) { 5 } else { 3 }
    Start-Sleep -Seconds $verifyWait
    $verification = Verify-Installation -ContentPath $mcPath
    
    # ============================================================
    # SUCCESS: All files present (downloaded OR already existed)
    # ============================================================
    if ($verification.AllPresent) {
        # Re-enable Defender now that files are verified present
        if ($defenderDisabledByUs) {
            try {
                Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
            } catch { }
        }
        if ($bdWasSuspended) {
            Resume-Bitdefender
            Write-OK (T 'bd_resumed')
        }

        # If downloads failed but old files exist, warn user
        if ($failedFiles.Count -gt 0) {
            Write-C ""
            if ($Script:Lang -eq "pt") {
                Write-Warn "Alguns downloads falharam, mas os arquivos ja existem de uma instalacao anterior."
                Write-Warn "Verificando integridade dos arquivos existentes..."
            } else {
                Write-Warn "Some downloads failed, but files already exist from a previous installation."
                Write-Warn "Verifying integrity of existing files..."
            }
            # Verify hashes of existing files
            $hashMismatch = @()
            foreach ($file in $Script:OnlineFixFiles) {
                $diskName = Get-DiskName -SourceName $file.Name
                $filePath = Join-Path $mcPath $diskName
                if (Test-Path $filePath) {
                    try {
                        $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
                        $sha256 = [System.Security.Cryptography.SHA256]::Create()
                        $hashBytes = $sha256.ComputeHash($fileBytes)
                        $actualHash = -join ($hashBytes | ForEach-Object { $_.ToString("x2") })
                        # For dlllist.txt, skip hash check (content is patched with safe name)
                        if ($file.Name -ne "dlllist.txt" -and $actualHash -ne $file.Hash) {
                            $hashMismatch += $diskName
                        }
                    } catch { }
                }
            }
            if ($hashMismatch.Count -gt 0) {
                Write-C ""
                if ($Script:Lang -eq "pt") {
                    Write-Warn "Arquivos com hash diferente (podem estar desatualizados):"
                } else {
                    Write-Warn "Files with different hash (may be outdated):"
                }
                foreach ($f in $hashMismatch) { Write-Warn "    - $f" }
            } else {
                Write-OK (T 'hash_ok')
            }
        }
        
        Write-C ""
        Write-OK (T 'files_ok')
        
        # Launch Minecraft now: Defender/AV usually scans these DLLs on access.
        Write-C ""
        $launchValidation = Invoke-MinecraftLaunchValidation -ContentPath $mcPath -DurationSeconds 30
        $finalCheck = $launchValidation.FinalCheck
        if ($finalCheck -and $finalCheck.AllPresent) {
            # Install reboot persistence (Scheduled Task + encrypted backup)
            $persistOK = Install-Persistence -ContentPath $mcPath
            if ($persistOK) {
                Write-OK (T 'persistence_ok')
            } else {
                Write-Warn (T 'persistence_fail')
            }
            
            # Start background file guard (holds handles to prevent AV quarantine)
            Start-FileGuard -ContentPath $mcPath
            
            Write-C ""
            Write-OK (T 'install_ok')
            
            # BD Free: recommend on-access exclusion (optional, game already works)
            if ($isBDFree) {
                # Check if any BD exclusion already exists for this path
                if (Test-BDFreeExclusion -FolderPath $mcPath) {
                    Write-C ""
                    Write-OK (T 'bd_onaccess_verified')
                } else {
                    Write-C ""
                    if ($Script:Lang -eq "pt") {
                        Write-C "  O Bitdefender Free foi detectado no seu sistema." Yellow
                        Write-C "  Adicionar a exclusao e recomendado para evitar problemas futuros." Yellow
                        Write-C ""
                        Write-C "  Deseja configurar a exclusao agora? (Recomendado) [S/N]: " White -NoNewline
                    } else {
                        Write-C "  Bitdefender Free was detected on your system." Yellow
                        Write-C "  Adding the exclusion is recommended to prevent future issues." Yellow
                        Write-C ""
                        Write-C "  Do you want to configure the exclusion now? (Recommended) [Y/N]: " White -NoNewline
                    }
                    $choice = Read-Host
                    if ($choice -match '^[SsYy]') {
                        $null = Request-BDFreeOnAccessExclusion -ContentPath $mcPath
                    } else {
                        Write-C ""
                        if ($Script:Lang -eq "pt") {
                            Write-Warn "Se o Minecraft apresentar problemas, adicione a exclusao no Bitdefender."
                            Write-Info "  Pasta: $mcPath"
                        } else {
                            Write-Warn "If Minecraft has issues, add the exclusion in Bitdefender."
                            Write-Info "  Folder: $mcPath"
                        }
                    }
                }
            } else {
                if ($Script:Lang -eq "pt") {
                    Write-Info "Voce ja pode reativar a protecao do seu antivirus."
                } else {
                    Write-Info (T 'av_reenable')
                }
            }
        } else {
            # Files were deleted during watchdog and couldn't be restored
            Write-C ""
            Write-Err (T 'files_missing')
            foreach ($f in $finalCheck.Missing) { Write-Warn "    - $f" }
            Write-C ""
            if ($Script:Lang -eq "pt") {
                Write-C "  O antivirus removeu os arquivos durante ou logo apos abrir o Minecraft." Yellow
                Write-C "  Adicione a exclusao no antivirus e instale novamente." White
                Write-C "  Pasta: $mcPath" Cyan
            } else {
                Write-C "  Antivirus removed files during or right after opening Minecraft." Yellow
                Write-C "  Add the antivirus exclusion and install again." White
                Write-C "  Folder: $mcPath" Cyan
            }
        }
        Wait-Enter
        return
    }
    
    # ============================================================
    # AV DETECTED BLOCKING: Interactive pause + retry
    # ============================================================
    # Determine which files are actually missing now
    $actuallyMissing = $verification.Missing
    $isAVProblem = ($avBlockedFiles.Count -gt 0) -or ($actuallyMissing | Where-Object { $_ -match '\.dll$' })
    
    if ($isAVProblem) {
        # Show interactive AV disable prompt and WAIT for user
        Request-AVDisable -DetectedAV $detectedAV -FolderPath $mcPath -BlockedFiles $actuallyMissing
        
        # User pressed ENTER - retry writing cached files to disk (no re-download needed)
        Write-C ""
        Write-Info (T 'av_retrying_after_disable')
        Write-C ""
        
        # Disable Defender again if possible (user might have disabled their 3rd party AV)
        $defenderDisabledByUs = $false
        if (Test-DefenderActive) {
            try {
                Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction Stop
                $defenderDisabledByUs = $true
            } catch { }
        }
        
        # Unprotect files before retry (in case attributes are blocking)
        Unprotect-InstalledFiles -ContentPath $mcPath
        
        # Re-write from cached bytes (instant - no download)
        $null = Retry-CachedFiles -DestPath $mcPath
        
        # Protect files immediately
        Protect-InstalledFiles -ContentPath $mcPath
        
        # Wait longer and verify (Defender stays disabled until after verify)
        Start-Sleep -Seconds 5
        $verification2 = Verify-Installation -ContentPath $mcPath
        
        if ($verification2.AllPresent) {
            # Re-enable Defender now that files are verified present
            if ($defenderDisabledByUs) {
                try {
                    Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
                } catch { }
            }

            Write-C ""
            Write-OK (T 'files_ok')
            
            # Launch Minecraft now: Defender/AV usually scans these DLLs on access.
            Write-C ""
            $retryLaunchValidation = Invoke-MinecraftLaunchValidation -ContentPath $mcPath -DurationSeconds 30
            $finalRetry = $retryLaunchValidation.FinalCheck
            if ($finalRetry -and $finalRetry.AllPresent) {
                $null = Install-Persistence -ContentPath $mcPath
                Start-FileGuard -ContentPath $mcPath
                Write-C ""
                Write-OK (T 'install_ok')
                Write-C ""
                if ($isBDFree) {
                    $null = Request-BDFreeOnAccessExclusion -ContentPath $mcPath
                } else {
                    if ($Script:Lang -eq "pt") {
                        Write-OK "Voce ja pode REATIVAR a protecao do seu antivirus!"
                    } else {
                        Write-OK "You can now RE-ENABLE your antivirus protection!"
                    }
                }
            } else {
                Write-C ""
                Write-Err (T 'files_missing')
                foreach ($f in $finalRetry.Missing) { Write-Warn "    - $f" }
            }
            Wait-Enter
            return
        }
        
        # ============================================================
        # SECOND RETRY: Still failing, try once more
        # ============================================================
        Write-C ""
        Write-Err (T 'av_still_blocking')
        Write-C ""
        
        if ($Script:Lang -eq "pt") {
            Write-C "  Verificando se o antivirus esta realmente desativado..." Yellow
        } else {
            Write-C "  Checking if antivirus is actually disabled..." Yellow
        }
        Write-C ""
        
        # Check if there are still active AV products
        $currentAV = Detect-Antivirus
        $stillActive = $currentAV | Where-Object { $_.Active -and $_.Type -ne "defender" }
        
        if ($stillActive) {
            if ($Script:Lang -eq "pt") {
                Write-Warn "  Seu antivirus ainda esta ATIVO!"
            } else {
                Write-Warn "  Your antivirus is STILL ACTIVE!"
            }
            Write-C ""
            if ($Script:Lang -eq "pt") {
                Write-C "  Seu antivirus ainda esta ativo. Certifique-se de desativar" Yellow
                Write-C "  a PROTECAO EM TEMPO REAL (Real-Time Protection / Shield)." Yellow
                Write-C ""
                Write-C "  >> Desative completamente e pressione ENTER..." White
            } else {
                Write-C "  Your antivirus is still active. Make sure to disable" Yellow
                Write-C "  REAL-TIME PROTECTION (Shield)." Yellow
                Write-C ""
                Write-C "  >> Fully disable it and press ENTER..." White
            }
            Read-Host
        }
        
        Write-C ""
        Write-Info (T 'retry_install')
        Write-C ""
        
        # Unprotect and re-write from cache again
        Unprotect-InstalledFiles -ContentPath $mcPath
        $null = Retry-CachedFiles -DestPath $mcPath
        Protect-InstalledFiles -ContentPath $mcPath
        
        Start-Sleep -Seconds 5
        $verification3 = Verify-Installation -ContentPath $mcPath
        
        if ($verification3.AllPresent) {
            # Re-enable Defender now that files are verified present
            if ($defenderDisabledByUs) {
                try {
                    Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
                } catch { }
            }

            Write-C ""
            Write-OK (T 'files_ok')
            
            # Launch Minecraft now: Defender/AV usually scans these DLLs on access.
            Write-C ""
            $thirdLaunchValidation = Invoke-MinecraftLaunchValidation -ContentPath $mcPath -DurationSeconds 30
            $finalCheck3 = $thirdLaunchValidation.FinalCheck
            if ($finalCheck3 -and $finalCheck3.AllPresent) {
                $null = Install-Persistence -ContentPath $mcPath
                Start-FileGuard -ContentPath $mcPath
                Write-C ""
                Write-OK (T 'install_ok')
                Write-C ""
                if ($isBDFree) {
                    $null = Request-BDFreeOnAccessExclusion -ContentPath $mcPath
                } else {
                    if ($Script:Lang -eq "pt") {
                        Write-OK "Voce ja pode REATIVAR a protecao do seu antivirus!"
                    } else {
                        Write-OK "You can now RE-ENABLE your antivirus protection!"
                    }
                }
            } else {
                Write-C ""
                Write-Err (T 'files_missing')
                foreach ($f in $finalCheck3.Missing) { Write-Warn "    - $f" }
            }
            Wait-Enter
            return
        }
        
        # ============================================================
        # FINAL FAILURE: Show last-resort instructions
        # ============================================================
        Write-C ""
        Write-C "  ============================================================" Red
        if ($Script:Lang -eq "pt") {
            Write-Err "INSTALACAO FALHOU - ANTIVIRUS AINDA BLOQUEANDO"
            Write-C ""
            Write-C "  Os arquivos continuam sendo deletados. Tente:" Yellow
            Write-C ""
            Write-C "  1. Abra seu antivirus e DESATIVE COMPLETAMENTE" White
            Write-C "     (nao so exclusoes - desative o Shield/Escudo)" White
            Write-C "  2. Verifique se nao ha outro antivirus rodando" White
            Write-C "  3. Execute este script novamente" White
            Write-C ""
            Write-C "  Pasta do Minecraft:" Cyan
            Write-C "  $mcPath" Yellow
            Write-C ""
            Write-C "  Discord para ajuda: $Script:DiscordUrl" Cyan
        } else {
            Write-Err "INSTALLATION FAILED - ANTIVIRUS STILL BLOCKING"
            Write-C ""
            Write-C "  Files are still being deleted. Try:" Yellow
            Write-C ""
            Write-C "  1. Open your antivirus and FULLY DISABLE it" White
            Write-C "     (not just exclusions - disable the Shield)" White
            Write-C "  2. Make sure no other antivirus is running" White
            Write-C "  3. Run this script again" White
            Write-C ""
            Write-C "  Minecraft folder:" Cyan
            Write-C "  $mcPath" Yellow
            Write-C ""
            Write-C "  Discord for help: $Script:DiscordUrl" Cyan
        }
        Write-C "  ============================================================" Red
        Write-C ""
        # Re-enable Defender before exiting on failure
        if ($defenderDisabledByUs) {
            try {
                Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
            } catch { }
        }
        if ($bdWasSuspended) {
            Resume-Bitdefender
        }
        Wait-Enter
        return
    }
    
    # ============================================================
    # NON-AV FAILURE: Network/other issues
    # ============================================================
    # Re-enable Defender before exiting on failure
    if ($defenderDisabledByUs) {
        try {
            Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
        } catch { }
    }
    if ($bdWasSuspended) {
        Resume-Bitdefender
    }
    Write-C ""
    Write-Err (T 'install_fail')
    foreach ($f in $failedFiles) {
        Write-Warn "    - $f"
    }
    Write-C ""
    if ($Script:Lang -eq "pt") {
        Write-Info "Verifique sua conexao com a internet e tente novamente."
    } else {
        Write-Info "Check your internet connection and try again."
    }
    Write-C ""
    Write-Info "Discord: $Script:DiscordUrl"
    Wait-Enter
}

function Reset-StoreLicenseCache {
    # Reset the Windows Store and Gaming Services license cache
    # This ensures the system re-validates the actual license status
    
    Write-Info (T 'resetting_license')
    
    $resetDone = $false
    
    # Method 1: Restart ClipSVC (Client License Platform Service)
    try {
        $clipSvc = Get-Service -Name "ClipSVC" -ErrorAction SilentlyContinue
        if ($clipSvc) {
            Stop-Service -Name "ClipSVC" -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            Start-Service -Name "ClipSVC" -ErrorAction SilentlyContinue
            Write-OK "ClipSVC (License Service) - Reset OK"
            $resetDone = $true
        }
    } catch {
        Write-Warn "ClipSVC reset failed: $_"
    }
    
    # Method 2: Restart GamingServices
    try {
        $gamingSvc = Get-Service -Name "GamingServices" -ErrorAction SilentlyContinue
        if ($gamingSvc) {
            Stop-Service -Name "GamingServices" -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            Start-Service -Name "GamingServices" -ErrorAction SilentlyContinue
            Write-OK "GamingServices - Reset OK"
            $resetDone = $true
        }
    } catch {
        Write-Warn "GamingServices reset failed: $_"
    }
    
    # Method 3: Restart GamingServicesNet
    try {
        $gamingSvcNet = Get-Service -Name "GamingServicesNet" -ErrorAction SilentlyContinue
        if ($gamingSvcNet) {
            Stop-Service -Name "GamingServicesNet" -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
            Start-Service -Name "GamingServicesNet" -ErrorAction SilentlyContinue
            Write-OK "GamingServicesNet - Reset OK"
            $resetDone = $true
        }
    } catch {
        Write-Warn "GamingServicesNet reset failed: $_"
    }
    
    # Method 4: Clear the Microsoft Store cache (silent mode)
    try {
        $wsreset = Get-Command "wsreset.exe" -ErrorAction SilentlyContinue
        if ($wsreset) {
            # Use -i for silent/non-interactive if available, otherwise use cmd trick
            $proc = Start-Process -FilePath "wsreset.exe" -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue
            if ($proc) {
                $proc | Wait-Process -Timeout 10 -ErrorAction SilentlyContinue
                if (-not $proc.HasExited) {
                    $proc | Stop-Process -Force -ErrorAction SilentlyContinue
                }
                Write-OK "Microsoft Store Cache - Reset OK"
                $resetDone = $true
            }
        }
    } catch {
        Write-Warn "Store cache reset failed: $_"
    }
    
    # Method 5: Clear Xbox Live token cache
    try {
        $xboxCachePath = "C:\ProgramData\Microsoft\XboxLive"
        if (Test-Path $xboxCachePath) {
            $htCacheFile = Join-Path $xboxCachePath "HTCache.dat"
            if (Test-Path $htCacheFile) {
                Remove-Item -Path $htCacheFile -Force -ErrorAction SilentlyContinue
                Write-OK "Xbox Live Cache - Cleared"
                $resetDone = $true
            }
        }
    } catch {
        Write-Warn "Xbox cache clear failed: $_"
    }
    
    if (-not $resetDone) {
        Write-Warn (T 'license_reset_partial')
    }
    
    Write-C ""
}

function Restore-Original {
    $mcPath = Find-MinecraftPath
    
    if (-not $mcPath) {
        Write-Err (T 'mc_not_found')
        Wait-Enter
        return
    }
    
    # Initialize safe DLL names so we know what files to remove
    Initialize-SafeDllNames -ContentPath $mcPath
    
    # IMPORTANT: Kill Minecraft FIRST, before any file operations
    # DLLs loaded in memory persist even after deletion
    if (Test-MinecraftRunning) {
        Stop-Minecraft
        # Extra wait to ensure process fully terminates and releases DLLs
        Start-Sleep -Seconds 2
    }
    
    Write-Info (T 'removing')
    Write-C ""
    
    # Kill background file guard process (holds handles on DLLs)
    try {
        $guardPidFile = Join-Path $env:TEMP "mbu_guard.pid"
        if (Test-Path $guardPidFile) {
            $guardPid = [int](Get-Content $guardPidFile -ErrorAction SilentlyContinue)
            if ($guardPid) { Stop-Process -Id $guardPid -Force -ErrorAction SilentlyContinue }
            Remove-Item $guardPidFile -Force -ErrorAction SilentlyContinue
        }
    } catch { }
    
    # Remove reboot persistence (Scheduled Task + encrypted backups)
    Remove-Persistence
    Write-OK (T 'persistence_removed')
    
    # Remove file protection attributes before deleting
    Unprotect-InstalledFiles -ContentPath $mcPath
    
    # Read dlllist.txt to find the custom DLL name (if renamed)
    $customDllName = $null
    $dllListPath = Join-Path $mcPath "dlllist.txt"
    if (Test-Path $dllListPath) {
        $content = (Get-Content $dllListPath -ErrorAction SilentlyContinue | Where-Object { $_.Trim() }) | Select-Object -First 1
        $candidate = if ($content) { $content.Trim() } else { $null }
        if ($candidate -and $candidate -ne "OnlineFix64.dll" -and (Test-SafeDllName -Name $candidate)) {
            $customDllName = $candidate
        }
    }
    
    # Current OnlineFix files + legacy OpenFix/bypass file names
    $filesToRemove = @(
        # Current OnlineFix (both original and safe name)
        "winmm.dll", "OnlineFix64.dll", "dlllist.txt", "OnlineFix.ini",
        # Legacy OpenFix (older bypass versions)
        "OpenFix.ini", "OpenFix64.dll", "OpenFix.log",
        # Legacy backup/logs
        "winmm_orig.dll", "FakeGDK.log", "FullBypass.log",
        "DirectHook.log", "Monitor.log", "VPMon.log", "XStore.log"
    )
    # Add custom-named DLL if found
    if ($customDllName -and $customDllName -notin $filesToRemove) {
        $filesToRemove += $customDllName
    }
    
    $removedCount = 0
    $foundCount = 0
    $failedFiles = @()
    $pendingRebootFiles = @()
    foreach ($file in $filesToRemove) {
        $filePath = Join-Path $mcPath $file
        if (Test-Path $filePath) {
            $foundCount++
            if (Remove-FileRobust -FilePath $filePath) {
                Write-OK "Removed: $file"
                $removedCount++
            } else {
                if ($Script:LastRemovePendingReboot) {
                    $pendingRebootFiles += $file
                    Write-Warn "Scheduled for removal after reboot: $file"
                } else {
                    $failedFiles += $file
                    Write-Warn "Failed to remove: $file"
                }
            }
        }
    }
    
    if ($foundCount -eq 0) {
        Write-Info "No bypass files found to remove."
    }
    
    Write-C ""
    
    # Reset Windows Store / Gaming Services license cache
    # This forces the system to re-validate the real license status
    Reset-StoreLicenseCache
    
    # Re-register Minecraft package to force full license re-validation
    Write-Info (T 'reregistering_mc')
    try {
        $mcPkg = Get-AppxPackage -Name "MICROSOFT.MINECRAFTUWP" -ErrorAction SilentlyContinue
        if ($mcPkg -and $mcPkg.InstallLocation) {
            $manifest = Join-Path $mcPkg.InstallLocation "AppxManifest.xml"
            if (Test-Path $manifest) {
                Add-AppxPackage -Register $manifest -DisableDevelopmentMode -ForceApplicationShutdown -ErrorAction SilentlyContinue
                Write-OK (T 'reregister_ok')
            }
        }
    } catch {
        Write-Warn "Re-register failed: $_"
    }
    
    # Clear Minecraft app local data (license tokens / settings cache)
    Write-Info (T 'clearing_app_cache')
    try {
        $appDataPath = "$env:LOCALAPPDATA\Packages\MICROSOFT.MINECRAFTUWP_8wekyb3d8bbwe"
        if (Test-Path $appDataPath) {
            $cacheDirs = @("LocalCache", "TempState")
            foreach ($dir in $cacheDirs) {
                $dirPath = Join-Path $appDataPath $dir
                if (Test-Path $dirPath) {
                    Get-ChildItem -Path $dirPath -Recurse -Force -ErrorAction SilentlyContinue | 
                        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
            # Clear settings.dat (contains cached license state)
            $settingsPath = Join-Path $appDataPath "Settings"
            if (Test-Path $settingsPath) {
                Get-ChildItem -Path $settingsPath -Filter "settings.dat*" -Force -ErrorAction SilentlyContinue | 
                    Remove-Item -Force -ErrorAction SilentlyContinue
                Write-OK (T 'cache_cleared')
            }
        }
    } catch {
        Write-Warn "Cache clear failed: $_"
    }
    
    Write-C ""
    if ($failedFiles.Count -eq 0 -and $pendingRebootFiles.Count -eq 0) {
        Write-OK (T 'removed_ok')
        Write-C ""
        Write-Info (T 'restore_reopen_note')
    } elseif ($failedFiles.Count -eq 0 -and $pendingRebootFiles.Count -gt 0) {
        Write-Warn "Some bypass files were scheduled for removal on the next reboot."
        foreach ($file in $pendingRebootFiles) { Write-Warn "  - $file" }
        Write-C ""
        if ($Script:Lang -eq 'pt') {
            Write-Info "Reinicie o PC para concluir a remocao completa do bypass."
        } else {
            Write-Info "Restart the PC to finish removing the bypass completely."
        }
    } else {
        Write-Warn "Some bypass files could not be removed."
        foreach ($file in $failedFiles) { Write-Warn "  - $file" }
        foreach ($file in $pendingRebootFiles) { Write-Warn "  - $file (pending reboot)" }
        Write-C ""
        if ($Script:Lang -eq 'pt') {
            Write-Info "Feche o Minecraft, Xbox App e qualquer Explorer aberto nessa pasta. Depois execute novamente como administrador."
        } else {
            Write-Info "Close Minecraft, Xbox App and any Explorer window opened in that folder, then run again as administrator."
        }
    }
    Wait-Enter
}

function Start-MinecraftApp {
    $opened = $false

    # Method 1: shell:AppsFolder (most reliable, works even without minecraft: URI)
    try {
        Start-Process "shell:AppsFolder\Microsoft.MinecraftUWP_8wekyb3d8bbwe!App" -ErrorAction Stop
        $opened = $true
    } catch { }

    # Method 2: minecraft: URI protocol
    if (-not $opened) {
        try {
            Start-Process "minecraft:" -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            if (Test-MinecraftRunning) { $opened = $true }
        } catch { }
    }

    # Method 3: Direct exe via Get-AppxPackage
    if (-not $opened) {
        try {
            $pkg = Get-AppxPackage -Name "MICROSOFT.MINECRAFTUWP" -ErrorAction SilentlyContinue
            if ($pkg) {
                $exe = Join-Path $pkg.InstallLocation "Minecraft.Windows.exe"
                if (Test-Path $exe) {
                    Start-Process $exe -ErrorAction Stop
                    $opened = $true
                }
            }
        } catch { }
    }

    return $opened
}

function Invoke-MinecraftLaunchValidation {
    param(
        [string]$ContentPath,
        [int]$DurationSeconds = 30
    )

    if (-not $ContentPath) {
        return @{ Opened = $false; AllPresent = $false; FinalCheck = $null }
    }

    $beforeLaunch = Verify-Installation -ContentPath $ContentPath
    if (-not $beforeLaunch.AllPresent) {
        return @{ Opened = $false; AllPresent = $false; FinalCheck = $beforeLaunch }
    }

    if (-not (Test-GamingServices)) {
        Start-GamingServices
        Start-Sleep -Seconds 2
    }

    if ($Script:Lang -eq "pt") {
        Write-Info "Abrindo Minecraft para validar o carregamento das DLLs com o antivirus ativo..."
    } else {
        Write-Info "Opening Minecraft to validate DLL loading with antivirus active..."
    }

    Start-FileGuard -ContentPath $ContentPath
    $opened = Start-MinecraftApp

    if ($opened) {
        Write-OK (T 'mc_opened')
    } else {
        if ($Script:Lang -eq "pt") {
            Write-Warn "Minecraft nao abriu automaticamente. Ainda vou verificar se os arquivos continuam presentes."
        } else {
            Write-Warn "Minecraft did not open automatically. Validation will still check whether files remain present."
        }
    }

    if ($Script:Lang -eq "pt") {
        Write-Info "Aguardando ${DurationSeconds}s apos abrir o Minecraft para ver se o antivirus remove as DLLs..."
    } else {
        Write-Info "Waiting ${DurationSeconds}s after opening Minecraft to see whether antivirus removes DLLs..."
    }

    Start-Sleep -Seconds $DurationSeconds
    $finalCheck = Verify-Installation -ContentPath $ContentPath
    return @{ Opened = $opened; AllPresent = $finalCheck.AllPresent; FinalCheck = $finalCheck }
}

function Open-Minecraft {
    $mcPath = Find-MinecraftPath

    # Health check before opening - more robust with file protection
    if ($mcPath) {
        Initialize-SafeDllNames -ContentPath $mcPath
        $verification = Verify-Installation -ContentPath $mcPath
        if (-not $verification.AllPresent -and $verification.Missing.Count -lt 4) {
            if ($Script:Lang -eq "pt") {
                Write-Warn "Arquivos do bypass faltando! Tentando reparo automatico..."
            } else {
                Write-Warn "Bypass files missing! Attempting auto-repair..."
            }
            # Add AV exclusions first
            $null = Add-AllAVExclusions -Path $mcPath
            # Try Bitdefender exclusion
            $null = Try-BitdefenderExclusion -FolderPath $mcPath
            Start-Sleep -Milliseconds 500

            # Initialize cache for watchdog
            $Script:BytesCache = @{}

            foreach ($file in $Script:OnlineFixFiles) {
                $diskName = Get-DiskName -SourceName $file.Name
                $filePath = Join-Path $mcPath $diskName
                if ((-not (Test-Path $filePath)) -or ($verification.Invalid -contains $diskName)) {
                    $null = Download-OnlineFixFile -FileName $file.Name -DestPath $mcPath -ExpectedHash $file.Hash
                }
            }
            # Protect repaired files
            Protect-InstalledFiles -ContentPath $mcPath

            Start-Sleep -Seconds 2
            $repairCheck = Verify-Installation -ContentPath $mcPath
            if ($repairCheck.AllPresent) {
                if ($Script:Lang -eq "pt") {
                    Write-OK "Reparo automatico bem-sucedido!"
                } else {
                    Write-OK "Auto-repair successful!"
                }
            } else {
                if ($Script:Lang -eq "pt") {
                    Write-Err "Reparo falhou - antivirus pode estar bloqueando"
                    Write-C "  Adicione a pasta do Minecraft nas exclusoes do antivirus:" Yellow
                    Write-C "  $mcPath" Cyan
                } else {
                    Write-Err "Repair failed - antivirus may be blocking"
                    Write-C "  Add the Minecraft folder to your antivirus exclusions:" Yellow
                    Write-C "  $mcPath" Cyan
                }
            }
        } elseif ($verification.AllPresent) {
            # Files exist - refresh protection attributes
            Protect-InstalledFiles -ContentPath $mcPath
        }
    }

    Write-Info (T 'opening_mc')
    $opened = $false
    if ($mcPath) {
        $launchResult = Invoke-MinecraftLaunchValidation -ContentPath $mcPath -DurationSeconds 5
        $opened = $launchResult.Opened
        if (-not $launchResult.AllPresent) {
            Write-Err (T 'files_missing')
            foreach ($f in $launchResult.FinalCheck.Missing) { Write-Warn "    - $f" }
        }
    } else {
        $opened = Start-MinecraftApp
    }

    if (-not $opened) {
        Write-Err "Failed to open Minecraft. Please open manually from the Start Menu."
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
    
    # Initialize safe DLL names so Verify-Installation checks correct filenames
    if ($mcPath) { Initialize-SafeDllNames -ContentPath $mcPath }
    
    Write-Line
    Write-C "  $(T 'status_title')" Cyan
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
        } elseif ($verification.Invalid.Count -gt 0 -or $verification.Missing.Count -lt 4) {
            Write-C (T 'status_partial') Yellow
            foreach ($f in $verification.Invalid) {
                Write-C "    - invalid/corrupted: $f" Yellow
            }
            foreach ($f in ($verification.Missing | Where-Object { $verification.Invalid -notcontains $_ })) {
                Write-C "    - missing: $f" Yellow
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
    $avList = Detect-Antivirus
    $activeAV = @($avList | Where-Object { $_.Active })
    if ($activeAV.Count -gt 0) {
        if ($Script:Lang -eq "pt") {
            Write-C "Detectado" Yellow
        } else {
            Write-C "Detected" Yellow
        }
    } elseif (Test-DefenderActive) {
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
    
    # Reboot Persistence
    Write-C "  $(T 'status_persistence'):  " -NoNewline
    if (Test-Persistence) {
        Write-C (T 'status_installed') Green
    } else {
        Write-C (T 'status_not_installed') DarkGray
    }
    
    Write-C ""
    Write-Line
    Wait-Enter
}

function Show-Diagnostics {
    $mcPath = Find-MinecraftPath
    
    Write-Line
    Write-C "  $(T 'diag_title')" Cyan
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
        Initialize-SafeDllNames -ContentPath $mcPath
        $v = Verify-Installation -ContentPath $mcPath
        $bypassOk = $v.AllPresent
        if ($v.AllPresent) {
            $bypassMsg = "All files present and hash-valid"
        } elseif ($v.Invalid.Count -gt 0) {
            $bypassMsg = "Invalid/corrupted: $($v.Invalid -join ', ')"
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
    Set-ConsoleAppearance
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
            "1" { try { Install-Bypass } catch { Write-C ""; Write-Err "$($_.Exception.Message)"; Write-C ""; Read-Host "  $(if ($Script:Lang -eq 'pt') { 'Pressione ENTER para continuar' } else { 'Press ENTER to continue' })" } }
            "2" { try { Restore-Original } catch { Write-C ""; Write-Err "$($_.Exception.Message)"; Write-C ""; Read-Host "  $(if ($Script:Lang -eq 'pt') { 'Pressione ENTER para continuar' } else { 'Press ENTER to continue' })" } }
            "3" { try { Open-Minecraft } catch { Write-C ""; Write-Err "$($_.Exception.Message)"; Write-C ""; Read-Host "  $(if ($Script:Lang -eq 'pt') { 'Pressione ENTER para continuar' } else { 'Press ENTER to continue' })" } }
            "4" { try { Open-XboxApp } catch { Write-C ""; Write-Err "$($_.Exception.Message)"; Write-C ""; Read-Host "  $(if ($Script:Lang -eq 'pt') { 'Pressione ENTER para continuar' } else { 'Press ENTER to continue' })" } }
            "5" { try { Show-Status } catch { Write-C ""; Write-Err "$($_.Exception.Message)"; Write-C ""; Read-Host "  $(if ($Script:Lang -eq 'pt') { 'Pressione ENTER para continuar' } else { 'Press ENTER to continue' })" } }
            "6" { try { Show-Diagnostics } catch { Write-C ""; Write-Err "$($_.Exception.Message)"; Write-C ""; Read-Host "  $(if ($Script:Lang -eq 'pt') { 'Pressione ENTER para continuar' } else { 'Press ENTER to continue' })" } }
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
try {
    Start-MainLoop
} catch {
    Write-C ""
    Write-C "  ============================================================" Red
    Write-C ""
    Write-Err "Critical error: $($_.Exception.Message)"
    Write-C ""
    if ($Script:Lang -eq 'pt') {
        Write-C "  O script encontrou um erro inesperado e nao pode continuar." Yellow
        Write-C "  Por favor, tire um print desta mensagem e reporte o erro." Yellow
        Write-C "  Se foi o antivirus: execute novamente apos desativa-lo." Yellow
    } else {
        Write-C "  The script encountered an unexpected error and cannot continue." Yellow
        Write-C "  Please take a screenshot of this message and report it." Yellow
        Write-C "  If it was your antivirus: run again after disabling it." Yellow
    }
    Write-C ""
    Write-C "  ============================================================" Red
    Write-C ""
    Read-Host "  $(if ($Script:Lang -eq 'pt') { 'Pressione ENTER para sair' } else { 'Press ENTER to exit' })"
}
