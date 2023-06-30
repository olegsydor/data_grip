
     SELECT null as  "StrategyInID",
       SILS.TRANSACTION_ID as "TransactionID",
       SILS.INSTRUMENT_ID as "InstrumentID",
       SILS.L1_SCOPE as "L1Scope",
       SILS.SIDE as "Side",
       SILS.EXCHANGE_ID as "ExchangeID",
       SILS.PRICE as "Price",
       SILS.QUANTITY as "Qty"
   FROM  STRATEGY_ROUTING_TABLE SINO
    inner join STRATEGY_TRANSACTION st on (SINO.transaction_id = ST.transaction_id)
    inner join  STRATEGY_IN_L1_SNAPSHOT_V2 SILS on (SINO.transaction_id = SILS.transaction_id)
   where st.STRATEGY_DATA_MODEL_TYPE=2
   and SINO.INTERNAL_ORDER_ID = p_order_id;


     select co.internal_order_id,
         null              as "StrategyInID",
            co.TRANSACTION_ID as "TransactionID",
            co.INSTRUMENT_ID  as "InstrumentID",
--            ls.exchange_id,
            co.EXCHANGE_ID    as "ExchangeID",
            ls.bid_price      as "Bid Price",
            ls.bid_quantity   as "Bid Qty",
            ls.ask_price      as "Ask Price",
            ls.bid_quantity   as "Ask Qty"
     from dwh.client_order co
              join dwh.l1_snapshot ls
                   on ls.transaction_id = co.transaction_id
                       and ls.start_date_id = co.create_date_id
     where co.create_date_id = 20230629
       and co.internal_order_id = 793027343579

     select * from strategy_transaction_output