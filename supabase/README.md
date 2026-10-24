# Supabase — etapas 1 a 4

## Aplicação

Crie um projeto Supabase e execute todo o conteúdo de
`migrations/001_init.sql` no SQL Editor com a função administrativa do painel.
O arquivo usa uma transação e pode ser reaplicado ao mesmo schema sem duplicar
tabelas, índices, policies, triggers ou bucket.

Essa migration é a inicial de um projeto novo; alterações futuras de schema
devem receber novas migrations incrementais.

Configure Email/SMTP e as Redirect URLs conforme o README principal. Use apenas
a chave pública no aplicativo. Não há projeto remoto ou credenciais incluídos.

## Estrutura

- `suppliers`, `ingredients`, `ingredient_prices`.
- `transactions`, `transaction_categories`, `recurring_transactions`.
- `products`, `product_recipe_items`, `app_settings` (base da etapa 5).

Todas as tabelas têm UUID, dono, timestamps, RLS e policies para cada operação.
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

As views usam security_invoker e as funções de negócio usam o contexto do
usuário, respeitando a RLS. Não há função de negócio security definer.

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
