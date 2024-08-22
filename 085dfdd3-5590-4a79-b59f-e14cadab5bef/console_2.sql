use blaze7;

CREATE TABLE Blaze7.dbo.exchange_map
(
    mic_code               varchar(200) NOT NULL,
    security_type          char(1)      NOT NULL,
    venue_exchange         varchar(200) NULL,
    business_name          varchar(200) NULL,
    ex_destination         varchar(200) NULL,
    venue_fix_code         varchar(200) NULL,
    exchange_code          char(1)      NULL,
    is_exchange            char(1)      NOT NULL,
    applicable_spread_type char(1)      NULL,
    supports_bi            char(1)      NOT NULL,
    supports_cob           char(1)      NOT NULL,
    CONSTRAINT pk_exchange_map PRIMARY KEY (mic_code)
);

truncate table [dbo].[exchange_map];

select 1;