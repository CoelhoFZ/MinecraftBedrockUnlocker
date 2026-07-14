$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

# ── Bootstrap v3.3.1: downloads and executes unlocker.ps1 (NO EXE) ──

trap {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host '[MBU v3.3.1] ERROR:' $_.Exception.Message -ForegroundColor Red
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host ''
    Write-Host 'The bootstrap failed. Possible causes:' -ForegroundColor Yellow
    Write-Host '  1. No internet connection or GitHub is unreachable' -ForegroundColor Yellow
    Write-Host '  2. Antivirus blocked the download' -ForegroundColor Yellow
    Write-Host '  3. PowerShell execution policy is restricted' -ForegroundColor Yellow
    Write-Host ''
    try {
        $prompt = if ($null -ne $Script:Msg -and $null -ne $Script:Lang -and $Script:Msg.ContainsKey($Script:Lang)) { $Script:Msg[$Script:Lang].pressEnter } else { 'Press ENTER to exit' }
        Read-Host $prompt | Out-Null
    } catch {
        Read-Host 'Press ENTER to exit' | Out-Null
    }
    break
}

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'MinecraftBedrockUnlocker must be run on Windows.'
}

# ── Network setup ──
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls13 } catch { }

$ProgressPreference = 'SilentlyContinue'

$Headers = @{
    'Cache-Control' = 'no-cache, no-store, max-age=0'
    'Pragma'        = 'no-cache'
    'Expires'       = '0'
    'User-Agent'    = 'MinecraftBedrockUnlockerBootstrap/3.3.1'
}

$Script:RepoOwner = 'CoelhoFZ'
$Script:RepoName  = 'MinecraftBedrockUnlocker'

# Primary URL (raw, always latest from main)
$Script:RawUrl = "https://raw.githubusercontent.com/$($Script:RepoOwner)/$($Script:RepoName)/main/unlocker.ps1"
# Fallback URL (release asset)
$Script:ReleaseUrl = "https://github.com/$($Script:RepoOwner)/$($Script:RepoName)/releases/latest/download/unlocker.ps1"

# ── Language detection (top 7 worldwide) ──
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
        'pt-*' { $Script:Lang = 'pt' }
        default { $Script:Lang = 'en' }
    }
} catch { }

$Script:Msg = @{
    en = @{
        downloading  = 'Downloading installer from GitHub...'
        starting     = 'Starting Minecraft Bedrock Unlocker...'
        allFailed    = '[MBU] Failed to download the installer.'
        lastError    = '[MBU] Last error: {0}'
        smartScreen  = 'WINDOWS SMARTSCREEN / APP CONTROL IS BLOCKING THE SCRIPT!'
        smartScreen2 = 'Your Windows security policy blocked execution.'
        smartScreen3 = 'This usually happens when PowerShell scripts are restricted.'
        smartFix1    = 'QUICK FIX - Run this command, then try again:'
        smartFix2    = '  Set-ExecutionPolicy Bypass -Scope Process -Force'
        smartFix3    = 'OR: Right-click PowerShell -> Run as Administrator, then paste the install command.'
        generic      = 'Check your internet connection and try again.'
        generic2     = 'If the problem persists, the GitHub servers may be unavailable.'
        pressEnter   = 'Press ENTER to exit'
    }
    zh = @{
        downloading  = '正在从 GitHub 下载安装程序...'
        starting     = '正在启动 Minecraft Bedrock Unlocker...'
        allFailed    = '[MBU] 下载安装程序失败。'
        lastError    = '[MBU] 最后一个错误: {0}'
        smartScreen  = 'WINDOWS SMARTSCREEN / 应用程序控制正在阻止脚本!'
        smartScreen2 = '您的 Windows 安全策略阻止了执行。'
        smartScreen3 = '这通常发生在 PowerShell 脚本受限制时。'
        smartFix1    = '快速修复 - 运行此命令,然后重试:'
        smartFix2    = '  Set-ExecutionPolicy Bypass -Scope Process -Force'
        smartFix3    = '或者:右键单击 PowerShell -> 以管理员身份运行,然后粘贴安装命令。'
        generic      = '检查您的网络连接并重试。'
        generic2     = '如果问题仍然存在,GitHub 服务器可能不可用。'
        pressEnter   = '按回车退出'
    }
    hi = @{
        downloading  = 'GitHub से इंस्टॉलर डाउनलोड हो रहा है...'
        starting     = 'Minecraft Bedrock Unlocker शुरू हो रहा है...'
        allFailed    = '[MBU] इंस्टॉलर डाउनलोड करने में विफल।'
        lastError    = '[MBU] अंतिम त्रुटि: {0}'
        smartScreen  = 'WINDOWS SMARTSCREEN / ऐप कंट्रोल स्क्रिप्ट को ब्लॉक कर रहा है!'
        smartScreen2 = 'आपकी Windows सुरक्षा नीति ने निष्पादन को ब्लॉक कर दिया।'
        smartScreen3 = 'यह आमतौर पर तब होता है जब PowerShell स्क्रिप्ट प्रतिबंधित होती हैं।'
        smartFix1    = 'त्वरित समाधान - यह कमांड चलाएँ, फिर पुनः प्रयास करें:'
        smartFix2    = '  Set-ExecutionPolicy Bypass -Scope Process -Force'
        smartFix3    = 'या: PowerShell पर राइट-क्लिक करें -> व्यवस्थापक के रूप में चलाएँ, फिर इंस्टॉल कमांड पेस्ट करें।'
        generic      = 'अपना इंटरनेट कनेक्शन जाँचें और पुनः प्रयास करें।'
        generic2     = 'यदि समस्या बनी रहती है, तो GitHub सर्वर अनुपलब्ध हो सकते हैं।'
        pressEnter   = 'बाहर निकलने के लिए एंटर दबाएँ'
    }
    es = @{
        downloading  = 'Descargando instalador desde GitHub...'
        starting     = 'Iniciando Minecraft Bedrock Unlocker...'
        allFailed    = '[MBU] Error al descargar el instalador.'
        lastError    = '[MBU] Último error: {0}'
        smartScreen  = '¡WINDOWS SMARTSCREEN / CONTROL DE APLICACIONES ESTÁ BLOQUEANDO EL SCRIPT!'
        smartScreen2 = 'Su política de seguridad de Windows bloqueó la ejecución.'
        smartScreen3 = 'Esto suele ocurrir cuando los scripts de PowerShell están restringidos.'
        smartFix1    = 'SOLUCIÓN RÁPIDA - Ejecute este comando y vuelva a intentarlo:'
        smartFix2    = '  Set-ExecutionPolicy Bypass -Scope Process -Force'
        smartFix3    = 'O: Haga clic derecho en PowerShell -> Ejecutar como administrador, luego pegue el comando de instalación.'
        generic      = 'Compruebe su conexión a internet e inténtelo de nuevo.'
        generic2     = 'Si el problema persiste, los servidores de GitHub pueden no estar disponibles.'
        pressEnter   = 'Pulse ENTER para salir'
    }
    fr = @{
        downloading  = 'Téléchargement de l''installateur depuis GitHub...'
        starting     = 'Démarrage de Minecraft Bedrock Unlocker...'
        allFailed    = '[MBU] Échec du téléchargement de l''installateur.'
        lastError    = '[MBU] Dernière erreur : {0}'
        smartScreen  = 'WINDOWS SMARTSCREEN / CONTRÔLE D''APPLICATION BLOQUE LE SCRIPT !'
        smartScreen2 = 'Votre politique de sécurité Windows a bloqué l''exécution.'
        smartScreen3 = 'Cela se produit généralement lorsque les scripts PowerShell sont restreints.'
        smartFix1    = 'CORRECTIF RAPIDE - Exécutez cette commande, puis réessayez :'
        smartFix2    = '  Set-ExecutionPolicy Bypass -Scope Process -Force'
        smartFix3    = 'OU : Clic droit sur PowerShell -> Exécuter en tant qu''administrateur, puis collez la commande d''installation.'
        generic      = 'Vérifiez votre connexion Internet et réessayez.'
        generic2     = 'Si le problème persiste, les serveurs GitHub sont peut-être indisponibles.'
        pressEnter   = 'Appuyez sur ENTRÉE pour quitter'
    }
    ar = @{
        downloading  = 'جارٍ تنزيل المثبت من GitHub...'
        starting     = 'جارٍ بدء Minecraft Bedrock Unlocker...'
        allFailed    = '[MBU] فشل تنزيل المثبت.'
        lastError    = '[MBU] الخطأ الأخير: {0}'
        smartScreen  = 'WINDOWS SMARTSCREEN / التحكم في التطبيقات يحظر البرنامج النصي!'
        smartScreen2 = 'قامت سياسة أمان Windows بحظر التنفيذ.'
        smartScreen3 = 'يحدث هذا عادةً عندما تكون برامج PowerShell النصية مقيدة.'
        smartFix1    = 'إصلاح سريع - قم بتشغيل هذا الأمر، ثم حاول مرة أخرى:'
        smartFix2    = '  Set-ExecutionPolicy Bypass -Scope Process -Force'
        smartFix3    = 'أو: انقر بزر الماوس الأيمن على PowerShell -> تشغيل كمسؤول، ثم الصق أمر التثبيت.'
        generic      = 'تحقق من اتصالك بالإنترنت وحاول مرة أخرى.'
        generic2     = 'إذا استمرت المشكلة، فقد تكون خوادم GitHub غير متاحة.'
        pressEnter   = 'اضغط مفتاح الإدخال للخروج'
    }
    ru = @{
        downloading  = 'Загрузка установщика с GitHub...'
        starting     = 'Запуск Minecraft Bedrock Unlocker...'
        allFailed    = '[MBU] Не удалось загрузить установщик.'
        lastError    = '[MBU] Последняя ошибка: {0}'
        smartScreen  = 'WINDOWS SMARTSCREEN / КОНТРОЛЬ ПРИЛОЖЕНИЙ БЛОКИРУЕТ СКРИПТ!'
        smartScreen2 = 'Ваша политика безопасности Windows заблокировала выполнение.'
        smartScreen3 = 'Обычно это происходит, когда скрипты PowerShell ограничены.'
        smartFix1    = 'БЫСТРОЕ ИСПРАВЛЕНИЕ - Запустите эту команду, затем повторите:'
        smartFix2    = '  Set-ExecutionPolicy Bypass -Scope Process -Force'
        smartFix3    = 'ИЛИ: Щёлкните правой кнопкой мыши PowerShell -> Запуск от имени администратора, затем вставьте команду установки.'
        generic      = 'Проверьте подключение к Интернету и повторите попытку.'
        generic2     = 'Если проблема не исчезнет, серверы GitHub могут быть недоступны.'
        pressEnter   = 'Нажмите ВВОД для выхода'
    }
    pt = @{
        downloading  = 'Baixando instalador do GitHub...'
        starting     = 'Iniciando Minecraft Bedrock Unlocker...'
        allFailed    = '[MBU] Falha ao baixar o instalador.'
        lastError    = '[MBU] Último erro: {0}'
        smartScreen  = 'O WINDOWS SMARTSCREEN / CONTROLE DE APLICATIVOS ESTÁ BLOQUEANDO O SCRIPT!'
        smartScreen2 = 'Sua política de segurança do Windows bloqueou a execução.'
        smartScreen3 = 'Isso geralmente acontece quando scripts do PowerShell são restritos.'
        smartFix1    = 'CORREÇÃO RÁPIDA - Execute este comando e tente novamente:'
        smartFix2    = '  Set-ExecutionPolicy Bypass -Scope Process -Force'
        smartFix3    = 'OU: Clique com o botão direito no PowerShell -> Executar como administrador, depois cole o comando de instalação.'
        generic      = 'Verifique sua conexão com a internet e tente novamente.'
        generic2     = 'Se o problema persistir, os servidores do GitHub podem estar indisponíveis.'
        pressEnter   = 'Pressione ENTER para sair'
    }
}

# ── Download and execute unlocker.ps1 ──
$lastError = $null
$content = $null
$urls = @($Script:RawUrl, $Script:ReleaseUrl)

Write-Host ($Script:Msg[$Script:Lang].downloading)

foreach ($url in $urls) {
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            $cb = [guid]::NewGuid().ToString('N')
            $sep = if ($url.Contains('?')) { '&' } else { '?' }
            $cachebusted = "$url${sep}cb=$cb"

            $content = Invoke-RestMethod -UseBasicParsing -Headers $Headers -Uri $cachebusted -MaximumRedirection 5 -ErrorAction Stop

            if ([string]::IsNullOrWhiteSpace($content)) {
                throw 'empty response'
            }

            $trimmed = $content.TrimStart()
            if ($trimmed.StartsWith('<!DOCTYPE', [StringComparison]::OrdinalIgnoreCase) -or `
                $trimmed.StartsWith('<html', [StringComparison]::OrdinalIgnoreCase)) {
                throw 'received HTML instead of script'
            }

            if ($content -notmatch 'Minecraft Bedrock Unlocker' -or $content -notmatch 'Start-MainLoop') {
                throw 'downloaded content is not the expected installer'
            }

            $content = $content.TrimStart([char]0xFEFF, [char]0x200B, [char]0x200C, [char]0x200D, "`n", "`r", "`t", ' ')
            Write-Host ($Script:Msg[$Script:Lang].starting)
            $Script:MBUContent = $content
            iex $content
            exit 0
        }
        catch {
            $lastError = $_
            Start-Sleep -Milliseconds (250 * $attempt)
        }
    }
}

# ── All attempts failed: show diagnostics ──
Write-Host ''
Write-Host '============================================================' -ForegroundColor Red
Write-Host $Script:Msg[$Script:Lang].allFailed -ForegroundColor Red
if ($lastError) {
    $errMsg = $lastError.Exception.Message
    Write-Host ($Script:Msg[$Script:Lang].lastError -f $errMsg) -ForegroundColor Red
}
Write-Host '============================================================' -ForegroundColor Red
Write-Host ''

# SmartScreen / App Control / execution policy detection
if ($lastError -and $errMsg -match 'Controle de Aplicativo|Application.?Control|SmartScreen|reputa[cç].*o|reputation|bloqueou este arquivo|blocked.*app|protected.*PC|unrecognized|não reconhecido|signer|não pode ser executado|mal.intencionada|operation.*validated|Publisher.*blocked|prevented.*start|running scripts is disabled|execution of scripts is disabled|não pode ser carregado|cannot be loaded|PSSecurityException|UnauthorizedAccess') {
    Write-Host $Script:Msg[$Script:Lang].smartScreen -ForegroundColor Red
    Write-Host $Script:Msg[$Script:Lang].smartScreen2 -ForegroundColor Yellow
    Write-Host $Script:Msg[$Script:Lang].smartScreen3 -ForegroundColor Yellow
    Write-Host ''
    Write-Host $Script:Msg[$Script:Lang].smartFix1 -ForegroundColor Cyan
    Write-Host $Script:Msg[$Script:Lang].smartFix2 -ForegroundColor White
    Write-Host ''
    Write-Host $Script:Msg[$Script:Lang].smartFix3 -ForegroundColor Yellow
} else {
    Write-Host $Script:Msg[$Script:Lang].generic -ForegroundColor Yellow
    Write-Host $Script:Msg[$Script:Lang].generic2 -ForegroundColor Yellow
}

Write-Host ''
Read-Host $Script:Msg[$Script:Lang].pressEnter
exit 1
