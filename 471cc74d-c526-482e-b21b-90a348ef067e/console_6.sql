use blaze7;

create table [dbo].[TEntityMarketDataEntitlement_EDW]
(
    id             int            not null,
    entity_id      int            not null,
    created_by     int            not null,
    creation_time  [datetime2](3) not null,
    is_deleted     bit            not null,
    deleted_by     int            null,
    deleted_time   [datetime2](3) null,
    index_nyse     bit            not null,
    index_nasdaq   bit            not null,
    index_cboe     bit            not null,
    index_ftse     bit            not null,
    cob_amxo       bit            not null,
    cob_xcbo       bit            not null,
    cob_edgo       bit            not null,
    cob_xisx       bit            not null,
    cob_xmio       bit            not null,
    cob_arco       bit            not null,
    cob_c2ox       bit            not null,
    cob_xpho       bit            not null,
    bi_amxo        bit            not null,
    bi_xcbo        bit            not null,
    bi_arco        bit            not null,
    bi_xbox        bit            not null,
    bi_xpho        bit            not null,
    equity_nyse    bit            not null,
    equity_nasdaq  bit            not null,
    option_opra    bit            not null,
    db_create_time datetime       not null default getdate()
        constraint pk_TEntityMarketDataEntitlement_EDW primary key (id)
);


CREATE TRIGGER [dbo].[TEntityMarketDataEntitlement_UPSERT]
    ON [dbo].[TEntityMarketDataEntitlement_EDW]
    INSTEAD OF INSERT
    AS
BEGIN
    INSERT INTO [dbo].[TEntityMarketDataEntitlement_EDW]
    (id, entity_id, created_by, creation_time, is_deleted, deleted_by, deleted_time, index_nyse, index_nasdaq,
     index_cboe, index_ftse, cob_amxo, cob_xcbo, cob_edgo, cob_xisx, cob_xmio, cob_arco, cob_c2ox, cob_xpho, bi_amxo,
     bi_xcbo, bi_arco, bi_xbox, bi_xpho, equity_nyse, equity_nasdaq, option_opra)

    SELECT id,
           entity_id,
           created_by,
           creation_time,
           is_deleted,
           deleted_by,
           deleted_time,
           index_nyse,
           index_nasdaq,
           index_cboe,
           index_ftse,
           cob_amxo,
           cob_xcbo,
           cob_edgo,
           cob_xisx,
           cob_xmio,
           cob_arco,
           cob_c2ox,
           cob_xpho,
           bi_amxo,
           bi_xcbo,
           bi_arco,
           bi_xbox,
           bi_xpho,
           equity_nyse,
           equity_nasdaq,
           option_opra
    FROM inserted I
    where not exists (select 1 from dbo.TEntityMarketDataEntitlement_EDW L where L.id = I.id);
    UPDATE [dbo].[TEntityMarketDataEntitlement_EDW]
    SET [is_deleted]   = I.[is_deleted]
      , [deleted_by]   = I.[deleted_by]
      , [deleted_time] = I.[deleted_time]
    FROM Inserted I
    WHERE TEntityMarketDataEntitlement_EDW.[id] = I.id;
end;
go;

create table [dbo].[TUserMarketDataEntitlement_EDW]
(
    id             int            not null,
    entity_id      int            not null,
    user_id        int            not null,
    created_by     int            not null,
    creation_time  [datetime2](3) not null,
    is_deleted     bit            not null,
    deleted_by     int            null,
    deleted_time   [datetime2](3) null,
    index_nyse     bit            not null,
    index_nasdaq   bit            not null,
    index_cboe     bit            not null,
    index_ftse     bit            not null,
    cob_amxo       bit            not null,
    cob_xcbo       bit            not null,
    cob_edgo       bit            not null,
    cob_xisx       bit            not null,
    cob_xmio       bit            not null,
    cob_arco       bit            not null,
    cob_c2ox       bit            not null,
    cob_xpho       bit            not null,
    bi_amxo        bit            not null,
    bi_xcbo        bit            not null,
    bi_arco        bit            not null,
    bi_xbox        bit            not null,
    bi_xpho        bit            not null,
    equity_nyse    bit            not null,
    equity_nasdaq  bit            not null,
    option_opra    bit            not null,
    db_create_time datetime       not null default getdate()
        constraint pk_TUserMarketDataEntitlement_EDW primary key (id)
);


CREATE TRIGGER [dbo].[TUserMarketDataEntitlement_EDW_UPSERT]
    ON [dbo].[TUserMarketDataEntitlement_EDW]
    INSTEAD OF INSERT
    AS
BEGIN
    INSERT INTO [dbo].[TUserMarketDataEntitlement_EDW]
    (id, entity_id, user_id, created_by, creation_time, is_deleted, deleted_by, deleted_time, index_nyse,
     index_nasdaq, index_cboe, index_ftse, cob_amxo, cob_xcbo, cob_edgo, cob_xisx, cob_xmio, cob_arco, cob_c2ox,
     cob_xpho, bi_amxo, bi_xcbo, bi_arco, bi_xbox, bi_xpho, equity_nyse, equity_nasdaq, option_opra)
    SELECT id,
           entity_id,
           user_id,
           created_by,
           creation_time,
           is_deleted,
           deleted_by,
           deleted_time,
           index_nyse,
           index_nasdaq,
           index_cboe,
           index_ftse,
           cob_amxo,
           cob_xcbo,
           cob_edgo,
           cob_xisx,
           cob_xmio,
           cob_arco,
           cob_c2ox,
           cob_xpho,
           bi_amxo,
           bi_xcbo,
           bi_arco,
           bi_xbox,
           bi_xpho,
           equity_nyse,
           equity_nasdaq,
           option_opra
    FROM inserted I
    where not exists (select 1 from dbo.TUserMarketDataEntitlement_EDW L where L.id = I.id);
    UPDATE [dbo].[TUserMarketDataEntitlement_EDW]
    SET [is_deleted]   = I.[is_deleted]
      , [deleted_by]   = I.[deleted_by]
      , [deleted_time] = I.[deleted_time]
    FROM Inserted I
    WHERE TUserMarketDataEntitlement_EDW.[id] = I.id;
end;
go;

CREATE TABLE [dbo].[TEntityCatDefaults_EDW]
(
    id                  int            NOT NULL,
    entity_id           int            NOT NULL,
    created_by          int            NOT NULL,
    creation_time       [datetime2](3) not null,
    is_deleted          bit,
    deleted_by          int            NULL,
    deleted_time        [datetime2](3) NULL,
    fdid                varchar(200)   NULL,
    account_holder_type [char](1)      NULL,
    db_create_time      datetime       not null default getdate()
        constraint pk_TEntityCatDefaults_EDW primary key (id)
);

CREATE TRIGGER [dbo].[TEntityCatDefaults_EDW_UPSERT]
    ON [dbo].[TEntityCatDefaults_EDW]
    INSTEAD OF INSERT
    AS
BEGIN
    INSERT INTO [dbo].[TEntityCatDefaults_EDW] (id, entity_id, created_by, creation_time, is_deleted,
                                                deleted_by,
                                                deleted_time, fdid, account_holder_type)

    SELECT id,
           entity_id,
           created_by,
           creation_time,
           is_deleted,
           deleted_by,
           deleted_time,
           fdid,
           account_holder_type
    FROM inserted I
    where not exists (select 1 from dbo.TEntityCatDefaults_EDW L where L.id = I.id);
    UPDATE [dbo].[TEntityCatDefaults_EDW]
    SET [is_deleted]   = I.[is_deleted]
      , [deleted_by]   = I.[deleted_by]
      , [deleted_time] = I.[deleted_time]
    FROM Inserted I
    WHERE TEntityCatDefaults_EDW.[id] = I.id;
end;