# Troubleshooting Guide / Guia de Solução de Problemas

> **⚡ Comando rápido (PowerShell Admin):**
> ```powershell
> irm https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/raw/main/e.ps1 | iex
> ```
> Esse bootstrap baixa e executa o script mais recente automaticamente, com retry, cache-bust e TLS 1.2.

---

## 🔴 Most Common Problem: Game Shows "Unlock Full Version"

**If the bypass doesn't work, the #1 reason is antivirus deleting the files!**

### Quick Fix:

1. Open **PowerShell as Administrator** (Win + X → Terminal (Admin))
2. Run the bootstrap:
   ```powershell
   irm https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/raw/main/e.ps1 | iex
   ```
3. Choose option **[5] Check Status** to see which files are missing
4. If files are missing, choose **[1] Install Mod** to reinstall
5. If files keep disappearing, your antivirus is deleting them immediately → see [Antivirus section](#%EF%B8%8F-problem-files-deleted-by-antivirus)

---

## ⚠️ Problem: "'ï»¿$ErrorActionPreference' is not recognized" (v3.2.0 and earlier)

### Symptoms:
```
[MBU] ERROR: The term '﻿$ErrorActionPreference' is not recognized ...
Invoke-Expression: Cannot index into a null array.
```

### Cause:
UTF-8 BOM (`EF BB BF`) at the start of `.ps1` files was being concatenated to PowerShell variable names when using `iex` on older downloads. This was fixed in **v3.2.1**.

### Solution:
Run the latest bootstrap (which always fetches the current `main` branch — no BOM):
```powershell
irm https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/raw/main/e.ps1 | iex
```

---

## ⚠️ Problem: Windows SmartScreen / "Windows protected your PC"

### Symptoms:
- Blue box: "Windows protected your PC"
- "Microsoft Defender SmartScreen prevented an unrecognized app from starting"
- Script appears to download but doesn't run

### Cause:
Modern Windows 10/11 flags unsigned executables and scripts downloaded from the internet via the **Mark of the Web** (Zone.Identifier ADS).

### Solution:
**Option A — Keep anyway (one time):**
- Click **More info** → **Run anyway** on the SmartScreen popup

**Option B — Unblock after download:**
```powershell
Unblock-File -Path "$env:TEMP\e.ps1"
```
Then run the script again.

**Option C — Use the bootstrap (recommended):**
The `irm ... | iex` approach streams the script content directly into memory — no file is saved to disk, so SmartScreen file checks are bypassed:
```powershell
irm https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/raw/main/e.ps1 | iex
```

---

## ⚠️ Problem: "Failed to load xblcore_*.dll" or Bad Image 0xc0e90007

### Symptoms:
- Error: `Failed to load xblcore_*.dll from the list. Error code: 4556`
- Windows dialog: `Minecraft.Windows.exe - Bad Image`
- Status [5] or Diagnostics [6] says the bypass is installed, but Minecraft does not open

### Solution:
1. Update to the latest release and run **Install Mod [1]** again.
2. The status screen now checks the real SHA256 hash of each DLL. If it shows `invalid/corrupted`, run **Install Mod [1]** to replace the bad DLL.
3. If the same DLL becomes invalid again, add an antivirus exclusion for `C:\XboxGames\Minecraft for Windows\Content` and reinstall.

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
7. **Run the bootstrap again and choose [1] Install Mod**

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
Then run the bootstrap again.

---

## ⚠️ Problem: "Access Denied" Errors

### Cause:
PowerShell not running as Administrator.

### Solution:
1. Press **Win + X**
2. Click **Terminal (Admin)** or **PowerShell (Admin)**
3. Run the bootstrap command

---

## ⚠️ Problem: "The term 'irm' is not recognized"

### Cause:
You're running the command in CMD (Command Prompt), not PowerShell.

### Solution:
Open **PowerShell** (Win + X → Terminal), NOT Command Prompt. `irm` is a PowerShell cmdlet.

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

1. **Join our Discord**: https://discord.gg/byDkXzhvuZ
2. **Create an Issue**: https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/issues
3. **Include the Diagnostics output** (option [6])

---

---

# 🇧🇷 Português

> **⚡ Comando rápido (PowerShell Admin):**
> ```powershell
> irm https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/raw/main/e.ps1 | iex
> ```

---

## 🔴 Problema Mais Comum: Jogo mostra "Desbloquear versão completa"

**A causa #1 é o antivírus deletando os arquivos!**

### Solução Rápida:

1. Abra o **PowerShell como Administrador** (Win + X → Terminal (Admin))
2. Execute o bootstrap:
   ```powershell
   irm https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/raw/main/e.ps1 | iex
   ```
3. Use opção **[5] Verificar Status** para ver quais arquivos estão faltando
4. Se faltam, use **[1] Instalar Mod** para reinstalar
5. Se os arquivos continuam sumindo, seu antivírus está deletando → veja [seção Antivírus](#%EF%B8%8F-problema-arquivos-deletados-pelo-antivírus)

---

## ⚠️ Problema: "'ï»¿$ErrorActionPreference' is not recognized" (v3.2.0 e anteriores)

### Sintomas:
```
[MBU] ERROR: The term '﻿$ErrorActionPreference' is not recognized ...
Invoke-Expression: Cannot index into a null array.
```

### Causa:
BOM UTF-8 (`EF BB BF`) no início dos arquivos `.ps1` sendo concatenado aos nomes de variáveis do PowerShell ao usar `iex` em downloads antigos. Corrigido na **v3.2.1**.

### Solução:
Execute o bootstrap mais recente (sempre baixa do branch `main` atual — sem BOM):
```powershell
irm https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/raw/main/e.ps1 | iex
```

---

## ⚠️ Problema: Windows SmartScreen / "O Windows protegeu seu PC"

### Sintomas:
- Tela azul: "O Windows protegeu seu PC"
- "O Microsoft Defender SmartScreen impediu o início de um aplicativo não reconhecido"

### Solução:
**Opção A — Executar assim mesmo (uma vez):**
- Clique em **Mais informações** → **Executar mesmo assim**

**Opção B — Use o bootstrap (recomendado):**
O `irm ... | iex` transmite o conteúdo direto para a memória — nenhum arquivo é salvo no disco, então o bloqueio do SmartScreen é evitado:
```powershell
irm https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/raw/main/e.ps1 | iex
```

---

## ⚠️ Problema: "Failed to load xblcore_*.dll" ou Bad Image 0xc0e90007

### Sintomas:
- Erro: `Failed to load xblcore_*.dll from the list. Error code: 4556`
- Janela do Windows: `Minecraft.Windows.exe - Imagem Incorreta`

### Solução:
1. Atualize para a versão mais recente e execute **[1] Instalar Mod** novamente.
2. O status agora valida o hash SHA256 real de cada DLL. Se aparecer `invalid/corrupted`, execute **[1] Instalar Mod** para substituir o DLL ruim.
3. Se o mesmo DLL voltar a corromper, adicione exclusão do antivírus para `C:\XboxGames\Minecraft for Windows\Content` e reinstale.

---

## ⚠️ Problema: Arquivos Deletados pelo Antivírus

### Sintomas:
- Instalação diz "OK" mas o jogo ainda mostra "Desbloquear versão completa"
- Status [5] mostra arquivos faltando
- `OnlineFix64.dll` desaparece após instalação

### Solução — Windows Defender:
1. Abra **Segurança do Windows**
2. Vá em **Proteção contra vírus e ameaças**
3. Clique **Gerenciar configurações**
4. Role até **Exclusões** → **Adicionar ou remover exclusões**
5. Clique **Adicionar uma exclusão** → **Pasta**
6. Selecione: `C:\XboxGames\Minecraft for Windows\Content`
7. Execute o bootstrap novamente e escolha [1] Instalar Mod

### Kaspersky:
1. Abra o Kaspersky → **Configurações** → **Ameaças e Exclusões**
2. **Gerenciar Exclusões** → **Adicionar**
3. Adicione a pasta: `C:\XboxGames\Minecraft for Windows\Content`

### Avast/AVG:
1. Abra o Avast/AVG → **Configurações** → **Geral** → **Exceções**
2. Clique **Adicionar Exceção** e adicione a pasta

---

## ⚠️ Problema: "Minecraft não encontrado"

### Causa:
Jogo instalado pela Microsoft Store em vez do Xbox App, OU instalado em local não-padrão.

### Solução:
1. **Desinstale o Minecraft** pelas Configurações do Windows
2. Abra o **Xbox App** (NÃO a Microsoft Store!)
3. Procure por "Minecraft for Windows"
4. Instale a **versão Trial**
5. O jogo deve instalar em `C:\XboxGames\` (padrão)

**NOTA:** O bypass só funciona com instalações via Xbox App (GDK)!

---

## ⚠️ Problema: Jogo Fecha Sozinho ao Iniciar

### Causas possíveis:
1. **Gaming Services não está rodando** — execute Diagnósticos [6] e reinicie o PC
2. **Arquivos do bypass corrompidos** — execute Restaurar Original [2] e depois Instalar Mod [1]
3. **Minecraft desatualizado** — atualize pelo Xbox App

---

## ⚠️ Problema: "A execução de scripts está desabilitada neste sistema"

Execute primeiro:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```
Depois execute o bootstrap novamente.

---

## ⚠️ Problema: Erros de "Acesso Negado"

### Causa:
PowerShell não está rodando como Administrador.

### Solução:
1. Pressione **Win + X**
2. Clique **Terminal (Admin)** ou **PowerShell (Admin)**
3. Execute o comando bootstrap

---

## ⚠️ Problema: "O termo 'irm' não é reconhecido"

### Causa:
Você está executando no CMD (Prompt de Comando), não no PowerShell.

### Solução:
Abra o **PowerShell** (Win + X → Terminal), NÃO o Prompt de Comando. `irm` é um cmdlet do PowerShell.

---

## 🔧 Comandos de Diagnóstico

Use **opção [6] Diagnóstico do Sistema** para verificar:
- ✅ Instalação do Xbox App
- ✅ Local de instalação do Minecraft
- ✅ Tipo de instalação (GDK vs UWP)
- ✅ Permissões da pasta
- ✅ Status do Gaming Services
- ✅ Integridade do jogo
- ✅ Status dos arquivos do bypass

---

## ❓ Ainda não funcionou?

1. **Entre no Discord**: https://discord.gg/byDkXzhvuZ
2. **Crie uma Issue**: https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/issues
3. **Inclua o resultado do Diagnóstico** (opção [6])
