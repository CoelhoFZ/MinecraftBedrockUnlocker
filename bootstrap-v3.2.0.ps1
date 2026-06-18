<#
.SYNOPSIS
  Minecraft Bedrock Unlocker v3.2.0 - Unified bootstrap (PowerShell) with Multi7 language support (en, zh, hi, es, fr, ar, ru) based on OS culture (Get-Culture).

.DESCRIPTION
  v3.2.0 consolidates install.ps1 + e.ps1 + i.ps1 into a single bootstrap.
  Why this exists: v3.1.11 on GitHub release ships only MinecraftBedrockUnlocker.exe
  as a release asset. The PowerShell installers (install.ps1, unlocker.ps1) reference
  multiple release-hosted assets (winmm.dll, OnlineFix64.dll, dlllist.txt, etc.) that
  return HTTP 404. This bootstrap:

    1. Detects Windows + PowerShell 5.1+ (WinPS) or PowerShell 7+ (Core).
    2. Downloads MinecraftBedrockUnlocker.exe from the latest CoelhoFZ release.
    3. Verifies the EXE is a valid PE32+ binary (size + MZ header + .NET assembly).
    4. Optionally verifies SHA256 against SHA256SUMS.txt when reachable.
    5. Launches the EXE as Administrator (UAC prompt).
    6. Falls back to running unlocker.ps1 from raw/main if the EXE fails to launch.

  This bootstrap is NOT a replacement for the CoelhoFZ/Gustavo upstream installer.
  It only fixes the broken PowerShell bootstrap path. The EXE wrapper
  (Online-Fix GDK Client, ProductVersion 1.0.4.0) is unchanged.

.PARAMETER SkipExe
  Skip the EXE download and use the unlocker.ps1 fallback path only.

.PARAMETER UseRawMain
  Fetch unlocker.ps1 from raw/main instead of the release. Useful for testing.

.PARAMETER Lang
  Force UI language: 'en' or 'pt'. Defaults to OS culture detection.

.EXAMPLE
  iex (irm 'https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/main/bootstrap-v3.2.0.ps1')

.EXAMPLE
  .\bootstrap-v3.2.0.ps1 -SkipExe

.NOTES
  Version:        3.2.1
  Author: CoelhoFZ + Gustavo (CoelhoFZ Community)
  License: GPLv3 (this script only; bundled Online-Fix binaries retain their own license).
#>

[CmdletBinding()]
param(
    [switch]$SkipExe,
    [switch]$UseRawMain,
    [ValidateSet('auto','en','zh','hi','es','fr','ar','ru')]
    [string]$Lang = 'auto'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

$Script:Version = '3.2.1'
$Script:RepoOwner = 'CoelhoFZ'
$Script:RepoName  = 'MinecraftBedrockUnlocker'
$Script:ExeName   = 'MinecraftBedrockUnlocker.exe'

$Script:ReleaseExeUrl  = "https://github.com/$($Script:RepoOwner)/$($Script:RepoName)/releases/latest/download/$($Script:ExeName)"
$Script:RawMainExeUrl  = "https://raw.githubusercontent.com/$($Script:RepoOwner)/$($Script:RepoName)/main/$($Script:ExeName)"
$Script:ReleaseFallbackUrl = "https://github.com/$($Script:RepoOwner)/$($Script:RepoName)/releases/latest/download"
$Script:RawMainUrl     = "https://raw.githubusercontent.com/$($Script:RepoOwner)/$($Script:RepoName)/main"
$Script:Sha256SumsUrl  = "$($Script:RawMainUrl)/SHA256SUMS.txt"

# ---------------------------------------------------------------------------
# i18n
# ---------------------------------------------------------------------------

function Detect-Lang {
    if ($Lang -ne 'auto') { return $Lang }
    try {
        $c = (Get-Culture).Name
        switch -Wildcard ($c) {
            'zh-*' { return 'zh' }
            'hi-*' { return 'hi' }
            'es-*' { return 'es' }
            'fr-*' { return 'fr' }
            'ar-*' { return 'ar' }
            'ru-*' { return 'ru' }
            default { return 'en' }
        }
    } catch { }
    return 'en'
}

function T {
    param([string]$Key)
    $lang = Detect-Lang
    $table = @{
        en = @{
            'banner' = 'Minecraft Bedrock Unlocker - bootstrap v3.2.1'
            'detecting_os' = 'Detecting platform...'
            'os_unsupported' = 'This bootstrap requires Windows.'
            'ps_unsupported' = 'PowerShell 5.1 or newer is required (you have {0}).'
            'downloading_exe' = 'Downloading {0} from {1}...'
            'verify_pe' = 'Verifying EXE signature (PE32+ MZ header)...'
            'verify_sha' = 'Verifying SHA256 against SHA256SUMS.txt...'
            'sha_match' = 'SHA256 OK.'
            'sha_mismatch' = 'SHA256 mismatch. Expected {0}, got {1}.'
            'sha_skip' = 'SHA256SUMS.txt unavailable; skipping hash check.'
            'launching_admin' = 'Launching {0} as Administrator (UAC prompt)...'
            'fallback_header' = 'EXE failed to launch. Falling back to unlocker.ps1 from raw/main...'
            'downloading_ps1' = 'Downloading unlocker.ps1 from {0}...'
            'verify_ps1' = 'Verifying unlocker.ps1 (size + content-type)...'
            'running_ps1' = 'Running unlocker.ps1 with PowerShell...'
            'all_failed' = 'All attempts failed. Possible causes:'
            'cause_internet' = '  1. No internet connection or GitHub is unreachable'
            'cause_av' = '  2. Antivirus blocked the download'
            'cause_release' = '  3. GitHub release assets are temporarily unavailable'
            'cause_local' = '  4. Local PowerShell cannot elevate to Administrator'
            'suggestion' = 'Suggestions:'
            'suggest_disable_av' = '  - Temporarily disable real-time antivirus protection'
            'suggest_wait' = '  - Wait a few minutes and retry (GitHub may be rate-limiting)'
            'suggest_release' = '  - Open https://github.com/{0}/{1}/releases and download the EXE manually'
            'enter_to_exit' = 'Press ENTER to exit'
            'press_enter_pt' = 'Pressione ENTER para sair'
        }
        zh = @{
            'banner' = 'Minecraft 基岩版解锁器 - 引导程序 v3.2.1'
            'detecting_os' = '正在检测平台...'
            'os_unsupported' = '此引导程序仅支持 Windows。'
            'ps_unsupported' = '需要 PowerShell 5.1 或更高版本（您当前为 {0}）。'
            'downloading_exe' = '正在从 {1} 下载 {0}...'
            'verify_pe' = '正在验证 EXE 签名 (PE32+ MZ 头)...'
            'verify_sha' = '正在对照 SHA256SUMS.txt 验证 SHA256...'
            'sha_match' = 'SHA256 校验通过。'
            'sha_mismatch' = 'SHA256 不匹配。预期 {0}，实际 {1}。'
            'sha_skip' = 'SHA256SUMS.txt 不可用；跳过哈希校验。'
            'launching_admin' = '正以管理员身份启动 {0}（UAC 提示）...'
            'fallback_header' = 'EXE 启动失败。回退到从 raw/main 获取 unlocker.ps1...'
            'downloading_ps1' = '正在从 {0} 下载 unlocker.ps1...'
            'verify_ps1' = '正在验证 unlocker.ps1（大小 + 内容类型）...'
            'running_ps1' = '正在使用 PowerShell 运行 unlocker.ps1...'
            'all_failed' = '所有尝试均失败。可能原因：'
            'cause_internet' = '  1. 没有网络连接或 GitHub 无法访问'
            'cause_av' = '  2. 杀毒软件阻止了下载'
            'cause_release' = '  3. GitHub 发布资源暂时不可用'
            'cause_local' = '  4. 本地 PowerShell 无法提升为管理员'
            'suggestion' = '建议：'
            'suggest_disable_av' = '  - 暂时禁用实时杀毒保护'
            'suggest_wait' = '  - 等待几分钟后重试（GitHub 可能正在限流）'
            'suggest_release' = '  - 打开 https://github.com/{0}/{1}/releases 并手动下载 EXE'
            'enter_to_exit' = '按回车退出'
            'press_enter_pt' = '按回车退出'
        }
        hi = @{
            'banner' = 'Minecraft Bedrock अनलॉकर - बूटस्ट्रैप v3.2.1'
            'detecting_os' = 'प्लेटफ़ॉर्म का पता लगा रहा है...'
            'os_unsupported' = 'यह बूटस्ट्रैप केवल Windows पर काम करता है।'
            'ps_unsupported' = 'PowerShell 5.1 या नया संस्करण आवश्यक है (आपके पास {0} है)।'
            'downloading_exe' = '{1} से {0} डाउनलोड हो रहा है...'
            'verify_pe' = 'EXE हस्ताक्षर सत्यापित हो रहा है (PE32+ MZ हेडर)...'
            'verify_sha' = 'SHA256SUMS.txt के विरुद्ध SHA256 सत्यापित हो रहा है...'
            'sha_match' = 'SHA256 ठीक है।'
            'sha_mismatch' = 'SHA256 मेल नहीं खाता। अपेक्षित {0}, प्राप्त {1}।'
            'sha_skip' = 'SHA256SUMS.txt अनुपलब्ध; हैश जाँच छोड़ रहे हैं।'
            'launching_admin' = '{0} को व्यवस्थापक के रूप में लॉन्च किया जा रहा है (UAC संकेत)...'
            'fallback_header' = 'EXE लॉन्च विफल। raw/main से unlocker.ps1 पर वापस जा रहे हैं...'
            'downloading_ps1' = '{0} से unlocker.ps1 डाउनलोड हो रहा है...'
            'verify_ps1' = 'unlocker.ps1 सत्यापित हो रहा है (आकार + सामग्री प्रकार)...'
            'running_ps1' = 'unlocker.ps1 को PowerShell के साथ चलाया जा रहा है...'
            'all_failed' = 'सभी प्रयास विफल। संभावित कारण:'
            'cause_internet' = '  1. इंटरनेट कनेक्शन नहीं है या GitHub अप्राप्य है'
            'cause_av' = '  2. एंटीवायरस ने डाउनलोड को ब्लॉक किया'
            'cause_release' = '  3. GitHub रिलीज़ एसेट अस्थायी रूप से अनुपलब्ध हैं'
            'cause_local' = '  4. स्थानीय PowerShell व्यवस्थापक तक नहीं बढ़ा सकता'
            'suggestion' = 'सुझाव:'
            'suggest_disable_av' = '  - रियल-टाइम एंटीवायरस सुरक्षा अस्थायी रूप से अक्षम करें'
            'suggest_wait' = '  - कुछ मिनट प्रतीक्षा करें और पुनः प्रयास करें (GitHub दर सीमित कर रहा हो सकता है)'
            'suggest_release' = '  - https://github.com/{0}/{1}/releases खोलें और EXE मैन्युअल रूप से डाउनलोड करें'
            'enter_to_exit' = 'बाहर निकलने के लिए एंटर दबाएँ'
            'press_enter_pt' = 'बाहर निकलने के लिए एंटर दबाएँ'
        }
        es = @{
            'banner' = 'Minecraft Bedrock Unlocker - bootstrap v3.2.1'
            'detecting_os' = 'Detectando plataforma...'
            'os_unsupported' = 'Este bootstrap sólo funciona en Windows.'
            'ps_unsupported' = 'Se requiere PowerShell 5.1 o más reciente (usted tiene {0}).'
            'downloading_exe' = 'Descargando {0} desde {1}...'
            'verify_pe' = 'Verificando firma del EXE (cabecera PE32+ MZ)...'
            'verify_sha' = 'Verificando SHA256 contra SHA256SUMS.txt...'
            'sha_match' = 'SHA256 correcto.'
            'sha_mismatch' = 'SHA256 no coincide. Esperado {0}, obtenido {1}.'
            'sha_skip' = 'SHA256SUMS.txt no disponible; se omite la comprobación del hash.'
            'launching_admin' = 'Iniciando {0} como Administrador (aviso UAC)...'
            'fallback_header' = 'El EXE no se pudo iniciar. Volviendo a unlocker.ps1 desde raw/main...'
            'downloading_ps1' = 'Descargando unlocker.ps1 desde {0}...'
            'verify_ps1' = 'Verificando unlocker.ps1 (tamaño + tipo de contenido)...'
            'running_ps1' = 'Ejecutando unlocker.ps1 con PowerShell...'
            'all_failed' = 'Todos los intentos fallaron. Posibles causas:'
            'cause_internet' = '  1. Sin conexión a internet o GitHub no está accesible'
            'cause_av' = '  2. El antivirus bloqueó la descarga'
            'cause_release' = '  3. Los activos del release de GitHub no están disponibles temporalmente'
            'cause_local' = '  4. El PowerShell local no puede elevarse a Administrador'
            'suggestion' = 'Sugerencias:'
            'suggest_disable_av' = '  - Desactive temporalmente la protección antivirus en tiempo real'
            'suggest_wait' = '  - Espere unos minutos y vuelva a intentarlo (GitHub puede estar limitando la tasa)'
            'suggest_release' = '  - Abra https://github.com/{0}/{1}/releases y descargue el EXE manualmente'
            'enter_to_exit' = 'Pulse ENTER para salir'
            'press_enter_pt' = 'Pulse ENTER para salir'
        }
        fr = @{
            'banner' = 'Minecraft Bedrock Unlocker - bootstrap v3.2.1'
            'detecting_os' = 'Détection de la plateforme...'
            'os_unsupported' = 'Ce bootstrap ne fonctionne que sur Windows.'
            'ps_unsupported' = 'PowerShell 5.1 ou plus récent est requis (vous avez {0}).'
            'downloading_exe' = 'Téléchargement de {0} depuis {1}...'
            'verify_pe' = 'Vérification de la signature EXE (en-tête PE32+ MZ)...'
            'verify_sha' = 'Vérification du SHA256 par rapport à SHA256SUMS.txt...'
            'sha_match' = 'SHA256 OK.'
            'sha_mismatch' = 'SHA256 ne correspond pas. Attendu {0}, obtenu {1}.'
            'sha_skip' = 'SHA256SUMS.txt indisponible ; vérification de l''empreinte ignorée.'
            'launching_admin' = 'Lancement de {0} en tant qu''administrateur (invite UAC)...'
            'fallback_header' = 'L''EXE n''a pas pu être lancé. Retour à unlocker.ps1 depuis raw/main...'
            'downloading_ps1' = 'Téléchargement de unlocker.ps1 depuis {0}...'
            'verify_ps1' = 'Vérification de unlocker.ps1 (taille + type de contenu)...'
            'running_ps1' = 'Exécution de unlocker.ps1 avec PowerShell...'
            'all_failed' = 'Toutes les tentatives ont échoué. Causes possibles :'
            'cause_internet' = '  1. Pas de connexion Internet ou GitHub inaccessible'
            'cause_av' = '  2. L''antivirus a bloqué le téléchargement'
            'cause_release' = '  3. Les ressources du release GitHub sont temporairement indisponibles'
            'cause_local' = '  4. Le PowerShell local ne peut pas être élevé en administrateur'
            'suggestion' = 'Suggestions :'
            'suggest_disable_av' = '  - Désactivez temporairement la protection antivirus en temps réel'
            'suggest_wait' = '  - Attendez quelques minutes et réessayez (GitHub peut limiter le débit)'
            'suggest_release' = '  - Ouvrez https://github.com/{0}/{1}/releases et téléchargez l''EXE manuellement'
            'enter_to_exit' = 'Appuyez sur ENTRÉE pour quitter'
            'press_enter_pt' = 'Appuyez sur ENTRÉE pour quitter'
        }
        ar = @{
            'banner' = 'Minecraft Bedrock Unlocker - مُحمِّل v3.2.1'
            'detecting_os' = 'جارٍ اكتشاف النظام الأساسي...'
            'os_unsupported' = 'هذا المُحمِّل يعمل فقط على Windows.'
            'ps_unsupported' = 'مطلوب PowerShell 5.1 أو أحدث (لديك {0}).'
            'downloading_exe' = 'جارٍ تنزيل {0} من {1}...'
            'verify_pe' = 'جارٍ التحقق من توقيع EXE (ترويسة PE32+ MZ)...'
            'verify_sha' = 'جارٍ التحقق من SHA256 مقابل SHA256SUMS.txt...'
            'sha_match' = 'SHA256 سليم.'
            'sha_mismatch' = 'SHA256 غير متطابق. متوقع {0}، تم الحصول على {1}.'
            'sha_skip' = 'SHA256SUMS.txt غير متوفر؛ يتم تخطي فحص التجزئة.'
            'launching_admin' = 'جارٍ تشغيل {0} كمسؤول (موجه UAC)...'
            'fallback_header' = 'فشل تشغيل EXE. الرجوع إلى unlocker.ps1 من raw/main...'
            'downloading_ps1' = 'جارٍ تنزيل unlocker.ps1 من {0}...'
            'verify_ps1' = 'جارٍ التحقق من unlocker.ps1 (الحجم + نوع المحتوى)...'
            'running_ps1' = 'جارٍ تشغيل unlocker.ps1 باستخدام PowerShell...'
            'all_failed' = 'فشلت جميع المحاولات. الأسباب المحتملة:'
            'cause_internet' = '  1. لا يوجد اتصال بالإنترنت أو GitHub غير متاح'
            'cause_av' = '  2. قام برنامج مكافحة الفيروسات بحظر التنزيل'
            'cause_release' = '  3. أصول إصدار GitHub غير متاحة مؤقتاً'
            'cause_local' = '  4. لا يستطيع PowerShell المحلي الارتفاع إلى صلاحية المسؤول'
            'suggestion' = 'اقتراحات:'
            'suggest_disable_av' = '  - قم بتعطيل الحماية في الوقت الفعلي من برنامج مكافحة الفيروسات مؤقتاً'
            'suggest_wait' = '  - انتظر بضع دقائق وأعد المحاولة (قد يكون GitHub يحد من المعدل)'
            'suggest_release' = '  - افتح https://github.com/{0}/{1}/releases وقم بتنزيل EXE يدوياً'
            'enter_to_exit' = 'اضغط مفتاح الإدخال للخروج'
            'press_enter_pt' = 'اضغط مفتاح الإدخال للخروج'
        }
        ru = @{
            'banner' = 'Minecraft Bedrock Unlocker - загрузчик v3.2.1'
            'detecting_os' = 'Определение платформы...'
            'os_unsupported' = 'Этот загрузчик работает только в Windows.'
            'ps_unsupported' = 'Требуется PowerShell 5.1 или новее (у вас {0}).'
            'downloading_exe' = 'Загрузка {0} из {1}...'
            'verify_pe' = 'Проверка подписи EXE (заголовок PE32+ MZ)...'
            'verify_sha' = 'Проверка SHA256 по SHA256SUMS.txt...'
            'sha_match' = 'SHA256 в порядке.'
            'sha_mismatch' = 'SHA256 не совпадает. Ожидалось {0}, получено {1}.'
            'sha_skip' = 'SHA256SUMS.txt недоступен; проверка хеша пропущена.'
            'launching_admin' = 'Запуск {0} от имени администратора (запрос UAC)...'
            'fallback_header' = 'Не удалось запустить EXE. Возврат к unlocker.ps1 из raw/main...'
            'downloading_ps1' = 'Загрузка unlocker.ps1 из {0}...'
            'verify_ps1' = 'Проверка unlocker.ps1 (размер + тип содержимого)...'
            'running_ps1' = 'Запуск unlocker.ps1 с помощью PowerShell...'
            'all_failed' = 'Все попытки не удались. Возможные причины:'
            'cause_internet' = '  1. Нет подключения к Интернету или GitHub недоступен'
            'cause_av' = '  2. Антивирус заблокировал загрузку'
            'cause_release' = '  3. Файлы релиза GitHub временно недоступны'
            'cause_local' = '  4. Локальный PowerShell не может быть повышен до администратора'
            'suggestion' = 'Рекомендации:'
            'suggest_disable_av' = '  - Временно отключите антивирусную защиту в реальном времени'
            'suggest_wait' = '  - Подождите несколько минут и повторите попытку (GitHub может ограничивать скорость)'
            'suggest_release' = '  - Откройте https://github.com/{0}/{1}/releases и скачайте EXE вручную'
            'enter_to_exit' = 'Нажмите ВВОД для выхода'
            'press_enter_pt' = 'Нажмите ВВОД для выхода'
        }
    }
    $fmt = $table[$lang][$Key]
    if (-not $fmt) { return $Key }
    return $fmt
}

function Write-Banner {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host (' ' + (T 'banner')) -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ''
}

function Write-Info {
    param([string]$Msg)
    Write-Host "[$Script:Version] $Msg"
}

function Write-Err {
    param([string]$Msg)
    Write-Host "[$Script:Version][ERROR] $Msg" -ForegroundColor Red
}

function Write-Warn {
    param([string]$Msg)
    Write-Host "[$Script:Version][WARN] $Msg" -ForegroundColor Yellow
}

function Write-OK {
    param([string]$Msg)
    Write-Host "[$Script:Version][OK] $Msg" -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Network helpers
# ---------------------------------------------------------------------------

function Get-DownloadFolder {
    # Use TEMP: Windows Defender is less aggressive there, and we add it to exclusions below.
    $tempParent = Join-Path ([System.IO.Path]::GetTempPath()) 'MinecraftBedrockUnlocker'
    if (-not (Test-Path -LiteralPath $tempParent)) {
        New-Item -ItemType Directory -Path $tempParent -Force | Out-Null
    }
    try { Add-MpPreference -ExclusionPath $tempParent -ErrorAction SilentlyContinue } catch { }
    return $tempParent
}

function Get-NoCacheHeaders {
    return @{
        'Cache-Control' = 'no-cache, no-store, max-age=0'
        'Pragma'        = 'no-cache'
        'Expires'       = '0'
        'User-Agent'    = "MinecraftBedrockUnlockerBootstrap/$($Script:Version)"
        'Accept'        = '*/*'
    }
}

function New-CacheBustedUrl {
    param([Parameter(Mandatory=$true)][string]$Url)
    $sep = if ($Url.Contains('?')) { '&' } else { '?' }
    return ('{0}{1}cb={2}' -f $Url, $sep, [guid]::NewGuid().ToString('N'))
}

function Invoke-HttpGet {
    param(
        [Parameter(Mandatory=$true)][string]$Url,
        [string]$OutFile,
        [int]$TimeoutSec = 180,
        [int]$MaxRedirection = 5
    )
    $h = Get-NoCacheHeaders
    $u = New-CacheBustedUrl $Url
    $args = @{
        Uri         = $u
        Headers     = $h
        UseBasicParsing = $true
        MaximumRedirection = $MaxRedirection
        TimeoutSec  = $TimeoutSec
    }
    if ($OutFile) { $args.OutFile = $OutFile }
    return Invoke-WebRequest @args
}

function Test-UrlReachable {
    param([Parameter(Mandatory=$true)][string]$Url)
    try {
        $r = Invoke-HttpGet -Url $Url -TimeoutSec 15 -MaximumRedirection 5
        return ($r.StatusCode -ge 200 -and $r.StatusCode -lt 400)
    } catch {
        return $false
    }
}

# ---------------------------------------------------------------------------
# Verification helpers
# ---------------------------------------------------------------------------

function Test-PeSignature {
    param([Parameter(Mandatory=$true)][string]$Path)
    $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try {
        if ($stream.Length -lt 2) { return $false }
        $header = New-Object byte[] 2
        $read = $stream.Read($header, 0, $header.Length)
        return ($read -eq 2 -and $header[0] -eq 0x4d -and $header[1] -eq 0x5a)
    } finally {
        $stream.Dispose()
    }
}

function Get-FileSha256Hex {
    param([Parameter(Mandatory=$true)][string]$Path)
    try {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $stream = [System.IO.File]::OpenRead($Path)
        try {
            $hashBytes = $sha.ComputeHash($stream)
            return -join ($hashBytes | ForEach-Object { $_.ToString('x2') })
        } finally {
            $stream.Dispose()
            $sha.Dispose()
        }
    } catch {
        return $null
    }
}

function Get-Sha256FromSumsFile {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$FileName
    )
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $line = Get-Content -LiteralPath $Path | Where-Object { $_ -match ("\s{0}$" -f [regex]::Escape($FileName)) } | Select-Object -First 1
    if (-not $line) { return $null }
    $parts = $line.Trim() -split '\s+', 2
    if ($parts.Count -lt 2) { return $null }
    return $parts[0].ToLowerInvariant()
}

function Test-PsScriptHeader {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $size = (Get-Item -LiteralPath $Path).Length
    if ($size -lt 10000) { return $false }   # unlocker.ps1 is ~190KB
    try {
        $head = Get-Content -LiteralPath $Path -TotalCount 5 -ErrorAction Stop | Out-String
        $trim = $head.TrimStart()
        return ($trim.StartsWith('<#') -or $trim.StartsWith('#') -or $trim.StartsWith('param('))
    } catch {
        return $false
    }
}

# ---------------------------------------------------------------------------
# Main flow
# ---------------------------------------------------------------------------

function Start-Bootstrap {
    Write-Banner

    # 1. OS check
    Write-Info (T 'detecting_os')
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
        Write-Err (T 'os_unsupported')
        exit 2
    }

    # 2. PowerShell version check
    $psv = $PSVersionTable.PSVersion
    if ($psv.Major -lt 5) {
        Write-Err ((T 'ps_unsupported') -f $psv.ToString())
        exit 2
    }
    Write-OK "PowerShell $($psv.ToString()) on Windows."

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls13
    } catch { }
    [Net.ServicePointManager]::Expect100Continue = $false

    $tempParent = Get-DownloadFolder
    $runFolder = Join-Path $tempParent ([guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $runFolder -Force | Out-Null

    $exePath = Join-Path $runFolder $Script:ExeName

    # 3. Download EXE (skip if -SkipExe)
    if (-not $SkipExe) {
        $urlsToTry = @($Script:ReleaseExeUrl, $Script:RawMainExeUrl)
        $downloaded = $false
        $lastError = $null

        foreach ($url in $urlsToTry) {
            try {
                Write-Info ((T 'downloading_exe') -f $Script:ExeName, $url)
                if (Test-Path -LiteralPath $exePath) {
                    Remove-Item -LiteralPath $exePath -Force -ErrorAction SilentlyContinue
                }
                Invoke-HttpGet -Url $url -OutFile $exePath -TimeoutSec 240 | Out-Null
                $item = Get-Item -LiteralPath $exePath
                if ($item.Length -lt 5000000) {
                    throw "Download is too small ($($item.Length) bytes). Expected >= 5MB."
                }
                Write-Info (T 'verify_pe')
                if (-not (Test-PeSignature -Path $exePath)) {
                    throw 'Downloaded file is not a valid Windows executable (MZ header missing).'
                }
                Write-OK "EXE downloaded ($([math]::Round($item.Length/1MB,2)) MB) and PE signature OK."

                # 4. SHA256 verify (best-effort)
                Write-Info (T 'verify_sha')
                try {
                    $sumsTmp = Join-Path $runFolder 'SHA256SUMS.txt'
                    Invoke-HttpGet -Url $Script:Sha256SumsUrl -OutFile $sumsTmp -TimeoutSec 30 | Out-Null
                    $expected = Get-Sha256FromSumsFile -Path $sumsTmp -FileName $Script:ExeName
                    if ($expected) {
                        $actual = Get-FileSha256Hex -Path $exePath
                        if ($actual -eq $expected) {
                            Write-OK (T 'sha_match')
                        } else {
                            Write-Warn ((T 'sha_mismatch') -f $expected, $actual)
                        }
                    } else {
                        Write-Warn (T 'sha_skip')
                    }
                } catch {
                    Write-Warn (T 'sha_skip')
                }

                # 5. Launch as Administrator
                Write-Info ((T 'launching_admin') -f $Script:ExeName)
                try {
                    $proc = Start-Process -FilePath $exePath -Verb RunAs -PassThru
                    if ($proc) {
                        Write-OK "EXE launched (PID $($proc.Id)). Bootstrap exiting successfully."
                        exit 0
                    } else {
                        throw 'Start-Process returned no process.'
                    }
                } catch {
                    $lastError = $_
                    Write-Warn "EXE launch failed: $($_.Exception.Message)"
                }
            } catch {
                $lastError = $_
                Write-Warn "Download from $url failed: $($_.Exception.Message)"
                continue
            }
        }

        # If we reach here, EXE path failed entirely.
        Write-Err (T 'fallback_header')
    }

    # 6. Fallback: run unlocker.ps1
    # v3.2.0: try release first, then raw/main automatically. The CoelhoFZ
    # release often ships only the EXE, so raw/main is the reliable source.
    $ps1Candidates = @(
        "$($Script:ReleaseFallbackUrl)/unlocker.ps1",
        "$($Script:RawMainUrl)/unlocker.ps1"
    )
    if ($UseRawMain) {
        $ps1Candidates = @("$($Script:RawMainUrl)/unlocker.ps1")
    }
    $ps1Downloaded = $false
    $ps1LastError = $null
    foreach ($ps1Url in $ps1Candidates) {
        try {
            Write-Info ((T 'downloading_ps1') -f $ps1Url)
            $ps1Path = Join-Path $runFolder 'unlocker.ps1'
            if (Test-Path -LiteralPath $ps1Path) {
                Remove-Item -LiteralPath $ps1Path -Force -ErrorAction SilentlyContinue
            }
            Invoke-HttpGet -Url $ps1Url -OutFile $ps1Path -TimeoutSec 120 | Out-Null
            Write-Info (T 'verify_ps1')
            if (-not (Test-PsScriptHeader -Path $ps1Path)) {
                throw "Downloaded unlocker.ps1 looks invalid (size=$(if (Test-Path -LiteralPath $ps1Path) { (Get-Item -LiteralPath $ps1Path).Length } else { 0 }))."
            }
            Write-OK "unlocker.ps1 downloaded from $ps1Url and looks valid."
            $ps1Downloaded = $true
            $finalPs1Path = $ps1Path
            break
        } catch {
            $ps1LastError = $_
            Write-Warn "Download from $ps1Url failed: $($_.Exception.Message)"
            continue
        }
    }

    if ($ps1Downloaded) {
        Write-Info (T 'running_ps1')
        try {
            # Use Start-Process without -Wait so the bootstrap can return immediately
            # (the unlocker.ps1 is interactive and needs its own console).
            Start-Process -FilePath $finalPs1Path -Verb RunAs
            Write-OK "unlocker.ps1 launched (it will run in its own Administrator window)."
            exit 0
        } catch {
            Write-Err "Failed to launch unlocker.ps1: $($_.Exception.Message)"
        }
    } else {
        Write-Err "All unlocker.ps1 download attempts failed."
        if ($ps1LastError) { Write-Err "Last error: $($ps1LastError.Exception.Message)" }
    }

    # 7. Final error message with troubleshooting hints
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host '[v3.2.1] ' (T 'all_failed') -ForegroundColor Red
    Write-Host (T 'cause_internet')  -ForegroundColor Yellow
    Write-Host (T 'cause_av')        -ForegroundColor Yellow
    Write-Host (T 'cause_release')   -ForegroundColor Yellow
    Write-Host (T 'cause_local')     -ForegroundColor Yellow
    Write-Host ''
    Write-Host (T 'suggestion') -ForegroundColor Cyan
    Write-Host (T 'suggest_disable_av') -ForegroundColor White
    Write-Host (T 'suggest_wait')       -ForegroundColor White
    Write-Host ((T 'suggest_release') -f $Script:RepoOwner, $Script:RepoName) -ForegroundColor White
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host ''
    # Skip Read-Host in non-interactive contexts (SSH, scheduled tasks, CI).
    if ($Host.Name -ne 'ServerHost' -and $Host.UI.RawUI) {
        if ((Detect-Lang) -eq 'pt') {
            Read-Host (T 'press_enter_pt')
        } else {
            Read-Host (T 'enter_to_exit')
        }
    }
    exit 1
}

# ---------------------------------------------------------------------------
# Entry
# ---------------------------------------------------------------------------

try {
    Start-Bootstrap
} catch {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host '[v3.2.1] FATAL: ' $_.Exception.Message -ForegroundColor Red
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host ''
    if ($Host.Name -ne 'ServerHost' -and $Host.UI.RawUI) {
        if ((Detect-Lang) -eq 'pt') {
            Read-Host (T 'press_enter_pt')
        } else {
            Read-Host (T 'enter_to_exit')
        }
    }
    exit 1
}
