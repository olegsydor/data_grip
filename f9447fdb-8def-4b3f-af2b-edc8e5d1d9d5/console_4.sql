do
$$
    begin
        alter table genesis2.trade_record
            add constraint trade_record_pk primary key (trade_record_id, date_id);
    exception
        when others then
            raise notice 'The constraint has been created before';
    end;
$$