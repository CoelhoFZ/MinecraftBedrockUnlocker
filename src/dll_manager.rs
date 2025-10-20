use anyhow::{Context, Result};
use colored::*;
use sha2::{Sha256, Digest};
use std::fs;
use std::path::{Path, PathBuf};
use std::io::{self, Write};
use crate::i18n::Translations;

const TARGET_DLL: &str = "Windows.ApplicationModel.Store.dll";
const ORIGINAL_DLL: &[u8] = include_bytes!("../../dlls/Original/Windows.ApplicationModel.Store.dll");
const MODIFIED_DLL: &[u8] = include_bytes!("../../dlls/Modificado/Windows.ApplicationModel.Store.dll");

pub struct DllManager {
    system32_path: PathBuf,
    target_dll_path: PathBuf,
}

impl DllManager {
    pub fn new() -> Result<Self> {
        let system32_path = get_system32_path()?;
        let target_dll_path = system32_path.join(TARGET_DLL);

        Ok(Self {
            system32_path,
            target_dll_path,
        })
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

        // Check DLL
        println!("                    {}          {}", Translations::dll_path(), self.target_dll_path.display());

        if !self.target_dll_path.exists() {
            println!("                    {}           File not found", Translations::dll_state().yellow());
        } else {
            let current_hash = calculate_file_hash(&self.target_dll_path)?;
            let original_hash = calculate_hash(ORIGINAL_DLL);
            let modified_hash = calculate_hash(MODIFIED_DLL);

            print!("             {}           ", Translations::dll_state());
            if current_hash == original_hash {
                println!("{}", Translations::dll_original_locked().yellow());
            } else if current_hash == modified_hash {
                println!("{}", Translations::dll_modified_unlocked().green());
            } else {
                println!("{}", Translations::dll_unknown().magenta());
            }

            println!("                    Hash SHA256:             {}", current_hash);
        }

        println!();
        println!("                    ════════════════════════════════════════════════════");

        Ok(())
    }

    pub fn install_modified(&self) -> Result<()> {
        println!("                    {} {}", Translations::info().cyan(), Translations::installing_modified());

        // Try direct copy
        match self.try_copy_dll(MODIFIED_DLL) {
            Ok(_) => {
                println!("                    {} {}", Translations::ok().green().bold(), Translations::modified_installed());
                println!("                    {} {}", Translations::info().cyan(), Translations::can_start_minecraft());
                return Ok(());
            }
            Err(_) => {
                println!("                    {}", "[AVISO] Processos estão usando a DLL...".yellow());
            }
        }

        // Listar processos usando a DLL
        let processes = crate::process_utils::get_processes_using_file(&self.target_dll_path)?;
        
        if !processes.is_empty() {
            println!();
            println!("                    Processos que precisam ser encerrados:");
            for (i, (pid, name)) in processes.iter().enumerate() {
                if i >= 10 {
                    println!("                      • ... e mais {} processo(s)", processes.len() - 10);
                    break;
                }
                println!("                      • PID {} - {}", pid, name);
            }
            println!();

            print!("             Deseja encerrar esses processos? (S/N): ");
            io::stdout().flush()?;
            
            let mut response = String::new();
            io::stdin().read_line(&mut response)?;
            let response = response.trim().to_uppercase();

            if response != "S" && response != "SIM" && response != "Y" && response != "YES" {
                println!("                    {}", "[AVISO] Operação cancelada pelo usuário.".yellow());
                return Ok(());
            }

            println!("                    {}", "[INFO] Encerrando processos...".cyan());
            crate::process_utils::close_processes(&processes)?;
            
            // Aguardar mais tempo para os processos liberarem o arquivo
            println!("                    {}", "[INFO] Aguardando liberação do arquivo...".cyan());
            std::thread::sleep(std::time::Duration::from_millis(2000));

            // Tentar novamente
            if self.try_copy_dll(MODIFIED_DLL).is_ok() {
                println!("                    {}", "[OK] DLL Modificada instalada com sucesso! ✓".green().bold());
                return Ok(());
            }
        }

        // Tentar com privilégios elevados
        println!("                    {}", "[AVISO] Tentando com ajuste de permissões...".yellow());
        
        // Aguardar mais um pouco antes de forçar
        std::thread::sleep(std::time::Duration::from_millis(1000));
        
        // Tentar múltiplas vezes com retry
        for attempt in 1..=5 {
            match self.force_copy_dll(MODIFIED_DLL) {
                Ok(_) => {
                    println!("{}", "[OK] DLL Modificada instalada com sucesso!".green());
                    return Ok(());
                }
                Err(e) => {
                    if attempt < 5 {
                        println!("{}", format!("[AVISO] Tentativa {} falhou, tentando novamente...", attempt).yellow());
                        std::thread::sleep(std::time::Duration::from_millis(1000));
                    } else {
                        return Err(e).context("Falha ao forçar cópia da DLL após 5 tentativas");
                    }
                }
            }
        }
        
        Ok(())
    }

    pub fn restore_original(&self) -> Result<()> {
        println!("{}", "[INFO] Restaurando DLL Original...".cyan());

        // Tentar cópia direta
        match self.try_copy_dll(ORIGINAL_DLL) {
            Ok(_) => {
                println!("{}", "[OK] DLL Original restaurada com sucesso!".green());
                return Ok(());
            }
            Err(_) => {
                println!("{}", "[AVISO] Processos estão usando a DLL.".yellow());
            }
        }

        // Listar processos
        let processes = crate::process_utils::get_processes_using_file(&self.target_dll_path)?;
        
        if !processes.is_empty() {
            println!();
            println!("Processos usando a DLL:");
            for (i, (pid, name)) in processes.iter().enumerate() {
                if i >= 10 {
                    println!("  • ... e mais {} processo(s)", processes.len() - 10);
                    break;
                }
                println!("  • PID {} - {}", pid, name);
            }
            println!();

            print!("Deseja encerrar esses processos? (S/N): ");
            io::stdout().flush()?;
            
            let mut response = String::new();
            io::stdin().read_line(&mut response)?;
            let response = response.trim().to_uppercase();

            if response != "S" && response != "SIM" && response != "Y" && response != "YES" {
                println!("{}", "[AVISO] Operação cancelada pelo usuário.".yellow());
                return Ok(());
            }

            crate::process_utils::close_processes(&processes)?;
            
            // Aguardar liberação do arquivo
            println!("{}", "[INFO] Aguardando liberação do arquivo...".cyan());
            std::thread::sleep(std::time::Duration::from_millis(2000));

            if self.try_copy_dll(ORIGINAL_DLL).is_ok() {
                println!("{}", "[OK] DLL Original restaurada com sucesso!".green());
                return Ok(());
            }
        }

        // Forçar com permissões e retry
        println!("{}", "[AVISO] Tentando com ajuste de permissões...".yellow());
        std::thread::sleep(std::time::Duration::from_millis(1000));
        
        for attempt in 1..=5 {
            match self.force_copy_dll(ORIGINAL_DLL) {
                Ok(_) => {
                    println!("{}", "[OK] DLL Original restaurada com sucesso!".green());
                    return Ok(());
                }
                Err(e) => {
                    if attempt < 5 {
                        println!("{}", format!("[AVISO] Tentativa {} falhou, tentando novamente...", attempt).yellow());
                        std::thread::sleep(std::time::Duration::from_millis(1000));
                    } else {
                        return Err(e).context("Falha ao restaurar DLL após 5 tentativas");
                    }
                }
            }
        }
        
        Ok(())
    }

    fn try_copy_dll(&self, data: &[u8]) -> Result<()> {
        fs::write(&self.target_dll_path, data)
            .context("Falha ao copiar DLL")
    }

    fn force_copy_dll(&self, data: &[u8]) -> Result<()> {
        use crate::process_utils::take_ownership;
        
        // Tomar posse do arquivo
        take_ownership(&self.target_dll_path)?;
        
        // Remover atributos de readonly e system
        if self.target_dll_path.exists() {
            // Remover atributos especiais do Windows
            let _ = std::process::Command::new("attrib")
                .args(&["-R", "-S", "-H", self.target_dll_path.to_str().unwrap()])
                .output();
            
            let metadata = fs::metadata(&self.target_dll_path)?;
            let mut permissions = metadata.permissions();
            permissions.set_readonly(false);
            let _ = fs::set_permissions(&self.target_dll_path, permissions);
            
            // Tentar deletar o arquivo antigo
            let _ = fs::remove_file(&self.target_dll_path);
            
            // Aguardar um pouco
            std::thread::sleep(std::time::Duration::from_millis(200));
        }

        // Tentar copiar
        match fs::write(&self.target_dll_path, data) {
            Ok(_) => Ok(()),
            Err(e) => {
                // Se falhar, tentar renomear o antigo e copiar
                if self.target_dll_path.exists() {
                    let backup_path = self.target_dll_path.with_extension("dll.old");
                    let _ = fs::rename(&self.target_dll_path, &backup_path);
                    std::thread::sleep(std::time::Duration::from_millis(200));
                }
                
                fs::write(&self.target_dll_path, data)
                    .context(format!("Falha ao forçar cópia da DLL: {}", e))
            }
        }
    }
}

fn get_system32_path() -> Result<PathBuf> {
    let windows_dir = std::env::var("WINDIR")
        .or_else(|_| std::env::var("SystemRoot"))
        .unwrap_or_else(|_| "C:\\Windows".to_string());
    
    Ok(PathBuf::from(windows_dir).join("System32"))
}

fn calculate_file_hash(path: &Path) -> Result<String> {
    let data = fs::read(path)
        .context("Falha ao ler arquivo para hash")?;
    Ok(calculate_hash(&data))
}

fn calculate_hash(data: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(data);
    let result = hasher.finalize();
    hex::encode(result).to_uppercase()
}
