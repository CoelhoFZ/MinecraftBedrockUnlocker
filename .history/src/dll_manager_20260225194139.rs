use anyhow::{Context, Result, anyhow};
use colored::*;
use sha2::{Sha256, Digest};
use std::fs;
use std::path::PathBuf;
use crate::i18n::Translations;

// OnlineFix files embedded in binary
const WINMM_DLL: &[u8] = include_bytes!("../dlls/OnlineFix/winmm.dll");
const ONLINEFIX64_DLL: &[u8] = include_bytes!("../dlls/OnlineFix/OnlineFix64.dll");
const DLLLIST_TXT: &[u8] = include_bytes!("../dlls/OnlineFix/dlllist.txt");
const ONLINEFIX_INI: &[u8] = include_bytes!("../dlls/OnlineFix/OnlineFix.ini");

pub struct DllManager {
    minecraft_content_path: PathBuf,
}

impl DllManager {
    pub fn new() -> Result<Self> {
        let minecraft_content_path = find_minecraft_content_path()?;
        
        Ok(Self {
            minecraft_content_path,
        })
    }

    /// Get the Minecraft content path
    pub fn get_minecraft_path(&self) -> &std::path::Path {
        &self.minecraft_content_path
    }

    pub fn show_status(&self) -> Result<()> {
        println!("                    ════════════════════════════════════════════════════");
        println!("                                     {}                    ", Translations::system_status().cyan().bold());
        println!("                    ════════════════════════════════════════════════════");
        println!();

        // Check if Minecraft is installed
        print!("             {}     ", Translations::minecraft_installed());
        if crate::minecraft::is_minecraft_installed() {
            println!("{}", Translations::yes().green());
        } else {
            println!("{}", Translations::no().red());
        }

        // Check content path
        println!("                    {}:", Translations::minecraft_path().white());
        println!("                      {}", self.minecraft_content_path.display().to_string().cyan());
        println!();

        // Check OnlineFix status
        let winmm_path = self.minecraft_content_path.join("winmm.dll");
        let onlinefix_path = self.minecraft_content_path.join("OnlineFix64.dll");

        print!("             {}       ", Translations::bypass_status());
        if winmm_path.exists() && onlinefix_path.exists() {
            println!("{}", Translations::installed().green().bold());
            
            // Show file hashes
            if let Ok(hash) = calculate_file_hash(&winmm_path) {
                println!("                    winmm.dll Hash:");
                let indent = "                         ";
                for chunk in hash.as_bytes().chunks(32) {
                    if let Ok(part) = std::str::from_utf8(chunk) {
                        println!("{}{}", indent, part);
                    }
                }
            }
        } else {
            println!("{}", Translations::not_installed().red().bold());
        }

        println!();
        println!("                    ════════════════════════════════════════════════════");

        Ok(())
    }

    pub fn install_modified(&self) -> Result<()> {
        println!("                    {} {}", Translations::info().cyan(), Translations::installing_bypass());
        println!();

        // Check if Minecraft is running FIRST
        if crate::process_utils::is_minecraft_running() {
            println!("                    {} {}", Translations::warning().yellow(), Translations::minecraft_running());
            println!("                    {} {}", Translations::info().cyan(), Translations::closing_minecraft());
            crate::process_utils::close_minecraft()?;
            // Increased wait time for slower systems
            std::thread::sleep(std::time::Duration::from_secs(3));
        }

        // CRITICAL: Add ALL antivirus exclusions BEFORE copying files
        self.add_all_antivirus_exclusions();

        // Small delay to ensure exclusions are applied
        std::thread::sleep(std::time::Duration::from_millis(500));

        // Install all OnlineFix files
        let files = [
            ("winmm.dll", WINMM_DLL),
            ("OnlineFix64.dll", ONLINEFIX64_DLL),
            ("dlllist.txt", DLLLIST_TXT),
            ("OnlineFix.ini", ONLINEFIX_INI),
        ];

        for (filename, data) in files.iter() {
            let target_path = self.minecraft_content_path.join(filename);
            
            match fs::write(&target_path, data) {
                Ok(_) => {
                    println!("                    {} {} {}", Translations::ok().green(), filename, Translations::file_installed());
                }
                Err(e) => {
                    println!("                    {} {} {}: {}", Translations::error().red(), Translations::failed_to_install(), filename, e);
                    return Err(anyhow!("{} {}: {}", Translations::failed_to_install(), filename, e));
                }
            }
        }

        // CRITICAL: Verify files after installation (antivirus may delete them immediately)
        println!();
        println!("                    {} {}", Translations::info().cyan(), verifying_installation_msg());
        std::thread::sleep(std::time::Duration::from_secs(2)); // Wait for antivirus to potentially delete

        let verification_result = self.verify_installation();
        
        match verification_result {
            InstallVerification::Success => {
                println!();
                println!("                    {} {}", Translations::ok().green().bold(), Translations::bypass_installed());
                println!("                    {} {}", Translations::info().cyan(), Translations::open_minecraft_now());
            }
            InstallVerification::FilesMissing(missing) => {
                println!();
                println!("                    {} {}", Translations::warning().red().bold(), files_deleted_by_av_msg());
                for file in &missing {
                    println!("                      - {}", file.yellow());
                }
                println!();
                println!("                    {} {}", Translations::info().cyan(), av_exclusion_needed_msg());
                
                // Try to reinstall the missing files one more time
                println!("                    {} {}", Translations::info().cyan(), retrying_installation_msg());
                std::thread::sleep(std::time::Duration::from_secs(1));
                
                for filename in &missing {
                    let data = match filename.as_str() {
                        "winmm.dll" => WINMM_DLL,
                        "OnlineFix64.dll" => ONLINEFIX64_DLL,
                        "dlllist.txt" => DLLLIST_TXT,
                        "OnlineFix.ini" => ONLINEFIX_INI,
                        _ => continue,
                    };
                    let target_path = self.minecraft_content_path.join(filename);
                    let _ = fs::write(&target_path, data);
                }
                
                // Final check
                std::thread::sleep(std::time::Duration::from_secs(2));
                if self.verify_installation() == InstallVerification::Success {
                    println!("                    {} {}", Translations::ok().green().bold(), retry_success_msg());
                } else {
                    println!();
                    println!("                    {} {}", "[!]".red().bold(), manual_av_disable_msg());
                    self.print_antivirus_instructions();
                }
            }
        }

        Ok(())
    }

    /// Verify that all files are still present after installation
    fn verify_installation(&self) -> InstallVerification {
        let files = ["winmm.dll", "OnlineFix64.dll", "dlllist.txt", "OnlineFix.ini"];
        let mut missing = Vec::new();

        for file in files {
            let path = self.minecraft_content_path.join(file);
            if !path.exists() {
                missing.push(file.to_string());
            }
        }

        if missing.is_empty() {
            InstallVerification::Success
        } else {
            InstallVerification::FilesMissing(missing)
        }
    }

    /// Add exclusions for ALL detected antivirus programs
    fn add_all_antivirus_exclusions(&self) {
        use crate::antivirus::{AntivirusDetector, AntivirusType};
        
        let path = &self.minecraft_content_path;
        let detected = AntivirusDetector::detect();

        println!("                    {} {}", Translations::info().cyan(), adding_av_exclusions_msg());

        for av in &detected {
            match av {
                AntivirusType::WindowsDefender => {
                    // Add folder exclusion
                    if AntivirusDetector::add_defender_exclusion(path) {
                        println!("                    {} Windows Defender: {}", Translations::ok().green(), exclusion_added_msg());
                    }
                    // Also add exclusions for individual DLL files
                    let dll_path = path.join("OnlineFix64.dll");
                    let _ = AntivirusDetector::add_defender_exclusion(&dll_path);
                    let winmm_path = path.join("winmm.dll");
                    let _ = AntivirusDetector::add_defender_exclusion(&winmm_path);
                }
                AntivirusType::None => {}
                _ => {
                    // For third-party antivirus, we can only warn the user
                    let name = AntivirusDetector::get_name(av);
                    println!("                    {} {}: {}", Translations::warning().yellow(), name, manual_exclusion_needed_msg());
                }
            }
        }
        println!();
    }

    /// Print detailed antivirus instructions
    fn print_antivirus_instructions(&self) {
        use crate::antivirus::{AntivirusDetector, AntivirusType};
        
        let detected = AntivirusDetector::detect();
        
        println!();
        println!("                    {}", av_instructions_header_msg().cyan().bold());
        println!();
        
        for av in &detected {
            if *av != AntivirusType::None {
                let instructions = AntivirusDetector::get_exclusion_instructions(av);
                println!("                    • {}", instructions.white());
            }
        }
        
        println!();
        println!("                    {} {}", Translations::info().cyan(), folder_to_exclude_msg());
        println!("                      {}", self.minecraft_content_path.display().to_string().yellow());
    }

    /// Add the Minecraft Content folder to Windows Defender exclusion list
    /// This prevents the antivirus from deleting OnlineFix64.dll
    fn add_defender_exclusion(&self) {
        use std::process::Command;
        
        let path = self.minecraft_content_path.display().to_string();
        
        println!("                    {} {}", Translations::info().cyan(), Translations::adding_defender_exclusion());
        
        // Use PowerShell to add exclusion
        let result = Command::new("powershell")
            .args([
                "-NoProfile",
                "-ExecutionPolicy", "Bypass",
                "-Command",
                &format!(
                    "Add-MpPreference -ExclusionPath '{}' -ErrorAction SilentlyContinue",
                    path
                ),
            ])
            .output();

        match result {
            Ok(output) => {
                if output.status.success() {
                    println!("                    {} {}", Translations::ok().green(), Translations::defender_exclusion_added());
                } else {
                    // Silently continue - the user might not have Windows Defender
                    // or might be running a third-party antivirus
                    println!("                    {} {}", Translations::warning().yellow(), Translations::defender_exclusion_failed());
                }
            }
            Err(_) => {
                // PowerShell not available or other error - continue anyway
                println!("                    {} {}", Translations::warning().yellow(), Translations::defender_exclusion_failed());
            }
        }
        
        println!();
    }

    pub fn restore_original(&self) -> Result<()> {
        println!("                    {} {}", Translations::info().cyan(), Translations::removing_bypass());
        println!();

        // Check if Minecraft is running
        if crate::process_utils::is_minecraft_running() {
            println!("                    {} {}", Translations::warning().yellow(), Translations::minecraft_running());
            println!("                    {} {}", Translations::info().cyan(), Translations::closing_minecraft());
            crate::process_utils::close_minecraft()?;
            std::thread::sleep(std::time::Duration::from_secs(2));
        }

        // Remove OnlineFix files
        let files_to_remove = ["winmm.dll", "OnlineFix64.dll", "dlllist.txt", "OnlineFix.ini"];

        for filename in files_to_remove.iter() {
            let target_path = self.minecraft_content_path.join(filename);
            
            if target_path.exists() {
                match fs::remove_file(&target_path) {
                    Ok(_) => {
                        println!("                    {} {} {}", Translations::ok().green(), filename, Translations::file_removed());
                    }
                    Err(e) => {
                        println!("                    {} {} {}: {}", Translations::warning().yellow(), Translations::failed_to_remove(), filename, e);
                    }
                }
            }
        }

        println!();
        println!("                    {} {}", Translations::ok().green().bold(), Translations::bypass_removed());

        Ok(())
    }
}

fn find_minecraft_content_path() -> Result<PathBuf> {
    // Priority 1: XboxGames installation (most common for GDK)
    let xbox_path = PathBuf::from(r"C:\XboxGames\Minecraft for Windows\Content");
    if xbox_path.exists() {
        return Ok(xbox_path);
    }

    // Priority 2: Check all available drives for XboxGames
    // Use Windows API to get logical drives dynamically
    let drives = get_available_drives();
    for drive in drives {
        let path = PathBuf::from(format!(r"{}:\XboxGames\Minecraft for Windows\Content", drive));
        if path.exists() {
            return Ok(path);
        }
    }

    // Priority 3: WindowsApps (requires special permissions)
    let program_files = std::env::var("ProgramFiles").unwrap_or_else(|_| r"C:\Program Files".to_string());
    let windows_apps = PathBuf::from(program_files).join("WindowsApps");
    
    if windows_apps.exists() {
        // Try to find Minecraft folder
        if let Ok(entries) = fs::read_dir(&windows_apps) {
            for entry in entries.flatten() {
                let name = entry.file_name().to_string_lossy().to_string();
                if name.starts_with("Microsoft.Minecraft") && name.contains("8wekyb3d8bbwe") {
                    let content_path = entry.path().join("Content");
                    if content_path.exists() {
                        return Ok(content_path);
                    }
                }
            }
        }
    }

    Err(anyhow!(
        "Minecraft not found!\n\
        Please install Minecraft Trial from Microsoft Store or Xbox App.\n\
        Make sure to install to C:\\XboxGames via Xbox App."
    ))
}

fn calculate_file_hash(path: &std::path::Path) -> Result<String> {
    let data = fs::read(path).context("Failed to read file for hash")?;
    let mut hasher = Sha256::new();
    hasher.update(&data);
    let result = hasher.finalize();
    Ok(hex::encode(result).to_uppercase())
}

/// Get all available drive letters on the system using Windows API
fn get_available_drives() -> Vec<char> {
    crate::utils::get_available_drives()
}
