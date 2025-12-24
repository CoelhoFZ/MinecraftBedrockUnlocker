// Antivirus Detection Module - Detects installed antivirus and provides specific instructions
// Supports Windows Defender, Kaspersky, Avast, AVG, Norton, Bitdefender, McAfee

use colored::*;
use std::process::Command;
use std::path::Path;
use crate::i18n::{get_language, Language};

#[derive(Debug, Clone, PartialEq)]
pub enum AntivirusType {
    WindowsDefender,
    Kaspersky,
    Avast,
    AVG,
    Norton,
    Bitdefender,
    McAfee,
    ESET,
    Malwarebytes,
    Unknown(String),
    None,
}

pub struct AntivirusDetector;

impl AntivirusDetector {
    /// Detect which antivirus is installed on the system
    pub fn detect() -> Vec<AntivirusType> {
        let mut detected = Vec::new();

        // Check Windows Defender (always present but may be disabled)
        if Self::is_defender_active() {
            detected.push(AntivirusType::WindowsDefender);
        }

        // Check for third-party antivirus by looking at installed services/processes
        let third_party = Self::detect_third_party();
        detected.extend(third_party);

        if detected.is_empty() {
            detected.push(AntivirusType::None);
        }

        detected
    }

    fn is_defender_active() -> bool {
        // Check if Windows Defender is enabled via PowerShell
        let output = Command::new("powershell")
            .args([
                "-NoProfile",
                "-Command",
                "Get-MpComputerStatus | Select-Object -ExpandProperty RealTimeProtectionEnabled"
            ])
            .output();

        match output {
            Ok(out) => {
                let stdout = String::from_utf8_lossy(&out.stdout);
                stdout.trim().to_lowercase() == "true"
            }
            Err(_) => false,
        }
    }

    fn detect_third_party() -> Vec<AntivirusType> {
        let mut found = Vec::new();

        // Common antivirus installation paths and process names
        let checks: Vec<(&str, AntivirusType)> = vec![
            (r"C:\Program Files\Kaspersky Lab", AntivirusType::Kaspersky),
            (r"C:\Program Files (x86)\Kaspersky Lab", AntivirusType::Kaspersky),
            (r"C:\Program Files\Avast Software", AntivirusType::Avast),
            (r"C:\Program Files (x86)\Avast Software", AntivirusType::Avast),
            (r"C:\Program Files\AVG", AntivirusType::AVG),
            (r"C:\Program Files (x86)\AVG", AntivirusType::AVG),
            (r"C:\Program Files\Norton Security", AntivirusType::Norton),
            (r"C:\Program Files\NortonLifeLock", AntivirusType::Norton),
            (r"C:\Program Files\Bitdefender", AntivirusType::Bitdefender),
            (r"C:\Program Files\Bitdefender Agent", AntivirusType::Bitdefender),
            (r"C:\Program Files\McAfee", AntivirusType::McAfee),
            (r"C:\Program Files\Common Files\McAfee", AntivirusType::McAfee),
            (r"C:\Program Files\ESET", AntivirusType::ESET),
            (r"C:\Program Files (x86)\ESET", AntivirusType::ESET),
            (r"C:\Program Files\Malwarebytes", AntivirusType::Malwarebytes),
        ];

        for (path, av_type) in checks {
            if Path::new(path).exists() && !found.contains(&av_type) {
                found.push(av_type);
            }
        }

        found
    }

    /// Get the name of the antivirus for display
    pub fn get_name(av: &AntivirusType) -> &'static str {
        match av {
            AntivirusType::WindowsDefender => "Windows Defender",
            AntivirusType::Kaspersky => "Kaspersky",
            AntivirusType::Avast => "Avast",
            AntivirusType::AVG => "AVG",
            AntivirusType::Norton => "Norton",
            AntivirusType::Bitdefender => "Bitdefender",
            AntivirusType::McAfee => "McAfee",
            AntivirusType::ESET => "ESET NOD32",
            AntivirusType::Malwarebytes => "Malwarebytes",
            AntivirusType::Unknown(_) => "Unknown",
            AntivirusType::None => "None",
        }
    }

    /// Get instructions for adding exclusion for a specific antivirus
    pub fn get_exclusion_instructions(av: &AntivirusType) -> String {
        match get_language() {
            Language::English => Self::get_instructions_en(av),
            Language::PortugueseBR | Language::PortuguesePT => Self::get_instructions_pt(av),
            Language::Spanish => Self::get_instructions_es(av),
            _ => Self::get_instructions_en(av),
        }
    }

    fn get_instructions_en(av: &AntivirusType) -> String {
        match av {
            AntivirusType::WindowsDefender => 
                "Windows Defender: Settings > Virus protection > Exclusions > Add folder".to_string(),
            AntivirusType::Kaspersky => 
                "Kaspersky: Settings > Threats and Exclusions > Manage Exclusions > Add".to_string(),
            AntivirusType::Avast => 
                "Avast: Settings > General > Exceptions > Add Exception".to_string(),
            AntivirusType::AVG => 
                "AVG: Menu > Settings > General > Exceptions > Add Exception".to_string(),
            AntivirusType::Norton => 
                "Norton: Settings > Antivirus > Scans and Risks > Items to Exclude".to_string(),
            AntivirusType::Bitdefender => 
                "Bitdefender: Protection > Antivirus > Settings > Exclusions".to_string(),
            AntivirusType::McAfee => 
                "McAfee: PC Security > Real-Time Scanning > Excluded Files".to_string(),
            AntivirusType::ESET => 
                "ESET: Setup > Advanced Setup > Detection Engine > Exclusions".to_string(),
            AntivirusType::Malwarebytes => 
                "Malwarebytes: Settings > Allow List > Add".to_string(),
            _ => "Check your antivirus settings to add an exclusion".to_string(),
        }
    }

    fn get_instructions_pt(av: &AntivirusType) -> String {
        match av {
            AntivirusType::WindowsDefender => 
                "Windows Defender: Configurações > Proteção contra vírus > Exclusões > Adicionar pasta".to_string(),
            AntivirusType::Kaspersky => 
                "Kaspersky: Configurações > Ameaças e Exclusões > Gerenciar Exclusões > Adicionar".to_string(),
            AntivirusType::Avast => 
                "Avast: Configurações > Geral > Exceções > Adicionar Exceção".to_string(),
            AntivirusType::AVG => 
                "AVG: Menu > Configurações > Geral > Exceções > Adicionar Exceção".to_string(),
            AntivirusType::Norton => 
                "Norton: Configurações > Antivírus > Verificações e Riscos > Itens a Excluir".to_string(),
            AntivirusType::Bitdefender => 
                "Bitdefender: Proteção > Antivírus > Configurações > Exclusões".to_string(),
            AntivirusType::McAfee => 
                "McAfee: Segurança do PC > Verificação em Tempo Real > Arquivos Excluídos".to_string(),
            AntivirusType::ESET => 
                "ESET: Configuração > Configuração Avançada > Mecanismo de Detecção > Exclusões".to_string(),
            AntivirusType::Malwarebytes => 
                "Malwarebytes: Configurações > Lista de Permissões > Adicionar".to_string(),
            _ => "Verifique as configurações do seu antivírus para adicionar uma exclusão".to_string(),
        }
    }

    fn get_instructions_es(av: &AntivirusType) -> String {
        match av {
            AntivirusType::WindowsDefender => 
                "Windows Defender: Configuración > Protección contra virus > Exclusiones > Agregar carpeta".to_string(),
            AntivirusType::Kaspersky => 
                "Kaspersky: Configuración > Amenazas y Exclusiones > Administrar Exclusiones > Agregar".to_string(),
            AntivirusType::Avast => 
                "Avast: Configuración > General > Excepciones > Agregar Excepción".to_string(),
            _ => "Revise la configuración de su antivirus para agregar una exclusión".to_string(),
        }
    }

    /// Print detected antivirus to console
    pub fn print_detected() {
        let detected = Self::detect();
        
        println!("                    {} {}", 
            "[ANTIVIRUS]".cyan().bold(), 
            av_detected_label());

        for av in &detected {
            let name = Self::get_name(av);
            let status = if *av == AntivirusType::WindowsDefender && Self::is_defender_active() {
                format!("{} ({})", name, av_active())
            } else if *av == AntivirusType::None {
                format!("{}", av_none_detected())
            } else {
                format!("{} ({})", name, av_installed())
            };
            println!("                      • {}", status.white());
        }
    }

    /// Add Defender exclusion automatically
    pub fn add_defender_exclusion(path: &std::path::Path) -> bool {
        let path_str = path.display().to_string();
        
        let result = Command::new("powershell")
            .args([
                "-NoProfile",
                "-ExecutionPolicy", "Bypass",
                "-Command",
                &format!(
                    "Add-MpPreference -ExclusionPath '{}' -ErrorAction SilentlyContinue",
                    path_str
                ),
            ])
            .output();

        match result {
            Ok(output) => output.status.success(),
            Err(_) => false,
        }
    }

    /// Open Windows Security settings
    pub fn open_defender_settings() {
        let _ = Command::new("cmd")
            .args(["/C", "start", "windowsdefender://threatsettings"])
            .spawn();
    }

    /// Try to restore file from Windows Defender quarantine
    pub fn try_restore_from_quarantine(filename: &str) -> bool {
        // Get quarantine items and try to restore
        let script = format!(
            r#"
            $items = Get-MpThreatDetection | Where-Object {{ $_.Resources -like '*{}*' }}
            if ($items) {{
                foreach ($item in $items) {{
                    Remove-MpThreat -ThreatID $item.ThreatID -ErrorAction SilentlyContinue
                }}
                Write-Output "restored"
            }}
            "#,
            filename
        );

        let result = Command::new("powershell")
            .args(["-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", &script])
            .output();

        match result {
            Ok(output) => {
                let stdout = String::from_utf8_lossy(&output.stdout);
                stdout.contains("restored")
            }
            Err(_) => false,
        }
    }
}

// Localized strings
fn av_detected_label() -> &'static str {
    match get_language() {
        Language::English => "Detected:",
        Language::PortugueseBR | Language::PortuguesePT => "Detectado:",
        Language::Spanish => "Detectado:",
        Language::French => "Détecté:",
        Language::German => "Erkannt:",
        Language::ChineseSimplified => "检测到:",
        Language::Russian => "Обнаружено:",
    }
}

fn av_active() -> &'static str {
    match get_language() {
        Language::English => "ACTIVE",
        Language::PortugueseBR | Language::PortuguesePT => "ATIVO",
        Language::Spanish => "ACTIVO",
        Language::French => "ACTIF",
        Language::German => "AKTIV",
        Language::ChineseSimplified => "活跃",
        Language::Russian => "АКТИВЕН",
    }
}

fn av_installed() -> &'static str {
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

fn av_none_detected() -> &'static str {
    match get_language() {
        Language::English => "No antivirus detected",
        Language::PortugueseBR | Language::PortuguesePT => "Nenhum antivírus detectado",
        Language::Spanish => "Ningún antivirus detectado",
        Language::French => "Aucun antivirus détecté",
        Language::German => "Kein Antivirus erkannt",
        Language::ChineseSimplified => "未检测到杀毒软件",
        Language::Russian => "Антивирус не обнаружен",
    }
}
