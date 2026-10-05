<<<<<<< Updated upstream
   # Supabase — etapa 2

   Esta etapa entrega a infraestrutura inicial do backend financeiro do app,
   incluindo tabela do modelo de negócio, RLS, triggers, views, funções de
   cálculo e seed auxiliar para categorias e configurações padrão.

   A migration principal está em `supabase/migrations/001_init.sql` e foi pensada
   para ser aplicada em um projeto Supabase novo ou vazio.
=======
# Supabase

## Configuração
>>>>>>> Stashed changes

   ## O que a migration cria

   - Tabelas de fornecedores, ingredientes, cotações históricas, produtos,
     itens da receita, categorias de transação, lançamentos, recorrências e
     configurações do app.
   - `owner_id uuid references auth.users` em todas as tabelas para isolamento por
     usuário e multi-tenant.
   - Trigger de `updated_at` e cálculo do preço por unidade base em
     `ingredient_prices`.
   - Índices para consultas de extrato, filtros e dashboards.
   - Policies RLS explícitas para `select`, `insert`, `update` e `delete`.
   - Views e funções para preço atual, custo de ingrediente, margem de produto,
     resumo do dashboard e ranking por fornecedor.
   - Funções `seed_default_categories` e `ensure_app_settings` para facilitar a
     entrada inicial do usuário.

   ## Aplicar a migration

   No painel do Supabase:

   1. Abra o projeto.
   2. Acesse `SQL Editor`.
   3. Execute o conteúdo de `supabase/migrations/001_init.sql`.
   4. Se quiser popular categorias e configurações para um usuário específico,
      execute:

   ```sql
   select public.seed_default_categories(auth.uid());
   select * from public.app_settings where owner_id = auth.uid();
   ```

   ## Configuração de autenticação

   Para o app continuar funcionando com login e sessão persistente, siga também as
   instruções abaixo:

   1. Crie um projeto no [Supabase](https://supabase.com/dashboard).
   2. Copie a **Project URL** e a chave **publishable** (ou **anon** legada).
   3. Em **Authentication → Providers → Email**, habilite e-mail/senha e confirmação
   de e-mail. A senha mínima do app é 8 caracteres; alinhe esse mínimo no painel.
   4. Em **Authentication → URL Configuration**, cadastre os retornos:
      - `br.com.mocochovisk.app://login-callback` para Android/iOS;
      - `http://localhost:3000/` para o teste web local;
      - a URL HTTPS exata do app ao hospedar a versão web.
   5. Use uma Site URL web válida no projeto. Confira se os templates de e-mail
      mantêm o link `{{ .ConfirmationURL }}`. Templates personalizados que descartam
      `redirect_to` impedem o retorno ao app.
   6. Configure SMTP para enviar confirmações/recuperações aos usuários reais.

<<<<<<< Updated upstream
   Os arquivos `config/*.example.json` documentam as variáveis. Não use chaves
   `secret` ou `service_role`: o aplicativo rejeita essas chaves. A autorização dos
   dados financeiros é feita por RLS, com `owner_id = auth.uid()`.

   Referências: [Flutter + Supabase](https://supabase.com/docs/guides/getting-started/quickstarts/flutter),
   [redirecionamentos](https://supabase.com/docs/guides/auth/redirect-urls),
   [deep links](https://supabase.com/docs/guides/auth/native-mobile-deep-linking),
   [SMTP](https://supabase.com/docs/guides/auth/auth-smtp).
=======
Os arquivos `config/*.example.json` documentam as variáveis. Não use chaves
`secret` ou `service_role`: o aplicativo rejeita essas chaves. Os dados
financeiros são isolados por RLS com `owner_id = auth.uid()`.

O SDK gerencia PKCE, persistência da sessão e atualização dos tokens. Para
confirmar cadastro ou recuperar senha, abra o e-mail no mesmo dispositivo e,
na web, no mesmo perfil de navegador que iniciou a operação. Os callbacks
mobile já estão registrados no AndroidManifest e Info.plist; o handler padrão
de deep links do Flutter está desativado para evitar competir com Supabase.

## Aplicar a migration

A migration inicial está em `supabase/migrations/001_init.sql`. Para um projeto
Supabase já criado, a forma mais direta é abrir **SQL Editor** no dashboard,
colar o conteúdo do arquivo e executar. O script é idempotente.

Para aplicar migrations pela CLI em um ambiente de desenvolvimento:

```bash
supabase login
supabase init
supabase link --project-ref SEU_PROJECT_REF
supabase db push
```

Execute `supabase init` somente se ainda não houver `supabase/config.toml` e
preserve os arquivos existentes em `supabase/`. Encontre o Project Ref nas
configurações do projeto no dashboard. A CLI e o SQL Editor são caminhos
alternativos; escolha um deles para aplicar esta migration.

Se executar primeiro pelo SQL Editor e depois usar a CLI, `db push` poderá
executar novamente o script idempotente para registrar a migration no histórico
da CLI. Não execute `supabase db reset` em um projeto com dados que deseja
preservar.

### O que a migration cria

- Fornecedores, ingredientes, histórico imutável de preços, produtos e receitas,
  categorias, lançamentos, recorrências e configurações individuais.
- Policies explícitas de `SELECT`, `INSERT`, `UPDATE` e `DELETE` em todas as
  tabelas. Cotações de ingredientes permitem leitura e inclusão, mas não edição
  ou exclusão; correções devem ser registradas como novas cotações.
- Categorias padrão e configurações iniciais para usuários novos e existentes.
- Conversão de `kg` para `g` e de `l` para `ml`, custo por ingrediente,
  custo/margem/markup/preço sugerido por produto e consultas para resumo
  financeiro, despesas por categoria e gastos por fornecedor.

### Premissas desta etapa

- Cada conta é um tenant independente; não há compartilhamento de dados ou
  permissões entre funcionários.
- O resumo considera apenas lançamentos pagos nas entradas e saídas; despesas
  pendentes são mostradas separadamente.
- Recorrências são modelos com próxima data de vencimento. A geração automática
  de lançamentos ou lembretes ficará na etapa de interface.
- Uma recorrência já usada por um lançamento não pode ser apagada; desative-a
  para preservar o vínculo e o histórico.
- A unidade base do ingrediente não pode ser alterada depois do registro de
  cotações ou receitas, pois isso invalidaria os dados históricos.
- A tabela de lançamentos guarda o caminho do comprovante (`receipt_path`), mas
  bucket, políticas do Storage e envio dos arquivos ficam para a feature de
  lançamentos. Não envie comprovantes ao Storage ainda.

Referências: [Flutter + Supabase](https://supabase.com/docs/guides/getting-started/quickstarts/flutter),
[redirecionamentos](https://supabase.com/docs/guides/auth/redirect-urls),
[deep links](https://supabase.com/docs/guides/auth/native-mobile-deep-linking),
[SMTP](https://supabase.com/docs/guides/auth/auth-smtp).
>>>>>>> Stashed changes
