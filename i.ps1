# ============================================================
#  MinecraftBedrockUnlocker -> Minecraft-Bedrock-Free
#  Este repositorio e apenas um aviso: o projeto mudou de nome.
#  This repository only warns that the project has been renamed.
#  Suporte a 8 idiomas (pt/en/es/fr/zh/hi/ar/ru) com deteccao
#  automatica, igual ao menu.ps1 do projeto novo.
# ============================================================
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

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

$Lang = Resolve-MbuLanguage
$Cmd = 'irm https://github.com/CoelhoFZ/Minecraft-Bedrock-Free/raw/main/i.ps1 | iex'
$Rel = 'https://github.com/CoelhoFZ/Minecraft-Bedrock-Free/releases'

$Msg = @{
    'pt' = @(
        'ATENCAO: o projeto mudou de nome!',
        'MinecraftBedrockUnlocker agora e Minecraft-Bedrock-Free. Este repositorio so existe para proteger o nome antigo.',
        'Execute o comando NOVO:',
        'NAO execute nada de links curtos ou outros dominios - golpistas imitam este projeto.'
    )
    'en' = @(
        'WARNING: the project has been renamed!',
        'MinecraftBedrockUnlocker is now Minecraft-Bedrock-Free. This repository only exists to protect the old name.',
        'Run the NEW command:',
        'Never run anything from short links or unknown domains - scammers imitate this project.'
    )
    'es' = @(
        'ATENCION: el proyecto cambio de nombre!',
        'MinecraftBedrockUnlocker ahora es Minecraft-Bedrock-Free. Este repositorio solo existe para proteger el nombre antiguo.',
        'Ejecuta el comando NUEVO:',
        'No ejecutes nada de enlaces cortos ni de otros dominios - los estafadores imitan este proyecto.'
    )
    'fr' = @(
        'ATTENTION : le projet a change de nom !',
        'MinecraftBedrockUnlocker est devenu Minecraft-Bedrock-Free. Ce depot n existe que pour proteger l ancien nom.',
        'Executez la NOUVELLE commande :',
        'N executez jamais rien venant de liens courts ou d autres domaines - des fraudeurs imitent ce projet.'
    )
    'zh' = @(
        '警告：项目已改名！',
        'MinecraftBedrockUnlocker 现在是 Minecraft-Bedrock-Free。此仓库仅用于保护旧名称。',
        '请运行新命令：',
        '切勿运行来自短链接或其他域名的内容——有骗子冒充此项目。'
    )
    'hi' = @(
        'चेतावनी: प्रोजेक्ट का नाम बदल गया है!',
        'MinecraftBedrockUnlocker अब Minecraft-Bedrock-Free है। यह रिपॉजिटरी केवल पुराने नाम की सुरक्षा के लिए है।',
        'नया कमांड चलाएँ:',
        'शॉर्ट लिंक या अन्य डोमेन से कुछ भी न चलाएँ - स्कैमर्स इस प्रोजेक्ट की नकल करते हैं।'
    )
    'ar' = @(
        'تحذير: تم تغيير اسم المشروع!',
        'MinecraftBedrockUnlocker أصبح الآن Minecraft-Bedrock-Free. هذا المستودع موجود فقط لحماية الاسم القديم.',
        'نفّذ الأمر الجديد:',
        'لا تنفّذ أبدًا أي شيء من روابط قصيرة أو نطاقات أخرى - المحتالون يقلّدون هذا المشروع.'
    )
    'ru' = @(
        'ВНИМАНИЕ: проект сменил название!',
        'MinecraftBedrockUnlocker теперь Minecraft-Bedrock-Free. Этот репозиторий существует только для защиты старого названия.',
        'Выполните НОВУЮ команду:',
        'Никогда не выполняйте ничего с коротких ссылок или чужих доменов - мошенники подделывают этот проект.'
    )
}

$m = $Msg[$Lang]
if (-not $m) { $m = $Msg['en'] }

Write-Host ""
Write-Host ('  ' + $m[0]) -ForegroundColor Yellow
Write-Host ""
Write-Host ('  ' + $m[1])
Write-Host ""
Write-Host ('  ' + $m[2]) -ForegroundColor Cyan
Write-Host ""
Write-Host ('      ' + $Cmd) -ForegroundColor Green
Write-Host ""
Write-Host ('  ' + $Rel) -ForegroundColor Green
Write-Host ""
Write-Host ('  ' + $m[3]) -ForegroundColor Red
Write-Host ""
