use anyhow::{Context, Result};
use std::path::Path;
use windows::Win32::Foundation::*;
use windows::Win32::System::Diagnostics::ToolHelp::*;
use windows::Win32::System::Threading::*;
use windows::Win32::System::ProcessStatus::*;
use windows::Win32::Security::*;
use windows::core::PCWSTR;

pub fn get_processes_using_file(file_path: &Path) -> Result<Vec<(u32, String)>> {
    let mut processes = Vec::new();
    let file_name = file_path.file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("")
        .to_lowercase();

    unsafe {
        let snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
            .context("Failed to create process snapshot")?;

        let mut entry = PROCESSENTRY32W {
            dwSize: std::mem::size_of::<PROCESSENTRY32W>() as u32,
            ..Default::default()
        };

        if Process32FirstW(snapshot, &mut entry).is_ok() {
            loop {
                let process_id = entry.th32ProcessID;
                
                // Skip system processes
                if process_id == 0 || process_id == 4 {
                    if Process32NextW(snapshot, &mut entry).is_err() {
                        break;
                    }
                    continue;
                }

                // Open process
                if let Ok(handle) = OpenProcess(
                    PROCESS_QUERY_INFORMATION | PROCESS_VM_READ,
                    false,
                    process_id,
                ) {
                    // Check if process loaded the DLL
                    let mut modules = [HMODULE::default(); 1024];
                    let mut needed = 0u32;

                    if EnumProcessModules(
                        handle,
                        modules.as_mut_ptr(),
                        std::mem::size_of_val(&modules) as u32,
                        &mut needed,
                    ).is_ok() {
                        let count = (needed as usize / std::mem::size_of::<HMODULE>()).min(1024);
                        
                        for &module in &modules[..count] {
                            let mut module_name = [0u16; 260];
                            if GetModuleBaseNameW(handle, module, &mut module_name) > 0 {
                                let name = String::from_utf16_lossy(&module_name)
                                    .trim_end_matches('\0')
                                    .to_lowercase();
                                
                                if name == file_name {
                                    let process_name = String::from_utf16_lossy(&entry.szExeFile)
                                        .trim_end_matches('\0')
                                        .to_string();
                                    processes.push((process_id, process_name));
                                    break;
                                }
                            }
                        }
                    }

                    let _ = CloseHandle(handle);
                }

                if Process32NextW(snapshot, &mut entry).is_err() {
                    break;
                }
            }
        }

        let _ = CloseHandle(snapshot);
    }

    Ok(processes)
}

pub fn close_processes(processes: &[(u32, String)]) -> Result<()> {
    for (pid, name) in processes {
        // Skip critical processes
        let name_lower = name.to_lowercase();
        if name_lower == "system" || name_lower == "services" || name_lower == "csrss" {
            continue;
        }

        unsafe {
            if let Ok(handle) = OpenProcess(PROCESS_TERMINATE, false, *pid) {
                // Try to terminate gracefully first (doesn't work with UWP, but we try)
                let _ = TerminateProcess(handle, 0);
                
                // Wait up to 2 seconds for process to terminate
                let _ = WaitForSingleObject(handle, 2000);
                
                let _ = CloseHandle(handle);
                
                // Small pause between processes
                std::thread::sleep(std::time::Duration::from_millis(100));
            }
        }
    }
    
    // Wait a bit more to ensure handles are released
    std::thread::sleep(std::time::Duration::from_millis(500));
    
    Ok(())
}

pub fn take_ownership(_file_path: &Path) -> Result<()> {
    unsafe {
        let mut token = HANDLE::default();
        
        // Open process token
        if OpenProcessToken(
            GetCurrentProcess(),
            TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY,
            &mut token,
        ).is_ok() {
            // Enable privileges
            enable_privilege(token, "SeTakeOwnershipPrivilege")?;
            enable_privilege(token, "SeRestorePrivilege")?;
            enable_privilege(token, "SeBackupPrivilege")?;
            
            let _ = CloseHandle(token);
        }
    }

    Ok(())
}

unsafe fn enable_privilege(token: HANDLE, privilege: &str) -> Result<()> {
    let privilege_wide: Vec<u16> = privilege.encode_utf16().chain(std::iter::once(0)).collect();
    
    let mut luid = LUID::default();
    if LookupPrivilegeValueW(PCWSTR::null(), PCWSTR(privilege_wide.as_ptr()), &mut luid).is_ok() {
        let tp = TOKEN_PRIVILEGES {
            PrivilegeCount: 1,
            Privileges: [LUID_AND_ATTRIBUTES {
                Luid: luid,
                Attributes: SE_PRIVILEGE_ENABLED,
            }],
        };

        let _ = AdjustTokenPrivileges(
            token,
            false,
            Some(&tp),
            0,
            None,
            None,
        );
    }

    Ok(())
}

/// Check if Minecraft is currently running
pub fn is_minecraft_running() -> bool {
    unsafe {
        let Ok(snapshot) = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0) else {
            return false;
        };

        let mut entry = PROCESSENTRY32W {
            dwSize: std::mem::size_of::<PROCESSENTRY32W>() as u32,
            ..Default::default()
        };

        if Process32FirstW(snapshot, &mut entry).is_ok() {
            loop {
                let process_name = String::from_utf16_lossy(&entry.szExeFile)
                    .trim_end_matches('\0')
                    .to_lowercase();
                
                if process_name.contains("minecraft") {
                    let _ = CloseHandle(snapshot);
                    return true;
                }

                if Process32NextW(snapshot, &mut entry).is_err() {
                    break;
                }
            }
        }

        let _ = CloseHandle(snapshot);
        false
    }
}

/// Close Minecraft process
pub fn close_minecraft() -> Result<()> {
    unsafe {
        let Ok(snapshot) = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0) else {
            return Ok(());
        };

        let mut entry = PROCESSENTRY32W {
            dwSize: std::mem::size_of::<PROCESSENTRY32W>() as u32,
            ..Default::default()
        };

        if Process32FirstW(snapshot, &mut entry).is_ok() {
            loop {
                let process_name = String::from_utf16_lossy(&entry.szExeFile)
                    .trim_end_matches('\0')
                    .to_lowercase();
                
                if process_name.contains("minecraft") {
                    if let Ok(handle) = OpenProcess(PROCESS_TERMINATE, false, entry.th32ProcessID) {
                        let _ = TerminateProcess(handle, 0);
                        let _ = WaitForSingleObject(handle, 3000);
                        let _ = CloseHandle(handle);
                    }
                }

                if Process32NextW(snapshot, &mut entry).is_err() {
                    break;
                }
            }
        }

        let _ = CloseHandle(snapshot);
    }
    
    Ok(())
}
