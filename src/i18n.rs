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
    // Try to detect from Windows locale
    if let Ok(locale) = std::env::var("LANG") {
        return parse_locale(&locale);
    }
    
    // Fallback: try Windows-specific environment variables
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
            Language::English => "Install Minecraft Bedrock (Microsoft Store)",
            Language::PortugueseBR | Language::PortuguesePT => "Instalar Minecraft Bedrock (Microsoft Store)",
            Language::Spanish => "Instalar Minecraft Bedrock (Microsoft Store)",
            Language::French => "Installer Minecraft Bedrock (Microsoft Store)",
            Language::German => "Minecraft Bedrock installieren (Microsoft Store)",
            Language::ChineseSimplified => "安装Minecraft基岩版 (微软商店)",
            Language::Russian => "Установить Minecraft Bedrock (Microsoft Store)",
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
            Language::English => "Opening Microsoft Store...",
            Language::PortugueseBR | Language::PortuguesePT => "Abrindo Microsoft Store...",
            Language::Spanish => "Abriendo Microsoft Store...",
            Language::French => "Ouverture du Microsoft Store...",
            Language::German => "Microsoft Store wird geöffnet...",
            Language::ChineseSimplified => "正在打开微软商店...",
            Language::Russian => "Открытие Microsoft Store...",
        }
    }

    pub fn store_opened() -> &'static str {
        match get_language() {
            Language::English => "Store opened! 🛒",
            Language::PortugueseBR | Language::PortuguesePT => "Store aberta! 🛒",
            Language::Spanish => "¡Store abierta! 🛒",
            Language::French => "Store ouvert! 🛒",
            Language::German => "Store geöffnet! 🛒",
            Language::ChineseSimplified => "商店已打开！🛒",
            Language::Russian => "Магазин открыт! 🛒",
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
}
