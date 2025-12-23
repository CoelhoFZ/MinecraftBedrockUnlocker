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
mod process_utils;
mod minecraft;
mod i18n;

use dll_manager::DllManager;
use i18n::Translations;

/// MINECRAFT UNLOCKER CLI - byCoelhoFZ
/// Minecraft DLL Manager (Console Mode)
#[derive(Parser)]
#[command(name = "MinecraftUnlocker")]
#[command(version = "1.0.0")]
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

    // Check if running as administrator
    if !is_elevated() {
        eprintln!("{}", Translations::admin_required().red().bold());
        eprintln!("{}", Translations::admin_how_to().yellow());
        std::process::exit(1);
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

fn print_menu(show_youtube_option: bool) {
    println!("                        {}                  ", Translations::available_options().green().bold());
    println!();
    println!("                {} {}        ", "[1]".green().bold(), Translations::menu_option_1().white());
    println!("                {} {}        ", "[2]".green().bold(), Translations::menu_option_2().white());
    println!("                {} {}          ", "[3]".green().bold(), Translations::menu_option_3().white());
    println!("                {} {}", "[4]".green().bold(), Translations::menu_option_4().white());
    println!("                {} {}       ", "[5]".green().bold(), Translations::menu_option_5().white());
    println!("                {} {}               ", "[0]".red().bold(), Translations::menu_option_0().white());
    if show_youtube_option {
        println!("                {} {}", "[6]".yellow().bold(), Translations::menu_option_6().white());
    }
    println!();
    println!("             ════════════════════════════════════════════════");
    println!();
    // Display version at bottom
    println!("                              {} {}", "v".dimmed(), env!("CARGO_PKG_VERSION").dimmed());
    println!();
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
                has_used_option = true;
                wait_and_return_to_menu(has_used_option);
            }
            "6" => {
                if has_used_option {
                    open_youtube_channel()?;
                    wait_and_return_to_menu(has_used_option);
                } else {
                    println!("      {}", Translations::invalid_option("5").yellow().bold());
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
                let max_option = if has_used_option { "6" } else { "5" };
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
