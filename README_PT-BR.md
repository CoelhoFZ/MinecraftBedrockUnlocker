# Minecraft Bedrock Unlocker (GDK) - Minecraft Grátis Windows 10/11

[![GitHub release](https://img.shields.io/github/v/release/CoelhoFZ/MinecraftBedrockUnlocker?style=flat-square&color=brightgreen)](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases)
[![License](https://img.shields.io/github/license/CoelhoFZ/MinecraftBedrockUnlocker?style=flat-square&color=blue)](LICENSE)
[![Stars](https://img.shields.io/github/stars/CoelhoFZ/MinecraftBedrockUnlocker?style=flat-square&color=yellow)](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/stargazers)
[![Discord](https://img.shields.io/badge/Discord-Entrar-7289da?style=flat-square&logo=discord&logoColor=white)](https://discord.gg/bfFdyJ3gEj)

> **🔓 Desbloqueie o Minecraft Bedrock Edition DE GRAÇA no Windows 10/11!**

**Minecraft Bedrock grátis** | **Minecraft Windows 10 grátis** | **Minecraft crack 2024** | **Minecraft desbloqueador** | **Minecraft PC grátis** | **Como baixar Minecraft de graça**

Uma ferramenta PowerShell para desbloquear a versão completa do **Minecraft Bedrock Edition (GDK)** usando o método OnlineFix. **Só funciona com instalações do Xbox App** (NÃO Microsoft Store!). Sem precisar comprar - jogue Minecraft de graça!

> ⚠️ **Aviso**: Este projeto é apenas para fins educacionais. Por favor, apoie os desenvolvedores comprando o jogo.

## Requisitos

- Windows 10/11
- Minecraft Bedrock Edition (Trial) instalado pelo **Xbox App** (⚠️ NÃO pela Microsoft Store!)
- Jogo instalado em `C:\XboxGames\Minecraft for Windows\` (local padrão do Xbox App)

## Instalação

### PowerShell One-Liner (Só copiar e colar!)

Abra o **PowerShell como Administrador** e execute:

```powershell
irm https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/main/install.ps1 | iex
```

> Se bloqueado pelo provedor/DNS, tente esta alternativa:
> ```powershell
> iex (curl.exe -s https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/main/install.ps1 | Out-String)
> ```

É só isso! O script vai:
1. Detectar seu idioma automaticamente
2. Solicitar privilégios de Administrador se necessário
3. Encontrar sua instalação do Minecraft
4. Adicionar exclusões no Windows Defender automaticamente
5. Baixar e instalar os arquivos de bypass
6. Verificar a instalação

## Como Funciona

O script usa o método OnlineFix que:
1. Baixa os arquivos de bypass direto do GitHub para a pasta Content do Minecraft
2. O `winmm.dll` intercepta chamadas de API XStore
3. Retorna status "licenciado" antes da UI carregar

## Menu Interativo

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
