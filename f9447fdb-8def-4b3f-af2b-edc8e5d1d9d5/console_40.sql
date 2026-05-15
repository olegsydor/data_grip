create function dash360.get_elliot(in_account_id int8)
    returns varchar(20)
    language plpgsql
as
$$
declare
    l_ret_val              varchar(20);
    l_sg_parent_account_id int8;
begin
    select sg_elliot, sg_parent_account_id
    into l_ret_val, l_sg_parent_account_id
    from staging.sg_account
    where account_id = in_account_id;

    if l_ret_val is not null or l_sg_parent_account_id is null then
        return l_ret_val;
    end if;

    if exists (select null from staging.SG_NULL_ACCOUNT_PARAMETER where account_id = in_account_id) then
        return null;
    else
        select sg_elliot
        into l_ret_val
        from staging.sg_account
        where account_id = l_sg_parent_account_id;
        return l_ret_val;
    end if;

end
$$


select jsonb_pretty('{"noAllocs": 1, "tradeDate": 20260514, "processTime": "2026-05-14T16:00:51.686", "AllocInstrId": -122499, "instrumentTypeId": "O", "allocationEntries": [{"clrFirm": "551", "allocQty": 110, "EquityBRID": null, "OptionBRID": "70001229", "subAccount": null, "salesTrader": "anthony.reinen", "actionableId": "SUS", "allocAccount": null, "sgMintAccount": null, "individualAllocID": 608517, "AllocEntryCCRURate": null, "ElliotCounterpartyCode": "SUSQUEHAFIUS", "AllocEntryCCRUTotalAmount": null}]}'::jsonb)