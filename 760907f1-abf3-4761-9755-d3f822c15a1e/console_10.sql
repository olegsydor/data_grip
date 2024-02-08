insert into external_data.activ_us_equity_option(permission_id, state, bid_condition, record_status, update_id,
                                                 bid_size, bid, bid_time, bid_exchange, ask_time, ask_condition,
                                                 last_update_date, ask_size, ask, ask_exchange, quote_date,
                                                 previous_close, option_type, create_date, trade_size, trade,
                                                 trade_exchange, trade_date, open, expiration_type, close_date,
                                                 cumulative_value, trade_id, trade_high, entity_type, close_status,
                                                 cumulative_price, trade_time, previous_trading_date, trade_low,
                                                 closing_quote_date, trade_count, previous_trade_time, reset_date,
                                                 close, previous_quote_date, cumulative_volume, closing_bid,
                                                 previous_open, closing_bid_exchange, trade_correction_time,
                                                 closing_ask, trade_condition, previous_trade_high,
                                                 close_cumulative_volume_date, strike_price, previous_ask,
                                                 open_exchange, previous_trade_low, close_cumulative_volume_status,
                                                 trade_id_cancel, net_change, life_time_high,
                                                 close_cumulative_value_tatus, mic, previous_net_change, trade_low_time,
                                                 life_time_low, close_cumulative_volume, percent_change,
                                                 trade_id_original, "close_cumulative_vValue", trade_high_time,
                                                 trade_correction_date, trade_id_corrected, previous_cumulative_volume,
                                                 previous_bid, trade_high_exchange, open_interest_date, local_code,
                                                 trade_low_exchange, previous_open_interest_date, context,
                                                 close_exchange, previous_cumulative_value, open_time,
                                                 life_time_high_date, open_interest, closing_ask_exchange,
                                                 previous_cumulative_volume_date, previous_percent_change,
                                                 trade_high_condition, life_time_low_date, previous_open_interest,
                                                 close_condition, previous_close_date, previous_cumulative_price,
                                                 trade_low_condition, expiration_date, open_condition, symbol,
                                                 load_batch_id)
select "PermissionId(441)"::int4,
       "State(361)"::int4,
       "BidCondition(2)",
       "RecordStatus(447)"::int4,
       "UpdateId(483)"::int4,
       "BidSize(1)"::int4,
       "Bid(0)":: double precision,
       "BidTime(3)"::time(3),
       "BidExchange(4)",
       "AskTime(8)"::time(3),
       "AskCondition(7)",
       "LastUpdateDate(413)"::date,
       "AskSize(6)"::int4,
       "Ask(5)":: double precision,
       "AskExchange(9)",
       "QuoteDate(11)"::date,
       "PreviousClose(113)":: double precision,
       "OptionType(329)",
       "CreateDate(395)"::date,
       "TradeSize(13)"::int4,
       "Trade(12)":: double precision,
       "TradeExchange(17)",
       "TradeDate(16)"::date,
       "Open(35)":: double precision,
       "ExpirationType(753)"::int4,
       "CloseDate(65)"::date,
       "CumulativeValue(51)":: double precision,
       "TradeId(1128)",
       "TradeHigh(18)":: double precision,
       "EntityType(398)"::int4,
       "CloseStatus(63)"::int4,
       "CumulativePrice(50)":: double precision,
       "TradeTime(15)"::time(3),
       "PreviousTradingDate(112)"::date,
       "TradeLow(22)":: double precision,
       "ClosingQuoteDate(60)"::date,
       "TradeCount(26)"::int4,
       "PreviousTradeTime(1359)"::time(3),
       "ResetDate(449)"::date,
       "Close(61)":: double precision,
       "PreviousQuoteDate(654)"::date,
       "CumulativeVolume(52)"::int4,
       "ClosingBid(56)":: double precision,
       "PreviousOpen(114)":: double precision,
       "ClosingBidExchange(57)",
       "TradeCorrectionTime(1132)"::time(3),
       "ClosingAsk(58)":: double precision,
       "TradeCondition(14)",
       "PreviousTradeHigh(115)":: double precision,
       "CloseCumulativeVolumeDate(69)"::date,
       "StrikePrice(362)":: double precision,
       "PreviousAsk(653)":: double precision,
       "OpenExchange(39)",
       "PreviousTradeLow(116)":: double precision,
       "CloseCumulativeVolumeStatus(68)"::int4,
       "TradeIdCancel(1141)",
       "NetChange(54)":: double precision,
       "LifetimeHigh(156)":: double precision,
       "CloseCumulativeValueStatus(71)"::int4,
       "Mic(1159)",
       "PreviousNetChange(119)":: double precision,
       "TradeLowTime(24)"::time(3),
       "LifetimeLow(158)":: double precision,
       "CloseCumulativeVolume(67)"::int4,
       "PercentChange(55)":: double precision,
       "TradeIdOriginal(1129)",
       "CloseCumulativeValue(70)":: double precision,
       "TradeHighTime(20)"::time(3),
       "TradeCorrectionDate(1131)"::date,
       "TradeIdCorrected(1130)",
       "PreviousCumulativeVolume(658)"::int4,
       "PreviousBid(652)":: double precision,
       "TradeHighExchange(21)",
       "OpenInterestDate(135)"::date,
       "LocalCode(301)",
       "TradeLowExchange(25)",
       "PreviousOpenInterestDate(122)"::date,
       "Context(394)"::int4,
       "CloseExchange(66)",
       "PreviousCumulativeValue(657)":: double precision,
       "OpenTime(38)"::time(3),
       "LifetimeHighDate(157)"::date,
       "OpenInterest(134)"::int4,
       "ClosingAskExchange(59)",
       "PreviousCumulativeVolumeDate(659)"::date,
       "PreviousPercentChange(120)":: double precision,
       "TradeHighCondition(19)",
       "LifetimeLowDate(159)"::date,
       "PreviousOpenInterest(121)"::int4,
       "CloseCondition(62)",
       "PreviousCloseDate(655)"::date,
       "PreviousCumulativePrice(516)",
       "TradeLowCondition(23)",
       "ExpirationDate(280)"::date,
       "OpenCondition(37)",
       "Symbol(456)",
       -1::int4
select *
from billing.activ
where "Symbol(456)" ilike '%AA/MKz8K.O%';

