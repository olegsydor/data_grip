select *
from dash360.report_compliance_avg_parent_order_count(in_start_date_id := 20250303, in_end_date_id := 20250315
    , in_trading_firm_ids := '{alpaca,caerus}'
    , in_account_ids := '{71912, 72420, 72917}'
     , in_instrument_type_id := null
     );

select *
from dash360.report_compliance_avg_parent_order_count(
        in_trading_firm_ids := '{OFP0058,OFP0077,t3trade01}',
        in_instrument_type_id := null
     );


-- DROP FUNCTION dash360.report_compliance_avg_parent_order_count(int4, int4, _varchar, _int4, bpchar);

CREATE OR REPLACE FUNCTION dash360.report_compliance_avg_parent_order_count(in_start_date_id integer DEFAULT NULL::integer,
                                                                            in_end_date_id integer DEFAULT NULL::integer,
                                                                            in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[],
                                                                            in_account_ids integer[] DEFAULT '{}'::integer[],
                                                                            in_instrument_type_id character DEFAULT 'O'::bpchar)
    RETURNS TABLE
            (
                ret_row text
            )
    LANGUAGE plpgsql
AS
$function$
    -- https://dashfinancial.atlassian.net/browse/DEVREQ-6008
declare
    l_load_id       int;
    l_row_cnt       int;
    l_step_id       int;
    l_account_ids   int4[];
    l_message       text;
    l_start_date    date := case
                                when in_start_date_id is not null then in_start_date_id::text::date
                                else date_trunc('month', current_date - '1 month'::interval)::date end;
    l_end_date      date := case
                                when in_end_date_id is not null then in_end_date_id::text::date
                                else (date_trunc('month', current_date) - '1 day'::interval)::date end;
    l_start_date_id int4 := to_char(l_start_date, 'YYYYMMDD');
    l_end_date_id   int4 := to_char(l_end_date, 'YYYYMMDD');
    l_all_days      int4;
begin
    if coalesce(in_account_ids, '{}') = '{}' and coalesce(in_trading_firm_ids, '{}') = '{}' then
        l_account_ids := '{}';
    else
        select array_agg(account_id)
        into l_account_ids
        from dwh.d_account
        where true
          and is_active
          and case
                  when coalesce(in_trading_firm_ids, '{}') <> '{}'::varchar[]
                      then trading_firm_id = ANY (in_trading_firm_ids)
                  else true end
          and case
                  when coalesce(in_account_ids, '{}') <> '{}'::integer[] then account_id = ANY (in_account_ids)
                  else true end;
    end if;

    l_message =
            'report_compliance_avg_parent_order_count' ||
            case
                when in_account_ids = '{}' then ''
                else ' accounts-' || left(array_to_string(in_account_ids::int4[], ',', '')::text, 50) end ||
            case
                when in_trading_firm_ids = '{}' then ''
                else ' trading_firm-' ||
                     left(array_to_string(in_trading_firm_ids::varchar[], ',', '')::text, 50) end ||
            ' for ' || l_start_date_id::text || '-' || l_end_date_id::text ||
            ' ';

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           l_message || 'STARTED ===', 0, 'O')
    into l_step_id;

    select count(*)
    into l_all_days
    from (select generate_series(l_start_date, l_end_date, '1 day')::date as dt) x
    where extract(dow from x.dt) between 1 and 5
      and not exists (select null from public.holiday_calendar hc where hc.holiday_date = x.dt and hc.is_active);

    drop table if exists t_report;
    create temp table t_report as
    select to_char(hods."StatusDate", 'Month') as "Month",
           to_char(hods."StatusDate", 'YYYY')  as "Year",
           count(distinct "StatusDate")        as "Actual Trading Days",
           tf.trading_firm_name::varchar       as "Firm",
           a.account_name::varchar             as "Account",
           cf.customer_or_firm_name::varchar   as "Capacity",
           count(distinct hods."ClOrdID")      as "Parent Order Count",
           hods."InstrumentType"
    from dwh.historic_order_details_storage hods
             join dwh.d_account a on (a.account_id = hods."AccountID")
             join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
--              left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = hods."CustomerOrFirm")
             left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = a.opt_customer_or_firm)
    where true
      and "Status_Date_id" >= l_start_date_id
      and "Status_Date_id" <= l_end_date_id
      and case when in_instrument_type_id is null then true else hods."InstrumentType" = in_instrument_type_id end
      and hods."CustomerOrderID" is null
      and hods."AccountID" = any (l_account_ids)
    group by to_char(hods."StatusDate", 'Month'), to_char(hods."StatusDate", 'YYYY'), a.account_name,
             cf.customer_or_firm_name, tf.trading_firm_name, hods."InstrumentType";

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           l_message || ' data set calculated', l_row_cnt, 'O')
    into l_step_id;

    return query
        select 'Firm,Account,Capacity,Year,Month,Calendar Trading Days,Actual Trading Days,Total Orders';
    return query
        select array_to_string(ARRAY [
                                   "Firm",
                                   "Account",
                                   "Capacity",
                                   "Year",
                                   trim("Month"),
                                   l_all_days::text,
                                   "Actual Trading Days"::text,
                                   "Parent Order Count"::text
                                   ], ',', '')
        from t_report
        order by "Firm", "Account", "Capacity", "Year", trim("Month");
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           l_message || ' COMPLETED=====', l_row_cnt, 'O')
    into l_step_id;

end;
$function$
;


select * from t_report
select trim(to_char(:"Period", 'Month')) May;

select to_char(to_date(:proforma_invoice_date, 'DD/MM/YYYY'), 'Month')

    select to_date(:proforma_invoice_date, 'DD/MM/YYYY')
select array_to_string('{1, 2, 3}'::int4[], ',', '');

select 'report_compliance_avg_parent_order_count, ' ||
            case when :in_account_ids = '{}' then '' else 'accounts-' || left(array_to_string(:in_account_ids::int4[], ',', '')::text, 50) end ||
            case
                when :in_trading_firm_ids = '{}' then ''
                else ', trading_firm-' || left(array_to_string(:in_trading_firm_ids::varchar[], ',', '')::text, 50) end ||
            ' for ' || :l_start_date_id::text || '-' || :l_end_date_id::text ||
            ' ';



select to_char(hods."StatusDate", 'Month') as "Month",
           to_char(hods."StatusDate", 'YYYY')  as "Year",
           count(distinct "StatusDate")        as "Actually Trading Days",
           tf.trading_firm_name::varchar       as "Firm",
           a.account_name::varchar             as "Account",
           cf.customer_or_firm_name::varchar   as "Capacity",
           count(distinct hods."ClOrdID")      as "Parent Order Count",
           hods."InstrumentType"
    from dwh.historic_order_details_storage hods
             join dwh.d_account a on (a.account_id = hods."AccountID")
             join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
             left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = a.opt_customer_or_firm)
    where true
      and "Status_Date_id" >= :l_start_date_id
      and "Status_Date_id" <= :l_end_date_id
      and case when :in_instrument_type_id is null then true else hods."InstrumentType" = :in_instrument_type_id end
      and hods."CustomerOrderID" is null
      and hods."AccountID" = any (:l_account_ids) -- '{54612,54613,54690,54691,62093,62577,72945,73094}'
      and hods."AccountID" = 71783
    group by to_char(hods."StatusDate", 'Month'), to_char(hods."StatusDate", 'YYYY'), a.account_name,
             cf.customer_or_firm_name, tf.trading_firm_name,hods."InstrumentType";



        select --co.create_time::date                as "Period",
               tf.trading_firm_name::varchar       as "Trading Firm",
               a.account_name::varchar             as "Account",
               cf.customer_or_firm_name::varchar   as "Capacity",
               count(distinct co.client_order_id)  as "Parent Order Count"
        from dwh.client_order co
                 join dwh.d_instrument i on (i.instrument_id = co.instrument_id)
                 join dwh.d_account a on (a.account_id = co.account_id)
                 join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
--                  left join dwh.d_customer_or_firm cf
--                            on (cf.customer_or_firm_id = coalesce(co.customer_or_firm_id, a.opt_customer_or_firm))
                 left join dwh.d_customer_or_firm cf
                           on (cf.customer_or_firm_id = coalesce(a.opt_customer_or_firm))


        where true
          and co.create_date_id between :l_start_date_id and :l_end_date_id
          and co.parent_order_id is null
        and co.account_id = 71783
--           and case when in_instrument_type_id is null then true else i.instrument_type_id = in_instrument_type_id end
        group by --"Period",
                 "Account", "Capacity", "Trading Firm";


        select string_agg(account_id::text, ', ')
        from dwh.d_account
        where true
          and case
                  when coalesce(:in_trading_firm_ids, '{}') <> '{}'::varchar[]
                      then trading_firm_id = ANY (:in_trading_firm_ids)
                  else true end
        and is_active


        select * from dwh.d_account
        where trading_firm_id ilike '%T3%'

        select * from dwh.d_trading_firm
        where trading_firm_id = any('{OFP0058,OFP0077,t3trade01}')
        and is_active


         create temp table t_report as
    select to_char(hods."StatusDate", 'Month') as "Month",
           to_char(hods."StatusDate", 'YYYY')  as "Year",
           count(distinct "StatusDate")        as "Actual Trading Days",
           tf.trading_firm_name::varchar       as "Firm",
           a.account_name::varchar             as "Account",
           cf.customer_or_firm_name::varchar   as "Capacity",
           count(distinct hods."ClOrdID")      as "Parent Order Count",
           hods."InstrumentType"
    from dwh.historic_order_details_storage hods
             join dwh.d_account a on (a.account_id = hods."AccountID")
             join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
--              left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = hods."CustomerOrFirm")
                 left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = a.opt_customer_or_firm)
    where true
      and "Status_Date_id" >= :l_start_date_id
      and "Status_Date_id" <= :l_end_date_id
      and case when :in_instrument_type_id is null then true else hods."InstrumentType" = :in_instrument_type_id end
      and hods."CustomerOrderID" is null
      and hods."AccountID" = any (:l_account_ids)
    group by to_char(hods."StatusDate", 'Month'), to_char(hods."StatusDate", 'YYYY'), a.account_name,
             cf.customer_or_firm_name, tf.trading_firm_name,hods."InstrumentType";


19864, 19865, 23198, 23199, 23200, 23201, 23202, 23203, 23204, 23205, 23206, 23208, 23209, 23210, 23211, 23403, 23405, 23670, 24529, 25236, 25911, 26031, 26112, 26149, 26289, 27409, 28412, 28669, 28670, 28849, 29099, 34189, 35735, 36269, 36656, 36678, 36698, 38407, 38412, 38928, 51781, 52723, 52724, 53341, 53384, 53469, 53731, 53742, 53745, 53770, 53980, 53982, 53983, 53984, 53986, 53987, 53988, 53989, 53990, 54051, 54087, 54153, 54157, 54158, 54191, 54209, 54210, 54211, 54212, 54213, 54214, 54215, 54216, 54217, 54218, 54219, 54220, 54221, 54222, 54223, 54224, 54383, 54493, 54494, 54572, 54597, 54612, 54613, 54625, 54656, 54677, 54678, 54679, 54690, 54691, 54858, 54859, 54860, 54861, 54862, 54863, 54864, 54865, 54866, 54867, 54868, 54869, 54870, 54871, 54872, 54907, 55034, 55035, 55155, 55315, 55457, 55474, 55478, 55481, 55485, 55489, 55555, 55572, 55576, 55594, 55972, 56152, 56192, 56758, 56858, 56972, 57032, 57058, 57193, 57292, 57312, 57514, 57632, 57674, 57752, 57912, 57988, 58229, 58269, 58330, 58419, 58473, 58870, 58949, 59009, 59169, 59489, 59629, 60229, 61089, 61093, 61094, 61095, 61096, 61097, 61098, 61099, 61730, 61834, 61835, 61846, 62012, 62013, 62075, 62093, 62095, 62467, 62476, 62478, 62577, 62578, 62645, 62968, 62969, 62976, 63047, 63048, 63257, 63258, 63318, 63319, 63355, 63519, 63690, 63697, 63734, 63833, 63852, 63871, 64657, 64821, 64927, 65021, 66300, 66377, 66452, 67487, 67940, 67941, 67962, 68040, 68478, 68536, 68622, 68623, 68864, 69151, 69152, 69246, 69280, 69290, 69424, 69432, 69545, 69551, 69553, 69554, 69555, 69556, 69557, 69560, 69802, 69804, 69806, 69813, 69820, 69826, 69888, 69898, 69900, 69901, 69951, 69952, 70001, 70002, 70003, 70038, 70039, 70213, 71117, 71580, 71695, 72113, 72451, 73083, 73084, 55952, 73524, 73127, 57652, 55479, 71700, 73637, 73867, 63571, 71751, 55476, 67957, 71756, 71792, 73931, 72992, 56953, 71850, 55480, 55490, 55483, 72335, 55473, 72482, 71789, 57412, 71811, 71812, 71785, 71787, 71795, 71802, 71808, 71824, 71848, 71849, 71855, 71868, 71733, 71736, 71737, 71742, 71746, 71755, 71758, 71761, 71762, 71730, 71731, 71738, 71740, 71743, 71753, 71765, 71801, 71815, 71817, 71831, 71832, 71744, 71763, 71828, 71866, 71764, 71768, 71771, 71778, 71781, 71784, 71793, 71846, 71847, 71873, 72081, 72084, 72087, 72088, 72114, 72128, 72301, 72453, 72490, 72943, 72952, 72961, 73089, 73298, 73499, 73573, 73623, 73830, 73960, 73993, 73868, 71865, 72929, 73959, 55477, 55484, 55486, 71874, 71749, 72991, 71829, 71735, 71779, 74049, 69552, 69896, 71788, 71766, 55488, 71741, 71790, 71823, 71864, 73081, 74141, 71853, 74156, 72945, 74140, 71833, 73953, 74098, 71734, 71775, 71820, 71845, 72083, 71839, 71867, 71870, 73454, 73685, 73693, 71772, 71821, 71875, 74157, 53985, 71809, 71791, 72085, 73706, 72302, 55475, 55482, 71732, 71786, 71807, 71825, 71877, 72089, 73094, 73480, 73656, 73566, 73996, 74050, 58549, 62550, 69548, 71752, 71803, 71827, 71830, 71834, 71837, 71838, 71851, 71859, 71860, 71869, 72086, 72433, 72800, 72986, 73095, 73292, 73884, 74047, 23207, 53981, 54152, 55487, 62431, 62542, 63253, 64894, 68334, 68709, 69207, 71304, 71739, 71745, 71747, 71748, 71750, 71754, 71757, 71759, 71760, 71767, 71769, 71770, 71773, 71774, 71776, 71777, 71780, 71782, 71783, 71794, 71796, 71797, 71798, 71799, 71800, 71804, 71805, 71806, 71810, 71813, 71814, 71816, 71818, 71819, 71822, 71826, 71835, 71836, 71840, 71841, 71842, 71843, 71844, 71852, 71854, 71856, 71857, 71858, 71861, 71862, 71863, 71871, 71872, 71876, 72082, 72117, 72452, 72918, 72942, 73021, 73090, 73403, 73570, 73595, 73653, 73900, 73915, 74053, 74055, 74090
19864, 19865, 23198, 23199, 23200, 23201, 23202, 23203, 23204, 23205, 23206, 23208, 23209, 23210, 23211, 23403, 23405, 23670, 24529, 25236, 25911, 26031, 26112, 26149, 26289, 27409, 28412, 28669, 28670, 28849, 29099, 34189, 35735, 36269, 36656, 36678, 36698, 38407, 38412, 38928, 51781, 52723, 52724, 53341, 53384, 53469, 53731, 53742, 53745, 53770, 53980, 53982, 53983, 53984, 53986, 53987, 53988, 53989, 53990, 54051, 54087, 54153, 54157, 54158, 54191, 54209, 54210, 54211, 54212, 54213, 54214, 54215, 54216, 54217, 54218, 54219, 54220, 54221, 54222, 54223, 54224, 54383, 54493, 54494, 54572, 54597, 54625, 54656, 54677, 54678, 54679, 54858, 54859, 54860, 54861, 54862, 54863, 54864, 54865, 54866, 54867, 54868, 54869, 54870, 54871, 54872, 54907, 55034, 55035, 55155, 55457, 55474, 55478, 55481, 55485, 55489, 55555, 55572, 55576, 55594, 55972, 56152, 56192, 56758, 56858, 56972, 57032, 57058, 57193, 57292, 57312, 57514, 57632, 57674, 57752, 57912, 57988, 58229, 58269, 58330, 58419, 58473, 58870, 58949, 59009, 59169, 59489, 59629, 60229, 61089, 61093, 61094, 61095, 61096, 61097, 61098, 61099, 61730, 61834, 61835, 61846, 62012, 62013, 62075, 62095, 62467, 62476, 62478, 62578, 62645, 62969, 62976, 63047, 63048, 63257, 63258, 63318, 63319, 63355, 63519, 63690, 63697, 63734, 63833, 63852, 63871, 64657, 64821, 64927, 65021, 66300, 66377, 66452, 67487, 67940, 67941, 67962, 68040, 68478, 68536, 68622, 68623, 68864, 69151, 69152, 69246, 69280, 69290, 69424, 69432, 69545, 69553, 69554, 69555, 69556, 69557, 69560, 69802, 69804, 69806, 69813, 69820, 69826, 69888, 69898, 69900, 69901, 69951, 69952, 70001, 70002, 70003, 70038, 70039, 70213, 71117, 71580, 71695, 72451, 73083, 73084, 55952, 73524, 73127, 57652, 55479, 71700, 73637, 73867, 63571, 71751, 55476, 67957, 71756, 71792, 73931, 72992, 56953, 71850, 55480, 55490, 55483, 72335, 55473, 72482, 71789, 57412, 71811, 71812, 71785, 71787, 71795, 71802, 71808, 71824, 71848, 71849, 71855, 71868, 71733, 71736, 71737, 71742, 71746, 71755, 71758, 71761, 71762, 71730, 71731, 71738, 71740, 71743, 71753, 71765, 71801, 71815, 71817, 71831, 71832, 71744, 71763, 71828, 71866, 71764, 71768, 71771, 71778, 71781, 71784, 71793, 71846, 71847, 71873, 72081, 72084, 72087, 72088, 72114, 72128, 72301, 72453, 72490, 72943, 72952, 72961, 73089, 73298, 73499, 73573, 73623, 73830, 73960, 73993, 73868, 71865, 72929, 73959, 55477, 55484, 55486, 71874, 71749, 72991, 71829, 71735, 71779, 74049, 69552, 69896, 71788, 71766, 55488, 71741, 71790, 71823, 71864, 73081, 74141, 71853, 74156, 72945, 74140, 71833, 73953, 74098, 71734, 71775, 71820, 71845, 72083, 71839, 71867, 71870, 73454, 73685, 73693, 71772, 71821, 71875, 74157, 53985, 71809, 71791, 72085, 73706, 72302, 55475, 55482, 71732, 71786, 71807, 71825, 71877, 72089, 73094, 73480, 73656, 73566, 73996, 74050, 58549, 62550, 69548, 71752, 71803, 71827, 71830, 71834, 71837, 71838, 71851, 71859, 71860, 71869, 72086, 72433, 72800, 72986, 73095, 73292, 73884, 74047, 23207, 53981, 54152, 55487, 62431, 62542, 63253, 64894, 68334, 68709, 69207, 71304, 71739, 71745, 71747, 71748, 71750, 71754, 71757, 71759, 71760, 71767, 71769, 71770, 71773, 71774, 71776, 71777, 71780, 71782, 71783, 71794, 71796, 71797, 71798, 71799, 71800, 71804, 71805, 71806, 71810, 71813, 71814, 71816, 71818, 71819, 71822, 71826, 71835, 71836, 71840, 71841, 71842, 71843, 71844, 71852, 71854, 71856, 71857, 71858, 71861, 71862, 71863, 71871, 71872, 71876, 72082, 72117, 72452, 72918, 72942, 73021, 73090, 73403, 73570, 73595, 73653, 73900, 73915, 74053, 74055, 74090

select *
from dash360.report_compliance_avg_parent_order_count(in_start_date_id := 20250325, in_end_date_id := 20250325
    , in_trading_firm_ids := '{OFP0058,OFP0077,t3trade01}'
     );

select "OrderID", fmj.*, hods.""
from dwh.historic_order_details_storage hods
join lateral(select fmj.fix_message ->> '10147' as t10147
             from dwh.client_order co join fix_capture.fix_message_json fmj on fmj.fix_message_id = co.fix_message_id where co.order_id = hods."OrderID" limit 1) fmj on true
where true
      and "Status_Date_id" >= :l_start_date_id
      and "Status_Date_id" <= :l_end_date_id
      and case when :in_instrument_type_id is null then true else hods."InstrumentType" = :in_instrument_type_id end
      and hods."CustomerOrderID" is null
      and hods."AccountID" = any (:l_account_ids)
