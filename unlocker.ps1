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

    # Keep OnlineFix.ini writable and out of the encrypted persistence
    # manifest, so first-run state is not rolled back at logon. The core has
    # changed indentation over time, so use a narrow regex instead of an
    # indentation-sensitive literal replacement.
    if ($text -notmatch 'runtime state is never rolled back at logon') {
        $backupPattern = '(?ms)(?<indent>^[ \t]*)# Save encrypted copies of each file\r?\n(?<indent2>[ \t]*)\$manifest = @\(\)\r?\n(?<indent3>[ \t]*)foreach \(\$file in \$Script:OnlineFixFiles\) \{\r?\n(?<indent4>[ \t]*)\$diskName = Get-DiskName -SourceName \$file\.Name'
        $backupMatch = [regex]::Match($text, $backupPattern)
        if (-not $backupMatch.Success) {
            throw 'The expected persistence backup block was not found.'
        }
        $indent = $backupMatch.Groups['indent'].Value
        $indent2 = $backupMatch.Groups['indent2'].Value
        $indent3 = $backupMatch.Groups['indent3'].Value
        $indent4 = $backupMatch.Groups['indent4'].Value
        $replacement = @(
            "$indent# Save encrypted copies of static runtime files only. OnlineFix.ini is"
            "$indent# intentionally excluded so runtime state is never rolled back at logon."
            "${indent2}`$manifest = @()"
            "${indent3}foreach (`$file in `$Script:OnlineFixFiles) {"
            "${indent4}    if (`$file.Name -eq `"OnlineFix.ini`") { continue }"
            "${indent4}    `$diskName = Get-DiskName -SourceName `$file.Name"
        ) -join "`n"
        $text = $text.Substring(0, $backupMatch.Index) + $replacement + $text.Substring($backupMatch.Index + $backupMatch.Length)
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
    $mainMarker = $mainMarker.Replace("`r`n", "`n")

    $upgradeBlock = @'
function Get-MbuCompatText {
    param(
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $false)][object[]]$Args
    )

    $translations = @{
        en = @{
            health_title = 'AUTOMATIC MINECRAFT CHECK'; healthy = 'The official Minecraft installation is ready.'
            reason = 'Reason: {0}'; checked = 'Checked file/location: {0}'; solution = 'Solution: {0}'
            guidance = 'Guidance: {0}'; warning = '{0}'; service_missing = 'The {0} service is not installed.'
            service_stopped = 'The {0} service is stopped.'; service_started = 'The {0} service was started automatically.'
            multi_install = 'More than one registered Minecraft installation was found.'
            multi_install_solution = 'Remove old installations through the Xbox app to avoid using the wrong version.'
            no_game = 'Minecraft for Windows was not found.'; no_game_solution = 'Install Minecraft for Windows through the Xbox app, then run the script again.'
            broken_path = 'Windows points to a Minecraft folder that no longer exists.'; broken_path_solution = 'Open the Xbox app, remove the broken installation entry, and install the game again.'
            uwp = 'The Microsoft Store/UWP version was found and is not compatible.'; uwp_solution = 'Uninstall this version and install Minecraft for Windows through the Xbox app.'
            exe_missing = 'The main Minecraft.Windows.exe file is missing.'; exe_missing_solution = 'Use Verify and repair in the Xbox app, or reinstall the game.'
            exe_empty = 'Minecraft.Windows.exe exists but is empty.'; exe_empty_solution = 'Use Verify and repair in the Xbox app or reinstall the game.'
            exe_inspect = 'The main Minecraft file could not be inspected by the script.'; exe_inspect_solution = 'This check does not block installation. Repair the game only if it actually fails to start.'
            manifest_missing = 'No main game manifest was found in the expected locations.'; manifest_missing_solution = 'Use Verify and repair in the Xbox app if the game does not open.'
            manifest_invalid = 'The main game manifest is empty, unreadable, or contains invalid XML.'; manifest_invalid_solution = 'Use Verify and repair in the Xbox app or reinstall the game.'
            no_write = 'The Minecraft folder is not writable.'; no_write_solution = 'Run the script as administrator, or repair the installation through the Xbox app.'
            service_solution = 'Open Windows Settings > Apps > Gaming Services > Advanced options and choose Repair, then restart the PC.'
            greeting_morning = 'Good morning'; greeting_afternoon = 'Good afternoon'; greeting_evening = 'Good evening'
            greeting_unlocked = 'Hello, {0}. Minecraft is already unlocked! To remove the bypass, press [1] and Enter.'
            greeting_locked = 'Hello, {0}! Minecraft is not unlocked yet. To unlock it, press [1] and Enter.'
            menu_restore = '[1] Restore original (return to Trial)'; menu_partial = 'An incomplete installation was detected.'
            menu_repair = '[1] Repair/reinstall automatically'; menu_cleanup = '[2] Restore original and remove incomplete files'; menu_install = '[1] Install'; menu_exit = '[0] Exit'
            final_title = 'AUTOMATIC FINAL CHECK'; final_valid = 'All files installed by the script are present and valid.'; final_trial = 'Open Minecraft and confirm that the Trial screen is gone.'
            final_incomplete = 'The installation is incomplete.'; missing_file = 'Missing file: {0}'; invalid_file = 'Invalid or corrupted file: {0}'; final_solution = 'Run the installation again. If a file disappears, check your antivirus history.'
            restore_title = 'RESTORE CHECK'; restore_success = 'Original state restored: no script files remain in the game folder.'; restore_failed = 'Restore could not remove every file.'; remaining_file = 'Remaining file: {0}'; restore_solution = 'Restart the PC and run Restore original again as administrator.'
            continue = 'Press ENTER to continue'; install_blocked = 'Installation was stopped to avoid modifying an incomplete or corrupted Minecraft installation.'; no_action = 'No action available for option 1.'; no_restore = 'No script installation was detected to restore.'
        }
        zh = @{
            health_title = 'Minecraft 自动检查'; healthy = '官方 Minecraft 安装已准备就绪。'; reason = '原因：{0}'; checked = '检查的位置：{0}'; solution = '解决方案：{0}'; guidance = '建议：{0}'; warning = '{0}'; service_missing = '未安装 {0} 服务。'; service_stopped = '{0} 服务已停止。'; service_started = '{0} 服务已自动启动。'; multi_install = '发现多个已注册的 Minecraft 安装。'; multi_install_solution = '通过 Xbox 应用删除旧安装，避免使用错误版本。'; no_game = '未找到 Minecraft for Windows。'; no_game_solution = '通过 Xbox 应用安装 Minecraft for Windows，然后重新运行脚本。'; broken_path = 'Windows 指向的 Minecraft 文件夹已不存在。'; broken_path_solution = '打开 Xbox 应用，删除损坏的安装条目并重新安装游戏。'; uwp = '发现 Microsoft Store/UWP 版本，该版本不兼容。'; uwp_solution = '卸载此版本，并通过 Xbox 应用安装 Minecraft for Windows。'; exe_missing = '缺少主要的 Minecraft.Windows.exe 文件。'; exe_missing_solution = '在 Xbox 应用中使用“验证和修复”，或重新安装游戏。'; exe_empty = 'Minecraft.Windows.exe 存在但为空。'; exe_empty_solution = '在 Xbox 应用中使用“验证和修复”或重新安装游戏。'; exe_inspect = '脚本无法检查 Minecraft 主文件。'; exe_inspect_solution = '此检查不会阻止安装；只有在游戏无法启动时才需要修复。'; manifest_missing = '在预期位置未找到游戏主清单。'; manifest_missing_solution = '如果游戏无法打开，请在 Xbox 应用中使用“验证和修复”。'; manifest_invalid = '游戏主清单为空、无法读取或 XML 无效。'; manifest_invalid_solution = '在 Xbox 应用中使用“验证和修复”或重新安装游戏。';             no_write = 'Minecraft 文件夹不可写。'; no_write_solution = '以管理员身份运行脚本，或通过 Xbox 应用修复安装。'; service_solution = '打开 Windows 设置 > 应用 > Gaming Services > 高级选项，选择修复，然后重启电脑。'; greeting_morning = '早上好'; greeting_afternoon = '下午好'; greeting_evening = '晚上好'; greeting_unlocked = '你好，{0}。Minecraft 已经解锁！要移除绕过，请按 [1] 然后回车。'; greeting_locked = '你好，{0}！Minecraft 尚未解锁。要解锁，请按 [1] 然后回车。'; menu_restore = '[1] 还原原始状态（恢复试用版）'; menu_partial = '检测到不完整的安装。'; menu_repair = '[1] 自动修复/重新安装'; menu_cleanup = '[2] 还原原始状态并删除不完整文件'; menu_install = '[1] 安装'; menu_exit = '[0] 退出'; final_title = '自动最终检查'; final_valid = '脚本安装的所有文件都存在且有效。'; final_trial = '打开 Minecraft，确认试用版界面已消失。'; final_incomplete = '安装不完整。'; missing_file = '缺少文件：{0}'; invalid_file = '文件无效或已损坏：{0}'; final_solution = '重新运行安装。如果文件消失，请检查杀毒软件历史记录。'; restore_title = '还原检查'; restore_success = '已恢复原始状态：游戏文件夹中没有脚本文件。'; restore_failed = '无法删除所有文件。'; remaining_file = '剩余文件：{0}'; restore_solution = '重启电脑，然后以管理员身份再次运行“还原原始状态”。'; continue = '按回车继续'; install_blocked = '为避免修改不完整或损坏的 Minecraft，安装已停止。'; no_action = '选项 1 没有可用操作。'; no_restore = '未检测到脚本安装，无法还原。'
        }
        hi = @{
            health_title = 'Minecraft स्वचालित जाँच'; healthy = 'आधिकारिक Minecraft स्थापना तैयार है।'; reason = 'कारण: {0}'; checked = 'जाँची गई जगह: {0}'; solution = 'समाधान: {0}'; guidance = 'सलाह: {0}'; warning = '{0}'; service_missing = '{0} सेवा स्थापित नहीं है।'; service_stopped = '{0} सेवा बंद है।'; service_started = '{0} सेवा अपने-आप शुरू की गई।'; multi_install = 'Minecraft की एक से अधिक पंजीकृत स्थापनाएँ मिलीं।'; multi_install_solution = 'गलत संस्करण से बचने के लिए Xbox ऐप से पुरानी स्थापनाएँ हटाएँ।'; no_game = 'Minecraft for Windows नहीं मिला।'; no_game_solution = 'Xbox ऐप से Minecraft for Windows स्थापित करें और स्क्रिप्ट फिर चलाएँ।'; broken_path = 'Windows जिस Minecraft फ़ोल्डर की ओर संकेत करता है वह मौजूद नहीं है।'; broken_path_solution = 'Xbox ऐप खोलें, टूटी हुई स्थापना हटाएँ और गेम फिर स्थापित करें।'; uwp = 'Microsoft Store/UWP संस्करण मिला, जो संगत नहीं है।'; uwp_solution = 'इस संस्करण को हटाएँ और Xbox ऐप से Minecraft for Windows स्थापित करें।'; exe_missing = 'मुख्य Minecraft.Windows.exe फ़ाइल नहीं मिली।'; exe_missing_solution = 'Xbox ऐप में Verify and repair चलाएँ या गेम फिर स्थापित करें।'; exe_empty = 'Minecraft.Windows.exe मौजूद है लेकिन खाली है।'; exe_empty_solution = 'Xbox ऐप में Verify and repair चलाएँ या गेम फिर स्थापित करें।'; exe_inspect = 'स्क्रिप्ट Minecraft की मुख्य फ़ाइल की जाँच नहीं कर सकी।'; exe_inspect_solution = 'यह जाँच स्थापना को नहीं रोकती; गेम न शुरू होने पर ही मरम्मत करें।'; manifest_missing = 'अपेक्षित स्थानों पर गेम का मुख्य manifest नहीं मिला।'; manifest_missing_solution = 'गेम न खुले तो Xbox ऐप में Verify and repair चलाएँ।'; manifest_invalid = 'मुख्य manifest खाली, अपठनीय या अमान्य XML है।'; manifest_invalid_solution = 'Xbox ऐप में Verify and repair चलाएँ या गेम फिर स्थापित करें।';             no_write = 'Minecraft फ़ोल्डर में लिखने की अनुमति नहीं है।'; no_write_solution = 'स्क्रिप्ट को व्यवस्थापक के रूप में चलाएँ या Xbox ऐप से स्थापना सुधारें।'; service_solution = 'Windows Settings > Apps > Gaming Services > Advanced options खोलें, Repair चुनें और PC पुनरारंभ करें।'; greeting_morning = 'सुप्रभात'; greeting_afternoon = 'नमस्कार'; greeting_evening = 'शुभ संध्या'; greeting_unlocked = 'नमस्ते, {0}। Minecraft पहले से अनलॉक है! हटाने के लिए [1] दबाएँ और Enter करें।'; greeting_locked = 'नमस्ते, {0}! Minecraft अभी अनलॉक नहीं है। अनलॉक करने के लिए [1] दबाएँ और Enter करें।'; menu_restore = '[1] मूल स्थिति पुनर्स्थापित करें (ट्रायल पर लौटें)'; menu_partial = 'अपूर्ण स्थापना मिली।'; menu_repair = '[1] अपने-आप सुधारें/फिर स्थापित करें'; menu_cleanup = '[2] मूल स्थिति पुनर्स्थापित करें और अधूरी फ़ाइलें हटाएँ'; menu_install = '[1] स्थापित करें'; menu_exit = '[0] बाहर निकलें'; final_title = 'स्वचालित अंतिम जाँच'; final_valid = 'स्क्रिप्ट की सभी स्थापित फ़ाइलें मौजूद और मान्य हैं।'; final_trial = 'Minecraft खोलकर पुष्टि करें कि Trial स्क्रीन हट गई है।'; final_incomplete = 'स्थापना अधूरी है।'; missing_file = 'गुम फ़ाइल: {0}'; invalid_file = 'अमान्य या दूषित फ़ाइल: {0}'; final_solution = 'स्थापना फिर चलाएँ। फ़ाइल गायब हो तो एंटीवायरस इतिहास देखें।'; restore_title = 'पुनर्स्थापना जाँच'; restore_success = 'मूल स्थिति बहाल: गेम फ़ोल्डर में स्क्रिप्ट की कोई फ़ाइल नहीं है।'; restore_failed = 'सभी फ़ाइलें हटाई नहीं जा सकीं।'; remaining_file = 'बची हुई फ़ाइल: {0}'; restore_solution = 'PC पुनरारंभ करें और व्यवस्थापक के रूप में Restore original फिर चलाएँ।'; continue = 'जारी रखने के लिए ENTER दबाएँ'; install_blocked = 'अपूर्ण या दूषित Minecraft को बदलने से बचने के लिए स्थापना रोक दी गई।'; no_action = 'विकल्प 1 के लिए कोई कार्रवाई उपलब्ध नहीं है।'; no_restore = 'पुनर्स्थापित करने के लिए स्क्रिप्ट की स्थापना नहीं मिली।'
        }
        es = @{
            health_title = 'COMPROBACIÓN AUTOMÁTICA DE MINECRAFT'; healthy = 'La instalación oficial de Minecraft está lista.'; reason = 'Motivo: {0}'; checked = 'Ubicación comprobada: {0}'; solution = 'Solución: {0}'; guidance = 'Orientación: {0}'; warning = '{0}'; service_missing = 'El servicio {0} no está instalado.'; service_stopped = 'El servicio {0} está detenido.'; service_started = 'El servicio {0} se inició automáticamente.'; multi_install = 'Se encontró más de una instalación registrada de Minecraft.'; multi_install_solution = 'Elimina instalaciones antiguas desde la aplicación Xbox para evitar usar la versión incorrecta.'; no_game = 'No se encontró Minecraft for Windows.'; no_game_solution = 'Instala Minecraft for Windows desde la aplicación Xbox y ejecuta el script de nuevo.'; broken_path = 'Windows apunta a una carpeta de Minecraft que ya no existe.'; broken_path_solution = 'Abre la aplicación Xbox, elimina la instalación dañada e instala el juego de nuevo.'; uwp = 'Se encontró la versión Microsoft Store/UWP, que no es compatible.'; uwp_solution = 'Desinstala esta versión e instala Minecraft for Windows desde la aplicación Xbox.'; exe_missing = 'Falta el archivo principal Minecraft.Windows.exe.'; exe_missing_solution = 'Usa Verificar y reparar en la aplicación Xbox o reinstala el juego.'; exe_empty = 'Minecraft.Windows.exe existe pero está vacío.'; exe_empty_solution = 'Usa Verificar y reparar en la aplicación Xbox o reinstala el juego.'; exe_inspect = 'El script no pudo inspeccionar el archivo principal de Minecraft.'; exe_inspect_solution = 'Esta comprobación no bloquea la instalación; repáralo solo si el juego no inicia.'; manifest_missing = 'No se encontró el manifiesto principal del juego en las ubicaciones esperadas.'; manifest_missing_solution = 'Si el juego no abre, usa Verificar y reparar en la aplicación Xbox.'; manifest_invalid = 'El manifiesto principal está vacío, no se puede leer o contiene XML inválido.'; manifest_invalid_solution = 'Usa Verificar y reparar en la aplicación Xbox o reinstala el juego.';             no_write = 'La carpeta de Minecraft no permite escritura.'; no_write_solution = 'Ejecuta el script como administrador o repara la instalación desde la aplicación Xbox.'; service_solution = 'Abre Configuración de Windows > Aplicaciones > Gaming Services > Opciones avanzadas, elige Reparar y reinicia el PC.'; greeting_morning = 'Buenos días'; greeting_afternoon = 'Buenas tardes'; greeting_evening = 'Buenas noches'; greeting_unlocked = 'Hola, {0}. ¡Minecraft ya está desbloqueado! Para quitar el bypass, pulsa [1] y Enter.'; greeting_locked = '¡Hola, {0}! Minecraft aún no está desbloqueado. Para desbloquearlo, pulsa [1] y Enter.'; menu_restore = '[1] Restaurar original (volver a Trial)'; menu_partial = 'Se detectó una instalación incompleta.'; menu_repair = '[1] Reparar/reinstalar automáticamente'; menu_cleanup = '[2] Restaurar original y eliminar archivos incompletos'; menu_install = '[1] Instalar'; menu_exit = '[0] Salir'; final_title = 'COMPROBACIÓN FINAL AUTOMÁTICA'; final_valid = 'Todos los archivos instalados por el script están presentes y son válidos.'; final_trial = 'Abre Minecraft y confirma que desapareció la pantalla Trial.'; final_incomplete = 'La instalación está incompleta.'; missing_file = 'Archivo faltante: {0}'; invalid_file = 'Archivo inválido o dañado: {0}'; final_solution = 'Ejecuta de nuevo la instalación. Si desaparece un archivo, revisa el historial del antivirus.'; restore_title = 'COMPROBACIÓN DE RESTAURACIÓN'; restore_success = 'Estado original restaurado: no quedan archivos del script en la carpeta del juego.'; restore_failed = 'No se pudieron eliminar todos los archivos.'; remaining_file = 'Archivo restante: {0}'; restore_solution = 'Reinicia el PC y ejecuta Restaurar original como administrador.'; continue = 'Pulsa ENTER para continuar'; install_blocked = 'La instalación se detuvo para evitar modificar un Minecraft incompleto o dañado.'; no_action = 'No hay ninguna acción disponible para la opción 1.'; no_restore = 'No se detectó una instalación del script para restaurar.'
        }
        fr = @{
            health_title = 'VÉRIFICATION AUTOMATIQUE DE MINECRAFT'; healthy = 'Linstallation officielle de Minecraft est prête.'; reason = 'Motif : {0}'; checked = 'Emplacement vérifié : {0}'; solution = 'Solution : {0}'; guidance = 'Conseil : {0}'; warning = '{0}'; service_missing = 'Le service {0} nest pas installé.'; service_stopped = 'Le service {0} est arrêté.'; service_started = 'Le service {0} a été démarré automatiquement.'; multi_install = 'Plusieurs installations enregistrées de Minecraft ont été trouvées.'; multi_install_solution = 'Supprimez les anciennes installations via lapplication Xbox pour éviter la mauvaise version.'; no_game = 'Minecraft for Windows est introuvable.'; no_game_solution = 'Installez Minecraft for Windows via lapplication Xbox, puis relancez le script.'; broken_path = 'Windows pointe vers un dossier Minecraft qui nexiste plus.'; broken_path_solution = 'Ouvrez lapplication Xbox, supprimez linstallation endommagée et réinstallez le jeu.'; uwp = 'La version Microsoft Store/UWP a été trouvée et nest pas compatible.'; uwp_solution = 'Désinstallez cette version et installez Minecraft for Windows via lapplication Xbox.'; exe_missing = 'Le fichier principal Minecraft.Windows.exe est manquant.'; exe_missing_solution = 'Utilisez Vérifier et réparer dans lapplication Xbox ou réinstallez le jeu.'; exe_empty = 'Minecraft.Windows.exe existe mais est vide.'; exe_empty_solution = 'Utilisez Vérifier et réparer dans lapplication Xbox ou réinstallez le jeu.'; exe_inspect = 'Le script na pas pu inspecter le fichier principal de Minecraft.'; exe_inspect_solution = 'Cette vérification ne bloque pas linstallation ; réparez seulement si le jeu ne démarre pas.'; manifest_missing = 'Aucun manifeste principal du jeu na été trouvé aux emplacements attendus.'; manifest_missing_solution = 'Si le jeu ne souvre pas, utilisez Vérifier et réparer dans lapplication Xbox.'; manifest_invalid = 'Le manifeste principal est vide, illisible ou contient un XML invalide.'; manifest_invalid_solution = 'Utilisez Vérifier et réparer dans lapplication Xbox ou réinstallez le jeu.';             no_write = 'Le dossier Minecraft nest pas accessible en écriture.'; no_write_solution = 'Exécutez le script en tant quadministrateur ou réparez linstallation via lapplication Xbox.'; service_solution = 'Ouvrez Paramètres Windows > Applications > Gaming Services > Options avancées, choisissez Réparer puis redémarrez le PC.'; greeting_morning = 'Bonjour'; greeting_afternoon = 'Bon après-midi'; greeting_evening = 'Bonsoir'; greeting_unlocked = 'Bonjour, {0}. Minecraft est déjà déverrouillé ! Pour supprimer le bypass, appuyez sur [1] puis Entrée.'; greeting_locked = 'Bonjour, {0} ! Minecraft nest pas encore déverrouillé. Pour le déverrouiller, appuyez sur [1] puis Entrée.'; menu_restore = '[1] Restaurer loriginal (revenir à Trial)'; menu_partial = 'Une installation incomplète a été détectée.'; menu_repair = '[1] Réparer/réinstaller automatiquement'; menu_cleanup = '[2] Restaurer loriginal et supprimer les fichiers incomplets'; menu_install = '[1] Installer'; menu_exit = '[0] Quitter'; final_title = 'VÉRIFICATION FINALE AUTOMATIQUE'; final_valid = 'Tous les fichiers installés par le script sont présents et valides.'; final_trial = 'Ouvrez Minecraft et confirmez que lécran Trial a disparu.'; final_incomplete = 'Linstallation est incomplète.'; missing_file = 'Fichier manquant : {0}'; invalid_file = 'Fichier invalide ou corrompu : {0}'; final_solution = 'Relancez linstallation. Si un fichier disparaît, consultez lhistorique de lantivirus.'; restore_title = 'VÉRIFICATION DE LA RESTAURATION'; restore_success = 'État original restauré : aucun fichier du script ne reste dans le dossier du jeu.'; restore_failed = 'Impossible de supprimer tous les fichiers.'; remaining_file = 'Fichier restant : {0}'; restore_solution = 'Redémarrez le PC et relancez Restaurer loriginal en tant quadministrateur.'; continue = 'Appuyez sur ENTRÉE pour continuer'; install_blocked = 'Linstallation a été arrêtée pour éviter de modifier un Minecraft incomplet ou endommagé.'; no_action = 'Aucune action nest disponible pour loption 1.'; no_restore = 'Aucune installation du script na été détectée à restaurer.'
        }
        ar = @{
            health_title = 'فحص Minecraft التلقائي'; healthy = 'تثبيت Minecraft الرسمي جاهز.'; reason = 'السبب: {0}'; checked = 'الموقع الذي تم فحصه: {0}'; solution = 'الحل: {0}'; guidance = 'الإرشاد: {0}'; warning = '{0}'; service_missing = 'خدمة {0} غير مثبتة.'; service_stopped = 'خدمة {0} متوقفة.'; service_started = 'تم تشغيل خدمة {0} تلقائياً.'; multi_install = 'تم العثور على أكثر من تثبيت مسجل لـ Minecraft.'; multi_install_solution = 'احذف التثبيتات القديمة من تطبيق Xbox لتجنب استخدام الإصدار الخاطئ.'; no_game = 'لم يتم العثور على Minecraft for Windows.'; no_game_solution = 'ثبّت Minecraft for Windows من تطبيق Xbox ثم شغّل البرنامج مرة أخرى.'; broken_path = 'يشير Windows إلى مجلد Minecraft لم يعد موجوداً.'; broken_path_solution = 'افتح تطبيق Xbox واحذف التثبيت التالف وثبّت اللعبة مرة أخرى.'; uwp = 'تم العثور على إصدار Microsoft Store/UWP وهو غير متوافق.'; uwp_solution = 'أزل هذا الإصدار وثبّت Minecraft for Windows من تطبيق Xbox.'; exe_missing = 'ملف Minecraft.Windows.exe الرئيسي مفقود.'; exe_missing_solution = 'استخدم التحقق والإصلاح في تطبيق Xbox أو أعد تثبيت اللعبة.'; exe_empty = 'ملف Minecraft.Windows.exe موجود لكنه فارغ.'; exe_empty_solution = 'استخدم التحقق والإصلاح في تطبيق Xbox أو أعد تثبيت اللعبة.'; exe_inspect = 'تعذر على البرنامج فحص ملف Minecraft الرئيسي.'; exe_inspect_solution = 'هذا الفحص لا يمنع التثبيت؛ أصلح اللعبة فقط إذا لم تبدأ فعلياً.'; manifest_missing = 'لم يتم العثور على بيان اللعبة الرئيسي في المواقع المتوقعة.'; manifest_missing_solution = 'إذا لم تفتح اللعبة، استخدم التحقق والإصلاح في تطبيق Xbox.'; manifest_invalid = 'بيان اللعبة الرئيسي فارغ أو غير قابل للقراءة أو يحتوي على XML غير صالح.'; manifest_invalid_solution = 'استخدم التحقق والإصلاح في تطبيق Xbox أو أعد تثبيت اللعبة.';             no_write = 'مجلد Minecraft غير قابل للكتابة.'; no_write_solution = 'شغّل البرنامج كمسؤول أو أصلح التثبيت من خلال تطبيق Xbox.'; service_solution = 'افتح إعدادات Windows > التطبيقات > Gaming Services > الخيارات المتقدمة، اختر الإصلاح ثم أعد تشغيل الكمبيوتر.'; greeting_morning = 'صباح الخير'; greeting_afternoon = 'مساء الخير'; greeting_evening = 'مساء الخير'; greeting_unlocked = 'مرحباً، {0}. Minecraft مفتوح بالفعل! لإزالة التجاوز، اضغط [1] ثم Enter.'; greeting_locked = 'مرحباً، {0}! Minecraft غير مفتوح بعد. لفتحه، اضغط [1] ثم Enter.'; menu_restore = '[1] استعادة الحالة الأصلية (العودة إلى Trial)'; menu_partial = 'تم اكتشاف تثبيت غير مكتمل.'; menu_repair = '[1] إصلاح/إعادة التثبيت تلقائياً'; menu_cleanup = '[2] استعادة الحالة الأصلية وحذف الملفات غير المكتملة'; menu_install = '[1] تثبيت'; menu_exit = '[0] خروج'; final_title = 'الفحص النهائي التلقائي'; final_valid = 'جميع الملفات التي ثبتها البرنامج موجودة وصالحة.'; final_trial = 'افتح Minecraft وتأكد من اختفاء شاشة Trial.'; final_incomplete = 'التثبيت غير مكتمل.'; missing_file = 'ملف مفقود: {0}'; invalid_file = 'ملف غير صالح أو تالف: {0}'; final_solution = 'شغّل التثبيت مرة أخرى. إذا اختفى ملف، راجع سجل برنامج مكافحة الفيروسات.'; restore_title = 'فحص الاستعادة'; restore_success = 'تمت استعادة الحالة الأصلية: لا توجد ملفات للبرنامج في مجلد اللعبة.'; restore_failed = 'تعذر حذف جميع الملفات.'; remaining_file = 'الملف المتبقي: {0}'; restore_solution = 'أعد تشغيل الكمبيوتر وشغّل استعادة الحالة الأصلية كمسؤول.'; continue = 'اضغط ENTER للمتابعة'; install_blocked = 'تم إيقاف التثبيت لتجنب تعديل Minecraft غير المكتمل أو التالف.'; no_action = 'لا يوجد إجراء متاح للخيار 1.'; no_restore = 'لم يتم العثور على تثبيت للبرنامج لاستعادته.'
        }
        ru = @{
            health_title = 'АВТОМАТИЧЕСКАЯ ПРОВЕРКА MINECRAFT'; healthy = 'Официальная установка Minecraft готова.'; reason = 'Причина: {0}'; checked = 'Проверенное расположение: {0}'; solution = 'Решение: {0}'; guidance = 'Рекомендация: {0}'; warning = '{0}'; service_missing = 'Служба {0} не установлена.'; service_stopped = 'Служба {0} остановлена.'; service_started = 'Служба {0} запущена автоматически.'; multi_install = 'Найдено несколько зарегистрированных установок Minecraft.'; multi_install_solution = 'Удалите старые установки через приложение Xbox, чтобы не использовать неправильную версию.'; no_game = 'Minecraft for Windows не найден.'; no_game_solution = 'Установите Minecraft for Windows через приложение Xbox и снова запустите скрипт.'; broken_path = 'Windows указывает на несуществующую папку Minecraft.'; broken_path_solution = 'Откройте приложение Xbox, удалите повреждённую установку и установите игру заново.'; uwp = 'Найдена версия Microsoft Store/UWP, которая несовместима.'; uwp_solution = 'Удалите эту версию и установите Minecraft for Windows через приложение Xbox.'; exe_missing = 'Отсутствует основной файл Minecraft.Windows.exe.'; exe_missing_solution = 'Используйте проверку и восстановление в приложении Xbox или переустановите игру.'; exe_empty = 'Minecraft.Windows.exe существует, но пуст.'; exe_empty_solution = 'Используйте проверку и восстановление в приложении Xbox или переустановите игру.'; exe_inspect = 'Скрипт не смог проверить основной файл Minecraft.'; exe_inspect_solution = 'Эта проверка не блокирует установку; исправляйте игру только если она действительно не запускается.'; manifest_missing = 'Основной манифест игры не найден в ожидаемых местах.'; manifest_missing_solution = 'Если игра не открывается, используйте проверку и восстановление в приложении Xbox.'; manifest_invalid = 'Основной манифест пуст, нечитаем или содержит недопустимый XML.'; manifest_invalid_solution = 'Используйте проверку и восстановление в приложении Xbox или переустановите игру.';             no_write = 'Папка Minecraft недоступна для записи.'; no_write_solution = 'Запустите скрипт от имени администратора или восстановите установку через приложение Xbox.'; service_solution = 'Откройте Параметры Windows > Приложения > Gaming Services > Дополнительные параметры, выберите Восстановить и перезагрузите компьютер.'; greeting_morning = 'Доброе утро'; greeting_afternoon = 'Добрый день'; greeting_evening = 'Добрый вечер'; greeting_unlocked = 'Здравствуйте, {0}. Minecraft уже разблокирован! Чтобы удалить обход, нажмите [1] и Enter.'; greeting_locked = 'Здравствуйте, {0}! Minecraft ещё не разблокирован. Для разблокировки нажмите [1] и Enter.'; menu_restore = '[1] Восстановить оригинал (вернуться к Trial)'; menu_partial = 'Обнаружена неполная установка.'; menu_repair = '[1] Автоматически исправить/переустановить'; menu_cleanup = '[2] Восстановить оригинал и удалить неполные файлы'; menu_install = '[1] Установить'; menu_exit = '[0] Выход'; final_title = 'АВТОМАТИЧЕСКАЯ ФИНАЛЬНАЯ ПРОВЕРКА'; final_valid = 'Все файлы, установленные скриптом, существуют и исправны.'; final_trial = 'Откройте Minecraft и убедитесь, что экран Trial исчез.'; final_incomplete = 'Установка неполная.'; missing_file = 'Отсутствует файл: {0}'; invalid_file = 'Недействительный или повреждённый файл: {0}'; final_solution = 'Запустите установку снова. Если файл исчезает, проверьте историю антивируса.'; restore_title = 'ПРОВЕРКА ВОССТАНОВЛЕНИЯ'; restore_success = 'Оригинальное состояние восстановлено: в папке игры не осталось файлов скрипта.'; restore_failed = 'Не удалось удалить все файлы.'; remaining_file = 'Оставшийся файл: {0}'; restore_solution = 'Перезагрузите компьютер и снова запустите восстановление от имени администратора.'; continue = 'Нажмите ENTER для продолжения'; install_blocked = 'Установка остановлена, чтобы не изменять неполный или повреждённый Minecraft.'; no_action = 'Для варианта 1 нет доступного действия.'; no_restore = 'Установка скрипта для восстановления не найдена.'
        }
        pt = @{
            health_title = 'VERIFICACAO AUTOMATICA DO MINECRAFT'; healthy = 'A instalacao oficial do Minecraft esta pronta.'; reason = 'Motivo: {0}'; checked = 'Arquivo/local verificado: {0}'; solution = 'Solucao: {0}'; guidance = 'Orientacao: {0}'; warning = '{0}'; service_missing = 'O servico {0} nao esta instalado.'; service_stopped = 'O servico {0} esta parado.'; service_started = 'O servico {0} foi iniciado automaticamente.'; multi_install = 'Mais de uma instalacao registrada do Minecraft foi encontrada.'; multi_install_solution = 'Remova instalacoes antigas pelo aplicativo Xbox para evitar usar a versao errada.'; no_game = 'O Minecraft for Windows nao foi encontrado.'; no_game_solution = 'Instale o Minecraft for Windows pelo aplicativo Xbox e execute o script novamente.'; broken_path = 'O Windows aponta para uma pasta do Minecraft que nao existe mais.'; broken_path_solution = 'Abra o aplicativo Xbox, remova a instalacao quebrada e instale o jogo novamente.'; uwp = 'Foi encontrada a versao Microsoft Store/UWP, que nao e compativel.'; uwp_solution = 'Desinstale essa versao e instale o Minecraft for Windows pelo aplicativo Xbox.'; exe_missing = 'O arquivo principal Minecraft.Windows.exe esta faltando.'; exe_missing_solution = 'Use Verificar e reparar no aplicativo Xbox ou reinstale o jogo.'; exe_empty = 'Minecraft.Windows.exe existe, mas esta vazio.'; exe_empty_solution = 'Use Verificar e reparar no aplicativo Xbox ou reinstale o jogo.'; exe_inspect = 'O arquivo principal do Minecraft nao pode ser inspecionado pelo script.'; exe_inspect_solution = 'A checagem nao bloqueia a instalacao; repare o jogo apenas se ele realmente nao iniciar.'; manifest_missing = 'Nenhum manifesto principal do jogo foi encontrado nos locais esperados.'; manifest_missing_solution = 'Use Verificar e reparar no aplicativo Xbox se o jogo nao abrir.'; manifest_invalid = 'O manifesto principal esta vazio, ilegivel ou possui XML invalido.'; manifest_invalid_solution = 'Use Verificar e reparar no aplicativo Xbox ou reinstale o jogo.';             no_write = 'A pasta do Minecraft nao permite gravacao.'; no_write_solution = 'Execute o script como administrador ou repare a instalacao pelo aplicativo Xbox.'; service_solution = 'Abra Configuracoes do Windows > Aplicativos > Gaming Services > Opcoes avancadas, escolha Reparar e reinicie o PC.'; greeting_morning = 'Bom dia'; greeting_afternoon = 'Boa tarde'; greeting_evening = 'Boa noite'; greeting_unlocked = 'Ola, {0}. O Minecraft ja esta desbloqueado! Para remover o desbloqueio, pressione [1] e aperte Enter.'; greeting_locked = 'Ola, {0}! O Minecraft ainda nao esta desbloqueado. Para desbloquear, pressione [1] e aperte Enter.'; menu_restore = '[1] Restaurar original (voltar para Trial)'; menu_partial = 'Uma instalacao incompleta foi detectada.'; menu_repair = '[1] Reparar/reinstalar automaticamente'; menu_cleanup = '[2] Restaurar original e remover os arquivos incompletos'; menu_install = '[1] Instalar'; menu_exit = '[0] Sair'; final_title = 'VERIFICACAO FINAL AUTOMATICA'; final_valid = 'Todos os arquivos instalados pelo script estao presentes e validos.'; final_trial = 'Abra o Minecraft e confirme se a tela Trial desapareceu.'; final_incomplete = 'A instalacao esta incompleta.'; missing_file = 'Arquivo faltando: {0}'; invalid_file = 'Arquivo invalido ou corrompido: {0}'; final_solution = 'Execute a instalacao novamente. Se um arquivo desaparecer, verifique o historico do antivirus.'; restore_title = 'VERIFICACAO DA RESTAURACAO'; restore_success = 'Estado original restaurado: nenhum arquivo do script permaneceu na pasta do jogo.'; restore_failed = 'A restauracao nao conseguiu remover todos os arquivos.'; remaining_file = 'Arquivo restante: {0}'; restore_solution = 'Reinicie o PC e execute Restaurar original novamente como administrador.'; continue = 'Pressione ENTER para continuar'; install_blocked = 'A instalacao foi interrompida para evitar alterar um Minecraft incompleto ou corrompido.'; no_action = 'Nenhuma acao disponivel para a opcao 1.'; no_restore = 'Nenhuma instalacao do script foi detectada para restaurar.'
        }
    }

    $language = if ($translations.ContainsKey($Script:Lang)) { $Script:Lang } else { 'en' }
    $text = $translations[$language][$Key]
    if ($null -eq $text) { $text = $translations.en[$Key] }
    if ($Args -and $Args.Count -gt 0) { return ($text -f $Args) }
    return $text
}

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
            Reason = Get-MbuCompatText 'no_game'
            Path = $null
            Solution = Get-MbuCompatText 'no_game_solution'
            OpenXbox = $true
        }
    } elseif (-not (Test-Path -LiteralPath $mcPath -PathType Container)) {
        $issues += [pscustomobject]@{
            Reason = Get-MbuCompatText 'broken_path'
            Path = $mcPath
            Solution = Get-MbuCompatText 'broken_path_solution'
            OpenXbox = $true
        }
    } elseif (Test-UwpMinecraftPath -Path $mcPath) {
        $issues += [pscustomobject]@{
            Reason = Get-MbuCompatText 'uwp'
            Path = $mcPath
            Solution = Get-MbuCompatText 'uwp_solution'
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
                Reason = Get-MbuCompatText 'exe_missing'
                Path = $expected
                Solution = Get-MbuCompatText 'exe_missing_solution'
                OpenXbox = $true
            }
        } else {
            # The GDK executable is not a reliable install gate. Xbox packages
            # can use catalog signing, sparse/stub launchers, and file sharing
            # rules that make a PE/signature/read probe fail even while the game
            # opens normally. The bypass writes separate files in Content, so a
            # failed probe must not abort a supported XboxGames installation.
            try {
                $exeItem = Get-Item -LiteralPath $exePath -Force -ErrorAction Stop
                if ($exeItem.Length -le 0) {
                    $issues += [pscustomobject]@{
                        Reason = Get-MbuCompatText 'exe_empty'
                        Path = $exePath
                        Solution = Get-MbuCompatText 'exe_empty_solution'
                        OpenXbox = $false
                    }
                }
            } catch {
                $warnings += [pscustomobject]@{
                    Reason = Get-MbuCompatText 'exe_inspect'
                    Path = $exePath
                    Solution = Get-MbuCompatText 'exe_inspect_solution'
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
                Reason = Get-MbuCompatText 'manifest_missing'
                Path = ($manifestCandidates | Select-Object -Unique) -join '; '
                Solution = Get-MbuCompatText 'manifest_missing_solution'
            }
        } else {
            try {
                $manifestItem = Get-Item -LiteralPath $manifestPath -Force -ErrorAction Stop
                if ($manifestItem.Length -le 0) { throw 'The manifest is empty.' }
                $manifestText = [System.IO.File]::ReadAllText($manifestPath)
                $null = [xml]$manifestText
            } catch {
                $issues += [pscustomobject]@{
                    Reason = Get-MbuCompatText 'manifest_invalid'
                    Path = $manifestPath
                    Solution = Get-MbuCompatText 'manifest_invalid_solution'
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
                Reason = Get-MbuCompatText 'no_write'
                Path = $mcPath
                Solution = Get-MbuCompatText 'no_write_solution'
                OpenXbox = $false
            }
        }
    }

    $serviceProblems = @()
    foreach ($serviceName in @('GamingServices', 'GamingServicesNet')) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if (-not $service) {
            $serviceProblems += Get-MbuCompatText 'service_missing' @($serviceName)
            continue
        }
        if ($service.Status -ne 'Running' -and $AttemptRepair) {
            try {
                Start-Service -Name $serviceName -ErrorAction Stop
                Start-Sleep -Milliseconds 500
                $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                if ($service -and $service.Status -eq 'Running') {
                    $repairs += Get-MbuCompatText 'service_started' @($serviceName)
                }
            } catch { }
        }
        if (-not $service -or $service.Status -ne 'Running') {
            $serviceProblems += Get-MbuCompatText 'service_stopped' @($serviceName)
        }
    }
    if ($serviceProblems.Count -gt 0) {
        $issues += [pscustomobject]@{
            Reason = ($serviceProblems -join ' ')
            Path = $null
            Solution = Get-MbuCompatText 'service_solution'
            OpenXbox = $false
        }
    }

    try {
        $registeredLocations = @(Get-AppxPackage -AllUsers -Name 'MICROSOFT.MINECRAFTUWP' -ErrorAction SilentlyContinue | Where-Object { $_.InstallLocation } | ForEach-Object { $_.InstallLocation.TrimEnd('\') } | Select-Object -Unique)
        if ($registeredLocations.Count -gt 1) {
            $warnings += [pscustomobject]@{
                Reason = Get-MbuCompatText 'multi_install'
                Path = ($registeredLocations -join '; ')
                Solution = Get-MbuCompatText 'multi_install_solution'
            }
        }
    } catch { }

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
    Write-C (Get-MbuCompatText 'health_title') Cyan
    Write-Line
    Write-C ''

    foreach ($repair in $report.Repairs) { Write-OK $repair }

    if ($report.Healthy) {
        Write-OK (Get-MbuCompatText 'healthy')
    } else {
        foreach ($issue in $report.Issues) {
            Write-Err (Get-MbuCompatText 'reason' @($issue.Reason))
            if ($issue.Path) {
                Write-C (Get-MbuCompatText 'checked' @($issue.Path)) Yellow
            }
            Write-C (Get-MbuCompatText 'solution' @($issue.Solution)) White
            Write-C ''
        }
    }

    if (-not $Compact) {
        foreach ($warning in $report.Warnings) {
            Write-Warn (Get-MbuCompatText 'warning' @($warning.Reason))
            if ($warning.Path) {
                Write-C (Get-MbuCompatText 'checked' @($warning.Path)) DarkGray
            }
            Write-C (Get-MbuCompatText 'guidance' @($warning.Solution)) Yellow
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

    Write-C ''

    switch ($state.Mode) {
        'restore' {
            Write-C (Get-MbuCompatText 'menu_restore') Green
        }
        'partial' {
            Write-Warn (Get-MbuCompatText 'menu_partial')
            Write-C (Get-MbuCompatText 'menu_repair') Green
            Write-C (Get-MbuCompatText 'menu_cleanup') Yellow
        }
        default {
            Write-C (Get-MbuCompatText 'menu_install') Green
        }
    }

    Write-C (Get-MbuCompatText 'menu_exit') DarkGray
    Write-C ''
    return $state
}

function Show-MbuPostInstallResult {
    $pt = ($Script:Lang -eq 'pt')
    $state = Get-MbuActionState
    Write-C ''
    Write-Line
    Write-C (Get-MbuCompatText 'final_title') Cyan
    Write-Line
    Write-C ''

    if ($state.Mode -eq 'restore') {
        Write-OK (Get-MbuCompatText 'final_valid')
        Write-Info (Get-MbuCompatText 'final_trial')
    } elseif ($state.Verification) {
        Write-Err (Get-MbuCompatText 'final_incomplete')
        foreach ($file in $state.Verification.Missing) {
            Write-C (Get-MbuCompatText 'missing_file' @($file)) Yellow
        }
        foreach ($file in $state.Verification.Invalid) {
            Write-C (Get-MbuCompatText 'invalid_file' @($file)) Yellow
        }
        Write-C (Get-MbuCompatText 'final_solution') White
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
    Write-C (Get-MbuCompatText 'restore_title') Cyan
    Write-Line
    Write-C ''

    if ($leftovers.Count -eq 0) {
        Write-OK (Get-MbuCompatText 'restore_success')
    } else {
        Write-Err (Get-MbuCompatText 'restore_failed')
        foreach ($file in $leftovers) {
            Write-C (Get-MbuCompatText 'remaining_file' @($file)) Yellow
        }
        Write-C (Get-MbuCompatText 'restore_solution') White
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
function Get-TimeGreeting {
    $hour = (Get-Date).Hour
    if ($hour -ge 6 -and $hour -lt 12) { return (Get-MbuCompatText 'greeting_morning') }
    elseif ($hour -ge 12 -and $hour -lt 18) { return (Get-MbuCompatText 'greeting_afternoon') }
    else { return (Get-MbuCompatText 'greeting_evening') }
}

function Start-MainLoop {
    Detect-Language
    Set-ConsoleAppearance
    Show-Banner

    if (-not (Test-Admin)) {
        Request-Elevation
        return
    }

    $greeting = Get-TimeGreeting
    $state = Get-MbuActionState
    $pt = ($Script:Lang -eq 'pt')
    $isUnlocked = ($state.Mode -eq 'restore')

    $greetingKey = if ($isUnlocked) { 'greeting_unlocked' } else { 'greeting_locked' }
    Write-C (Get-MbuCompatText $greetingKey @($greeting)) Green

    while ($true) {
        $menuState = Show-MbuDynamicMenu
        Write-C "  $(T 'choose'): " Cyan -NoNewline
        $choice = Read-Host
        Show-Banner

        switch ($choice.Trim()) {
            '1' {
                if ($menuState.Mode -eq 'restore') {
                    try {
                        Restore-Original
                        Show-MbuRestoreResult
                    } catch {
                        Write-C ''
                        Write-Err "$($_.Exception.Message)"
                        Write-C ''
                        Read-Host "  $(Get-MbuCompatText 'continue')"
                    }
                } elseif ($menuState.Mode -in @('install', 'partial')) {
                    try {
                        $health = Show-MbuOfficialMinecraftHealth -AttemptRepair
                        if (-not $health.Healthy) {
                            Write-Warn (Get-MbuCompatText 'install_blocked')
                            Wait-Enter
                            continue
                        }
                        Install-Bypass
                        Show-MbuPostInstallResult
                    } catch {
                        Write-C ''
                        Write-Err "$($_.Exception.Message)"
                        Write-C ''
                        Read-Host "  $(Get-MbuCompatText 'continue')"
                    }
                } else {
                    Write-Warn (Get-MbuCompatText 'no_action')
                }
            }
            '2' {
                if ($menuState.Mode -notin @('restore', 'partial')) {
                    Write-Warn (Get-MbuCompatText 'no_restore')
                    continue
                }

                try {
                    Restore-Original
                    Show-MbuRestoreResult
                } catch {
                    Write-C ''
                    Write-Err "$($_.Exception.Message)"
                    Write-C ''
                    Read-Host "  $(Get-MbuCompatText 'continue')"
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
