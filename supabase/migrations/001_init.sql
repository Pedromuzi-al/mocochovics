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
    updated_at timestamptz not null default now(),
    unique (owner_id, id)
);

create table if not exists public.ingredients (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references auth.users (id) on delete cascade,
    name text not null check (btrim(name) <> ''),
    category text not null check (category in ('bebida', 'carne', 'hortifruti', 'laticinio', 'descartavel', 'outros')),
    base_unit text not null check (base_unit in ('g', 'ml', 'un')),
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (owner_id, id)
);

create table if not exists public.ingredient_prices (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references auth.users (id) on delete cascade,
    ingredient_id uuid not null,
    supplier_id uuid not null,
    package_size numeric(14,6) not null check (package_size > 0),
    package_unit text not null check (package_unit in ('g', 'kg', 'ml', 'l', 'un')),
    package_base_quantity numeric(14,6) not null check (package_base_quantity > 0),
    price numeric(12,2) not null check (price > 0),
    price_per_base_unit numeric(14,6) not null check (price_per_base_unit > 0),
    purchase_date date not null default current_date,
    notes text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (owner_id, id),
    foreign key (owner_id, ingredient_id)
        references public.ingredients (owner_id, id) on delete restrict,
    foreign key (owner_id, supplier_id)
        references public.suppliers (owner_id, id) on delete restrict
);

create table if not exists public.products (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references auth.users (id) on delete cascade,
    name text not null check (btrim(name) <> ''),
    category text not null check (category in ('bebida', 'comida', 'entrada', 'porcao', 'outros')),
    sale_price numeric(12,2) not null check (sale_price > 0),
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (owner_id, id)
);

create table if not exists public.product_recipe_items (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references auth.users (id) on delete cascade,
    product_id uuid not null,
    ingredient_id uuid not null,
    quantity numeric(14,6) not null check (quantity > 0),
    loss_rate numeric(6,4) not null default 0 check (loss_rate >= 0 and loss_rate <= 1),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (owner_id, id),
    unique (owner_id, product_id, ingredient_id),
    foreign key (owner_id, product_id)
        references public.products (owner_id, id) on delete cascade,
    foreign key (owner_id, ingredient_id)
        references public.ingredients (owner_id, id) on delete restrict
);

create table if not exists public.transaction_categories (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references auth.users (id) on delete cascade,
    name text not null check (btrim(name) <> ''),
    kind text not null check (kind in ('entrada', 'saida')),
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (owner_id, kind, name),
    unique (owner_id, id),
    unique (owner_id, id, kind)
);

create table if not exists public.transactions (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references auth.users (id) on delete cascade,
    kind text not null check (kind in ('entrada', 'saida')),
    amount numeric(12,2) not null check (amount > 0),
    transaction_date date not null default current_date,
    category_id uuid not null,
    payment_method text not null check (payment_method in ('dinheiro', 'pix', 'debito', 'credito', 'outro')),
    description text not null default '',
    supplier_id uuid,
    status text not null default 'pago' check (status in ('pago', 'pendente')),
    attachment_url text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    foreign key (owner_id, category_id, kind)
        references public.transaction_categories (owner_id, id, kind) on delete restrict,
    foreign key (owner_id, supplier_id)
        references public.suppliers (owner_id, id) on delete set null (supplier_id),
    check (supplier_id is null or kind = 'saida')
);

create table if not exists public.recurring_transactions (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references auth.users (id) on delete cascade,
    kind text not null check (kind in ('entrada', 'saida')),
    amount numeric(12,2) not null check (amount > 0),
    category_id uuid not null,
    supplier_id uuid,
    description text not null default '',
    payment_method text not null check (payment_method in ('dinheiro', 'pix', 'debito', 'credito', 'outro')),
    schedule_frequency text not null check (schedule_frequency in ('diario', 'semanal', 'mensal', 'anual')),
    next_due_date date not null default current_date,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    foreign key (owner_id, category_id, kind)
        references public.transaction_categories (owner_id, id, kind) on delete restrict,
    foreign key (owner_id, supplier_id)
        references public.suppliers (owner_id, id) on delete set null (supplier_id),
    check (supplier_id is null or kind = 'saida')
);

create table if not exists public.app_settings (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references auth.users (id) on delete cascade,
    target_margin numeric(5,4) not null default 0.30 check (target_margin > 0 and target_margin < 1),
    cost_method text not null default 'weighted_average_5' check (cost_method in ('last_price', 'weighted_average_5', 'lowest_price')),
    alert_price_increase_pct numeric(5,4) not null default 0.10 check (alert_price_increase_pct >= 0 and alert_price_increase_pct < 10),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (owner_id)
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

create or replace function public.calculate_ingredient_price_per_base_unit()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
    ingredient_base_unit text;
    conversion_factor numeric(14,6);
begin
    select i.base_unit
      into ingredient_base_unit
      from public.ingredients i
     where i.id = new.ingredient_id
       and i.owner_id = new.owner_id;

    if ingredient_base_unit is null then
        raise exception 'Ingredient does not belong to this user';
    end if;

    conversion_factor := case
        when ingredient_base_unit = 'g' and new.package_unit = 'g' then 1
        when ingredient_base_unit = 'g' and new.package_unit = 'kg' then 1000
        when ingredient_base_unit = 'ml' and new.package_unit = 'ml' then 1
        when ingredient_base_unit = 'ml' and new.package_unit = 'l' then 1000
        when ingredient_base_unit = 'un' and new.package_unit = 'un' then 1
        else null
    end;

    if conversion_factor is null then
        raise exception 'Package unit is incompatible with ingredient base unit';
    end if;

    new.package_base_quantity := round(new.package_size * conversion_factor, 6);
    new.price_per_base_unit := round(new.price / new.package_base_quantity, 6);
    return new;
end;
$$;

create or replace function public.prevent_ingredient_price_history_change()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
    raise exception 'Price history is immutable; insert a new quote instead';
end;
$$;

create or replace function public.prevent_ingredient_base_unit_change()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
    if new.base_unit is distinct from old.base_unit
       and (
           exists (
               select 1
                 from public.ingredient_prices
                where owner_id = old.owner_id
                  and ingredient_id = old.id
           )
           or exists (
               select 1
                 from public.product_recipe_items
                where owner_id = old.owner_id
                  and ingredient_id = old.id
           )
       ) then
        raise exception 'Base unit cannot change after prices or recipes are recorded';
    end if;
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
set search_path = public, auth, pg_temp
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
                   order by ip.purchase_date desc, ip.created_at desc, ip.id desc
               ) as rn
        from public.ingredient_prices ip
        where ip.owner_id = p_owner_id
          and p_owner_id = auth.uid()
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
set search_path = public, auth, pg_temp
as $$
declare
    settings_record record;
    last_price numeric(14,6);
    weighted_average numeric(14,6);
    lowest_price numeric(14,6);
begin
    if auth.uid() is null or p_owner_id is distinct from auth.uid() then
        raise exception 'Cannot read costs for another user';
    end if;

    select * into settings_record
    from public.app_settings
    where owner_id = p_owner_id
    limit 1;

    if settings_record is null then
        select sum(ip.price_per_base_unit * ip.package_base_quantity)
                   / nullif(sum(ip.package_base_quantity), 0)
        into weighted_average
        from (
            select price_per_base_unit, package_base_quantity
              from public.ingredient_prices
             where owner_id = p_owner_id
               and ingredient_id = p_ingredient_id
             order by purchase_date desc, created_at desc, id desc
             limit 5
        ) ip;
        return weighted_average;
    end if;

    if settings_record.cost_method = 'last_price' then
        select ip.price_per_base_unit into last_price
        from public.ingredient_prices ip
        where ip.owner_id = p_owner_id
          and ip.ingredient_id = p_ingredient_id
        order by ip.purchase_date desc, ip.created_at desc, ip.id desc
        limit 1;
        return last_price;
    elsif settings_record.cost_method = 'lowest_price' then
        select min(current_price.price_per_base_unit) into lowest_price
          from public.current_ingredient_prices current_price
          join public.suppliers supplier
            on supplier.owner_id = current_price.owner_id
           and supplier.id = current_price.supplier_id
           and supplier.is_active
         where current_price.owner_id = p_owner_id
           and current_price.ingredient_id = p_ingredient_id;
        return lowest_price;
    else
        select sum(recent_prices.price_per_base_unit * recent_prices.package_base_quantity)
                   / nullif(sum(recent_prices.package_base_quantity), 0)
          into weighted_average
        from (
            select ip.price_per_base_unit, ip.package_base_quantity
            from public.ingredient_prices ip
            where ip.owner_id = p_owner_id
              and ip.ingredient_id = p_ingredient_id
            order by ip.purchase_date desc, ip.created_at desc, ip.id desc
            limit 5
        ) as recent_prices;
        return weighted_average;
    end if;
end;
$$;

create or replace view public.product_cost_summary as
with product_costs as (
    select
        p.id as product_id,
        p.owner_id,
        p.name as product_name,
        p.sale_price,
        count(pri.id) as recipe_item_count,
        count(ingredient_cost.cost_per_base_unit) as priced_item_count,
        sum((pri.quantity * (1 + pri.loss_rate))
            * ingredient_cost.cost_per_base_unit) as ingredient_cost_total
    from public.products p
    left join public.product_recipe_items pri
      on pri.owner_id = p.owner_id
     and pri.product_id = p.id
    left join lateral (
        select public.current_ingredient_cost(p.owner_id, pri.ingredient_id)
            as cost_per_base_unit
        where pri.id is not null
    ) ingredient_cost on true
    where p.is_active = true
    group by p.id, p.owner_id, p.name, p.sale_price
)
select
    product_id,
    owner_id,
    product_name,
    sale_price,
    case
        when recipe_item_count > 0 and recipe_item_count = priced_item_count
            then ingredient_cost_total
    end as ingredient_cost_total,
    case
        when recipe_item_count > 0 and recipe_item_count = priced_item_count
            then sale_price - ingredient_cost_total
    end as gross_margin_value,
    case
        when recipe_item_count > 0
         and recipe_item_count = priced_item_count
         and sale_price > 0
            then (sale_price - ingredient_cost_total) / sale_price
    end as gross_margin_pct,
    case
        when recipe_item_count > 0
         and recipe_item_count = priced_item_count
         and ingredient_cost_total > 0
            then sale_price / ingredient_cost_total
    end as markup
from product_costs;

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
set search_path = public, auth, pg_temp
as $$
    select
        coalesce(sum(case when t.kind = 'entrada' and t.status = 'pago' then t.amount else 0 end), 0)::numeric(12,2) as total_entries,
        coalesce(sum(case when t.kind = 'saida' and t.status = 'pago' then t.amount else 0 end), 0)::numeric(12,2) as total_outputs,
        (coalesce(sum(case when t.kind = 'entrada' and t.status = 'pago' then t.amount else 0 end), 0) - coalesce(sum(case when t.kind = 'saida' and t.status = 'pago' then t.amount else 0 end), 0))::numeric(12,2) as balance,
        coalesce(sum(case when t.kind = 'saida' and t.status = 'pendente' then t.amount else 0 end), 0)::numeric(12,2) as pending_payables,
        count(*)::bigint as transaction_count
    from public.transactions t
    where t.owner_id = p_owner_id
      and p_owner_id = auth.uid()
      and t.transaction_date between p_start_date and p_end_date;
$$;

create or replace function public.dashboard_expenses_by_category(
    p_owner_id uuid,
    p_start_date date,
    p_end_date date
)
returns table (
    category_id uuid,
    category_name text,
    total_amount numeric(12,2),
    transaction_count bigint
)
language sql
stable
set search_path = public, auth, pg_temp
as $$
    select c.id,
           c.name,
           coalesce(sum(t.amount), 0)::numeric(12,2),
           count(t.id)::bigint
      from public.transaction_categories c
      left join public.transactions t
        on t.owner_id = c.owner_id
       and t.category_id = c.id
       and t.kind = 'saida'
       and t.status = 'pago'
       and t.transaction_date between p_start_date and p_end_date
     where c.owner_id = p_owner_id
       and p_owner_id = auth.uid()
       and c.kind = 'saida'
       and c.is_active
     group by c.id, c.name
     order by sum(t.amount) desc nulls last, c.name;
$$;

create or replace function public.dashboard_supplier_spending(
    p_owner_id uuid,
    p_start_date date,
    p_end_date date
)
returns table (
    supplier_id uuid,
    supplier_name text,
    total_amount numeric(12,2),
    transaction_count bigint
)
language sql
stable
set search_path = public, auth, pg_temp
as $$
    select s.id,
           s.name,
           coalesce(sum(t.amount), 0)::numeric(12,2),
           count(t.id)::bigint
      from public.suppliers s
      join public.transactions t
        on t.owner_id = s.owner_id
       and t.supplier_id = s.id
       and t.kind = 'saida'
       and t.status = 'pago'
       and t.transaction_date between p_start_date and p_end_date
     where s.owner_id = p_owner_id
       and p_owner_id = auth.uid()
     group by s.id, s.name
     order by sum(t.amount) desc, s.name;
$$;

create or replace view public.category_spend_summary as
select
    t.owner_id,
    c.name as category_name,
    c.kind,
    sum(t.amount) as total_amount,
    count(*) as transaction_count
from public.transactions t
join public.transaction_categories c
  on c.owner_id = t.owner_id
 and c.id = t.category_id
where t.kind = 'saida'
  and t.status = 'pago'
group by t.owner_id, c.name, c.kind;

create or replace view public.supplier_spend_summary as
select
    t.owner_id,
    s.id as supplier_id,
    s.name as supplier_name,
    sum(t.amount) as total_spent,
    count(*) as transaction_count
from public.transactions t
join public.suppliers s
  on s.owner_id = t.owner_id
 and s.id = t.supplier_id
where t.kind = 'saida'
  and t.status = 'pago'
  and t.supplier_id is not null
group by t.owner_id, s.id, s.name;

create or replace view public.current_ingredient_prices as
with ranked as (
    select
        ip.*,
        row_number() over (
            partition by ip.owner_id, ip.ingredient_id, ip.supplier_id
            order by ip.purchase_date desc, ip.created_at desc, ip.id desc
        ) as rn
    from public.ingredient_prices ip
)
select *
from ranked
where rn = 1;

create or replace view public.ingredient_price_alerts as
with ranked as (
    select
        ip.owner_id,
        ip.ingredient_id,
        ip.supplier_id,
        ip.price_per_base_unit as current_price_per_base_unit,
        ip.purchase_date as current_purchase_date,
        lead(ip.price_per_base_unit) over (
            partition by ip.owner_id, ip.ingredient_id, ip.supplier_id
            order by ip.purchase_date desc, ip.created_at desc, ip.id desc
        ) as previous_price_per_base_unit,
        row_number() over (
            partition by ip.owner_id, ip.ingredient_id, ip.supplier_id
            order by ip.purchase_date desc, ip.created_at desc, ip.id desc
        ) as quote_rank
    from public.ingredient_prices ip
)
select
    latest.owner_id,
    latest.ingredient_id,
    i.name as ingredient_name,
    latest.supplier_id,
    s.name as supplier_name,
    latest.current_price_per_base_unit,
    latest.previous_price_per_base_unit,
    latest.current_purchase_date,
    (latest.current_price_per_base_unit / latest.previous_price_per_base_unit) - 1
        as increase_ratio,
    settings.alert_price_increase_pct as alert_threshold_ratio
from ranked latest
join public.ingredients i
  on i.owner_id = latest.owner_id
 and i.id = latest.ingredient_id
join public.suppliers s
  on s.owner_id = latest.owner_id
 and s.id = latest.supplier_id
join public.app_settings settings on settings.owner_id = latest.owner_id
where latest.quote_rank = 1
  and latest.previous_price_per_base_unit > 0
  and latest.current_price_per_base_unit > latest.previous_price_per_base_unit
  and s.is_active
  and (latest.current_price_per_base_unit / latest.previous_price_per_base_unit) - 1
      >= settings.alert_price_increase_pct;

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
    s.target_margin,
    case
        when pcs.ingredient_cost_total is not null
         and s.target_margin is not null
            then pcs.ingredient_cost_total / nullif(1 - s.target_margin, 0)
    end as suggested_sale_price,
    case
        when pcs.gross_margin_pct is not null
         and s.target_margin is not null
            then pcs.gross_margin_pct < s.target_margin
    end as below_target_margin
from public.products p
left join public.product_cost_summary pcs
  on pcs.owner_id = p.owner_id
 and pcs.product_id = p.id
left join public.app_settings s on s.owner_id = p.owner_id
where p.is_active;

alter view public.product_cost_summary set (security_invoker = true);
alter view public.category_spend_summary set (security_invoker = true);
alter view public.supplier_spend_summary set (security_invoker = true);
alter view public.current_ingredient_prices set (security_invoker = true);
alter view public.ingredient_price_alerts set (security_invoker = true);
alter view public.current_product_margin set (security_invoker = true);

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

create or replace trigger prevent_ingredient_price_history_change
before update or delete on public.ingredient_prices
for each row execute function public.prevent_ingredient_price_history_change();

create or replace trigger prevent_ingredient_base_unit_change
before update of base_unit on public.ingredients
for each row execute function public.prevent_ingredient_base_unit_change();

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

drop policy if exists suppliers_select_policy on public.suppliers;
create policy suppliers_select_policy on public.suppliers
    for select to authenticated using (owner_id = (select auth.uid()));
drop policy if exists suppliers_insert_policy on public.suppliers;
create policy suppliers_insert_policy on public.suppliers
    for insert to authenticated with check (owner_id = (select auth.uid()));
drop policy if exists suppliers_update_policy on public.suppliers;
create policy suppliers_update_policy on public.suppliers
    for update to authenticated
    using (owner_id = (select auth.uid()))
    with check (owner_id = (select auth.uid()));
drop policy if exists suppliers_delete_policy on public.suppliers;
create policy suppliers_delete_policy on public.suppliers
    for delete to authenticated using (owner_id = (select auth.uid()));

drop policy if exists ingredients_select_policy on public.ingredients;
create policy ingredients_select_policy on public.ingredients
    for select to authenticated using (owner_id = (select auth.uid()));
drop policy if exists ingredients_insert_policy on public.ingredients;
create policy ingredients_insert_policy on public.ingredients
    for insert to authenticated with check (owner_id = (select auth.uid()));
drop policy if exists ingredients_update_policy on public.ingredients;
create policy ingredients_update_policy on public.ingredients
    for update to authenticated
    using (owner_id = (select auth.uid()))
    with check (owner_id = (select auth.uid()));
drop policy if exists ingredients_delete_policy on public.ingredients;
create policy ingredients_delete_policy on public.ingredients
    for delete to authenticated using (owner_id = (select auth.uid()));

drop policy if exists ingredient_prices_select_policy on public.ingredient_prices;
create policy ingredient_prices_select_policy on public.ingredient_prices
    for select to authenticated using (owner_id = (select auth.uid()));
drop policy if exists ingredient_prices_insert_policy on public.ingredient_prices;
create policy ingredient_prices_insert_policy on public.ingredient_prices
    for insert to authenticated with check (owner_id = (select auth.uid()));
drop policy if exists ingredient_prices_update_policy on public.ingredient_prices;
create policy ingredient_prices_update_policy on public.ingredient_prices
    for update to authenticated using (false) with check (false);
drop policy if exists ingredient_prices_delete_policy on public.ingredient_prices;
create policy ingredient_prices_delete_policy on public.ingredient_prices
    for delete to authenticated using (false);

drop policy if exists products_select_policy on public.products;
create policy products_select_policy on public.products
    for select to authenticated using (owner_id = (select auth.uid()));
drop policy if exists products_insert_policy on public.products;
create policy products_insert_policy on public.products
    for insert to authenticated with check (owner_id = (select auth.uid()));
drop policy if exists products_update_policy on public.products;
create policy products_update_policy on public.products
    for update to authenticated
    using (owner_id = (select auth.uid()))
    with check (owner_id = (select auth.uid()));
drop policy if exists products_delete_policy on public.products;
create policy products_delete_policy on public.products
    for delete to authenticated using (owner_id = (select auth.uid()));

drop policy if exists product_recipe_items_select_policy on public.product_recipe_items;
create policy product_recipe_items_select_policy on public.product_recipe_items
    for select to authenticated using (owner_id = (select auth.uid()));
drop policy if exists product_recipe_items_insert_policy on public.product_recipe_items;
create policy product_recipe_items_insert_policy on public.product_recipe_items
    for insert to authenticated with check (owner_id = (select auth.uid()));
drop policy if exists product_recipe_items_update_policy on public.product_recipe_items;
create policy product_recipe_items_update_policy on public.product_recipe_items
    for update to authenticated
    using (owner_id = (select auth.uid()))
    with check (owner_id = (select auth.uid()));
drop policy if exists product_recipe_items_delete_policy on public.product_recipe_items;
create policy product_recipe_items_delete_policy on public.product_recipe_items
    for delete to authenticated using (owner_id = (select auth.uid()));

drop policy if exists transaction_categories_select_policy on public.transaction_categories;
create policy transaction_categories_select_policy on public.transaction_categories
    for select to authenticated using (owner_id = (select auth.uid()));
drop policy if exists transaction_categories_insert_policy on public.transaction_categories;
create policy transaction_categories_insert_policy on public.transaction_categories
    for insert to authenticated with check (owner_id = (select auth.uid()));
drop policy if exists transaction_categories_update_policy on public.transaction_categories;
create policy transaction_categories_update_policy on public.transaction_categories
    for update to authenticated
    using (owner_id = (select auth.uid()))
    with check (owner_id = (select auth.uid()));
drop policy if exists transaction_categories_delete_policy on public.transaction_categories;
create policy transaction_categories_delete_policy on public.transaction_categories
    for delete to authenticated using (owner_id = (select auth.uid()));

drop policy if exists transactions_select_policy on public.transactions;
create policy transactions_select_policy on public.transactions
    for select to authenticated using (owner_id = (select auth.uid()));
drop policy if exists transactions_insert_policy on public.transactions;
create policy transactions_insert_policy on public.transactions
    for insert to authenticated with check (owner_id = (select auth.uid()));
drop policy if exists transactions_update_policy on public.transactions;
create policy transactions_update_policy on public.transactions
    for update to authenticated
    using (owner_id = (select auth.uid()))
    with check (owner_id = (select auth.uid()));
drop policy if exists transactions_delete_policy on public.transactions;
create policy transactions_delete_policy on public.transactions
    for delete to authenticated using (owner_id = (select auth.uid()));

drop policy if exists recurring_transactions_select_policy on public.recurring_transactions;
create policy recurring_transactions_select_policy on public.recurring_transactions
    for select to authenticated using (owner_id = (select auth.uid()));
drop policy if exists recurring_transactions_insert_policy on public.recurring_transactions;
create policy recurring_transactions_insert_policy on public.recurring_transactions
    for insert to authenticated with check (owner_id = (select auth.uid()));
drop policy if exists recurring_transactions_update_policy on public.recurring_transactions;
create policy recurring_transactions_update_policy on public.recurring_transactions
    for update to authenticated
    using (owner_id = (select auth.uid()))
    with check (owner_id = (select auth.uid()));
drop policy if exists recurring_transactions_delete_policy on public.recurring_transactions;
create policy recurring_transactions_delete_policy on public.recurring_transactions
    for delete to authenticated using (owner_id = (select auth.uid()));

drop policy if exists app_settings_select_policy on public.app_settings;
create policy app_settings_select_policy on public.app_settings
    for select to authenticated using (owner_id = (select auth.uid()));
drop policy if exists app_settings_insert_policy on public.app_settings;
create policy app_settings_insert_policy on public.app_settings
    for insert to authenticated with check (owner_id = (select auth.uid()));
drop policy if exists app_settings_update_policy on public.app_settings;
create policy app_settings_update_policy on public.app_settings
    for update to authenticated
    using (owner_id = (select auth.uid()))
    with check (owner_id = (select auth.uid()));
drop policy if exists app_settings_delete_policy on public.app_settings;
create policy app_settings_delete_policy on public.app_settings
    for delete to authenticated using (owner_id = (select auth.uid()));

create or replace function public.seed_default_categories(p_owner_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    if auth.uid() is null or p_owner_id is distinct from auth.uid() then
        raise exception 'Cannot seed defaults for another user';
    end if;

    perform public._seed_default_categories(p_owner_id);
end;
$$;

create or replace function public._seed_default_categories(p_owner_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
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

create or replace function public.seed_user_defaults_after_signup()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    perform public._seed_default_categories(new.id);
    return new;
end;
$$;

drop trigger if exists seed_user_defaults_after_signup on auth.users;
create trigger seed_user_defaults_after_signup
after insert on auth.users
for each row execute function public.seed_user_defaults_after_signup();

do $$
declare
    existing_user record;
begin
    for existing_user in select id from auth.users
    loop
        perform public._seed_default_categories(existing_user.id);
    end loop;
end;
$$;

create or replace function public.ensure_app_settings(p_owner_id uuid)
returns public.app_settings
language plpgsql
set search_path = public, auth, pg_temp
as $$
declare
    record_row public.app_settings;
begin
    if auth.uid() is null or p_owner_id is distinct from auth.uid() then
        raise exception 'Cannot access another user settings';
    end if;

    select * into record_row
    from public.app_settings
    where owner_id = p_owner_id
    limit 1;

    if record_row.id is null then
        insert into public.app_settings (owner_id, target_margin, cost_method, alert_price_increase_pct)
        values (p_owner_id, 0.30, 'weighted_average_5', 0.10)
        on conflict (owner_id) do nothing
        returning * into record_row;
    end if;

    if record_row.id is null then
        select * into record_row
        from public.app_settings
        where owner_id = p_owner_id;
    end if;

    return record_row;
end;
$$;

revoke all on table public.suppliers, public.ingredients, public.ingredient_prices,
    public.products, public.product_recipe_items, public.transaction_categories,
    public.transactions, public.recurring_transactions, public.app_settings
    from public, anon, authenticated;

grant select, insert, update, delete on table
    public.suppliers, public.ingredients, public.products,
    public.product_recipe_items, public.transaction_categories,
    public.transactions, public.recurring_transactions, public.app_settings
    to authenticated;
grant select, insert on table public.ingredient_prices to authenticated;

revoke all on public.product_cost_summary, public.category_spend_summary,
    public.supplier_spend_summary, public.current_ingredient_prices,
    public.ingredient_price_alerts, public.current_product_margin
    from public, anon, authenticated;
grant select on public.product_cost_summary, public.category_spend_summary,
    public.supplier_spend_summary, public.current_ingredient_prices,
    public.ingredient_price_alerts, public.current_product_margin
    to authenticated;

revoke all on function public.set_updated_at() from public, anon, authenticated;
revoke all on function public.calculate_ingredient_price_per_base_unit()
    from public, anon, authenticated;
revoke all on function public.prevent_ingredient_price_history_change()
    from public, anon, authenticated;
revoke all on function public.prevent_ingredient_base_unit_change()
    from public, anon, authenticated;
revoke all on function public.current_ingredient_price_by_supplier(uuid, uuid, uuid)
    from public, anon, authenticated;
revoke all on function public.current_ingredient_cost(uuid, uuid)
    from public, anon, authenticated;
revoke all on function public.dashboard_summary(uuid, date, date)
    from public, anon, authenticated;
revoke all on function public.dashboard_expenses_by_category(uuid, date, date)
    from public, anon, authenticated;
revoke all on function public.dashboard_supplier_spending(uuid, date, date)
    from public, anon, authenticated;
revoke all on function public.seed_default_categories(uuid)
    from public, anon, authenticated;
revoke all on function public._seed_default_categories(uuid)
    from public, anon, authenticated;
revoke all on function public.seed_user_defaults_after_signup()
    from public, anon, authenticated;
revoke all on function public.ensure_app_settings(uuid)
    from public, anon, authenticated;

grant execute on function public.current_ingredient_price_by_supplier(uuid, uuid, uuid)
    to authenticated;
grant execute on function public.current_ingredient_cost(uuid, uuid)
    to authenticated;
grant execute on function public.dashboard_summary(uuid, date, date)
    to authenticated;
grant execute on function public.dashboard_expenses_by_category(uuid, date, date)
    to authenticated;
grant execute on function public.dashboard_supplier_spending(uuid, date, date)
    to authenticated;
grant execute on function public.seed_default_categories(uuid)
    to authenticated;
grant execute on function public.ensure_app_settings(uuid)
    to authenticated;
