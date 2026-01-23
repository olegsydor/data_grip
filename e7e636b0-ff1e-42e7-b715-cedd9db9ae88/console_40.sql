drop table if exists t_os;
create temp table t_os as
select otd.*
    from occ_data.occ_trade_data otd
    where true
      and otd.clearing_member_number in ('00333', '00733')
      and otd.gup_clearing_firm_originator is null
      and otd.date_id = :in_date_id
      and otd.trans_type <> '1'
      and not exists (select null
                      from occ_data.occ_trade_data ino
                      where ino.clearing_member_number in ('00333', '00733')
                        and ino.gup_clearing_firm_originator is null
                        and ino.date_id = :in_date_id
                        and ino.trans_type = '1'
                        and ino.rpt_id = otd.rpt_id
                        and ino.side = otd.side);

select *
from t_os t1
where t1.trade_type = '0'
  and exists (select null
              from t_os t2
              where t2.trade_type = '3'
                and t2.instrument_id = t1.instrument_id
                and t2.side <> t1.side
                and t1.last_qty = t2.last_qty
                and t1.last_px = t2.last_px
                and t2.pg_db_create_time < t1.pg_db_create_time
              )


select '{"side": "2", "avgPx": 2.000000, "symbol": "AAPL", "trades": [{"lastQty": 32, "legRefId": null, "dashExecId": "610244808330", "chainExecId": null, "secondaryExchExecId": "167757436852109397"}, {"lastQty": 32, "legRefId": null, "dashExecId": "610244808298", "chainExecId": null, "secondaryExchExecId": "167757436852109385"}, {"lastQty": 32, "legRefId": null, "dashExecId": "610244808346", "chainExecId": null, "secondaryExchExecId": "167757436852109403"}, {"lastQty": 24, "legRefId": null, "dashExecId": "610244808314", "chainExecId": null, "secondaryExchExecId": "167757436852109391"}, {"lastQty": 8, "legRefId": null, "dashExecId": "610244808314", "chainExecId": null, "secondaryExchExecId": "167757436852109391"}, {"lastQty": 12, "legRefId": null, "dashExecId": "610244808282", "chainExecId": null, "secondaryExchExecId": "167757436852109379"}, {"lastQty": 20, "legRefId": null, "dashExecId": "610244808282", "chainExecId": null, "secondaryExchExecId": "167757436852109379"}], "noExecs": 7, "secType": "OPT", "CCRURate": null, "noAllocs": 1, "strikePx": 230.0000, "totalQty": 160, "putOrCall": "1", "tradeDate": 20260121, "maturityDay": "15", "processTime": "2026-01-21T12:02:13.711", "CCRUTotalAmount": null, "allocationEntries": [{"brid": null, "clrFirm": "007", "allocQty": 160, "subAccount": null, "actionableId": "OCC12", "allocAccount": null, "sgMintAccount": null, "individualAllocID": 592269, "AllocEntryCCRURate": null, "AllocEntryCCRUTotalAmount": null}], "maturityMonthYear": "202701"}'::jsonb