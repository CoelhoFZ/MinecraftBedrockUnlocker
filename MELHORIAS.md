# Melhorias identificadas

Revisao feita em 16/07/2026 (UTC) sobre o codigo em `main`, os assets do release mais recente e as issues abertas.

## Aplicado nesta alteracao

- Removido do menu principal o bloco `ACOES DISPONIVEIS` / `AVAILABLE ACTIONS` e seus dois separadores.

Todo o backlog abaixo permanece pendente e nao foi aplicado nesta alteracao.

## Prioridade P0

### 1. Verificar criptograficamente todo payload antes da execucao

**Evidencia**

- `unlocker.ps1:52-77` baixa o core de `main` ou do release e aceita o conteudo apenas por tamanho, texto e existencia de `Start-MainLoop`.
- `i.ps1:236-270` e `e.ps1:236-270` executam o texto baixado com `iex` apos validacoes estruturais equivalentes.
- Os URLs de `main` sao mutaveis, portanto o conteudo executado nao esta vinculado a uma versao publicada.

**Melhoria**

Publicar um manifesto por versao contendo SHA-256 de cada script e DLL, baixar apenas assets do release versionado, validar o hash antes da execucao e assinar os scripts PowerShell com Authenticode. Ativar releases imutaveis para impedir troca posterior de tag ou asset.

**Criterio de aceite**

- Toda execucao remota falha antes de `iex` ou `[ScriptBlock]::Create` quando hash, assinatura ou versao divergir.
- O fluxo nao depende de `raw/main` para instalar uma versao publicada.
- O release contem manifesto, hashes e atestacao verificaveis.

Referencias: [PowerShell signing](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_signing?view=powershell-7.6), [GitHub immutable releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases).

### 2. Corrigir o contrato de assets e os fallbacks de download

**Evidencia**

- O release mais recente publicado em 14/07/2026 contem apenas `install.bat` e `OnlineFix.zip`.
- `unlocker.ps1:52-55` declara fallback para `releases/latest/download/unlocker.ps1`, asset que nao existe nesse release.
- A issue [#27](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/issues/27) registra 404 no bootstrap e recebeu confirmacoes de outros usuarios.

**Melhoria**

Definir um manifesto de release obrigatorio e publicar juntos `install.bat`, `install.ps1`, `i.ps1`, `e.ps1`, `unlocker.ps1`, `SHA256SUMS.txt` e `OnlineFix.zip`, ou alterar os fallbacks para os assets realmente publicados. Criar smoke test que faz download de cada URL documentada e de cada fallback antes de publicar.

**Criterio de aceite**

- Nenhum URL de fallback aponta para asset ausente.
- O smoke test valida HTTP 200, conteudo esperado e hash de todos os downloads.
- A mensagem de falha mostra URL, status HTTP e o proximo comando valido.

### 3. Alinhar tag, versao, nome do release e artefatos

**Evidencia**

- `VERSION` contem `3.3.3`.
- O release se chama `v3.3.3`, mas o tag associado e `v1.0.0`.
- O release e mutavel no estado atual.

**Melhoria**

Usar `VERSION` como fonte unica e bloquear publicacao quando `v$VERSION`, tag, nome do release, headers dos scripts e hashes nao forem iguais.

**Criterio de aceite**

- A pipeline recusa um release com tag diferente de `v$VERSION`.
- O changelog, o binario e todos os scripts exibem a mesma versao.
- A publicacao usa draft, sobe todos os assets e so depois publica o release imutavel.

## Prioridade P1

### 4. Eliminar a reescrita dinamica do core em tempo de execucao

**Evidencia**

- `unlocker.ps1:90-150` substitui trechos literais do core.
- `unlocker.ps1:523-607` localiza e troca `Start-MainLoop` por regex.
- Uma mudanca inocente de texto ou formato em `runtime/unlocker-core.ps1` pode impedir a inicializacao do bootstrap.

**Melhoria**

Mover compatibilidade, diagnostico e menu dinamico para o proprio core, expondo funcoes e parametros versionados em vez de editar codigo baixado como texto.

**Criterio de aceite**

- O core inicia sem `Replace` de codigo e sem substituicao de bloco por regex.
- Uma nova versao do core declara compatibilidade e recebe testes de contrato.
- O bootstrap informa versao do core e motivo claro se houver incompatibilidade.

### 5. Criar testes automatizados e CI versionado no repositorio

**Evidencia**

- Nao ha arquivos de teste no checkout.
- `.github/` contem somente `FUNDING.yml`; nao ha workflow de validacao versionado.
- Os scripts concentram deteccao de caminho, download, elevacao, instalacao, reparo e restauracao sem cobertura automatica.

**Melhoria**

Adicionar testes Pester e um workflow Windows para Windows PowerShell 5.1 e PowerShell 7. O gate deve executar parser, PSScriptAnalyzer, testes de hashes, testes com downloads mockados e testes da matriz de estados do menu.

**Criterio de aceite**

- Pull request falha em erro de parser, regra critica do analisador, hash divergente ou teste falho.
- Casos de 404, HTML no lugar de script, arquivo truncado, core incompativel e install/restore parcial possuem testes.
- O workflow publica resultados de teste e cobertura.

Referencias: [PSScriptAnalyzer](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/overview?view=ps-modules), [Pester](https://pester.dev/docs/quick-start/).

### 6. Impor encoding UTF-8 sem BOM e validar no build

**Evidencia**

- A issue [#25](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/issues/25) relata caracteres corrompidos e erros de parser em um `install.ps1` extraido do EXE.
- O checkout atual esta em UTF-8 valido e sem BOM, mas nao existe teste de bytes nem CI que preserve isso.
- `i.ps1` e `e.ps1` contem traducoes multibyte e sao sensiveis a regressao de encoding.

**Melhoria**

Adicionar `.editorconfig`, teste de UTF-8 sem BOM, parser em Windows PowerShell 5.1 e PowerShell 7, e geracao deterministica dos assets antes de empacotar o EXE.

**Criterio de aceite**

- Todo `.ps1` falha no gate se nao for UTF-8 valido e sem BOM.
- O artefato extraido do EXE passa no parser nos dois runtimes.
- Uma reproducao do erro da issue #25 entra como teste de regressao.

### 7. Tornar o build reproduzivel e falhar cedo para dependencias ausentes

**Evidencia**

- `build/build.sh:12-17` baixa DLLs do "latest" release sem pin de versao e continua apos erro.
- O release atual fornece `OnlineFix.zip`, enquanto o build procura DLLs individuais.
- O script usa um cache em `dist/` e nao valida hashes dos arquivos embutidos antes do `mcs`.

**Melhoria**

Trocar "latest" por versao travada em lockfile, baixar e extrair o ZIP de forma deterministica, validar todos os arquivos obrigatorios e seus hashes e abortar antes da compilacao quando qualquer requisito faltar.

**Criterio de aceite**

- Um build limpo usa somente versoes e hashes declarados.
- Arquivo faltante ou hash invalido encerra com erro direto antes de gerar EXE.
- Duas execucoes limpas da mesma revisao produzem inventario e hashes iguais.

### 8. Corrigir o gerador de hashes e validar o manifesto no gate

**Evidencia**

- `scripts/update-hashes.ps1:28-35` tenta atualizar `$Script:PayloadSha256` em `install.ps1`.
- A variavel nao existe no `install.ps1` atual, portanto a parte declarada pelo script nao tem efeito.
- O manifesto e editado facilmente fora de uma pipeline e nao ha teste que compare todos os arquivos listados.

**Melhoria**

Refatorar o gerador para emitir apenas dados que sao consumidos, checar entradas extras e ausentes, gerar o manifesto a partir do diretorio de release e validar com `sha256sum -c` ou equivalente PowerShell.

**Criterio de aceite**

- O comando de geracao e idempotente.
- O gate falha para hash, nome, encoding ou inventario divergente.
- O manifesto do release descreve exatamente os assets anexados.

### 9. Unificar os bootstraps duplicados

**Evidencia**

- `i.ps1` e `e.ps1` possuem o mesmo hash em `SHA256SUMS.txt`.
- Ambos repetem o mesmo fluxo de idioma, download, validacao e `iex`.

**Melhoria**

Manter uma fonte unica e gerar os dois nomes de bootstrap no build, ou remover o alias que nao tenha funcao de produto. O gerador deve validar que os artefatos publicados correspondem ao template.

**Criterio de aceite**

- Uma alteracao no fluxo acontece em um unico arquivo-fonte.
- O build reproduz ambos os assets e compara seus hashes esperados.
- A documentacao explica qual comando usa cada bootstrap.

## Prioridade P2

### 10. Fazer o menu e o core terem uma unica fonte de verdade

**Evidencia**

- O menu dinamico efetivo fica em `unlocker.ps1:440-462`.
- `runtime/unlocker-core.ps1:1794-1808` ainda mantem outro menu estatico com opcoes diferentes.
- O bootstrap substitui o loop do core, deixando comportamento diferente conforme a forma de execucao.

**Melhoria**

Consolidar o menu no core e usar o mesmo modelo de estado para console, bootstrap e testes. O menu deve receber capacidades detectadas e apresentar somente acoes realmente disponiveis.

**Criterio de aceite**

- Nao existem dois menus com conjuntos diferentes de opcoes.
- A mesma entrada e o mesmo estado produzem a mesma acao em todos os entrypoints.
- Cada opcao possui teste de install, partial, restore, invalid e exit.

### 11. Criar modo nao interativo e codigos de saida estaveis

**Evidencia**

- O fluxo e orientado por `Read-Host` em varios pontos do core e do bootstrap.
- O projeto ja recebe `ResourceDir` e `MinecraftPath`, mas nao expoe contrato completo para install, restore, diagnose ou validacao automatizada.

**Melhoria**

Adicionar parametros `-Action`, `-NonInteractive`, `-Json` e codigos de saida documentados. Manter o menu atual como camada interativa sobre as mesmas funcoes.

**Criterio de aceite**

- Suporte e CI conseguem executar diagnose, install dry-run, restore dry-run e validacao sem prompt.
- Cada falha tem codigo de saida e mensagem estruturada.
- O modo interativo continua com a experiencia atual.

### 12. Melhorar diagnostico, suporte e compatibilidade documentada

**Evidencia**

- A issue [#26](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/issues/26) relata falha com `.mcpack` e redirecionamento inesperado.
- A issue #27 mostra que a mensagem de download nao distingue URL antiga, asset ausente, 404 e indisponibilidade geral.
- A documentacao informa suporte a Xbox App/GDK e bloqueia UWP, mas nao ha matriz versionada de Windows, Minecraft, Xbox App e Game Services.

**Melhoria**

Adicionar `diagnose` com relatorio redigido para suporte, mensagens especificas por causa, issue templates com dados minimos e matriz de compatibilidade publicada. Para URL legada, detectar o padrao conhecido e exibir o comando canonico atual.

**Criterio de aceite**

- Um usuario consegue anexar um relatorio sem dados sensiveis.
- O suporte recebe versao do bootstrap, core, origem do download, versao do jogo e resultado das verificacoes.
- A matriz indica combinacoes verificadas, nao verificadas e sem suporte.

## Ordem recomendada

1. Integridade de download e contrato de assets.
2. Tag/versao, hashes e release reproduzivel.
3. Testes, CI e encoding.
4. Remocao de reescrita dinamica e consolidacao do menu.
5. Modo nao interativo, diagnostico e suporte.
