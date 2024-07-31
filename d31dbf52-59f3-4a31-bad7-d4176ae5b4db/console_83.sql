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
where not(cs."Multiplier" = 100 and csg."Total Non-Cash Component" = 1) --If in_all_multipliers = 'N' else include everything;