// Internationalization (i18n) module
// Supports multiple languages with automatic system detection

use std::sync::OnceLock;

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum Language {
    English,
    PortugueseBR,
    PortuguesePT,
    Spanish,
    French,
    German,
    ChineseSimplified,
    Russian,
}

static CURRENT_LANGUAGE: OnceLock<Language> = OnceLock::new();

pub fn init_language() {
    let lang = detect_system_language();
    CURRENT_LANGUAGE.set(lang).ok();
}

pub fn get_language() -> Language {
    *CURRENT_LANGUAGE.get_or_init(|| detect_system_language())
}

fn detect_system_language() -> Language {
    // Priority 1: Try Windows API (correct way on Windows)
    #[cfg(target_os = "windows")]
    {
        // Use GetUserDefaultUILanguage from Windows API
        // LANGID format: primary lang (low byte) + sublang (high byte)
        extern "system" {
            fn GetUserDefaultUILanguage() -> u16;
        }
        
        let langid = unsafe { GetUserDefaultUILanguage() };
        let primary_lang = langid & 0x3FF; // Extract primary language
        let sub_lang = (langid >> 10) & 0x3F; // Extract sublanguage
        
        match primary_lang {
            0x16 => { // Portuguese
                if sub_lang == 0x01 { // Brazilian
                    return Language::PortugueseBR;
                }
                return Language::PortuguesePT;
            }
            0x0A => return Language::Spanish,    // Spanish
            0x0C => return Language::French,     // French
            0x07 => return Language::German,     // German
            0x04 => return Language::ChineseSimplified, // Chinese
            0x19 => return Language::Russian,    // Russian
            0x09 => return Language::English,    // English
            _ => {} // Continue to fallback
        }
    }
    
    // Fallback: try environment variables (Unix-style, rarely set on Windows)
    if let Ok(locale) = std::env::var("LANG") {
        return parse_locale(&locale);
    }
    
    if let Ok(locale) = std::env::var("LC_ALL") {
        return parse_locale(&locale);
    }
    
    // Default to English
    Language::English
}

fn parse_locale(locale: &str) -> Language {
    let locale_lower = locale.to_lowercase();
    
    if locale_lower.starts_with("pt_br") || locale_lower.starts_with("pt-br") {
        Language::PortugueseBR
    } else if locale_lower.starts_with("pt") {
        Language::PortuguesePT
    } else if locale_lower.starts_with("es") {
        Language::Spanish
    } else if locale_lower.starts_with("fr") {
        Language::French
    } else if locale_lower.starts_with("de") {
        Language::German
    } else if locale_lower.starts_with("zh_cn") || locale_lower.starts_with("zh-cn") {
        Language::ChineseSimplified
    } else if locale_lower.starts_with("ru") {
        Language::Russian
    } else {
        Language::English
    }
}

pub struct Translations;

impl Translations {
    // Menu options
    pub fn menu_option_1() -> &'static str {
        match get_language() {
            Language::English => "Install Modified DLL",
            Language::PortugueseBR | Language::PortuguesePT => "Instalar DLL Modificada",
            Language::Spanish => "Instalar DLL Modificada",
            Language::French => "Installer DLL Modifiée",
            Language::German => "Modifizierte DLL installieren",
            Language::ChineseSimplified => "安装修改的DLL",
            Language::Russian => "Установить модифицированную DLL",
        }
    }

    pub fn menu_option_2() -> &'static str {
        match get_language() {
            Language::English => "Restore Original DLL",
            Language::PortugueseBR | Language::PortuguesePT => "Restaurar DLL Original",
            Language::Spanish => "Restaurar DLL Original",
            Language::French => "Restaurer DLL Originale",
            Language::German => "Originale DLL wiederherstellen",
            Language::ChineseSimplified => "恢复原始DLL",
            Language::Russian => "Восстановить оригинальную DLL",
        }
    }

    pub fn menu_option_3() -> &'static str {
        match get_language() {
            Language::English => "Open Minecraft",
            Language::PortugueseBR | Language::PortuguesePT => "Abrir Minecraft",
            Language::Spanish => "Abrir Minecraft",
            Language::French => "Ouvrir Minecraft",
            Language::German => "Minecraft öffnen",
            Language::ChineseSimplified => "打开Minecraft",
            Language::Russian => "Открыть Minecraft",
        }
    }

    pub fn menu_option_4() -> &'static str {
        match get_language() {
            Language::English => "Install Minecraft (Xbox App)",
            Language::PortugueseBR | Language::PortuguesePT => "Instalar Minecraft (Xbox App)",
            Language::Spanish => "Instalar Minecraft (Xbox App)",
            Language::French => "Installer Minecraft (Xbox App)",
            Language::German => "Minecraft installieren (Xbox App)",
            Language::ChineseSimplified => "安装Minecraft (Xbox应用)",
            Language::Russian => "Установить Minecraft (Xbox App)",
        }
    }

    pub fn menu_option_5() -> &'static str {
        match get_language() {
            Language::English => "Check Status",
            Language::PortugueseBR | Language::PortuguesePT => "Verificar Status",
            Language::Spanish => "Verificar Estado",
            Language::French => "Vérifier le Statut",
            Language::German => "Status prüfen",
            Language::ChineseSimplified => "检查状态",
            Language::Russian => "Проверить статус",
        }
    }

    pub fn menu_option_0() -> &'static str {
        match get_language() {
            Language::English => "Exit",
            Language::PortugueseBR | Language::PortuguesePT => "Sair",
            Language::Spanish => "Salir",
            Language::French => "Quitter",
            Language::German => "Beenden",
            Language::ChineseSimplified => "退出",
            Language::Russian => "Выход",
        }
    }

    pub fn menu_option_6() -> &'static str {
        match get_language() {
            Language::English => "Open CoelhoFZ YouTube Channel (subscribe!)",
            Language::PortugueseBR => "Abrir o canal do CoelhoFZ no YouTube (se inscreve lá po)",
            Language::PortuguesePT => "Abrir o canal do CoelhoFZ no YouTube (subscreve lá)",
            Language::Spanish => "Abrir canal de CoelhoFZ en YouTube (¡suscríbete!)",
            Language::French => "Ouvrir la chaîne YouTube de CoelhoFZ (abonnez-vous!)",
            Language::German => "CoelhoFZ YouTube-Kanal öffnen (abonnieren!)",
            Language::ChineseSimplified => "打开CoelhoFZ的YouTube频道 (订阅!)",
            Language::Russian => "Открыть канал CoelhoFZ на YouTube (подпишись!)",
        }
    }

    pub fn available_options() -> &'static str {
        match get_language() {
            Language::English => "Available Options:",
            Language::PortugueseBR | Language::PortuguesePT => "Opções Disponíveis:",
            Language::Spanish => "Opciones Disponibles:",
            Language::French => "Options Disponibles:",
            Language::German => "Verfügbare Optionen:",
            Language::ChineseSimplified => "可用选项:",
            Language::Russian => "Доступные опции:",
        }
    }

    pub fn choose_option(max: &str) -> String {
        match get_language() {
            Language::English => format!("Choose an option [1,2,3,4,5,{},0]:", max),
            Language::PortugueseBR | Language::PortuguesePT => format!("Escolha uma opção [1,2,3,4,5,{},0]:", max),
            Language::Spanish => format!("Elige una opción [1,2,3,4,5,{},0]:", max),
            Language::French => format!("Choisissez une option [1,2,3,4,5,{},0]:", max),
            Language::German => format!("Wählen Sie eine Option [1,2,3,4,5,{},0]:", max),
            Language::ChineseSimplified => format!("选择一个选项 [1,2,3,4,5,{},0]:", max),
            Language::Russian => format!("Выберите опцию [1,2,3,4,5,{},0]:", max),
        }
    }

    pub fn exiting() -> &'static str {
        match get_language() {
            Language::English => "Exiting... Goodbye! 👋",
            Language::PortugueseBR | Language::PortuguesePT => "Saindo... Até logo! 👋",
            Language::Spanish => "Saliendo... ¡Adiós! 👋",
            Language::French => "Fermeture... Au revoir! 👋",
            Language::German => "Beenden... Auf Wiedersehen! 👋",
            Language::ChineseSimplified => "退出中... 再见! 👋",
            Language::Russian => "Выход... До свидания! 👋",
        }
    }

    pub fn invalid_option(max: &str) -> String {
        match get_language() {
            Language::English => format!("⚠️  Invalid option! Choose a number from 0 to {}.", max),
            Language::PortugueseBR | Language::PortuguesePT => format!("⚠️  Opção inválida! Escolha um número de 0 a {}.", max),
            Language::Spanish => format!("⚠️  ¡Opción inválida! Elige un número de 0 a {}.", max),
            Language::French => format!("⚠️  Option invalide! Choisissez un nombre de 0 à {}.", max),
            Language::German => format!("⚠️  Ungültige Option! Wählen Sie eine Zahl von 0 bis {}.", max),
            Language::ChineseSimplified => format!("⚠️  无效选项！选择0到{}之间的数字。", max),
            Language::Russian => format!("⚠️  Неверная опция! Выберите число от 0 до {}.", max),
        }
    }

    pub fn error() -> &'static str {
        match get_language() {
            Language::English => "ERROR:",
            Language::PortugueseBR | Language::PortuguesePT => "ERRO:",
            Language::Spanish => "ERROR:",
            Language::French => "ERREUR:",
            Language::German => "FEHLER:",
            Language::ChineseSimplified => "错误:",
            Language::Russian => "ОШИБКА:",
        }
    }

    pub fn info() -> &'static str {
        match get_language() {
            Language::English => "[INFO]",
            Language::PortugueseBR | Language::PortuguesePT => "[INFO]",
            Language::Spanish => "[INFO]",
            Language::French => "[INFO]",
            Language::German => "[INFO]",
            Language::ChineseSimplified => "[信息]",
            Language::Russian => "[ИНФО]",
        }
    }

    pub fn warning() -> &'static str {
        match get_language() {
            Language::English => "[WARNING]",
            Language::PortugueseBR | Language::PortuguesePT => "[AVISO]",
            Language::Spanish => "[ADVERTENCIA]",
            Language::French => "[AVERTISSEMENT]",
            Language::German => "[WARNUNG]",
            Language::ChineseSimplified => "[警告]",
            Language::Russian => "[ПРЕДУПРЕЖДЕНИЕ]",
        }
    }

    pub fn ok() -> &'static str {
        match get_language() {
            Language::English => "[OK]",
            Language::PortugueseBR | Language::PortuguesePT => "[OK]",
            Language::Spanish => "[OK]",
            Language::French => "[OK]",
            Language::German => "[OK]",
            Language::ChineseSimplified => "[成功]",
            Language::Russian => "[ОК]",
        }
    }

    pub fn admin_required() -> &'static str {
        match get_language() {
            Language::English => "ERROR: This program needs to be run as Administrator!",
            Language::PortugueseBR | Language::PortuguesePT => "ERRO: Este programa precisa ser executado como Administrador!",
            Language::Spanish => "ERROR: ¡Este programa necesita ejecutarse como Administrador!",
            Language::French => "ERREUR: Ce programme doit être exécuté en tant qu'Administrateur!",
            Language::German => "FEHLER: Dieses Programm muss als Administrator ausgeführt werden!",
            Language::ChineseSimplified => "错误：此程序需要以管理员身份运行！",
            Language::Russian => "ОШИБКА: Эту программу нужно запустить от имени Администратора!",
        }
    }

    pub fn admin_how_to() -> &'static str {
        match get_language() {
            Language::English => "Right-click and select 'Run as administrator'",
            Language::PortugueseBR | Language::PortuguesePT => "Clique com botão direito e selecione 'Executar como administrador'",
            Language::Spanish => "Haz clic derecho y selecciona 'Ejecutar como administrador'",
            Language::French => "Cliquez avec le bouton droit et sélectionnez 'Exécuter en tant qu'administrateur'",
            Language::German => "Rechtsklick und 'Als Administrator ausführen' auswählen",
            Language::ChineseSimplified => "右键单击并选择\"以管理员身份运行\"",
            Language::Russian => "Нажмите правой кнопкой мыши и выберите 'Запуск от имени администратора'",
        }
    }

    pub fn installing_modified() -> &'static str {
        match get_language() {
            Language::English => "Installing Modified DLL...",
            Language::PortugueseBR | Language::PortuguesePT => "Instalando DLL Modificada...",
            Language::Spanish => "Instalando DLL Modificada...",
            Language::French => "Installation de la DLL Modifiée...",
            Language::German => "Modifizierte DLL wird installiert...",
            Language::ChineseSimplified => "正在安装修改的DLL...",
            Language::Russian => "Установка модифицированной DLL...",
        }
    }

    pub fn modified_installed() -> &'static str {
        match get_language() {
            Language::English => "Modified DLL installed successfully! ✓",
            Language::PortugueseBR | Language::PortuguesePT => "DLL Modificada instalada com sucesso! ✓",
            Language::Spanish => "¡DLL Modificada instalada exitosamente! ✓",
            Language::French => "DLL Modifiée installée avec succès! ✓",
            Language::German => "Modifizierte DLL erfolgreich installiert! ✓",
            Language::ChineseSimplified => "修改的DLL安装成功！✓",
            Language::Russian => "Модифицированная DLL успешно установлена! ✓",
        }
    }

    pub fn can_start_minecraft() -> &'static str {
        match get_language() {
            Language::English => "You can now start Minecraft! 🎮",
            Language::PortugueseBR | Language::PortuguesePT => "Agora você pode iniciar o Minecraft! 🎮",
            Language::Spanish => "¡Ahora puedes iniciar Minecraft! 🎮",
            Language::French => "Vous pouvez maintenant démarrer Minecraft! 🎮",
            Language::German => "Sie können jetzt Minecraft starten! 🎮",
            Language::ChineseSimplified => "现在可以启动Minecraft了！🎮",
            Language::Russian => "Теперь можно запустить Minecraft! 🎮",
        }
    }

    pub fn opening_minecraft() -> &'static str {
        match get_language() {
            Language::English => "Opening Minecraft...",
            Language::PortugueseBR | Language::PortuguesePT => "Abrindo Minecraft...",
            Language::Spanish => "Abriendo Minecraft...",
            Language::French => "Ouverture de Minecraft...",
            Language::German => "Minecraft wird geöffnet...",
            Language::ChineseSimplified => "正在打开Minecraft...",
            Language::Russian => "Открытие Minecraft...",
        }
    }

    pub fn minecraft_started() -> &'static str {
        match get_language() {
            Language::English => "Minecraft started! 🎮",
            Language::PortugueseBR | Language::PortuguesePT => "Minecraft iniciado! 🎮",
            Language::Spanish => "¡Minecraft iniciado! 🎮",
            Language::French => "Minecraft démarré! 🎮",
            Language::German => "Minecraft gestartet! 🎮",
            Language::ChineseSimplified => "Minecraft已启动！🎮",
            Language::Russian => "Minecraft запущен! 🎮",
        }
    }

    pub fn opening_store() -> &'static str {
        match get_language() {
            Language::English => "Opening Xbox website...",
            Language::PortugueseBR | Language::PortuguesePT => "Abrindo site do Xbox...",
            Language::Spanish => "Abriendo sitio web de Xbox...",
            Language::French => "Ouverture du site Xbox...",
            Language::German => "Xbox-Website wird geöffnet...",
            Language::ChineseSimplified => "正在打开Xbox网站...",
            Language::Russian => "Открытие сайта Xbox...",
        }
    }

    pub fn store_opened() -> &'static str {
        match get_language() {
            Language::English => "Browser opened! 🌐",
            Language::PortugueseBR | Language::PortuguesePT => "Navegador aberto! 🌐",
            Language::Spanish => "¡Navegador abierto! 🌐",
            Language::French => "Navigateur ouvert! 🌐",
            Language::German => "Browser geöffnet! 🌐",
            Language::ChineseSimplified => "浏览器已打开！🌐",
            Language::Russian => "Браузер открыт! 🌐",
        }
    }

    pub fn opening_youtube() -> &'static str {
        match get_language() {
            Language::English => "🎬 Opening CoelhoFZ YouTube channel...",
            Language::PortugueseBR | Language::PortuguesePT => "🎬 Abrindo o canal do CoelhoFZ no YouTube...",
            Language::Spanish => "🎬 Abriendo el canal de CoelhoFZ en YouTube...",
            Language::French => "🎬 Ouverture de la chaîne YouTube de CoelhoFZ...",
            Language::German => "🎬 CoelhoFZ YouTube-Kanal wird geöffnet...",
            Language::ChineseSimplified => "🎬 正在打开CoelhoFZ的YouTube频道...",
            Language::Russian => "🎬 Открытие канала CoelhoFZ на YouTube...",
        }
    }

    pub fn youtube_opened() -> &'static str {
        match get_language() {
            Language::English => "✓ Browser opened! Subscribe! 👍",
            Language::PortugueseBR => "✓ Navegador aberto! Se inscreve lá po! 👍",
            Language::PortuguesePT => "✓ Navegador aberto! Subscreve! 👍",
            Language::Spanish => "✓ ¡Navegador abierto! ¡Suscríbete! 👍",
            Language::French => "✓ Navigateur ouvert! Abonnez-vous! 👍",
            Language::German => "✓ Browser geöffnet! Abonnieren! 👍",
            Language::ChineseSimplified => "✓ 浏览器已打开！订阅！👍",
            Language::Russian => "✓ Браузер открыт! Подпишись! 👍",
        }
    }

    pub fn system_status() -> &'static str {
        match get_language() {
            Language::English => "SYSTEM STATUS",
            Language::PortugueseBR | Language::PortuguesePT => "STATUS DO SISTEMA",
            Language::Spanish => "ESTADO DEL SISTEMA",
            Language::French => "STATUT DU SYSTÈME",
            Language::German => "SYSTEMSTATUS",
            Language::ChineseSimplified => "系统状态",
            Language::Russian => "СОСТОЯНИЕ СИСТЕМЫ",
        }
    }

    pub fn minecraft_installed() -> &'static str {
        match get_language() {
            Language::English => "Minecraft installed:",
            Language::PortugueseBR | Language::PortuguesePT => "Minecraft instalado:",
            Language::Spanish => "Minecraft instalado:",
            Language::French => "Minecraft installé:",
            Language::German => "Minecraft installiert:",
            Language::ChineseSimplified => "Minecraft已安装:",
            Language::Russian => "Minecraft установлен:",
        }
    }

    pub fn yes() -> &'static str {
        match get_language() {
            Language::English => "✓ YES",
            Language::PortugueseBR | Language::PortuguesePT => "✓ SIM",
            Language::Spanish => "✓ SÍ",
            Language::French => "✓ OUI",
            Language::German => "✓ JA",
            Language::ChineseSimplified => "✓ 是",
            Language::Russian => "✓ ДА",
        }
    }

    pub fn no() -> &'static str {
        match get_language() {
            Language::English => "✗ NO",
            Language::PortugueseBR | Language::PortuguesePT => "✗ NÃO",
            Language::Spanish => "✗ NO",
            Language::French => "✗ NON",
            Language::German => "✗ NEIN",
            Language::ChineseSimplified => "✗ 否",
            Language::Russian => "✗ НЕТ",
        }
    }

    pub fn dll_path() -> &'static str {
        match get_language() {
            Language::English => "DLL Path:",
            Language::PortugueseBR | Language::PortuguesePT => "Caminho da DLL:",
            Language::Spanish => "Ruta de DLL:",
            Language::French => "Chemin DLL:",
            Language::German => "DLL-Pfad:",
            Language::ChineseSimplified => "DLL路径:",
            Language::Russian => "Путь к DLL:",
        }
    }

    pub fn dll_state() -> &'static str {
        match get_language() {
            Language::English => "DLL State:",
            Language::PortugueseBR | Language::PortuguesePT => "Estado da DLL:",
            Language::Spanish => "Estado de DLL:",
            Language::French => "État DLL:",
            Language::German => "DLL-Status:",
            Language::ChineseSimplified => "DLL状态:",
            Language::Russian => "Состояние DLL:",
        }
    }

    pub fn dll_original_locked() -> &'static str {
        match get_language() {
            Language::English => "Original DLL (locked)",
            Language::PortugueseBR | Language::PortuguesePT => "DLL Original (bloqueada)",
            Language::Spanish => "DLL Original (bloqueada)",
            Language::French => "DLL Originale (verrouillée)",
            Language::German => "Originale DLL (gesperrt)",
            Language::ChineseSimplified => "原始DLL (锁定)",
            Language::Russian => "Оригинальная DLL (заблокирована)",
        }
    }

    pub fn dll_modified_unlocked() -> &'static str {
        match get_language() {
            Language::English => "Modified DLL (unlocked)",
            Language::PortugueseBR | Language::PortuguesePT => "DLL Modificada (desbloqueada)",
            Language::Spanish => "DLL Modificada (desbloqueada)",
            Language::French => "DLL Modifiée (déverrouillée)",
            Language::German => "Modifizierte DLL (entsperrt)",
            Language::ChineseSimplified => "修改的DLL (解锁)",
            Language::Russian => "Модифицированная DLL (разблокирована)",
        }
    }

    pub fn dll_unknown() -> &'static str {
        match get_language() {
            Language::English => "Unknown DLL",
            Language::PortugueseBR | Language::PortuguesePT => "DLL desconhecida",
            Language::Spanish => "DLL desconocida",
            Language::French => "DLL inconnue",
            Language::German => "Unbekannte DLL",
            Language::ChineseSimplified => "未知DLL",
            Language::Russian => "Неизвестная DLL",
        }
    }

    pub fn processes_using_dll() -> &'static str {
        match get_language() {
            Language::English => "Processes are using the DLL...",
            Language::PortugueseBR | Language::PortuguesePT => "Processos estão usando a DLL...",
            Language::Spanish => "Los procesos están usando la DLL...",
            Language::French => "Les processus utilisent la DLL...",
            Language::German => "Prozesse verwenden die DLL...",
            Language::ChineseSimplified => "进程正在使用DLL...",
            Language::Russian => "Процессы используют DLL...",
        }
    }

    pub fn operation_cancelled() -> &'static str {
        match get_language() {
            Language::English => "Operation cancelled by user.",
            Language::PortugueseBR | Language::PortuguesePT => "Operação cancelada pelo usuário.",
            Language::Spanish => "Operación cancelada por el usuario.",
            Language::French => "Opération annulée par l'utilisateur.",
            Language::German => "Vorgang vom Benutzer abgebrochen.",
            Language::ChineseSimplified => "用户取消操作。",
            Language::Russian => "Операция отменена пользователем.",
        }
    }

    pub fn closing_processes() -> &'static str {
        match get_language() {
            Language::English => "Closing processes...",
            Language::PortugueseBR | Language::PortuguesePT => "Encerrando processos...",
            Language::Spanish => "Cerrando procesos...",
            Language::French => "Fermeture des processus...",
            Language::German => "Prozesse werden geschlossen...",
            Language::ChineseSimplified => "正在关闭进程...",
            Language::Russian => "Закрытие процессов...",
        }
    }

    pub fn waiting_file_release() -> &'static str {
        match get_language() {
            Language::English => "Waiting for file release...",
            Language::PortugueseBR | Language::PortuguesePT => "Aguardando liberação do arquivo...",
            Language::Spanish => "Esperando la liberación del archivo...",
            Language::French => "En attente de la libération du fichier...",
            Language::German => "Warten auf Dateifreigabe...",
            Language::ChineseSimplified => "等待文件释放...",
            Language::Russian => "Ожидание освобождения файла...",
        }
    }

    pub fn trying_permissions() -> &'static str {
        match get_language() {
            Language::English => "Trying with permission adjustment...",
            Language::PortugueseBR | Language::PortuguesePT => "Tentando com ajuste de permissões...",
            Language::Spanish => "Intentando con ajuste de permisos...",
            Language::French => "Tentative avec ajustement des permissions...",
            Language::German => "Versuch mit Berechtigungsanpassung...",
            Language::ChineseSimplified => "正在尝试调整权限...",
            Language::Russian => "Попытка с настройкой разрешений...",
        }
    }

    pub fn attempt_failed(attempt: u32) -> String {
        match get_language() {
            Language::English => format!("Attempt {} failed, trying again...", attempt),
            Language::PortugueseBR | Language::PortuguesePT => format!("Tentativa {} falhou, tentando novamente...", attempt),
            Language::Spanish => format!("Intento {} falló, intentando de nuevo...", attempt),
            Language::French => format!("Tentative {} échouée, nouvelle tentative...", attempt),
            Language::German => format!("Versuch {} fehlgeschlagen, erneuter Versuch...", attempt),
            Language::ChineseSimplified => format!("尝试 {} 失败，正在重试...", attempt),
            Language::Russian => format!("Попытка {} не удалась, повторная попытка...", attempt),
        }
    }

    pub fn restoring_original() -> &'static str {
        match get_language() {
            Language::English => "Restoring Original DLL...",
            Language::PortugueseBR | Language::PortuguesePT => "Restaurando DLL Original...",
            Language::Spanish => "Restaurando DLL Original...",
            Language::French => "Restauration de la DLL Originale...",
            Language::German => "Originale DLL wird wiederhergestellt...",
            Language::ChineseSimplified => "正在恢复原始DLL...",
            Language::Russian => "Восстановление оригинальной DLL...",
        }
    }

    pub fn original_restored() -> &'static str {
        match get_language() {
            Language::English => "Original DLL restored successfully!",
            Language::PortugueseBR | Language::PortuguesePT => "DLL Original restaurada com sucesso!",
            Language::Spanish => "¡DLL Original restaurada con éxito!",
            Language::French => "DLL Originale restaurée avec succès!",
            Language::German => "Originale DLL erfolgreich wiederhergestellt!",
            Language::ChineseSimplified => "原始DLL恢复成功！",
            Language::Russian => "Оригинальная DLL успешно восстановлена!",
        }
    }

    // New translations for OnlineFix bypass
    pub fn minecraft_path() -> &'static str {
        match get_language() {
            Language::English => "Minecraft Path",
            Language::PortugueseBR | Language::PortuguesePT => "Pasta do Minecraft",
            Language::Spanish => "Ruta de Minecraft",
            Language::French => "Chemin Minecraft",
            Language::German => "Minecraft-Pfad",
            Language::ChineseSimplified => "Minecraft路径",
            Language::Russian => "Путь к Minecraft",
        }
    }

    pub fn bypass_status() -> &'static str {
        match get_language() {
            Language::English => "Bypass Status:",
            Language::PortugueseBR | Language::PortuguesePT => "Status do Bypass:",
            Language::Spanish => "Estado del Bypass:",
            Language::French => "Statut du Bypass:",
            Language::German => "Bypass-Status:",
            Language::ChineseSimplified => "绕过状态:",
            Language::Russian => "Статус обхода:",
        }
    }

    pub fn installed() -> &'static str {
        match get_language() {
            Language::English => "INSTALLED ✓",
            Language::PortugueseBR | Language::PortuguesePT => "INSTALADO ✓",
            Language::Spanish => "INSTALADO ✓",
            Language::French => "INSTALLÉ ✓",
            Language::German => "INSTALLIERT ✓",
            Language::ChineseSimplified => "已安装 ✓",
            Language::Russian => "УСТАНОВЛЕНО ✓",
        }
    }

    pub fn not_installed() -> &'static str {
        match get_language() {
            Language::English => "NOT INSTALLED ✗",
            Language::PortugueseBR | Language::PortuguesePT => "NÃO INSTALADO ✗",
            Language::Spanish => "NO INSTALADO ✗",
            Language::French => "NON INSTALLÉ ✗",
            Language::German => "NICHT INSTALLIERT ✗",
            Language::ChineseSimplified => "未安装 ✗",
            Language::Russian => "НЕ УСТАНОВЛЕНО ✗",
        }
    }

    pub fn installing_bypass() -> &'static str {
        match get_language() {
            Language::English => "Installing OnlineFix bypass...",
            Language::PortugueseBR | Language::PortuguesePT => "Instalando bypass OnlineFix...",
            Language::Spanish => "Instalando bypass OnlineFix...",
            Language::French => "Installation du bypass OnlineFix...",
            Language::German => "OnlineFix-Bypass wird installiert...",
            Language::ChineseSimplified => "正在安装OnlineFix绕过...",
            Language::Russian => "Установка обхода OnlineFix...",
        }
    }

    pub fn minecraft_running() -> &'static str {
        match get_language() {
            Language::English => "Minecraft is running!",
            Language::PortugueseBR | Language::PortuguesePT => "Minecraft está rodando!",
            Language::Spanish => "¡Minecraft está ejecutándose!",
            Language::French => "Minecraft est en cours d'exécution!",
            Language::German => "Minecraft läuft!",
            Language::ChineseSimplified => "Minecraft正在运行！",
            Language::Russian => "Minecraft запущен!",
        }
    }

    pub fn closing_minecraft() -> &'static str {
        match get_language() {
            Language::English => "Closing Minecraft...",
            Language::PortugueseBR | Language::PortuguesePT => "Fechando Minecraft...",
            Language::Spanish => "Cerrando Minecraft...",
            Language::French => "Fermeture de Minecraft...",
            Language::German => "Minecraft wird geschlossen...",
            Language::ChineseSimplified => "正在关闭Minecraft...",
            Language::Russian => "Закрытие Minecraft...",
        }
    }

    pub fn file_installed() -> &'static str {
        match get_language() {
            Language::English => "installed",
            Language::PortugueseBR | Language::PortuguesePT => "instalado",
            Language::Spanish => "instalado",
            Language::French => "installé",
            Language::German => "installiert",
            Language::ChineseSimplified => "已安装",
            Language::Russian => "установлен",
        }
    }

    pub fn failed_to_install() -> &'static str {
        match get_language() {
            Language::English => "Failed to install",
            Language::PortugueseBR | Language::PortuguesePT => "Falha ao instalar",
            Language::Spanish => "Error al instalar",
            Language::French => "Échec de l'installation",
            Language::German => "Installation fehlgeschlagen",
            Language::ChineseSimplified => "安装失败",
            Language::Russian => "Ошибка установки",
        }
    }

    pub fn bypass_installed() -> &'static str {
        match get_language() {
            Language::English => "OnlineFix bypass installed successfully!",
            Language::PortugueseBR | Language::PortuguesePT => "Bypass OnlineFix instalado com sucesso!",
            Language::Spanish => "¡Bypass OnlineFix instalado con éxito!",
            Language::French => "Bypass OnlineFix installé avec succès!",
            Language::German => "OnlineFix-Bypass erfolgreich installiert!",
            Language::ChineseSimplified => "OnlineFix绕过安装成功！",
            Language::Russian => "Обход OnlineFix успешно установлен!",
        }
    }

    pub fn open_minecraft_now() -> &'static str {
        match get_language() {
            Language::English => "Open Minecraft from Start Menu.",
            Language::PortugueseBR | Language::PortuguesePT => "Abra o Minecraft pelo Menu Iniciar.",
            Language::Spanish => "Abre Minecraft desde el Menú Inicio.",
            Language::French => "Ouvrez Minecraft depuis le Menu Démarrer.",
            Language::German => "Öffnen Sie Minecraft über das Startmenü.",
            Language::ChineseSimplified => "从开始菜单打开Minecraft。",
            Language::Russian => "Откройте Minecraft из меню Пуск.",
        }
    }

    pub fn removing_bypass() -> &'static str {
        match get_language() {
            Language::English => "Removing OnlineFix bypass...",
            Language::PortugueseBR | Language::PortuguesePT => "Removendo bypass OnlineFix...",
            Language::Spanish => "Eliminando bypass OnlineFix...",
            Language::French => "Suppression du bypass OnlineFix...",
            Language::German => "OnlineFix-Bypass wird entfernt...",
            Language::ChineseSimplified => "正在移除OnlineFix绕过...",
            Language::Russian => "Удаление обхода OnlineFix...",
        }
    }

    pub fn file_removed() -> &'static str {
        match get_language() {
            Language::English => "removed",
            Language::PortugueseBR | Language::PortuguesePT => "removido",
            Language::Spanish => "eliminado",
            Language::French => "supprimé",
            Language::German => "entfernt",
            Language::ChineseSimplified => "已移除",
            Language::Russian => "удалён",
        }
    }

    pub fn failed_to_remove() -> &'static str {
        match get_language() {
            Language::English => "Failed to remove",
            Language::PortugueseBR | Language::PortuguesePT => "Falha ao remover",
            Language::Spanish => "Error al eliminar",
            Language::French => "Échec de la suppression",
            Language::German => "Entfernen fehlgeschlagen",
            Language::ChineseSimplified => "移除失败",
            Language::Russian => "Ошибка удаления",
        }
    }

    pub fn bypass_removed() -> &'static str {
        match get_language() {
            Language::English => "Bypass removed! Game restored to Trial mode.",
            Language::PortugueseBR | Language::PortuguesePT => "Bypass removido! Jogo restaurado ao modo Trial.",
            Language::Spanish => "¡Bypass eliminado! Juego restaurado al modo Trial.",
            Language::French => "Bypass supprimé! Jeu restauré en mode Trial.",
            Language::German => "Bypass entfernt! Spiel auf Trial-Modus zurückgesetzt.",
            Language::ChineseSimplified => "绕过已移除！游戏恢复为试用模式。",
            Language::Russian => "Обход удалён! Игра восстановлена в пробный режим.",
        }
    }

    pub fn adding_defender_exclusion() -> &'static str {
        match get_language() {
            Language::English => "Adding Windows Defender exclusion...",
            Language::PortugueseBR | Language::PortuguesePT => "Adicionando exclusão no Windows Defender...",
            Language::Spanish => "Agregando exclusión en Windows Defender...",
            Language::French => "Ajout d'une exclusion Windows Defender...",
            Language::German => "Windows Defender-Ausnahme wird hinzugefügt...",
            Language::ChineseSimplified => "正在添加Windows Defender排除项...",
            Language::Russian => "Добавление исключения в Windows Defender...",
        }
    }

    pub fn defender_exclusion_added() -> &'static str {
        match get_language() {
            Language::English => "Windows Defender exclusion added!",
            Language::PortugueseBR | Language::PortuguesePT => "Exclusão do Windows Defender adicionada!",
            Language::Spanish => "¡Exclusión de Windows Defender agregada!",
            Language::French => "Exclusion Windows Defender ajoutée!",
            Language::German => "Windows Defender-Ausnahme hinzugefügt!",
            Language::ChineseSimplified => "Windows Defender排除项已添加！",
            Language::Russian => "Исключение Windows Defender добавлено!",
        }
    }

    pub fn defender_exclusion_failed() -> &'static str {
        match get_language() {
            Language::English => "Could not add Defender exclusion (may already exist or Defender disabled)",
            Language::PortugueseBR | Language::PortuguesePT => "Não foi possível adicionar exclusão do Defender (pode já existir ou Defender desativado)",
            Language::Spanish => "No se pudo agregar exclusión de Defender (puede ya existir o Defender desactivado)",
            Language::French => "Impossible d'ajouter l'exclusion Defender (peut déjà exister ou Defender désactivé)",
            Language::German => "Defender-Ausnahme konnte nicht hinzugefügt werden (existiert möglicherweise bereits oder Defender deaktiviert)",
            Language::ChineseSimplified => "无法添加Defender排除项（可能已存在或Defender已禁用）",
            Language::Russian => "Не удалось добавить исключение Defender (возможно, уже существует или Defender отключён)",
        }
    }
}