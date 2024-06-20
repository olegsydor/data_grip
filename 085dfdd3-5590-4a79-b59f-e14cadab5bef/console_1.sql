select dateadd(hour, 1, tr.TransactionDateTime)                                              as trade_record_time,
select dateadd(hour, 1, tr.TransactionDateTime)                                              as trade_record_time,
select dateadd(hour, 1, tr.TransactionDateTime)                                              as trade_record_time,
select dateadd(hour, 1, tr.TransactionDateTime)                                              as trade_record_time,
       cast(convert(char(8), tr.TransactionDateTime, 112) as int)                            as date_id,
       case when tor.SystemID = 8 then 'OMS_EDW' else 'LPEDW' end                            as subsystem_id,
       coalesce(nullif(torm.[DashAlias], ''),
                case
                    when ISNULL(u.AORSUsername, Login) = 'BBNTRST' then 'NTRSCBOE'
                    else ISNULL(u.AORSUsername, Login)
                    end)                                                                     as account_name,
       CONCAT(coalesce(nullif(torm.[DashAlias], ''), case
                                                         when ISNULL(u.AORSUsername, Login) = 'BBNTRST' then 'NTRSCBOE'
                                                         else ISNULL(u.AORSUsername, Login)
           end),
              isnull(tor.GiveUpFirm, tr.[ExecutingBroker]),
              case
                  when isnull(tor.GiveUpFirm, '') = '792'
                      then case
                               when isnull(nullif(tor.CMTAFirm, ''), '949') = '949'
                                   then 'PTA'
                               else null
                      end
                  else null
                  end
       )                                                                                     as account_name_gvp,
       tor.SystemOrderID                                                                     as client_order_id,
       cast(tl.side as varchar(1))                                                           as side,
       case tl.OpenClose
           when 1 then 'O'
           when 2 then 'C'
           end                                                                               as open_close,
       coalesce(nullif(tr.[LiquidityIndicator], ''), 'R')                                    as trade_liquidity_indicator,
       tr.ExchangeMappedOrderID                                                              as secondary_order_id,
       tr.Transaction64ReportID                                                              as exch_exec_id,
       tr.ExchangeTransactionID                                                              as secondary_exch_exec_id,
       case
           when nullif(coalesce(den.last_mkt, den1.last_mkt, tr.ExDestination), '') in
                ('CBOE-CRD NO BK', 'PAR', 'CBOIE') then 'W'
           when nullif(coalesce(den.last_mkt, den1.last_mkt, tr.ExDestination), '') in ('XPAR', 'PLAK', 'PARL')
               then 'LQPT'
           when nullif(coalesce(den.last_mkt, den1.last_mkt, tr.ExDestination), '') in ('SOHO', 'KNIGHT', 'LSCI', 'NOM')
               then 'ECUT'
           when nullif(coalesce(den.last_mkt, den1.last_mkt, tr.ExDestination), '') in ('FOGS', 'MID') then 'XCHI'
           when nullif(coalesce(den.last_mkt, den1.last_mkt, tr.ExDestination), '') in ('C2', 'CBOE2') then 'C2OX'
           when nullif(coalesce(den.last_mkt, den1.last_mkt, tr.ExDestination), '') = 'SMARTR' then 'COWEN'
           when nullif(coalesce(den.last_mkt, den1.last_mkt, tr.ExDestination), '') in
                ('ACT', 'BOE', 'OTC', 'lp', 'VOL') then 'BRKPT'
           when nullif(coalesce(den.last_mkt, den1.last_mkt, tr.ExDestination), '') in ('XPSE') then 'N'
           when nullif(coalesce(den.last_mkt, den1.last_mkt, tr.ExDestination), '') in ('TO') then '1'
           else nullif(coalesce(den.last_mkt, den1.last_mkt, tr.ExDestination), '') end      as last_mkt,

       case
           when nullif(coalesce(den1.mic_code, tr.ExDestination), '') in ('CBOE-CRD NO BK', 'PAR', 'CBOIE') then 'XCBO'
           when nullif(coalesce(den1.mic_code, tr.ExDestination), '') in ('XPAR', 'PLAK', 'PARL') then 'LQPT'
           when nullif(coalesce(den1.mic_code, tr.ExDestination), '') in ('SOHO', 'KNIGHT', 'LSCI', 'NOM') then 'ECUT'
           when nullif(coalesce(den1.mic_code, tr.ExDestination), '') in ('FOGS', 'MID') then 'XCHI'
           when nullif(coalesce(den1.mic_code, tr.ExDestination), '') in ('C2', 'CBOE2') then 'C2OX'
           when nullif(coalesce(den1.mic_code, tr.ExDestination), '') = 'SMARTR' then 'COWEN'
           when nullif(coalesce(den1.mic_code, tr.ExDestination), '') in ('ACT', 'BOE', 'OTC', 'lp', 'VOL') then 'BRKPT'
           when nullif(coalesce(den1.mic_code, tr.ExDestination), '') in ('XPSE') then 'ARCO'
           when nullif(coalesce(den1.mic_code, tr.ExDestination), '') = 'TO' then 'AMXO'
           else nullif(coalesce(den1.mic_code, tr.ExDestination), '') end                    as mic_code,
       tr.LastShares                                                                         as last_qty,
       convert(numeric(16, 8), (convert(numeric(16, 0), tr.LastPrice) / 100000000))          as last_px,
       --NULL as street_order_qty,
       coalesce(nullif(case
                           when nullif(tl.[ExpirationDate], '1900-01-01 00:00:00.000') is not null and
                                nullif(tl.[Strike], 0.00) is not null then tl.OptionQuantity
                           else tl.StockQuantity end, 0), tl.Quantity)                       as street_order_qty,
       coalesce(nullif(case
                           when nullif(tl.[ExpirationDate], '1900-01-01 00:00:00.000') is not null and
                                nullif(tl.[Strike], 0.00) is not null then tl.OptionQuantity
                           else tl.StockQuantity end, 0), tl.Quantity)                       as order_qty,
       case when tor.LegCount > 1 then 2 else 1 end                                          as multileg_reporting_type,
/*	isnull(nullif(tr.[ExecutingBroker],''),tor.GiveUpFirm) as exec_broker,*/
       isnull(tor.GiveUpFirm, tr.[ExecutingBroker])                                          as exec_broker,
       tor.CMTAFirm                                                                             cmta,
       --NULL as street_time_in_force,
       case
           when tor.[TimeInForceCode] in (24, 17, 10, 1, 44) then 0
           when tor.[TimeInForceCode] in (26, 18, 3, 45, 12) then 1
           when tor.[TimeInForceCode] in (31, 8, 15, 46) then 2
           when tor.[TimeInForceCode] in (47, 28, 11, 19, 5) then 3
           when tor.[TimeInForceCode] in (48, 2, 13, 25, 20) then 4
           when tor.[TimeInForceCode] in (36, 37, 38, 49) then 5
           when tor.[TimeInForceCode] in (50, 14, 21, 33) then 6
           when tor.[TimeInForceCode] in (32, 9, 16) then 7
           else null
           end                                                                               as street_time_in_force,
       NULL                                                                                  as street_order_type,
    /*case when tor.ForWhom=78 then '0'
        when tor.ForWhom=79 then '1'
        when tor.ForWhom=97 then '2'
        when tor.ForWhom=96 then '3'
        when tor.ForWhom=81 then '4'
        when tor.ForWhom=82 then '5'
        when tor.ForWhom=83 then '7'
        when tor.ForWhom=98 then '8'
        when tor.ForWhom=86 then 'J'
        else null
    end as opt_customer_firm,*/
       case
           when tor.ForWhom in (1, 25, 32, 78) then '0'
           when tor.ForWhom in (33, 26, 79) then '1'
           when tor.ForWhom in (52, 103, 20, 97) then '2'
           when tor.ForWhom in (19, 30, 38, 96) then '3'
           when tor.ForWhom in (35, 28, 4, 81) then '4'
           when tor.ForWhom in (5, 29, 36, 82) then '5'
           when tor.ForWhom IN (21, 6, 83) then '7'
           when tor.ForWhom IN (31, 23, 41, 98) then '8'
           when tor.ForWhom IN (9, 40, 50, 86) then 'J'
           else null
           end                                                                               as opt_customer_firm,
       case when OrigOrderID <> '00000000-0000-0000-0000-000000000000' then 'Y' else 'N' end as is_cross_order,
       --NULL as street_is_cross_order,
       case when OrigOrderID <> '00000000-0000-0000-0000-000000000000' then 'Y' else 'N' end as street_is_cross_order,
       NULL                                                                                  as street_cross_type,
       tr.ContraBroker                                                                       as contra_broker,
       coalesce(c.CompanyCode, u.Login)                                                      as client_id,
       --convert(numeric(12,4), tl.Price) as order_price,
       case
           when tl.price > 99999999.9999 then convert(numeric(12, 4), 99999999.9999)
           else convert(numeric(12, 4), tl.Price)
           end                                                                               as order_price,
       case ExchangeMappedOrderID
           when '' then null
           else ExchangeMappedOrderID
           end                                                                               as street_client_order_id,
       'LPEDWCOMPID'                                                                         as fix_comp_id,
       LeavesQty                                                                             as leaves_qty,
       NULL                                                                                  as street_exec_inst,
       NULL                                                                                  as street_order_price,
       tl.LegNumber                                                                          as leg_ref_id,
       case tl.TypeCode
           when 'P' then '0'
           when 'C' then '1'
           end                                                                               as put_or_call,
       tl.BaseCode                                                                           as symbol,
       cast(tl.Strike as numeric(12, 4))                                                     as strike_price,
       datepart(year, tl.[ExpirationDate])                                                   as maturity_year,
       datepart(month, tl.[ExpirationDate])                                                  as maturity_month,
       datepart(day, tl.[ExpirationDate])                                                    as maturity_day,
       tr.SecurityType                                                                       as security_type,
       iif(bust.ID IS NULL, 'N', 'Y')                                                        as is_busted,
       tr.OrderID                                                                            as order_id_guid,
       iif(ParentID = '00000000-0000-0000-0000-000000000000', 'Y', 'N')                      as is_parent,
       tor.ChildOrders                                                                       as child_orders,
       tr.Handling                                                                           as handling_id,
       tr.Transaction64LegID                                                                 as secondary_order_id2,
       CASE
           WHEN tor.ORIGOrderID <> '00000000-0000-0000-0000-000000000000' or
                tor.ContraOrderID <> '00000000-0000-0000-0000-000000000000' then 26
           WHEN tor.ParentOrderID <> '00000000-0000-0000-0000-000000000000' or
                (tor.ParentOrderID = '00000000-0000-0000-0000-000000000000' and tor.ChildOrders != 0) then 10
           WHEN tor.COMMENT like '%OVR%' then 4
           ELSE 50 end                                                                       as strategy_decision_reason_code,
       tor.systemid                                                                          as system_id,
    /* case when nullif(tl.[ExpirationDate],'1900-01-01 00:00:00.000') is not null and nullif(tl.[Strike],0.00) is not null
                        then  replace(isnull(replace(replace(tl.[BaseCode],'.',''),'-','')+ ' '
                                                                              + upper(left(datename(month,tl.[ExpirationDate]),3))+right(datename(year,tl.[ExpirationDate]),2)+' '
                                                                              + case when charindex('0.',cast(cast(tl.[Strike] as float) as varchar(8)))=1 then right(cast(cast(tl.[Strike] as float) as varchar(8)), len(cast(cast(tl.[Strike] as float) as varchar(8)))-1)
                                                                                    else cast(cast(tl.[Strike] as float) as varchar(8))	end
                                                                               + cast(tl.TypeCode as varchar(8)), ContractDesc) ,'/','')
          else replace(replace(tl.[BaseCode],'.',''),'-','')
      end as display_instrument_id */
       case
           when nullif(tl.[ExpirationDate], '1900-01-01 00:00:00.000') is not null and
                nullif(tl.[Strike], 0.00) is not null
               then replace(
                   isnull(replace(replace(coalesce(nullif(tl.[RootCode], ''), tl.BaseCode), '.', ''), '-', '') + ' '
                              + RIGHT('0' + cast(datepart(day, tl.[ExpirationDate]) as varchar), 2)
                              + left(datename(month, tl.[ExpirationDate]), 3)
                              + right(datename(year, tl.[ExpirationDate]), 2) + ' '
                              + case
                                    when charindex('0.', cast(cast(tl.[Strike] as float) as varchar(8))) = 1
                                        then right(cast(cast(tl.[Strike] as float) as varchar(8)),
                                                   len(cast(cast(tl.[Strike] as float) as varchar(8))) - 1)
                                    else cast(cast(tl.[Strike] as float) as varchar(8))
                              end
                              + cast(tl.TypeCode as varchar(8)), ContractDesc), '/', '')
           else replace(replace(coalesce(nullif(tl.[RootCode], ''), tl.BaseCode), '.', ''), '-', '')
           end                                                                               as display_instrument_id,
       case
           when nullif(tl.[ExpirationDate], '1900-01-01 00:00:00.000') is not null and
                nullif(tl.[Strike], 0.00) is not null then 'O'
           else 'E'
           end                                                                               as instrument_type_id,
       replace(replace(tl.[BaseCode], '.', '/'), '-', '/')                                   as activ_symbol,
       tr.ID * (-1)                                                                          as exec_id,
       tor.ID * (-1)                                                                         as order_id,
       torm.AcctComm                                                                         as CRU,
       case
           when u.Login = 'TRAFXPSC' and coalesce(nullif(tor.AccountAlias, ''), uam.Alias) is null then tor.Account
           else coalesce(nullif(tor.AccountAlias, ''), uam.Alias) end                        as AccountAlias,
       --tor.AccountAlias,
       case
           when tor.SystemID = 8 and tor.SystemOrderID like 'f_%' then 1
           when tr.Status = 151 then coalesce([EDW_Billing].[dbo].[f_get_is_trade_SOR_routed_daily_temp](tr.ID), 0)
           else 0
           end                                                                               as is_sor_routed,
       tr.ReportID,
       (case
            when lag(c.companyname, 1) over (partition by tr.ExchangeTransactionID order by tor.generation) <>
                 c.companyname
                and lag(tor.OrderID, 1) over (partition by tr.ExchangeTransactionID order by tor.generation) =
                    tor.ParentORdeRID then 1
            else 0
           end)                                                                              as is_company_name_changed,
       companyname,
       -- tor.generation,
       case
           when tor.generation = 1 and tor.ParentOrderID = '00000000-0000-0000-0000-000000000000' then 0
           else tor.generation
           end                                                                               as generation,
       max(tor.generation) over (partition by tr.ExchangeTransactionID)                         mx_gen,
       tor.OrderID,
       tor.ParentORdeRID,
       row_number() over (partition by tr.ReportID order by tr.ID)                           as rn,
       case
           when replace(replace(tl.[BaseCode], '.', '/'), '-', '/') like '[0-9]%' then 1
           else 0
           end                                                                               as real_flex_order,
       convert(numeric(16, 8), (convert(numeric(16, 0), tr.LastPrice) / 100000000))          as last_px_temp

FROM [LiquidPoint_EDW].[dbo].[TReports_EDW_daily] tr with (nolock)
         inner join [LiquidPoint_EDW].[dbo].[TOrder_EDW_daily] tor with (nolock) on tor.[OrderID] = tr.[OrderID]
         inner join [LiquidPoint_EDW].[dbo].[TOrderMisc1_EDW_daily] torm with (nolock)
                    on tor.[OrderID] = torm.[OrderID] and tor.[SystemID] = torm.[SystemID]
         left join [LiquidPoint_EDW].[dbo].[TLegs_EDW_daily] tl with (nolock)
                   on tl.[OrderID] = tr.[OrderID] and tl.[LegNumber] = tr.[LegNumber]
         left join [LiquidPoint_EDW].[dbo].[LExchange] le with (nolock) on le.ExchangeCode = tr.ExCode
         left join [LiquidPoint_EDW].[dbo].[TUsers] u with (nolock) on tor.UserID = u.ID
         outer apply (select top 1 Alias
                      from #TUserAccountAlias_temp uam with (nolock)--FlexTran.dbo.TUserAccountAlias uam with(nolock)
                      where u.UserID = uam.UserID
                        and u.SystemID = 2
                        and torm.DashAlias = uam.[DashAlias]) uam
         left join [LiquidPoint_EDW].[dbo].[TCompany] c with (nolock) on tor.CompanyID = c.ID
         left join [EDW_Billing].[dbo].[dash_exchange_names] den with (nolock)
                   on den.mic_code = replace(replace(tr.ExDestination, 'DIRECT-', ''), ' Printer', '') and
                      den.real_exchange_id = den.exchange_id and den.mic_code != '' and den.is_active = 'TRUE'
         left join [EDW_Billing].[dbo].[dash_exchange_names] den1 with (nolock)
                   on den1.exchange_id = replace(replace(tr.ExDestination, 'DIRECT-', ''), ' Printer', '') and
                      den1.real_exchange_id = den1.exchange_id and den1.mic_code != '' and den1.is_active = 'TRUE'
         left join (select r.ID
                    From [LiquidPoint_EDW].dbo.TReports_EDW_Daily r with (nolock)
                             inner join [LiquidPoint_EDW].dbo.TReports_EDW_Daily r2 with (nolock)
                                        on convert(varchar(255), r2.TradeCancelledReportID) = r.ReportID
                                            and ((r.OrderID = r2.OrderID and r2.status in (149, 194, 152)))) bust
                   on bust.ID = tr.ID
where tr.Status in (151, 156, 239)
  --and tor.generation=0
  and tor.SystemID in (2, 3, 8)
    /*and bust.ID is null*/
  and tr.TransactionDateTime >= @start_date
  and tr.TransactionDateTime < @end_date
  and tor.SystemOrderTypeID <> 87;

select nullif('a', 'a');
select isnull(null, 'a')


select replace(replace('.....------jk', '.', '/'), '-', '/')