# Troubleshooting Guide / Guia de Solução de Problemas

## 🔴 Most Common Problem: Game Shows "Unlock Full Version"

**If the bypass doesn't work, the #1 reason is antivirus deleting the files!**

### Quick Fix:

1. **Disable your antivirus temporarily**
2. **Run `mc_unlocker.exe` as Administrator**
3. **Choose option [1] to reinstall the bypass**
4. **Wait 5 seconds and check option [5] Status**
5. **If files are still missing, your antivirus is deleting them immediately**

---

## ⚠️ Problem: Files Deleted by Antivirus

### Symptoms:
- Install says "OK" but game still shows "Unlock Full Version"
- Running Status [5] shows files are missing
- `OnlineFix64.dll` disappears after installation

### Solution:

#### For Windows Defender:
1. Open **Windows Security** (search in Start Menu)
2. Go to **Virus & threat protection**
3. Click **Manage settings** under "Virus & threat protection settings"
4. Scroll down to **Exclusions** and click **Add or remove exclusions**
5. Click **Add an exclusion** → **Folder**
6. Navigate to and select: `C:\XboxGames\Minecraft for Windows\Content`
7. **Restart the unlocker and choose [1] Install Mod again**

#### For Kaspersky:
1. Open Kaspersky
2. Go to **Settings** → **Threats and Exclusions**
3. Click **Manage Exclusions** → **Add**
4. Add the folder: `C:\XboxGames\Minecraft for Windows\Content`

#### For Avast/AVG:
1. Open Avast/AVG
2. Go to **Settings** → **General** → **Exceptions**
3. Click **Add Exception**
4. Add the folder path

#### For Other Antivirus:
- Look for "Exclusions", "Exceptions", or "Whitelist" in settings
- Add the entire Minecraft Content folder

---

## ⚠️ Problem: "Minecraft not found"

### Cause:
The game is installed from Microsoft Store instead of Xbox App, OR installed in a non-standard location.

### Solution:
1. **Uninstall Minecraft** from Windows Settings
2. Open **Xbox App** (NOT Microsoft Store!)
3. Search for "Minecraft for Windows"
4. Install the **Trial version**
5. Make sure it installs to `C:\XboxGames\` (default)

**NOTE:** The bypass ONLY works with Xbox App (GDK) installations!

---

## ⚠️ Problem: Game Crashes on Startup

### Possible Causes:

1. **Gaming Services not running**
   - Run **Diagnostics [6]** to check
   - Solution: Restart your PC or reinstall Xbox App

2. **Corrupted bypass files**
   - Run **Restore Original [2]** first
   - Then **Install Mod [1]** again

3. **Outdated Minecraft version**
   - Update Minecraft from Xbox App
   - The OnlineFix DLLs may need updating for newer versions

---

## ⚠️ Problem: Windows SmartScreen Warning

When you first run the executable, Windows shows "Windows protected your PC".

### Solution:
1. Click **"More info"**
2. Click **"Run anyway"**

This is normal for unsigned applications.

---

## ⚠️ Problem: "Access Denied" Errors

### Cause:
Program not running as Administrator.

### Solution:
1. Right-click `mc_unlocker.exe`
2. Select **"Run as administrator"**
3. Click **Yes** on the UAC prompt

---

## 🔧 Diagnostic Commands

Use **option [6] System Diagnostics** to check:
- ✅ Xbox App installation
- ✅ Minecraft installation location
- ✅ Installation type (GDK vs UWP)
- ✅ Folder permissions
- ✅ Gaming Services status
- ✅ Game integrity
- ✅ Bypass files status

---

## ❓ Still Not Working?

1. **Join our Discord**: https://discord.gg/bfFdyJ3gEj
2. **Create an Issue**: https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/issues
3. **Include the Diagnostics output** (option [6])

---

## 🇧🇷 Português

### Problema: Jogo mostra "Desbloquear versão completa"

**A causa #1 é o antivírus deletando os arquivos!**

#### Solução Rápida:
1. Desative o antivírus temporariamente
2. Execute `mc_unlocker.exe` como Administrador
3. Escolha opção [1] para reinstalar
4. Espere 5 segundos e verifique opção [5] Status
5. Se os arquivos sumiram, adicione exclusão do antivírus

### Como adicionar exclusão no Windows Defender:
1. Abra **Segurança do Windows**
2. Vá em **Proteção contra vírus e ameaças**
3. Clique **Gerenciar configurações**
4. Role até **Exclusões** → **Adicionar ou remover exclusões**
5. Clique **Adicionar uma exclusão** → **Pasta**
6. Selecione: `C:\XboxGames\Minecraft for Windows\Content`
7. Reinstale o bypass com opção [1]

### Minecraft não encontrado?
- Instale pelo **Xbox App** (NÃO Microsoft Store!)
- O jogo deve estar em `C:\XboxGames\`
