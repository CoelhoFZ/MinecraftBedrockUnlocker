<p align="center">
  <img src="https://img.icons8.com/color/96/minecraft-logo.png" alt="Minecraft Bedrock Unlocker" width="96"/>
</p>

<h1 align="center">Minecraft Bedrock Unlocker</h1>

<p align="center">
  <strong>Unlock Minecraft Bedrock Edition for free on Windows 10/11</strong>
</p>

<p align="center">
  <a href="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest"><img src="https://img.shields.io/github/v/release/CoelhoFZ/MinecraftBedrockUnlocker?style=for-the-badge&color=brightgreen&label=Latest%20Version" alt="Latest Release"/></a>
  <a href="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/stargazers"><img src="https://img.shields.io/github/stars/CoelhoFZ/MinecraftBedrockUnlocker?style=for-the-badge&color=yellow" alt="Stars"/></a>
  <a href="https://discord.gg/bfFdyJ3gEj"><img src="https://img.shields.io/badge/Discord-Join%20Us-7289da?style=for-the-badge&logo=discord&logoColor=white" alt="Discord"/></a>
</p>

<p align="center">
  <a href="README_PT-BR.md">🇧🇷 Português</a> · <a href="#installation">🇺🇸 English</a>
</p>

---

## What is this?

**Minecraft Bedrock Unlocker** is a tool that unlocks the full version of **Minecraft Bedrock Edition (GDK)** on Windows. No need to purchase the game — just install and play!

- Works with **Windows 10** and **Windows 11** (64-bit)
- One-command installation — no technical knowledge required
- Survives antivirus scans and system reboots
- Multi-language support (English, Portuguese, Spanish)

> ⚠️ **Disclaimer**: This project is for educational purposes only. Please support the developers by purchasing the game.

---

## Requirements

| Requirement | Details |
|---|---|
| **OS** | Windows 10 or 11 (64-bit) |
| **Minecraft** | Bedrock Edition (Trial) installed from **Xbox App** |
| **Install Path** | `C:\XboxGames\Minecraft for Windows\` (default Xbox App location) |
| **Privileges** | Run as Administrator |

> **Important:** The game MUST be installed via the **Xbox App**, NOT the Microsoft Store.

---

## Installation

### Method 1: PowerShell (Recommended)

Open **PowerShell as Administrator** and paste:

```powershell
irm https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest/download/install.ps1 | iex
```

> **Alternative** (if your ISP/DNS blocks the URL):
> ```powershell
> iex (curl.exe -sL https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest/download/install.ps1 | Out-String)
> ```

The script handles everything automatically:
1. Detects your language
2. Requests Administrator privileges
3. Finds your Minecraft installation
4. Configures antivirus exclusions
5. Installs and verifies the unlock

### Method 2: EXE (Portable)

1. Go to [**Releases**](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest)
2. Download `MinecraftBedrockUnlocker.exe`
3. Run as Administrator

> **Note:** Your antivirus might flag the EXE. This is a false positive — see [Antivirus FAQ](#antivirus-faq) below.

---

## Menu

After running the tool:

```
  ============================================================
   __  __ _                            __ _   
  |  \/  (_)_ __   ___  ___ _ __ __ _ / _| |_ 
  | |\/| | | '_ \ / _ \/ __| '__/ _' | |_| __|
  | |  | | | | | |  __/ (__| | | (_| |  _| |_ 
  |_|  |_|_|_| |_|\___|\___|_|  \__,_|_|  \__|
     ____           _                 _        
    | __ )  ___  __| |_ __ ___   ___| | __    
    |  _ \ / _ \/ _' | '__/ _ \ / __| |/ /    
    | |_) |  __/ (_| | | | (_) | (__|   <     
    |____/ \___|\__,_|_|  \___/ \___|_|\_\    
                     Unlocker by CoelhoFZ      
  ============================================================

  [1] Install Mod (Unlock Game)
  [2] Restore Original (Back to Trial)
  [3] Open Minecraft
  [4] Install Minecraft (Xbox App)
  [5] Check Status
  [6] System Diagnostics
  [0] Exit
```

---

## Antivirus FAQ

The tool modifies game files to bypass license checks. **Some antivirus programs will flag this as suspicious** — this is expected behavior for any game unlocker.

### What you should know:

- **No malware** — this tool does NOT steal data, mine crypto, or harm your PC
- **False positives** — antivirus warnings are triggered by the license bypass technique, not by actual malicious code
- **Auto-handled** — the script automatically configures antivirus exclusions
- **Reboot-safe** — even if your antivirus removes files during reboot, the tool restores them automatically

### If antivirus keeps blocking:

1. The script handles most cases automatically — just run it again
2. If needed, manually add an exclusion for: `C:\XboxGames\Minecraft for Windows\Content`
3. Join our [Discord](https://discord.gg/bfFdyJ3gEj) for help

---

## Compatibility

| Platform | Status |
|---|---|
| Windows 10 (64-bit) | ✅ Supported |
| Windows 11 (64-bit) | ✅ Supported |
| Minecraft 1.21+ (GDK) | ✅ Supported |
| Xbox App installations | ✅ Required |
| Microsoft Store installations | ❌ Not supported |
| Xbox / PlayStation / Switch | ❌ Not supported |
| Mobile (Android / iOS) | ❌ Not supported |

---

## Troubleshooting

| Problem | Solution |
|---|---|
| "Minecraft not found" | Install the game via **Xbox App** (not Microsoft Store) |
| Game still shows trial | Run the script again — antivirus may have removed files |
| Game crashes on launch | Use option **[6] System Diagnostics** to check your setup |
| Script blocked by antivirus | Use the PowerShell method (less likely to be blocked than EXE) |
| Download blocked by ISP | Try the alternative command with `curl.exe` |

---

## Community & Support

- **Discord:** [discord.gg/bfFdyJ3gEj](https://discord.gg/bfFdyJ3gEj)
- **Issues:** Open an issue on this repository

---

## Credits

Developed by **CoelhoFZ**

---

<p align="center">
  <sub>⭐ If this tool helped you, please give it a star! It helps others find it.</sub>
</p>
