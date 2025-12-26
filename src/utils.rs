// Common utilities shared across modules

/// Get all available drive letters on the system using Windows API
/// Skips A: and B: (floppy drives)
pub fn get_available_drives() -> Vec<char> {
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
