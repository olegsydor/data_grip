CREATE TABLE public.banking_holiday_calendar
(
    banking_holiday_id      int8                   NOT NULL,
    banking_holiday_name    varchar(100)           NOT NULL,
    banking_holiday_date    date                   NOT NULL,
    banking_holiday_date_id int4                   NULL,
    is_active               bool      DEFAULT true NULL,
    date_start              timestamp DEFAULT now() NULL,
    date_end                timestamp              NULL
);
CREATE UNIQUE INDEX banking_holiday_calendar_pk ON public.banking_holiday_calendar USING btree (banking_holiday_id);
CREATE UNIQUE INDEX banking_holiday_calendar_unq ON public.banking_holiday_calendar USING btree (banking_holiday_date_id);


CREATE TABLE public.holiday_calendar
(
    holiday_id      int8                   NOT NULL,
    holiday_name    varchar(100)           NULL,
    holiday_date    date                   NULL,
    holiday_date_id int4                   NULL,
    is_active       bool      DEFAULT true NULL,
    date_start      timestamp DEFAULT now() NULL,
    date_end        timestamp              NULL,
    holiday_type    bpchar(1)              NULL
);
CREATE UNIQUE INDEX holiday_calendar_pk ON public.holiday_calendar USING btree (holiday_id);
CREATE UNIQUE INDEX holiday_calendar_unq ON public.holiday_calendar USING btree (holiday_date_id);



INSERT INTO public.banking_holiday_calendar (banking_holiday_id,banking_holiday_name,banking_holiday_date,banking_holiday_date_id,is_active,date_start,date_end) VALUES
	 (1,'Columbus Day','2011-10-10',20111010,true,'2011-10-10 00:00:00',NULL),
	 (2,'Veterans Day','2011-11-11',20111111,true,'2011-10-10 00:00:00',NULL),
	 (21,'Columbus Day','2012-10-08',20121008,true,'2011-10-10 00:00:00',NULL),
	 (22,'Veterans Day','2012-11-12',20121112,true,'2011-10-10 00:00:00',NULL),
	 (42,'Veterans Day','2013-11-11',20131111,true,'2011-10-10 00:00:00',NULL),
	 (43,'Columbus Day','2014-10-13',20141013,true,'2011-10-10 00:00:00',NULL),
	 (44,'Veterans Day','2014-11-11',20141111,true,'2011-10-10 00:00:00',NULL),
	 (45,'Columbus Day','2015-10-12',20151012,true,'2011-10-10 00:00:00',NULL),
	 (46,'Veterans Day','2015-11-11',20151111,true,'2011-10-10 00:00:00',NULL),
	 (47,'Columbus Day','2016-10-10',20161010,true,'2011-10-10 00:00:00',NULL),
	 (48,'Veterans Day','2016-11-11',20161111,true,'2011-10-10 00:00:00',NULL),
	 (49,'Columbus Day','2017-10-09',20171009,true,'2011-10-10 00:00:00',NULL),
	 (51,'Columbus Day','2018-10-08',20181008,true,'2011-10-10 00:00:00',NULL),
	 (52,'Veterans Day','2018-11-12',20181112,true,'2011-10-10 00:00:00',NULL),
	 (53,'Columbus Day','2019-10-14',20191014,true,'2011-10-10 00:00:00',NULL),
	 (54,'Veterans Day','2019-11-11',20191111,true,'2011-10-10 00:00:00',NULL),
	 (61,'Columbus Day','2021-10-11',20211011,true,'2020-10-28 20:00:06.219076',NULL),
	 (56,'Veterans Day','2020-11-11',20201111,true,'2011-10-10 00:00:00',NULL),
	 (57,'Columbus Day','2013-10-14',20131014,true,'2011-10-10 00:00:00',NULL),
	 (62,'Veterans Day','2021-11-11',20211111,true,'2020-10-28 20:00:06.219076',NULL),
	 (63,'Columbus Day','2022-10-10',20221010,true,'2020-10-28 20:00:06.219076',NULL),
	 (55,'Columbus Day','2020-10-12',20201012,true,'2011-10-10 00:00:00',NULL),
	 (64,'Veterans Day','2022-11-11',20221111,true,'2020-10-28 20:00:06.219076',NULL),
	 (82,'Veterans Day','2024-11-11',20241111,true,'2023-07-03 11:29:27.530275',NULL),
	 (83,'Veterans Day','2025-11-11',20251111,true,'2023-07-03 11:29:27.530275',NULL),
	 (84,'Veterans Day','2026-11-11',20261111,true,'2023-07-03 11:29:27.530275',NULL),
	 (85,'Columbus Day','2023-10-09',20231009,true,'2023-07-03 11:29:27.530275',NULL),
	 (86,'Columbus Day','2024-10-14',20241014,true,'2023-07-03 11:29:27.530275',NULL),
	 (87,'Columbus Day','2025-10-13',20251013,true,'2023-07-03 11:29:27.530275',NULL),
	 (88,'Columbus Day','2026-10-12',20261012,true,'2023-07-03 11:29:27.530275',NULL),
	 (81,'Veterans Day','2023-11-10',20231110,true,'2023-07-03 11:29:27.530275',NULL);

    select * from public.holiday_calendar
INSERT INTO public.holiday_calendar (holiday_id,holiday_name,holiday_date,holiday_date_id,is_active,date_start,date_end,holiday_type) VALUES
	 (80,'Memorial Day','2020-05-25',20200525,true,'2009-01-01 00:00:00',NULL,'U'),
	 (81,'Independence Day','2020-07-03',20200703,true,'2009-01-01 00:00:00',NULL,'U'),
	 (82,'Labor Day','2020-09-07',20200907,true,'2009-01-01 00:00:00',NULL,'U'),
	 (83,'Thanksgiving','2020-11-26',20201126,true,'2009-01-01 00:00:00',NULL,'U'),
	 (132,'Martin Luther King, Jr. Day ','2020-01-20',20200120,true,'2009-01-01 00:00:00',NULL,'U'),
	 (139,'Washington’s Birthday','2020-02-17',20200217,true,'2009-01-01 00:00:00',NULL,'U'),
	 (186,'Martin Luther King, Jr. Day','2021-01-18',20210118,true,'2020-10-28 20:00:05.846643',NULL,'U'),
	 (189,'Washington Birthday','2022-02-21',20220221,true,'2020-10-28 20:00:05.846643',NULL,'H'),
	 (188,'Washington Birthday','2021-02-15',20210215,true,'2020-10-28 20:00:05.846643',NULL,'U'),
	 (245,'New Years Day','2023-01-02',20230102,true,'2022-06-21 20:00:05.174358',NULL,'H'),
	 (193,'Memorial Day','2022-05-30',20220530,true,'2020-10-28 20:00:05.846643',NULL,'U'),
	 (194,'Independence Day','2021-07-05',20210705,true,'2020-10-28 20:00:05.846643',NULL,'U'),
	 (195,'Independence Day','2022-07-04',20220704,true,'2020-10-28 20:00:05.846643',NULL,'U'),
	 (196,'Labor Day','2021-09-06',20210906,true,'2020-10-28 20:00:05.846643',NULL,'U'),
	 (197,'Labor Day','2022-09-05',20220905,true,'2020-10-28 20:00:05.846643',NULL,'U'),
	 (199,'Thanksgiving Day','2022-11-24',20221124,true,'2020-10-28 20:00:05.846643',NULL,'U'),
	 (198,'Thanksgiving Day','2021-11-25',20211125,true,'2020-10-28 20:00:05.846643',NULL,'H'),
	 (225,'Juneteenth National Independence','2022-06-20',20220620,true,'2021-12-10 20:00:01.779398',NULL,'U'),
	 (226,'Christmas Day (Obs)','2022-12-26',20221226,true,'2021-12-10 20:00:01.779398',NULL,'H'),
	 (187,'Martin Luther King, Jr. Day','2022-01-17',20220117,true,'2020-10-28 20:00:05.846643',NULL,'H'),
	 (246,'Martin Luther King, Jr. Day','2023-01-16',20230116,true,'2022-06-21 20:00:05.174358',NULL,'U'),
	 (247,'Washingtons Birthday','2023-02-20',20230220,true,'2022-06-21 20:00:05.174358',NULL,'U'),
	 (248,'Good Friday','2023-04-07',20230407,true,'2022-06-21 20:00:05.174358',NULL,'H'),
	 (249,'Memorial Day','2023-05-29',20230529,true,'2022-06-21 20:00:05.174358',NULL,'U'),
	 (250,'Juneteenth National Independence','2023-06-19',20230619,true,'2022-06-21 20:00:05.174358',NULL,'U'),
	 (251,'Independence Day','2023-07-04',20230704,true,'2022-06-21 20:00:05.174358',NULL,'U'),
	 (265,'Labor Day','2023-09-04',20230904,true,'2023-07-03 11:29:27.188069',NULL,'U'),
	 (267,'Christmas Day','2023-12-25',20231225,true,'2023-07-03 11:29:27.188069',NULL,'H'),
	 (266,'Thanksgiving Day','2023-11-23',20231123,true,'2023-07-03 11:29:27.188069',NULL,'U'),
	 (268,'New Years Day','2024-01-01',20240101,true,'2023-07-03 20:00:04.740314',NULL,'H'),
	 (269,'Martin Luther King Jr Day','2024-01-15',20240115,true,'2023-07-03 20:00:04.740314',NULL,'U'),
	 (270,'Washington''s Birthday','2024-02-19',20240219,true,'2023-07-03 20:00:04.740314',NULL,'U'),
	 (271,'Good Friday','2024-03-29',20240329,true,'2023-07-03 20:00:04.740314',NULL,'H'),
	 (272,'Memorial Day','2024-05-27',20240527,true,'2023-07-03 20:00:04.740314',NULL,'U'),
	 (273,'Juneteenth','2024-06-19',20240619,true,'2023-07-03 20:00:04.740314',NULL,'U'),
	 (274,'Independence Day','2024-07-04',20240704,true,'2023-07-03 20:00:04.740314',NULL,'U'),
	 (275,'Labor Day','2024-09-02',20240902,true,'2023-07-03 20:00:04.740314',NULL,'U'),
	 (276,'Thanksgiving Day','2024-11-28',20241128,true,'2023-07-03 20:00:04.740314',NULL,'U'),
	 (277,'Christmas Day','2024-12-25',20241225,true,'2023-07-03 20:00:04.740314',NULL,'H'),
	 (278,'New Years Day','2025-01-01',20250101,true,'2023-07-03 20:00:04.740314',NULL,'H'),
	 (279,'Martin Luther King Jr Day','2025-01-20',20250120,true,'2023-07-03 20:00:04.740314',NULL,'U'),
	 (280,'Washington''s Birthday','2025-02-17',20250217,true,'2023-07-03 20:00:04.740314',NULL,'U'),
	 (281,'Good Friday','2025-04-18',20250418,true,'2023-07-03 20:00:04.740314',NULL,'H'),
	 (282,'Memorial Day','2025-05-26',20250526,true,'2023-07-03 20:00:04.740314',NULL,'U'),
	 (283,'Juneteenth','2025-06-19',20250619,true,'2023-07-03 20:00:04.740314',NULL,'U'),
	 (284,'Independence Day','2025-07-04',20250704,true,'2023-07-03 20:00:04.740314',NULL,'U'),
	 (285,'Labor Day','2025-09-01',20250901,true,'2023-07-03 20:00:04.740314',NULL,'U'),
	 (286,'Thanksgiving Day','2025-11-27',20251127,true,'2023-07-03 20:00:04.740314',NULL,'U'),
	 (287,'Christmas Day','2025-12-25',20251225,true,'2023-07-03 20:00:04.740314',NULL,'H'),
	 (288,'New Years Day','2026-01-01',20260101,true,'2023-07-03 20:00:04.740314',NULL,'H'),
	 (305,'Martin Luther King Jr Day','2026-01-19',20260119,true,'2024-01-02 20:00:05.437448',NULL,'U'),
	 (306,'Washington''s Birthday','2026-02-16',20260216,true,'2024-01-02 20:00:05.437448',NULL,'U'),
	 (307,'Good Friday','2026-04-03',20260403,true,'2024-01-02 20:00:05.437448',NULL,'H'),
	 (308,'Memorial Day','2026-05-25',20260525,true,'2024-01-02 20:00:05.437448',NULL,'U'),
	 (309,'Juneteenth','2026-06-19',20260619,true,'2024-01-02 20:00:05.437448',NULL,'U'),
	 (310,'Independence Day','2026-07-03',20260703,true,'2024-01-02 20:00:05.437448',NULL,'U'),
	 (311,'Labor Day','2026-09-07',20260907,true,'2024-01-02 20:00:05.437448',NULL,'U'),
	 (312,'Thanksgiving Day','2026-11-26',20261126,true,'2024-01-02 20:00:05.437448',NULL,'U'),
	 (313,'Christmas Day','2026-12-25',20261225,true,'2024-01-02 20:00:05.437448',NULL,'H'),
	 (78,'New Years Day','2020-01-01',20200101,true,'2009-01-01 00:00:00',NULL,NULL),
	 (79,'Good Friday','2020-04-10',20200410,true,'2009-01-01 00:00:00',NULL,NULL),
	 (84,'Christmas','2020-12-25',20201225,true,'2009-01-01 00:00:00',NULL,NULL),
	 (185,'New Years Day','2021-01-01',20210101,true,'2020-10-28 20:00:05.846643',NULL,NULL),
	 (190,'Good Friday','2021-04-02',20210402,true,'2020-10-28 20:00:05.846643',NULL,NULL),
	 (191,'Good Friday','2022-04-15',20220415,true,'2020-10-28 20:00:05.846643',NULL,NULL),
	 (205,'Christmas','2021-12-24',20211224,true,'2020-12-31 20:00:00.96065',NULL,'H'),
	 (1,'New Years Day','2009-01-01',20090101,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (2,'Good Friday','2009-04-10',20090410,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (3,'Memorial Day','2009-05-25',20090525,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (4,'Independence Day','2009-07-03',20090703,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (5,'Labor Day','2009-09-07',20090907,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (6,'Thanksgiving','2009-11-26',20091126,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (7,'Christmas','2009-12-25',20091225,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (8,'New Years Day','2010-01-01',20100101,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (9,'Good Friday','2010-04-02',20100402,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (10,'Memorial Day','2010-05-31',20100531,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (11,'Independence Day','2010-07-05',20100705,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (12,'Labor Day','2010-09-06',20100906,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (13,'Thanksgiving','2010-11-25',20101125,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (14,'Christmas','2010-12-24',20101224,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (15,'New Years Day','2010-12-31',20101231,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (16,'Good Friday','2011-04-22',20110422,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (17,'Memorial Day','2011-05-30',20110530,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (18,'Independence Day','2011-07-04',20110704,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (19,'Labor Day','2011-09-05',20110905,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (20,'Thanksgiving','2011-11-24',20111124,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (21,'Christmas','2011-12-26',20111226,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (22,'New Years Day','2012-01-02',20120102,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (23,'Good Friday','2012-04-06',20120406,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (24,'Memorial Day','2012-05-28',20120528,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (25,'Independence Day','2012-07-04',20120704,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (26,'Labor Day','2012-09-03',20120903,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (27,'Thanksgiving','2012-11-22',20121122,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (28,'Christmas','2012-12-25',20121225,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (29,'New Years Day','2013-01-01',20130101,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (30,'Good Friday','2013-03-29',20130329,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (31,'Memorial Day','2013-05-27',20130527,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (32,'Independence Day','2013-07-04',20130704,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (33,'Labor Day','2013-09-02',20130902,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (34,'Thanksgiving','2013-11-28',20131128,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL);
INSERT INTO public.holiday_calendar (holiday_id,holiday_name,holiday_date,holiday_date_id,is_active,date_start,date_end,holiday_type) VALUES
	 (35,'Christmas','2013-12-25',20131225,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (36,'New Years Day','2014-01-01',20140101,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (37,'Good Friday','2014-04-18',20140418,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (38,'Memorial Day','2014-05-26',20140526,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (39,'Independence Day','2014-07-04',20140704,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (40,'Labor Day','2014-09-01',20140901,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (41,'Thanksgiving','2014-11-27',20141127,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (42,'Christmas','2014-12-25',20141225,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (43,'New Years Day','2015-01-01',20150101,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (44,'Good Friday','2015-04-03',20150403,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (45,'Memorial Day','2015-05-25',20150525,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (46,'Independence Day','2015-07-03',20150703,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (47,'Labor Day','2015-09-07',20150907,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (48,'Thanksgiving','2015-11-26',20151126,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (49,'Christmas','2015-12-25',20151225,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (50,'New Years Day','2016-01-01',20160101,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (51,'Good Friday','2016-03-25',20160325,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (52,'Memorial Day','2016-05-30',20160530,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (53,'Independence Day','2016-07-04',20160704,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (54,'Labor Day','2016-09-05',20160905,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (55,'Thanksgiving','2016-11-24',20161124,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (56,'Christmas','2016-12-26',20161226,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (57,'New Years Day','2017-01-02',20170102,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (58,'Good Friday','2017-04-14',20170414,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (59,'Memorial Day','2017-05-29',20170529,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (60,'Independence Day','2017-07-04',20170704,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (61,'Labor Day','2017-09-04',20170904,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (62,'Thanksgiving','2017-11-23',20171123,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (63,'Christmas','2017-12-25',20171225,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (64,'New Years Day','2018-01-01',20180101,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (65,'Good Friday','2018-03-30',20180330,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (66,'Memorial Day','2018-05-28',20180528,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (67,'Independence Day','2018-07-04',20180704,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (68,'Labor Day','2018-09-03',20180903,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (69,'Thanksgiving','2018-11-22',20181122,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (70,'Christmas','2018-12-25',20181225,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (71,'New Years Day','2019-01-01',20190101,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (72,'Good Friday','2019-04-19',20190419,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (73,'Memorial Day','2019-05-27',20190527,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (74,'Independence Day','2019-07-04',20190704,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (75,'Labor Day','2019-09-02',20190902,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (76,'Thanksgiving','2019-11-28',20191128,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (77,'Christmas','2019-12-25',20191225,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (86,'Martin Luther King, Jr. Day','2012-01-16',20120116,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (87,'Washington’s Birthday/ Presidents Day','2012-02-20',20120220,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (105,'Martin Luther King, Jr. Day ','2013-01-21',20130121,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (125,'Washington’s Birthday','2013-02-18',20130218,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (126,'Martin Luther King, Jr. Day ','2014-01-20',20140120,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (127,'Martin Luther King, Jr. Day ','2015-01-19',20150119,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (128,'Martin Luther King, Jr. Day ','2016-01-18',20160118,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (129,'Martin Luther King, Jr. Day ','2017-01-16',20170116,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (130,'Martin Luther King, Jr. Day ','2018-01-15',20180115,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (131,'Martin Luther King, Jr. Day ','2019-01-21',20190121,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (133,'Washington’s Birthday','2014-02-17',20140217,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (192,'Memorial Day','2021-05-31',20210531,true,'2020-10-28 20:00:05.846643',NULL,'U'),
	 (134,'Washington’s Birthday','2015-02-16',20150216,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (135,'Washington’s Birthday','2016-02-15',20160215,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (136,'Washington’s Birthday','2017-02-20',20170220,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (137,'Washington’s Birthday','2018-02-19',20180219,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (138,'Washington’s Birthday','2019-02-18',20190218,false,'2009-01-01 00:00:00','2021-08-04 01:28:20',NULL),
	 (165,'National Day of Mourning','2018-12-05',20181205,false,'2018-12-05 06:47:19.091383','2021-08-04 01:28:20',NULL);


CREATE FUNCTION public.get_business_date(in_date date DEFAULT CURRENT_DATE, in_offset integer DEFAULT 0,
                                                    ignore_banking_holiday boolean DEFAULT true)
    RETURNS date
    LANGUAGE plpgsql
    IMMUTABLE
AS
$function$
begin
    return (SELECT generated.holiday_date AS workday
            FROM (SELECT generate_series(dday, dday + 8, interval '1d')::date AS holiday_date
                  FROM (SELECT in_date + in_offset AS dday) x) generated
                     LEFT JOIN public.holiday_calendar h on (generated.holiday_date = h.holiday_date and h.is_active)
                     LEFT JOIN public.banking_holiday_calendar bh on (generated.holiday_date = bh.banking_holiday_date)
            WHERE h.holiday_date IS null
              and (bh.banking_holiday_date is null or ignore_banking_holiday)
              AND extract(isodow from generated.holiday_date) < 6
            ORDER BY generated.holiday_date
            LIMIT 1);
end;
$function$
;


CREATE OR REPLACE FUNCTION public.get_dateid(period date)
    RETURNS integer
    LANGUAGE plpgsql
    IMMUTABLE
AS
$function$
begin
    return (select to_char(period, 'YYYYMMDD')::int as date_id);
end;
$function$
;


