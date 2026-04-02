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
group by grp;

with client_groups as (select CustomerID,
                              cnt,
                              ntile(10) over (order by CustomerID, cnt) as grp
                       from (select CustomerID as CustomerID,
                                    count(*) as cnt
                             from billing.TBillingOrderDetail_Daily_inc
                             group by CustomerID) t)

select array_agg(distinct CustomerID), grp, sum(cnt)
from client_groups
group by grp