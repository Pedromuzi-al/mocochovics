# Supabase — etapa 1

Nesta etapa o aplicativo usa somente **Supabase Auth**. Não há tabelas financeiras,
seed, migration, chamadas administrativas ou banco local com dados fictícios.
A migration `migrations/001_init.sql`, as policies RLS e o seed serão entregues
na etapa 2, depois da validação da etapa 1, conforme a sequência solicitada.

## Configuração necessária agora

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
   O serviço de e-mail de teste do Supabase tem restrições de destinatários e taxa.

Os arquivos `config/*.example.json` documentam as variáveis. Não use chaves
`secret` ou `service_role`: o aplicativo rejeita essas chaves. Autorização dos
dados financeiros será feita por RLS, com `owner_id = auth.uid()` na etapa 2.

O SDK gerencia PKCE, persistência da sessão e atualização dos tokens. Para
confirmar cadastro ou recuperar senha, abra o e-mail no mesmo dispositivo e,
na web, no mesmo perfil de navegador que iniciou a operação. Os callbacks
mobile já estão registrados no AndroidManifest e Info.plist; o handler padrão
de deep links do Flutter está desativado para evitar competir com Supabase.

Referências: [Flutter + Supabase](https://supabase.com/docs/guides/getting-started/quickstarts/flutter),
[redirecionamentos](https://supabase.com/docs/guides/auth/redirect-urls),
[deep links](https://supabase.com/docs/guides/auth/native-mobile-deep-linking),
[SMTP](https://supabase.com/docs/guides/auth/auth-smtp).
