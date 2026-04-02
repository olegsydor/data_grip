with client_groups as (select CustomerID,
                              ntile(10) over (order by CustomerID) as grp
                       from (select distinct CustomerID as CustomerID
                             from billing.TBillingOrderDetail_Daily_inc) t)
   , nt as (select c.*,
                   g.grp
            from billing.TBillingOrderDetail_Daily_inc c
                     join client_groups g using (CustomerID))
select array_agg(CustomerID), grp, count(*)
from nt
group by grp