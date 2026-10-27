# Hover, cards e menu retrátil

Atualização de 27/10/2026, sobre o refinamento visual existente.

## Comportamento entregue

- No celular/tablet com menos de 1000 px, o botão de três linhas no canto superior esquerdo abre o menu pela esquerda. A navegação inferior foi substituída por esse menu, com as mesmas cinco áreas e a conta no rodapé.
- O menu fecha ao escolher uma área, tocar fora, tocar em Fechar menu, pressionar Escape/voltar ou deslizar para a esquerda. A navegação conserva as pilhas das áreas pelo GoRouter existente.
- No desktop, o botão de três linhas recolhe a barra para uma faixa de 80 px com ícones. O mesmo botão expande os rótulos novamente. Os ícones continuam acessíveis e acionáveis quando recolhidos.
- Botões, linhas com ação, campos, busca, filtros, seletores e ações de modais recebem hover e indicação de foco. Os controles continuam usando Cupertino para toque, semântica e estados desabilitados. Linhas com ação também aceitam Enter/espaço pelo teclado.
- Cards financeiros e painéis recebem destaque de borda/sombra e uma elevação de 2 px ao passar o mouse, sem mudar o espaço ocupado no layout. As animações de entrada e de valores do refinamento anterior continuam disponíveis; no toque, os botões conservam o feedback nativo de pressão.
- A redução de movimento elimina o deslocamento dos cards e a duração das transições. Os efeitos não executam ações nem habilitam controles desabilitados.

## Implementação

`lib/core/widgets/app_interaction.dart` centraliza `AppHover`, `AppButton` e
`AppListTile`. Os botões e linhas da aplicação usam essas primitivas, incluindo
formulários de autenticação e financeiros. A lógica de autenticação e de dados
permanece nos componentes anteriores.

`lib/core/widgets/app_navigation_menu.dart` fornece o mesmo conteúdo para a
barra lateral e o menu móvel. `lib/core/router/app_shell.dart` controla a
abertura modal, o foco, Escape, fechamento por gesto e recolhimento no desktop.
O menu modal mantém o foco no diálogo e o fundo bloqueado durante o uso.

`PremiumSurface`, o card de saldo e o resumo do extrato usam o efeito de card.
Não foi adicionada biblioteca de animação nem alterado o banco.

## Validação

Resultado final: **115 testes aprovados**, **190 capturas de widgets**, sem
exceções de layout coletadas, análise estática sem issues e build web release
compilado. No Chrome, o login renderizou nas seis combinações de resolução/tema,
sem exceções JavaScript capturadas. O teste adicional de expiração de sessão com
o menu aberto confirmou que o menu e o conteúdo protegido desaparecem ao voltar
ao login.


- Testes de navegação: cinco destinos, retorno, redimensionamento, menu recolhido, fechamento por barreira/Escape/voltar e fonte de 200% em tela estreita.
- Testes de interação: hover sem acionar o botão, um acionamento por toque/teclado, botões desabilitados, ativação de linhas por teclado e redução de movimento sem deslocar o layout do card.
- Capturas de widgets nos dois temas, em celular/tablet/desktop e fonte ampliada, incluindo menu aberto, barra recolhida e card com hover.
- Análise estática, formatação, suíte completa e build web release.

As capturas das áreas autenticadas usam exclusivamente fixtures de teste. A
verificação em Chrome cobre a inicialização real/login; CRUD remoto e aparelhos
físicos não foram revalidados nesta atualização.

## Pré-visualizações

- [Menu no celular](../build/visual-audit/mobile-dark/navigation-menu.png).
- [Desktop recolhido](../build/visual-audit/desktop-dark/navigation-collapsed.png).
- [Cards com hover](../build/visual-audit/desktop-dark/dashboard-hover.png).

A versão compilada fica em `build/web` e é servida localmente na porta 3000.
Para desenvolvimento, use os comandos Flutter do README.
