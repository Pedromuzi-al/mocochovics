# Supabase — etapas 1 a 6

## Aplicação

Crie um projeto Supabase e execute todo o conteúdo de
`migrations/001_init.sql` e depois `migrations/002_product_history.sql` no SQL Editor
com a função administrativa do painel. Os arquivos usam transações e podem ser
reaplicados sem duplicar estruturas. Em projetos que já possuem a etapa 4,
aplique somente a migration 002.

Essa migration é a inicial de um projeto novo; alterações futuras de schema
devem receber novas migrations incrementais.

Configure Email/SMTP e as Redirect URLs conforme o README principal. Use apenas
a chave pública no aplicativo. Não há projeto remoto ou credenciais incluídos.

## Estrutura

- `suppliers`, `ingredients`, `ingredient_prices`.
- `transactions`, `transaction_categories`, `recurring_transactions`.
- `products`, `product_recipe_items`, `app_settings`.
- `product_cost_history` (observações de custos desde a migration 002).

Todas as tabelas têm UUID, dono, timestamps e RLS. As nove tabelas operacionais
têm policies para cada operação; o histórico de produtos permite somente leitura
ao dono e não concede inserção, alteração ou exclusão ao cliente.
Chaves estrangeiras compostas impedem referências a cadastros de outros donos.
O histórico de preços bloqueia edição/exclusão por trigger; para corrigir um
preço, insira um registro com a nova cotação.

Valores são numeric(12,2); quantidades, preços por unidade e frações são
numeric(14,6). Perdas e margens usam frações: 0.30 significa 30%.
A unidade base de um ingrediente em uso não pode ser alterada.

## Funções e views

- `ensure_defaults()`: cria configurações e onze categorias padrão na primeira
  preparação de cada conta. Não recria categorias apagadas em acessos posteriores.
- `current_supplier_prices`: preço mais recente por ingrediente/fornecedor,
  ordenado por data informada, criação e UUID.
- `ingredient_costs`: último preço pago, média ponderada das últimas N compras
  (padrão cinco), ou menor cotação atual entre fornecedores ativos.
- `product_costs`: custo com perdas, lucro, margem percentual, markup,
  sugestão de preço e margem baixa. Receita sem preços fica com custo nulo,
  nunca assume custo zero para ingredientes sem preço.
- `dashboard_summary(start_date,end_date)`, `expenses_by_category(...)`,
  `supplier_ranking(...)`: resumos por período, usando movimentos pagos.
- `save_transaction(entry,quote)`: grava lançamento e compra opcional juntos.
- `generate_recurring()`: gera pendências até a data corrente e avança o
  vencimento. Bloqueios de linha e chave única evitam geração concorrente duplicada.

As views usam security_invoker e as RPCs usam o contexto do usuário, respeitando
a RLS. A função de trigger `record_product_costs` usa security definer apenas
para gravar o histórico protegido: tem search_path vazio, filtra pelo dono da
linha que disparou o evento e não concede execução direta aos clientes.

## Histórico dos produtos

A migration 002 registra custo, preço de venda, margem-alvo e método de cálculo
quando essas informações mudam por produto, receita, preços, fornecedor ativo
ou configurações. Mudanças sem efeito financeiro não duplicam observações.
Um bloqueio por dono serializa a geração; a coluna revision determina a ordem.

Produtos existentes recebem uma observação inicial na data da aplicação. Não
há reconstrução artificial de custos anteriores. O histórico é de observação:
uma compra retroativa só altera o histórico do produto na data em que é inserida.
Os gráficos usam a última observação por dia e podem trazer uma observação
anterior como referência no início do período. Custos desconhecidos geram lacunas.
Excluir um produto remove sua receita e seu histórico de custos.

As configurações ficam em Mais → Custos e alertas e se aplicam a todos os
produtos. Perda, margem e limite de alerta entram na interface em porcentagem;
o banco armazena frações com seis casas. A entrada percentual aceita até quatro
casas, evitando arredondamentos silenciosos.

## Dashboard

O app agrega as linhas protegidas por RLS usando centavos/Decimal no domínio;
as views e RPCs continuam disponíveis para consultas no banco. Consultas são
paginadas em lotes de 500 para não truncar resultados no limite padrão da API.
Atualizações no app invalidam a leitura compartilhada; alterações de outros
dispositivos aparecem ao atualizar a lista. Não há assinatura Realtime nesta etapa.

Caixa, categorias e fornecedores consideram pagamentos no período escolhido.
Contas a pagar são somente saídas pendentes. Margens e seu ranking são atuais,
independentemente do período. Alertas de ingredientes comparam a última cotação
no período com a anterior por fornecedor ativo; o aumento deve superar o limite.

## Regras operacionais

Cotações (`quote`) participam da comparação de fornecedores; somente compras
(`purchase`) participam de último preço pago e média ponderada.
A média é soma dos valores pagos dividida pela soma das quantidades base.

Registrar uma compra diretamente no ingrediente não cria lançamento financeiro.
Para registrar os dois, utilize Novo lançamento → Saída paga → Fornecedor →
Registrar compra de ingrediente. A quantidade informada é o total adquirido;
uma caixa de doze unidades deve ser registrada como 12 un.

Na saída, o valor da compra de ingrediente pode ser menor que o total do
lançamento, mas não maior. O fluxo atual vincula um ingrediente por lançamento;
compras com vários ingredientes podem ter seus demais preços registrados
individualmente no histórico.

Editar ou excluir uma saída não reescreve o histórico de compras. A exclusão
remove o vínculo com a saída, preservando a cotação. A interface explica essa
separação ao editar uma saída com compra vinculada.

O saldo do extrato é a soma de entradas pagas menos saídas pagas do filtro.
Pendências aparecem separadas. O acumulado inicia em zero para os registros
selecionados, sem representar saldo bancário anterior ao filtro.

Recorrências seguem a data do bar em America/Sao_Paulo, são mensais (intervalo de 1 a 120 meses) e geradas ao carregar ou
atualizar os dados. Dia 31 usa o último dia de meses menores e volta ao dia 31
quando disponível. Pausar mantém o histórico; excluir uma regra com lançamentos
vinculados é bloqueado. Não há cron configurado para funcionar com o app fechado.

## Comprovantes

Bucket privado `receipts`, até 10 MB, tipos JPEG/PNG/PDF. O primeiro segmento
do objeto é o UUID do dono; policies protegem leitura, inserção, atualização e
exclusão. O app abre URLs assinadas com validade de sessenta segundos.
Substituir/remover um comprovante ou excluir seu lançamento tenta remover o
objeto antigo; interrupções de rede podem deixar objetos órfãos para limpeza
posterior. Nenhuma URL pública é persistida.

## Validação

`scripts/validate_sql.mjs` testa reaplicação, cálculos, constraints, isolamento
entre duas contas, policies de objetos, atomicidade e recorrências, usando
Postgres em WASM. Veja instalação/execução no README principal.

Valide também no projeto real: confirmação/recuperação de e-mail, upload e
download de comprovantes e consultas autenticadas com duas contas. O teste
local não executa os serviços Supabase Auth/Storage.
