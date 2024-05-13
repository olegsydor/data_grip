do
$$
    declare
        scr      record;
        l_return int4;
    begin
        for scr in (select dat
                    from generate_series('2022-12-31'::date, '2020-01-01'::date, interval '-1 day') as x(dat))
            loop
                begin
                    select into l_return
                    from dwh.gtc_insert_daily(to_char(scr.dat, 'YYYYMMDD')::int4,
                                              to_char(scr.dat + '1 day'::interval, 'YYYYMMDD')::int4);
                    raise notice '%: inserted - %', to_char(clock_timestamp(), 'YYYY-MM-DD HH24:MI:SS'), l_return;

                    select into l_return
                    from dwh.gtc_update_daily(to_char(scr.dat, 'YYYYMMDD')::int4,
                                              to_char(scr.dat + '1 day'::interval, 'YYYYMMDD')::int4);
                    raise notice '%: updated - %', to_char(clock_timestamp(), 'YYYY-MM-DD HH24:MI:SS'), l_return;
                    commit;
                end;
            end loop;
    end ;

$$



select min(create_date_id) from dwh.gtc_order_status