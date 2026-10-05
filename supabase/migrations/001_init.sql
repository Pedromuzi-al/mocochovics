create extension if not exists pgcrypto with schema extensions;

create table if not exists public.suppliers (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references auth.users (id) on delete cascade,
    name text not null check (btrim(name) <> ''),
    document_number text,
    phone text,
    email text,
    address text,
    payment_terms_days integer not null default 0 check (payment_terms_days >= 0),
    notes text,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.ingredients (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references auth.users (id) on delete cascade,
    name text not null check (btrim(name) <> ''),
    category text not null check (category in ('bebida', 'carne', 'hortifruti', 'laticinio', 'descartavel', 'outros')),
    base_unit text not null check (base_unit in ('g', 'ml', 'un')),
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.ingredient_prices (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references auth.users (id) on delete cascade,
    ingredient_id uuid not null references public.ingredients (id) on delete cascade,
    supplier_id uuid not null references public.suppliers (id) on delete cascade,
    package_size numeric(14,6) not null check (package_size > 0),
    package_unit text not null check (package_unit in ('g', 'ml', 'un')),
    price numeric(12,2) not null check (price > 0),
    price_per_base_unit numeric(14,6) not null check (price_per_base_unit > 0),
    purchase_date date not null default current_date,
    notes text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    check (package_unit = 'un' or package_size >= 1)
);

create table if not exists public.products (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references auth.users (id) on delete cascade,
    name text not null check (btrim(name) <> ''),
    category text not null check (category in ('bebida', 'comida', 'entrada', 'porcao', 'outros')),
    sale_price numeric(12,2) not null check (sale_price > 0),
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.product_recipe_items (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references auth.users (id) on delete cascade,
    product_id uuid not null references public.products (id) on delete cascade,
    ingredient_id uuid not null references public.ingredients (id) on delete cascade,
    quantity numeric(14,6) not null check (quantity > 0),
    loss_rate numeric(6,4) not null default 0 check (loss_rate >= 0 and loss_rate <= 1),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.transaction_categories (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references auth.users (id) on delete cascade,
    name text not null check (btrim(name) <> ''),
    kind text not null check (kind in ('entrada', 'saida')),
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (owner_id, kind, name)
);

create table if not exists public.transactions (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references auth.users (id) on delete cascade,
    kind text not null check (kind in ('entrada', 'saida')),
    amount numeric(12,2) not null check (amount > 0),
    transaction_date date not null default current_date,
    category_id uuid not null references public.transaction_categories (id) on delete restrict,
    payment_method text not null check (payment_method in ('dinheiro', 'pix', 'debito', 'credito', 'outro')),
    description text not null default '',
    supplier_id uuid references public.suppliers (id) on delete set null,
    status text not null default 'pago' check (status in ('pago', 'pendente')),
    attachment_url text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.recurring_transactions (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references auth.users (id) on delete cascade,
    kind text not null check (kind in ('entrada', 'saida')),
    amount numeric(12,2) not null check (amount > 0),
    category_id uuid not null references public.transaction_categories (id) on delete restrict,
    supplier_id uuid references public.suppliers (id) on delete set null,
    description text not null default '',
    payment_method text not null check (payment_method in ('dinheiro', 'pix', 'debito', 'credito', 'outro')),
    schedule_frequency text not null check (schedule_frequency in ('diario', 'semanal', 'mensal', 'anual')),
    next_due_date date not null default current_date,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.app_settings (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references auth.users (id) on delete cascade,
    target_margin numeric(5,4) not null default 0.30 check (target_margin > 0 and target_margin < 1),
    cost_method text not null default 'weighted_average_5' check (cost_method in ('last_price', 'weighted_average_5', 'lowest_price')),
    alert_price_increase_pct numeric(5,4) not null default 0.10 check (alert_price_increase_pct > 0 and alert_price_increase_pct < 1),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (owner_id)
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

create or replace function public.calculate_ingredient_price_per_base_unit()
returns trigger
language plpgsql
as $$
begin
    if new.package_size is null or new.package_size <= 0 then
        raise exception 'package_size must be greater than zero';
    end if;

    new.price_per_base_unit = new.price / new.package_size;
    return new;
end;
$$;

create or replace function public.current_ingredient_price_by_supplier(p_owner_id uuid, p_ingredient_id uuid, p_supplier_id uuid)
returns table (
    ingredient_id uuid,
    supplier_id uuid,
    price numeric(12,2),
    price_per_base_unit numeric(14,6),
    purchase_date date,
    created_at timestamptz
)
language sql
stable
as $$
    with ranked as (
        select ip.ingredient_id,
               ip.supplier_id,
               ip.price,
               ip.price_per_base_unit,
               ip.purchase_date,
               ip.created_at,
               row_number() over (
                   partition by ip.ingredient_id, ip.supplier_id
                   order by ip.purchase_date desc, ip.created_at desc
               ) as rn
        from public.ingredient_prices ip
        where ip.owner_id = p_owner_id
          and ip.ingredient_id = p_ingredient_id
          and ip.supplier_id = p_supplier_id
    )
    select ingredient_id,
           supplier_id,
           price,
           price_per_base_unit,
           purchase_date,
           created_at
    from ranked
    where rn = 1;
$$;

create or replace function public.current_ingredient_cost(p_owner_id uuid, p_ingredient_id uuid)
returns numeric(14,6)
language plpgsql
stable
as $$
declare
    settings_record record;
    last_price numeric(14,6);
    weighted_average numeric(14,6);
    lowest_price numeric(14,6);
begin
    select * into settings_record
    from public.app_settings
    where owner_id = p_owner_id
    order by updated_at desc
    limit 1;

    if settings_record is null then
        select coalesce(avg(ip.price_per_base_unit), 0)
        into weighted_average
        from public.ingredient_prices ip
        where ip.owner_id = p_owner_id
          and ip.ingredient_id = p_ingredient_id;
        return weighted_average;
    end if;

    if settings_record.cost_method = 'last_price' then
        select ip.price_per_base_unit into last_price
        from public.ingredient_prices ip
        where ip.owner_id = p_owner_id
          and ip.ingredient_id = p_ingredient_id
        order by ip.purchase_date desc, ip.created_at desc
        limit 1;
        return coalesce(last_price, 0);
    elsif settings_record.cost_method = 'lowest_price' then
        select min(ip.price_per_base_unit) into lowest_price
        from public.ingredient_prices ip
        where ip.owner_id = p_owner_id
          and ip.ingredient_id = p_ingredient_id;
        return coalesce(lowest_price, 0);
    else
        select avg(ip.price_per_base_unit) into weighted_average
        from (
            select ip.price_per_base_unit
            from public.ingredient_prices ip
            where ip.owner_id = p_owner_id
              and ip.ingredient_id = p_ingredient_id
            order by ip.purchase_date desc, ip.created_at desc
            limit 5
        ) as recent_prices;
        return coalesce(weighted_average, 0);
    end if;
end;
$$;

create or replace view public.product_cost_summary as
select
    p.id as product_id,
    p.owner_id,
    p.name as product_name,
    p.sale_price,
    coalesce(sum((pri.quantity * (1 + pri.loss_rate)) * public.current_ingredient_cost(p.owner_id, pri.ingredient_id)), 0) as ingredient_cost_total,
    p.sale_price - coalesce(sum((pri.quantity * (1 + pri.loss_rate)) * public.current_ingredient_cost(p.owner_id, pri.ingredient_id)), 0) as gross_margin_value,
    case
        when p.sale_price > 0 then (
            ((p.sale_price - coalesce(sum((pri.quantity * (1 + pri.loss_rate)) * public.current_ingredient_cost(p.owner_id, pri.ingredient_id)), 0)) / p.sale_price)
        )
        else 0
    end as gross_margin_pct,
    case
        when coalesce(sum((pri.quantity * (1 + pri.loss_rate)) * public.current_ingredient_cost(p.owner_id, pri.ingredient_id)), 0) > 0 then (
            p.sale_price / coalesce(sum((pri.quantity * (1 + pri.loss_rate)) * public.current_ingredient_cost(p.owner_id, pri.ingredient_id)), 0)
        )
        else 0
    end as markup
from public.products p
left join public.product_recipe_items pri on pri.product_id = p.id
where p.is_active = true
group by p.id, p.owner_id, p.name, p.sale_price;

create or replace function public.dashboard_summary(p_owner_id uuid, p_start_date date, p_end_date date)
returns table (
    total_entries numeric(12,2),
    total_outputs numeric(12,2),
    balance numeric(12,2),
    pending_payables numeric(12,2),
    transaction_count bigint
)
language sql
stable
as $$
    select
        coalesce(sum(case when t.kind = 'entrada' then t.amount else 0 end), 0)::numeric(12,2) as total_entries,
        coalesce(sum(case when t.kind = 'saida' then t.amount else 0 end), 0)::numeric(12,2) as total_outputs,
        (coalesce(sum(case when t.kind = 'entrada' then t.amount else 0 end), 0) - coalesce(sum(case when t.kind = 'saida' then t.amount else 0 end), 0))::numeric(12,2) as balance,
        coalesce(sum(case when t.kind = 'saida' and t.status = 'pendente' then t.amount else 0 end), 0)::numeric(12,2) as pending_payables,
        count(*)::bigint as transaction_count
    from public.transactions t
    where t.owner_id = p_owner_id
      and t.transaction_date between p_start_date and p_end_date;
$$;

create or replace view public.category_spend_summary as
select
    t.owner_id,
    c.name as category_name,
    c.kind,
    sum(t.amount) as total_amount,
    count(*) as transaction_count
from public.transactions t
join public.transaction_categories c on c.id = t.category_id
where t.kind = 'saida'
group by t.owner_id, c.name, c.kind;

create or replace view public.supplier_spend_summary as
select
    t.owner_id,
    s.id as supplier_id,
    s.name as supplier_name,
    sum(t.amount) as total_spent,
    count(*) as transaction_count
from public.transactions t
join public.suppliers s on s.id = t.supplier_id
where t.kind = 'saida'
  and t.supplier_id is not null
group by t.owner_id, s.id, s.name;

create or replace view public.current_ingredient_prices as
with ranked as (
    select
        ip.*,
        row_number() over (
            partition by ip.owner_id, ip.ingredient_id, ip.supplier_id
            order by ip.purchase_date desc, ip.created_at desc
        ) as rn
    from public.ingredient_prices ip
)
select *
from ranked
where rn = 1;

create or replace view public.current_product_margin as
select
    p.id as product_id,
    p.owner_id,
    p.name,
    p.sale_price,
    pcs.ingredient_cost_total,
    pcs.gross_margin_value,
    pcs.gross_margin_pct,
    pcs.markup,
    s.target_margin
from public.products p
left join public.product_cost_summary pcs on pcs.product_id = p.id
left join public.app_settings s on s.owner_id = p.owner_id;

create table if not exists public.sql_migration_log (
    id uuid primary key default gen_random_uuid(),
    migration_name text not null,
    applied_at timestamptz not null default now()
);

create or replace trigger set_updated_at_suppliers
before update on public.suppliers
for each row execute function public.set_updated_at();

create or replace trigger set_updated_at_ingredients
before update on public.ingredients
for each row execute function public.set_updated_at();

create or replace trigger set_updated_at_ingredient_prices
before update on public.ingredient_prices
for each row execute function public.set_updated_at();

create or replace trigger set_updated_at_products
before update on public.products
for each row execute function public.set_updated_at();

create or replace trigger set_updated_at_product_recipe_items
before update on public.product_recipe_items
for each row execute function public.set_updated_at();

create or replace trigger set_updated_at_transaction_categories
before update on public.transaction_categories
for each row execute function public.set_updated_at();

create or replace trigger set_updated_at_transactions
before update on public.transactions
for each row execute function public.set_updated_at();

create or replace trigger set_updated_at_recurring_transactions
before update on public.recurring_transactions
for each row execute function public.set_updated_at();

create or replace trigger set_updated_at_app_settings
before update on public.app_settings
for each row execute function public.set_updated_at();

create or replace trigger calculate_ingredient_price_per_base_unit_before_insert
before insert or update on public.ingredient_prices
for each row execute function public.calculate_ingredient_price_per_base_unit();

create index if not exists idx_suppliers_owner_name on public.suppliers (owner_id, name);
create index if not exists idx_ingredients_owner_category on public.ingredients (owner_id, category);
create index if not exists idx_ingredient_prices_owner_ingredient_date on public.ingredient_prices (owner_id, ingredient_id, purchase_date desc);
create index if not exists idx_ingredient_prices_owner_supplier_date on public.ingredient_prices (owner_id, supplier_id, purchase_date desc);
create index if not exists idx_products_owner_category on public.products (owner_id, category);
create index if not exists idx_product_recipe_items_owner_product on public.product_recipe_items (owner_id, product_id);
create index if not exists idx_transactions_owner_date_kind on public.transactions (owner_id, transaction_date desc, kind);
create index if not exists idx_transactions_owner_category on public.transactions (owner_id, category_id, transaction_date desc);
create index if not exists idx_transactions_owner_supplier on public.transactions (owner_id, supplier_id, transaction_date desc);
create index if not exists idx_recurring_transactions_owner_next_due on public.recurring_transactions (owner_id, next_due_date);
create index if not exists idx_app_settings_owner on public.app_settings (owner_id);

alter table public.suppliers enable row level security;
alter table public.ingredients enable row level security;
alter table public.ingredient_prices enable row level security;
alter table public.products enable row level security;
alter table public.product_recipe_items enable row level security;
alter table public.transaction_categories enable row level security;
alter table public.transactions enable row level security;
alter table public.recurring_transactions enable row level security;
alter table public.app_settings enable row level security;

create policy if not exists suppliers_select_policy on public.suppliers
    for select using (owner_id = auth.uid());
create policy if not exists suppliers_insert_policy on public.suppliers
    for insert with check (owner_id = auth.uid());
create policy if not exists suppliers_update_policy on public.suppliers
    for update using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy if not exists suppliers_delete_policy on public.suppliers
    for delete using (owner_id = auth.uid());

create policy if not exists ingredients_select_policy on public.ingredients
    for select using (owner_id = auth.uid());
create policy if not exists ingredients_insert_policy on public.ingredients
    for insert with check (owner_id = auth.uid());
create policy if not exists ingredients_update_policy on public.ingredients
    for update using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy if not exists ingredients_delete_policy on public.ingredients
    for delete using (owner_id = auth.uid());

create policy if not exists ingredient_prices_select_policy on public.ingredient_prices
    for select using (owner_id = auth.uid());
create policy if not exists ingredient_prices_insert_policy on public.ingredient_prices
    for insert with check (owner_id = auth.uid());
create policy if not exists ingredient_prices_update_policy on public.ingredient_prices
    for update using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy if not exists ingredient_prices_delete_policy on public.ingredient_prices
    for delete using (owner_id = auth.uid());

create policy if not exists products_select_policy on public.products
    for select using (owner_id = auth.uid());
create policy if not exists products_insert_policy on public.products
    for insert with check (owner_id = auth.uid());
create policy if not exists products_update_policy on public.products
    for update using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy if not exists products_delete_policy on public.products
    for delete using (owner_id = auth.uid());

create policy if not exists product_recipe_items_select_policy on public.product_recipe_items
    for select using (owner_id = auth.uid());
create policy if not exists product_recipe_items_insert_policy on public.product_recipe_items
    for insert with check (owner_id = auth.uid());
create policy if not exists product_recipe_items_update_policy on public.product_recipe_items
    for update using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy if not exists product_recipe_items_delete_policy on public.product_recipe_items
    for delete using (owner_id = auth.uid());

create policy if not exists transaction_categories_select_policy on public.transaction_categories
    for select using (owner_id = auth.uid());
create policy if not exists transaction_categories_insert_policy on public.transaction_categories
    for insert with check (owner_id = auth.uid());
create policy if not exists transaction_categories_update_policy on public.transaction_categories
    for update using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy if not exists transaction_categories_delete_policy on public.transaction_categories
    for delete using (owner_id = auth.uid());

create policy if not exists transactions_select_policy on public.transactions
    for select using (owner_id = auth.uid());
create policy if not exists transactions_insert_policy on public.transactions
    for insert with check (owner_id = auth.uid());
create policy if not exists transactions_update_policy on public.transactions
    for update using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy if not exists transactions_delete_policy on public.transactions
    for delete using (owner_id = auth.uid());

create policy if not exists recurring_transactions_select_policy on public.recurring_transactions
    for select using (owner_id = auth.uid());
create policy if not exists recurring_transactions_insert_policy on public.recurring_transactions
    for insert with check (owner_id = auth.uid());
create policy if not exists recurring_transactions_update_policy on public.recurring_transactions
    for update using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy if not exists recurring_transactions_delete_policy on public.recurring_transactions
    for delete using (owner_id = auth.uid());

create policy if not exists app_settings_select_policy on public.app_settings
    for select using (owner_id = auth.uid());
create policy if not exists app_settings_insert_policy on public.app_settings
    for insert with check (owner_id = auth.uid());
create policy if not exists app_settings_update_policy on public.app_settings
    for update using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy if not exists app_settings_delete_policy on public.app_settings
    for delete using (owner_id = auth.uid());

create or replace function public.seed_default_categories(p_owner_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.transaction_categories (owner_id, name, kind, is_active)
    values
        (p_owner_id, 'Vendas', 'entrada', true),
        (p_owner_id, 'Outras receitas', 'entrada', true),
        (p_owner_id, 'Ingredientes / insumos', 'saida', true),
        (p_owner_id, 'Salários', 'saida', true),
        (p_owner_id, 'Aluguel', 'saida', true),
        (p_owner_id, 'Energia', 'saida', true),
        (p_owner_id, 'Água', 'saida', true),
        (p_owner_id, 'Internet', 'saida', true),
        (p_owner_id, 'Manutenção', 'saida', true),
        (p_owner_id, 'Impostos', 'saida', true),
        (p_owner_id, 'Outros', 'saida', true)
    on conflict (owner_id, kind, name) do nothing;

    insert into public.app_settings (owner_id, target_margin, cost_method, alert_price_increase_pct)
    values (p_owner_id, 0.30, 'weighted_average_5', 0.10)
    on conflict (owner_id) do nothing;
end;
$$;

create or replace function public.ensure_app_settings(p_owner_id uuid)
returns public.app_settings
language plpgsql
security definer
set search_path = public
as $$
declare
    record_row public.app_settings;
begin
    select * into record_row
    from public.app_settings
    where owner_id = p_owner_id
    limit 1;

    if record_row.id is null then
        insert into public.app_settings (owner_id, target_margin, cost_method, alert_price_increase_pct)
        values (p_owner_id, 0.30, 'weighted_average_5', 0.10)
        returning * into record_row;
    end if;

    return record_row;
end;
$$;
