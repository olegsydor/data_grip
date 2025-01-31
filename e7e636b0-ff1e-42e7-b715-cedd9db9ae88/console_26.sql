--https://www.finra.org/rules-guidance/rulebooks/corporate-organization/section-1-member-regulatory-fees
--* Trading Activity Fee rates are as follows: Each member shall pay to FINRA: (1) $0.000166 per share for each sale of a covered equity security,
--with a maximum charge of $8.30 per trade; (2) $0.00279 per contract for each sale of an option; (3) $0.00011 per contract for each round turn
--transaction of a security future, provided there is a minimum charge of $0.014 per round turn transaction; (4) $0.00105 per bond for each sale
--of a covered TRACE-Eligible Security (other than an Asset-Backed Security) and/or municipal security, with a maximum charge of $1.05 per trade;
-- and (5) $0.00000105 times the value, as reported to TRACE, of a sale of an Asset-Backed Security, with a maximum charge of $1.05 per trade.
--In addition, if the execution price for a covered security is less than the Trading Activity Fee rate ($0.000166 for covered equity securities,
--$0.00279 for covered option contracts, or $0.014 for a security future) on a per share, per contract, or round turn transaction basis then no fee will be assessed.
select extract(year from to_date(cast(dtr.date_id as text), 'YYYYMMDD'))  as year
     , extract(month from to_date(cast(dtr.date_id as text), 'YYYYMMDD')) as month
     , dtr.date_id
     , dtr.instrument_type_id
     , dtr.trading_firm_id
     , tf.trading_firm_name
     , tf.cat_crd
     , dtr.side
--,array_agg(idl.imid) as cat_imids
     , a.broker_dealer_mpid
     , a.is_broker_dealer
     , array_agg(distinct idl.finra_member)                               as cat_finra_member
     , array_agg(distinct idl.exchange_id)                                as cat_exchange_finra
     , array_agg(distinct idl.file_date_id)                               as cat_file_date_id
     , sum(dtr.last_qty)                                                  as last_qty
--this case statement is used to hardcode firms that we know have the wrong is finra member  in this dataset
     , case
           when lower(dtr.trading_firm_id) in
                ('aostb01', 'chapdel', 'deutsche', 'elevation', 'eroom01', 'ftrust', 'haywood01', 'meridian',
                 'ofp0055', 'ofp0048', 'rwbaird01', 'srtamex', 'sunrise01', 'tdsec', 'tfsnova', 'triadsc01',
                 'coexparis', 'wexats')
               then '{Y}'
           when lower(dtr.trading_firm_id) in
                ('3ifund', '3ifund2', 'buckpac', 'caceisb01', 'ctcht', 'dftdesk04', 'dftdesk03', 'dashdesk',
                 'dftdesk02',
                 'famco01', 'grponeht', 'hudson02', 'ionicap02', 'janestht', 'murchnsn2', 'opcoht', 'peak6ht',
                 'sarasindf', 'schafer01', 'sfght',
                 'sgcap02', 'socgenlon', 'tornoht', 'ofp0132', 'wiltrht', 'wolvrnht')
               then '{N}'
           else array_agg(distinct idl.finra_member)
    end                                                                   as Corrected_Is_FINRA_Member
--designate trading firms with incorrect imid as finra members and therefore 0 fees
     , case
           when lower(dtr.trading_firm_id) in
                ('aostb01', 'chapdel', 'deutsche', 'elevation', 'eroom01', 'ftrust', 'haywood01', 'meridian',
                 'ofp0055', 'ofp0048', 'rwbaird01', 'srtamex', 'sunrise01', 'tdsec', 'tfsnova', 'triadsc01',
                 'coexparis', 'wexats')
               then 0
    -------------------------------------beginning of 2024 fees
           when dtr.date_id >= '20240101' and dtr.instrument_type_id = 'O'
               and lower(dtr.trading_firm_id) in
                   ('3ifund', '3ifund2', 'buckpac', 'caceisb01', 'ctcht', 'dftdesk04', 'dftdesk03', 'dashdesk',
                    'dftdesk02',
                    'famco01', 'grponeht', 'hudson02', 'ionicap02', 'janestht', 'murchnsn2', 'opcoht', 'peak6ht',
                    'sarasindf', 'schafer01', 'sfght',
                    'sgcap02', 'socgenlon', 'tornoht', 'ofp0132', 'wiltrht', 'wolvrnht')
               then sum(dtr.last_qty) * .00279
           when dtr.date_id >= '20240101' and dtr.instrument_type_id = 'E' and dtr.side <> '1'
               and lower(dtr.trading_firm_id) in
                   ('3ifund', '3ifund2', 'buckpac', 'caceisb01', 'ctcht', 'dftdesk04', 'dftdesk03', 'dashdesk',
                    'dftdesk02',
                    'famco01', 'grponeht', 'hudson02', 'ionicap02', 'janestht', 'murchnsn2', 'opcoht', 'peak6ht',
                    'sarasindf', 'schafer01', 'sfght',
                    'sgcap02', 'socgenlon', 'tornoht', 'ofp0132', 'wiltrht', 'wolvrnht')
               then sum(dtr.last_qty) * .000166
    --adjustment for trading firms using DFIN that are not FINRA BDs and should have fees assessed for 2023 equities
           when dtr.date_id >= '20240101' and dtr.instrument_type_id = 'O' and
                array_agg(distinct idl.finra_member) <> '{Y}' and dtr.side <> '1'
               then sum(dtr.last_qty) * .00279
--show the calculation for all equity trades. House DVP and client DVP charges will need to be replaced with allocation based calculations.
           when dtr.date_id >= '20240101' and dtr.instrument_type_id = 'E' and
                array_agg(distinct idl.finra_member) <> '{Y}' and dtr.side <> '1'
               then sum(dtr.last_qty) * .000166
    end                                                                   as Option_and_Equity_TAF_Charges
from genesis2.billing.dash_trade_record dtr
         left outer join genesis2.genesis2.account a on dtr.account_id = a.account_id and a.is_deleted = 'N'
    --left outer join genesis2.genesis2.clearing_account ca      on dtr.account_id = ca.account_id and ca.is_deleted = 'N'
         left outer join genesis2.genesis2.trading_firm tf on dtr.trading_firm_id = tf.trading_firm_id
    --left outer join temp_cat on temp_cat.crdid = tf.cat_crd
         left join lateral (select idl.crdid, idl.firm_name, idl.finra_member, idl.exchange_id, idl.file_date_id
                            from genesis2.external_data.imid_daily_list idl
                            where tf.cat_crd = idl.crdid
                              and idl.exchange_id = 'FINRA'
                              and dtr.date_id >= idl.file_date_id
                            order by idl.file_date_id desc
                            limit 1
    )
    as idl on true
--	and idl.exchange_id = 'FINRA'
--	and idl.is_deleted = 'N'
--	and date(dtr.trade_record_time) >= date(idl.start_date)
--	and (idl.end_date is null or date(dtr.trade_record_time) <= date(idl.end_date))
where dtr.date_id >= 20241101
  and dtr.date_id < 20241201
  and dtr.is_busted = 'N'
  and dtr.side <> '1'
  and upper(dtr.subsystem_id) not in ('LPEDW', 'LPEDW_DUPE')
  and upper(dtr.subsystem_id) not like ('OMS_EDW%')
  and upper(dtr.fix_comp_id) not in ('TRAFIXALGOINT_NY', 'TRAFIXCROSS_NY')
  and upper(dtr.symbol) not in
      ('ASBAG', 'BJE', 'BKX', 'BKX', 'BTK', 'BYTX', 'CRX', 'CZH', 'DDX', 'DFI', 'DFX', 'DIVD', 'DJX',
       'DRG', 'DXL', 'EPX', 'EWF', 'GUO', 'HGX', 'HKO', 'INDU', 'INDUDL', 'JBV', 'JLO', 'KBK', 'KIX', 'KRX', 'KSX',
       'MID', 'MNX', 'MRUT', 'MSH', 'MXEA', 'MXEF', 'NANOS', 'NBI', 'NDX', 'NDX', 'NDXDL', 'NDXP', 'NDXQ', 'NDXW',
       'NDXX',
       'NDXY', 'NQX', 'NQX', 'NYFANG', 'OEX', 'OEX', 'OEXM', 'OEXQ', 'OSX', 'OSX', 'PGG', 'QGRI', 'RAV', 'RIY', 'RLG',
       'RLV',
       'RMC', 'ROY', 'RRY', 'RTY', 'RUJ', 'RUO', 'RUT', 'RUTQ', 'RUTW', 'RUY', 'SIXB', 'SIXC', 'SIXE', 'SIXI', 'SIXM',
       'SIXR',
       'SIXRE', 'SIXT', 'SIXU', 'SIXV', 'SIXY', 'SML', 'SOX', 'SOX', 'SPIKE', 'SPX', 'SPX', 'SPXPM', 'SPXQ', 'SPXQ',
       'SPXW',
       'UTY', 'UTY', 'VIX', 'VIXQ', 'VIXW', 'VOLQ', 'XAL', 'XAU', 'XAU', 'XBD', 'XCI', 'XEO', 'XEO', 'XEOQ', 'XMI',
       'XND', 'XNDX',
       'XSP', 'XSP', 'XSPQ')
  and upper(dtr.exchange_id) not in ('BLAZE', 'TRAFX', 'C1PAR', 'PHLXFB', 'XCHI', 'BLAZEE',
                                     'BRKPT', 'BRKPTE', 'SQHA', 'SQHT', 'JSEB', 'CTDL', 'BRKPT', 'AMXO')
  and upper(dtr.trading_firm_id) <> 'RFABOXQOO'
group by dtr.date_id
       , dtr.instrument_type_id
       , dtr.trading_firm_id
       , tf.trading_firm_name
       , tf.cat_crd
       , dtr.side
       , a.broker_dealer_mpid
       , a.is_broker_dealer

create index if not exists imid_daily_list_crdid_exchange_id_idx on external_data.imid_daily_list (crdid,exchange_id);


create function dash360.report_billing_taf_fee_calculation(in_start_date_id int4,
                                                           in_end_date_id int4)
    returns table
            (
                ret_row text
            )
    language plpgsql
AS
$fn$
    -- 2025-01-30 OS https://dashfinancial.atlassian.net/browse/DEVREQ-5351
declare
    l_load_id int;
    l_step_id int;
    l_row_cnt int;
    l_list_1  text[] := '{aostb01, chapdel, deutsche, elevation, eroom01, ftrust, haywood01, meridian, ofp0055,
                 ofp0048, rwbaird01, srtamex, sunrise01, tdsec, tfsnova, triadsc01, coexparis, wexats}'::text[];
    l_list_2  text[] := '{3ifund, 3ifund2, buckpac, caceisb01, ctcht, dftdesk04, dftdesk03, dashdesk,
                 dftdesk02, famco01, grponeht, hudson02, ionicap02, janestht, murchnsn2, opcoht,
                 peak6ht, sarasindf, schafer01, sfght, sgcap02, socgenlon, tornoht, ofp0132, wiltrht,
                 wolvrnht}'::text[];

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, 'report_billing_taf_fee_calculation for ' || in_start_date_id::text ||
                                                 '-' || in_end_date_id::text || ' STARTED ====', 0, 'O')
    into l_step_id;

    return query
        select array_to_string(ARRAY [
                                   substr(date_id::text, 1, 4), -- as year,
                                   substr(date_id::text, 5, 2), --as month,
                                   dtr.date_id::text,
                                   dtr.instrument_type_id,
                                   dtr.trading_firm_id,
                                   tf.trading_firm_name,
                                   tf.cat_crd,
                                   dtr.side,
--,array_agg(idl.imid) as cat_imids
                                   a.broker_dealer_mpid,
                                   a.is_broker_dealer,
                                   array_agg(distinct idl.finra_member)::text, --as cat_finra_member,
                                   array_agg(distinct idl.exchange_id)::text, --as cat_exchange_finra,
                                   array_agg(distinct idl.file_date_id)::text, --as cat_file_date_id,
                                   sum(dtr.last_qty)::text, --as last_qty,
--this case statement is used to hardcode firms that we know have the wrong is finra member  in this dataset
                                   case
                                       when lower(dtr.trading_firm_id) = any (l_list_1)
                                           then '{Y}'::text
                                       when lower(dtr.trading_firm_id) = any (l_list_2) then '{N}'::text
                                       else array_agg(distinct idl.finra_member)::text end, --as Corrected_Is_FINRA_Member
--designate trading firms with incorrect imid as finra members and therefore 0 fees
                                   case
                                       when lower(dtr.trading_firm_id) = any (l_list_1)
                                           then 0::text
                                       -------------------------------------beginning of 2024 fees
                                       when dtr.date_id >= '20240101' and dtr.instrument_type_id = 'O'
                                           and lower(dtr.trading_firm_id) = any (l_list_2)
                                           then (sum(dtr.last_qty) * .00279)::text
                                       when dtr.date_id >= '20240101' and dtr.instrument_type_id = 'E' and
                                            dtr.side <> '1'
                                           and lower(dtr.trading_firm_id) = any (l_list_2)
                                           then (sum(dtr.last_qty) * .000166)::text
                                       --adjustment for trading firms using DFIN that are not FINRA BDs and should have fees assessed for 2023 equities
                                       when dtr.date_id >= '20240101' and dtr.instrument_type_id = 'O' and
                                            array_agg(distinct idl.finra_member) <> '{Y}' and dtr.side <> '1'
                                           then (sum(dtr.last_qty) * .00279)::text
--show the calculation for all equity trades. House DVP and client DVP charges will need to be replaced with allocation based calculations.
                                       when dtr.date_id >= '20240101' and dtr.instrument_type_id = 'E' and
                                            array_agg(distinct idl.finra_member) <> '{Y}' and dtr.side <> '1'
                                           then (sum(dtr.last_qty) * .000166)::text
                                       end --as Option_and_Equity_TAF_Charges
                                   ], ',', '')
        from billing.dash_trade_record dtr
                 left join genesis2.account a on dtr.account_id = a.account_id and a.is_deleted = 'N'
            --left outer join genesis2.genesis2.clearing_account ca      on dtr.account_id = ca.account_id and ca.is_deleted = 'N'
                 left join genesis2.trading_firm tf on dtr.trading_firm_id = tf.trading_firm_id
            --left outer join temp_cat on temp_cat.crdid = tf.cat_crd
                 left join lateral (select idl.crdid, idl.firm_name, idl.finra_member, idl.exchange_id, idl.file_date_id
                                    from external_data.imid_daily_list idl
                                    where tf.cat_crd = idl.crdid
                                      and idl.exchange_id = 'FINRA'
                                      and dtr.date_id >= idl.file_date_id
                                    order by idl.file_date_id desc
                                    limit 1
            )
            as idl on true

        where dtr.date_id between in_start_date_id and in_end_date_id
          and dtr.is_busted = 'N'
          and dtr.side <> '1'
          and dtr.subsystem_id not ilike all ('{LPEDW,LPEDW_DUPE,OMS_EDW%}')
          and dtr.fix_comp_id not ilike all ('{TRAFIXALGOINT_NY,TRAFIXCROSS_NY}')
          and dtr.symbol not ilike all ('{ASBAG,BJE,BKX,BKX,BTK,BYTX,CRX,CZH,DDX,DFI,DFX,DIVD,DJX,DRG,DXL,EPX,EWF,GUO,HGX,HKO,INDU,INDUDL,JBV,JLO,KBK,KIX,KRX,KSX,MID,MNX,MRUT,MSH,MXEA,MXEF,NANOS,NBI,NDX,NDX,NDXDL,NDXP,NDXQ,NDXW,
NDXX,NDXY,NQX,NQX,NYFANG,OEX,OEX,OEXM,OEXQ,OSX,OSX,PGG,QGRI,RAV,RIY,RLG,RLV,RMC,ROY,RRY,RTY,RUJ,RUO,RUT,RUTQ,RUTW,RUY,SIXB,SIXC,SIXE,SIXI,SIXM,SIXR,SIXRE,SIXT,SIXU,SIXV,SIXY,SML,SOX,SOX,SPIKE,SPX,SPX,SPXPM,SPXQ,SPXQ,
SPXW,UTY,UTY,VIX,VIXQ,VIXW,VOLQ,XAL,XAU,XAU,XBD,XCI,XEO,XEO,XEOQ,XMI,XND,XNDX,XSP,XSP,XSPQ}')
          and dtr.exchange_id not ilike all
              ('{BLAZE,TRAFX,C1PAR, PHLXFB, XCHI, BLAZEE,BRKPT, BRKPTE, SQHA, SQHT, JSEB, CTDL, BRKPT, AMXO}')
          and dtr.trading_firm_id not ilike 'RFABOXQOO'
        group by dtr.date_id
               , dtr.instrument_type_id
               , dtr.trading_firm_id
               , tf.trading_firm_name
               , tf.cat_crd
               , dtr.side
               , a.broker_dealer_mpid
               , a.is_broker_dealer;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, 'report_billing_taf_fee_calculation for ' || in_start_date_id::text ||
                                                 '-' || in_end_date_id::text || ' STARTED ====', l_row_cnt, 'O')
    into l_step_id;
end;
$fn$;
select * from dash360.report_billing_taf_fee_calculation(20241101, 20241130);

create temp table t_dtr as
select date_id,
       instrument_type_id,
       trading_firm_id,
       side,
       last_qty,
       account_id,
       subsystem_id,
       fix_comp_id,
       symbol,
       exchange_id
from billing.dash_trade_record dtr
where dtr.date_id between :in_start_date_id and :in_end_date_id
  and dtr.is_busted = 'N'
  and dtr.side <> '1';
create index on t_dtr (symbol);
create index on t_dtr (exchange_id);
create index on t_dtr (date_id, instrument_type_id,trading_firm_id,side)

 select array_to_string(ARRAY [
                                   substr(date_id::text, 1, 4), -- as year,
                                   substr(date_id::text, 5, 2), --as month,
                                   dtr.date_id::text,
                                   dtr.instrument_type_id,
                                   dtr.trading_firm_id,
                                   tf.trading_firm_name,
                                   tf.cat_crd,
                                   dtr.side,
--,array_agg(idl.imid) as cat_imids
                                   a.broker_dealer_mpid,
                                   a.is_broker_dealer,
                                   array_agg(distinct idl.finra_member)::text, --as cat_finra_member,
                                   array_agg(distinct idl.exchange_id)::text, --as cat_exchange_finra,
                                   array_agg(distinct idl.file_date_id)::text, --as cat_file_date_id,
                                   sum(dtr.last_qty)::text, --as last_qty,
--this case statement is used to hardcode firms that we know have the wrong is finra member  in this dataset
                                   case
                                       when lower(dtr.trading_firm_id) = any (:l_list_1)
                                           then '{Y}'::text
                                       when lower(dtr.trading_firm_id) = any (:l_list_2) then '{N}'::text
                                       else array_agg(distinct idl.finra_member)::text end, --as Corrected_Is_FINRA_Member
--designate trading firms with incorrect imid as finra members and therefore 0 fees
                                   case
                                       when lower(dtr.trading_firm_id) = any (:l_list_1)
                                           then 0::text
                                       -------------------------------------beginning of 2024 fees
                                       when dtr.date_id >= '20240101' and dtr.instrument_type_id = 'O'
                                           and lower(dtr.trading_firm_id) = any (:l_list_2)
                                           then (sum(dtr.last_qty) * .00279)::text
                                       when dtr.date_id >= '20240101' and dtr.instrument_type_id = 'E' and
                                            dtr.side <> '1'
                                           and lower(dtr.trading_firm_id) = any (:l_list_2)
                                           then (sum(dtr.last_qty) * .000166)::text
                                       --adjustment for trading firms using DFIN that are not FINRA BDs and should have fees assessed for 2023 equities
                                       when dtr.date_id >= '20240101' and dtr.instrument_type_id = 'O' and
                                            array_agg(distinct idl.finra_member) <> '{Y}' and dtr.side <> '1'
                                           then (sum(dtr.last_qty) * .00279)::text
--show the calculation for all equity trades. House DVP and client DVP charges will need to be replaced with allocation based calculations.
                                       when dtr.date_id >= '20240101' and dtr.instrument_type_id = 'E' and
                                            array_agg(distinct idl.finra_member) <> '{Y}' and dtr.side <> '1'
                                           then (sum(dtr.last_qty) * .000166)::text
                                       end --as Option_and_Equity_TAF_Charges
                                   ], ',', '')
--         from billing.dash_trade_record dtr
        from t_dtr dtr
                 left join genesis2.account a on dtr.account_id = a.account_id and a.is_deleted = 'N'
            --left outer join genesis2.genesis2.clearing_account ca      on dtr.account_id = ca.account_id and ca.is_deleted = 'N'
                 left join genesis2.trading_firm tf on dtr.trading_firm_id = tf.trading_firm_id
            --left outer join temp_cat on temp_cat.crdid = tf.cat_crd
                 left join lateral (select idl.crdid, idl.firm_name, idl.finra_member, idl.exchange_id, idl.file_date_id
                                    from external_data.imid_daily_list idl
                                    where tf.cat_crd = idl.crdid
                                      and idl.exchange_id = 'FINRA'
                                      and dtr.date_id >= idl.file_date_id
                                    order by idl.file_date_id desc
                                    limit 1
            )
            as idl on true

        where true
--           and dtr.date_id between :in_start_date_id and :in_end_date_id
--           and dtr.is_busted = 'N'
--           and dtr.side <> '1'
          and dtr.subsystem_id not ilike all ('{LPEDW,LPEDW_DUPE,OMS_EDW%}')
          and dtr.fix_comp_id not ilike all ('{TRAFIXALGOINT_NY,TRAFIXCROSS_NY}')
          and dtr.symbol not ilike all ('{ASBAG,BJE,BKX,BKX,BTK,BYTX,CRX,CZH,DDX,DFI,DFX,DIVD,DJX,DRG,DXL,EPX,EWF,GUO,HGX,HKO,INDU,INDUDL,JBV,JLO,KBK,KIX,KRX,KSX,MID,MNX,MRUT,MSH,MXEA,MXEF,NANOS,NBI,NDX,NDX,NDXDL,NDXP,NDXQ,NDXW,
NDXX,NDXY,NQX,NQX,NYFANG,OEX,OEX,OEXM,OEXQ,OSX,OSX,PGG,QGRI,RAV,RIY,RLG,RLV,RMC,ROY,RRY,RTY,RUJ,RUO,RUT,RUTQ,RUTW,RUY,SIXB,SIXC,SIXE,SIXI,SIXM,SIXR,SIXRE,SIXT,SIXU,SIXV,SIXY,SML,SOX,SOX,SPIKE,SPX,SPX,SPXPM,SPXQ,SPXQ,
SPXW,UTY,UTY,VIX,VIXQ,VIXW,VOLQ,XAL,XAU,XAU,XBD,XCI,XEO,XEO,XEOQ,XMI,XND,XNDX,XSP,XSP,XSPQ}')
          and dtr.exchange_id not ilike all
              ('{BLAZE,TRAFX,C1PAR, PHLXFB, XCHI, BLAZEE,BRKPT, BRKPTE, SQHA, SQHT, JSEB, CTDL, BRKPT, AMXO}')
          and dtr.trading_firm_id not ilike 'RFABOXQOO'
        group by dtr.date_id
               , dtr.instrument_type_id
               , dtr.trading_firm_id
               , tf.trading_firm_name
               , tf.cat_crd
               , dtr.side
               , a.broker_dealer_mpid
               , a.is_broker_dealer;

select dtr.account_name, a.account_name
        from billing.dash_trade_record dtr
                 left join genesis2.account a on dtr.account_id = a.account_id and a.is_deleted = 'N'
                 left join genesis2.trading_firm tf on dtr.trading_firm_id = tf.trading_firm_id
        where dtr.date_id between :in_start_date_id and :in_end_date_id
and a.account_name is null