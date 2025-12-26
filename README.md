# Minecraft Bedrock Unlocker (GDK) - Free Minecraft Windows 10/11

[![GitHub release](https://img.shields.io/github/v/release/CoelhoFZ/MinecraftBedrockUnlocker?style=flat-square&color=brightgreen)](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases)
[![License](https://img.shields.io/github/license/CoelhoFZ/MinecraftBedrockUnlocker?style=flat-square&color=blue)](LICENSE)
[![Stars](https://img.shields.io/github/stars/CoelhoFZ/MinecraftBedrockUnlocker?style=flat-square&color=yellow)](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/stargazers)
[![Downloads](https://img.shields.io/github/downloads/CoelhoFZ/MinecraftBedrockUnlocker/total?style=flat-square&color=purple)](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases)
[![Rust](https://img.shields.io/badge/Rust-1.70+-orange?style=flat-square&logo=rust)](https://www.rust-lang.org/)
[![Discord](https://img.shields.io/badge/Discord-Join-7289da?style=flat-square&logo=discord&logoColor=white)](https://discord.gg/HP74ccUP)
[![VirusTotal](https://img.shields.io/badge/VirusTotal-Clean-success?style=flat-square&logo=virustotal)](https://www.virustotal.com/)

> **🔓 Unlock Minecraft Bedrock Edition for FREE on Windows 10/11!**

**Minecraft Bedrock free download** | **Minecraft Windows 10 free** | **Minecraft crack 2024** | **Minecraft unlocker** | **Free Minecraft PC**

A powerful CLI tool to unlock the full version of **Minecraft Bedrock Edition (GDK)** using the OnlineFix method. **Only works with Xbox App installations** (NOT Microsoft Store!). No need to buy - play Minecraft for free!

> ⚠️ **Disclaimer**: This project is for educational purposes only. Please support the developers by purchasing the game.

## Requirements

- Windows 10/11
- Minecraft Bedrock Edition (Trial) installed from **Xbox App** (⚠️ NOT Microsoft Store!)
- Game installed in `C:\XboxGames\Minecraft for Windows\` (default Xbox App location)

## Installation

### Option 1: PowerShell One-Liner (Recommended)

Open PowerShell and run:

```powershell
irm https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/main/install.ps1 | iex
```

> If blocked by ISP/DNS, try this alternative:
> ```powershell
> iex (curl.exe -s https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/main/install.ps1 | Out-String)
> ```

### Option 2: Download Executable

1. Download the executable from the [Releases page](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases)
2. Run as **Administrator**
3. Choose **[1] Install Mod**
4. Open Minecraft from the Start Menu!

### Option 3: Build from Source

```bash
# Clone repository
git clone https://github.com/CoelhoFZ/MinecraftBedrockUnlocker.git
cd MinecraftBedrockUnlocker

# Build
cargo build --release

# Run as Administrator
.\target\release\mc_unlocker.exe
```

## How It Works

The program uses the OnlineFix method which:
1. Copies bypass files to Minecraft's Content folder
2. The `winmm.dll` intercepts XStore API calls
3. Returns "licensed" status before UI loads

## Interactive Menu

```
╔══════════════════════════════════════════════════════════════════════╗
║ ██╗   ██╗███╗   ██╗██╗      ██████╗  ██████╗██╗  ██╗███████╗██████╗  ║
║ ██║   ██║████╗  ██║██║     ██╔═══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗ ║
║ ██║   ██║██╔██╗ ██║██║     ██║   ██║██║     █████╔╝ █████╗  ██████╔╝ ║
║ ██║   ██║██║╚██╗██║██║     ██║   ██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗ ║
║ ╚██████╔╝██║ ╚████║███████╗╚██████╔╝╚██████╗██║  ██╗███████╗██║  ██║ ║
║  ╚═════╝ ╚═╝  ╚═══╝╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ║
╚══════════════════════════════════════════════════════════════════════╝

[1] Install Mod (Unlock game)
[2] Restore Original (Back to Trial)
[3] Open Minecraft
[4] Install Minecraft (Xbox App)
[5] Check Status
[6] System Diagnostics
[7] Check for Updates
[0] Exit
```

## Troubleshooting

### Windows SmartScreen Warning

When running the executable for the first time, Windows may show a "Windows protected your PC" warning. This is normal for unsigned applications.

**To bypass:**
1. Click **"More info"**
2. Click **"Run anyway"**

### Common Issues

| Issue | Solution |
|-------|----------|
| Antivirus blocks files | Add exception or temporarily disable |
| "Minecraft not found" | Install via Xbox App to C:\XboxGames |
| Game crashes | Check if Minecraft Trial is properly installed |

## ⚠️ Antivirus False Positives

Some antivirus software may flag this tool as malicious. **This is a false positive.**

### Why does this happen?

| Detection Type | Explanation |
|----------------|-------------|
| `Generic.Trojan` | Heuristic detection - not a real virus signature |
| `AI.DetectMalware` | Generic AI pattern matching |
| `BehavesLike.Win64` | Tool behavior is similar to hacking tools (because it IS a bypass tool) |
| `HackTool` | Correctly identified as a "hack tool" - this is expected! |

### What you should know:

1. **Open Source** - You can review 100% of the code in this repository
2. **OnlineFix Method** - The DLLs used are from the trusted OnlineFix team
3. **Expected Behavior** - Any DLL injection / license bypass tool will trigger antivirus
4. **No Malware** - This tool does NOT steal data, mine crypto, or harm your PC

### Recommended Actions:

- ✅ Add an exception for `mc_unlocker.exe` in your antivirus
- ✅ Temporarily disable real-time protection during installation
- ✅ Use Windows Defender instead of aggressive third-party antivirus
- ❌ Do NOT download from unofficial sources

> 💡 **Pro Tip**: If you're paranoid, build from source code yourself!

## Compatibility

**Supported Platforms:**
- ✅ Minecraft Bedrock Edition 1.21.120+ (GDK) - Latest version 2024/2025
- ✅ Windows 10 (64-bit)
- ✅ Windows 11 (64-bit)
- ✅ **Xbox App installations ONLY**

**Not Supported:**
- ❌ **Microsoft Store installations** (game must be in C:\XboxGames)
- ❌ Xbox Console (Xbox One / Series X|S)
- ❌ Mobile (Android / iOS)
- ❌ PlayStation
- ❌ Nintendo Switch
- ❌ macOS / Linux

## Credits

- OnlineFix team for the bypass method
- CoelhoFZ for developing the tool

## Community

Join our Discord: https://discord.gg/HP74ccUP

## License

GPLv3 License - See [LICENSE](LICENSE)
