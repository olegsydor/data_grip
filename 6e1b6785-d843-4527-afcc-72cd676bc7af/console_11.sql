SELECT to_char(public.get_business_date(), 'YYYYMMDD')::INT;

select tca.load_order_tca_inc(in_order_ids=> array(
        select order_id
        from dwh.flat_trade_record
        where date_id = :lwd
          and order_id is not null
          and subsystem_id not in ('LPEDW', 'LPDROP')
          and instrument_type_id = 'O'
          and is_busted = 'N'
        except
        select ot.parent_order_id
        from tca.order_tca ot
        where date_id = :lwd
          and instrument_type_id = 'O'
        limit 15000
                                             )
           , in_load_id=> null
           , in_instrument_type_id=>'O'
           , in_date_id=> :lwd);