$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

# Multi7 i18n: detect OS culture (en, zh, hi, es, fr, ar, ru)
$Script:Lang = 'en'
try {
    $c = (Get-Culture).Name
    switch -Wildcard ($c) {
        'zh-*' { $Script:Lang = 'zh' }
        'hi-*' { $Script:Lang = 'hi' }
        'es-*' { $Script:Lang = 'es' }
        'fr-*' { $Script:Lang = 'fr' }
        'ar-*' { $Script:Lang = 'ar' }
        'ru-*' { $Script:Lang = 'ru' }
        default { $Script:Lang = 'en' }
    }
} catch { }

$Script:Msg = @{
    en = @{
        errTitle    = 'ERROR'
        errGeneric  = 'The bootstrap failed. Possible causes:'
        cause1      = '  1. No internet connection or GitHub is unreachable'
        cause2      = '  2. Antivirus blocked the download'
        cause3      = '  3. The release asset was not found (try again later)'
        pressEnter  = 'Press ENTER to exit'
        downloading = 'Downloading MinecraftBedrockUnlocker.exe to {0}...'
        verified    = 'EXE verified (PE signature OK). Starting as Administrator...'
        notSaved    = 'EXE was not saved'
        tooSmall    = 'Download is too small ({0} bytes)'
        notExe      = 'Downloaded file is not a valid Windows executable'
        allFailed   = '[MBU] All download attempts failed.'
        lastError   = '[MBU] Last error: {0}'
        tempLocked  = 'TEMP FILE LOCK DETECTED.'
        tempLocked2 = 'A previous download or antivirus scan kept the EXE locked.'
        tempLocked3 = 'This launcher now uses a unique temp folder on each attempt.'
        tempLocked4 = 'Run the command again so PowerShell fetches the updated e.ps1 from GitHub.'
        defBlocked  = 'WINDOWS DEFENDER IS BLOCKING THE FILE!'
        defBlocked2 = 'The file was downloaded but Windows Defender blocked access to it.'
        defFixTitle = 'QUICK FIX - Run this command as Administrator, then try again:'
        defFixCmd   = '  Add-MpPreference -ExclusionPath "{0}"'
        defFixOr    = 'OR: Temporarily disable Real-time protection in Windows Security,'
        defFixOr2   = '     run this script, then re-enable it after.'
        generic     = 'Check your internet connection and try again.'
        generic2    = 'If the problem persists, the GitHub release may be unavailable.'
    }
    zh = @{
        errTitle    = '错误'
        errGeneric  = '引导失败。可能原因：'
        cause1      = '  1. 没有网络连接或 GitHub 无法访问'
        cause2      = '  2. 杀毒软件阻止了下载'
        cause3      = '  3. 找不到发布资源（稍后重试）'
        pressEnter  = '按回车退出'
        downloading = '正在下载 MinecraftBedrockUnlocker.exe 到 {0}...'
        verified    = 'EXE 验证通过（PE 签名正常）。正在以管理员身份启动...'
        notSaved    = 'EXE 未保存'
        tooSmall    = '下载文件太小（{0} 字节）'
        notExe      = '下载的文件不是有效的 Windows 可执行文件'
        allFailed   = '[MBU] 所有下载尝试均失败。'
        lastError   = '[MBU] 最后一个错误：{0}'
        tempLocked  = '检测到临时文件锁定。'
        tempLocked2 = '之前的下载或杀毒软件扫描锁定了该 EXE。'
        tempLocked3 = '此启动器现在每次都使用唯一的临时文件夹。'
        tempLocked4 = '再次运行该命令，让 PowerShell 从 GitHub 拉取最新的 e.ps1。'
        defBlocked  = 'WINDOWS DEFENDER 正在阻止该文件！'
        defBlocked2 = '文件已下载，但 Windows Defender 阻止了对它的访问。'
        defFixTitle = '快速修复 - 以管理员身份运行此命令，然后重试：'
        defFixCmd   = '  Add-MpPreference -ExclusionPath "{0}"'
        defFixOr    = '或者：在 Windows 安全中心临时禁用实时保护，'
        defFixOr2   = '     运行此脚本，完成后重新启用。'
        generic     = '检查您的网络连接并重试。'
        generic2    = '如果问题仍然存在，GitHub 发布可能不可用。'
    }
    hi = @{
        errTitle    = 'त्रुटि'
        errGeneric  = 'बूटस्ट्रैप विफल। संभावित कारण:'
        cause1      = '  1. इंटरनेट कनेक्शन नहीं है या GitHub अप्राप्य है'
        cause2      = '  2. एंटीवायरस ने डाउनलोड को ब्लॉक किया'
        cause3      = '  3. रिलीज़ एसेट नहीं मिला (बाद में पुनः प्रयास करें)'
        pressEnter  = 'बाहर निकलने के लिए एंटर दबाएँ'
        downloading = 'MinecraftBedrockUnlocker.exe को {0} पर डाउनलोड हो रहा है...'
        verified    = 'EXE सत्यापित (PE हस्ताक्षर ठीक है)। व्यवस्थापक के रूप में शुरू हो रहा है...'
        notSaved    = 'EXE सहेजा नहीं गया'
        tooSmall    = 'डाउनलोड बहुत छोटा है ({0} बाइट्स)'
        notExe      = 'डाउनलोड की गई फ़ाइल मान्य Windows निष्पादन योग्य नहीं है'
        allFailed   = '[MBU] सभी डाउनलोड प्रयास विफल।'
        lastError   = '[MBU] अंतिम त्रुटि: {0}'
        tempLocked  = 'अस्थायी फ़ाइल लॉक का पता चला।'
        tempLocked2 = 'पिछला डाउनलोड या एंटीवायरस स्कैन ने EXE को लॉक कर दिया।'
        tempLocked3 = 'यह लॉन्चर अब हर प्रयास पर एक अद्वितीय अस्थायी फ़ोल्डर का उपयोग करता है।'
        tempLocked4 = 'कमांड को फिर से चलाएँ ताकि PowerShell GitHub से अद्यतन e.ps1 प्राप्त कर सके।'
        defBlocked  = 'WINDOWS DEFENDER फ़ाइल को ब्लॉक कर रहा है!'
        defBlocked2 = 'फ़ाइल डाउनलोड हो गई लेकिन Windows Defender ने उस तक पहुँच को ब्लॉक कर दिया।'
        defFixTitle = 'त्वरित समाधान - व्यवस्थापक के रूप में यह कमांड चलाएँ, फिर पुनः प्रयास करें:'
        defFixCmd   = '  Add-MpPreference -ExclusionPath "{0}"'
        defFixOr    = 'या: Windows सुरक्षा में रियल-टाइम सुरक्षा को अस्थायी रूप से अक्षम करें,'
        defFixOr2   = '     यह स्क्रिप्ट चलाएँ, फिर बाद में फिर से सक्षम करें।'
        generic     = 'अपना इंटरनेट कनेक्शन जाँचें और पुनः प्रयास करें।'
        generic2    = 'यदि समस्या बनी रहती है, तो GitHub रिलीज़ अनुपलब्ध हो सकती है।'
    }
    es = @{
        errTitle    = 'ERROR'
        errGeneric  = 'El bootstrap fallo. Posibles causas:'
        cause1      = '  1. Sin conexion a internet o GitHub no accesible'
        cause2      = '  2. El antivirus bloqueo la descarga'
        cause3      = '  3. No se encontro el asset del release (intentalo mas tarde)'
        pressEnter  = 'Presione ENTER para salir'
        downloading = 'Descargando MinecraftBedrockUnlocker.exe a {0}...'
        verified    = 'EXE verificado (firma PE OK). Iniciando como Administrador...'
        notSaved    = 'EXE no se guardo'
        tooSmall    = 'La descarga es demasiado pequena ({0} bytes)'
        notExe      = 'El archivo descargado no es un ejecutable de Windows valido'
        allFailed   = '[MBU] Todos los intentos de descarga fallaron.'
        lastError   = '[MBU] Ultimo error: {0}'
        tempLocked  = 'BLOQUEO DE ARCHIVO TEMPORAL DETECTADO.'
        tempLocked2 = 'Una descarga anterior o el analisis del antivirus mantuvo el EXE bloqueado.'
        tempLocked3 = 'Este launcher ahora usa una carpeta temporal unica en cada intento.'
        tempLocked4 = 'Ejecuta el comando de nuevo para que PowerShell obtenga el e.ps1 actualizado de GitHub.'
        defBlocked  = 'WINDOWS DEFENDER ESTA BLOQUEANDO EL ARCHIVO!'
        defBlocked2 = 'El archivo se descargo pero Windows Defender bloqueo el acceso.'
        defFixTitle = 'SOLUCION RAPIDA - Ejecuta este comando como Administrador, luego reintenta:'
        defFixCmd   = '  Add-MpPreference -ExclusionPath "{0}"'
        defFixOr    = 'O: Desactiva temporalmente la proteccion en tiempo real en Windows Security,'
        defFixOr2   = '     ejecuta este script, luego reactivala.'
        generic     = 'Verifica tu conexion a internet y reintenta.'
        generic2    = 'Si el problema persiste, el release de GitHub puede no estar disponible.'
    }
    fr = @{
        errTitle    = 'ERREUR'
        errGeneric  = 'Echec du bootstrap. Causes possibles:'
        cause1      = '  1. Pas de connexion Internet ou GitHub injoignable'
        cause2      = '  2. L antivirus a bloque le telechargement'
        cause3      = '  3. La ressource du release est introuvable (reessayez plus tard)'
        pressEnter  = 'Appuyez sur ENTREE pour quitter'
        downloading = 'Telechargement de MinecraftBedrockUnlocker.exe vers {0}...'
        verified    = 'EXE verifie (signature PE OK). Demarrage en tant qu Administrateur...'
        notSaved    = 'EXE non enregistre'
        tooSmall    = 'Telechargement trop petit ({0} octets)'
        notExe      = 'Le fichier telecharge n est pas un executable Windows valide'
        allFailed   = '[MBU] Toutes les tentatives de telechargement ont echoue.'
        lastError   = '[MBU] Derniere erreur: {0}'
        tempLocked  = 'VERROU DE FICHIER TEMPORAIRE DETECTE.'
        tempLocked2 = 'Un telechargement precedent ou une analyse antivirus a verouille l EXE.'
        tempLocked3 = 'Ce lanceur utilise maintenant un dossier temporaire unique a chaque tentative.'
        tempLocked4 = 'Reexecutez la commande pour que PowerShell recupere le e.ps1 mis a jour depuis GitHub.'
        defBlocked  = 'WINDOWS DEFENDER BLOQUE LE FICHIER !'
        defBlocked2 = 'Le fichier a ete telecharge mais Windows Defender en a bloque l acces.'
        defFixTitle = 'CORRECTIF RAPIDE - Executez cette commande en tant qu Administrateur, puis reessayez :'
        defFixCmd   = '  Add-MpPreference -ExclusionPath "{0}"'
        defFixOr    = 'OU: Desactivez temporairement la protection en temps reel dans Windows Security,'
        defFixOr2   = '     executez ce script, puis reactivez-la.'
        generic     = 'Verifiez votre connexion Internet et reessayez.'
        generic2    = 'Si le probleme persiste, le release GitHub est peut-etre indisponible.'
    }
    ar = @{
        errTitle    = 'خطأ'
        errGeneric  = 'فشل التمهيد. الأسباب المحتملة:'
        cause1      = '  1. لا يوجد اتصال بالإنترنت أو GitHub غير متاح'
        cause2      = '  2. قام برنامج مكافحة الفيروسات بحظر التنزيل'
        cause3      = '  3. لم يتم العثور على أصل الإصدار (حاول مرة أخرى لاحقًا)'
        pressEnter  = 'اضغط مفتاح الإدخال للخروج'
        downloading = 'تنزيل MinecraftBedrockUnlocker.exe إلى {0}...'
        verified    = 'تم التحقق من EXE (توقيع PE سليم). البدء كمسؤول...'
        notSaved    = 'لم يتم حفظ EXE'
        tooSmall    = 'التنزيل صغير جدًا ({0} بايت)'
        notExe      = 'الملف الذي تم تنزيله ليس ملفًا تنفيذيًا صالحًا لنظام Windows'
        allFailed   = '[MBU] فشلت جميع محاولات التنزيل.'
        lastError   = '[MBU] الخطأ الأخير: {0}'
        tempLocked  = 'تم اكتشاف قفل ملف مؤقت.'
        tempLocked2 = 'تنزيل سابق أو فحص برنامج مكافحة الفيروسات أبقى على EXE مغلقًا.'
        tempLocked3 = 'يستخدم هذا المشغل الآن مجلدًا مؤقتًا فريدًا في كل محاولة.'
        tempLocked4 = 'قم بتشغيل الأمر مرة أخرى حتى يقوم PowerShell بجلب e.ps1 المحدّث من GitHub.'
        defBlocked  = 'يقوم WINDOWS DEFENDER بحظر الملف!'
        defBlocked2 = 'تم تنزيل الملف لكن Windows Defender منع الوصول إليه.'
        defFixTitle = 'إصلاح سريع - قم بتشغيل هذا الأمر كمسؤول، ثم حاول مرة أخرى:'
        defFixCmd   = '  Add-MpPreference -ExclusionPath "{0}"'
        defFixOr    = 'أو: قم بتعطيل الحماية في الوقت الفعلي مؤقتًا في Windows Security،'
        defFixOr2   = '     قم بتشغيل هذا البرنامج النصي، ثم أعد تمكينه بعد ذلك.'
        generic     = 'تحقق من اتصالك بالإنترنت وحاول مرة أخرى.'
        generic2    = 'إذا استمرت المشكلة، فقد يكون إصدار GitHub غير متاح.'
    }
    ru = @{
        errTitle    = 'ОШИБКА'
        errGeneric  = 'Сбой загрузчика. Возможные причины:'
        cause1      = '  1. Нет подключения к интернету или GitHub недоступен'
        cause2      = '  2. Антивирус заблокировал загрузку'
        cause3      = '  3. Файл релиза не найден (попробуйте позже)'
        pressEnter  = 'Нажмите ВВОД для выхода'
        downloading = 'Загрузка MinecraftBedrockUnlocker.exe в {0}...'
        verified    = 'EXE проверен (подпись PE в порядке). Запуск от имени администратора...'
        notSaved    = 'EXE не сохранён'
        tooSmall    = 'Загрузка слишком мала ({0} байт)'
        notExe      = 'Загруженный файл не является допустимым исполняемым файлом Windows'
        allFailed   = '[MBU] Все попытки загрузки не удались.'
        lastError   = '[MBU] Последняя ошибка: {0}'
        tempLocked  = 'ОБНАРУЖЕНА БЛОКИРОВКА ВРЕМЕННОГО ФАЙЛА.'
        tempLocked2 = 'Предыдущая загрузка или антивирусное сканирование заблокировали EXE.'
        tempLocked3 = 'Этот загрузчик теперь использует уникальную временную папку при каждой попытке.'
        tempLocked4 = 'Запустите команду снова, чтобы PowerShell получил обновлённый e.ps1 с GitHub.'
        defBlocked  = 'WINDOWS DEFENDER БЛОКИРУЕТ ФАЙЛ!'
        defBlocked2 = 'Файл загружен, но Windows Defender заблокировал к нему доступ.'
        defFixTitle = 'БЫСТРОЕ ИСПРАВЛЕНИЕ - Запустите эту команду от имени администратора, затем повторите:'
        defFixCmd   = '  Add-MpPreference -ExclusionPath "{0}"'
        defFixOr    = 'ИЛИ: Временно отключите защиту в реальном времени в Windows Security,'
        defFixOr2   = '     запустите этот скрипт, затем снова включите её.'
        generic     = 'Проверьте подключение к интернету и повторите попытку.'
        generic2    = 'Если проблема не исчезнет, релиз GitHub может быть недоступен.'
    }
}

trap {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host '[MBU] ' $Script:Msg[$Script:Lang].errTitle ':' $_.Exception.Message -ForegroundColor Red
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host ''
    Write-Host $Script:Msg[$Script:Lang].errGeneric -ForegroundColor Yellow
    Write-Host $Script:Msg[$Script:Lang].cause1 -ForegroundColor Yellow
    Write-Host $Script:Msg[$Script:Lang].cause2 -ForegroundColor Yellow
    Write-Host $Script:Msg[$Script:Lang].cause3 -ForegroundColor Yellow
    Write-Host ''
    Read-Host $Script:Msg[$Script:Lang].pressEnter
    break
}

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'MinecraftBedrockUnlocker.exe must be run on Windows.'
}

$ReleaseBase = 'https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest/download'
$Headers = @{
    'Cache-Control' = 'no-cache, no-store, max-age=0'
    'Pragma' = 'no-cache'
    'Expires' = '0'
    'User-Agent' = 'MinecraftBedrockUnlockerShortExe'
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Get-DownloadFolder {
    # Use TEMP instead of Downloads: Windows Defender is less aggressive scanning temp files,
    # and the EXE already adds %TEMP%\MinecraftBedrockUnlocker to Defender exclusions.
    $tempParent = Join-Path ([System.IO.Path]::GetTempPath()) 'MinecraftBedrockUnlocker'
    if (-not (Test-Path -LiteralPath $tempParent)) {
        New-Item -ItemType Directory -Path $tempParent -Force | Out-Null
    }
    # Best-effort: try to add Defender exclusion (may fail if not admin - that's OK)
    try { Add-MpPreference -ExclusionPath $tempParent -ErrorAction SilentlyContinue } catch { }
    return $tempParent
}

function New-RunDownloadFolder {
    param([Parameter(Mandatory = $true)][string]$ParentFolder)

    $runFolder = Join-Path $ParentFolder ([guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $runFolder -Force | Out-Null
    return $runFolder
}

function Wait-FileReady {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [int]$Retries = 12,
        [int]$DelayMilliseconds = 250
    )

    for ($try = 1; $try -le $Retries; $try++) {
        try {
            $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
            try {
                return
            } finally {
                $stream.Dispose()
            }
        } catch {
            if ($try -eq $Retries) {
                throw
            }
            Start-Sleep -Milliseconds $DelayMilliseconds
        }
    }
}

function Test-PeSignature {
    param([Parameter(Mandatory = $true)][string]$Path)

    $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try {
        if ($stream.Length -lt 2) {
            return $false
        }
        $header = New-Object byte[] 2
        $read = $stream.Read($header, 0, $header.Length)
        return ($read -eq 2 -and $header[0] -eq 0x4d -and $header[1] -eq 0x5a)
    } finally {
        $stream.Dispose()
    }
}

$lastError = $null
$downloadFolder = Get-DownloadFolder

for ($attempt = 1; $attempt -le 3; $attempt++) {
    try {
        $runFolder = New-RunDownloadFolder -ParentFolder $downloadFolder
        $exePath = Join-Path $runFolder 'MinecraftBedrockUnlocker.exe'
        $url = "$ReleaseBase/MinecraftBedrockUnlocker.exe`?cb=$([guid]::NewGuid().ToString('N'))"
        Write-Host ("[MBU] " + $Script:Msg[$Script:Lang].downloading -f $exePath)
        Invoke-WebRequest -UseBasicParsing -Headers $Headers -Uri $url -MaximumRedirection 5 -OutFile $exePath
        if (-not (Test-Path -LiteralPath $exePath)) { throw $Script:Msg[$Script:Lang].notSaved }
        $item = Get-Item -LiteralPath $exePath
        if ($item.Length -lt 5000000) { throw ($Script:Msg[$Script:Lang].tooSmall -f $item.Length) }
        Wait-FileReady -Path $exePath
        if (Test-PeSignature -Path $exePath) {
            Write-Host ('[MBU] ' + $Script:Msg[$Script:Lang].verified)
            Start-Process -FilePath $exePath -Verb RunAs
            exit 0
        }
        throw $Script:Msg[$Script:Lang].notExe
    } catch {
        $lastError = $_
        Start-Sleep -Seconds $attempt
    }
}
Write-Host ''
Write-Host '============================================================' -ForegroundColor Red
Write-Host $Script:Msg[$Script:Lang].allFailed -ForegroundColor Red
if ($lastError) {
    $errMsg = $lastError.Exception.Message
    Write-Host ($Script:Msg[$Script:Lang].lastError -f $errMsg) -ForegroundColor Red
}
Write-Host '============================================================' -ForegroundColor Red
Write-Host ''
if ($lastError -and $errMsg -match 'used by another process|sendo usado por outro processo') {
    Write-Host $Script:Msg[$Script:Lang].tempLocked -ForegroundColor Red
    Write-Host $Script:Msg[$Script:Lang].tempLocked2 -ForegroundColor Yellow
    Write-Host $Script:Msg[$Script:Lang].tempLocked3 -ForegroundColor Yellow
    Write-Host $Script:Msg[$Script:Lang].tempLocked4 -ForegroundColor Cyan
} elseif ($lastError -and $errMsg -match 'v.rus|software.*indesej|unwanted|potentially|acesso negado|access.*denied|opera..o.*v.lida') {
    Write-Host $Script:Msg[$Script:Lang].defBlocked -ForegroundColor Red
    Write-Host $Script:Msg[$Script:Lang].defBlocked2 -ForegroundColor Yellow
    Write-Host ''
    Write-Host $Script:Msg[$Script:Lang].defFixTitle -ForegroundColor Cyan
    Write-Host '  Add-MpPreference -ExclusionPath "$downloadFolder"' -ForegroundColor White
    Write-Host ''
    Write-Host $Script:Msg[$Script:Lang].defFixOr -ForegroundColor Yellow
    Write-Host $Script:Msg[$Script:Lang].defFixOr2 -ForegroundColor Yellow
} else {
    Write-Host $Script:Msg[$Script:Lang].generic -ForegroundColor Yellow
    Write-Host $Script:Msg[$Script:Lang].generic2 -ForegroundColor Yellow
}
Write-Host ''
Read-Host 'Press ENTER to exit'
exit 1
