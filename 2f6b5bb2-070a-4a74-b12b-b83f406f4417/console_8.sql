do
$$
    declare
        l_val int4;
    begin
        select account_id
        into strict l_val
        from dwh.d_account
        where trading_firm_id = 'dashdesk'
--         and 1=2
        ;

        raise notice 'value - %', l_val;
    end;
$$