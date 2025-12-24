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

        // Add Windows Defender exclusion BEFORE copying files
        self.add_defender_exclusion();

        // Check if Minecraft is running
        if crate::process_utils::is_minecraft_running() {
            println!("                    {} {}", Translations::warning().yellow(), Translations::minecraft_running());
            println!("                    {} {}", Translations::info().cyan(), Translations::closing_minecraft());
            crate::process_utils::close_minecraft()?;
            std::thread::sleep(std::time::Duration::from_secs(2));
        }

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

        println!();
        println!("                    {} {}", Translations::ok().green().bold(), Translations::bypass_installed());
        println!("                    {} {}", Translations::info().cyan(), Translations::open_minecraft_now());

        Ok(())
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
    let mut drives = Vec::new();
    
    #[cfg(target_os = "windows")]
    {
        extern "system" {
            fn GetLogicalDrives() -> u32;
        }
        
        let bitmask = unsafe { GetLogicalDrives() };
        
        // Check each bit (A=0, B=1, C=2, etc.)
        for i in 0..26u32 {
            if (bitmask & (1 << i)) != 0 {
                let drive_letter = (b'A' + i as u8) as char;
                // Skip A: and B: (floppy drives)
                if drive_letter != 'A' && drive_letter != 'B' {
                    drives.push(drive_letter);
                }
            }
        }
    }
    
    // Fallback for non-Windows (shouldn't happen but just in case)
    #[cfg(not(target_os = "windows"))]
    {
        drives = vec!['C', 'D', 'E', 'F', 'G'];
    }
    
    drives
}
