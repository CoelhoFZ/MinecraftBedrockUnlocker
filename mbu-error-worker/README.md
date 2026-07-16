# MBU Error Report Worker

Cloudflare Worker que recebe relatórios de erro mínimos do bootstrap `i.ps1` e
os encaminha para um webhook do Discord.

## Dados enviados

O envio é opcional e ocorre somente depois da confirmação do usuário. O cliente
manda apenas:

```json
{
  "v": "3.3.3",
  "os": "Microsoft Windows 10.0.22631",
  "lang": "pt",
  "smartScreen": true,
  "err": "mensagem sanitizada, sem caminhos locais"
}
```

Não são enviados nome da máquina, usuário, endereço IP, timestamp, caminhos de
arquivo ou a URL do webhook. O Worker valida o schema, limita o corpo a 16 KB e
sanitiza novamente as strings antes do encaminhamento.

## Deploy

1. Instale o Wrangler e autentique-se:

   ```bash
   npm i -g wrangler
   wrangler login
   ```

2. Cadastre o webhook exclusivamente como secret do Worker:

   ```bash
   wrangler secret put DISCORD_WEBHOOK_URL
   ```

3. Publique o Worker:

   ```bash
   wrangler deploy
   ```

4. Copie apenas a URL pública terminada em `/report` para
   `$Script:ReportEndpoint` em `i.ps1`. Nunca adicione o webhook do Discord ao
   repositório ou ao script.

## Proteção contra abuso

O endpoint é público porque o bootstrap é distribuído ao usuário final e não
contém segredo reutilizável. Antes de disponibilizá-lo, configure uma regra de
**Rate Limiting** no Cloudflare para `POST /report`. O Worker também limita
método, tamanho e campos; falhas ao encaminhar ao Discord não são expostas ao
cliente.
