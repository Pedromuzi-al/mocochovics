begin;

create extension if not exists pgcrypto;

create table if not exists public.suppliers (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users on delete cascade,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  name text not null check (length(trim(name)) > 0), document text, phone text, email text,
  address text, payment_term_days integer not null default 0 check (payment_term_days >= 0),
  notes text, active boolean not null default true, unique (id, owner_id)
);
create table if not exists public.ingredients (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users on delete cascade,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  name text not null check (length(trim(name)) > 0),
  category text not null check (category in ('bebida','carne','hortifruti','laticinio','descartavel','outros')),
  base_unit text not null check (base_unit in ('g','ml','un')), unique (id, owner_id)
);
create table if not exists public.transaction_categories (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users on delete cascade,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  name text not null check (length(trim(name)) > 0), type text not null check (type in ('entrada','saida')),
  unique(owner_id, type, name), unique (id, owner_id, type)
);
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users on delete cascade,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  name text not null check (length(trim(name)) > 0), category text not null default 'outros',
  sale_price numeric(12,2) not null check (sale_price > 0), unique (id, owner_id)
);
create table if not exists public.app_settings (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users on delete cascade unique,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  target_margin numeric(14,6) not null default 0.30 check (target_margin >= 0 and target_margin < 1),
  cost_method text not null default 'weighted_average' check (cost_method in ('last_paid','weighted_average','lowest_active')),
  purchase_count integer not null default 5 check (purchase_count between 1 and 1000),
  price_alert_threshold numeric(14,6) not null default 0.10 check (price_alert_threshold >= 0)
);
create table if not exists public.product_recipe_items (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users on delete cascade,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  product_id uuid not null, ingredient_id uuid not null,
  quantity numeric(14,6) not null check (quantity > 0), loss numeric(14,6) not null default 0 check (loss >= 0),
  foreign key(product_id, owner_id) references public.products(id, owner_id) on delete cascade,
  foreign key(ingredient_id, owner_id) references public.ingredients(id, owner_id),
  unique(product_id, ingredient_id)
);
create table if not exists public.recurring_transactions (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users on delete cascade,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  type text not null check(type in ('entrada','saida')), amount numeric(12,2) not null check(amount > 0),
  category_id uuid not null, supplier_id uuid,
  payment_method text not null check(payment_method in ('dinheiro','pix','debito','credito','outro')),
  description text not null default '', next_date date not null,
  interval_months integer not null default 1 check(interval_months between 1 and 120),
  anchor_day integer not null check(anchor_day between 1 and 31), active boolean not null default true,
  check (type = 'saida' or supplier_id is null),
  foreign key(category_id, owner_id, type) references public.transaction_categories(id, owner_id, type),
  foreign key(supplier_id, owner_id) references public.suppliers(id, owner_id), unique(id, owner_id)
);
create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users on delete cascade,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  type text not null check(type in ('entrada','saida')), amount numeric(12,2) not null check(amount > 0),
  date date not null, category_id uuid not null, supplier_id uuid,
  payment_method text not null check(payment_method in ('dinheiro','pix','debito','credito','outro')),
  description text not null default '', status text not null default 'pago' check(status in ('pago','pendente')),
  receipt_path text, recurring_id uuid,
  foreign key(category_id, owner_id, type) references public.transaction_categories(id, owner_id, type),
  foreign key(supplier_id, owner_id) references public.suppliers(id, owner_id),
  foreign key(recurring_id, owner_id) references public.recurring_transactions(id, owner_id),
  check (type = 'saida' or supplier_id is null), unique(recurring_id, date), unique(id, owner_id)
);
create table if not exists public.ingredient_prices (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users on delete cascade,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  ingredient_id uuid not null, supplier_id uuid not null,
  package_size numeric(14,6) not null check(package_size > 0),
  package_unit text not null check(package_unit in ('g','kg','ml','l','un')),
  price numeric(12,2) not null check(price > 0),
  base_quantity numeric(14,6) not null check(base_quantity > 0),
  unit_price numeric(14,6) not null check(unit_price > 0), date date not null,
  kind text not null default 'quote' check(kind in ('quote','purchase')), transaction_id uuid,
  foreign key(ingredient_id, owner_id) references public.ingredients(id, owner_id),
  foreign key(supplier_id, owner_id) references public.suppliers(id, owner_id),
  foreign key(transaction_id, owner_id) references public.transactions(id, owner_id) on delete set null (transaction_id)
);

create index if not exists transactions_owner_date_idx on public.transactions(owner_id, date desc);
create index if not exists transactions_owner_type_idx on public.transactions(owner_id, type, date);
create index if not exists transactions_owner_category_idx on public.transactions(owner_id, category_id, date);
create index if not exists transactions_owner_supplier_idx on public.transactions(owner_id, supplier_id, date);
create index if not exists transactions_owner_status_idx on public.transactions(owner_id, status, date);
create index if not exists ingredient_prices_history_idx on public.ingredient_prices(owner_id, ingredient_id, supplier_id, date desc, created_at desc);
create index if not exists recurring_due_idx on public.recurring_transactions(owner_id, next_date) where active;
create index if not exists recipe_ingredient_idx on public.product_recipe_items(owner_id, ingredient_id);

create or replace function public.touch_updated_at() returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at := now(); return new; end $$;

do $$
declare table_name text;
begin
  foreach table_name in array array['suppliers','ingredients','ingredient_prices','products','product_recipe_items','transaction_categories','transactions','recurring_transactions','app_settings'] loop
    execute format('alter table public.%I enable row level security', table_name);
    execute format('drop policy if exists owner_select on public.%I', table_name);
    execute format('create policy owner_select on public.%I for select to authenticated using (owner_id = (select auth.uid()))', table_name);
    execute format('drop policy if exists owner_insert on public.%I', table_name);
    execute format('create policy owner_insert on public.%I for insert to authenticated with check (owner_id = (select auth.uid()))', table_name);
    execute format('drop policy if exists owner_update on public.%I', table_name);
    execute format('create policy owner_update on public.%I for update to authenticated using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()))', table_name);
    execute format('drop policy if exists owner_delete on public.%I', table_name);
    execute format('create policy owner_delete on public.%I for delete to authenticated using (owner_id = (select auth.uid()))', table_name);
    execute format('drop trigger if exists touch_updated_at on public.%I', table_name);
    execute format('create trigger touch_updated_at before update on public.%I for each row execute function public.touch_updated_at()', table_name);
    execute format('grant select, insert, update, delete on public.%I to authenticated', table_name);
    execute format('revoke all on public.%I from anon', table_name);
  end loop;
end $$;

create or replace function public.calculate_unit_price() returns trigger language plpgsql set search_path = '' as $$
declare ingredient_unit text;
begin
  select base_unit into ingredient_unit from public.ingredients where id = new.ingredient_id and owner_id = new.owner_id;
  if not ((ingredient_unit = 'g' and new.package_unit in ('g','kg')) or
          (ingredient_unit = 'ml' and new.package_unit in ('ml','l')) or
          (ingredient_unit = 'un' and new.package_unit = 'un')) then
    raise exception 'Unidade incompatível com o ingrediente';
  end if;
  new.base_quantity := new.package_size * case when new.package_unit in ('kg','l') then 1000 else 1 end;
  new.unit_price := round(new.price / new.base_quantity, 6);
  return new;
end $$;
drop trigger if exists calculate_unit_price on public.ingredient_prices;
create trigger calculate_unit_price before insert or update on public.ingredient_prices for each row execute function public.calculate_unit_price();

create or replace function public.guard_price_history() returns trigger language plpgsql set search_path = '' as $$
begin
  if tg_op = 'DELETE' then raise exception 'O histórico de preços não pode ser excluído'; end if;
  if (to_jsonb(new) - 'updated_at' - 'transaction_id') is distinct from (to_jsonb(old) - 'updated_at' - 'transaction_id') then
    raise exception 'Insira uma nova cotação para preservar o histórico';
  end if;
  if new.transaction_id is not null then raise exception 'O vínculo de uma compra não pode ser alterado'; end if;
  return new;
end $$;
drop trigger if exists guard_price_history on public.ingredient_prices;
create trigger guard_price_history before update or delete on public.ingredient_prices for each row execute function public.guard_price_history();

create or replace function public.guard_ingredient_unit() returns trigger language plpgsql set search_path = '' as $$
begin
  if new.base_unit <> old.base_unit and (exists(select 1 from public.ingredient_prices where ingredient_id = old.id) or exists(select 1 from public.product_recipe_items where ingredient_id = old.id)) then
    raise exception 'A unidade base não pode mudar após ser utilizada';
  end if;
  return new;
end $$;
drop trigger if exists guard_ingredient_unit on public.ingredients;
create trigger guard_ingredient_unit before update on public.ingredients for each row execute function public.guard_ingredient_unit();

create or replace function public.ensure_defaults() returns void language plpgsql security invoker set search_path = '' as $$
declare inserted integer;
begin
  if auth.uid() is null then raise exception 'Acesso não autorizado'; end if;
  insert into public.app_settings(owner_id) values(auth.uid()) on conflict(owner_id) do nothing;
  get diagnostics inserted = row_count;
  if inserted = 0 then return; end if;
  insert into public.transaction_categories(owner_id, type, name)
  select auth.uid(), defaults.type, defaults.name from (values
    ('entrada','Vendas'),('entrada','Outras receitas'),('saida','Ingredientes/insumos'),
    ('saida','Salários'),('saida','Aluguel'),('saida','Energia'),('saida','Água'),
    ('saida','Internet'),('saida','Manutenção'),('saida','Impostos'),('saida','Outros')
  ) as defaults(type,name) on conflict(owner_id,type,name) do nothing;
end $$;

create or replace view public.current_supplier_prices with (security_invoker = true) as
select distinct on (owner_id, ingredient_id, supplier_id) * from public.ingredient_prices
order by owner_id, ingredient_id, supplier_id, date desc, created_at desc, id desc;

create or replace view public.ingredient_costs with (security_invoker = true) as
select ingredient.id, ingredient.owner_id, ingredient.name, ingredient.base_unit,
  case coalesce(settings.cost_method,'weighted_average')
    when 'last_paid' then (select price.unit_price from public.ingredient_prices price where price.ingredient_id = ingredient.id and price.kind = 'purchase' order by price.date desc, price.created_at desc, price.id desc limit 1)
    when 'lowest_active' then (select min(price.unit_price) from public.current_supplier_prices price join public.suppliers supplier on supplier.id = price.supplier_id where price.ingredient_id = ingredient.id and supplier.active)
    else (select round(sum(recent.price) / nullif(sum(recent.base_quantity),0),6) from
      (select price.price, price.base_quantity from public.ingredient_prices price where price.ingredient_id = ingredient.id and price.kind = 'purchase' order by price.date desc, price.created_at desc, price.id desc limit coalesce(settings.purchase_count,5)) recent)
  end as unit_cost
from public.ingredients ingredient left join public.app_settings settings on settings.owner_id = ingredient.owner_id;

create or replace view public.product_costs with (security_invoker = true) as
with costs as (
  select product.id, product.owner_id, product.name, product.sale_price,
    coalesce(settings.target_margin,0.30) target_margin,
    case when count(recipe.id) = 0 or count(*) filter(where recipe.id is not null and cost.unit_cost is null) > 0 then null
      else round(sum(recipe.quantity * (1 + recipe.loss) * cost.unit_cost),2) end as cost
  from public.products product left join public.app_settings settings on settings.owner_id = product.owner_id
  left join public.product_recipe_items recipe on recipe.product_id = product.id
  left join public.ingredient_costs cost on cost.id = recipe.ingredient_id
  group by product.id, settings.target_margin
)
select *, sale_price - cost profit, round((sale_price-cost)/sale_price * 100,2) margin_percent,
  round(sale_price/nullif(cost,0),6) markup, round(cost/(1-target_margin),2) suggested_price,
  (sale_price-cost)/sale_price < target_margin as low_margin from costs;

create or replace function public.dashboard_summary(start_date date, end_date date)
returns table(income numeric, expenses numeric, balance numeric, pending_payables numeric)
language sql stable security invoker set search_path = '' as $$
  select coalesce(sum(amount) filter(where type='entrada' and status='pago'),0),
    coalesce(sum(amount) filter(where type='saida' and status='pago'),0),
    coalesce(sum(case when type='entrada' then amount else -amount end) filter(where status='pago'),0),
    coalesce(sum(amount) filter(where type='saida' and status='pendente'),0)
  from public.transactions where date between start_date and end_date;
$$;
create or replace function public.expenses_by_category(start_date date, end_date date)
returns table(category_id uuid, name text, total numeric)
language sql stable security invoker set search_path = '' as $$
  select category.id, category.name, sum(entry.amount) from public.transactions entry
  join public.transaction_categories category on category.id=entry.category_id
  where entry.type='saida' and entry.status='pago' and entry.date between start_date and end_date
  group by category.id,category.name order by sum(entry.amount) desc;
$$;
create or replace function public.supplier_ranking(start_date date, end_date date)
returns table(supplier_id uuid, name text, total numeric)
language sql stable security invoker set search_path = '' as $$
  select supplier.id, supplier.name, sum(entry.amount) from public.transactions entry
  join public.suppliers supplier on supplier.id=entry.supplier_id
  where entry.type='saida' and entry.status='pago' and entry.date between start_date and end_date
  group by supplier.id,supplier.name order by sum(entry.amount) desc;
$$;

create or replace function public.save_transaction(entry jsonb, quote jsonb default null)
returns uuid language plpgsql security invoker set search_path = '' as $$
declare entry_id uuid := coalesce(nullif(entry->>'id','')::uuid, gen_random_uuid()); result_id uuid;
begin
  if auth.uid() is null then raise exception 'Acesso não autorizado'; end if;
  insert into public.transactions(id,owner_id,type,amount,date,category_id,supplier_id,payment_method,description,status,receipt_path)
  values(entry_id,auth.uid(),entry->>'type',(entry->>'amount')::numeric,(entry->>'date')::date,
    (entry->>'category_id')::uuid,nullif(entry->>'supplier_id','')::uuid,entry->>'payment_method',
    coalesce(entry->>'description',''),entry->>'status',nullif(entry->>'receipt_path',''))
  on conflict(id) do update set type=excluded.type,amount=excluded.amount,date=excluded.date,
    category_id=excluded.category_id,supplier_id=excluded.supplier_id,payment_method=excluded.payment_method,
    description=excluded.description,status=excluded.status,receipt_path=excluded.receipt_path
  returning id into result_id;
  if quote is not null then
    if (quote->>'price')::numeric > (entry->>'amount')::numeric then
      raise exception 'O valor do ingrediente não pode superar o lançamento';
    end if;
    if entry->>'type' <> 'saida' or entry->>'status' <> 'pago' or nullif(entry->>'supplier_id','') is null then
      raise exception 'Uma compra exige saída paga e fornecedor';
    end if;
    if exists(select 1 from public.ingredient_prices where transaction_id = result_id) then
      if exists(select 1 from public.ingredient_prices where transaction_id = result_id
        and ingredient_id = (quote->>'ingredient_id')::uuid and supplier_id = (entry->>'supplier_id')::uuid
        and package_size = (quote->>'package_size')::numeric and package_unit = quote->>'package_unit'
        and price = (quote->>'price')::numeric and date = (entry->>'date')::date) then
        return result_id;
      end if;
      raise exception 'Esta compra já tem cotação. Registre uma nova cotação no ingrediente';
    end if;
    insert into public.ingredient_prices(owner_id,ingredient_id,supplier_id,package_size,package_unit,price,date,kind,transaction_id)
    values(auth.uid(),(quote->>'ingredient_id')::uuid,(entry->>'supplier_id')::uuid,
      (quote->>'package_size')::numeric,quote->>'package_unit',(quote->>'price')::numeric,
      (entry->>'date')::date,'purchase',result_id);
  end if;
  return result_id;
end $$;

create or replace function public.generate_recurring() returns integer
language plpgsql security invoker set search_path = '' as $$
declare rule public.recurring_transactions; generated integer := 0; inserted integer; month_start date;
  today date := (now() at time zone 'America/Sao_Paulo')::date;
begin
  if auth.uid() is null then raise exception 'Acesso não autorizado'; end if;
  for rule in select * from public.recurring_transactions where active and owner_id=auth.uid() and next_date<=today for update loop
    while rule.next_date <= today loop
      insert into public.transactions(owner_id,type,amount,date,category_id,supplier_id,payment_method,description,status,recurring_id)
      values(rule.owner_id,rule.type,rule.amount,rule.next_date,rule.category_id,rule.supplier_id,rule.payment_method,rule.description,'pendente',rule.id)
      on conflict(recurring_id,date) do nothing;
      get diagnostics inserted = row_count;
      generated := generated + inserted;
      month_start := (date_trunc('month',rule.next_date) + make_interval(months=>rule.interval_months))::date;
      rule.next_date := month_start + (least(rule.anchor_day,extract(day from (month_start + interval '1 month - 1 day'))::integer)-1);
    end loop;
    update public.recurring_transactions set next_date=rule.next_date where id=rule.id;
  end loop;
  return generated;
end $$;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('receipts','receipts',false,10485760,array['image/jpeg','image/png','application/pdf'])
on conflict(id) do update set public=false,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists receipts_select on storage.objects;
create policy receipts_select on storage.objects for select to authenticated using(bucket_id='receipts' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists receipts_insert on storage.objects;
create policy receipts_insert on storage.objects for insert to authenticated with check(bucket_id='receipts' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists receipts_update on storage.objects;
create policy receipts_update on storage.objects for update to authenticated using(bucket_id='receipts' and (storage.foldername(name))[1]=(select auth.uid())::text) with check(bucket_id='receipts' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists receipts_delete on storage.objects;
create policy receipts_delete on storage.objects for delete to authenticated using(bucket_id='receipts' and (storage.foldername(name))[1]=(select auth.uid())::text);

revoke execute on function public.ensure_defaults(), public.save_transaction(jsonb,jsonb), public.generate_recurring(), public.dashboard_summary(date,date), public.expenses_by_category(date,date), public.supplier_ranking(date,date) from public, anon;
grant execute on function public.ensure_defaults(), public.save_transaction(jsonb,jsonb), public.generate_recurring(), public.dashboard_summary(date,date), public.expenses_by_category(date,date), public.supplier_ranking(date,date) to authenticated;
grant select on public.current_supplier_prices, public.ingredient_costs, public.product_costs to authenticated;
revoke all on public.current_supplier_prices, public.ingredient_costs, public.product_costs from anon;

commit;
