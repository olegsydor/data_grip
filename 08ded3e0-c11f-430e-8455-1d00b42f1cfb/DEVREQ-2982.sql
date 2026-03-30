alter function billing.generic_trade_details_report set schema trash;

CREATE OR REPLACE FUNCTION billing.generic_trade_details_report(in_date_begin integer, in_date_end integer,
                                                                in_billing_entities text[] DEFAULT '{}'::text[],
                                                                in_account text[] DEFAULT '{}'::text[],
                                                                in_instrument_type text default null,
                                                                in_companies text[] default null::text[]
)
    RETURNS TABLE
            (
                "Billing Entity"       varchar(50),
                "User"                 varchar,
                "Exchange"             varchar,
                "Symbol"               varchar(100),
                "Expiration"           date,
                "Strike"               numeric,
                "OSI Series"           varchar,
                "C/P"                  varchar(100),
                "B/S"                  varchar(100),
                "Filled Qty"           int4,
                "Limit Price"          numeric,
                "Exec Price"           numeric(20, 6),
                "Principal Amount"     numeric,
                "Date"                 date,
                "Order Type"           varchar(100),
                "Giveup"               varchar(100),
                "CMTA Firm"            varchar(100),
                "Range"                varchar(100),
                "Account"              varchar(100),
                "Company"              varchar(100),
                "Dest Company"         varchar(100),
                "Electronic"           varchar(100),
                "Leg Number"           text,
                "Single/Complex"       varchar,
                "Connection"           varchar(100),
                "Sub Strategy"         text,
                "Security Type"        varchar(50),
                "Crossing"             varchar,
                "Penny"                varchar,
                "Symbol Type"          varchar(100),
                "PTM ID"               int8,
                "Link Exch"            varchar(100),
                "Ex Destination"       varchar(32),
                "Order ID"             int8,
                "Report ID"            int8,
                "ClOrdID"              varchar(150),
                "Liquidity Flag"       varchar(50),
                "LP/Dash"              varchar(64),
                "Open/Close"           varchar(12),
                "Cross Type"           varchar(50),
                "Customer Billing Tag" varchar(20),
                "ATS Channel"          varchar(32),
                "FIX Comp ID"          varchar(100),
                "Is Marketable"        text,
                "Sub Account 3"        varchar(100),
                "Exec Broker"          varchar(50),
                "OCC Actionable ID"    varchar,
                "Contra Party"         varchar(100),
                "Commission Rate"      numeric,
                "Commission Amount"    numeric,
                "Exchange Rate"        numeric,
                "Exchange Amount"      numeric,
                "Tier Rate"            numeric,
                "Tier Amount"          numeric,
                "LADR"                 numeric,
                "LADR$"                numeric,
                "LAST"                 numeric,
                "LAST$"                numeric,
                "DMOF"                 numeric,
                "DMOF$"                numeric,
                "SOFT"                 numeric,
                "SOFT$"                numeric,
                "ETF"                  numeric,
                "ETF$"                 numeric,
                "MTF"                  numeric,
                "MTF$"                 numeric,
                "SRCTF"                numeric,
                "SRCTF$"               numeric,
                "LTF"                  numeric,
                "LTF$"                 numeric,
                "TPF"                  numeric,
                "TPF$"                 numeric,
                "GUTF"                 numeric,
                "GUTF$"                numeric,
                "PSTF"                 numeric,
                "PSTF$"                numeric,
                "BZEX_Tier"            numeric,
                "BZEX_Tier$"           numeric,
                "ARCA_Tier"            numeric,
                "ARCA_Tier$"           numeric,
                "MPRL_Tier"            numeric,
                "MPRL_Tier$"           numeric,
                "NOM_Tier"             numeric,
                "NOM_Tier$"            numeric,
                "PHLX_Tier"            numeric,
                "PHLX_Tier$"           numeric,
                "GMNI_Tier"            numeric,
                "GMNI_Tier$"           numeric,
                "BOX_Tier"             numeric,
                "BOX_Tier$"            numeric,
                "CBOE_Tier"            numeric,
                "CBOE_Tier$"           numeric,
                "PFOFBRO"              numeric,
                "PFOFBRO$"             numeric,
                "BPCR"                 numeric,
                "BPCR$"                numeric,
                "DAEF"                 numeric,
                "DAEF$"                numeric,
                "DMST"                 numeric,
                "DMST$"                numeric,
                "TTCF"                 numeric,
                "TTCF$"                numeric,
                "BADR"                 numeric,
                "BADR$"                numeric,
                "OIRGPMT"              numeric,
                "OIRGPMT$"             numeric,
                "SECFEE"               numeric,
                "SECFEE$"              numeric,
                "TAF"                  numeric,
                "TAF$"                 numeric,
                "CATTF"                numeric,
                "CATTF$"               numeric,
                "PFOFTF"               numeric,
                "PFOFTF$"              numeric,
                "PFOFRB"               numeric,
                "PFOFRB$"              numeric,
                "TIERS"                numeric,
                "TIERS$"               numeric,
                "SPRTF"                numeric,
                "SPRTF$"               numeric,
                "REBATE"               numeric,
                "REBATE$"              numeric,
                "OCC"                  numeric,
                "OCC$"                 numeric,
                "ECC"                  numeric,
                "ECC$"                 numeric,
                "EAC"                  numeric,
                "EAC$"                 numeric,
                "NSCC"                 numeric,
                "NSCC$"                numeric,
                "CMTA"                 numeric,
                "CMTA$"                numeric,
                "MARS"                 numeric,
                "MARS$"                numeric,
                "MORP"                 numeric,
                "MORP$"                numeric,
                "QCC"                  numeric,
                "QCC$"                 numeric,
                "CVIP"                 numeric,
                "CVIP$"                numeric,
                "WRA"                  numeric,
                "WRA$"                 numeric,
                "CBOEMM"               numeric,
                "CBOEMM$"              numeric,
                "3PPT"                 numeric,
                "3PPT$"                numeric,
                "CRR"                  numeric,
                "CRR$"                 numeric,
                "CMDT"                 numeric,
                "CMDT$"                numeric,
                "DATS"                 numeric,
                "DATS$"                numeric,
                "EQTYTIERS"            numeric,
                "EQTYTIERS$"           numeric
            )
    LANGUAGE plpgsql
AS
$function$
    -- SO 20260330 https://dashfinancial.atlassian.net/browse/DEVREQ-2982
declare
    l_billing_entities text[];
    l_date_begin       date := in_date_begin::text::date;
    l_date_end         date := in_date_end::text::date;
    l_load_id          int;
    l_row_cnt          int;
    l_step_id          int;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'generic_trade_details_report for ' || l_date_begin::text || '-' ||
                           l_date_end::text || ' STARTED ===', 0, 'O')
    into l_step_id;

    l_billing_entities := case
                              when in_billing_entities = '{}' --and p_606s3_file_type = 'S3_Vision'
                                  then ARRAY ['VFM','VIS','OEVFM','VISNCBOE','VFM2']
                              else in_billing_entities
        end;
    
    select tcb.billingentity                                             as "Billing Entity",
           tcb."USER"                                                    as "User",
           tcb.exchange                                                  as "Exchange",
           tcb.symbol                                                    as "Symbol",
           tcb.expiration                                                as "Expiration",
           tcb.strike                                                    as "Strike",
           coalesce(tcb.osiseries, tcb.symbol)                           as "OSI Series",
           tcb."C/P",
           tcb."B/S",
           tcb."FILLED QTY"                                              as "Filled Qty",
           --tr.price_limit as "Limit Price",
           null::numeric                                                 as "Limit Price",
           tcb.premium                                                   as "Exec Price",
           case
               when tcb."C/P" = 'S' then tcb."FILLED QTY" * tcb.premium
               when tcb."C/P" in ('C', 'P')
                   then tcb."FILLED QTY" * tcb.premium * 100 --coalesce(tr.contract_multiplier, 100)
               end                                                       as "Principal Amount",
           tcb."date"                                                    as "Date",
           tcb."ORDER TYPE"                                              as "Order Type",
           tcb.giveup                                                    as "Giveup",
           tcb."CMTA FIRM"                                               as "CMTA Firm",
           tcb."range"                                                   as "Range",
           tcb.account                                                   as "Account",
           tcb.company                                                   as "Company",
           tcb."DEST COMPANY"                                            as "Dest Company",
           tcb.electronic                                                as "Electronic",
           tcb."LEG NUMBER"                                              as "Leg Number",
           case
               when tcb."LEG NUMBER" = '1/1' then 'Single-Leg'
               else 'Complex'
               end::varchar                                              as "Single/Complex",
           --tcb.handling as "Handling",
           tcb."connection"                                              as "Connection",
           case
               when lower(tcb."connection") like lower(concat(tcb.exchange, ' dash%')) then 'DMA'
               when lower(tcb."connection") like '%blaze%' then tcb."connection"
               --when tcb.electronic = 'MANUAL' then 'BROKERPOINT'
               else coalesce(substring(tcb."connection" from '.+?(?= |\+|-)'), tcb."connection")
               end                                                       as "Sub Strategy",
           tcb."SECURITY TYPE"                                           as "Security Type",
           (case when tcb.crossing = '1' then 'Y' else 'N' end)::varchar as "Crossing",
           (case when tcb.penny = '1' then 'Y' else 'N' end)::varchar    as "Penny",
           tcb."SYMBOL TYPE"                                             as "Symbol Type",
           tcb.ptm_id                                                    as "PTM ID",
           tcb."LINK EXCH"                                               as "Link Exch",
           tcb.parentexdestination                                       as "Ex Destination",
           tcb.order_id                                                  as "Order ID",
           tcb.report_id                                                 as "Report ID",
           tcb.cl_ord_id                                                 as "ClOrdID",
           tcb.liquidityflag                                             as "Liquidity Flag",
           tcb.lp_dash                                                   as "LP/Dash",
           tcb.open_close                                                as "Open/Close",
           tcb.cross_type                                                as "Cross Type",
           tcb.custom_billing_tag                                        as "Customer Billing Tag",
           tcb.ats_channel                                               as "ATS Channel",
           tcb.fix_comp_id                                               as "FIX Comp ID",
           case when tcb.is_marketable = '1' then 'Y' else 'N' end       as "Is Marketable",
           tcb.subaccount3                                               as "Sub Account 3",
           tcb.street_exec_broker                                        as "Exec Broker",
           tcb.occ_actionable_id                                         as "OCC Actionable ID",
           od.contraparty                                                as "Contra Party",
           round((
                     coalesce(tcb."LADR", 0.0) +
                     coalesce(tcb."LAST", 0.0) +
                     coalesce(tcb."DMOF", 0.0) +
                     coalesce(tcb."SOFT", 0.0)
                     )::numeric, 6)                                      as "Commission Rate",
           round((
                     coalesce(tcb."LADR$", 0.0) +
                     coalesce(tcb."LAST$", 0.0) +
                     coalesce(tcb."DMOF$", 0.0) +
                     coalesce(tcb."SOFT$", 0.0)
                     )::numeric, 6)                                      as "Commission Amount",
           round((
                     coalesce(tcb."ETF", 0.0) +
                     coalesce(tcb."LTF", 0.0) +
                     coalesce(tcb."MTF", 0.0) +
                     coalesce(tcb."SRCTF", 0.0) +
                     coalesce(tcb."TPF", 0.0) +
                     coalesce(tcb."PSTF", 0.0) +
                     coalesce(tcb."GUTF", 0.0)
                     )::numeric, 6)                                      as "Exchange Rate",
           round((
                     coalesce(tcb."ETF$", 0.0) +
                     coalesce(tcb."LTF$", 0.0) +
                     coalesce(tcb."MTF$", 0.0) +
                     coalesce(tcb."SRCTF$", 0.0) +
                     coalesce(tcb."TPF$", 0.0) +
                     coalesce(tcb."PSTF$", 0.0) +
                     coalesce(tcb."GUTF$", 0.0)
                     )::numeric, 6)                                      as "Exchange Amount",
           round((
                     coalesce(tcb."TIERS", 0.0) +
                     coalesce(tcb."BZEX_Tier", 0.0) +
                     coalesce(tcb."ARCA_Tier", 0.0) +
                     coalesce(tcb."MPRL_Tier", 0.0) +
                     coalesce(tcb."NOM_Tier", 0.0) +
                     coalesce(tcb."PHLX_Tier", 0.0) +
                     coalesce(tcb."GMNI_Tier", 0.0) +
                     coalesce(tcb."CBOE_Tier", 0.0) +
                     coalesce(tcb."EQTYTIERS", 0.0) +
                     coalesce(tcb."BOX_Tier", 0.0)
                     )::numeric, 6)                                      as "Tier Rate",
           round((
                     coalesce(tcb."TIERS$", 0.0) +
                     coalesce(tcb."BZEX_Tier$", 0.0) +
                     coalesce(tcb."ARCA_Tier$", 0.0) +
                     coalesce(tcb."MPRL_Tier$", 0.0) +
                     coalesce(tcb."NOM_Tier$", 0.0) +
                     coalesce(tcb."PHLX_Tier$", 0.0) +
                     coalesce(tcb."GMNI_Tier$", 0.0) +
                     coalesce(tcb."CBOE_Tier$", 0.0) +
                     coalesce(tcb."EQTYTIERS$", 0.0) +
                     coalesce(tcb."BOX_Tier$", 0.0)
                     )::numeric, 6)                                      as "Tier Amount",
           round(coalesce(tcb."LADR", 0.0)::numeric, 6)                  as "LADR",
           round(coalesce(tcb."LADR$", 0.0)::numeric, 6)                 as "LADR$",
           round(coalesce(tcb."LAST", 0.0)::numeric, 6)                  as "LAST",
           round(coalesce(tcb."LAST$", 0.0)::numeric, 6)                 as "LAST$",
           round(coalesce(tcb."DMOF", 0.0)::numeric, 6)                  as "DMOF",
           round(coalesce(tcb."DMOF$", 0.0)::numeric, 6)                 as "DMOF$",
           round(coalesce(tcb."SOFT", 0.0)::numeric, 6)                  as "SOFT",
           round(coalesce(tcb."SOFT$", 0.0)::numeric, 6)                 as "SOFT$",
           round(coalesce(tcb."ETF", 0.0)::numeric, 6)                   as "ETF",
           round(coalesce(tcb."ETF$", 0.0)::numeric, 6)                  as "ETF$",
           round(coalesce(tcb."MTF", 0.0)::numeric, 6)                   as "MTF",
           round(coalesce(tcb."MTF$", 0.0)::numeric, 6)                  as "MTF$",
           round(coalesce(tcb."SRCTF", 0.0)::numeric, 6)                 as "SRCTF",
           round(coalesce(tcb."SRCTF$", 0.0)::numeric, 6)                as "SRCTF$",
           round(coalesce(tcb."LTF", 0.0)::numeric, 6)                   as "LTF",
           round(coalesce(tcb."LTF$", 0.0)::numeric, 6)                  as "LTF$",
           round(coalesce(tcb."TPF", 0.0)::numeric, 6)                   as "TPF",
           round(coalesce(tcb."TPF$", 0.0)::numeric, 6)                  as "TPF$",
           round(coalesce(tcb."GUTF", 0.0)::numeric, 6)                  as "GUTF",
           round(coalesce(tcb."GUTF$", 0.0)::numeric, 6)                 as "GUTF$",
           round(coalesce(tcb."PSTF", 0.0)::numeric, 6)                  as "PSTF",
           round(coalesce(tcb."PSTF$", 0.0)::numeric, 6)                 as "PSTF$",
           round(coalesce(tcb."BZEX_Tier", 0.0)::numeric, 6)             as "BZEX_Tier",
           round(coalesce(tcb."BZEX_Tier$", 0.0)::numeric, 6)            as "BZEX_Tier$",
           round(coalesce(tcb."ARCA_Tier", 0.0)::numeric, 6)             as "ARCA_Tier",
           round(coalesce(tcb."ARCA_Tier$", 0.0)::numeric, 6)            as "ARCA_Tier$",
           round(coalesce(tcb."MPRL_Tier", 0.0)::numeric, 6)             as "MPRL_Tier",
           round(coalesce(tcb."MPRL_Tier$", 0.0)::numeric, 6)            as "MPRL_Tier$",
           round(coalesce(tcb."NOM_Tier", 0.0)::numeric, 6)              as "NOM_Tier",
           round(coalesce(tcb."NOM_Tier$", 0.0)::numeric, 6)             as "NOM_Tier$",
           round(coalesce(tcb."PHLX_Tier", 0.0)::numeric, 6)             as "PHLX_Tier",
           round(coalesce(tcb."PHLX_Tier$", 0.0)::numeric, 6)            as "PHLX_Tier$",
           round(coalesce(tcb."GMNI_Tier", 0.0)::numeric, 6)             as "GMNI_Tier",
           round(coalesce(tcb."GMNI_Tier$", 0.0)::numeric, 6)            as "GMNI_Tier$",
           round(coalesce(tcb."BOX_Tier", 0.0)::numeric, 6)              as "BOX_Tier",
           round(coalesce(tcb."BOX_Tier$", 0.0)::numeric, 6)             as "BOX_Tier$",
           round(coalesce(tcb."CBOE_Tier", 0.0)::numeric, 6)             as "CBOE_Tier",
           round(coalesce(tcb."CBOE_Tier$", 0.0)::numeric, 6)            as "CBOE_Tier$",
           round(coalesce(tcb."PFOFBRO", 0.0)::numeric, 6)               as "PFOFBRO",
           round(coalesce(tcb."PFOFBRO$", 0.0)::numeric, 6)              as "PFOFBRO$",
           round(coalesce(tcb."BPCR", 0.0)::numeric, 6)                  as "BPCR",
           round(coalesce(tcb."BPCR$", 0.0)::numeric, 6)                 as "BPCR$",
           round(coalesce(tcb."DAEF", 0.0)::numeric, 6)                  as "DAEF",
           round(coalesce(tcb."DAEF$", 0.0)::numeric, 6)                 as "DAEF$",
           round(coalesce(tcb."DMST", 0.0)::numeric, 6)                  as "DMST",
           round(coalesce(tcb."DMST$", 0.0)::numeric, 6)                 as "DMST$",
           round(coalesce(tcb."TTCF", 0.0)::numeric, 6)                  as "TTCF",
           round(coalesce(tcb."TTCF$", 0.0)::numeric, 6)                 as "TTCF$",
           round(coalesce(tcb."BADR", 0.0)::numeric, 6)                  as "BADR",
           round(coalesce(tcb."BADR$", 0.0)::numeric, 6)                 as "BADR$",
           round(coalesce(tcb."OIRGPMT", 0.0)::numeric, 6)               as "OIRGPMT",
           round(coalesce(tcb."OIRGPMT$", 0.0)::numeric, 6)              as "OIRGPMT$",
           round(coalesce(tcb."SECFEE", 0.0)::numeric, 6)                as "SECFEE",
           round(coalesce(tcb."SECFEE$", 0.0)::numeric, 6)               as "SECFEE$",
           round(coalesce(tcb."TAF", 0.0)::numeric, 6)                   as "TAF",
           round(coalesce(tcb."TAF$", 0.0)::numeric, 6)                  as "TAF$",
           round(coalesce(tcb."CATTF", 0.0)::numeric, 6)                 as "CATTF",
           round(coalesce(tcb."CATTF$", 0.0)::numeric, 6)                as "CATTF$",
           round(coalesce(tcb."PFOFTF", 0.0)::numeric, 6)                as "PFOFTF",
           round(coalesce(tcb."PFOFTF$", 0.0)::numeric, 6)               as "PFOFTF$",
           round(coalesce(tcb."PFOFRB", 0.0)::numeric, 6)                as "PFOFRB",
           round(coalesce(tcb."PFOFRB$", 0.0)::numeric, 6)               as "PFOFRB$",
           round(coalesce(tcb."TIERS", 0.0)::numeric, 6)                 as "TIERS",
           round(coalesce(tcb."TIERS$", 0.0)::numeric, 6)                as "TIERS$",
           round(coalesce(tcb."SPRTF", 0.0)::numeric, 6)                 as "SPRTF",
           round(coalesce(tcb."SPRTF$", 0.0)::numeric, 6)                as "SPRTF$",
           round(coalesce(tcb."REBATE", 0.0)::numeric, 6)                as "REBATE",
           round(coalesce(tcb."REBATE$", 0.0)::numeric, 6)               as "REBATE$",
           round(coalesce(tcb."OCC", 0.0)::numeric, 6)                   as "OCC",
           round(coalesce(tcb."OCC$", 0.0)::numeric, 6)                  as "OCC$",
           round(coalesce(tcb."ECC", 0.0)::numeric, 6)                   as "ECC",
           round(coalesce(tcb."ECC$", 0.0)::numeric, 6)                  as "ECC$",
           round(coalesce(tcb."EAC", 0.0)::numeric, 6)                   as "EAC",
           round(coalesce(tcb."EAC$", 0.0)::numeric, 6)                  as "EAC$",
           round(coalesce(tcb."NSCC", 0.0)::numeric, 6)                  as "NSCC",
           round(coalesce(tcb."NSCC$", 0.0)::numeric, 6)                 as "NSCC$",
           round(coalesce(tcb."CMTA", 0.0)::numeric, 6)                  as "CMTA",
           round(coalesce(tcb."CMTA$", 0.0)::numeric, 6)                 as "CMTA$",
           round(coalesce(tcb."MARS", 0.0)::numeric, 6)                  as "MARS",
           round(coalesce(tcb."MARS$", 0.0)::numeric, 6)                 as "MARS$",
           round(coalesce(tcb."MORP", 0.0)::numeric, 6)                  as "MORP",
           round(coalesce(tcb."MORP$", 0.0)::numeric, 6)                 as "MORP$",
           round(coalesce(tcb."QCC", 0.0)::numeric, 6)                   as "QCC",
           round(coalesce(tcb."QCC$", 0.0)::numeric, 6)                  as "QCC$",
           round(coalesce(tcb."CVIP", 0.0)::numeric, 6)                  as "CVIP",
           round(coalesce(tcb."CVIP$", 0.0)::numeric, 6)                 as "CVIP$",
           round(coalesce(tcb."WRA", 0.0)::numeric, 6)                   as "WRA",
           round(coalesce(tcb."WRA$", 0.0)::numeric, 6)                  as "WRA$",
           round(coalesce(tcb."CBOEMM", 0.0)::numeric, 6)                as "CBOEMM",
           round(coalesce(tcb."CBOEMM$", 0.0)::numeric, 6)               as "CBOEMM$",
           round(coalesce(tcb."3PPT", 0.0)::numeric, 6)                  as "3PPT",
           round(coalesce(tcb."3PPT$", 0.0)::numeric, 6)                 as "3PPT$",
           round(coalesce(tcb."CRR", 0.0)::numeric, 6)                   as "CRR",
           round(coalesce(tcb."CRR$", 0.0)::numeric, 6)                  as "CRR$",
           round(coalesce(tcb."CMDT", 0.0)::numeric, 6)                  as "CMDT",
           round(coalesce(tcb."CMDT$", 0.0)::numeric, 6)                 as "CMDT$",
           round(coalesce(tcb."DATS", 0.0)::numeric, 6)                  as "DATS",
           round(coalesce(tcb."DATS$", 0.0)::numeric, 6)                 as "DATS$",
           round(coalesce(tcb."EQTYTIERS", 0.0)::numeric, 6)             as "EQTYTIERS",
           round(coalesce(tcb."EQTYTIERS$", 0.0)::numeric, 6)            as "EQTYTIERS$"
    from billing.billing_data.tcustomer_billing_detail_all tcb
             left join billing.billing_data.tbillingorderdefinition od
                       on od.date_id = tcb.date_id and od.report_id = tcb.report_id
    where tcb.date_id between l_date_begin and l_date_end
      and tcb.billingentity = any (l_billing_entities)                                       --in_billing_entities
      and case when in_companies is null then true else tcb.company = any (in_companies) end --in_companies
      and case when in_account = '{}' then true else tcb.account = any (in_account) end      --in_accounts
      and case
              when in_instrument_type = 'E' then tcb."SECURITY TYPE" = 'Equity'
              when in_instrument_type = 'O' then tcb."SECURITY TYPE" = 'Option'
              when in_instrument_type is null then true
              else false end                                                                 --in_instrument_type: Need to map E > Equity and O to Option, null > Both
      and tcb.duplicate <> '1'
      and tcb."FILLED QTY" > 0
    order by tcb."date", tcb.report_id;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'generic_trade_details_report for ' || l_date_begin::text || '-' ||
                           l_date_end::text || ' COMPLETED ===', l_row_cnt, 'O')
    into l_step_id;
end ;
$function$
;

