-- DROP FUNCTION dash360.report_risk_baml_peak_consumption_file(int4, int4, _int8, _varchar, varchar, varchar);

CREATE OR REPLACE FUNCTION trash.so_report_risk_baml_peak_consumption_file(in_start_date_id integer DEFAULT NULL::integer,
                                                                          in_end_date_id integer DEFAULT NULL::integer,
                                                                          in_account_ids bigint[] DEFAULT '{}'::bigint[],
                                                                          in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[],
                                                                          in_is_include_rejected_order character varying DEFAULT 'N'::character varying,
                                                                          in_is_include_10503_10502_tags character varying DEFAULT 'N'::character varying)
    RETURNS TABLE
            (
                roe text
            )
    LANGUAGE plpgsql
    PARALLEL SAFE LEAKPROOF
AS
$function$
declare
    l_load_id                     int8;
    l_step_id                     int;
    l_current_date                date;
    l_start_date_id               int;
    l_end_date_id                 int;
    l_is_include_rejected_order   varchar;
    l_is_include_10503_10502_tags varchar;
    l_row_cnt                     integer;
    text_var1                     varchar;
    text_var2                     varchar;
    text_var3                     varchar;
    
    l_account_ids int8[];

begin

    --SET enable_bitmapscan TO off;
    --raise notice '>>%<<', current_setting('enable_bitmapscan');

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_risk_baml_peak_consumption_file STARTED===', 0, 'O')
    into l_step_id;

    -- Period: previous quarter by default
    l_current_date := current_date;
    if in_start_date_id is not null and in_end_date_id is not null
    then
        l_start_date_id := in_start_date_id;
        l_end_date_id := in_end_date_id;
    else
        l_start_date_id := to_char(date_trunc('quarter', l_current_date - interval '3 months'), 'YYYYMMDD')::integer;
        l_end_date_id := to_char(date_trunc('quarter', l_current_date) - interval '1 day', 'YYYYMMDD')::integer;
    end if;

    l_is_include_rejected_order := case when left(in_is_include_rejected_order, 1) ilike '%Y%' then 'Y' else 'N' end;
    l_is_include_10503_10502_tags :=
            case when left(in_is_include_10503_10502_tags, 1) ilike '%Y%' then 'Y' else 'N' end;

    select public.load_log(l_load_id, l_step_id,
                           ' Period: l_start_date_id = ' || l_start_date_id::varchar || ', l_end_date_id = ' ||
                           l_end_date_id::varchar, 0, 'O')
    into l_step_id;
    select public.load_log(l_load_id, l_step_id, left('in_account_ids = ' || in_account_ids::varchar, 200), 0, 'O')
    into l_step_id;
    select public.load_log(l_load_id, l_step_id, left('in_trading_firm_ids = ' || in_trading_firm_ids::varchar, 200), 0,
                           'O')
    into l_step_id;
    select public.load_log(l_load_id, l_step_id, left(
            'in_is_include_rejected_order = ' || in_is_include_rejected_order::varchar ||
            ' , in_is_include_10503_10502_tags = ' || in_is_include_10503_10502_tags::varchar, 200), 0, 'O')
    into l_step_id;
    select public.load_log(l_load_id, l_step_id, left(
            'l_is_include_rejected_order = ' || l_is_include_rejected_order::varchar ||
            ' , l_is_include_10503_10502_tags = ' || l_is_include_10503_10502_tags::varchar, 200), 0, 'O')
    into l_step_id;

    -- step 1: fill the config table
    --execute 'DROP TABLE IF EXISTS trash.sdn_tmp_risk_peak_conumption;';
    --create table trash.sdn_tmp_risk_peak_conumption with (parallel_workers = 8) as
    execute 'DROP TABLE IF EXISTS tmp_risk_peak_conumption;';
    create temp table tmp_risk_peak_conumption --with (parallel_workers = 8)
--                                                ON COMMIT drop
                                                   as
    select ac.account_name::character varying                   as tag_1
         , rlv.security_type::character varying                 as security_type
         --, rlv.osr_param_name as rl_parameter
         , (case
                when rlv.risk_mgmt_config_scope = 'H' then rlv.osr_param_name || '(EOS)'
                else rlv.osr_param_name end)::character varying as rl_parameter
         , rlv.osr_param_value::character varying               as current_limit
         , null::character varying                              as peak_value
         , null::character varying                              as peak_date
         , null::character varying                              as cl_ord_id
         --
         , gs.val::int4                                         as peak_id
         , tf.trading_firm_name::character varying
         , tf.trading_firm_id::character varying
         , ac.account_id
         , ac.account_name::character varying
         , rlv.osr_param_code::character varying
    --, rlv.*
    from staging.risk_limits_osr_param_v rlv
             left join dwh.d_account ac
                       on rlv.account_id = ac.account_id
             left join dwh.d_trading_firm tf
                       on (tf.trading_firm_unq_id = ac.trading_firm_unq_id or
                           (rlv.trading_firm_id = tf.trading_firm_id and tf.is_active = true))
             cross join generate_series(1, 5) gs(val)
    where rlv.osr_param_code in
          ('CRMNVE', 'CRMXNV', 'EMAXON', 'EMAXOS', 'DTNEQT', 'CRTNEQ', 'EDAYNV', 'CRMXCO', 'CRMXOC', 'OMAXNV', 'OMAXOC',
           'DTNOPT', 'CRTNOP', 'ODAYNV')
      and case when in_account_ids <> '{}' then ac.account_id = ANY (in_account_ids) else true end
      and case when in_trading_firm_ids <> '{}' then tf.trading_firm_id = ANY (in_trading_firm_ids) else true end
      and case
              when in_account_ids = '{}' and in_trading_firm_ids = '{}' then rlv.entity in ('BLMDO161', 'BLMDOSS161')
              else true end
      --and rlv.entity in ('BLMDO161') --,'BLMDOSS161')
      and ac.account_name is not null;

    insert into tmp_risk_peak_conumption
    select ac.account_name                                                                                           as tag_1
         --, 'Multileg' as security_type
         , case
               when rlv.osr_param_code in ('CRMNVE') then 'Multileg(Eq)'
               when rlv.osr_param_code in ('CRMXNV') then 'Multileg(Opt)'
               else 'Multileg'
        end                                                                                                          as security_type
         --, rlv.osr_param_name as rl_parameter
         , case
               when rlv.risk_mgmt_config_scope = 'H' then rlv.osr_param_name || '(EOS)'
               else rlv.osr_param_name end                                                                           as rl_parameter
         , rlv.osr_param_value                                                                                       as current_limit
         , null::varchar                                                                                             as peak_value
         , null::varchar                                                                                             as peak_date
         , null::varchar                                                                                             as cl_ord_id
         --
         , gs.val::int4                                                                                              as peak_id
         , tf.trading_firm_name
         , tf.trading_firm_id
         , ac.account_id
         , ac.account_name
         , rlv.osr_param_code || '_ML'                                                                               as osr_param_code
    --, rlv.*
    from staging.risk_limits_osr_param_v rlv
             left join dwh.d_account ac
                       on rlv.account_id = ac.account_id
             left join dwh.d_trading_firm tf
                       on (tf.trading_firm_unq_id = ac.trading_firm_unq_id or
                           (rlv.trading_firm_id = tf.trading_firm_id and tf.is_active = true))
             cross join generate_series(1, 5) gs(val)
    where rlv.osr_param_code in
          (/*'CRMNVE',*/ 'CRMXNV', 'EMAXON', 'EMAXOS', 'OMAXNV', 'OMAXOC', 'DTNOPT', 'DTNEQT', 'CRTNOP')
      and case when in_account_ids <> '{}' then ac.account_id = ANY (in_account_ids) else true end
      and case when in_trading_firm_ids <> '{}' then tf.trading_firm_id = ANY (in_trading_firm_ids) else true end
      and case
              when in_account_ids = '{}' and in_trading_firm_ids = '{}' then rlv.entity in ('BLMDO161', 'BLMDOSS161')
              else true end
      --and rlv.entity in ('BLMDO161') --,'BLMDOSS161')
      and ac.account_name is not null;
--     order by 1, 3, 2, 8;
    select count(*) into l_row_cnt from tmp_risk_peak_conumption;
--     GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    create index on tmp_risk_peak_conumption (account_id);
    analyze tmp_risk_peak_conumption;
    
    select array_agg(distinct account_id) 
    into l_account_ids
    from tmp_risk_peak_conumption;

    select public.load_log(l_load_id, l_step_id, 'Accounts and risk limit parameters are loaded', l_row_cnt, 'I')
    into l_step_id;


    -- step 2: load max_order_notional and max_order_shares/contracts parameters
    --execute 'DROP TABLE IF EXISTS trash.sdn_tmp_risk_peak_max_order_notshar_contr;';
    --create table trash.sdn_tmp_risk_peak_max_order_notshar_contr with (parallel_workers = 8) as
    execute 'DROP TABLE IF EXISTS tmp_risk_peak_max_order_notshar_contr;';
    EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON)
    create temp table tmp_risk_peak_max_order_notshar_contr --with (parallel_workers = 8)
--                                                             ON COMMIT drop
        as
    select src.account_id
         , src.osr_param_code
         , src.peak_num        as peak_id
         , max(peak_value)     as peak_value
         , max(peak_date)      as peak_date
         , max(peak_cl_ord_id) as peak_cl_ord_id
    from (select account_id
               , opc.osr_param_code
               , opc.peak_num
               , case
                     when osr_param_code = 'CRMXOC' and crmxoc > 0 and rn_crmxoc = peak_num then crmxoc
                     when osr_param_code = 'CRMXCO' and crmxco > 0 and rn_crmxco = peak_num then crmxco
                     when osr_param_code = 'CRMNVE' and crmnve > 0 and rn_crmnve = peak_num then crmnve
            --when osr_param_code = 'CRMNVE_ML' and crmnve_ml > 0 and rn_crmnve_ml = peak_num then crmnve_ml
                     when osr_param_code = 'CRMXNV' and crmxnv > 0 and rn_crmxnv = peak_num then crmxnv
                     when osr_param_code = 'CRMXNV_ML' and crmxnv_ml > 0 and rn_crmxnv_ml = peak_num then crmxnv_ml
                     when osr_param_code = 'EMAXON' and emaxon > 0 and rn_emaxon = peak_num then emaxon
                     when osr_param_code = 'EMAXON_ML' and emaxon_ml > 0 and rn_emaxon_ml = peak_num then emaxon_ml
                     when osr_param_code = 'EMAXOS' and emaxos > 0 and rn_emaxos = peak_num then emaxos
                     when osr_param_code = 'EMAXOS_ML' and emaxos_ml > 0 and rn_emaxos_ml = peak_num then emaxos_ml
                     when osr_param_code = 'OMAXNV' and omaxnv > 0 and rn_omaxnv = peak_num then omaxnv
                     when osr_param_code = 'OMAXNV_ML' and omaxnv_ml > 0 and rn_omaxnv_ml = peak_num then omaxnv_ml
                     when osr_param_code = 'OMAXOC' and omaxoc > 0 and rn_omaxoc = peak_num then omaxoc
                     when osr_param_code = 'OMAXOC_ML' and omaxoc_ml > 0 and rn_omaxoc_ml = peak_num then omaxoc_ml
            end as peak_value
               -- peak date
               , case
                     when osr_param_code = 'CRMXOC' and crmxoc > 0 and rn_crmxoc = peak_num then create_date_id
                     when osr_param_code = 'CRMXCO' and crmxco > 0 and rn_crmxco = peak_num then create_date_id
                     when osr_param_code = 'CRMNVE' and crmnve > 0 and rn_crmnve = peak_num then create_date_id
            --when osr_param_code = 'CRMNVE_ML' and crmnve_ml > 0 and rn_crmnve_ml = peak_num then create_date_id
                     when osr_param_code = 'CRMXNV' and crmxnv > 0 and rn_crmxnv = peak_num then create_date_id
                     when osr_param_code = 'CRMXNV_ML' and crmxnv_ml > 0 and rn_crmxnv_ml = peak_num then create_date_id
                     when osr_param_code = 'EMAXON' and emaxon > 0 and rn_emaxon = peak_num then create_date_id
                     when osr_param_code = 'EMAXON_ML' and emaxon_ml > 0 and rn_emaxon_ml = peak_num then create_date_id
                     when osr_param_code = 'EMAXOS' and emaxos > 0 and rn_emaxos = peak_num then create_date_id
                     when osr_param_code = 'EMAXOS_ML' and emaxos_ml > 0 and rn_emaxos_ml = peak_num then create_date_id
                     when osr_param_code = 'OMAXNV' and omaxnv > 0 and rn_omaxnv = peak_num then create_date_id
                     when osr_param_code = 'OMAXNV_ML' and omaxnv_ml > 0 and rn_omaxnv_ml = peak_num then create_date_id
                     when osr_param_code = 'OMAXOC' and omaxoc > 0 and rn_omaxoc = peak_num then create_date_id
                     when osr_param_code = 'OMAXOC_ML' and omaxoc_ml > 0 and rn_omaxoc_ml = peak_num then create_date_id
            end as peak_date

               --peak_cl_ord_id
               , case
                     when osr_param_code = 'CRMXOC' and crmxoc > 0 and rn_crmxoc = peak_num then client_order_id
                     when osr_param_code = 'CRMXCO' and crmxco > 0 and rn_crmxco = peak_num then client_order_id
                     when osr_param_code = 'CRMNVE' and crmnve > 0 and rn_crmnve = peak_num then client_order_id
            --when osr_param_code = 'CRMNVE_ML' and crmnve_ml > 0 and rn_crmnve_ml = peak_num then client_order_id
                     when osr_param_code = 'CRMXNV' and crmxnv > 0 and rn_crmxnv = peak_num then client_order_id
                     when osr_param_code = 'CRMXNV_ML' and crmxnv_ml > 0 and rn_crmxnv_ml = peak_num
                         then client_order_id
                     when osr_param_code = 'EMAXON' and emaxon > 0 and rn_emaxon = peak_num then client_order_id
                     when osr_param_code = 'EMAXON_ML' and emaxon_ml > 0 and rn_emaxon_ml = peak_num
                         then client_order_id
                     when osr_param_code = 'EMAXOS' and emaxos > 0 and rn_emaxos = peak_num then client_order_id
                     when osr_param_code = 'EMAXOS_ML' and emaxos_ml > 0 and rn_emaxos_ml = peak_num
                         then client_order_id
                     when osr_param_code = 'OMAXNV' and omaxnv > 0 and rn_omaxnv = peak_num then client_order_id
                     when osr_param_code = 'OMAXNV_ML' and omaxnv_ml > 0 and rn_omaxnv_ml = peak_num
                         then client_order_id
                     when osr_param_code = 'OMAXOC' and omaxoc > 0 and rn_omaxoc = peak_num then client_order_id
                     when osr_param_code = 'OMAXOC_ML' and omaxoc_ml > 0 and rn_omaxoc_ml = peak_num
                         then client_order_id
            end as peak_cl_ord_id
          from (select op.osr_param_code, pn.peak_num
                from (select unnest(array ['CRMXOC', 'CRMXCO', 'CRMNVE', /*'CRMNVE_ML',*/ 'CRMXNV', 'CRMXNV_ML', 'EMAXON', 'EMAXON_ML', 'EMAXOS', 'EMAXOS_ML', 'OMAXNV', 'OMAXNV_ML', 'OMAXOC', 'OMAXOC_ML']) as osr_param_code) op
                         cross join
                         (select unnest(array [1,2,3,4,5]) as peak_num) pn) as opc
                   cross join
               --  select * from
                   (select account_id
                         , create_date_id
                         , client_order_id
                         , crmxoc
                         , row_number() over (partition by account_id order by crmxoc desc nulls last) as rn_crmxoc
                         , crmxco
                         , row_number() over (partition by account_id order by crmxco desc nulls last) as rn_crmxco
                         , crmnve
                         , row_number() over (partition by account_id order by crmnve desc nulls last) as rn_crmnve
                         --, crmnve_ml
                         --, row_number() over (partition by account_id order by crmnve_ml desc nulls last) as rn_crmnve_ml
                         , crmxnv
                         , row_number() over (partition by account_id order by crmxnv desc nulls last) as rn_crmxnv
                         , crmxnv_ml
                         , row_number()
                           over (partition by account_id order by crmxnv_ml desc nulls last) as           rn_crmxnv_ml
                         , emaxon
                         , row_number() over (partition by account_id order by emaxon desc nulls last) as rn_emaxon
                         , emaxon_ml
                         , row_number()
                           over (partition by account_id order by emaxon_ml desc nulls last) as           rn_emaxon_ml
                         , emaxos
                         , row_number() over (partition by account_id order by emaxos desc nulls last) as rn_emaxos
                         , emaxos_ml
                         , row_number()
                           over (partition by account_id order by emaxos_ml desc nulls last) as           rn_emaxos_ml
                         , omaxnv
                         , row_number() over (partition by account_id order by omaxnv desc nulls last) as rn_omaxnv
                         , omaxnv_ml
                         , row_number()
                           over (partition by account_id order by omaxnv_ml desc nulls last) as           rn_omaxnv_ml
                         , omaxoc
                         , row_number() over (partition by account_id order by omaxoc desc nulls last) as rn_omaxoc
                         , omaxoc_ml
                         , row_number()
                           over (partition by account_id order by omaxoc_ml desc nulls last) as           rn_omaxoc_ml
                    from (select distinct s.account_id
                                        , s.create_date_id
                                        , s.client_order_id--, s.order_id
                                        --, s.side, s.order_price
                                        , case
                                              when s.instrument_type_id = 'O' and coalesce(s.is_cross, false) = true and
                                                   s.multileg_reporting_type = '1' -- single options
                                                  then s.order_qty
                            end as CRMXOC                  --CrossMaxOrderContracts -- OPT
                                        , case
                                              when s.instrument_type_id = 'O' and coalesce(s.is_cross, false) = true and
                                                   s.multileg_reporting_type = '2' -- qty the same as mlrt=3
                                                  then s.order_qty
                            end as CRMXCO                  --CrossMaxOrderContracts -- MLEG
                                        , case
                                              when s.instrument_type_id = 'E' and coalesce(s.is_cross, false) = true and
                                                   s.multileg_reporting_type =
                                                   '2' -- multileg, cross eqyity legs. single cross equity legs are not present.
                                                  then s.cross_legs_order_notional --s.order_notional
                            end as CRMNVE                  --CrossMaxOrderNotional -- EQ MLEG
                              /*, case
                                  when s.instrument_type_id in ('E') and coalesce(s.is_cross, false) = true and s.multileg_reporting_type = '2' -- multileg, cross eqyity legs. single cross equity legs are not present.
                                    then s.cross_legs_order_notional --s.order_notional
                                end as CRMNVE_ML --CrossMaxOrderNotional -- MLEG EQ*/
                                        , case
                                              when s.instrument_type_id = 'O' and coalesce(s.is_cross, false) = true and
                                                   s.multileg_reporting_type = '1' -- single options
                                                  then s.order_notional
                            end as CRMXNV                  --CrossMaxOrderNotional -- OPT
                                        , case
                                              when s.instrument_type_id in ('O') and
                                                   coalesce(s.is_cross, false) = true and s.multileg_reporting_type =
                                                                                          '2' -- multileg, but what should be here, eq or opt legs? OPT
                                                  then s.cross_legs_order_notional
                            end as CRMXNV_ML               --CrossMaxOrderNotional -- MLEG OPT
                                        , case
                                              when s.instrument_type_id = 'E' and
                                                   coalesce(s.is_cross, false) = false and
                                                   s.multileg_reporting_type = '1' --
                                                  then s.fix_order_notional --s.order_notional
                            end as EMAXON                  --EquityMaxOrderNotional -- EQ
                                        , case
                                              when s.instrument_type_id = 'E' and
                                                   coalesce(s.is_cross, false) = false and
                                                   s.multileg_reporting_type = '2' --
                                                  then s.fix_order_notional --s.order_notional
                            end as EMAXON_ML               --EquityMaxOrderNotional -- MLEG
                                        , case
                                              when s.instrument_type_id = 'E' and
                                                   coalesce(s.is_cross, false) = false and
                                                   s.multileg_reporting_type = '1' --
                                                  then s.order_qty
                            end as EMAXOS                  --EquityMaxOrderShares -- EQ
                                        , case
                                              when s.instrument_type_id = 'E' and
                                                   coalesce(s.is_cross, false) = false and
                                                   s.multileg_reporting_type = '2' --
                                                  then s.order_qty
                            end as EMAXOS_ML               --EquityMaxOrderShares -- MLEG
                                        , case
                                              when s.instrument_type_id = 'O' and
                                                   coalesce(s.is_cross, false) = false and
                                                   s.multileg_reporting_type = '1' --
                                                  then s.fix_order_notional --s.order_notional
                            end as OMAXNV                  --OptionMaxOrderNotional -- OPT
                                        , case
                                              when s.instrument_type_id = 'O' and
                                                   coalesce(s.is_cross, false) = false and
                                                   s.multileg_reporting_type = '2' --
                                                  then s.fix_order_notional --s.order_notional
                            end as OMAXNV_ML               --OptionMaxOrderNotional -- MLEG
                                        , case
                                              when s.instrument_type_id = 'O' and
                                                   coalesce(s.is_cross, false) = false and
                                                   s.multileg_reporting_type = '1' --
                                                  then s.order_qty
                            end as OMAXOC                  --OptionsMaxOrderContracts -- OPT
                                        , case
                                              when s.instrument_type_id = 'O' and
                                                   coalesce(s.is_cross, false) = false and
                                                   s.multileg_reporting_type = '2' --
                                                  then s.order_qty
                            end as OMAXOC_ML               --OptionsMaxOrderContracts -- MLEG
                          from (select src.account_id
                                     , src.client_order_id
                                     , src.create_date_id
                                     , src.multileg_reporting_type
                                     , src.instrument_type_id
                                     , src.is_cross
                                     , max(src.order_qty)             as order_qty
                                     , abs(sum(src.order_notional))   as order_notional            -- left for single cross options (using NBBO)
                                     , max(src.fix_order_notional)    as fix_order_notional        -- for all non-crosses
                                     , abs(sum(src.principal_amount)) as cross_legs_order_notional -- for cross equity and option legs
                                from tmp_to_do1 src
                                group by src.account_id, src.client_order_id
                                       , src.create_date_id
                                       , src.multileg_reporting_type
                                       , src.instrument_type_id
                                       , src.is_cross
                                ) s) src) s
          where (crmxoc is not null and rn_crmxoc <= 5)
             or (crmxco is not null and rn_crmxco <= 5)
             or (crmnve is not null and rn_crmnve <= 5)
             --or ( crmnve_ml is not null and rn_crmnve_ml <= 5)
             or (crmxnv is not null and rn_crmxnv <= 5)
             or (crmxnv_ml is not null and rn_crmxnv_ml <= 5)
             or (emaxon is not null and rn_emaxon <= 5)
             or (emaxon_ml is not null and rn_emaxon_ml <= 5)
             or (emaxos is not null and rn_emaxos <= 5)
             or (emaxos_ml is not null and rn_emaxos_ml <= 5)
             or (omaxnv is not null and rn_omaxnv <= 5)
             or (omaxnv_ml is not null and rn_omaxnv_ml <= 5)
             or (omaxoc is not null and rn_omaxoc <= 5)
             or (omaxoc_ml is not null and rn_omaxoc_ml <= 5)

          ) src
    group by src.account_id
           , src.osr_param_code
           , src.peak_num
--     order by 1, 2, 3
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id,
                           'max_order_notional and max_order_shares/contracts parameters are loaded', l_row_cnt, 'I')
    into l_step_id;

    -- UPD values
    --update trash.sdn_tmp_risk_peak_conumption trg
    update tmp_risk_peak_conumption trg
    set peak_value = src.peak_value
      , peak_date  = src.peak_date
      , cl_ord_id  = src.peak_cl_ord_id
    from (select account_id, osr_param_code, peak_id, peak_value, peak_date, peak_cl_ord_id
          --from trash.sdn_tmp_risk_peak_max_order_notshar_contr
          from tmp_risk_peak_max_order_notshar_contr) src
    where trg.account_id = src.account_id
      and trg.osr_param_code = src.osr_param_code
      and trg.peak_id = src.peak_id;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id,
                           'max_order_notional and max_order_shares/contracts parameters are updated to DM', l_row_cnt,
                           'U')
    into l_step_id;

    -- step 4: load total_notionals (maximum notional value for trades over the course of the day) parameters
    --execute 'DROP TABLE IF EXISTS trash.sdn_tmp_risk_peak_total_notionals;';
    --create table trash.sdn_tmp_risk_peak_total_notionals with (parallel_workers = 8) as
    execute 'DROP TABLE IF EXISTS tmp_risk_peak_total_notionals;';
    create temp table tmp_risk_peak_total_notionals with (parallel_workers = 8)
                                                    ON COMMIT drop as
    select src.account_id
         , src.osr_param_code
         , src.peak_num              as peak_id
         , round(max(peak_value), 4) as peak_value
         , max(peak_date)            as peak_date
    from (select account_id
               , opc.osr_param_code
               , opc.peak_num
               , case
                     when osr_param_code = 'DTNEQT' and dtneqt is not null and rn_dtneqt = peak_num then dtneqt
                     when osr_param_code = 'CRTNEQ' and crtneq is not null and rn_crtneq = peak_num then crtneq
                     when osr_param_code = 'EDAYNV' and edaynv is not null and rn_edaynv = peak_num then edaynv
                     when osr_param_code = 'DTNEQT_ML' and dtneqt_ml is not null and rn_dtneqt_ml = peak_num
                         then dtneqt_ml
                     when osr_param_code = 'DTNOPT' and dtnopt is not null and rn_dtnopt = peak_num then dtnopt
                     when osr_param_code = 'CRTNOP' and crtnop is not null and rn_crtnop = peak_num then crtnop
                     when osr_param_code = 'ODAYNV' and odaynv is not null and rn_odaynv = peak_num then odaynv
                     when osr_param_code = 'DTNOPT_ML' and dtnopt_ml is not null and rn_dtnopt_ml = peak_num
                         then dtnopt_ml
                     when osr_param_code = 'CRTNOP_ML' and crtnop_ml is not null and rn_crtnop_ml = peak_num
                         then crtnop_ml
            end as peak_value
               -- peak date
               , case
                     when osr_param_code = 'DTNEQT' and dtneqt is not null and rn_dtneqt = peak_num then date_id
                     when osr_param_code = 'CRTNEQ' and crtneq is not null and rn_crtneq = peak_num then date_id
                     when osr_param_code = 'EDAYNV' and edaynv is not null and rn_edaynv = peak_num then date_id
                     when osr_param_code = 'DTNEQT_ML' and dtneqt_ml is not null and rn_dtneqt_ml = peak_num
                         then date_id
                     when osr_param_code = 'DTNOPT' and dtnopt is not null and rn_dtnopt = peak_num then date_id
                     when osr_param_code = 'CRTNOP' and crtnop is not null and rn_crtnop = peak_num then date_id
                     when osr_param_code = 'ODAYNV' and odaynv is not null and rn_odaynv = peak_num then date_id
                     when osr_param_code = 'DTNOPT_ML' and dtnopt_ml is not null and rn_dtnopt_ml = peak_num
                         then date_id
                     when osr_param_code = 'CRTNOP_ML' and crtnop_ml is not null and rn_crtnop_ml = peak_num
                         then date_id
            end as peak_date
          from (select op.osr_param_code, pn.peak_num
                from (select unnest(array ['DTNEQT', 'CRTNEQ', 'EDAYNV', 'DTNEQT_ML', 'DTNOPT', 'CRTNOP', 'ODAYNV', 'DTNOPT_ML', 'CRTNOP_ML']) as osr_param_code) op
                         cross join
                         (select unnest(array [1,2,3,4,5]) as peak_num) pn) as opc
                   cross join
               (select *
                from (select s.account_id
                           , s.date_id
                           , dtneqt
                           , row_number() over (partition by account_id order by dtneqt desc nulls last) as rn_dtneqt
                           , crtneq
                           , row_number() over (partition by account_id order by crtneq desc nulls last) as rn_crtneq
                           , edaynv
                           , row_number() over (partition by account_id order by edaynv desc nulls last) as rn_edaynv
                           , dtneqt_ml
                           , row_number()
                             over (partition by account_id order by dtneqt_ml desc nulls last) as           rn_dtneqt_ml
                           , dtnopt
                           , row_number() over (partition by account_id order by dtnopt desc nulls last) as rn_dtnopt
                           , crtnop
                           , row_number() over (partition by account_id order by crtnop desc nulls last) as rn_crtnop
                           , odaynv
                           , row_number() over (partition by account_id order by odaynv desc nulls last) as rn_odaynv
                           , dtnopt_ml
                           , row_number()
                             over (partition by account_id order by dtnopt_ml desc nulls last) as           rn_dtnopt_ml
                           , crtnop_ml
                           , row_number()
                             over (partition by account_id order by crtnop_ml desc nulls last) as           rn_crtnop_ml
                      from (select src.account_id
                                 , src.date_id
                                 --, src.calc_source
                                 , sum(DTNEQT)    as dtneqt
                                 , sum(CRTNEQ)    as crtneq
                                 , sum(EDAYNV)    as edaynv
                                 , sum(DTNEQT_ML) as dtneqt_ml
                                 , sum(DTNOPT)    as dtnopt
                                 , sum(CRTNOP)    as crtnop
                                 , sum(ODAYNV)    as odaynv
                                 , sum(DTNOPT_ML) as dtnopt_ml
                                 , sum(CRTNOP_ML) as crtnop_ml
                            from (select s.account_id
                                       , s.date_id
                                       --, s.calc_source
                                       , case
                                             when s.instrument_type_id = 'E' and s.multileg_reporting_type = '1'
                                                 then --s.principal_amount
                                                 case
                                                     when s.is_cross = true
                                                         then s.principal_amount
                                                     when s.is_10504_10505_exists = true -- If tags are available
                                                         then s.filled_portion_percentage_to_10504_10505_value -- use portional 10505 for the whole MLEG order(options part)
                                                 --when s.is_10504_10505_exists = false and s.principal_amount is null -- If there are no 10504/10505 tags and no executed notional in "NEW" orders
                                                 --  then order_notional_nbbo
                                                     else s.principal_amount -- modified . Use executed notional in case tags are missing (EOS,...)
                                                     end
                                    end as DTNEQT    --EquityTotalNotional -- EQ (equities, single)
                                       , case
                                             when s.instrument_type_id = 'E' and s.is_cross = true and
                                                  s.multileg_reporting_type = '1'
                                                 then --s.principal_amount
                                                 case
                                                     when s.is_cross = true
                                                         then s.principal_amount
                                                     when s.is_10504_10505_exists = true -- If tags are available
                                                         then s.filled_portion_percentage_to_10504_10505_value -- use portional 10505 for the whole MLEG order(options part)
                                                 --when s.is_10504_10505_exists = false and s.principal_amount is null -- If there are no 10504/10505 tags and no executed notional in "NEW" orders
                                                 --  then order_notional_nbbo
                                                     else s.principal_amount -- modified . Use executed notional in case tags are missing (EOS,...)
                                                     end
                                    end as CRTNEQ    --EquityTotalNotionalCross -- EQ (equities, single, only crosses)
                                       , case
                                             when s.instrument_type_id = 'E' and s.is_cross = false and
                                                  s.multileg_reporting_type = '1'
                                                 then --s.principal_amount
                                                 case
                                                     when s.is_cross = true
                                                         then s.principal_amount
                                                     when s.is_10504_10505_exists = true -- If tags are available
                                                         then s.filled_portion_percentage_to_10504_10505_value -- use portional 10505 for the whole MLEG order(options part)
                                                 --when s.is_10504_10505_exists = false and s.principal_amount is null -- If there are no 10504/10505 tags and no executed notional in "NEW" orders
                                                 --  then order_notional_nbbo
                                                     else s.principal_amount -- modified . Use executed notional in case tags are missing (EOS,...)
                                                     end
                                    end as EDAYNV    --EquityTotalNotionalNonCross -- EQ (equities, single, non-crosses)
                                       , case
                                             when s.instrument_type_id = 'E' and s.multileg_reporting_type = '2'
                                                 then --s.principal_amount
                                                 case
                                                     when s.is_cross = true
                                                         then s.principal_amount
                                                     when s.is_10504_10505_exists = true -- If tags are available
                                                         then s.filled_portion_percentage_to_10504_10505_value -- use portional 10505 for the whole MLEG order(options part)
                                                 --when s.is_10504_10505_exists = false and s.principal_amount is null -- If there are no 10504/10505 tags and no executed notional in "NEW" orders
                                                 --  then order_notional_nbbo
                                                     else s.principal_amount -- modified . Use executed notional in case tags are missing (EOS,...)
                                                     end
                                    end as DTNEQT_ML --EquityTotalNotional -- ML_EQ (Multileg - equities)
                                       , case
                                             when s.instrument_type_id = 'O' and s.multileg_reporting_type = '1'
                                                 then --s.principal_amount
                                                 case
                                                     when s.is_cross = true
                                                         then s.principal_amount
                                                     when s.is_10504_10505_exists = true -- If tags are available
                                                         then s.filled_portion_percentage_to_10504_10505_value -- use portional 10505 for the whole MLEG order(options part)
                                                 --when s.is_10504_10505_exists = false and s.principal_amount is null -- If there are no 10504/10505 tags and no executed notional in "NEW" orders
                                                 --  then order_notional_nbbo
                                                     else s.principal_amount -- modified . Use executed notional in case tags are missing (EOS,...)
                                                     end
                                    end as DTNOPT    --OptionTotalNotional -- OPT (options, single)
                                       , case
                                             when s.instrument_type_id = 'O' and s.is_cross = true and
                                                  s.multileg_reporting_type = '1'
                                                 then --s.principal_amount
                                                 case
                                                     when s.is_cross = true
                                                         then s.principal_amount
                                                     when s.is_10504_10505_exists = true -- If tags are available
                                                         then s.filled_portion_percentage_to_10504_10505_value -- use portional 10505 for the whole MLEG order(options part)
                                                 --when s.is_10504_10505_exists = false and s.principal_amount is null -- If there are no 10504/10505 tags and no executed notional in "NEW" orders
                                                 --  then order_notional_nbbo
                                                     else s.principal_amount -- modified . Use executed notional in case tags are missing (EOS,...)
                                                     end
                                    end as CRTNOP    --OptionTotalNotionalCross -- OPT (options, single, crosses)
                                       , case
                                             when s.instrument_type_id = 'O' and s.is_cross = false and
                                                  s.multileg_reporting_type = '1'
                                                 then --s.principal_amount
                                                 case
                                                     when s.is_cross = true
                                                         then s.principal_amount
                                                     when s.is_10504_10505_exists = true -- If tags are available
                                                         then s.filled_portion_percentage_to_10504_10505_value -- use portional 10505 for the whole MLEG order(options part)
                                                 --when s.is_10504_10505_exists = false and s.principal_amount is null -- If there are no 10504/10505 tags and no executed notional in "NEW" orders
                                                 --  then order_notional_nbbo
                                                     else s.principal_amount -- modified . Use executed notional in case tags are missing (EOS,...)
                                                     end
                                    end as ODAYNV    --OptionTotalNotionalNonCross -- OPT (options, single, non-crosses)
                                       , case
                                             when s.instrument_type_id = 'O' and s.multileg_reporting_type = '2'
                                                 then --s.principal_amount
                                                 case
                                                     when s.is_cross = true
                                                         then s.principal_amount
                                                     when s.is_10504_10505_exists = true -- If tags are available
                                                         then s.filled_portion_percentage_to_10504_10505_value -- use portional 10505 for the whole MLEG order(options part)
                                                 --when s.is_10504_10505_exists = false and s.principal_amount is null -- If there are no 10504/10505 tags and no executed notional in "NEW" orders
                                                 --  then order_notional_nbbo
                                                     else s.principal_amount -- modified . Use executed notional in case tags are missing (EOS,...)
                                                     end
                                    end as DTNOPT_ML --OptionTotalNotional -- ML_OPT (Multileg - options)
                                       , case
                                             when s.instrument_type_id = 'O' and s.is_cross = true and
                                                  s.multileg_reporting_type = '2'
                                                 then --s.principal_amount
                                                 case
                                                     when s.is_cross = true
                                                         then s.principal_amount
                                                     when s.is_10504_10505_exists = true -- If tags are available
                                                         then s.filled_portion_percentage_to_10504_10505_value -- use portional 10505 for the whole MLEG order(options part)
                                                 --when s.is_10504_10505_exists = false and s.principal_amount is null -- If there are no 10504/10505 tags and no executed notional in "NEW" orders
                                                 --  then order_notional_nbbo
                                                     else s.principal_amount -- modified . Use executed notional in case tags are missing (EOS,...)
                                                     end
                                    end as CRTNOP_ML --OptionTotalNotionalCross -- ML_OPT (Multileg - options, crosses)
                                  from (select s1.account_id
                                             , s1.date_id
                                             , s1.instrument_type_id
                                             , s1.is_cross
                                             , s1.multileg_reporting_type
                                             , s1.principal_amount
                                             , s1.filled_portion_percentage_to_10504_10505_value
                                             , 's1'          as calc_source
                                             , null::numeric as order_notional_nbbo
                                             , s1.is_10504_10505_exists
                                        from (select tr.account_id
                                                   , tr.date_id
                                                   , tr.instrument_type_id
                                                   , tr.is_cross
                                                   , tr.multileg_reporting_type
                                                   , abs(tr.principal_amount)                      as principal_amount                               -- modified for MLEG Option 10505 value percentage
                                                   --, tr.*, fx.*
                                                   --, tr.cum_qty/tr.order_qty * 100 as prc
                                                   , ((case
                                                           when tr.instrument_type_id = 'E'
                                                               then fx.tag_10504_equity_order_notional::numeric
                                                           else fx.tag_10505_option_order_notional::numeric end) /
                                                      tr.order_qty::numeric) *
                                                     tr.cum_qty::numeric                           as filled_portion_percentage_to_10504_10505_value -- по эквити легко: там 10504 будет соответствовать order_qty эквити лега
                                                   -- по опционам сложно: там 10505 будет соответствовать сумме order_qty опционовых легов
                                                   , tr.order_fix_message_id
                                                   , case
                                                         when coalesce(fx.tag_10504_equity_order_notional,
                                                                       fx.tag_10505_option_order_notional) is not null
                                                             then true
                                                         else false end                            as is_10504_10505_exists
                                              from (select s.account_id
                                                         , s.date_id
                                                         , s.client_order_id
                                                         , s.order_fix_message_id
                                                         , s.instrument_type_id
                                                         , s.is_cross
                                                         , s.multileg_reporting_type
                                                         , sum(s.order_qty)        as order_qty
                                                         , sum(s.cum_qty)          as cum_qty
                                                         , sum(s.principal_amount) as principal_amount
                                                    from (select tr.account_id
                                                               , tr.date_id
                                                               , tr.order_id
                                                               , tr.client_order_id
                                                               , tr.order_fix_message_id
                                                               , tr.instrument_type_id
                                                               , case when tr.is_cross_order = 'Y' then true else false end as is_cross
                                                               , tr.multileg_reporting_type
                                                               , avg(tr.last_px)                                            as avg_px
                                                               , max(tr.order_qty)                                          as order_qty
                                                               , sum(tr.last_qty)                                           as cum_qty
                                                               , sum(case
                                                                         when tr.multileg_reporting_type = '2' and tr.side not in ('1', '3')
                                                                             then -tr.principal_amount
                                                                         else tr.principal_amount end)                      as principal_amount
                                                          from dwh.flat_trade_record tr
                                                          where tr.date_id between l_start_date_id and l_end_date_id       -- = 20211207 --   20211201 and 20211231 --
                                                            and tr.account_id in
                                                                (select distinct account_id from tmp_risk_peak_conumption) --  --(25239, 24649 /*, 27630*/)
                                                            --and tr.account_id in (select distinct account_id from trash.sdn_tmp_risk_peak_conumption) -- in (24649, 25239, 29222, 24650,30214) --
                                                            and tr.is_busted = 'N'
                                                            and coalesce(tr.trade_record_reason, '-1') <> 'A'              -- ???? Away trades
                                                          --and tr.is_cross_order = 'Y' -- principal_amount logic is only for crosses
                                                          group by tr.account_id
                                                                 , tr.date_id
                                                                 , tr.order_id, tr.client_order_id
                                                                 , tr.order_fix_message_id
                                                                 , tr.instrument_type_id
                                                                 , case when tr.is_cross_order = 'Y' then true else false end
                                                                 , tr.multileg_reporting_type
                                                             --order by tr.order_fix_message_id
                                                         ) s
                                                    group by s.account_id
                                                           , s.date_id
                                                           , s.client_order_id
                                                           , s.order_fix_message_id
                                                           , s.instrument_type_id
                                                           , s.is_cross
                                                           , s.multileg_reporting_type
                                                       --order by s.order_fix_message_id
                                                   ) tr
                                                       left join lateral
                                                  (
                                                  select j.fix_message_id
                                                       , j.fix_message ->> '10504' as tag_10504_equity_order_notional
                                                       , j.fix_message ->> '10505' as tag_10505_option_order_notional
                                                  --, j.*
                                                  from fix_capture.fix_message_json j
                                                  where true
                                                    and j.fix_message_id = tr.order_fix_message_id
                                                    and j.date_id between l_start_date_id and l_end_date_id -- 20211201 and 20211231 --
                                                    --and j.date_id = tr.date_id
                                                    and tr.is_cross = false
                                                  limit 1
                                                  ) fx on true
                                                 --order by tr.order_fix_message_id
                                             ) s1
                                        union all
                                        -- include orders with status NEW
                                        select s2.account_id
                                             , s2.date_id
                                             , s2.instrument_type_id
                                             , s2.is_cross
                                             , s2.multileg_reporting_type
                                             , s2.principal_amount
                                             , s2.filled_portion_percentage_to_10504_10505_value
                                             , 's2'                                                as calc_source
                                             , s2.equity_order_notional + s2.option_order_notional as order_notional_nbbo -- will be dependent on instrument_type. Just in case there are no 10504/10505 tags in orders
                                             , s2.is_10504_10505_exists
                                        from (select conew.account_id
                                                   , conew.date_id
                                                   , conew.instrument_type_id
                                                   , conew.is_cross
                                                   , conew.multileg_reporting_type
                                                   , null::numeric                                       as principal_amount
                                                   --, tr.*, fx.*
                                                   --, tr.cum_qty/tr.order_qty * 100 as prc
                                                   , ((case
                                                           when conew.instrument_type_id = 'E'
                                                               then fx.tag_10504_equity_order_notional::numeric
                                                           else fx.tag_10505_option_order_notional::numeric end) /
                                                      conew.order_qty::numeric) *
                                                     conew.cum_qty::numeric                              as filled_portion_percentage_to_10504_10505_value -- по эквити легко: там 10504 будет соответствовать order_qty эквити лега
                                                   -- по опционам сложно: там 10505 будет соответствовать сумме order_qty опционовых легов
                                                   , conew.order_fix_message_id
                                                   , case
                                                         when coalesce(fx.tag_10504_equity_order_notional,
                                                                       fx.tag_10505_option_order_notional) is not null
                                                             then true
                                                         else false end                                  as is_10504_10505_exists
                                                   , abs(conew.equity_order_notional)                    as equity_order_notional
                                                   , abs(conew.option_order_notional)                    as option_order_notional
                                              from (select s.account_id
                                                         , s.date_id
                                                         , s.client_order_id
                                                         , s.order_fix_message_id
                                                         , s.instrument_type_id
                                                         , s.is_cross
                                                         , s.multileg_reporting_type
                                                         , sum(s.order_qty)             as order_qty
                                                         , sum(s.cum_qty)               as cum_qty
                                                         --, sum(s.principal_amount) as principal_amount
                                                         --NBBO Buy-Sell Order Notional
                                                         , sum(s.equity_order_notional) as equity_order_notional -- NBBO
                                                         , sum(s.option_order_notional) as option_order_notional -- NBBO - differs from what we have from 10504/10505
                                                    from (select co.account_id
                                                               , co.create_date_id                                                as date_id
                                                               , co.order_id
                                                               , co.client_order_id
                                                               , co.fix_message_id                                                as order_fix_message_id
                                                               , di.instrument_type_id
                                                               , case when co.cross_order_id is not null then true else false end as is_cross
                                                               , co.multileg_reporting_type
                                                               , co.order_qty
                                                               , co.order_qty                                                     as cum_qty
                                                               , fyc.nbbo_ask_price
                                                               , fyc.nbbo_bid_price
                                                               , co.side
                                                               , case
                                                                     when di.instrument_type_id = 'E'
                                                                         then abs(co.order_qty *
                                                                                  coalesce(
                                                                                          (case --when fyc.order_type_id <> '1' then fyc.order_price
                                                                                               when co.side in ('1', '3')
                                                                                                   then fyc.nbbo_ask_price -- fyc.order_type_id = '1' and
                                                                                               when co.side not in ('1', '3')
                                                                                                   then fyc.nbbo_bid_price -- fyc.order_type_id = '1' and
                                                                                              end), 0))
                                                            end                                                                   as equity_order_notional
                                                               , case
                                                                     when di.instrument_type_id = 'O'
                                                                         then (co.order_qty * os.contract_multiplier *
                                                                               coalesce(
                                                                                       (case --when fyc.order_type_id <> '1' then fyc.order_price
                                                                                            when co.side in ('1', '3')
                                                                                                then abs(fyc.nbbo_ask_price) -- fyc.order_type_id = '1' and
                                                                                            when co.side not in ('1', '3')
                                                                                                then -abs(fyc.nbbo_bid_price) -- fyc.order_type_id = '1' and
                                                                                           end), 0))
                                                            end                                                                   as option_order_notional
                                                          --, ex.*
                                                          --, co.trans_type
                                                          from dwh.client_order co
                                                                   join lateral
                                                              (
                                                              select ex.order_id
                                                                   , ex.order_status
                                                                   , ex.exec_type
                                                              --, first_value(ex.order_status) over (partition by ex.order_id order by ex.exec_id desc) as max_status
                                                              --, ex.*
                                                              from dwh.execution ex
                                                              where ex.order_id = co.order_id
                                                                and ex.exec_date_id between l_start_date_id and l_end_date_id -- 20211201 and 20211231
                                                              --and ex.exec_type = 'F'
                                                              order by ex.exec_id desc
                                                              limit 1
                                                              ) ex
                                                                        on ex.order_status = '0' -- ex.max_status = '0' --true --
                                                                   left join dwh.d_instrument di
                                                                             on co.instrument_id = di.instrument_id
                                                                   left join dwh.d_option_contract oc
                                                                             on di.instrument_id = oc.instrument_id
                                                                   left join dwh.d_option_series os
                                                                             on oc.option_series_id = os.option_series_id
                                                                   left join lateral
                                                              (
                                                              select fyc.order_id
                                                                   , fyc.nbbo_ask_price
                                                                   , fyc.nbbo_bid_price
                                                              from data_marts.f_yield_capture fyc
                                                              where fyc.status_date_id between l_start_date_id and l_end_date_id -- 20211201 and 20211231 --
                                                                and fyc.status_date_id = co.create_date_id
                                                                and fyc.order_id = co.order_id
                                                              limit 1
                                                              ) fyc on true
                                                          where co.create_date_id between l_start_date_id and l_end_date_id -- 20211201 and 20211231 -- = 20211207 --
                                                            and co.account_id in
                                                                (select distinct account_id from tmp_risk_peak_conumption)  -- in (24649, 25239, 29222, 24650,30214) --
                                                            --and co.account_id in (select distinct account_id from trash.sdn_tmp_risk_peak_conumption) -- in (24649, 25239, 29222, 24650,30214) --
                                                            and co.multileg_reporting_type in ('1', '2')
                                                            and co.trans_type not in ('F', 'G')
                                                            and co.parent_order_id is null                                  -- only parent orders
                                                            and co.cross_order_id is null -- only non-crosses
                                                             --order by co.fix_message_id, co.order_id --, ex.exec_id
                                                         ) s
                                                    group by s.account_id
                                                           , s.date_id
                                                           , s.client_order_id
                                                           , s.order_fix_message_id
                                                           , s.instrument_type_id
                                                           , s.is_cross
                                                           , s.multileg_reporting_type
                                                       --order by s.order_fix_message_id
                                                   ) conew
                                                       left join lateral
                                                  (
                                                  select j.fix_message_id
                                                       , j.fix_message ->> '10504' as tag_10504_equity_order_notional
                                                       , j.fix_message ->> '10505' as tag_10505_option_order_notional
                                                  --, j.*
                                                  from fix_capture.fix_message_json j
                                                  where true
                                                    and j.fix_message_id = conew.order_fix_message_id
                                                    and j.date_id between l_start_date_id and l_end_date_id -- 20211201 and 20211231 --
                                                  --and j.date_id = tr.date_id
                                                  --and co.cross_order_id is null --??
                                                  limit 1
                                                  ) fx on true
                                                 --order by tr.order_fix_message_id
                                             ) s2) s
                                     --order by 1,2
                                 ) src
                            group by src.account_id
                                   , src.date_id
                               --, src.calc_source
                               --order by 1,2
                           ) s
                         --order by 1,2
                     ) s2
                where (dtneqt is not null and rn_dtneqt <= 5)
                   or (crtneq is not null and rn_crtneq <= 5)
                   or (edaynv is not null and rn_edaynv <= 5)
                   or (dtneqt_ml is not null and rn_dtneqt_ml <= 5)
                   or (dtnopt is not null and rn_dtnopt <= 5)
                   or (crtnop is not null and rn_crtnop <= 5)
                   or (odaynv is not null and rn_odaynv <= 5)
                   or (dtnopt_ml is not null and rn_dtnopt_ml <= 5)
                   or (crtnop_ml is not null and rn_crtnop_ml <= 5)) fl) src
    group by src.account_id
           , src.osr_param_code
           , src.peak_num
    --order by 1,2,3
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id, 'total_notionals are loaded', l_row_cnt, 'I')
    into l_step_id;

    --update trash.sdn_tmp_risk_peak_conumption trg
    update tmp_risk_peak_conumption trg
    set peak_value = src.peak_value
      , peak_date  = src.peak_date
    from (select account_id, osr_param_code, peak_id, peak_value, peak_date
          --from trash.sdn_tmp_risk_peak_total_notionals
          from tmp_risk_peak_total_notionals) src
    where trg.account_id = src.account_id
      and trg.osr_param_code = src.osr_param_code
      and trg.peak_id = src.peak_id;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select public.load_log(l_load_id, l_step_id, 'total_notionals parameters are updated to DM', l_row_cnt, 'U')
    into l_step_id;

    if l_is_include_10503_10502_tags = 'Y'
    then
        -- step 5: load total_notionals (10502 and 10503 values from latest order of the day) parameters
        --execute 'DROP TABLE IF EXISTS trash.sdn_tmp_risk_10502_10503_total_notionals;';
        --create table trash.sdn_tmp_risk_10502_10503_total_notionals with (parallel_workers = 8) as
        execute 'DROP TABLE IF EXISTS tmp_risk_10502_10503_total_notionals;';
        create temp table tmp_risk_10502_10503_total_notionals with (parallel_workers = 8)
                                                               ON COMMIT drop as
        select create_date_id as date_id
             , s.account_id
             , s.tag_10502_equity_total_day_notional
             , s.tag_10503_option_total_day_notional
        from (select co.account_id
                   , co.create_date_id
                   , co.create_time
                   , co.process_time
                   , co.order_id
                   , co.multileg_reporting_type --, di.instrument_type_id--, co.fix_message_id
                   , co.client_order_id
                   , fx.fix_message_id
                   , fx.tag_10502_equity_total_day_notional
                   , fx.tag_10503_option_total_day_notional
                   , fx.tag_10504_equity_order_notional
                   , fx.tag_10505_option_order_notional
                   , row_number()
                     over (partition by co.account_id, co.create_date_id order by co.create_time desc, co.order_id desc) rn
                   , rj.*
              from dwh.client_order co
                       --left join dwh.d_instrument di
                       --  on co.instrument_id = di.instrument_id
                       join lateral
                  (
                  select j.fix_message_id
                       , j.fix_message ->> '10502' as tag_10502_equity_total_day_notional
                       , j.fix_message ->> '10503' as tag_10503_option_total_day_notional
                       , j.fix_message ->> '10504' as tag_10504_equity_order_notional
                       , j.fix_message ->> '10505' as tag_10505_option_order_notional
                  --, j.*
                  from fix_capture.fix_message_json j
                  where true
                    and j.fix_message_id = co.fix_message_id
                    and j.date_id between l_start_date_id and l_end_date_id -- 20220101 and 20220115 --
                    and j.date_id = co.create_date_id
                    and co.cross_order_id is null                           --??
                  limit 1
                  ) fx on true
                  -- rejected status - just to see if it inflience on the 10502 and 10503
                       left join lateral
                  (
                  select ex.order_status, ex.exec_type
                  from dwh.execution ex
                  where ex.order_id = co.order_id
                    and (ex.order_status = '8' or ex.exec_type = '8')
                    --and ex.exec_date_id >= co.create_date_id
                    and ex.exec_date_id between l_start_date_id and l_end_date_id
                  limit 1
                  ) rj on true
              where co.create_date_id between l_start_date_id and l_end_date_id                 -- 20220101 and 20220115 --
                and co.account_id in (select distinct account_id from tmp_risk_peak_conumption) -- (24649) --
                --and co.account_id in (select distinct account_id from trash.sdn_tmp_risk_peak_conumption) -- (24649) --
                and co.multileg_reporting_type in ('1', '2')
                and co.trans_type <> 'F'
                and co.parent_order_id is null
                --and rj.order_status is null -- exclude rejects
                and case when l_is_include_rejected_order = 'Y' then true else rj.order_status is null end) s
        where s.rn = 1 -- take tags from the last order per day per account
        ;
        GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

        select public.load_log(l_load_id, l_step_id, 'total_notionals from 10502 and 10503 are loaded', l_row_cnt, 'I')
        into l_step_id;

        execute 'DROP TABLE IF EXISTS trash.sdn_tmp_risk_10502_10503_total_notionals;';
        create table trash.sdn_tmp_risk_10502_10503_total_notionals with (parallel_workers = 8) as
        select * from tmp_risk_10502_10503_total_notionals;

    end if;


    select public.load_log(l_load_id, l_step_id, 'dash360.report_risk_baml_reak_consumption_file COMPLETED===', 0, 'O')
    into l_step_id;


    --execute 'DROP TABLE IF EXISTS trash.sdn_tmp_risk_peak_conumption;';
    --create table trash.sdn_tmp_risk_peak_conumption with (parallel_workers = 8) as
    --select * from tmp_risk_peak_conumption;
    -- just to check md5 (OS)
    if l_is_include_10503_10502_tags = 'Y'
    then

        RETURN QUERY
            select 'Tag 1,Security Type,Parameter,Current Limit,Peak Value,Peak Date,Cl Ord ID,Equity tag_10502 Day Total Notional,Option tag_10503 Day Total Notional' as header_roe
            union all
            select s.roe
            from (select coalesce(t.tag_1::varchar, '')::varchar || ',' || -- Tag 1
                         coalesce(t.security_type::varchar, '')::varchar || ',' || -- Security Type
                         coalesce(t.rl_parameter::varchar, '')::varchar || ',' || -- Parameter
                         coalesce(t.current_limit::varchar, '')::varchar || ',' || -- Current Limit
                         coalesce(t.peak_value::varchar, '')::varchar || ',' || -- Peak Value
                         coalesce(t.peak_date::varchar, '')::varchar || ',' || -- Peak Date
                         coalesce(t.cl_ord_id::varchar, '')::varchar || ',' || -- Cl Ord ID
                         coalesce(t.tag_10502_equity_total_day_notional::varchar, '')::varchar ||
                         ',' || -- Equity Total Notional
                         coalesce(t.tag_10503_option_total_day_notional::varchar, '')::varchar -- Option Total Notional
                             as roe
                  from (select t.tag_1
                             , t.security_type
                             , t.rl_parameter
                             , t.current_limit
                             , t.peak_value
                             , to_char(to_date(t.peak_date::varchar, 'YYYYMMDD'), 'MM/DD/YYYY') as peak_date
                             , t.cl_ord_id
                             , t.peak_id
                             , tn.tag_10502_equity_total_day_notional
                             , tn.tag_10503_option_total_day_notional
                        from --trash.sdn_tmp_risk_peak_conumption t
                             tmp_risk_peak_conumption t
                                 left join tmp_risk_10502_10503_total_notionals tn
                                 --trash.sdn_tmp_risk_10502_10503_total_notionals tn
                                           on tn.account_id = t.account_id
                                               and tn.date_id = t.peak_date::integer
                                               and t.rl_parameter ilike
                                                   '%TotalNotional%' -- reverted to print for all TotalNotionals
                           --and t.rl_parameter in ('EquityTotalNotional','OptionTotalNotional')
                           --where t.rl_parameter ilike '%TotalNotional%'
                       ) t
                  order by t.tag_1, t.rl_parameter, t.security_type, t.peak_id) s;

    else

        RETURN QUERY
            select 'Tag 1,Security Type,Parameter,Current Limit,Peak Value,Peak Date,Cl Ord ID' as header_roe
            union all
            select s.roe
            from (select coalesce(t.tag_1::varchar, '')::varchar || ',' || -- Tag 1
                         coalesce(t.security_type::varchar, '')::varchar || ',' || -- Security Type
                         coalesce(t.rl_parameter::varchar, '')::varchar || ',' || -- Parameter
                         coalesce(t.current_limit::varchar, '')::varchar || ',' || -- Current Limit
                         coalesce(t.peak_value::varchar, '')::varchar || ',' || -- Peak Value
                         coalesce(t.peak_date::varchar, '')::varchar || ',' || -- Peak Date
                         coalesce(t.cl_ord_id::varchar, '')::varchar -- Cl Ord ID
                             as roe
                  from (select t.tag_1
                             , t.security_type
                             , t.rl_parameter
                             , t.current_limit
                             , t.peak_value
                             , to_char(to_date(t.peak_date::varchar, 'YYYYMMDD'), 'MM/DD/YYYY') as peak_date
                             , t.cl_ord_id
                             , t.peak_id
                        from --trash.sdn_tmp_risk_peak_conumption t
                             tmp_risk_peak_conumption t) t
                  order by t.tag_1, t.rl_parameter, t.security_type, t.peak_id) s;

    end if;

exception
    when others then
        select public.load_log(l_load_id, l_step_id, 'dash360.report_risk_baml_peak_consumption_file ERROR=====', 0,
                               'E')
        into l_step_id;
        GET STACKED DIAGNOSTICS text_var1 = MESSAGE_TEXT,
            text_var2 = PG_EXCEPTION_DETAIL,
            text_var3 = PG_EXCEPTION_HINT;
        raise notice '% | % | %', text_var1, text_var2, text_var3;
    --DEALLOCATE ords_upd;
end;
$function$
;






--------------------------
create temp table tmp_to_do1 as
-- EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON)
select fyc.account_id
     , fyc.order_id
     , fyc.client_order_id -- fyc.order_id will be removed to group by cl_ord_id
     , to_char(fyc.routed_time, 'YYYYMMDD')::integer                     as create_date_id
     , fyc.multileg_reporting_type
     , fyc.instrument_type_id
     , case when fyc.cross_order_id is not null then true else false end as is_cross
     , fyc.order_qty
     , case
           when fyc.instrument_type_id = 'E'
               then abs(fyc.order_qty *
                        coalesce(
                                (case --when fyc.order_type_id <> '1' then fyc.order_price
                                     when fyc.side in ('1', '3')
                                         then fyc.nbbo_ask_price -- fyc.order_type_id = '1' and
                                     when fyc.side not in ('1', '3')
                                         then fyc.nbbo_bid_price -- fyc.order_type_id = '1' and
                                    end), 0))
           when fyc.instrument_type_id = 'O'
               then fyc.order_qty * os.contract_multiplier *
                    coalesce(
                            (case --when fyc.order_type_id <> '1' then fyc.order_price
                                 when fyc.side in ('1', '3')
                                     then abs(fyc.nbbo_ask_price) -- fyc.order_type_id = '1' and
                                 when fyc.side not in ('1', '3')
                                     then -abs(fyc.nbbo_bid_price) -- fyc.order_type_id = '1' and -- sell will summarizing as minus
                                end), 0)
    end                                                                  as order_notional
     , case
           when fyc.instrument_type_id = 'E'
               then tag_10504_equity_order_notional::numeric
           when fyc.instrument_type_id = 'O'
               then tag_10505_option_order_notional::numeric
    end                                                                  as fix_order_notional
     , case
           when fyc.multileg_reporting_type = '2' and fyc.instrument_type_id = 'E'
               then abs(tr.principal_amount)
           when fyc.multileg_reporting_type = '2' and
                fyc.instrument_type_id = 'O' and fyc.side = '1'
               then abs(tr.principal_amount)
           when fyc.multileg_reporting_type = '2' and
                fyc.instrument_type_id = 'O' and fyc.side <> '1'
               then -abs(tr.principal_amount)
    end                                                                  as principal_amount
--, fyc.order_type_id, fyc.side, fyc.order_price
--data_marts.f_yield_capture fyc
         from data_marts.f_yield_capture fyc
         left join dwh.d_option_contract oc on fyc.instrument_id = oc.instrument_id
         left join dwh.d_option_series os on oc.option_series_id = os.option_series_id
         left join lateral
                         (
                         select j.fix_message ->> '10504' as tag_10504_equity_order_notional
                              , j.fix_message ->> '10505' as tag_10505_option_order_notional
                         --, j.*
                         from fix_capture.fix_message_json j
                         where true
                           and j.fix_message_id = fyc.order_fix_message_id
                           and j.date_id between :l_start_date_id and :l_end_date_id -- 20210701 and 20210731 --
                           and j.date_id = fyc.status_date_id
                           and fyc.cross_order_id is null

                         limit 1
                         ) fx on true
         left join lateral
                         (
                         select tr.order_id
                              , sum(abs(tr.principal_amount)) as principal_amount
                         from dwh.flat_trade_record tr
                         where tr.date_id between :l_start_date_id and :l_end_date_id -- 20210701 and 20210731 --
                           and tr.order_id = fyc.order_id
                           and tr.is_busted = 'N'
                           -- equity multileg crosses(legs) Single Cross Options - via NBBO. Single Equities cannot be part of Crosses
                           -- and fyc.instrument_type_id in ('E', 'O')
                           and fyc.multileg_reporting_type = '2'                    -- cross multilegs only
                           and fyc.cross_order_id is not null
                         group by tr.order_id
                         limit 1
                         ) tr on true
         left join lateral
                         (
                         select ex.order_status, ex.exec_type
                         from dwh.execution ex
                         where ex.order_id = fyc.order_id
                           and (ex.order_status = '8' or ex.exec_type = '8')
                           --and ex.exec_date_id >= fyc.status_date_id
                           and ex.exec_date_id between :l_start_date_id and :l_end_date_id
                         limit 1
                         ) rj on true
where true
  --and rj.order_status is null -- exclude rejects
  and case
          when :l_is_include_rejected_order = 'Y' then true else rj.order_status is null end
           and fyc.account_id = any(:l_account_ids)
           and fyc.status_date_id between :l_start_date_id and :l_end_date_id -- 20210701 and 20210930 --
           and to_char(fyc.routed_time, 'YYYYMMDD')::varchar = fyc.status_date_id::varchar
                  and fyc.parent_order_id is null


select * from tmp_to_do1