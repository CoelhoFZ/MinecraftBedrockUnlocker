# Troubleshooting Guide / Guia de Solução de Problemas

## 🔴 Most Common Problem: Game Shows "Unlock Full Version"

**If the bypass doesn't work, the #1 reason is antivirus deleting the files!**

### Quick Fix:

1. Open **PowerShell as Administrator**
2. Run the script: `irm https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/main/install.ps1 | iex`
3. Choose option **[5] Check Status** to see which files are missing
4. If files are missing, choose **[1] Install Mod** to reinstall
5. If files keep disappearing, your antivirus is deleting them immediately

---

## ⚠️ Problem: Files Deleted by Antivirus

### Symptoms:
- Install says "OK" but game still shows "Unlock Full Version"
- Status [5] shows files are missing
- `OnlineFix64.dll` disappears after installation

### Solution:

The script tries to add Windows Defender exclusions automatically, but if that fails:

#### For Windows Defender:
1. Open **Windows Security** (search in Start Menu)
2. Go to **Virus & threat protection**
3. Click **Manage settings** under "Virus & threat protection settings"
4. Scroll down to **Exclusions** and click **Add or remove exclusions**
5. Click **Add an exclusion** → **Folder**
6. Navigate to and select: `C:\XboxGames\Minecraft for Windows\Content`
7. **Run the script again and choose [1] Install Mod**

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

## ⚠️ Problem: "Running scripts is disabled on this system"

### Solution:
Run this command first:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```
Then try the install command again.

---

## ⚠️ Problem: "Access Denied" Errors

### Cause:
PowerShell not running as Administrator.

### Solution:
1. Press **Win + X**
2. Click **Terminal (Admin)** or **PowerShell (Admin)**
3. Paste the install command

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
1. Abra o **PowerShell como Administrador**
2. Execute: `irm https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/main/install.ps1 | iex`
3. Use opção **[5] Verificar Status** para ver quais arquivos estão faltando
4. Se faltam, use **[1] Instalar Mod** para reinstalar
5. Se os arquivos continuam sumindo, adicione exclusão do antivírus

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

### Erro "A execução de scripts está desabilitada neste sistema"
Execute primeiro:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```
Depois tente o comando de instalação novamente.
