-- DROP PROCEDURE billing.update_imc_billing_type(date, date);
create schema billing;

-- billing.dash_trade_record definition

-- Drop table

-- DROP TABLE billing.dash_trade_record;

CREATE TABLE billing.dash_trade_record (
	id int8 NOT NULL,
	trade_record_id int8 NOT NULL,
	trade_record_time timestamp NULL,
	order_id varchar(256) NOT NULL,
	exec_id int8 NOT NULL,
	date_id int4 NOT NULL,
	is_busted bpchar(1) NULL,
	subsystem_id varchar(20) NULL,
	user_id int4 NULL,
	account_id int4 NULL,
	client_order_id varchar(256) NULL,
	side bpchar(1) NULL,
	open_close bpchar(1) NULL,
	exchange_id varchar(6) NULL,
	trade_liquidity_indicator varchar(256) NULL,
	last_mkt varchar(5) NULL,
	last_qty int4 NULL,
	last_px numeric NULL,
	ex_destination varchar(5) NULL,
	sub_strategy varchar(128) NULL,
	multileg_reporting_type bpchar(1) NULL,
	exec_broker varchar(32) NULL,
	cmta varchar(3) NULL,
	street_is_cross_order bpchar(1) NULL,
	street_cross_is_originator bpchar(1) NULL,
	street_time_in_force bpchar(1) NULL,
	street_order_qty int4 NULL,
	opt_customer_firm bpchar(1) NULL,
	contra_broker varchar(256) NULL,
	bid_price numeric(12, 4) NULL,
	bid_qty int4 NULL,
	ask_price numeric(12, 4) NULL,
	ask_qty int4 NULL,
	client_id varchar(256) NULL,
	leaves_qty int4 NULL,
	trading_firm_id varchar(60) NULL,
	strategy_decision_reason_code int2 NULL,
	account_name varchar(30) NULL,
	instrument_type_id bpchar(1) NULL,
	symbol varchar(10) NULL,
	inst_last_trade_date timestamp NULL,
	maturity_year int2 NULL,
	maturity_month int2 NULL,
	maturity_day int2 NULL,
	put_call bpchar(1) NULL,
	strike_price numeric(12, 4) NULL,
	trading_firm_unq_id int4 NULL,
	away_exchange_id varchar(50) NULL,
	floor_broker_id varchar(255) NULL,
	security_tape varchar(10) NULL,
	secondary_order_id varchar(255) NULL,
	secondary_exch_exec_id varchar(255) NULL,
	street_order_id varchar(255) NULL,
	exch_exec_id varchar(255) NULL,
	load_batch_id int4 NULL,
	mpid varchar(5) NULL,
	fix_comp_id varchar(30) NULL,
	on_behalf_of_sub_id varchar(256) NULL,
	orig_trade_record_id int8 NULL,
	cross_type varchar(50) NULL,
	street_opt_customer_firm varchar(1) NULL,
	auction_id int8 NULL,
	street_exec_broker varchar(50) NULL,
	street_order_type varchar(1) NULL,
	street_account_name varchar(50) NULL,
	contra_capacity varchar(50) NULL,
	price_limit numeric(12, 4) NULL,
	order_type varchar(5) NULL,
	edw_generation int4 NULL,
	edw_child_orders int4 NULL,
	edw_destination_company_id int8 NULL,
	edw_company_id int8 NULL,
	edw_user_id int8 NULL,
	edw_owner_id int8 NULL,
	edw_parent_order_id uuid NULL,
	edw_order_id int8 NULL,
	edw_report_id int8 NULL,
	edw_parent_exdestination varchar(50) NULL,
	edw_system_order_id varchar(128) NULL,
	edw_user_system_id int4 NULL,
	edw_account varchar(128) NULL,
	edw_par_route varchar(128) NULL,
	edw_par_booth varchar(128) NULL,
	edw_manual_route varchar(50) NULL,
	edw_account_comm money NULL,
	edw_sending_user_id int8 NULL,
	edw_sending_company_id int8 NULL,
	edw_give_up varchar(128) NULL,
	acc_rate_type varchar(10) NULL,
	billing_type varchar(20) NULL,
	exch_order_id varchar(50) NULL,
	pg_big_data_create_time timestamp NULL,
	lp_list varchar(200) NULL,
	pt_basket_id varchar(100) NULL,
	is_pragma bool NULL,
	edw_billing_type varchar(20) NULL,
	option_product_class varchar(50) NULL,
	street_cross_type varchar(50) NULL,
	trade_record_reason varchar(2) NULL,
	snapshot_parent_bid_price numeric(12, 4) NULL,
	snapshot_parent_ask_price numeric(12, 4) NULL,
	snapshot_parent_bid_qty int4 NULL,
	snapshot_parent_ask_qty int4 NULL,
	pg_exec_id int8 NULL,
	ml_tier_rate_diff numeric(22, 10) NULL,
	bundle_id int4 NULL,
	order_process_time timestamp NULL,
	cons_lite_lp_list varchar(100) NULL,
	billing_type_old varchar(50) NULL,
	cons_payment_per_contract numeric(12, 4) NULL,
	street_client_id varchar(255) NULL,
	fee_sensitivity int4 NULL,
	mco_maker_taker_fee numeric(16, 4) NULL,
	mco_transaction_fee numeric(16, 4) NULL,
	mco_trade_processing_fee numeric(16, 4) NULL,
	mco_dash_commission numeric(16, 4) NULL,
	mco_royalty_fee numeric(16, 4) NULL,
	component_type bpchar(1) NULL,
	clearing_charge float8 NULL,
	allocation_charge float8 NULL,
	cross_order_id int4 NULL,
	contra_trading_firm varchar(60) NULL,
	ats_channel varchar(12) NULL,
	billing_code varchar(20) NULL,
	exec_instruction varchar(128) NULL,
	box_transactions_breakups varchar(128) NULL,
	client_commission_rate numeric(20, 8) NULL,
	edw_exch_special_order_data varchar(32) NULL,
	edw_exch_give_up int4 NULL,
	edw_exch_cmta int4 NULL,
	edw_exch_capacity varchar(32) NULL,
	edw_exch_fee_code varchar(32) NULL,
	edw_exch_contra_capacity varchar(32) NULL,
	edw_exch_contra_multi_leg varchar(32) NULL,
	edw_exch_contra_order_type varchar(32) NULL,
	edw_exch_matching_type varchar(32) NULL,
	edw_exch_occ_id varchar(32) NULL,
	edw_exch_internal_order_id varchar(32) NULL,
	edw_exch_internal_trade_id varchar(32) NULL,
	edw_exch_match_id varchar(32) NULL,
	alloc_instr_id int4 NULL,
	edw_exch_fees float8 NULL,
	edw_exch_qty int8 NULL,
	edw_exch_fee_description varchar(128) NULL,
	edw_exch_fee_billed float8 NULL,
	edw_exch_fee_calc float8 NULL,
	is_ats bit(1) NULL,
	street_on_behalf_of_sub_id varchar(256) NULL,
	posting_tier varchar(255) NULL,
	posting_rebate_rate float8 NULL,
	removing_tier varchar(255) NULL,
	removing_rebate_rate float8 NULL,
	is_break_up bit(1) NULL,
	break_up_rebate_rate float8 NULL,
	complex_tier varchar(255) NULL,
	complex_tier_rebate_rate float8 NULL,
	crossing_tier varchar(255) NULL,
	crossing_tier_rebate_rate float8 NULL,
	arcaex_id varchar(50) NULL,
	routing_subsidy_tier varchar(255) NULL,
	routing_subsidy_tier_rebate_rate float8 NULL,
	additional_tier varchar(255) NULL,
	additional_tier_rebate_rate float8 NULL,
	edw_exch_invoice_group varchar(100) NULL,
	allocation_avg_price numeric(12, 6) NULL,
	account_nickname varchar(40) NULL,
	leg_ref_id varchar(51) NULL,
	no_legs int4 NULL,
	penny_nickel bpchar(1) NULL,
	order_qty int4 NULL,
	client_posting_tier varchar(255) NULL,
	client_posting_rebate_rate float8 NULL,
	client_removing_tier varchar(255) NULL,
	client_removing_rebate_rate float8 NULL,
	client_break_up_rebate_rate float8 NULL,
	client_complex_tier varchar(255) NULL,
	client_complex_tier_rebate_rate float8 NULL,
	client_crossing_tier varchar(255) NULL,
	client_crossing_tier_rebate_rate float8 NULL,
	client_routing_subsidy_tier varchar(255) NULL,
	client_routing_subsidy_tier_rebate_rate float8 NULL,
	client_additional_tier varchar(255) NULL,
	client_additional_tier_rebate_rate float8 NULL,
	edw_tier_billed float8 NULL,
	edw_exch_surcharge_fees float8 NULL,
	edw_exch_surcharge_calc float8 NULL,
	edw_exch_surcharge_billed float8 NULL,
	tcce_maker_taker_fee_amount numeric(20, 8) NULL,
	tcce_admin_maker_taker_fee_amount numeric(20, 8) NULL,
	tcce_admin_transaction_fee_amount numeric(20, 8) NULL,
	tcce_transaction_fee_amount numeric(20, 8) NULL,
	tcce_royalty_fee_amount numeric(20, 8) NULL,
	tcce_account_dash_commission_amount numeric(20, 8) NULL,
	tcce_trade_processing_fee_amount numeric(20, 8) NULL,
	arca_posting_tier numeric(16, 6) NULL,
	is_exchange_fee_eligible bool NULL,
	is_spi bpchar(1) NULL,
	taf_rate numeric(20, 6) NULL,
	dtr_db_create_time timestamp NULL,
	pg_update_time timestamp NULL,
	blaze_account_alias varchar(255) NULL,
	cons_lite_rfid varchar(256) NULL,
	trade_text varchar(100) NULL,
	dtr_daily_create_time timestamp NULL,
	CONSTRAINT pk_dash_trade_record PRIMARY KEY (id, date_id)
)
PARTITION BY RANGE (date_id);
CREATE INDEX dash_trade_record_edw_report_id_idxx ON ONLY billing.dash_trade_record USING btree (edw_report_id, date_id, is_busted) INCLUDE (client_order_id, order_process_time, multileg_reporting_type, instrument_type_id);
CREATE INDEX dash_trade_record_load_batch_id_idx ON ONLY billing.dash_trade_record USING btree (load_batch_id);
CREATE INDEX idxx_cboe_qcc ON ONLY billing.dash_trade_record USING btree (exchange_id, street_cross_is_originator, cross_type) INCLUDE (exec_id);
CREATE INDEX idxx_dash_trade_record_date_id_ise_matching ON ONLY billing.dash_trade_record USING btree (date_id) INCLUDE (id, trade_record_id, trade_record_time, exec_id, is_busted, side, open_close, exchange_id, last_mkt, last_qty, last_px, trading_firm_id, maturity_year, maturity_month, maturity_day, put_call, strike_price, secondary_order_id, street_order_id);
CREATE INDEX idxx_dash_trade_record_instrument_type_id_edw_billing_type_cont ON ONLY billing.dash_trade_record USING btree (instrument_type_id, edw_billing_type, contra_trading_firm, date_id, trading_firm_id) INCLUDE (trade_record_id, exec_id, edw_report_id, component_type, cons_payment_per_contract);
CREATE INDEX idxx_dash_trade_record_instrument_type_id_edw_exch_give_up_date ON ONLY billing.dash_trade_record USING btree (instrument_type_id, edw_exch_give_up, date_id) INCLUDE (id, trade_record_id);
CREATE INDEX idxx_dash_trade_record_replace_auction_id ON ONLY billing.dash_trade_record USING btree (auction_id);
CREATE INDEX idxx_dash_trade_record_replace_cross_order_id ON ONLY billing.dash_trade_record USING btree (cross_order_id) INCLUDE (id, trade_record_id, is_busted, lp_list, cons_lite_lp_list, cons_payment_per_contract, component_type);
CREATE INDEX idxx_dash_trade_record_replace_date_id ON ONLY billing.dash_trade_record USING btree (date_id, fix_comp_id) INCLUDE (id, trade_record_id, trade_record_time, exec_id, client_order_id, exch_exec_id, side, order_id, account_id, open_close, exchange_id, last_mkt, last_qty, last_px, trading_firm_id, maturity_year, maturity_month, maturity_day, put_call, strike_price, secondary_order_id, street_order_id);
CREATE INDEX idxx_dash_trade_record_replace_date_id_trade_record_id_exec_id ON ONLY billing.dash_trade_record USING btree (date_id) INCLUDE (trade_record_id, exec_id, exchange_id, last_qty, exec_broker, opt_customer_firm, client_id, trading_firm_id, symbol, street_exec_broker, contra_capacity);
CREATE INDEX idxx_dash_trade_record_replace_date_id_trading_firm_id_edw_bill ON ONLY billing.dash_trade_record USING btree (date_id, trading_firm_id, edw_billing_type) INCLUDE (trade_record_id, exec_id, edw_report_id);
CREATE INDEX idxx_dash_trade_record_replace_edw_report_id ON ONLY billing.dash_trade_record USING btree (is_busted, instrument_type_id, date_id, edw_report_id) INCLUDE (trade_record_id);
CREATE INDEX idxx_dash_trade_record_replace_exch_exec_id ON ONLY billing.dash_trade_record USING btree (exch_exec_id, trade_record_id, date_id) INCLUDE (client_order_id);
CREATE INDEX idxx_dash_trade_record_replace_is_busted ON ONLY billing.dash_trade_record USING btree (is_busted) INCLUDE (trade_record_id, exec_id, date_id, trading_firm_id);
CREATE INDEX idxx_dash_trade_record_replace_is_busted_date_id ON ONLY billing.dash_trade_record USING btree (date_id, is_busted) INCLUDE (trade_record_id, trade_record_time, exec_id, side, exchange_id, last_mkt, trading_firm_id, secondary_order_id, secondary_exch_exec_id, street_order_id, exch_exec_id, id, last_qty, maturity_year, maturity_month, maturity_day, put_call, strike_price, instrument_type_id, multileg_reporting_type);
CREATE INDEX idxx_dash_trade_record_replace_is_busted_exchange_id ON ONLY billing.dash_trade_record USING btree (is_busted, exchange_id) INCLUDE (trade_record_id, trade_record_time, exec_id, trading_firm_id, secondary_order_id, secondary_exch_exec_id, exch_exec_id);
CREATE INDEX idxx_dash_trade_record_replace_last_qty_trade_record_time ON ONLY billing.dash_trade_record USING btree (last_qty, trade_record_time) INCLUDE (trade_record_id, exec_id, side, exchange_id, last_mkt, trading_firm_id, put_call, secondary_order_id, street_order_id);
CREATE INDEX idxx_dash_trade_record_replace_pg_exec_id ON ONLY billing.dash_trade_record USING btree (pg_exec_id);
CREATE INDEX idxx_dash_trade_record_replace_street_order_id_trade_time_date_ ON ONLY billing.dash_trade_record USING btree (secondary_order_id, trade_record_time, date_id) INCLUDE (trade_record_id, exec_id, is_busted, exchange_id, last_mkt, trading_firm_id, secondary_exch_exec_id, exch_exec_id, auction_id);
CREATE INDEX idxx_dash_trade_record_replace_trade_record_id ON ONLY billing.dash_trade_record USING btree (trade_record_id) INCLUDE (exec_id, client_order_id, last_qty, exch_exec_id);
CREATE INDEX idxx_dash_trade_record_replaceis_busted_instrument_type_id ON ONLY billing.dash_trade_record USING btree (is_busted, instrument_type_id) INCLUDE (trade_record_id, exec_id, date_id);
CREATE UNIQUE INDEX idxx_dash_trade_record_trade_record_id ON ONLY billing.dash_trade_record USING btree (trade_record_id, date_id);
CREATE INDEX idxx_exec_id ON ONLY billing.dash_trade_record USING btree (exec_id, is_busted) INCLUDE (trade_record_id, date_id, pg_exec_id);


create or replace procedure billing.update_imc_billing_type(in p_start_date date, in p_end_date date)
    language plpgsql
as
$procedure$

declare
    l_load_id      int;
    l_step_id      int;
    l_startdate_id int;
    l_enddate_id   int;
    l_array_1      text[];
    l_array_2      text[];
    l_array_3      text[];
    l_array_4      text[];
    l_array_5      text[];
begin
   select nextval('public.load_timing_seq') into l_load_id;
   l_step_id:=1;


   l_array_1 =
           array ['AAXJ','AB','ABR','ACWI','ACWV','ACWX','AEHR','AEO','AGG','AJG','ALK','AMJ','AMLP','AMZA','ANGL','APLE','APPN','ARGT','ARKQ','ARKX','ARRY','ASHR','ASHS','ASO','ATI','AU', 'BALL','BBAI','BBH','BBWI','BCI','BE','BEN','BGFV','BGS','BHF','BIB','BIS','BIZD','BJK','BKF','BKLN','BKR','BLCN','BLDP','BLDR','BLOK','BMA','BND','BNO','BNS','BOTZ','BOX', 'BRF','BRZU','BUZZ','BVN','BXMT','BXP','BZH','BZQ','CANE','CB','CBRE','CC','CDC','CDE','CENX','CEQP','CFG','CG','CHAD','CHAU','CHIX','CIBR','CIM','CINF','CL','CM','CMC', 'CMS','CNK','CNP','CNXT','CNYA','COM','COOP','COPX','CORN','CPER','CS','CTRA','CTRM','CURE','CWB','CWEB','CYB','CYBR','D','DAX','DBA','DBB','DBC','DBI','DBO','DBP','DD', 'DDM','DEM','DFEN','DGRO','DGS','DIG','DINO','DJP','DLN','DOCN','DOG','DRIP','DRIV','DRN','DRV','DSL','DUG','DUSL','DUST','DVY','DXD','DXJ','EBIX','ECH','ECNS','EDC','EDV', 'EDZ','EEMV','EET','EEV','EFAV','EFG','EFV','EFZ','EIDO','EMB','ENB','ENVX','EPI','EPP','EPV','EQH','EQNR','EQR','ERY','ETN','ETR','EUFN','EUM','EUO','EURL','EVGO','EWA', 'EWC','EWH','EWI','EWL','EWM','EWP','EWQ','EWS','EWU','EWV','EZA','EZJ','EZU','FAN','FAST','FBT','FCG','FDN','FENY','FEZ','FFTY','FINX','FM','FNCL','FNGS','FNV','FOUR', 'FREY','FRO','FTV','FXA','FXB','FXC','FXG','FXH','FXP','GAMR','GCC','GDS','GFS','GINN','GLL','GNK','GNOM','GNR','GRAB','GREK','GSG','GSLC','GTLB','GXC','GXG','HA','HACK', 'HCP','HDGE','HDV','HEDJ','HERO','HEWG','HIBL','HIBS','HP','HPE','HUN','HYD','HYMB','IAI','IAT','IBN','ICF','IDU','IDV','IEFA','IEI','IEMG','IEO','IEUR','IEV','IEZ','IFF', 'IGE','IGF','IGM','IGN','IGT','IHE','IHF','IHI','IJH','IJJ','IJK','IJR','IJS','IJT','ILF','INDI','INDL','INDS','INDY','INFL','ING','IOO','IPO','IRM','ITA','ITOT','IUSG','IVE', 'IVOL','IVW','IVZ','IWB','IWC','IWD','IWF','IWN','IWO','IWP','IWR','IWS','IWV','IXC','IXJ','IXP','IXUS','IYC','IYE','IYF','IYG','IYH','IYM','IYT','IYW','IYZ','JDST','JEF','JNK', 'JOAN','KBA','KBE','KBWB','KCE','KEY','KEYS','KIE','KIM','KLXE','KNX','KRBN','KSA','KYN','LEMB','LIT','LPX','LYB','MAG','MAT','MBB','MBLY','MCHI','METV','MFC','MGC','MGK','MGV', 'MIDU','MKC','MNDY','MOO','MORT','MTDR','MTUM','MUB','MXI','MYY','MZZ','NAIL','NDAQ','NG','NINE','NOBL','NOG','NRG','NTNX','NYCB','O','OEF','OHI','OIL','OILK','OKE','OMF','ONLN', 'ONON','OUSA','OVV','OZK','PAA','PAGP','PATH','PAVE','PBF','PBW','PCT','PDBC','PEG','PEJ','PFF','PGF','PGR','PHO','PICK','PIN','PJP','PNQI','POTX','PPH','PRF','PRNT','PSA','PSCE', 'PSNY','PST','PSTG','PTEN','PWR','PXE','QCLN','QFIN','QQEW','QQQE','QQQJ','QQQM','QTEC','QUAL','QYLD','QYLG','RACE','REET','REK','REM','REMX','RETL','REW','REZ','RFV','RGLD','RING', 'RITM','RL','ROBO','ROM','RPV','RSP','RTH','RWM','RWR','RXD','RXL','RYLD','RZV','SA','SAA','SABR','SAND','SBIO','SBLK','SBRA','SCC','SCHA','SCHB','SCHD','SCHE','SCHG','SCHH','SCHM', 'SCHP','SCHV','SCHX','SCJ','SCO','SCZ','SD','SDD','SDIV','SDY','SEF','SF','SGOL','SHC','SIJ','SIL','SILJ','SIVR','SJB','SJNK','SKF','SKT','SKYU','SKYY','SLG','SLX','SM','SMDD','SMG', 'SMN','SOCL','SOUN','SOYB','SPCX','SPDN','SPDW','SPHB','SPHD','SPLG','SPLV','SPR','SPSM','SPTM','SPTS','SPUU','SPYD','SPYG','SPYV','SRLN','SRS','SRTY','SSG','SSRM','STM','SURG','SVIX', 'SWAN','SYY','TARK','TBF','TECS','TER','TFC','THCX','TIP','TOL','TRGP','TRIP','TTE','TTT','TUR','TWM','TYD','TYO','UA','UBS','UBT','UDN','UEC','UGA','UGL','ULE','UMDD','UNM','UPW','URA', 'URBN','URE','URNM','URTH','URTY','USCI','USD','USDU','USHY','USL','USMV','UTSL','UWM','UYG','UYM','VAW','VB','VBK','VBR','VCIT','VCR','VDC','VDE','VEA','VET','VEU','VFH','VGK','VGT','VHT', 'VIG','VIS','VIST','VIXM','VLUE','VMBS','VNQI','VO','VOD','VOE','VOT','VOX','VOYA','VPL','VPU','VRAY','VRNS','VSS','VST','VT','VTIP','VTLE','VTNR','VTV','VTWO','VUG','VV','VWO','VXF','VXUS', 'VXZ','VYM','WB','WCLD','WEAT','WEST','WGMI','WOLF','WOOD','WPC','WSM','WTI','WU','XAR','XES','XHE','XHS','XLC','XMLV','XPH','XPP','XSD','YCL','YCS','YXI','ZG','ZIM','ZION','ZIP','ZROZ','ZSL'];

   l_array_2 =
           array ['AB','ABR','ACWI','AEHR','AEO','AGG','AJG','ALK','AMLP','AMZA','ANGL','APLE','APPN','ARGT','ARKQ','ARKX','ARRY','ASHR','ASO','ATI', 'AU','BALL','BBAI','BBH','BBWI','BCI','BE','BEN','BGFV','BGS','BHF','BIB','BIZD','BKLN','BKR','BLDP','BLDR','BLOK','BMA','BND','BNO', 'BNS','BOTZ','BOX','BRZU','BUZZ','BXMT','BXP','BZH','BZQ','CANE','CB','CBRE','CC','CDE','CENX','CEQP','CFG','CG','CHAU','CIBR','CIM', 'CINF','CL','CM','CMC','CMS','CNK','CNP','COOP','COPX','CORN','CPER','CS','CTRA','CTRM','CURE','CWB','CWEB','CYB','CYBR','D','DBA', 'DBC','DBI','DBO','DD','DDM','DFEN','DGRO','DIG','DINO','DOCN','DOG','DRIP','DRIV','DRN','DRV','DUG','DUST','DVY','DXD','DXJ','EBIX', 'EDC','EDV','EDZ','EIDO','EMB','ENB','ENVX','EPI','EPV','EQH','EQNR','EQR','ERY','ETN','ETR','EUFN','EUO','EURL','EVGO','EWA','EWC', 'EWH','EWL','EWP','EWQ','EWU','EZA','EZU','FAST','FCG','FDN','FENY','FEZ','FFTY','FINX','FM','FNCL','FNGS','FNV','FOUR','FREY','FRO', 'FTV','FXB','FXP','GDS','GFS','GLL','GNK','GNR','GRAB','GREK','GSLC','HA','HACK','HCP','HDGE','HDV','HERO','HIBL','HIBS','HP','HPE', 'HUN','HYD','IAT','IBN','IDV','IEFA','IEI','IEMG','IEO','IEV','IEZ','IFF','IGE','IGT','IHF','IHI','IJH','IJJ','IJR','IJS','IJT','ILF', 'INDI','INDL','INDY','ING','IPO','IRM','ITA','ITOT','IUSG','IVE','IVOL','IVW','IVZ','IWB','IWC','IWD','IWF','IWN','IWO','IWP','IWR', 'IWV','IXC','IXUS','IYE','IYH','IYT','IYW','IYZ','JDST','JEF','JNK','JOAN','KBA','KBE','KBWB','KEY','KEYS','KIE','KIM','KLXE','KNX', 'KRBN','KYN','LIT','LPX','LYB','MAG','MAT','MBLY','MCHI','METV','MFC','MGC','MGK','MGV','MIDU','MKC','MNDY','MOO','MORT','MTDR','MUB', 'NAIL','NDAQ','NG','NINE','NOBL','NOG','NRG','NTNX','NYCB','O','OHI','OIL','OILK','OKE','OMF','ONON','OVV','OZK','PAA','PAGP','PATH', 'PAVE','PBF','PBW','PCT','PDBC','PEG','PEJ','PFF','PGR','PICK','POTX','PRNT','PSA','PSCE','PSNY','PST','PSTG','PTEN','PWR','PXE','QCLN', 'QFIN','QQQE','QQQJ','QQQM','QUAL','QYLD','RACE','REK','REM','REMX','RETL','REW','RGLD','RING','RITM','RL','ROM','RPV','RSP','RWM','RWR', 'RYLD','SA','SABR','SAND','SBLK','SBRA','SCHA','SCHB','SCHD','SCHE','SCHG','SCHH','SCHP','SCHV','SCHX','SCO','SCZ','SD','SDD','SDIV', 'SDY','SEF','SF','SGOL','SHC','SIL','SILJ','SIVR','SJB','SKF','SKT','SKYY','SLG','SLX','SM','SMG','SOUN','SOYB','SPCX','SPDN','SPHB', 'SPHD','SPLG','SPR','SPTM','SPTS','SPUU','SPYD','SPYG','SPYV','SRLN','SRS','SRTY','SSRM','STM','SURG','SVIX','SWAN','SYY','TARK', 'TECS','TER','TFC','THCX','TIP','TOL','TRGP','TRIP','TTE','TTT','TUR','TWM','TYD','TYO','UA','UBS','UBT','UDN','UEC','UGA','UGL', 'UNM','UPW','URA','URBN','URNM','URTH','URTY','USD','USHY','USL','USMV','UTSL','UWM','UYG','VAW','VB','VBK','VBR','VCIT','VDC','VDE', 'VEA','VET','VEU','VFH','VGK','VGT','VHT','VIG','VIS','VIST','VIXM','VMBS','VO','VOD','VOE','VOT','VOYA','VPL','VPU','VRAY','VRNS', 'VST','VT','VTIP','VTLE','VTNR','VTV','VTWO','VUG','VV','VWO','VXF','VXUS','VXZ','VYM','WB','WCLD','WEAT','WEST','WOLF','WPC','WSM', 'WTI','WU','XAR','XES','XHS','XLC','XPP','XSD','YCL','YCS','YXI','ZG','ZIM','ZION','ZIP','ZROZ','ZSL'];

   l_array_3 =
           array ['AB','ABR','AEHR','ALK','AMLP','AMZA','ARKQ','ARKX','ARRY','ASHR','ASO','ATI','AU','BBAI','BBWI','BCI','BE','BEN','BGFV','BGS','BHF','BIB','BKR','BLDP','BLDR','BLOK','BND','BNO','BOTZ','BOX','BRZU','BXMT','BXP','BZH', 'BZQ','CANE','CB','CC','CDE','CENX','CEQP','CFG','CG','CHAU','CIBR','CIM','CL','CNK','COOP','COPX','CORN','CPER','CTRA','CURE','CWEB','CYBR','D','DBA','DBC','DBI','DD','DFEN','DGRO','DIG','DINO','DOCN','DOG','DRIP','DRN','DRV', 'DUG','DUST','DVY','DXD','DXJ','EBIX','EDC','EDV','EDZ','ENB','ENVX','EPI','EQNR','EQR','ERY','ETN','EUFN','EUO','EURL','EVGO','EWC','EWU','FAST','FCG','FDN','FENY','FEZ','FNCL','FNGS','FNV','FOUR','FREY','FRO','FXB','GFS', 'GNK','GRAB','HACK','HCP','HDV','HIBL','HIBS','HPE','IAT','IEFA','IEO','IEV','IEZ','IHI','IJH','IJR','IJS','INDI','INDL','ING','IRM','ITA','ITOT','IVZ','IWC','IWD','IWF','IWN','IWO','IXC','IXUS','IYT','IYW','JDST','JEF','JNK','KBA', 'KBE','KBWB','KEY','KEYS','KIE','KLXE','KNX','KYN','LIT','LYB','MAG','MAT','MBLY','MCHI','METV','MGK','MNDY','MTDR','NAIL','NINE','NOBL','NOG','NRG','NYCB','O','OHI','OIL','OKE','OMF','ONON','OVV','OZK','PAA','PAGP','PATH','PAVE', 'PBF','PCT','PGR','POTX','PSCE','PSTG','QQQE','QQQJ','QQQM','QYLD','REK','REM','REMX','RETL','RING','RITM','RSP','RWM','RYLD','SA','SAND','SBLK','SCHA','SCHD','SCHG','SCHH','SCHP','SCO','SD','SDIV','SDY','SEF','SGOL','SIL','SILJ', 'SIVR','SKT','SKYY','SLG','SLX','SMG','SOUN','SOYB','SPDN','SPHD','SPLG','SPR','SPYD','SPYG','SPYV','SRS','SRTY','SSRM','STM','SURG','SVIX','SYY','TECS','TFC','TOL','TRGP','TRIP','TTE','TTT','TUR','TWM','TYD','TYO','UA','UBS','UDN','UEC', 'UGA','UGL','UNM','URA','URBN','URNM','URTY','USD','UWM','VAW','VB','VBR','VCIT','VDE','VEA','VET','VFH','VGK','VGT','VHT','VIG','VO','VOE','VST','VT','VTIP','VTLE','VTV','VTWO','VUG','VWO','VXF','VXUS','VYM','WB','WCLD','WEAT','WEST', 'WOLF','WPC','WSM','WTI','WU','XES','XLC','XSD','YCL','YCS','ZG','ZION','ZROZ','ZSL'];

   l_array_4 =
           array ['VWO','RWM','VGK','ZION','WEAT','WSM','WOLF','URTY','VTLE','URA','VGT','UDN','UGA','ZROZ','XLC','VYM','VEA','ENVX','VUG'];

   l_array_5 =
           array ['ABR','AEHR','AMLP','ARRY','ASO','BBAI','BBWI','BE','BGFV','BKR','BLDR','BXMT','CANE','CDE','CFG','CL','CPER','CTRA','CWEB','D','DBI','DD','DFEN','DOCN','DRIP','DRV','DUG','DUST','DXD','EDV','EVGO','FENY','FOUR','GRAB','HIBS', 'IAT','IEFA','ITA','ITOT','IWF','JDST','JNK','KBE','KEY','KNX','LIT','MBLY','NAIL','NOBL','NRG','NYCB','O','OHI','OKE','OMF','ONON','OVV','OZK','PATH','PBF','PSTG','QQQM','QYLD','RETL','RITM','RSP','SBLK','SCHD','SCHG','SIL', 'SILJ','SLG','SOUN','SPLG','SPR','SPYG','SRTY','SSRM','SVIX','TECS','TFC','TOL','TUR','UBS','URA'];

   select public.load_log(l_load_id, l_step_id, 'update_imc_billing_type STARTED ===', 0, 'O')
   into l_step_id;

   l_startdate_id = to_char(p_start_date, 'YYYYMMDD')::int;
   l_enddate_id = to_char(p_end_date, 'YYYYMMDD')::int;

     select public.load_log(l_load_id, l_step_id, 'run for l_startdate_id = '||l_startdate_id::text||' and l_enddate_id = '||l_enddate_id::text, 0, 'O')
   into l_step_id;

   update billing.dash_trade_record d
      set edw_billing_type = NULL
   where
       date_id between l_startdate_id and l_enddate_id and
       trading_firm_id like 'OFP%' and
       edw_billing_type is not null;

   select public.load_log(l_load_id, l_step_id, 'update Eedw_billing_type in null', 0, 'O')
   into l_step_id;

   update billing.dash_trade_record
   set billing_type = case
--                            when billing_type = 'DMA' then 'DMA' - не має сенсу, бо в where вони відсічуться
       when multileg_reporting_type <> '1' then 'IMC'
       when symbol = any (l_array_1)  then 'EXHAUST'
--                           when date_id >= 20230615 and symbol = any (l_array_1) and multileg_reporting_type = '1'
--                               then 'EXHAUST'
--                           when date_id >= 20230612 and symbol = any (l_array_2) and multileg_reporting_type = '1'
--                               then 'EXHAUST'
--                           when date_id >= 20230607 and symbol = any (l_array_3) and multileg_reporting_type = '1'
--                               then 'EXHAUST'
--                           when date_id = 20230606 and symbol = any (l_array_4) and multileg_reporting_type = '1'
--                               then 'EXHAUST'
--                           when date_id = 20230605 and symbol = any (l_array_5) and multileg_reporting_type = '1'
--                               then 'EXHAUST'
--                           when date_id >= 20230322 and
--                                symbol in ('CTRA', 'TOL', 'D', 'SSRM', 'BKR', 'PSTG', 'ENVX', 'RWM', 'RSP', 'LIT') and
--                                multileg_reporting_type = '1' then 'EXHAUST'
--                           when date_id >= 20230206 and date_id <= 20230321 and
--                                symbol in ('DUST', 'JDST', 'PAA', 'O', 'VOD') and multileg_reporting_type = '1'
--                               then 'EXHAUST'
--                           when date_id >= 20221220 and date_id <= 20230321 and
--                                symbol in ('ASHR', 'YANG', 'YINN', 'ZIM', 'CS') and multileg_reporting_type = '1'
--                               then 'EXHAUST'
                          else 'IMC'
       end
   where true
--        and (billing_type is null or upper(billing_type) = 'EXHAUST')
     and coalesce(billing_type, 'EXHAUST') in ('EXHAUST', 'Exhaust')
     and date_id between l_startdate_id and l_enddate_id
     and trading_firm_id like 'OFP%'
--      and not (coalesce(component_type, '') = 'A')
   and component_type is distinct from 'A';

   select public.load_log(l_load_id, l_step_id, 'update Eedw_billing_type 1', 0, 'O')
   into l_step_id;

   update billing.dash_trade_record
      set edw_billing_type =
         case
             when multileg_reporting_type <> '1' then billing_type
--             when billing_type = 'DMA' then 'DMA'
--             when date_id >= 20230615 and symbol = any(l_array_1) and multileg_reporting_type = '1' then 'EXHAUST'
             when symbol = any(l_array_1) and multileg_reporting_type = '1' then 'EXHAUST'
--              WHEN date_id >= 20230612 and symbol  = any(l_array_2) and multileg_reporting_type = '1' then 'EXHAUST'
--              WHEN date_id >= 20230607 and symbol = any(l_array_3) and multileg_reporting_type = '1' then 'EXHAUST'
--             WHEN date_id >= 20230606 and symbol  = any(l_array_4) and multileg_reporting_type = '1' then 'EXHAUST'
--             WHEN date_id >= 20230605 and symbol  = any(l_array_5) and multileg_reporting_type = '1' then 'EXHAUST'
--             when date_id >= 20230322 and symbol in ('CTRA', 'TOL', 'D', 'SSRM', 'BKR', 'PSTG', 'ENVX', 'RWM', 'RSP', 'LIT') and multileg_reporting_type = '1' then 'EXHAUST'
--             when date_id >= 20230206 and date_id <= 20230321 and symbol in ('DUST', 'JDST', 'PAA', 'O', 'VOD') and multileg_reporting_type = '1' then 'EXHAUST'
--             when date_id >= 20221220 and date_id <= 20230321 and symbol in ('ASHR', 'YANG', 'YINN', 'ZIM', 'CS') and multileg_reporting_type = '1' then 'EXHAUST'
--             when date_id > 20180900  and date_id < 20181000 and trading_firm_id = 'OFP0002' and multileg_reporting_type = '1' and sub_strategy = 'SENSOR' then billing_type
--             when date_id >= 20181119 and trading_firm_id in ('OFP0009') and multileg_reporting_type = '1' and upper(billing_type) = 'EXHAUST' then billing_type        --Adding Pershing to dedicated exhaust channel
--             when date_id >= 20180925 and trading_firm_id in ('OFP0011','OFP0012','OFP0013','OFP0014','OFP0015') and multileg_reporting_type = '1' and upper(billing_type) = 'EXHAUST' then billing_type
--             when date_id < 20180925 and trading_firm_id in ('OFP0011','OFP0012','OFP0013','OFP0014','OFP0015') and multileg_reporting_type = '1' and upper(billing_type) = 'EXHAUST' and lp_list = 'GRPOLPD' then billing_type
--             when date_id < 20180925 and trading_firm_id in ('OFP0011','OFP0012','OFP0013','OFP0014','OFP0015') and multileg_reporting_type = '1' and upper(billing_type) = 'EXHAUST' and lp_list = 'BARCLLPD' then billing_type
            when trading_firm_id in ('OFP0016','OFP0001') and multileg_reporting_type = '1' and upper(billing_type) = 'EXHAUST' then billing_type
--             when date_id >= 20181101 and date_id < 20181201 and client_id <> account_name and sub_strategy = 'CSLDTR' and fix_comp_id <> 'IMC_EDW' and account_name not in ('TASTYWRX2','TASTYWRX3','TASTYWRX4','JPMOFP','dasherror') then 'Exhaust'
            else billing_type
         end
   where
      date_id between l_startdate_id and l_enddate_id and
      trading_firm_id like 'OFP%' and
      edw_billing_type is null;

   select public.load_log(l_load_id, l_step_id, 'update Eedw_billing_type 2', 0, 'O')
   into l_step_id;

   ---====== ADDED for OFP0011/14 SPI Marketable Single non-Penny flow -- Added 7/1/2020


    --=============== Robinhood not shown to Simplex added 8/26/2022


    update billing.dash_trade_record def
       set edw_billing_type = 'IMC'
    where
        trading_firm_id = 'OFP0046' and
        date_id between l_startdate_id and l_enddate_id and
        upper(billing_type) not in (
            'EXHAUST_IMC',
            'IMC',
            'IMC_ATS') and
        coalesce(component_type, '') <> 'A';

   select public.load_log(l_load_id, l_step_id, 'update Eedw_billing_type 3', 0, 'O')
   into l_step_id;

   --===============  STOP at DESK
--   update billing.dash_trade_record
--      set edw_billing_type = 'DMA'
--   where
--      date_id between l_startdate_id and l_enddate_id and
--      trading_firm_id like 'OFP0%' and
--      edw_report_id is not null;

    --== CUTLER IN CONS LITE

    update billing.Dash_Trade_Record x
    set
        edw_billing_type = 'Exhaust'
    where
        cross_order_id in (
            select d.cross_order_id
            from billing.Dash_Trade_Record d
            where lower(d.trading_firm_id) = 'cutler'
              and d.date_id between l_startdate_id and l_enddate_id
              and d.account_name in ('JAGCL', 'RAGCL', 'LAGCL'))
        and trading_firm_id like 'OFP%' and
       x.date_id between l_startdate_id and l_enddate_id
        ;

   select public.load_log(l_load_id, l_step_id, 'update Eedw_billing_type 4', 0, 'O')
   into l_step_id;

   --==========  ATS Trades Broken Up  Billable to IMC on the White list
   create temp table timcbreakeup as (
      select
         coalesce(dash.edw_report_id,dash.exec_id) RecordID
      from exchange_data.ise_gemini_mcry_pfof_charge_data ise
      inner join billing.dash_trade_record dash
         on ise.trade_record_id = dash.trade_record_id
      inner join billing.TISE_BillingCodes bc
         on ise.charge_code = bc."Charge Code"
      where
         dash.date_id between l_startdate_id and l_enddate_id and
         ise.trade_date_id between l_startdate_id and l_enddate_id and
         lower(bc.internal) in ('breakup') and
         dash.instrument_type_id = 'O' and
         lower(dash.edw_billing_type) in ('exhaust') and
         dash.trading_firm_id like 'OFP%'
      group by
         dash.exec_id,
         dash.trade_record_id,
         coalesce(dash.edw_report_id, dash.exec_id),
         lp_list,
         coalesce(component_type, ''),
         cons_lite_lp_list,
         date_id,
         dash.edw_billing_type,
         instrument_type_id,
         dash.trading_firm_id,
         dash.contra_trading_firm

      union

      -- EDGX Breakups
      select lad_record_id RecordID
      from exchange_data.v_edgo_breakup_billing_exhaust r
      where date_id between l_startdate_id and l_enddate_id
      group by lad_record_id

      union

      -- Waiting for MIAX
      select lad_record_id RecordID
      from exchange_data.v_miax_breakup_billing_exhaust r
      where
         PFOF_Rate <> 0 and
         date_id between l_startdate_id and l_enddate_id

      union

      -- NEW AMEX Breakups
      select lad_record_id RecordID
      from exchange_data.v_amex_breakup_billing_exhaust r
      where date_id between l_startdate_id and l_enddate_id
      group by lad_record_id
   );

   select public.load_log(l_load_id, l_step_id, 'create temp table timcbreakeup', 0, 'O')
   into l_step_id;

   update billing.dash_trade_record dt1
      set edw_billing_type = 'Exhaust_IMC',
          contra_trading_firm = NULL
   from billing.dash_trade_record dt
   inner join timcbreakeup bu
      on dt.trade_record_id = bu.RecordID
   left outer join billing.imc_white_list imcw
      on dt.Symbol = imcw.Symbol and
      dt.date_id >= to_char(imcw.StartDate, 'yyyymmdd')::int and
      (dt.date_id <= to_char(imcw.EndDate, 'yyyymmdd')::int or imcw.EndDate is null)
   Where
      dt.id = dt1.id and
      dt.date_id between l_startdate_id and l_enddate_id and
      dt1.date_id between l_startdate_id and l_enddate_id and
      dt.trading_firm_id like 'OFP0%' and
      dt.street_is_cross_order = 'Y' and
      dt.billing_type <> 'IMC' and
      coalesce(dt.component_type, '') = 'A' and
      imcw.Symbol is not null;

   select public.load_log(l_load_id, l_step_id, 'update Eedw_billing_type 5', 0, 'O')
   into l_step_id;

   --===========

   update billing.dash_trade_record dash1
      set edw_billing_type =
         case
            when dash.date_id >= 20230615 and dash.symbol = any(l_array_1) then 'EXHAUST'
            when dash.date_id >= 20230612 and dash.symbol  = any(l_array_2) then 'EXHAUST'
            when dash.date_id >= 20230607 and dash.symbol = any(l_array_3) then 'EXHAUST'
            when dash.date_id >= 20230606 and dash.symbol   = any(l_array_4) then 'EXHAUST_ATS'
            when dash.date_id >= 20230605 and dash.symbol  = any(l_array_5) then 'EXHAUST_ATS'
            WHEN dash.date_id >= 20230322 and dash.symbol in ('CTRA', 'TOL', 'D', 'SSRM', 'BKR', 'PSTG', 'ENVX', 'RWM', 'RSP', 'LIT') then 'EXHAUST_ATS'
            when dash.date_id >= 20230206 and dash.date_id <= 20230321 and dash.symbol in ('DUST', 'JDST', 'PAA', 'O', 'VOD') then 'EXHAUST_ATS'
            when dash.date_id >= 20221220 and dash.date_id <= 20230321 and dash.symbol in ('ASHR', 'YANG', 'YINN', 'ZIM', 'CS') then  'EXHAUST_ATS'
            when imcw.Symbol is not null then  'IMC_ATS'
            when dash.date_id >= 20221014 then 'IMC_ATS'
            when dash.trading_firm_id = 'OFP0046' then 'IMC_ATS'
            when imcw.Symbol is null then  'Exhaust_ATS'
            else dash.edw_billing_type
         end
   from billing.Dash_Trade_Record dash
   left outer join billing.imc_white_list imcw
      on dash.Symbol = imcw.Symbol
  --       dash.date_id >= to_char(imcw.StartDate, 'yyyymmdd')::int and
   --      (dash.date_id <= to_char(imcw.EndDate, 'yyyymmdd')::int or imcw.EndDate is null)
   where
      dash.id = dash1.id and
      dash.instrument_type_id = 'O' and
      lower(dash.billing_type) in ('exhaust', 'exhaust_imc') and
      lower(dash.edw_billing_type) not in ('imc_ats', 'exhaust_ats' ) and
      dash.trading_firm_id like 'OFP%' and
      dash.trading_firm_id <> 'OFP0046' and
      coalesce(dash.component_type, '') ='A' and
      dash.date_id between l_startdate_id and l_enddate_id and
     dash1.date_id between l_startdate_id and l_enddate_id ;

   select public.load_log(l_load_id, l_step_id, 'update Eedw_billing_type 6', 0, 'O')
   into l_step_id;

   --=== All Complex go to IMC first only crossed not ATS trades are SPI to Simplex
   update billing.dash_trade_record dash1
      set edw_billing_type =
         case when dash.component_type = 'A' then 'IMC_ATS' else 'IMC' end
   from billing.dash_trade_record dash
   left outer join billing.imc_white_list imcw on
      dash.symbol = imcw.symbol
 --     dash.date_id >= to_char(imcw.StartDate, 'yyyymmdd')::int and
--      (dash.date_id <= to_char(imcw.EndDate, 'yyyymmdd')::int or imcw.EndDate is null)
   where
      dash.date_id between l_startdate_id and l_enddate_id and
      dash1.date_id between l_startdate_id and l_enddate_id and
      dash.id = dash1.id and
      dash.instrument_type_id = 'O' and
      dash.multileg_reporting_type = '2' and
      dash.trading_firm_id like 'OFP%' and
      dash.date_id >= 20210301 and
      upper(dash.billing_type) = 'EXHAUST' and
      (dash.street_is_cross_order = 'N' or coalesce(dash.component_type, '') = 'A');

   select public.load_log(l_load_id, l_step_id, 'update Eedw_billing_type 7', 0, 'O')
   into l_step_id;

    update billing.dash_trade_record d
        set edw_billing_type = case
            when date_id >= 20230615 and d.symbol = any(l_array_1) then 'EXHAUST'
             when date_id >= 20230612 and d.symbol = any(l_array_2) then 'EXHAUST'
             when date_id >= 20230607 and d.symbol = any(l_array_3) then 'EXHAUST'
            when date_id >= 20230606 and d.symbol   = any(l_array_4) then 'EXHAUST_ATS'
            when date_id >= 20230605 and d.symbol  = any(l_array_5) then 'EXHAUST_ATS'
            when date_id >= 20230322 and d.symbol in ('CTRA', 'TOL', 'D', 'SSRM', 'BKR', 'PSTG', 'ENVX', 'RWM', 'RSP', 'LIT') then 'EXHAUST_ATS'
            when date_id >= 20230206 and date_id <= 20230321 and symbol in ('DUST', 'JDST', 'PAA', 'O', 'VOD') then 'EXHAUST_ATS'
	        when date_id >= 20221220 and date_id <= 20230321 and symbol in ('ASHR', 'YANG', 'YINN', 'ZIM', 'CS') then  'EXHAUST_ATS'
	        else 'IMC_ATS'
        end
    where
        date_id between l_startdate_id and l_enddate_id and
        coalesce(component_type, '') = 'A' and
        trading_firm_id = 'OFP0046' and
        edw_billing_type <> 'IMC_ATS';

   select public.load_log(l_load_id, l_step_id, 'update Eedw_billing_type 8', 0, 'O')
   into l_step_id;

    update billing.dash_trade_record d1
        set edw_billing_type = replace(d.edw_billing_type, 'IMC', 'Exhaust')
    from billing.cons_lite_202211 e
    inner join billing.dash_trade_record d ON
        replace(e.client_order_id, '"', '') = d.secondary_order_id and
        e.date_id = d.date_id::text
    where
        d.id = d1.id and
        e.date_id between l_startdate_id and l_enddate_id and
        d.date_id between l_startdate_id and l_enddate_id and
        d1.date_id between l_startdate_id and l_enddate_id and
        d.edw_billing_type like 'IMC%';

   select public.load_log(l_load_id, l_step_id, 'update Eedw_billing_type 9', 0, 'O')
   into l_step_id;

   select public.load_log(l_load_id, l_step_id, 'update_imc_billing_type COMPLETE', 1, 'O')
   into l_step_id;
end;
$procedure$
;
