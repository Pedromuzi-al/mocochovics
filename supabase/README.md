   # Supabase — etapa 2

   Esta etapa entrega a infraestrutura inicial do backend financeiro do app,
   incluindo tabela do modelo de negócio, RLS, triggers, views, funções de
   cálculo e seed auxiliar para categorias e configurações padrão.

   A migration principal está em `supabase/migrations/001_init.sql` e foi pensada
   para ser aplicada em um projeto Supabase novo ou vazio.

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

   Os arquivos `config/*.example.json` documentam as variáveis. Não use chaves
   `secret` ou `service_role`: o aplicativo rejeita essas chaves. A autorização dos
   dados financeiros é feita por RLS, com `owner_id = auth.uid()`.

   Referências: [Flutter + Supabase](https://supabase.com/docs/guides/getting-started/quickstarts/flutter),
   [redirecionamentos](https://supabase.com/docs/guides/auth/redirect-urls),
   [deep links](https://supabase.com/docs/guides/auth/native-mobile-deep-linking),
   [SMTP](https://supabase.com/docs/guides/auth/auth-smtp).
