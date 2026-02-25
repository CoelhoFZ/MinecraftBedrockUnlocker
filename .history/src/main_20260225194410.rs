use anyhow::{Result, Context};
use clap::{Parser, Subcommand};
use colored::*;
use std::io::{self, Write};
use windows::Win32::System::Console::{
    GetStdHandle, SetConsoleScreenBufferSize, SetConsoleWindowInfo, 
    GetConsoleMode, SetConsoleMode, STD_OUTPUT_HANDLE, STD_INPUT_HANDLE,
    COORD, SMALL_RECT, CONSOLE_MODE, ENABLE_QUICK_EDIT_MODE, ENABLE_EXTENDED_FLAGS,
    ENABLE_VIRTUAL_TERMINAL_PROCESSING
};

mod dll_manager;
mod utils;
mod process_utils;
mod minecraft;
mod i18n;
mod health_check;
mod antivirus;
mod auto_update;
mod diagnostics;

use dll_manager::DllManager;
use i18n::Translations;
use health_check::HealthCheck;
use antivirus::AntivirusDetector;
use auto_update::AutoUpdater;
use diagnostics::Diagnostics;

/// MINECRAFT UNLOCKER CLI - byCoelhoFZ
/// Minecraft DLL Manager (Console Mode)
#[derive(Parser)]
#[command(name = "MinecraftUnlocker")]
#[command(version = env!("CARGO_PKG_VERSION"))]
#[command(about = "Minecraft Bedrock Edition DLL Manager", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    /// Install modified DLL
    InstalarMod,
    /// Restore original DLL
    RestaurarOriginal,
    /// Open Minecraft
    AbrirMinecraft,
    /// Open Minecraft Microsoft Store page
    AbrirStore,
    /// Check current status
    Status,
}

fn main() -> Result<()> {
    // Initialize i18n system
    i18n::init_language();
    
    // Environment initialization
    let _ = std::env::current_dir();
    let _ = std::env::var("USERNAME");
    
    // Small delay to ensure complete initialization
    std::thread::sleep(std::time::Duration::from_millis(100));
    
    set_console_size(); // Set window size
    print_banner();

    let cli = Cli::parse();

    // Check if running as administrator - if not, re-launch with elevation
    if !is_elevated() {
        // Try to re-launch with admin rights
        if !request_elevation() {
            eprintln!("{}", Translations::admin_required().red().bold());
            eprintln!("{}", Translations::admin_how_to().yellow());
            eprintln!();
            eprintln!("{}", press_enter_to_exit());
            let _ = io::stdin().read_line(&mut String::new());
        }
        std::process::exit(0); // Exit this non-elevated instance
    }

    let manager = DllManager::new()?;

    match cli.command {
        Some(Commands::InstalarMod) => manager.install_modified()?,
        Some(Commands::RestaurarOriginal) => manager.restore_original()?,
        Some(Commands::AbrirMinecraft) => minecraft::open_minecraft()?,
        Some(Commands::AbrirStore) => minecraft::open_store()?,
        Some(Commands::Status) => manager.show_status()?,
        None => run_interactive(manager)?,
    }

    Ok(())
}

fn set_console_size() {
    unsafe {
        // Disable Quick Edit Mode (text selection) to avoid pauses when clicking
        if let Ok(input_handle) = GetStdHandle(STD_INPUT_HANDLE) {
            let mut mode = CONSOLE_MODE(0);
            if GetConsoleMode(input_handle, &mut mode).is_ok() {
                // First enable ENABLE_EXTENDED_FLAGS, then remove ENABLE_QUICK_EDIT_MODE
                mode = CONSOLE_MODE(mode.0 | ENABLE_EXTENDED_FLAGS.0);
                mode = CONSOLE_MODE(mode.0 & !ENABLE_QUICK_EDIT_MODE.0);
                let _ = SetConsoleMode(input_handle, mode);
            }
        }
        
        if let Ok(handle) = GetStdHandle(STD_OUTPUT_HANDLE) {
            // ENABLE ANSI COLORS: Set ENABLE_VIRTUAL_TERMINAL_PROCESSING
            let mut mode = CONSOLE_MODE(0);
            if GetConsoleMode(handle, &mut mode).is_ok() {
                mode = CONSOLE_MODE(mode.0 | ENABLE_VIRTUAL_TERMINAL_PROCESSING.0);
                let _ = SetConsoleMode(handle, mode);
            }
            
            // FIRST: Shrink window to minimum
            let min_window = SMALL_RECT {
                Left: 0,
                Top: 0,
                Right: 0,
                Bottom: 0,
            };
            let _ = SetConsoleWindowInfo(handle, true, &min_window);
            
            // SECOND: Set exact buffer size (84x50) - increased for more content
            let buffer_size = COORD { X: 84, Y: 50 };
            let _ = SetConsoleScreenBufferSize(handle, buffer_size);
            
            // THIRD: Expand window to buffer size (removes scrollbar)
            let window_rect = SMALL_RECT {
                Left: 0,
                Top: 0,
                Right: 83,  // 84 columns (0-83)
                Bottom: 34, // 35 lines (0-34) - taller window
            };
            let _ = SetConsoleWindowInfo(handle, true, &window_rect);
        }
    }
}

fn print_banner() {
    // Clear screen completely
    print!("\x1B[2J\x1B[1;1H");
    
    println!();
    println!("      ╔══════════════════════════════════════════════════════════════════════╗");
    println!("      ║ ██╗   ██╗███╗   ██╗██╗      ██████╗  ██████╗██╗  ██╗███████╗██████╗  ║");
    println!("      ║ ██║   ██║████╗  ██║██║     ██╔═══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗ ║");
    println!("      ║ ██║   ██║██╔██╗ ██║██║     ██║   ██║██║     █████╔╝ █████╗  ██████╔╝ ║");
    println!("      ║ ██║   ██║██║╚██╗██║██║     ██║   ██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗ ║");
    println!("      ║ ╚██████╔╝██║ ╚████║███████╗╚██████╔╝╚██████╗██║  ██╗███████╗██║  ██║ ║");
    println!("      ║  ╚═════╝ ╚═╝  ╚═══╝╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ║");
    println!("      ║                                        Minecraft Bedrock byCoelhoFZ  ║");
    println!("      ╚══════════════════════════════════════════════════════════════════════╝");
    println!();
}

fn print_menu(show_extra_options: bool) {
    println!("                        {}                  ", Translations::available_options().green().bold());
    println!();
    println!("                {} {}        ", "[1]".green().bold(), Translations::menu_option_1().white());
    println!("                {} {}        ", "[2]".green().bold(), Translations::menu_option_2().white());
    println!("                {} {}          ", "[3]".green().bold(), Translations::menu_option_3().white());
    println!("                {} {}", "[4]".green().bold(), Translations::menu_option_4().white());
    println!("                {} {}       ", "[5]".green().bold(), Translations::menu_option_5().white());
    println!("                {} {}", "[6]".cyan().bold(), menu_diagnostics().white());
    println!("                {} {}", "[7]".cyan().bold(), menu_check_updates().white());
    println!("                {} {}               ", "[0]".red().bold(), Translations::menu_option_0().white());
    if show_extra_options {
        println!("                {} {}", "[8]".yellow().bold(), Translations::menu_option_6().white());
    }
    println!();
    println!("             ════════════════════════════════════════════════");
    println!();
    // Display version at bottom
    println!("                              {} {}", "v".dimmed(), env!("CARGO_PKG_VERSION").dimmed());
    println!();
}

fn menu_diagnostics() -> &'static str {
    use i18n::get_language;
    use i18n::Language;
    match get_language() {
        Language::English => "System Diagnostics",
        Language::PortugueseBR | Language::PortuguesePT => "Diagnóstico do Sistema",
        Language::Spanish => "Diagnóstico del Sistema",
        Language::French => "Diagnostic Système",
        Language::German => "Systemdiagnose",
        Language::ChineseSimplified => "系统诊断",
        Language::Russian => "Диагностика системы",
    }
}

fn menu_check_updates() -> &'static str {
    use i18n::get_language;
    use i18n::Language;
    match get_language() {
        Language::English => "Check for Updates",
        Language::PortugueseBR | Language::PortuguesePT => "Verificar Atualizações",
        Language::Spanish => "Buscar Actualizaciones",
        Language::French => "Vérifier les Mises à Jour",
        Language::German => "Nach Updates suchen",
        Language::ChineseSimplified => "检查更新",
        Language::Russian => "Проверить обновления",
    }
}

fn update_download_prompt() -> &'static str {
    use i18n::get_language;
    use i18n::Language;
    match get_language() {
        Language::English => "Visit GitHub to download the new version:",
        Language::PortugueseBR | Language::PortuguesePT => "Visite o GitHub para baixar a nova versão:",
        Language::Spanish => "Visite GitHub para descargar la nueva versión:",
        Language::French => "Visitez GitHub pour télécharger la nouvelle version:",
        Language::German => "Besuchen Sie GitHub für die neue Version:",
        Language::ChineseSimplified => "访问GitHub下载新版本:",
        Language::Russian => "Посетите GitHub для загрузки новой версии:",
    }
}

fn press_enter_to_exit() -> &'static str {
    use i18n::get_language;
    use i18n::Language;
    match get_language() {
        Language::English => "Press Enter to exit...",
        Language::PortugueseBR | Language::PortuguesePT => "Pressione Enter para sair...",
        Language::Spanish => "Presione Enter para salir...",
        Language::French => "Appuyez sur Entree pour quitter...",
        Language::German => "Druecken Sie Enter zum Beenden...",
        Language::ChineseSimplified => "按回车键退出...",
        Language::Russian => "Нажмите Enter для выхода...",
    }
}

fn bypass_files_missing() -> &'static str {
    use i18n::get_language;
    use i18n::Language;
    match get_language() {
        Language::English => "Some bypass files are missing!",
        Language::PortugueseBR | Language::PortuguesePT => "Alguns arquivos do bypass estão faltando!",
        Language::Spanish => "¡Faltan algunos archivos del bypass!",
        Language::French => "Certains fichiers du bypass sont manquants!",
        Language::German => "Einige Bypass-Dateien fehlen!",
        Language::ChineseSimplified => "部分绕过文件缺失！",
        Language::Russian => "Некоторые файлы обхода отсутствуют!",
    }
}

fn auto_repair_success() -> &'static str {
    use i18n::get_language;
    use i18n::Language;
    match get_language() {
        Language::English => "Auto-repair successful!",
        Language::PortugueseBR | Language::PortuguesePT => "Reparo automático bem-sucedido!",
        Language::Spanish => "¡Reparación automática exitosa!",
        Language::French => "Réparation automatique réussie!",
        Language::German => "Automatische Reparatur erfolgreich!",
        Language::ChineseSimplified => "自动修复成功！",
        Language::Russian => "Автоматическое восстановление успешно!",
    }
}

fn auto_repair_failed_msg() -> &'static str {
    use i18n::get_language;
    use i18n::Language;
    match get_language() {
        Language::English => "Auto-repair failed - antivirus may be blocking",
        Language::PortugueseBR | Language::PortuguesePT => "Reparo automático falhou - antivírus pode estar bloqueando",
        Language::Spanish => "Reparación automática fallida - el antivirus puede estar bloqueando",
        Language::French => "Réparation automatique échouée - l'antivirus peut bloquer",
        Language::German => "Automatische Reparatur fehlgeschlagen - Antivirus blockiert möglicherweise",
        Language::ChineseSimplified => "自动修复失败 - 杀毒软件可能正在阻止",
        Language::Russian => "Автоматическое восстановление не удалось - антивирус может блокировать",
    }
}

fn reinstall_bypass_hint() -> &'static str {
    use i18n::get_language;
    use i18n::Language;
    match get_language() {
        Language::English => "Use option [1] to reinstall the bypass",
        Language::PortugueseBR | Language::PortuguesePT => "Use a opção [1] para reinstalar o bypass",
        Language::Spanish => "Use la opción [1] para reinstalar el bypass",
        Language::French => "Utilisez l'option [1] pour réinstaller le bypass",
        Language::German => "Verwenden Sie Option [1] um den Bypass neu zu installieren",
        Language::ChineseSimplified => "使用选项[1]重新安装绕过",
        Language::Russian => "Используйте опцию [1] для переустановки обхода",
    }
}

fn bypass_not_installed_msg() -> &'static str {
    use i18n::get_language;
    use i18n::Language;
    match get_language() {
        Language::English => "Bypass is not installed yet!",
        Language::PortugueseBR | Language::PortuguesePT => "Bypass ainda não está instalado!",
        Language::Spanish => "¡El bypass aún no está instalado!",
        Language::French => "Le bypass n'est pas encore installé!",
        Language::German => "Bypass ist noch nicht installiert!",
        Language::ChineseSimplified => "绕过尚未安装！",
        Language::Russian => "Обход ещё не установлен!",
    }
}

fn install_bypass_first() -> &'static str {
    use i18n::get_language;
    use i18n::Language;
    match get_language() {
        Language::English => "Please install the bypass first with option [1]",
        Language::PortugueseBR | Language::PortuguesePT => "Por favor, instale o bypass primeiro com a opção [1]",
        Language::Spanish => "Por favor, instale el bypass primero con la opción [1]",
        Language::French => "Veuillez d'abord installer le bypass avec l'option [1]",
        Language::German => "Bitte installieren Sie zuerst den Bypass mit Option [1]",
        Language::ChineseSimplified => "请先使用选项[1]安装绕过",
        Language::Russian => "Пожалуйста, сначала установите обход с помощью опции [1]",
    }
}

fn clear_and_show_banner() {
    print_banner();
}

fn open_youtube_channel() -> Result<()> {
    println!("      {}", Translations::opening_youtube().cyan().bold());
    println!();
    
    let url = "https://www.youtube.com/@CoelhoFZ";
    
    use std::process::Command;
    #[cfg(target_os = "windows")]
    {
        Command::new("cmd")
            .args(&["/C", "start", url])
            .spawn()
            .context("Failed to open browser")?;
    }
    
    println!("      {}", Translations::youtube_opened().green().bold());
    println!("      {}", format!("  Link: {}", url).white());
    
    Ok(())
}

fn wait_and_return_to_menu(show_youtube_option: bool) {
    println!();
    std::thread::sleep(std::time::Duration::from_secs(3));
    print_banner();
    print_menu(show_youtube_option);
}

fn run_interactive(manager: DllManager) -> Result<()> {
    let mut has_used_option = false; // Track if any option was used
    
    print_menu(has_used_option);

    loop {
        let max_option = if has_used_option { "6" } else { "5" };
        let prompt_text = Translations::choose_option(max_option).cyan();
        
        print!("             {} ", prompt_text);
        io::stdout().flush()?;

        let mut input = String::new();
        io::stdin().read_line(&mut input)?;
        let input = input.trim().to_lowercase();

        // Clear screen after choice
        clear_and_show_banner();
        println!();

        match input.as_str() {
            "1" | "instalar-mod" => {
                if let Err(e) = manager.install_modified() {
                    eprintln!();
                    eprintln!("      {} {}", Translations::error().red().bold(), e);
                }
                has_used_option = true; // Mark that an option was used
                wait_and_return_to_menu(has_used_option);
            }
            "2" | "restaurar-original" => {
                if let Err(e) = manager.restore_original() {
                    eprintln!();
                    eprintln!("      {} {}", Translations::error().red().bold(), e);
                }
                has_used_option = true;
                wait_and_return_to_menu(has_used_option);
            }
            "3" | "abrir-minecraft" => {
                // Check bypass health before opening Minecraft
                let health = HealthCheck::new(manager.get_minecraft_path().to_path_buf());
                let status = health.check();
                
                match status {
                    health_check::HealthStatus::Missing(_) => {
                        println!("      {} {}", "[!]".yellow().bold(), bypass_files_missing());
                        // Try auto-repair
                        if health.auto_repair() {
                            println!("      {} {}", Translations::ok().green(), auto_repair_success());
                            std::thread::sleep(std::time::Duration::from_secs(1));
                        } else {
                            println!("      {} {}", Translations::warning().yellow(), auto_repair_failed_msg());
                            println!("      {} {}", Translations::info().cyan(), reinstall_bypass_hint());
                        }
                    }
                    health_check::HealthStatus::NotInstalled => {
                        println!("      {} {}", "[!]".yellow().bold(), bypass_not_installed_msg());
                        println!("      {} {}", Translations::info().cyan(), install_bypass_first());
                    }
                    _ => {}
                }
                
                // Open Minecraft anyway (user may want to test)
                if let Err(e) = minecraft::open_minecraft() {
                    eprintln!("      {} {}", Translations::error().red().bold(), e);
                }
                has_used_option = true;
                wait_and_return_to_menu(has_used_option);
            }
            "4" | "abrir-store" => {
                if let Err(e) = minecraft::open_store() {
                    eprintln!("      {} {}", Translations::error().red().bold(), e);
                }
                has_used_option = true;
                wait_and_return_to_menu(has_used_option);
            }
            "5" | "status" => {
                if let Err(e) = manager.show_status() {
                    eprintln!();
                    eprintln!("      {} {}", Translations::error().red().bold(), e);
                }
                // Also show health check and antivirus status
                println!();
                let health = HealthCheck::new(manager.get_minecraft_path().to_path_buf());
                health.print_status();
                println!();
                AntivirusDetector::print_detected();
                
                has_used_option = true;
                wait_and_return_to_menu(has_used_option);
            }
            "6" | "diagnostics" => {
                // Run full system diagnostics
                let diag = Diagnostics::new(manager.get_minecraft_path().to_path_buf());
                diag.print_results();
                
                has_used_option = true;
                wait_and_return_to_menu(has_used_option);
            }
            "7" | "update" => {
                // Check for updates
                let updater = AutoUpdater::new();
                updater.print_update_status();
                
                // If update available, ask if user wants to download
                if let Some(info) = updater.check_for_updates() {
                    if info.is_newer {
                        println!();
                        println!("                    {} {}", 
                            "[?]".yellow().bold(),
                            update_download_prompt());
                        println!("                    {} {}", 
                            Translations::info().cyan(),
                            "GitHub: https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases");
                    }
                }
                
                has_used_option = true;
                wait_and_return_to_menu(has_used_option);
            }
            "8" => {
                if has_used_option {
                    open_youtube_channel()?;
                    wait_and_return_to_menu(has_used_option);
                } else {
                    println!("      {}", Translations::invalid_option("7").yellow().bold());
                    wait_and_return_to_menu(has_used_option);
                }
            }
            "0" | "sair" | "exit" | "quit" => {
                println!();
                println!("      {}", Translations::exiting().cyan().bold());
                println!();
                std::thread::sleep(std::time::Duration::from_millis(1000));
                break;
            }
            "" => {
                print_banner();
                print_menu(has_used_option);
            }
            _ => {
                let max_option = if has_used_option { "8" } else { "7" };
                println!("      {}", Translations::invalid_option(max_option).yellow().bold());
                wait_and_return_to_menu(has_used_option);
            }
        }
    }

    Ok(())
}

// print_help() removed - was dead code (never called)

fn is_elevated() -> bool {
    use windows::Win32::Security::{GetTokenInformation, TokenElevation, TOKEN_ELEVATION, TOKEN_QUERY};
    use windows::Win32::System::Threading::{GetCurrentProcess, OpenProcessToken};
    use windows::Win32::Foundation::CloseHandle;
    
    unsafe {
        let mut token = windows::Win32::Foundation::HANDLE::default();
        if OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &mut token).is_ok() {
            let mut elevation = TOKEN_ELEVATION::default();
            let mut size = 0u32;
            let result = GetTokenInformation(
                token,
                TokenElevation,
                Some(&mut elevation as *mut _ as *mut std::ffi::c_void),
                std::mem::size_of::<TOKEN_ELEVATION>() as u32,
                &mut size,
            );
            let _ = CloseHandle(token);
            if result.is_ok() {
                return elevation.TokenIsElevated != 0;
            }
        }
        false
    }
}

/// Request elevation by re-launching this exe with admin rights (UAC prompt)
fn request_elevation() -> bool {
    use std::os::windows::ffi::OsStrExt;
    use std::ffi::OsStr;
    use windows::Win32::UI::Shell::ShellExecuteW;
    use windows::Win32::UI::WindowsAndMessaging::SW_SHOWNORMAL;
    use windows::core::PCWSTR;
    
    // Get the current executable path
    let exe_path = match std::env::current_exe() {
        Ok(path) => path,
        Err(_) => return false,
    };
    
    // Convert to wide string
    let exe_wide: Vec<u16> = OsStr::new(&exe_path)
        .encode_wide()
        .chain(std::iter::once(0))
        .collect();
    
    // "runas" verb triggers UAC prompt
    let verb: Vec<u16> = OsStr::new("runas")
        .encode_wide()
        .chain(std::iter::once(0))
        .collect();
    
    unsafe {
        let result = ShellExecuteW(
            None,
            PCWSTR::from_raw(verb.as_ptr()),
            PCWSTR::from_raw(exe_wide.as_ptr()),
            PCWSTR::null(),
            PCWSTR::null(),
            SW_SHOWNORMAL,
        );
        
        // ShellExecuteW returns a value > 32 on success
        result.0 as usize > 32
    }
}
