<p align="center">
  <img src="https://img.icons8.com/color/96/minecraft-logo.png" alt="Minecraft Bedrock Unlocker" width="96"/>
</p>

<h1 align="center">Minecraft Bedrock Unlocker</h1>

<p align="center">
  <strong>Desbloqueie o Minecraft Bedrock Edition de graça no Windows 10/11</strong>
</p>

<p align="center">
  <a href="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest"><img src="https://img.shields.io/github/v/release/CoelhoFZ/MinecraftBedrockUnlocker?style=for-the-badge&color=brightgreen&label=Vers%C3%A3o" alt="Última Versão"/></a>
  <a href="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/stargazers"><img src="https://img.shields.io/github/stars/CoelhoFZ/MinecraftBedrockUnlocker?style=for-the-badge&color=yellow" alt="Estrelas"/></a>
  <a href="https://discord.gg/bfFdyJ3gEj"><img src="https://img.shields.io/badge/Discord-Entrar-7289da?style=for-the-badge&logo=discord&logoColor=white" alt="Discord"/></a>
</p>

<p align="center">
  <a href="README.md">🇺🇸 English</a> · <a href="#instalação">🇧🇷 Português</a>
</p>

---

## O que é isso?

**Minecraft Bedrock Unlocker** é uma ferramenta que desbloqueia a versão completa do **Minecraft Bedrock Edition (GDK)** no Windows. Sem precisar comprar o jogo — é só instalar e jogar!

- Funciona no **Windows 10** e **Windows 11** (64-bit)
- Instalação com um único comando — sem conhecimento técnico
- Resiste a antivírus e reinicializações do sistema
- Suporte multi-idioma (Inglês, Português, Espanhol)

> ⚠️ **Aviso**: Este projeto é apenas para fins educacionais. Por favor, apoie os desenvolvedores comprando o jogo.

---

## Requisitos

| Requisito | Detalhes |
|---|---|
| **Sistema** | Windows 10 ou 11 (64-bit) |
| **Minecraft** | Bedrock Edition (Trial) instalado pelo **Xbox App** |
| **Local** | `C:\XboxGames\Minecraft for Windows\` (padrão do Xbox App) |
| **Permissão** | Executar como Administrador |

> **Importante:** O jogo DEVE ser instalado pelo **Xbox App**, NÃO pela Microsoft Store.

---

## Instalação

### Método 1: PowerShell (Recomendado)

Abra o **PowerShell como Administrador** e cole:

```powershell
irm https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest/download/install.ps1 | iex
```

> **Alternativa** (se seu provedor/DNS bloquear a URL):
> ```powershell
> iex (curl.exe -sL https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest/download/install.ps1 | Out-String)
> ```

O script faz tudo automaticamente:
1. Detecta seu idioma
2. Solicita privilégios de Administrador
3. Encontra sua instalação do Minecraft
4. Configura exclusões do antivírus
5. Instala e verifica o desbloqueio

### Método 2: EXE (Portátil)

1. Vá em [**Releases**](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest)
2. Baixe o `MinecraftBedrockUnlocker.exe`
3. Execute como Administrador

> **Nota:** Seu antivírus pode sinalizar o EXE. Isso é um falso positivo — veja o [FAQ de Antivírus](#faq-antivírus) abaixo.

---

## Menu

Após executar a ferramenta:

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

---

## FAQ Antivírus

A ferramenta modifica arquivos do jogo para contornar a verificação de licença. **Alguns antivírus vão sinalizar isso como suspeito** — é um comportamento esperado para qualquer desbloqueador de jogos.

### O que você precisa saber:

- **Sem malware** — esta ferramenta NÃO rouba dados, minera criptomoedas ou danifica seu PC
- **Falsos positivos** — alertas de antivírus são disparados pela técnica de desbloqueio, não por código malicioso
- **Tratamento automático** — o script configura exclusões de antivírus automaticamente
- **Resiste a reinício** — se o antivírus remover arquivos durante o reinício, a ferramenta os restaura automaticamente

### Se o antivírus continuar bloqueando:

1. O script trata a maioria dos casos automaticamente — só execute novamente
2. Se necessário, adicione uma exclusão manual para: `C:\XboxGames\Minecraft for Windows\Content`
3. Entre no nosso [Discord](https://discord.gg/bfFdyJ3gEj) para ajuda

---

## Compatibilidade

| Plataforma | Status |
|---|---|
| Windows 10 (64-bit) | ✅ Suportado |
| Windows 11 (64-bit) | ✅ Suportado |
| Minecraft 1.21+ (GDK) | ✅ Suportado |
| Instalações via Xbox App | ✅ Obrigatório |
| Instalações via Microsoft Store | ❌ Não suportado |
| Xbox / PlayStation / Switch | ❌ Não suportado |
| Mobile (Android / iOS) | ❌ Não suportado |

---

## Solução de Problemas

| Problema | Solução |
|---|---|
| "Minecraft não encontrado" | Instale o jogo pelo **Xbox App** (não pela Microsoft Store) |
| Jogo ainda mostra trial | Execute o script novamente — o antivírus pode ter removido arquivos |
| Jogo crasha ao abrir | Use a opção **[6] Diagnóstico do Sistema** para verificar |
| Script bloqueado pelo antivírus | Use o método PowerShell (menos chance de ser bloqueado que o EXE) |
| Download bloqueado pelo provedor | Tente o comando alternativo com `curl.exe` |

---

## Comunidade & Suporte

- **Discord:** [discord.gg/bfFdyJ3gEj](https://discord.gg/bfFdyJ3gEj)
- **Issues:** Abra uma issue neste repositório

---

## Créditos

Desenvolvido por **CoelhoFZ**

---

<p align="center">
  <sub>⭐ Se essa ferramenta te ajudou, dê uma estrela! Ajuda outras pessoas a encontrarem.</sub>
</p>
