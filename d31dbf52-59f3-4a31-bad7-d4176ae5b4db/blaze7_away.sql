create
     or replace
    drop function staging.custom_format(in_numb numeric default null, in_len int default 8)
    returns text
    language plpgsql
as
$$
    -- SO 2024-07-20
    -- the function works like the select cast(cast(in_numb as float) as varchar(in_len)) in T-sql
    -- for numbers < 1 it returns .valuable_decimals_only like .123 without trailing zeros

declare
    l_int_part     int;
    l_int_part_len int;
    l_adj          int := 2; -- adjustment keeping in mind decimal point and\or something else
begin
    if in_numb is null then
        return null;
    end if;
    if in_numb < 1 then
        return to_char(in_numb, 'FM999.999999');
    end if;

    select floor(in_numb) into l_int_part;
    select char_length(l_int_part::text) into l_int_part_len;
    return round(in_numb, in_len - l_int_part_len - l_adj);
end;
$$;
comment on function staging.custom_format is 'The function is used in away_trade flow for cases when input number < 1 or >= 1';

select trade_record_time,
       date_id,
       subsystem_id,
       account_name,
       cl_ord_id,
       instrument_id,
       side,
       openclose,
       exec_id,
       exchange_id,
       liquidityindicator,
       secondary_order_id,
       exch_exec_id,
       secondary_exch_exec_id,
       case
           when last_mkt in ('CBOE-CRD NO BK', 'PAR', 'CBOIE') then 'W'
           when last_mkt in ('XPAR', 'PLAK', 'PARL') then 'LQPT'
           when last_mkt in ('SOHO', 'KNIGHT', 'LSCI', 'NOM') then 'ECUT'
           when last_mkt in ('FOGS', 'MID') then 'XCHI'
           when last_mkt in ('C2', 'CBOE2') then 'C2OX'
           when last_mkt = 'SMARTR' then 'COWEN'
           when last_mkt in ('ACT', 'BOE', 'OTC', 'lp', 'VOL') then 'BRKPT'
           when last_mkt in ('XPSE') then 'N'
           when last_mkt in ('TO') then '1'
           else last_mkt end                                                                      as last_mkt,
       lastshares,
       last_px,
       ex_destination,
       sub_strategy,
       order_id,

       coalesce(
               case
                   when
                       ct.expiration_date is not null and coalesce(ct.strike, 0.00) <> 0.00
                       then ct.opt_qty::numeric
                   else ct.eq_qty::numeric end,
               ct.eq_leaves_qty::numeric
       )                                                                                          as street_order_qty,
       multileg_reporting_type,
       ct.exec_broker,
       ct.cmtafirm,

       case
           when ct.tif in (24, 17, 10, 1, 44) then 0
           when ct.tif in (26, 18, 3, 45, 12) then 1
           when ct.tif in (31, 8, 15, 46) then 2
           when ct.tif in (47, 28, 11, 19, 5) then 3
           when ct.tif in (48, 2, 13, 25, 20) then 4
           when ct.tif in (36, 37, 38, 49) then 5
           when ct.tif in (50, 14, 21, 33) then 6
           when ct.tif in (32, 9, 16) then 7
           end                                                                                    as street_time_in_force,
       opt_customer_firm,
       CASE
           when ct.crossing_side = 'C' and ct.cross_cl_ord_id is not null then 'Y'
           when ct.crossing_side <> 'C' and ct.orig_cl_ord_id is not null then 'Y'
           else 'N'
           END                                                                                    as is_cross_order,
       contra_broker,
       order_price,
       order_process_time,
       remarks,
       is_busted,
       street_client_order_id,
       fix_comp_id,
       leaves_qty,
       leg_ref_id,
       case
           when ct.orig_order_id is not null then 26
           when ct.contra_order_id is not null then 26
           when ct.parent_order_id is not null then 10
           when ct.parent_order_id is null and ct.last_child_order is not null then 10
           when rep_comment like '%OVR%' then 4
           else 50 end                                                                            as strategy_decision_reason_code,
       is_parent,
       symbol,
       strike_price,
       case ct.type_code
           when 'P' then '0'
           when 'C' then '1'
           end                                                                                    as put_or_call,
       extract(year from ct.expiration_date)                                                      as maturity_year,
       extract(month from ct.expiration_date)                                                     as maturity_month,
       extract(day from ct.expiration_date)                                                       as maturity_day,
       ct.securitytype                                                                            as security_type,
       ct.child_orders,
       ct.handling                                                                                as handling_id,
       ct.secondary_order_id2,

-- display_instrument_id
       ---
       ct.rootcode,
       ct.typecode,
ct.expiration_date,
ct.strike_price,
regexp_replace(coalesce(ct.rootcode, ''), '\.|-', '', 'g'),
       --
       case
           when ct.expiration_date is not null and ct.strike_price is not null then
               replace(coalesce(
                               regexp_replace(coalesce(ct.rootcode, ''), '\.|-', '', 'g') || ' ' ||
                               to_char(ct.expiration_date::date, 'DDMonYY') || ' ' ||
                               staging.custom_format(ct.strike_price) ||
                               left(ct.typecode, 8),
                               case
                                   when ct.ord_ContractDesc not like ct.basecode || ' %'
                                       then ct.basecode || ' ' || REPLACE(ct.ord_ContractDesc, ct.BaseCode, '')
                                   when ct.legcount::int = 1 and ct.typecode = 'S' then ct.ord_ContractDesc || ' Stock'
                                   when ct.ord_ContractDesc not like ' %' then ct.ord_ContractDesc || ' '
                                   else ct.ord_ContractDesc end
                       ), '/', '')
           else
               regexp_replace(coalesce(ct.rootcode, ''), '\.|-', '', 'g')
           end                                                                                    as display_instrument_id,
       case when ct.expiration_date is not null and ct.strike_price is not null then 'O' else 'E' end as instrument_type_id,
       regexp_replace(coalesce(ct.basecode, ''), '\.|-', '', 'g')                                 as activ_symbol,
       case when ct.orderreportspecialtype = 'M' then 1 else 0 end                                as is_sor_routed,
	(case
        when lag(ct.companyname,1) over (partition by ct.ExchangeTransactionID order by ct.generation) <> ct.companyname
         and lag(ct.OrderID,1) over (partition by ct.ExchangeTransactionID order by ct.generation) = ct.ParentORdeRID  then 1
        else 0
    end ) as is_company_name_changed,
    ct.companyname,
    ct.generation,
    max(ct.generation) over (partition by ct.ExchangeTransactionID) mx_gen,
    sum(ct.is_company_name_changed) over (partition by secondary_exch_exec_id) as num_firms
--        ''
from staging.v_away_trade_query ct;


  select
      trade_record_time,
      db_create_time,
      date_id,
      'to perform' as is_busted,
      'LPEDW'                                                                as subsystem_id,
      aw.user_id,
       case
           when coalesce(us.AORS_Username, us.user_Login) = 'BBNTRST' then 'NTRSCBOE'
           else coalesce(us.AORS_Username, us.user_Login) end                           as account_name,

             case
           when aw.expiration_date is not null and aw.strike_price is not null then
               replace(coalesce(
                               regexp_replace(coalesce(aw.rootcode, ''), '\.|-', '', 'g') || ' ' ||
                               to_char(aw.expiration_date::date, 'DDMonYY') || ' ' ||
                               staging.trailing_dot(aw.strike_price) ||
                               left(aw.typecode, 8),
                               case
                                   when aw.ord_ContractDesc not like aw.basecode || ' %'
                                       then aw.basecode || ' ' || REPLACE(aw.ord_ContractDesc, aw.BaseCode, '')
                                   when aw.legcount::int = 1 and aw.typecode = 'S' then aw.ord_ContractDesc || ' Stock'
                                   when aw.ord_ContractDesc not like ' %' then aw.ord_ContractDesc || ' '
                                   else aw.ord_ContractDesc end
                       ), '/', '')
           else
               regexp_replace(coalesce(aw.rootcode, ''), '\.|-', '', 'g')
           end                                                                                    as display_instrument_id
      ,
      aw.status,
      * from staging.v_away_trade aw
        left join staging.T_Users us on us.user_id = aw.user_id
  where true
  and cl_ord_id in ('1_65240605','1_2b8240605','1_254240617','1_3c6240617','1_16o240626')
  and order_id in (652865815179165700,
652934019335323648,
657283755907481600,
657302344068759552,
657302260082016256,
660511556445929472
)
    and status in ('1', '2')
--   and order_id = 657302260082016256
  and cl_ord_id in ('1_16o240626')

