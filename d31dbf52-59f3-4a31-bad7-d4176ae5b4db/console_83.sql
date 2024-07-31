create index symbolmaster_option_symbol_idx on external_data.symbolmaster (option_symbol);
analyze external_data.symbolmaster;

select * from external_data.symbolmaster
where effective_date::date <= :in_date_id::text::date;


create function dash360.report_fintech_adh_symbol_multiplier(in_date_id int4, in_all_multipliers char default 'N')
    returns table
            (
                "Root Symbol"   varchar(50),
                "Equity Symbol" varchar(50),
                "Multiplier"    numeric,
                "Component ID"  integer
            )
    language plpgsql
as
$fx$
    -- 2024-07-30 SO https://dashfinancial.atlassian.net/browse/DEVREQ-4428
begin

    return query
        with cte_symbol as
                 (select sm.option_symbol                              as "Root Symbol",
                         sm.delivered_equity                           as "Equity Symbol",
                         coalesce(sm.delivered_value, 100)             as "Multiplier",
                         sm.component_id                               as "Component ID",
                         count(*) over (partition by sm.option_symbol) as "Total Non-Cash Component"
                  from external_data.symbolmaster sm
                  where sm.delivered_equity not like '$%CASH%'
                  group by "Root Symbol", "Equity Symbol", "Multiplier", "Component ID")
        select cs."Root Symbol", cs."Equity Symbol", cs."Multiplier", cs."Component ID"
        from cte_symbol as cs
        where case
                  when in_all_multipliers = 'Y' then true
                  else
                      not (cs."Multiplier" = 100 and cs."Total Non-Cash Component" = 1) end--If in_all_multipliers = 'N' else include everything;
        order by "Root Symbol", "Component ID";
end ;
$fx$

select * from dash360.report_fintech_adh_symbol_multiplier(20240715, 'Y')


;
create temp table t_03 as
with cte_symbol as
(
	select
		sm.option_symbol as "Root Symbol",
		sm.delivered_equity as "Equity Symbol",
		coalesce(sm.delivered_value, 100) as "Multiplier",
		sm.component_id as "Component ID"
	from external_data.symbolmaster sm
	where sm.delivered_equity not like '$%CASH%'
	group by "Root Symbol", "Equity Symbol", "Multiplier", "Component ID"
	order by "Root Symbol", "Component ID"
)
select cs.*
from cte_symbol as cs
left join (
	select g."Root Symbol", count(1) as "Total Non-Cash Component"
	from cte_symbol as g
	group by g."Root Symbol"
) as csg on (csg."Root Symbol" = cs."Root Symbol")
where not(cs."Multiplier" = 100 and csg."Total Non-Cash Component" = 1)
order by "Root Symbol", "Component ID"
; --If in_all_multipliers = 'N' else include everything;

create temp table t_04 as
with cte_symbol as
(
	select
		sm.option_symbol as "Root Symbol",
		sm.delivered_equity as "Equity Symbol",
		coalesce(sm.delivered_value, 100) as "Multiplier",
		sm.component_id as "Component ID",
		count(*) over(partition by sm.option_symbol) as "Total Non-Cash Component"
	from external_data.symbolmaster sm
	where sm.delivered_equity not like '$%CASH%'
	group by "Root Symbol", "Equity Symbol", "Multiplier", "Component ID"
)
select cs.*
from cte_symbol as cs
where not(cs."Multiplier" = 100 and cs."Total Non-Cash Component" = 1) --If in_all_multipliers = 'N' else include everything;
order by "Root Symbol", "Component ID"

select "Root Symbol", "Equity Symbol", "Multiplier", "Component ID" from t_04
except
select "Root Symbol", "Equity Symbol", "Multiplier", "Component ID" from t_03;