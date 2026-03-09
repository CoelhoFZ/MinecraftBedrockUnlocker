# Minecraft Bedrock Unlocker (GDK) - Minecraft Grátis Windows 10/11

<p align="center">
  <img src="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/blob/main/docs/logo.png?raw=true" width="120" alt="logo"/>
</p>

<p align="center">
  <a href="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest">
    <img src="https://img.shields.io/github/v/release/CoelhoFZ/MinecraftBedrockUnlocker?style=for-the-badge&color=brightgreen&label=ÚLTIMA+VERSÃO" alt="Última Versão"/>
  </a>
  <a href="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/stargazers">
    <img src="https://img.shields.io/github/stars/CoelhoFZ/MinecraftBedrockUnlocker?style=for-the-badge&color=yellow" alt="Stars"/>
  </a>
  <a href="https://discord.gg/bfFdyJ3gEj">
    <img src="https://img.shields.io/badge/DISCORD-ENTRAR-7289da?style=for-the-badge&logo=discord&logoColor=white" alt="Discord"/>
  </a>
  <a href="README.md">
    <img src="https://img.shields.io/badge/lang-EN-012169?style=for-the-badge" alt="English"/>
  </a>
</p>

> **🔓 Desbloqueie o Minecraft Bedrock Edition DE GRAÇA no Windows 10/11!**

**Minecraft Bedrock grátis** | **Minecraft Windows 10 grátis** | **Minecraft crack 2024** | **Minecraft desbloqueador** | **Minecraft PC grátis** | **Como baixar Minecraft de graça**

Uma ferramenta para desbloquear a versão completa do **Minecraft Bedrock Edition (GDK)**. **Só funciona com instalações do Xbox App** (NÃO Microsoft Store!).

> ⚠️ **Aviso**: Este projeto é apenas para fins educacionais. Por favor, apoie os desenvolvedores comprando o jogo.

---

## ⬇️ Download

<p align="center">
  <a href="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest/download/MinecraftBedrockUnlocker.exe">
    <img src="https://img.shields.io/badge/Baixar%20EXE-MinecraftBedrockUnlocker.exe-blue?style=for-the-badge&logo=windows" alt="Baixar EXE"/>
  </a>
</p>

> **Opção 1 — EXE Portátil** *(recomendado, sem configuração)*
> Baixe e execute `MinecraftBedrockUnlocker.exe` como Administrador. Sem PowerShell, sem passos extras.

> **Opção 2 — Linha de comando PowerShell** *(online, sem arquivo para baixar)*
> Abra o **PowerShell como Administrador** e execute:
> ```powershell
> irm https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest/download/install.ps1 | iex
> ```

> Se bloqueado pelo provedor/DNS, tente:
> ```powershell
> iex (curl.exe -s https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest/download/install.ps1 | Out-String)
> ```

👉 [Ver todos os releases e changelogs](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases)

---

## Requisitos

- Windows 10/11 (64-bit)
- Minecraft Bedrock Edition instalado pelo **Xbox App** (⚠️ NÃO pela Microsoft Store!)
- Jogo instalado em `C:\XboxGames\Minecraft for Windows\` (local padrão do Xbox App)

## O que faz

A ferramenta:
1. Detecta seu idioma automaticamente (PT-BR, EN, ES)
2. Solicita privilégios de Administrador se necessário
3. Encontra sua instalação do Minecraft
4. Gerencia exclusões de antivírus automaticamente
5. Instala e verifica os arquivos de desbloqueio
6. Mantém o jogo desbloqueado após reinicializações

## Menu Interativo

```
  ============================================================
   __  __ _                            __ _   
  |  \/  (_)_ __   ___  ___ _ __ __ _ / _| |_ 
  | |\/| | | '_ \ / _ \/ __| '__/ _' | |_| __|
  | |  | | | | | |  __/ (__| | | (_| |  _| |_ 
  |_|  |_|_|_| |_|\___|\___|\_  \__,_|_|  \__|
     ____           _                 _        
    | __ )  ___  __| |_ __ ___   ___| | __    
    |  _ \ / _ \/ _' | '__/ _ \ / __| |/ /    
    | |_) |  __/ (_| | | | (_) | (__|   <     
    |____/ \___|\__,_|_|  \___/ \___|_|\_\    
                     Unlocker by CoelhoFZ      
  ============================================================

[1] Instalar Mod (Desbloquear Jogo)
[2] Restaurar Original (Voltar ao Trial)
[3] Abrir Minecraft
[4] Instalar Minecraft (Xbox App)
[5] Verificar Status
[6] Diagnóstico do Sistema
[0] Sair
```

## Funcionalidades

- 🌍 **Multi-idioma**: Detecta automaticamente EN, PT-BR, ES
- 🛡️ **Tratamento de antivírus**: Adiciona exclusões automaticamente para Windows Defender, Bitdefender Free e outros
- 🔄 **Tentativa automática**: Se o antivírus remover os arquivos, tenta novamente
- 📊 **Diagnóstico**: Verificação completa de saúde do sistema
- 🔧 **Auto-reparo**: Corrige arquivos faltando ao abrir o Minecraft
- ✅ **Verificação de integridade**: Checagem de hash após instalação
- 💾 **Persistência**: Sobrevive a reinicializações do sistema

## Solução de Problemas

### Problemas Comuns

| Problema | Solução |
|----------|---------|
| Antivírus bloqueia arquivos | A ferramenta adiciona exclusões automaticamente. Para Bitdefender Free, um processo guiado passo a passo é exibido |
| "Minecraft não encontrado" | Instale via Xbox App em `C:\XboxGames` |
| Jogo mostra "Desbloquear versão completa" | Arquivos foram removidos — execute a ferramenta novamente |
| Jogo crasha | Execute Diagnóstico [6] e verifique Gaming Services |

> Veja [TROUBLESHOOTING.md](TROUBLESHOOTING.md) para ajuda detalhada.

## ⚠️ Falsos Positivos de Antivírus

Os arquivos usados podem disparar alertas de antivírus — **isso é esperado** com qualquer ferramenta de desbloqueio.

1. **Código disponível** — Você pode revisar o script instalador neste repositório
2. **Sem malware** — Esta ferramenta NÃO rouba dados, minera criptomoedas ou danifica seu PC
3. **Exclusões guiadas** — A ferramenta guia você para adicionar exceções no seu AV específico

## Compatibilidade

**Suportado:**
- ✅ Minecraft Bedrock Edition 1.21.120+ (GDK)
- ✅ Windows 10 (64-bit)
- ✅ Windows 11 (64-bit)
- ✅ Instalações via Xbox App SOMENTE

**Não Suportado:**
- ❌ Instalações via Microsoft Store
- ❌ Xbox Console, Mobile, PlayStation, Nintendo Switch, macOS/Linux

## Comunidade

Entre no nosso Discord: https://discord.gg/bfFdyJ3gEj

## Créditos

- Equipe OnlineFix
- CoelhoFZ pelo desenvolvimento da ferramenta

## Licença

GPLv3 - Veja [LICENSE](LICENSE)


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

[1] Instalar Mod (Desbloquear Jogo)
[2] Restaurar Original (Voltar ao Trial)
[3] Abrir Minecraft
[4] Instalar Minecraft (Xbox App)
[5] Verificar Status
[6] Diagnóstico do Sistema
[0] Sair
```

## Funcionalidades

- 🌍 **Multi-idioma**: Detecta automaticamente EN, PT-BR, ES
- 🛡️ **Tratamento de antivírus**: Adiciona exclusões no Windows Defender automaticamente
- 🔄 **Tentativa automática**: Se o antivírus deletar os arquivos, tenta novamente
- 📊 **Diagnóstico**: Verificação completa de saúde do sistema
- 🔧 **Auto-reparo**: Corrige arquivos faltando ao abrir o Minecraft
- ✅ **Verificação de integridade**: Checagem SHA256 após download
- 📦 **Sem EXE**: Roda 100% no PowerShell - sem downloads bloqueados pelo antivírus!

## Solução de Problemas

### Problemas Comuns

| Problema | Solução |
|----------|---------|
| Antivírus bloqueia arquivos | O script adiciona exclusões automaticamente. Se ainda falhar, desative o AV temporariamente |
| "Minecraft não encontrado" | Instale via Xbox App em C:\XboxGames |
| Jogo mostra "Desbloquear versão completa" | Antivírus deletou os arquivos - execute o script novamente |
| Jogo crasha | Execute Diagnóstico [6] e verifique Gaming Services |

### Exclusão Manual de Antivírus

Se o script não conseguir adicionar exclusões automaticamente:

1. Abra **Segurança do Windows**
2. Vá em **Proteção contra vírus e ameaças** → **Gerenciar configurações**
3. Role até **Exclusões** → **Adicionar ou remover exclusões**
4. Adicione a pasta: `C:\XboxGames\Minecraft for Windows\Content`

> Veja [TROUBLESHOOTING.md](TROUBLESHOOTING.md) para ajuda detalhada.

## ⚠️ Falsos Positivos de Antivírus

Os arquivos DLL usados podem disparar alertas de antivírus. **Isso é comportamento esperado** - qualquer ferramenta de bypass de licença dispara detecções heurísticas.

### O que você deve saber:

1. **Código Aberto** - Você pode revisar 100% do código neste repositório
2. **Método OnlineFix** - As DLLs usadas são da confiável equipe OnlineFix
3. **Sem EXE** - O script PowerShell baixa DLLs diretamente do GitHub
4. **Sem Malware** - Esta ferramenta NÃO rouba dados, minera criptomoedas ou danifica seu PC

## Compatibilidade

**Suportado:**
- ✅ Minecraft Bedrock Edition 1.21.120+ (GDK) - 2024/2025
- ✅ Windows 10 (64-bit)
- ✅ Windows 11 (64-bit)
- ✅ **Instalações via Xbox App SOMENTE**

**Não Suportado:**
- ❌ Instalações via Microsoft Store (o jogo precisa estar em C:\XboxGames)
- ❌ Xbox Console (Xbox One / Series X|S)
- ❌ Mobile (Android / iOS)
- ❌ PlayStation / Nintendo Switch
- ❌ macOS / Linux

## Créditos

- Equipe OnlineFix pelo método de bypass
- CoelhoFZ pelo desenvolvimento da ferramenta

## Comunidade

Entre no nosso Discord: https://discord.gg/bfFdyJ3gEj

## Licença

GPLv3 License - Veja [LICENSE](LICENSE)
