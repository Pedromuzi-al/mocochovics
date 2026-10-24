begin;

create table if not exists public.product_cost_history (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users on delete cascade,
  created_at timestamptz not null default clock_timestamp(),
  updated_at timestamptz not null default clock_timestamp(),
  revision bigint generated always as identity,
  product_id uuid not null,
  observed_on date not null default (now() at time zone 'America/Sao_Paulo')::date,
  cost numeric(12,2), sale_price numeric(12,2) not null,
  target_margin numeric(14,6) not null,
  cost_method text not null, purchase_count integer not null,
  reason text not null,
  foreign key(product_id, owner_id) references public.products(id, owner_id) on delete cascade
);
create index if not exists product_cost_history_owner_product_idx on public.product_cost_history(owner_id, product_id, revision desc);
alter table public.product_cost_history enable row level security;
drop policy if exists owner_select on public.product_cost_history;
create policy owner_select on public.product_cost_history for select to authenticated using(owner_id=(select auth.uid()));
revoke all on public.product_cost_history from anon, authenticated;
grant select on public.product_cost_history to authenticated;

create or replace function public.record_product_costs() returns trigger
language plpgsql security definer set search_path = '' as $$
declare target_owner uuid; item record; previous public.product_cost_history;
begin
  if tg_op = 'DELETE' then target_owner := old.owner_id; else target_owner := new.owner_id; end if;
  if tg_table_name = 'suppliers' then
    if new.active is not distinct from old.active then return new; end if;
  end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(target_owner::text,0));
  for item in
    select costs.*, coalesce(settings.cost_method,'weighted_average') cost_method,
      coalesce(settings.purchase_count,5) purchase_count
    from public.product_costs costs
    left join public.app_settings settings on settings.owner_id=costs.owner_id
    where costs.owner_id=target_owner
  loop
    select * into previous from public.product_cost_history
    where product_id=item.id and owner_id=target_owner order by revision desc limit 1;
    if not found or row(previous.cost,previous.sale_price,previous.target_margin,previous.cost_method,previous.purchase_count)
      is distinct from row(item.cost,item.sale_price,item.target_margin,item.cost_method,item.purchase_count) then
      insert into public.product_cost_history(owner_id,product_id,cost,sale_price,target_margin,cost_method,purchase_count,reason)
      values(target_owner,item.id,item.cost,item.sale_price,item.target_margin,item.cost_method,item.purchase_count,tg_table_name);
    end if;
  end loop;
  if tg_op = 'DELETE' then return old; else return new; end if;
end $$;
revoke all on function public.record_product_costs() from public, anon, authenticated;

drop trigger if exists record_product_costs on public.products;
create trigger record_product_costs after insert or update on public.products for each row execute function public.record_product_costs();
drop trigger if exists record_product_costs on public.product_recipe_items;
create trigger record_product_costs after insert or update or delete on public.product_recipe_items for each row execute function public.record_product_costs();
drop trigger if exists record_product_costs on public.ingredient_prices;
create trigger record_product_costs after insert on public.ingredient_prices for each row execute function public.record_product_costs();
drop trigger if exists record_product_costs on public.suppliers;
create trigger record_product_costs after update on public.suppliers for each row execute function public.record_product_costs();
drop trigger if exists record_product_costs on public.app_settings;
create trigger record_product_costs after insert or update on public.app_settings for each row execute function public.record_product_costs();

insert into public.product_cost_history(owner_id,product_id,cost,sale_price,target_margin,cost_method,purchase_count,reason)
select costs.owner_id,costs.id,costs.cost,costs.sale_price,costs.target_margin,
  coalesce(settings.cost_method,'weighted_average'),coalesce(settings.purchase_count,5),'baseline'
from public.product_costs costs left join public.app_settings settings on settings.owner_id=costs.owner_id
where not exists(select 1 from public.product_cost_history history where history.product_id=costs.id);

commit;
