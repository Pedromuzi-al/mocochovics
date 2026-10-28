# Bar do Mocochovisk 2.0

Modernização do aplicativo existente com Flutter 3.47.5 e Dart 3.13.4.
As regras financeiras, os repositórios, o Auth, o Storage e as migrations foram
preservados. Não é necessário executar uma migration para esta atualização.

## Aparência

Em **Mais → Aplicativo → Aparência**, escolha **Sistema**, **Claro** ou **Escuro**.
A preferência é salva no dispositivo e também vale para a tela de login.
O ícone de aparência no cabeçalho do celular, na barra lateral e no login
oferece a mesma seleção. O modo Sistema acompanha mudanças do sistema operacional.

Os controles de **Reduzir movimento** e **Reduzir transparência** também são
persistidos. A redução de movimento do sistema tem prioridade sobre animações
do aplicativo. Alto contraste e navegação acessível usam materiais opacos.
Este SDK não expõe um sinal específico de redução de transparência em MediaQuery;
por isso há uma opção explícita no aplicativo, além desses sinais de acessibilidade.
Se o armazenamento do navegador estiver bloqueado, a seleção ainda é aplicada,
com uma mensagem caso não seja possível salvá-la.

## Etapas implementadas

| Etapa | Resultado |
| --- | --- |
| 1 — Materiais e motion | Tokens compartilhados; curva física amortecida com SpringSimulation; compressão de botões; materiais adaptativos com blur limitado a navegação e controles. |
| 2 — Navegação | Barra flutuante com cinco destinos, indicador móvel que se alonga durante a seleção, resposta do ícone e feedback tátil; compactação discreta na rolagem; ocultação com teclado; lateral recolhível no desktop. |
| 3 — Dashboard | Saldo em verde profundo, gradiente radial, tipografia tabular e valores animados; cards sólidos; gráficos e estados vazios preservados; acesso ao extrato a partir do saldo e dos indicadores. |
| 4 — Telas principais | Busca e filtros com materiais adaptativos; listas estáveis; agrupamento do extrato por data; seleção rápida de entradas/saídas; produto com identidade compartilhada por Hero; configurações de aparência em Mais. |
| 5 — Formulários | CupertinoSheetRoute com movimento nativo, controlador de rolagem integrado e adaptação ao teclado; fechamento explícito; confirmação para descartar alterações; proteção de anexos e operações em andamento; confirmação breve após salvar/excluir. |
| 6 — Validação | Testes de navegação, cálculos existentes, persistência, acessibilidade e proteção de formulários; capturas em celular, tablet, desktop e texto ampliado, nos dois temas. |

As abas mantêm seus próprios navigators, filtros e rolagem. A troca de abas tem
um fade curto e não recria as páginas. Detalhes preservam CupertinoPageRoute e o
gesto horizontal de voltar quando suportado. O Hero usa somente o nome do mesmo
produto na lista e no detalhe, e é desativado com redução de movimento.

As sheets usam a implementação Cupertino disponível no SDK, sem novas bibliotecas.
O arraste acompanha o gesto enquanto o formulário está intacto. Quando há dados
editados, um anexo alterado ou salvamento em andamento, o arraste fica bloqueado:
o botão fechar e o voltar do sistema passam pela confirmação de descarte.
O formulário só fecha por sucesso depois da conclusão da gravação.

Dados monetários permanecem em centavos/Decimal. A interpolação é exclusivamente
visual e a semântica informa imediatamente o valor final. As listas continuam
preguiçosas; exclusões usam fade breve; novas linhas recebem entrada discreta.
Falhas conhecidas aparecem mesmo durante as tentativas automáticas do Riverpod.
Após 20 segundos de carregamento inicial há uma ação explícita de recuperação.

## Materiais por plataforma

LiquidGlass utiliza BackdropFilter em áreas delimitadas e oferece alternativa
opaca. Conteúdo financeiro usa superfícies sólidas nos dois temas. A implementação
em Flutter Web/Android reproduz princípios de translucidez e profundidade; não
é uma integração com o compositor óptico nativo Liquid Glass da Apple.
Os controles, sheets e rotas utilizam Cupertino do Flutter.

## Reprodução da validação

Resultado da suíte: **124 testes aprovados**, análise estática sem problemas e
**200 capturas em 10 cenários**, com os relatórios de layout sem ocorrências.
O build web de produção também foi concluído com os arquivos do motor gráfico
servidos localmente, preservando a correção do carregamento inicial.
O navegador real abriu o login e alternou entre claro e escuro sem exceções de
JavaScript, mesmo com o download externo de CanvasKit bloqueado. As escolhas
foram gravadas no armazenamento local. Capturas: `build/live-login-light.png`
e `build/live-login-dark.png`.
Os testes novos cobrem restauração e persistência da aparência, seleção durante
restauração assíncrona, mudança de tema sem perder a aba, preservação da busca,
remoção de blur, descarte de formulários, anexos alterados e proteção durante
salvamento. A suíte financeira existente também foi executada.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/flutter.ps1 test --no-pub --dart-define=VISUAL_AUDIT=true --dart-define=CAPTURE_PREVIEWS=true
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/flutter.ps1 analyze --no-pub
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/flutter.ps1 build web --release --no-pub --no-web-resources-cdn --dart-define-from-file=config/supabase.web.json
```

O launcher serializa comandos. Encerre um `flutter run` ativo antes de usar o
mesmo launcher para testes ou builds.

As capturas estão em `build/visual-audit/`, separadas por tamanho e tema, com um
`report.json` por cenário. Incluem listas preenchidas e vazias, erros, gráficos,
formulários e a seção de aparência. Esses dados são fixtures exclusivas dos testes;
o aplicativo não recebeu registros fictícios nem alterações remotas no banco.

Esta validação cobre Flutter Web e dimensões móveis simuladas em widget tests.
Fluidez em hardware físico, efeitos táteis e o gesto de borda no iOS ainda precisam
ser conferidos em dispositivos reais. Não há medição de FPS nativo nesta entrega.

Referências das APIs: [CupertinoSheetRoute](https://api.flutter.dev/flutter/cupertino/CupertinoSheetRoute-class.html),
[MediaQueryData](https://api.flutter.dev/flutter/widgets/MediaQueryData-class.html).
