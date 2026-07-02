create temp table t_02 as
     insert into t_01
select o."StatusDate"::date               as "Period",
           tf.trading_firm_name::varchar      as "Trading Firm",
           a.account_name::varchar            as "Account",
           cf.customer_or_firm_name::varchar  as "Capacity",
           sum(coalesce(o."CumQty", 0))::int8 as "Qty",
           count(distinct o."ClOrdID")        as "Parent Order Count"
    from dwh.historic_order_details_storage o
             join dwh.d_account a on (a.account_id = o."AccountID")
             join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
             left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = o."CustomerOrFirm")
    where true
      and "Status_Date_id" >= :in_start_date_id
      and "Status_Date_id" <= :in_end_date_id
      and case when :in_instrument_type_id is null then true else o."InstrumentType" = :in_instrument_type_id end
      and o."CustomerOrderID" is null
    group by "Period", "Account", "Capacity", "Trading Firm";


select * from t_02
          where "Trading Firm" = 'Piper Sandler & Co' and "Account" = 'PIPR_5976'
union all
select * from t_01
          where "Trading Firm" = 'Piper Sandler & Co' and "Account" = 'PIPR_5976'
/*
припущення: запускати поденно і в репорті використовувати group by 