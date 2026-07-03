-- Adds the CPREMIUM stock type.
-- CPREMIUM costs 350 coins per unit.
-- Existing C stock stays at 300 coins.
-- Run manually in the Supabase SQL Editor.

insert into stock_types (
  prefix,
  name,
  item_unit_cost,
  quantity_per_stock_sale,
  capital_per_stock_sale,
  earnings_per_approved_sale
)
select
  'CPREMIUM',
  'Premium stock unit',
  350,
  1,
  350,
  100
where not exists (
  select 1
  from stock_types
  where prefix = 'CPREMIUM'
);