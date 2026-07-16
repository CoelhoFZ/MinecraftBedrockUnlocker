# 📦 Installation Guide - Minecraft Bedrock Unlocker

> Complete step-by-step installation guide for Windows

## 🎯 Quick Install

### Step 1: Install Minecraft Trial

1. Open the **Xbox App** (NOT Microsoft Store!)
2. Search for "Minecraft for Windows"
3. Install the **Trial version** (free)
4. Make sure it installs to `C:\XboxGames\` (default)

> ⚠️ **IMPORTANT**: Must be installed from Xbox App, NOT Microsoft Store!

### Step 2: Run the Unlocker

Open **PowerShell as Administrator** and paste one of these short commands:

**Option 1 - run the PowerShell installer directly:**

```powershell
irm https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/raw/main/i.ps1 | iex
```

**Option 2 - download and start the EXE:**

```powershell
irm https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/raw/main/install.ps1 | iex
```

Both short bootstraps download the latest release assets with cache-busting, reject empty or HTML responses and verify SHA256 before running anything.

### Step 3: Choose Option [1]

The script will show an interactive menu. If Minecraft is not installed, select **[1] Install Mod**.

### Step 4: Play!

Open Minecraft from the Start Menu or use option **[3]** in the script.

---

## 🔧 How to Open PowerShell as Administrator

### Method 1 (Easiest):
1. Press **Win + X**
2. Click **Terminal (Admin)** or **PowerShell (Admin)**

### Method 2:
1. Press **Win** key
2. Type **PowerShell**
3. Right-click → **Run as administrator**

### Method 3:
1. Press **Win + R**
2. Type `powershell`
3. Press **Ctrl + Shift + Enter** (runs as admin)

---

## 🌍 Language Support (Multi7)

The script automatically detects your Windows OS culture via `Get-Culture` and shows UI strings in the matching language. It never uses IP geolocation.

The unlocker ships with **full UI translation** in the **top 7 most-spoken languages worldwide** (Ethnologue 2023, native + L2):

| # | Language | Code | Native name |
|---|----------|------|-------------|
| 1 | English | `en` | English |
| 2 | Chinese (Mandarin) | `zh` | 中文 |
| 3 | Hindi | `hi` | हिन्दी |
| 4 | Spanish | `es` | Español |
| 5 | French | `fr` | Français |
| 6 | Arabic | `ar` | العربية |
| 7 | Russian | `ru` | Русский |

Examples of auto-detected Windows culture codes:
- `en-US`, `en-GB` → English
- `zh-CN`, `zh-TW` → 中文 (Chinese)
- `hi-IN` → हिन्दी (Hindi)
- `es-ES`, `es-MX`, `pt-BR` (not in top 7, falls back to English) → Español (Spanish) for `es-*`; everything else → English
- `fr-FR`, `fr-CA` → Français
- `ar-SA`, `ar-EG` → العربية
- `ru-RU` → Русский

You can override the language with the `-Lang` parameter on the `bootstrap-v3.2.0.ps1` script:
```powershell
.\bootstrap-v3.2.0.ps1 -Lang zh   # force Chinese
.\bootstrap-v3.2.0.ps1 -Lang auto # default (use OS culture)
```

---

## 🔄 Alternative Installation (if GitHub raw is blocked)

If a short command is blocked, use the release-hosted installer directly:

```powershell
$s=irm https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest/download/install.ps1|Out-String;$t=$s.TrimStart();if(!$t -or $t -match '(?i)^(<!doctype|<html)'){throw 'bad download'};iex $s
```

---

## ❓ Troubleshooting

### "Running scripts is disabled on this system"

Run this first:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```
Then try the install command again.

### "Access Denied" error

Make sure you're running PowerShell as **Administrator** (see above).

### Antivirus blocks the files

The script adds Windows Defender exclusions automatically. If you have a third-party antivirus:

1. Temporarily disable real-time protection
2. Run the script
3. Add exception for `C:\XboxGames\Minecraft for Windows\Content`
4. Re-enable antivirus

### "Minecraft not found"

The game must be installed via **Xbox App** in `C:\XboxGames\`:

1. Open Xbox App
2. Search "Minecraft for Windows"
3. Install the Trial version
4. Run the script again

---

## 📋 System Requirements

- **OS:** Windows 10/11 (64-bit)
- **PowerShell:** 5.1+ (pre-installed on Windows 10/11)
- **Internet:** Required (to download DLL files from GitHub)
- **Permissions:** Administrator rights
- **Disk:** ~15 MB free space in Minecraft folder

---

## 🔄 Uninstall / Restore Original

To remove the bypass and restore the game to Trial mode:

1. Run the script again
2. Choose option **[1] Restore Original**
3. Done! Game is back to normal

---

## ⚠️ Important Notes

1. **Educational purposes only**
   - This tool is for learning and research
   - Consider purchasing a legitimate license

2. **No warranty**
   - Use at your own risk

3. **Xbox App required**
   - Microsoft Store installations are NOT compatible

4. **Source and license scope**
   - Installer, launcher wrapper and documentation authored in this repository are GPLv3
   - Online-Fix runtime DLLs are closed-source third-party components documented in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)
   - See [SOURCE.md](SOURCE.md) for the build/source map

---

## 🆘 Need Help?

- **Discord:** https://discord.gg/byDkXzhvuZ
- **Issues:** [Report a bug](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/issues)

---

Made with ❤️ by [CoelhoFZ](https://github.com/CoelhoFZ) | [Back to README](README.md)
