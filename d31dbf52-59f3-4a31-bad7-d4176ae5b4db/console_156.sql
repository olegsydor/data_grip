create table trash.so_missed_account_md as
with base as (select x ->> 'key' as account_name, x ->> 'doc_count' as cnt
              from jsonb_array_elements((:in_json::jsonb #>> '{response,aggregations,by_account,buckets}')::jsonb) as x(f))
select ac.account_id, ac.account_name, base.cnt, '803 SEG80_EQT_RCS' as src
from dwh.d_account ac
         join base using (account_name)

insert into trash.so_missed_account_md
with base as (select x ->> 'key' as account_name, x ->> 'doc_count' as cnt
              from jsonb_array_elements((:in_json::jsonb #>> '{response,aggregations,by_account,buckets}')::jsonb) as x(f))
select ac.account_id, ac.account_name, base.cnt, '809 SEG80_ATS_RCS'
from dwh.d_account ac
         join base using (account_name)

select account_id, account_name, sum(cnt::int)
from trash.so_missed_account_md
group by account_id, account_name, src


select (:in_json::jsonb #>>'{response,aggregations,by_account,buckets}')::jsonb;

select * from dwh.d_account;

select distinct trading_firm_id from trash.so_missed_account_md
join dwh.d_account ac using(account_id)