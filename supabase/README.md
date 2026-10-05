# Supabase

## Configuração

1. Crie um projeto no [Supabase](https://supabase.com/dashboard).
2. Copie a **Project URL** e a chave pública **publishable** (ou a chave
   **anon** legada). Nunca coloque `secret` ou `service_role` no app.
3. Em **Authentication → Providers → Email**, habilite e-mail/senha e mantenha
   a confirmação de e-mail.
4. Em **Authentication → URL Configuration**, cadastre:
   - `br.com.mocochovisk.app://login-callback` para Android/iOS;
   - `http://localhost:3000/` para desenvolvimento web;
   - a URL HTTPS exata do aplicativo publicado.
5. Preserve `{{ .ConfirmationURL }}` nos templates de confirmação e recuperação
   e configure SMTP para envio de e-mails a usuários reais.

Os arquivos `config/*.example.json` mostram como passar URL e chave ao app.
O SDK gerencia PKCE, persistência da sessão e atualização de tokens. Abra os
links de confirmação e recuperação no mesmo dispositivo ou perfil de navegador
que iniciou a operação.

## Aplicar a migration inicial

O schema financeiro está em `supabase/migrations/001_init.sql`. Para executar
em um projeto Supabase novo:

1. Abra o projeto no dashboard e acesse **SQL Editor**.
2. Cole o conteúdo completo de `supabase/migrations/001_init.sql`.
3. Execute e confira se a consulta termina sem erros.

A migration cria as tabelas, constraints de tenant, policies RLS, triggers,
views, funções, categorias padrão e configurações. Categorias/configurações são
inicializadas automaticamente para usuários já existentes e em novos cadastros.
Os registros de cotação são históricos: o app pode consultar e adicionar
cotações, mas não alterá-las ou apagá-las.

`target_margin`, `alert_price_increase_pct` e `product_recipe_items.loss_rate`
são frações no banco: por exemplo, `0.30` representa 30%. O custo por unidade
base usa R$/g, R$/ml ou R$/un; `markup` é o fator `preço de venda ÷ custo`.

O arquivo é uma migration inicial, não um mecanismo de atualização de um schema
que já tenha sido parcialmente criado por uma versão anterior. Se uma execução
anterior falhou ou se a migration já foi aplicada, não a execute novamente em
produção sem verificar o estado do banco e preparar uma migration de reparo.
Não use `supabase db reset` em um projeto com dados a preservar.

## CLI (opcional)

Para novos ambientes locais que usam Supabase CLI:

```bash
supabase login
supabase init
supabase link --project-ref SEU_PROJECT_REF
supabase db push
```

Execute `supabase init` apenas se `supabase/config.toml` ainda não existir.
Preserve os arquivos já presentes em `supabase/`. O Project Ref fica nas
configurações do projeto no dashboard. Use a CLI ou o SQL Editor para aplicar a
migration inicial; não misture os métodos sem conferir o histórico de migrations.

## Premissas e limites atuais

- Cada conta é um tenant independente; usuários e funcionários não compartilham
  dados nem têm papéis diferenciados.
- Entradas/saídas e saldo do dashboard somam lançamentos pagos; contas a pagar
  pendentes são informadas separadamente.
- Recorrências são modelos; geração automática de lançamentos e lembretes fica
  para a etapa da aplicação que implementa essa função.
- A unidade base do ingrediente é `g`, `ml` ou `un`. Embalagens aceitam `g`,
  `kg`, `ml`, `l` ou `un`, com conversão compatível feita no banco.
- A unidade base não pode mudar depois de haver cotações ou itens de receita.
- `transactions.attachment_url` guarda apenas a referência futura do comprovante.
  Bucket, policies do Storage e upload ainda não foram implementados.
- Offline, fila de sincronização, exportação e geração automática de recorrências
  ainda não estão implementados.

Referências: [Flutter + Supabase](https://supabase.com/docs/guides/getting-started/quickstarts/flutter),
[redirecionamentos](https://supabase.com/docs/guides/auth/redirect-urls),
[deep links](https://supabase.com/docs/guides/auth/native-mobile-deep-linking),
[SMTP](https://supabase.com/docs/guides/auth/auth-smtp).
