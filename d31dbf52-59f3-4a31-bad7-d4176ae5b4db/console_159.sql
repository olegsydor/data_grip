-- DROP FUNCTION dash360.get_active_child_gtc_orders(_int4, int4, int4, _varchar);

CREATE OR REPLACE FUNCTION dash360.get_active_child_gtc_orders(in_account_ids integer[] DEFAULT NULL::integer[],
                                                             in_start_date_id integer DEFAULT (to_char((CURRENT_DATE)::timestamp with time zone, 'YYYYMMDD'::text))::integer,
                                                             in_end_date_id integer DEFAULT (to_char((CURRENT_DATE)::timestamp with time zone, 'YYYYMMDD'::text))::integer,
                                                             in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[])
    RETURNS TABLE
            (
                account_name     character varying,
                creation_date    timestamp without time zone,
                ord_status       character varying,
                sec_type         character,
                side             character,
                symbol           character varying,
                exchange_id      character varying,
                ex_dest          character varying,
                is_bdma          text,
                ord_qty          integer,
                ex_qty           numeric,
                ord_type         character,
                price            numeric,
                avg_px           numeric,
                lvs_qty          bigint,
                is_mleg          text,
                leg_id           character varying,
                open_close       character,
                dash_id          character varying,
                cl_ord_id        character varying,
                orig_cl_ord_id   character varying,
                parent_cl_ord_id character varying,
                occ_data         text,
                osi_symbol       character varying,
                client_id        character varying,
                subsystem        character varying,
                strike_px        numeric,
                put_call         character,
                exp_year         smallint,
                exp_month        smallint,
                exp_day          smallint,
                order_id         bigint,
                sender_comp_id   character varying
            )
    LANGUAGE plpgsql
AS
$function$
    -- 2023-07-07 SO: https://dashfinancial.atlassian.net/browse/DS-6948 and https://dashfinancial.atlassian.net/browse/DS-6866
-- 2023-10-05 SO: https://dashfinancial.atlassian.net/browse/DS-7359 change client_id and ex_dest into human readable format
-- 2024-01-17 SO: https://dashfinancial.atlassian.net/browse/DEVREQ-3910 added start_date_id and end_date_id
-- 2024-03-05 MB: https://dashfinancial.atlassian.net/browse/DS-7709 commented useless left join to d_client, we already use client_id_text from cl
-- 2024-05-09 SO: https://dashfinancial.atlassian.net/browse/DEVREQ-4264 added in_trading_firm_ids
-- 2024-05-28 SO: https://dashfinancial.atlassian.net/browse/DEVREQ-4264 added coalesce(trading_firm\account, '{})
-- 2026-01-29 SO: https://dashfinancial.atlassian.net/browse/DS-11029 performance improvement

declare
    l_row_cnt         int4;
    l_load_id         int;
    l_step_id         int;
    l_is_current_date bool := false;
    l_account_ids     int4[];
    l_min_gtc_date_id int4;
begin
    if in_start_date_id = in_end_date_id and in_start_date_id = to_char(current_date, 'YYYYMMDD')::int4 then
        l_is_current_date = true;
    end if;

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'get_active_child_gtc_orders for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED===',
                           0, 'O')
    into l_step_id;

    if coalesce(in_account_ids, '{}') = '{}' and coalesce(in_trading_firm_ids, '{}') = '{}' then
        l_account_ids := '{}';
    else
        select array_agg(account_id)
        into l_account_ids
        from dwh.d_account
        where true
          and case
                  when coalesce(in_trading_firm_ids, '{}') <> '{}'::varchar[]
                      then trading_firm_id = ANY (in_trading_firm_ids)
                  else true end
          and case
                  when coalesce(in_account_ids, '{}') <> '{}'::integer[] then account_id = ANY (in_account_ids)
                  else true end;
    end if;

    drop table if exists t_base;
    create temp table if not exists t_base as
    select ac.account_name,
           cl.create_time,
           ors.order_status_description,
           di.instrument_type_id,
           cl.side,
           di.symbol,
           exch.exchange_id,
           exch.exchange_name,
           exch.is_bdma,
           cl.order_qty,
           cl.order_type_id,
           cl.price,
           ex.avg_px,
           ex.leaves_qty,
           cl.multileg_reporting_type,
           cl.open_close,
           cl.dash_client_order_id,
           cl.client_order_id,
           par.client_order_id as par_client_order_id,
           cl.client_id_text,
           cl.order_id,
           gtc.create_date_id,
           cl.instrument_id,
           par.sub_system_unq_id,
           cl.fix_connection_id,
           cl.orig_order_id,
           cl.fix_message_id
    from dwh.gtc_order_status gtc
             join dwh.client_order cl on cl.order_id = gtc.order_id and cl.create_date_id = gtc.create_date_id and
                                         cl.parent_order_id is not null
             join dwh.d_account ac on gtc.account_id = ac.account_id
             join dwh.d_instrument di on di.instrument_id = cl.instrument_id and di.is_active
             inner join dwh.client_order par
                        on (cl.parent_order_id = par.order_id and par.create_date_id <= gtc.create_date_id)
             join lateral (select ex.exec_id as exec_id
                           from dwh.execution ex
                           where gtc.order_id = ex.order_id
                             and ex.order_status <> '3'
                             and ex.exec_date_id >= gtc.create_date_id
                           order by ex.exec_id desc
                           limit 1) gtex on true
             inner join lateral (select ex.avg_px, ex.last_px, ex.leaves_qty, ex.order_status
                                 from dwh.execution ex
                                 where ex.exec_id = gtex.exec_id
                                   and ex.exec_date_id >= gtc.create_date_id
                                 limit 1) ex on true
             join dwh.d_order_status ors on ors.order_status = ex.order_status
             inner join lateral (select exch.exchange_id,
                                        exch.exchange_name,
                                        case when exch.exchange_id like '%ML' then 'Y' else 'N' end as is_bdma
                                 from dwh.d_exchange exch
                                 where exch.exchange_id = cl.exchange_id
                                   and exch.is_active
                                 limit 1) exch on true
    where true
      and cl.parent_order_id is not null
      and gtc.create_date_id <= in_start_date_id
      and (gtc.close_date_id is null
        -- the code below has been added to provide the same performance in the case we use the report for CURRENT date
        or (case
                when l_is_current_date then false
                else gtc.close_date_id is not null and close_date_id > in_end_date_id end))
      -- end of
      and cl.trans_type in ('D', 'G')
      and cl.time_in_force_id in ('1', '6')
      and cl.multileg_reporting_type in ('1', '2')
      and case when l_account_ids = '{}' then true else gtc.account_id = any (l_account_ids) end;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'get_active_child_gtc_orders for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' the base table is calculated',
                           l_row_cnt, 'O')
    into l_step_id;


    select min(create_date_id)
    into l_min_gtc_date_id
    from t_base;

    drop table if exists t_final;
    create temp table t_final as
    select t_base.account_name             as account_name,
           t_base.create_time              as creation_date,
           t_base.order_status_description as ord_status,
           t_base.instrument_type_id       as sec_type,
           t_base.side                     as side,
           t_base.symbol                   as symbol,
           t_base.exchange_id              as exchange_id,
           t_base.exchange_name            as ex_dest,
           t_base.is_bdma                  as is_bdma,
           t_base.order_qty                as ord_qty,
           exl.ex_qty                      as ex_qty,
           t_base.order_type_id            as ord_type,
           t_base.price                    as price,
           t_base.avg_px                   as avg_px,
           t_base.leaves_qty               as lvs_qty,
           case
               when t_base.multileg_reporting_type = '1' then 'N'
               when t_base.multileg_reporting_type = '2'
                   then 'Y' end            as is_mleg,
           leg.client_leg_ref_id           as leg_id,
           t_base.open_close               as open_close,
           t_base.dash_client_order_id     as dash_id,
           t_base.client_order_id          as cl_ord_id,
           orig.client_order_id            as orig_cl_ord_id,
           t_base.par_client_order_id      as parent_cl_ord_id,
           fmj.t10441                      as occ_data,
           oc.opra_symbol                  as osi_symbol,
           t_base.client_id_text           as client_id,
           dss.sub_system_id               as subsystem,
           oc.strike_price                 as strike_px,
           oc.put_call                     as put_call,
           oc.maturity_year                as exp_year,
           oc.maturity_month               as exp_month,
           oc.maturity_day                 as exp_day,
           t_base.order_id                 as order_id,
           fc.fix_comp_id                  as sender_comp_id
    from t_base
             left join dwh.client_order orig
                       on (orig.order_id = t_base.orig_order_id and orig.create_date_id <= t_base.create_date_id)
             left join lateral (select sum(ex.last_qty) as ex_qty
                                from dwh.execution ex
                                where ex.exec_date_id >= t_base.create_date_id
                                  and ex.order_id = t_base.order_id
                                  and ex.exec_type in ('F', 'G')
                                  and ex.is_busted = 'N'
                                  and ex.exec_date_id >= l_min_gtc_date_id
                                limit 1) exl on true
             left join dwh.client_order_leg leg on (leg.order_id = t_base.order_id)
             left join lateral (select fix_message ->> '10441' as t10441
                                from fix_capture.fix_message_json fmj
                                where fmj.fix_message_id = t_base.fix_message_id
                                  and fmj.date_id = t_base.create_date_id
                                  and fmj.date_id >= l_min_gtc_date_id
                                limit 1) fmj on true
             left join dwh.d_option_contract oc on (oc.instrument_id = t_base.instrument_id and oc.is_active)
             left join dwh.d_sub_system dss on dss.sub_system_unq_id = t_base.sub_system_unq_id and dss.is_active
             left join dwh.d_fix_connection fc on (t_base.fix_connection_id = fc.fix_connection_id)
    --left join dwh.d_client dcl on dcl.client_unq_id = cl.client_id
    where true;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'get_active_child_gtc_orders for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' the final base table is calculated',
                           l_row_cnt, 'O')
    into l_step_id;
    create index on t_final (order_id);

    return query
        select *
        from t_final
        order by order_id;

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'get_active_child_gtc_orders for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' FINISHED===',
                           l_row_cnt, 'O')
    into l_step_id;
end;
$function$
;
drop table t_os;
create table t_os as
select 'new' as inst, * from trash.get_active_child_gtc_orders(in_start_date_id := 20260128, in_end_date_id := 20260129, in_trading_firm_ids := '{abnnv,aostb01,bmonblt}');

insert into t_os
select 'old', * from dash360.get_active_child_gtc_orders(in_start_date_id := 20260128, in_end_date_id := 20260129, in_trading_firm_ids := '{abnnv,aostb01,bmonblt}')



select *
from trash.get_active_child_gtc_orders(in_start_date_id := 20260128, in_end_date_id := 20260129,
                                       in_trading_firm_ids := '{hudson02,ingalls01,lightsp01}')
except
select *
from dash360.get_active_child_gtc_orders(in_start_date_id := 20260128, in_end_date_id := 20260129,
                                         in_trading_firm_ids :=  '{hudson02,ingalls01,lightsp01}');


select * from t_os
where order_id = 100000020091614011

select * from dwh.d_account where d_account.account_name = '5CG06139';

select trading_firm_id, count(*)
from dwh.gtc_order_status gtc
join dwh.d_account ac on ac.account_id = gtc.account_id
where close_date_id is null
group by trading_firm_id            ;

select account_name, creation_date, ord_status, sec_type, side, symbol, exchange_id, ex_dest, is_bdma, ord_qty,
 ex_qty, ord_type, price, avg_px, lvs_qty, is_mleg, leg_id, open_close, dash_id, cl_ord_id, orig_cl_ord_id,
 parent_cl_ord_id, occ_data, osi_symbol, client_id, subsystem, strike_px, put_call, exp_year, exp_month, exp_day,
 order_id, sender_comp_id
from t_os
where inst = 'old'
except
select account_name, creation_date, ord_status, sec_type, side, symbol, exchange_id, ex_dest, is_bdma, ord_qty,
 ex_qty, ord_type, price, avg_px, lvs_qty, is_mleg, leg_id, open_close, dash_id, cl_ord_id, orig_cl_ord_id,
 parent_cl_ord_id, occ_data, osi_symbol, client_id, subsystem, strike_px, put_call, exp_year, exp_month, exp_day,
 order_id, sender_comp_id
from t_os
where inst = 'new'

select * from dash360.get_active_parent_gtc_orders(in_start_date_id := 20260128, in_end_date_id := 20260129, in_trading_firm_ids := '{bnparibas,bnplon,caceisb01,cicmarch,clearprim}')
select * from dash360.get_active_parent_gtc_orders(in_start_date_id := 20260128, in_end_date_id := 20260129)

select *
from dash360.get_active_child_gtc_orders(
        in_account_ids := '{26470,26472,26474,26475,26476,26478,26479,26480,26481,26482,26483,26486,26488,26491,26150,26494,26496,26497,26498,26499,26501,29694,30409,30710,30712,30713,26371,26372,26373,26374,26375,53666,56714,29139,26151,26376,26377,26378,26379,26380,26381,26382,26383,26384,26385,26386,26387,26388,26389,26390,26391,26392,26393,26394,26395,26396,26397,26398,26400,26401,26402,26404,26406,26407,26408,26409,26411,26412,26414,26270,26415,26417,26420,26421,26423,26425,26427,26429,26431,26433,26434,26435,26436,26437,26438,26440,26441,26443,26444,26445,26446,26448,26450,26452,26453,26455,26457,26459,26461,26462,26463,26464,26466,26467,26468,29142,26506,26508,26510,26512,26513,26515,26517,26209,26271,26522,26526,26528,26530,26272,26532,26533,26535,26536,26538,26273,26543,26544,26546,26549,29135,26551,26554,26556,26557,26558,26559,26561,26563,26564,26565,26566,26569,26571,26573,26575,26577,26579,26581,26274,26583,26584,26585,26586,26587,26588,26589,26590,26591,26592,26593,26594,26595,26596,26597,26598,26599,26600,26601,26602,26603,26275,26604,26605,26606,26607,26608,26609,26610,26611,26612,26613,26614,26615,26616,26617,26636,26637,26269,26638,26639,26640,26641,26642,26643,26644,26645,26646,29623,26647,26649,26648,26650,26653,26651,26655,26657,49525,26659,26661,26276,26663,26665,26666,26668,26669,26671,26674,26676,26675,26678,26679,26681,26683,26685,26686,26687,26689,26691,26618,26619,26620,26621,26622,26623,26624,26625,26626,26627,26628,26629,26630,26631,26632,26633,26634,26635,26733,26732,26731,26277,26730,29212,26729,26728,26727,26726,26725,26724,26723,26722,26721,26720,26719,26718,26717,26716,26715,26714,26713,26712,26711,26710,26709,26708,26707,26706,26705,26704,26703,26702,26701,26700,26699,26698,26697,26696,26695,26694,26693,26692,26690,26688,26684,29140,26682,26680,26278,26677,26673,26672,26670,26667,26664,26662,26660,26658,26656,26654,26652,26405,26399,26410,26403,26413,26416,26418,26419,26422,26424,26426,26428,26430,26432,26439,26442,26447,26449,26451,26454,26456,26458,26460,26465,26469,26471,26473,26477,26484,26485,26487,26489,26490,26492,26493,26495,26500,26504,26505,26507,26509,26511,26514,26516,26518,26519,26520,26521,26523,26524,26525,26527,26529,26531,26534,26537,26539,26540,26541,26542,26545,26547,26548,26550,26552,26553,26555,26560,26562,26580,26567,26568,26570,26572,26574,26576,26578,29141,26582,29089,28690,28689,29136,29131,29137,29132,29133,29134,29849,29138,29217,29218,29219,29569,29434,29570,30370,30030,30031,30511,30150,30249,30250,30429,30430,30431,30711,31309,32489,32329,35996,31551,34249,32269,32949,38416,32769,32950,33029,32951,32952,34129,33992,33629,33993,34250,34592,34656,35389,35390,35450,36049,35592,36051,36050,36655,37873,37874,37875,37876,38415,38475,38476,50282,50241,38541,38929,38930,38931,38932,38933,38913,49780,49781,51385,49881,49923,49924,49925,50084,50083,51383,51384,51381,51382,51542,51902,52468,52201,52469,52464,52465,52466,52467,52543,52544,53767,53768,53276,53277,53278,53161,53462,53463,53275,53465,53464,53466,53492,53611,53493,53612,53977,53707,53978,53948,53949,53950,53979,54242,54243,54088,54089,54090,54091,54092,54241,54329,54495,54330,54331,54496,54497,54620,54621,54622,54623,54624,54772,54908,54909,55112,55113,55460,55461,55459,55414,55614,55674,57952,55874,56474,56475,56476,56715,56835,57175,56713,56712,56998,57336,57337,57338,57339,57340,57341,57133,56999,57000,57134,57176,57342,57612,57613,57917,57916,57918,58431,58380,58381,58382,58432,58613,58537,58933,58934,58594,58773,58774,58775,59050,59051,59070,58929,59049,58930,59052,59053,59789,59933,60090,59947,59948,60149,60089,60150,61129,61130,26502,26503,36180,36150}',
        in_start_date_id := 20260130, in_end_date_id := 20260130, in_trading_firm_ids := '{}')