select * from dash360.get_active_parent_gtc_orders('{23549,23548,23547,23546,23545,23544,23543,23542,23541,23540,23499,23498,23501,23500,23539,68230,68232,68233,68234,68235,68236,68406,68405,68231,68211,69219,61152,68280,19962,63844,19964,20917,20918,20919,14657,20955,20956,20957,20958,20959,20960,20961,20962,20963,20964,20965,20966,20967,20968,20969,24129,26961,26849,20970,20971,20972,20973,20997,20974,20975,20976,20977,20978,20998,21000,20979,32710,20980,20981,20999,20982,20983,20984,20985,20986,20987,20988,20989,20990,20991,20992,20993,20994,23651,23652,24869,20995,20996}');
select * from dash360.get_active_child_gtc_orders('{23549,23548,23547,23546,23545,23544,23543,23542,23541,23540,23499,23498,23501,23500,23539,68230,68232,68233,68234,68235,68236,68406,68405,68231,68211,69219,61152,68280,19962,63844,19964,20917,20918,20919,14657,20955,20956,20957,20958,20959,20960,20961,20962,20963,20964,20965,20966,20967,20968,20969,24129,26961,26849,20970,20971,20972,20973,20997,20974,20975,20976,20977,20978,20998,21000,20979,32710,20980,20981,20999,20982,20983,20984,20985,20986,20987,20988,20989,20990,20991,20992,20993,20994,23651,23652,24869,20995,20996}');



drop function if exists dash360.get_active_parent_gtc_orders;
CREATE OR REPLACE FUNCTION dash360.get_active_parent_gtc_orders(in_account_ids integer[] DEFAULT NULL::integer[])
    RETURNS TABLE
            (
                account_name   character varying,
                creation_date  timestamp without time zone,
                ord_status     character varying,
                sec_type       character,
                side           character,
                symbol         character varying,
                ex_dest        character varying,
                ord_qty        integer,
                ex_qty         numeric,
                ord_type       character,
                price          numeric,
                avg_px         numeric,
                lvs_qty        bigint,
                is_mleg        text,
                leg_id         character varying,
                open_close     character,
                dash_id        character varying,
                cl_ord_id      character varying,
                orig_cl_ord_id character varying,
                occ_data       text,
                osi_symbol     character varying,
                client_id      character varying,
                subsystem      character varying,
                strike_px      numeric,
                put_call       character,
                exp_year       smallint,
                exp_month      smallint,
                exp_day        smallint,
                order_id       bigint,
                sender_comp_id character varying
            )
    LANGUAGE plpgsql
AS
$function$
-- 2023-07-07 SO: https://dashfinancial.atlassian.net/browse/DS-6948 and https://dashfinancial.atlassian.net/browse/DS-6866
-- 2023-10-05 SO: https://dashfinancial.atlassian.net/browse/DS-7359 change client_id and ex_dest into human readable format
begin
    return query
        select ac.account_name              as account_name,
               cl.create_time               as creation_date,
               ors.order_status_description as ord_status,
               di.instrument_type_id        as sec_type,
               cl.side                      as side,
               di.symbol                    as symbol,
--                cl.ex_destination            as ex_dest,
               dex.ex_destination_code_name as ex_dest,
               cl.order_qty                 as ord_qty,
               exl.ex_qty,
               cl.order_type_id             as ord_type,
               cl.price                     as price,
               ex.avg_px                    as avg_px,
               ex.leaves_qty                as lvs_qty,
               case
                   when cl.multileg_reporting_type = '1' then 'N'
                   when cl.multileg_reporting_type = '2'
                       then 'Y' end         as is_mleg,
               leg.client_leg_ref_id        as leg_id,
               cl.open_close                as open_close,
               cl.dash_client_order_id      as dash_id,
               cl.client_order_id           as cl_ord_id,
               orig.client_order_id         as orig_cl_ord_id,
               fmj.t10441                   as occ_data,
               oc.opra_symbol               as osi_symbol,
--                dcl.client_id                as client_id,
               cl.client_id_text            as client_id,
               ss.sub_system_id             as subsystem,
               oc.strike_price              as strike_px,
               oc.put_call                  as put_call,
               oc.maturity_year             as exp_year,
               oc.maturity_month            as exp_month,
               oc.maturity_day              as exp_day,
               cl.order_id                  as order_id,
               fc.fix_comp_id               as sender_comp_id
        from dwh.gtc_order_status gtc
                 join dwh.client_order cl on cl.order_id = gtc.order_id and cl.create_date_id = gtc.create_date_id
                 join dwh.d_instrument di on di.instrument_id = cl.instrument_id
                 inner join dwh.d_account ac on (cl.account_id = ac.account_id)
                 left join dwh.client_order orig on (orig.order_id = cl.orig_order_id)
                 join lateral (select ex.exec_id as exec_id,
                                      ex.avg_px,
                                      ex.leaves_qty,
                                      ex.order_status
                               from dwh.execution ex
                               where gtc.order_id = ex.order_id
                                 and ex.order_status <> '3'
                                 and ex.exec_date_id >= gtc.create_date_id
                               order by ex.exec_time desc
                               limit 1) ex on true
                 inner join dwh.d_order_status ors on ors.order_status = ex.order_status
                 left join lateral (select sum(ex.last_qty) as ex_qty
                                    from dwh.execution ex
                                    where ex.exec_date_id >= gtc.create_date_id
                                      and ex.order_id = cl.order_id
                                      and ex.exec_type in ('F', 'G')
                                      and ex.is_busted = 'N'
                                    limit 1) exl on true
                 left join lateral (select fix_message ->> '10441' as t10441
                                    from fix_capture.fix_message_json fmj
                                    where fmj.fix_message_id = cl.fix_message_id
                                      and fmj.date_id = cl.create_date_id
                                    limit 1) fmj on true
                 left join dwh.d_option_contract oc on oc.instrument_id = cl.instrument_id
                 left join dwh.client_order_leg leg on leg.order_id = cl.order_id
                 left join dwh.d_sub_system ss on ss.sub_system_unq_id = cl.sub_system_unq_id
                 left join dwh.d_fix_connection fc on fc.fix_connection_id = cl.fix_connection_id
                 left join dwh.d_ex_destination_code dex on dex.ex_destination_code = cl.ex_destination and dex.is_acitive
                 left join dwh.d_client dcl on dcl.client_unq_id = cl.client_id
        where cl.parent_order_id is null
          and gtc.close_date_id is null
          and cl.trans_type in ('D', 'G')
          and cl.time_in_force_id in ('1', '6')
          and cl.multileg_reporting_type in ('1', '2')
          and case when coalesce(in_account_ids, '{}') = '{}' then true else gtc.account_id = any (in_account_ids) end
    order by gtc.order_id;
end;
$function$
;

select ex_destination_code, count(ex_destination_desc)
from dwh.d_ex_destination dex
where is_active
group by ex_destination_code
having count(ex_destination_desc) > 1


select * from dwh.d_ex_destination dex
where is_active
and ex_destination_code = 'GMNI'

select co.ex_destination_code_id, ex_destination_code, de.* from dwh.client_order co
join dwh.d_ex_destination de on --(de.ex_destination_code = co.ex_destination)
de.ex_destination_id = co.ex_destination_code_id
where ex_destination_desc = 'EDGX Options'
and ex_destination_code_id is not null

select cl.client_id, dc.* from dwh.client_order cl
join dwh.d_client dc on dc.client_unq_id = cl.client_id
where cl.client_id = 88600
and cl.create_date_id >= 20230101
limit 10


select * from dwh.d_client
where client_unq_id = 88600


select * from dwh.gtc_order_status
where close_date_id is null



drop FUNCTION dash360.get_active_child_gtc_orders;
CREATE OR REPLACE FUNCTION dash360.get_active_child_gtc_orders(in_account_ids integer[] DEFAULT NULL::integer[])
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
begin
    return query
        select ac.account_name              as account_name,
               cl.create_time               as creation_date,
               ors.order_status_description as ord_status,
               di.instrument_type_id        as sec_type,
               cl.side                      as side,
               di.symbol                    as symbol,
               exch.exchange_id             as exchange_id,
               exch.exchange_name           as ex_dest,
               exch.is_bdma                 as is_bdma,
               cl.order_qty                 as ord_qty,
               exl.ex_qty                   as ex_qty,
               cl.order_type_id             as ord_type,
               cl.price                     as price,
               ex.avg_px                    as avg_px,
               ex.leaves_qty                as lvs_qty,
               case
                   when cl.multileg_reporting_type = '1' then 'N'
                   when cl.multileg_reporting_type = '2'
                       then 'Y' end         as is_mleg,
               leg.client_leg_ref_id        as leg_id,
               cl.open_close                as open_close,
               cl.dash_client_order_id      as dash_id,
               cl.client_order_id           as cl_ord_id,
               orig.client_order_id         as orig_cl_ord_id,
               par.client_order_id          as parent_cl_ord_id,
               fmj.t10441                   as occ_data,
               oc.opra_symbol               as osi_symbol,
               cl.client_id_text            as client_id,
               dss.sub_system_id            as subsystem,
               oc.strike_price              as strike_px,
               oc.put_call                  as put_call,
               oc.maturity_year             as exp_year,
               oc.maturity_month            as exp_month,
               oc.maturity_day              as exp_day,
               cl.order_id                  as order_id,
               fc.fix_comp_id               as sender_comp_id
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
                 left join dwh.client_order orig
                           on (orig.order_id = cl.orig_order_id and orig.create_date_id <= cl.create_date_id)
                 left join lateral (select sum(ex.last_qty) as ex_qty
                                    from dwh.execution ex
                                    where ex.exec_date_id >= gtc.create_date_id
                                      and ex.order_id = cl.order_id
                                      and ex.exec_type in ('F', 'G')
                                      and ex.is_busted = 'N'
                                    limit 1) exl on true
                 left join dwh.client_order_leg leg on (leg.order_id = gtc.order_id)
                 left join lateral (select fix_message ->> '10441' as t10441
                                    from fix_capture.fix_message_json fmj
                                    where fmj.fix_message_id = cl.fix_message_id
                                      and fmj.date_id = cl.create_date_id
                                    limit 1) fmj on true
                 left join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id and oc.is_active)
                 left join dwh.d_sub_system dss on dss.sub_system_unq_id = par.sub_system_unq_id and dss.is_active
                 left join dwh.d_fix_connection fc on (cl.fix_connection_id = fc.fix_connection_id)
                 left join dwh.d_client dcl on dcl.client_unq_id = cl.client_id
        where true
          and cl.parent_order_id is not null
          and gtc.close_date_id is null
          and cl.trans_type in ('D', 'G')
          and cl.time_in_force_id in ('1', '6')
          and cl.multileg_reporting_type in ('1', '2')
          and case when coalesce(in_account_ids, '{}') = '{}' then true else gtc.account_id = any (in_account_ids) end
        order by gtc.order_id;
end;
$function$
;


select * from dwh.client_order cl
inner join lateral (select exch.exchange_id,
                                            exch.exchange_name,
                                            case when exch.exchange_id like '%ML' then 'Y' else 'N' end as is_bdma
                                     from dwh.d_exchange exch
                                     where exch.exchange_id = cl.exchange_id
                                       and exch.is_active
                                     limit 1) exch on true
where cl.exchange_id = 'GEMINI';



 select ac.account_name              as account_name,
               cl.create_time               as creation_date,
               ors.order_status_description as ord_status,
               di.instrument_type_id        as sec_type,
               cl.side                      as side,
               di.symbol                    as symbol,
               cl.exchange_id,
               exch.exchange_name           as ex_dest,
               cl.order_qty                 as ord_qty,
               exl.ex_qty,
               cl.order_type_id             as ord_type,
               cl.price                     as price,
               ex.avg_px                    as avg_px,
               ex.leaves_qty                as lvs_qty,
               case
                   when cl.multileg_reporting_type = '1' then 'N'
                   when cl.multileg_reporting_type = '2'
                       then 'Y' end         as is_mleg,
               leg.client_leg_ref_id        as leg_id,
               cl.open_close                as open_close,
               cl.dash_client_order_id      as dash_id,
               cl.client_order_id           as cl_ord_id,
               orig.client_order_id         as orig_cl_ord_id,
               fmj.t10441                   as occ_data,
               oc.opra_symbol               as osi_symbol,
               dcl.client_id                as client_id,
               ss.sub_system_id             as subsystem,
               oc.strike_price              as strike_px,
               oc.put_call                  as put_call,
               oc.maturity_year             as exp_year,
               oc.maturity_month            as exp_month,
               oc.maturity_day              as exp_day,
               cl.order_id                  as order_id,
               fc.fix_comp_id               as sender_comp_id
        from dwh.gtc_order_status gtc
                 join dwh.client_order cl on cl.order_id = gtc.order_id and cl.create_date_id = gtc.create_date_id
                 join dwh.d_instrument di on di.instrument_id = cl.instrument_id
                 inner join dwh.d_account ac on (cl.account_id = ac.account_id)
                 left join dwh.client_order orig on (orig.order_id = cl.orig_order_id)
                 join lateral (select ex.exec_id as exec_id,
                                      ex.avg_px,
                                      ex.leaves_qty,
                                      ex.order_status
                               from dwh.execution ex
                               where gtc.order_id = ex.order_id
                                 and ex.order_status <> '3'
                                 and ex.exec_date_id >= gtc.create_date_id
                               order by ex.exec_time desc
                               limit 1) ex on true
                 inner join dwh.d_order_status ors on ors.order_status = ex.order_status
left join lateral (select
                                            exch.exchange_name
                                     from dwh.d_exchange exch
                                     where exch.exchange_id = cl.exchange_id
                                       and exch.is_active
                                     limit 1) exch on true
                 left join lateral (select sum(ex.last_qty) as ex_qty
                                    from dwh.execution ex
                                    where ex.exec_date_id >= gtc.create_date_id
                                      and ex.order_id = cl.order_id
                                      and ex.exec_type in ('F', 'G')
                                      and ex.is_busted = 'N'
                                    limit 1) exl on true
                 left join lateral (select fix_message ->> '10441' as t10441
                                    from fix_capture.fix_message_json fmj
                                    where fmj.fix_message_id = cl.fix_message_id
                                      and fmj.date_id = cl.create_date_id
                                    limit 1) fmj on true
                 left join dwh.d_option_contract oc on oc.instrument_id = cl.instrument_id
                 left join dwh.client_order_leg leg on leg.order_id = cl.order_id
                 left join dwh.d_sub_system ss on ss.sub_system_unq_id = cl.sub_system_unq_id
                 left join dwh.d_fix_connection fc on fc.fix_connection_id = cl.fix_connection_id
--                  left join dwh.d_ex_destination dex on dex.ex_destination_code = cl.ex_destination and dex.is_active
                 left join dwh.d_client dcl on dcl.client_unq_id = cl.client_id
        where cl.parent_order_id is null
          and gtc.close_date_id is null
          and cl.trans_type in ('D', 'G')
          and cl.time_in_force_id in ('1', '6')
          and cl.multileg_reporting_type in ('1', '2')
 and gtc.account_id = any (:in_account_ids)


                 left join dwh.d_ex_destination_code edc
                           on edc.ex_destination_code = gtc.ex_destination and edc.is_acitive
select exch.exchange_name, *
from dwh.d_exchange exch
where exch.exchange_id = 'GEMINI'
  and exch.is_active;

select ex_destination_code, ex_destination_desc, *--count(*)
from dwh.d_ex_destination
where is_active
group by ex_destination_code, ex_destination_desc
having count(*) > 1



select exch.exchange_id,
       count(distinct exch.exchange_name)
--        case when exch.exchange_id like '%ML' then 'Y' else 'N' end as is_bdma
from dwh.d_exchange exch
where is_active
group by exch.exchange_id
having count(distinct exch.exchange_name) > 1