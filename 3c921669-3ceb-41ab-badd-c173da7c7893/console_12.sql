with ind ("Exchange Name", "Trade Liq Ind", "Description", "DASH Liq Ind Type", "Harrys revised answers", exchange_id)
         as (
	 select 'PHLX','1','Add/Maker','','1','PHLX' from dual
 union all
	 select 'PHLX','10','Routed Out','','3','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','11','Trade Report','2','8','GMNIF' from dual
 union all
	 select 'PHLX','11','Trade Report','','8','PHLX' from dual
 union all
	 select 'NASDAQ Texas Options','11','Trade Report','2','8','NQBXO' from dual
 union all
	 select 'ISE Fusion','11','Trade Report','2','8','ISEF' from dual
 union all
	 select 'ISE Mercury Fusion','11','Trade Report','2','8','MCRYF' from dual
 union all
	 select 'PHLX','12','Combo Maker Against Combo','','1','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','12','Combo Maker Against Combo','','1','GMNIF' from dual
 union all
	 select 'PHLX','13','Combo Taker Against Combo','','2','PHLX' from dual
 union all
	 select 'PHLX','14','Combo Response Against Combo','','4','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','15','Combo Hidden Against Combo','4','8','GMNIF' from dual
 union all
	 select 'NASDAQ Texas Options','15','Combo Hidden Against Combo','4','8','NQBXO' from dual
 union all
	 select 'ISE Fusion','15','Combo Hidden Against Combo','4','8','ISEF' from dual
 union all
	 select 'ISE Mercury Fusion','15','Combo Hidden Against Combo','4','8','MCRYF' from dual
 union all
	 select 'PHLX','15','Combo Hidden Against Combo','','8','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','16','Combo Opening Rotation','4','8','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','16','Combo Opening Rotation','4','8','MCRYF' from dual
 union all
	 select 'NASDAQ Texas Options','16','Combo Opening Rotation','4','8','NQBXO' from dual
 union all
	 select 'ISE Fusion','16','Combo Opening Rotation','4','8','ISEF' from dual
 union all
	 select 'PHLX','16','Combo Opening Rotation','','8','PHLX' from dual
 union all
	 select 'ISE Mercury Fusion','17','Combo Cross','4','5','MCRYF' from dual
 union all
	 select 'NASDAQ Texas Options','17','Combo Cross','4','5','NQBXO' from dual
 union all
	 select 'ISE Fusion','17','Combo Cross','4','5','ISEF' from dual
 union all
	 select 'PHLX','17','Combo Cross','','5','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','17','Combo Cross','4','5','GMNIF' from dual
 union all
	 select 'PHLX','18','Combo Taker Against Regular','','2','PHLX' from dual
 union all
	 select 'PHLX','19','Regular Maker Against Combo','','1','PHLX' from dual
 union all
	 select 'PHLX','20','Combo Taker Against IO','','2','PHLX' from dual
 union all
	 select 'PHLX','21','Regular Taker Against IO (incl. PIM)','','2','PHLX' from dual
 union all
	 select 'PHLX','22','IO Maker Against Combo','','1','PHLX' from dual
 union all
	 select 'PHLX','23','IO Maker Against Regular','','1','PHLX' from dual
 union all
	 select 'PHLX','24','Regular Maker Against IO Participant','','1','PHLX' from dual
 union all
	 select 'PHLX','25','IO Participant Taker Against Regular','','2','PHLX' from dual
 union all
	 select 'NASDAQ Texas Options','26','Broken Price Improvements','4','5','NQBXO' from dual
 union all
	 select 'PHLX','26','Broken Price Improvement§§','','5','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','26','Broken Price Improvement','4','5','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','26','Broken Price Improvement','4','5','MCRYF' from dual
 union all
	 select 'ISE Fusion','26','Broken Price Improvement','4','5','ISEF' from dual
 union all
	 select 'ISE Mercury Fusion','27','Broken Facilitation','4','5','MCRYF' from dual
 union all
	 select 'ISE Fusion','27','Broken Facilitation','4','5','ISEF' from dual
 union all
	 select 'NASDAQ Texas Options','27','Broken Facilitation','4','5','NQBXO' from dual
 union all
	 select 'PHLX','27','Broken Facilitation','','5','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','27','Broken Facilitation','4','5','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','28','Broken Solicitation','4','5','MCRYF' from dual
 union all
	 select 'ISE Fusion','28','Broken Solicitation','4','5','ISEF' from dual
 union all
	 select 'PHLX','28','Broken Solicitation','','5','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','28','Broken Solicitation','4','5','GMNIF' from dual
 union all
	 select 'NASDAQ Texas Options','28','Broken Solicitation','4','5','NQBXO' from dual
 union all
	 select 'NASDAQ Texas Options','29','Combo Broken Price Improvement','4','5','NQBXO' from dual
 union all
	 select 'ISE Gemini Fusion','29','Combo Broken Price Improvement','4','5','GMNIF' from dual
 union all
	 select 'PHLX','29','Combo Broken Price Improvement','','5','PHLX' from dual
 union all
	 select 'ISE Fusion','29','Combo Broken Price Improvement','4','5','ISEF' from dual
 union all
	 select 'ISE Mercury Fusion','29','Combo Broken Price Improvement','4','5','MCRYF' from dual
 union all
	 select 'PHLX','30','Combo Broken Facilitation','','5','PHLX' from dual
 union all
	 select 'NASDAQ Texas Options','30','Combo Broken Facilitation','4','5','NQBXO' from dual
 union all
	 select 'ISE Gemini Fusion','30','Combo Broken Facilitation','4','5','GMNIF' from dual
 union all
	 select 'ISE Fusion','30','Combo Broken Facilitation','4','5','ISEF' from dual
 union all
	 select 'ISE Mercury Fusion','30','Combo Broken Facilitation','4','5','MCRYF' from dual
 union all
	 select 'PHLX','31','Combo Broken Solicitation','','5','PHLX' from dual
 union all
	 select 'NASDAQ Texas Options','31','Combo Broken Solicitation','4','5','NQBXO' from dual
 union all
	 select 'ISE Mercury Fusion','31','Combo Broken Solicitation','4','5','MCRYF' from dual
 union all
	 select 'ISE Gemini Fusion','31','Combo Broken Solicitation','4','5','GMNIF' from dual
 union all
	 select 'ISE Fusion','31','Combo Broken Solicitation','4','5','ISEF' from dual
 union all
	 select 'PHLX','32','Block','','4','PHLX' from dual
 union all
	 select 'PHLX','33','Block Response','','4','PHLX' from dual
 union all
	 select 'PHLX','34','Directed Response','','8','PHLX' from dual
 union all
	 select 'NASDAQ Texas Options','34','Directed Response','','8','NQBXO' from dual
 union all
	 select 'ISE Fusion','34','Directed Response','','8','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','34','Directed Response','','8','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','34','Directed Response','','8','MCRYF' from dual
 union all
	 select 'ISE Mercury Fusion','35','Facilitation','4','5','MCRYF' from dual
 union all
	 select 'PHLX','35','Facilitation','','5','PHLX' from dual
 union all
	 select 'ISE Fusion','35','Facilitation','4','5','ISEF' from dual
 union all
	 select 'NASDAQ Texas Options','35','Facilitation','4','5','NQBXO' from dual
 union all
	 select 'ISE Gemini Fusion','35','Facilitation','4','5','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','36','Facilitation Response','4','5','MCRYF' from dual
 union all
	 select 'ISE Gemini Fusion','36','Facilitation Response','4','5','GMNIF' from dual
 union all
	 select 'NASDAQ Texas Options','36','Facilitation Response','4','5','NQBXO' from dual
 union all
	 select 'ISE Fusion','36','Facilitation Response','4','5','ISEF' from dual
 union all
	 select 'PHLX','36','Facilitation Response','','5','PHLX' from dual
 union all
	 select 'NASDAQ Texas Options','37','Price Improvement','1','5','NQBXO' from dual
 union all
	 select 'ISE Gemini Fusion','37','Price Improvement','1','5','GMNIF' from dual
 union all
	 select 'ISE Fusion','37','Price Improvement','1','5','ISEF' from dual
 union all
	 select 'PHLX','37','Price Improvement','','5','PHLX' from dual
 union all
	 select 'ISE Mercury Fusion','37','Price Improvement','1','5','MCRYF' from dual
 union all
	 select 'ISE Mercury Fusion','38','Price improvement Response','1','5','MCRYF' from dual
 union all
	 select 'NASDAQ Texas Options','38','Price Improvement Response','1','5','NQBXO' from dual
 union all
	 select 'ISE Gemini Fusion','38','Price improvement Response','1','5','GMNIF' from dual
 union all
	 select 'ISE Fusion','38','Price improvement Response','1','5','ISEF' from dual
 union all
	 select 'PHLX','38','Price improvement Response','','5','PHLX' from dual
 union all
	 select 'NASDAQ Texas Options','39','Solicitation','4','5','NQBXO' from dual
 union all
	 select 'ISE Gemini Fusion','39','Solicitation','4','5','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','39','Solicitation','4','5','MCRYF' from dual
 union all
	 select 'PHLX','39','Solicitation','','5','PHLX' from dual
 union all
	 select 'ISE Fusion','39','Solicitation','4','5','ISEF' from dual
 union all
	 select 'NASDAQ Texas Options','4','Response','2','4','NQBXO' from dual
 union all
	 select 'ISE Gemini Fusion','4','Response','2','4','GMNIF' from dual
 union all
	 select 'PHLX','4','Response','','4','PHLX' from dual
 union all
	 select 'ISE Fusion','4','Response','2','4','ISEF' from dual
 union all
	 select 'ISE Mercury Fusion','4','Response','2','4','MCRYF' from dual
 union all
	 select 'PHLX','40','Solicitation Response','','5','PHLX' from dual
 union all
	 select 'ISE Mercury Fusion','40','Solicitation Response','4','5','MCRYF' from dual
 union all
	 select 'ISE Fusion','40','Solicitation Response','4','5','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','40','Solicitation Response','4','5','GMNIF' from dual
 union all
	 select 'NASDAQ Texas Options','40','Solicitation Response','4','5','NQBXO' from dual
 union all
	 select 'PHLX','41','Qualified Contingent Cross','','5','PHLX' from dual
 union all
	 select 'ISE Fusion','41','Qualified Contingent Cross','4','5','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','41','Qualified Contingent Cross','4','5','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','41','Qualified Contingent Cross','4','5','MCRYF' from dual
 union all
	 select 'NASDAQ Texas Options','41','Qualified Contingent Cross','4','5','NQBXO' from dual
 union all
	 select 'NASDAQ Texas Options','42','Customer to Customer','4','5','NQBXO' from dual
 union all
	 select 'ISE Mercury Fusion','42','Customer to Customer','4','5','MCRYF' from dual
 union all
	 select 'ISE Gemini Fusion','42','Customer to Customer','4','5','GMNIF' from dual
 union all
	 select 'PHLX','42','Customer to Customer','','5','PHLX' from dual
 union all
	 select 'ISE Fusion','42','Customer to Customer','4','5','ISEF' from dual
 union all
	 select 'ISE Fusion','43','Combo Facilitation','4','5','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','43','Combo Facilitation','4','5','GMNIF' from dual
 union all
	 select 'NASDAQ Texas Options','43','Combo Facilitation','4','5','NQBXO' from dual
 union all
	 select 'PHLX','43','Combo Facilitation','','5','PHLX' from dual
 union all
	 select 'ISE Mercury Fusion','43','Combo Facilitation','4','5','MCRYF' from dual
 union all
	 select 'NASDAQ Texas Options','44','Combo Facilitation Response','4','5','NQBXO' from dual
 union all
	 select 'ISE Fusion','44','Combo Facilitation Response','4','5','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','44','Combo Facilitation Response','4','5','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','44','Combo Facilitation Response','4','5','MCRYF' from dual
 union all
	 select 'PHLX','44','Combo Facilitation Response','','5','PHLX' from dual
 union all
	 select 'PHLX','45','Combo Price Improvement','','5','PHLX' from dual
 union all
	 select 'ISE Fusion','45','Combo Price Improvement','','5','ISEF' from dual
 union all
	 select 'NASDAQ Texas Options','45','Combo Price Improvement','','5','NQBXO' from dual
 union all
	 select 'ISE Gemini Fusion','45','Combo Price Improvement','','5','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','45','Combo Price Improvement','1','5','MCRYF' from dual
 union all
	 select 'PHLX','46','Combo Price Improvement Response','','5','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','46','Combo Price Improvement Response','','5','GMNIF' from dual
 union all
	 select 'ISE Fusion','46','Combo Price Improvement Response','','5','ISEF' from dual
 union all
	 select 'NASDAQ Texas Options','46','Combo Price Improvement Response','','5','NQBXO' from dual
 union all
	 select 'ISE Mercury Fusion','46','Combo Price Improvement Response','1','5','MCRYF' from dual
 union all
	 select 'ISE Mercury Fusion','47','Combo Solicitation','4','5','MCRYF' from dual
 union all
	 select 'NASDAQ Texas Options','47','Combo Solicitation','','5','NQBXO' from dual
 union all
	 select 'PHLX','47','Combo Solicitation','','5','PHLX' from dual
 union all
	 select 'ISE Fusion','47','Combo Solicitation','4','5','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','47','Combo Solicitation','','5','GMNIF' from dual
 union all
	 select 'ISE Fusion','48','Combo Solicitation Response','4','5','ISEF' from dual
 union all
	 select 'NASDAQ Texas Options','48','Combo Solicitation Response','4','5','NQBXO' from dual
 union all
	 select 'PHLX','48','Combo Solicitation Response','','5','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','48','Combo Solicitation Response','4','5','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','48','Combo Solicitation Response','4','5','MCRYF' from dual
 union all
	 select 'ISE Mercury Fusion','49','Combo Qualified Contingent Cross','4','5','MCRYF' from dual
 union all
	 select 'PHLX','49','Combo Qualified Contingent Cross','','5','PHLX' from dual
 union all
	 select 'ISE Fusion','49','Combo Qualified Contingent Cross','4','5','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','49','Combo Qualified Contingent Cross','4','5','GMNIF' from dual
 union all
	 select 'NASDAQ Texas Options','49','Combo Qualified Contingent Cross','4','5','NQBXO' from dual
 union all
	 select 'ISE Mercury Fusion','5','Hidden','2','8','MCRYF' from dual
 union all
	 select 'PHLX','5','Hidden','','8','PHLX' from dual
 union all
	 select 'NASDAQ Texas Options','5','Hidden','2','8','NQBXO' from dual
 union all
	 select 'ISE Fusion','5','Hidden','2','8','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','5','Hidden','2','8','GMNIF' from dual
 union all
	 select 'ISE Fusion','50','Combo Customer to Customer','4','5','ISEF' from dual
 union all
	 select 'PHLX','50','Combo Customer to Customer','','5','PHLX' from dual
 union all
	 select 'NASDAQ Texas Options','50','Combo Customer to Customer','4','5','NQBXO' from dual
 union all
	 select 'ISE Mercury Fusion','50','Combo Customer to Customer','4','5','MCRYF' from dual
 union all
	 select 'ISE Gemini Fusion','50','Combo Customer to Customer','4','5','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','51','Sweep Routed Out','2','3','MCRYF' from dual
 union all
	 select 'ISE Fusion','51','Sweep Routed Out','2','3','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','51','Sweep Routed Out','2','3','GMNIF' from dual
 union all
	 select 'NASDAQ Texas Options','51','Sweep Routed Out','2','3','NQBXO' from dual
 union all
	 select 'PHLX','51','Sweep Routed Out','','3','PHLX' from dual
 union all
	 select 'PHLX','52','Sweep Trade Report','','2','PHLX' from dual
 union all
	 select 'PHLX','53','Combo Taker Against Regular – Thru NBBO','','2','PHLX' from dual
 union all
	 select 'PHLX','54','Combo Taker Against IO – Thru NBBO','','2','PHLX' from dual
 union all
	 select 'PHLX','55','Simple Exposure Order – Upon Receipt','','4','PHLX' from dual
 union all
	 select 'PHLX','56','Simple Exposure Order – Subsequent','','4','PHLX' from dual
 union all
	 select 'PHLX','57','Simple Exposure Order – Responder','','4','PHLX' from dual
 union all
	 select 'ISE Fusion','58','Flex Auction','','4','ISEF' from dual
 union all
	 select 'PHLX','58','Flex Auction','','4','PHLX' from dual
 union all
	 select 'ISE Mercury Fusion','58','Flex Auction','','4','MCRYF' from dual
 union all
	 select 'ISE Gemini Fusion','58','Flex Auction','','4','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','59','Flex Auction Responder','','8','MCRYF' from dual
 union all
	 select 'ISE Fusion','59','Flex Auction Responder','','8','ISEF' from dual
 union all
	 select 'PHLX','59','Flex Auction Responder','','8','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','59','Flex Auction Responder','','8','GMNIF' from dual
 union all
	 select 'NASDAQ Texas Options','6','Opening','','8','NQBXO' from dual
 union all
	 select 'PHLX','6','Opening','','8','PHLX' from dual
 union all
	 select 'ISE Mercury Fusion','6','Opening','1','8','MCRYF' from dual
 union all
	 select 'ISE Fusion','6','Opening','4','8','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','6','Opening','4','8','GMNIF' from dual
 union all
	 select 'PHLX','60','Flex Price Improvement','','5','PHLX' from dual
 union all
	 select 'ISE Mercury Fusion','60','Flex Price Improvement','','5','MCRYF' from dual
 union all
	 select 'ISE Fusion','60','Flex Price Improvement','','5','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','60','Flex Price Improvement','','5','GMNIF' from dual
 union all
	 select 'ISE Fusion','61','Flex Price Improvement Responder','','5','ISEF' from dual
 union all
	 select 'ISE Mercury Fusion','61','Flex Price Improvement Responder','','5','MCRYF' from dual
 union all
	 select 'ISE Gemini Fusion','61','Flex Price Improvement Responder','','5','GMNIF' from dual
 union all
	 select 'PHLX','61','Flex Price Improvement Responder','','5','PHLX' from dual
 union all
	 select 'ISE Fusion','62','Flex Broken Price Improvement','','5','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','62','Flex Broken Price Improvement','','5','GMNIF' from dual
 union all
	 select 'PHLX','62','Flex Broken Price Improvement','','5','PHLX' from dual
 union all
	 select 'ISE Mercury Fusion','62','Flex Broken Price Improvement','','5','MCRYF' from dual
 union all
	 select 'ISE Mercury Fusion','63','Flex Solicitation','','5','MCRYF' from dual
 union all
	 select 'ISE Fusion','63','Flex Solicitation','','5','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','63','Flex Solicitation','','5','GMNIF' from dual
 union all
	 select 'PHLX','63','Flex Solicitation','','5','PHLX' from dual
 union all
	 select 'ISE Fusion','64','Flex Solicitation Responder','','5','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','64','Flex Solicitation Responder','','5','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','64','Flex Solicitation Responder','','5','MCRYF' from dual
 union all
	 select 'PHLX','64','Flex Solicitation Responder','','5','PHLX' from dual
 union all
	 select 'ISE Mercury Fusion','65','Flex Broken Solicitation','','5','MCRYF' from dual
 union all
	 select 'PHLX','65','Flex Broken Solicitation','','5','PHLX' from dual
 union all
	 select 'ISE Fusion','65','Flex Broken Solicitation','','5','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','65','Flex Broker Soliciation','','5','GMNIF' from dual
 union all
	 select 'PHLX','66','Combo Flex Auction','','4','PHLX' from dual
 union all
	 select 'ISE Mercury Fusion','66','Combo Flex Auction','','4','MCRYF' from dual
 union all
	 select 'ISE Gemini Fusion','66','Combo Flex Auction','','4','GMNIF' from dual
 union all
	 select 'ISE Fusion','66','Combo Flex Auction','','4','ISEF' from dual
 union all
	 select 'ISE Fusion','67','Combo Flex Auction Responder','','8','ISEF' from dual
 union all
	 select 'PHLX','67','Combo Flex Auction Responder','','8','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','67','Combo Flex Auction Responder','','8','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','67','Combo Flex Auction Responder','','8','MCRYF' from dual
 union all
	 select 'ISE Mercury Fusion','68','Combo Flex Price Improvement','','5','MCRYF' from dual
 union all
	 select 'ISE Gemini Fusion','68','Combo Flex Price Improvement','','5','GMNIF' from dual
 union all
	 select 'ISE Fusion','68','Combo Flex Price Improvement','','5','ISEF' from dual
 union all
	 select 'PHLX','68','Combo Flex Price Improvement','','5','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','69','Combo Flex Price Improvement Responder','','5','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','69','Combo Flex Price Improvement Responder','','5','MCRYF' from dual
 union all
	 select 'ISE Fusion','69','Combo Flex Price Improvement Responder','','5','ISEF' from dual
 union all
	 select 'PHLX','69','Combo Flex Price Improvement Responder','','5','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','7','Cross','4','5','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','7','Cross','4','5','MCRYF' from dual
 union all
	 select 'ISE Fusion','7','Cross','4','5','ISEF' from dual
 union all
	 select 'NASDAQ Texas Options','7','Cross','4','5','NQBXO' from dual
 union all
	 select 'PHLX','7','Cross','','5','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','70','Combo Flex Broken Price Improvement','','5','GMNIF' from dual
 union all
	 select 'PHLX','70','Combo Flex Broken Price Improvement','','5','PHLX' from dual
 union all
	 select 'ISE Fusion','70','Combo Flex Broken Price Improvement Responder','','5','ISEF' from dual
 union all
	 select 'ISE Mercury Fusion','70','Combo Flex Broken Price Improvement','','5','MCRYF' from dual
 union all
	 select 'ISE Gemini Fusion','71','Combo Flex Solicitation','','5','GMNIF' from dual
 union all
	 select 'ISE Fusion','71','Combo Flex Solicitation','','5','ISEF' from dual
 union all
	 select 'PHLX','71','Combo Flex Solicitation','','5','PHLX' from dual
 union all
	 select 'ISE Mercury Fusion','71','Combo Flex Solicitation','','5','MCRYF' from dual
 union all
	 select 'ISE Fusion','72','Combo Flex Solicitation Responder','','5','ISEF' from dual
 union all
	 select 'PHLX','72','Combo Flex Solicitation Responder','','5','PHLX' from dual
 union all
	 select 'ISE Mercury Fusion','72','Combo Flex Solicitation Responder','','5','MCRYF' from dual
 union all
	 select 'ISE Gemini Fusion','72','Combo Flex Solicitation Responder','','5','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','73','Combo Flex Broken Solicitation','','5','MCRYF' from dual
 union all
	 select 'ISE Fusion','73','Combo Flex Broken Solicitation','','5','ISEF' from dual
 union all
	 select 'PHLX','73','Combo Flex Broken Solicitation','','5','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','73','Combo Flex Broker Solicitation','','5','GMNIF' from dual
 union all
	 select 'PHLX','8','Flashed Order','','4','PHLX' from dual
 union all
	 select 'PHLX','9','Flash Response','','4','PHLX' from dual
 union all
	 select 'CBOE','B1','Customer, CBTX','4','8','CBOE' from dual
 union all
	 select 'CBOE','B2','Non-Customer, Manual, CBTX','4','6','CBOE' from dual
 union all
	 select 'EDGX Options','BA','AIM Agency (Non-Customer)','4','5','EDGO' from dual
 union all
	 select 'CBOE','BA','Broker-Dealer, Away Market-Maker, Manual','','6','CBOE' from dual
 union all
	 select 'CBOE','BB','Non-Customer, Non-Market-Maker, Non-Firm, Electronic, Penny','','8','CBOE' from dual
 union all
	 select 'EDGX Options','BB','AIM Contra, Penny','4','5','EDGO' from dual
 union all
	 select 'BATS Options','BC','"Adds or removes liquidity (Customer), RUT	"','4','8','BATO' from dual
 union all
	 select 'C2','BC','Public Customer ','4','8','C2OX' from dual
 union all
	 select 'CBOE','BC','Non-Customer, Non-Market-Maker, Non-Firm, Electronic, Non-Penny','','8','CBOE' from dual
 union all
	 select 'EDGX Options','BC','AIM Agency (Customer), Penny','4','5','EDGO' from dual
 union all
	 select 'EDGX Options','BD','AIM Response, Penny','4','5','EDGO' from dual
 union all
	 select 'CBOE','BD','Non-Customer, Non-Market-Maker, Non-Firm, AIM Agency','','5','CBOE' from dual
 union all
	 select 'CBOE','BE','Non-Customer, Non-Market-Maker, Non-Firm, Sector Indexes','','8','CBOE' from dual
 union all
	 select 'EDGX Options','BE','AIM Response, Non-Penny','4','5','EDGO' from dual
 union all
	 select 'EDGX Options','BF','AIM Contra, Non-Penny','4','5','EDGO' from dual
 union all
	 select 'CBOE','BG','Non-Customer, Non-Market-Maker, Non-Firm, MXACW, MXUSA, MXWLD','4','8','CBOE' from dual
 union all
	 select 'EDGX Options','BG','AIM Agency (Customer), Non-Penny','4','5','EDGO' from dual
 union all
	 select 'CBOE','BK','Non-Customer, Non-Market-Maker, Non-Firm, Electronic, Non-AIM, RUT Family','','8','CBOE' from dual
 union all
	 select 'BATS Options','BM','"Adds or removes liquidity (MM), RUT	"','4','8','BATO' from dual
 union all
	 select 'CBOE','BM','Non-Customer, Non-MarketMaker, Non-Firm, MRUT','4','8','CBOE' from dual
 union all
	 select 'C2','BM','C2 Market Maker ','4','8','C2OX' from dual
 union all
	 select 'C2','BN','All Non-Customer','4','8','C2OX' from dual
 union all
	 select 'BATS Options','BN','"Adds or removes liquidity (Non-Customer/Non-MM), RUT	"','4','8','BATO' from dual
 union all
	 select 'BATS Options','BO','"Trades on the Open, RUT	"','4','8','BATO' from dual
 union all
	 select 'CBOE','BR','Non-Customer, Non-Market-Maker, Non-Firm, OEX, XEO and VIX','','8','CBOE' from dual
 union all
	 select 'CBOE','BS','Non-Customer, Non-Market-Maker, Non-Firm, Manual, AIM, RUT Family','','5','CBOE' from dual
 union all
	 select 'CBOE','BT','Non-Customer, Non-Market-Maker, Non-Firm, SPX, SPESG','','8','CBOE' from dual
 union all
	 select 'C2','CA','Resting Simple Order Trades with Resting Complex Order','4','8','C2OX' from dual
 union all
	 select 'CBOE','CB','Customer, Index','','8','CBOE' from dual
 union all
	 select 'EDGX Options','CC','"AIM Customer-to-Customer Immediate Cross	"','4','5','EDGO' from dual
 union all
	 select 'CBOE','CC','Customer, XSP, >=10 contracts','','8','CBOE' from dual
 union all
	 select 'CBOE','CE','Customer, Adds liquidity, ETF','','1','CBOE' from dual
 union all
	 select 'CBOE','CG','Customer, MXACW, MXUSA, MXWLD','4','8','CBOE' from dual
 union all
	 select 'CBOE','CI','Customer, ProCustomer, Combo portion of an index combo order execution, VIX','4','8','CBOE' from dual
 union all
	 select 'CBOE','CK','Customer, Equity, ETF','','8','CBOE' from dual
 union all
	 select 'CBOE','CM','Customer, MXEA','','8','CBOE' from dual
 union all
	 select 'CBOE','CN','Customer, MXEF','','8','CBOE' from dual
 union all
	 select 'CBOE','CO','Customer, OEX, XEO','','8','CBOE' from dual
 union all
	 select 'CBOE','CP','Customer, Sector Indexes','','8','CBOE' from dual
 union all
	 select 'CBOE','CQ','Customer, MRUT','4','8','CBOE' from dual
 union all
	 select 'CBOE','CR','Customer, RUT family ','','8','CBOE' from dual
 union all
	 select 'CBOE','CS','Customer, Premium <$1.00, SPX, SPESG','','8','CBOE' from dual
 union all
	 select 'C2','CT','Resting Complex Orders Trades with Resting Simple Order','4','8','C2OX' from dual
 union all
	 select 'CBOE','CT','Customer, Premimum >=$1.00, SPX, SPESG','','8','CBOE' from dual
 union all
	 select 'CBOE','CV','Customer, Premium $0.00-$0.10, VIX, Simple','','8','CBOE' from dual
 union all
	 select 'CBOE','CW','Customer, Premium $0.11-$0.99, VIX, Simple','','8','CBOE' from dual
 union all
	 select 'CBOE','CX','Customer, Premium $1.00-$1.99, VIX, Simple ','','8','CBOE' from dual
 union all
	 select 'CBOE','CY','Customer, Premium >=$2.00, VIX, Simple','','8','CBOE' from dual
 union all
	 select 'CBOE','CZ','Customer, Premium $0.00-$0.10, VIX, Complex','','8','CBOE' from dual
 union all
	 select 'CBOE','DA','Customer, Premium, $0.11-$0.99, VIX, Complex','','8','CBOE' from dual
 union all
	 select 'CBOE','DB','Customer,Premium $1.00-$1.99, VIX, Complex','','8','CBOE' from dual
 union all
	 select 'C2','DC','Public Customer - DJX','4','8','C2OX' from dual
 union all
	 select 'CBOE','DC','Customer, Premium >=$2.00, VIX, Complex','','8','CBOE' from dual
 union all
	 select 'C2','DM','C2 Market Maker - DJX','4','8','C2OX' from dual
 union all
	 select 'C2','DN','All Non-Customer - DJX','4','8','C2OX' from dual
 union all
	 select 'C2','DO','"Trades at the Open - DJX	"','4','8','C2OX' from dual
 union all
	 select 'CBOE','E1','SPEQX, Customer','4','8','CBOE' from dual
 union all
	 select 'CBOE','E2','SPEQX, Non-Customer','4','8','CBOE' from dual
 union all
	 select 'EDGX Options','EF','Equity Leg - FOG','4','8','EDGO' from dual
 union all
	 select 'CBOE','EF','Equity Leg - FOG','4','8','CBOE' from dual
 union all
	 select 'CBOE','EL','Equity Leg - Libucki','4','8','CBOE' from dual
 union all
	 select 'EDGX Options','EL','Equity Leg - Libucki','4','8','EDGO' from dual
 union all
	 select 'CBOE','EP','Equity Leg - Penserra','4','8','CBOE' from dual
 union all
	 select 'EDGX Options','EP','Equity Leg - Penserra','4','8','EDGO' from dual
 union all
	 select 'EDGX Options','EQ','Equity Leg - Cowen (capped at $50/execution)','','8','EDGO' from dual
 union all
	 select 'CBOE','EQ','Equity Leg - Cowen (capped at $50/execution)','','8','CBOE' from dual
 union all
	 select 'EDGX Options','ES','Equity Leg - SRT','4','8','EDGO' from dual
 union all
	 select 'CBOE','ES','Equity Leg - SRT','4','8','CBOE' from dual
 union all
	 select 'CBOE','FA','Firm, Manual','','6','CBOE' from dual
 union all
	 select 'CBOE','FB','Firm, Electronic, Penny','','8','CBOE' from dual
 union all
	 select 'CBOE','FC','Firm, Electronic, Non-Penny','','8','CBOE' from dual
 union all
	 select 'CBOE','FD','Firm, AIM Agency ','','5','CBOE' from dual
 union all
	 select 'CBOE','FF','Firm Facilitation','4','5','CBOE' from dual
 union all
	 select 'CBOE','FG','Firm, MXACW, MXUSA, MXWLD','4','8','CBOE' from dual
 union all
	 select 'CBOE','FH','Firm, Underlying Symbol List A','','8','CBOE' from dual
 union all
	 select 'CBOE','FI','Firm, Sector Indexes','','8','CBOE' from dual
 union all
	 select 'CBOE','FK','Firm, VIX','','8','CBOE' from dual
 union all
	 select 'CBOE','FM','Firm, MRUT','4','8','CBOE' from dual
 union all
	 select 'CBOE','FS','Non-Customer, Manual, Merger, Short Stock Interest, Reversal, Conversion and Jelly Roll Strategies, Equity, ETF','4','6','CBOE' from dual
 union all
	 select 'CBOE','GA','Customer, Market-Maker, Firm, RUT, Flex Micro','4','8','CBOE' from dual
 union all
	 select 'CBOE','GB','Non-Customer, Non-Market-Maker, Non-Firm, Manual, AIM, RUT, Flex Micro','4','5','CBOE' from dual
 union all
	 select 'CBOE','GC','Non-Customer, Non-Market-Maker, Non-Firm, Electronic, Non-AIM, RUT, Flex Micro','4','8','CBOE' from dual
 union all
	 select 'CBOE','GD','Non-Customer, Non-Market-Maker, Non-Firm, SPX, Flex Micro','4','8','CBOE' from dual
 union all
	 select 'CBOE','GE','Customer, Firm, SPX, Flex Micro','4','8','CBOE' from dual
 union all
	 select 'CBOE','GF','Market-Maker, SPX, Flex Micro','4','8','CBOE' from dual
 union all
	 select 'CBOE','GG','Customer, MXEA, MXEF, DJX, Flex Micro','4','8','CBOE' from dual
 union all
	 select 'CBOE','GH','Market-Maker, MXEA, MXEF, DJX, Flex Micro','4','8','CBOE' from dual
 union all
	 select 'CBOE','GI','Non-Customer, Non-Market-Maker, MXEA, MXEF, Electronic, Flex Micro','4','8','CBOE' from dual
 union all
	 select 'CBOE','GJ','Non-Customer, Non-Market-Maker, DJX, Electronic, Flex Micro','4','8','CBOE' from dual
 union all
	 select 'CBOE','GK','Non-Customer, Non-Market-Maker, MXEA, MXEF, DJX, Manual, AIM Agency, Flex Micro','4','5','CBOE' from dual
 union all
	 select 'CBOE','GL','Non-Customer, MXEA, MXEF, DJX, AIM Contra, Flex Micro','4','5','CBOE' from dual
 union all
	 select 'CBOE','GM','Non-Customer, DJX, AIM Response, Flex Micro','4','5','CBOE' from dual
 union all
	 select 'CBOE','GN','Non-Customer, MXEA, MXEF, AIM Response, Flex Micro','4','5','CBOE' from dual
 union all
	 select 'CBOE','M1','Customer, MBTX','4','8','CBOE' from dual
 union all
	 select 'CBOE','M2','Non-Customer, MBTX','4','8','CBOE' from dual
 union all
	 select 'CBOE','MA','Market-Maker, Electronic','','8','CBOE' from dual
 union all
	 select 'CBOE','MB','Market-Maker, Manual','4','6','CBOE' from dual
 union all
	 select 'CBOE','MC','Market Maker, Electronic, Contra Customer, XSP, MRUT, DJX','4','8','CBOE' from dual
 union all
	 select 'CBOE','MD','Market-Maker, AIM Responder','4','5','CBOE' from dual
 union all
	 select 'CBOE','MG','Market-Maker, MXACW, MXUSA, MXWLD','4','8','CBOE' from dual
 union all
	 select 'CBOE','MI','Market-Maker, VIX, Contra Order Quantity >=5000 Contracts, >=3 Legs, Manual','4','6','CBOE' from dual
 union all
	 select 'CBOE','MM','Market-Maker, MRUT','4','8','CBOE' from dual
 union all
	 select 'CBOE','MP','Market Maker, Manual, XSP, MRUT, DJX','4','6','CBOE' from dual
 union all
	 select 'CBOE','MR','Market-Maker, OEX, XEO','','8','CBOE' from dual
 union all
	 select 'CBOE','MS','"Market-Maker, SPX, SPESG	"','','8','CBOE' from dual
 union all
	 select 'CBOE','MT','"Market-Maker, RUT only	"','','8','CBOE' from dual
 union all
	 select 'CBOE','MV','"Market-Maker, Premium $0.00-$0.10, VIX	"','','8','CBOE' from dual
 union all
	 select 'CBOE','MW','"Market-Maker, Premium >=$0.11, VIX	"','','8','CBOE' from dual
 union all
	 select 'CBOE','MX','Market Maker, Electronic, Contra Non-Customer and Adding Liquidity, XSP','','8','CBOE' from dual
 union all
	 select 'CBOE','MY','Market Maker, Electronic, Contra Non-Customer and Removing Liquidity, XSP, MRUT, DJX','2','8','CBOE' from dual
 union all
	 select 'PHLX','N','Executed on PHLX – Maker/Taker N/A','4','8','PHLX' from dual
 union all
	 select 'NASDAQ Options','N','Maker/Taker','','8','NSDQO' from dual
 union all
	 select 'NASDAQ BX Options','N','Maker/Taker','','8', 'NQBXO' from dual
 union all
	 select 'CBOE','NB','"Non-Customer, Non-Market-Maker, AIM Response, Penny	"','','5','CBOE' from dual
 union all
	 select 'EDGX Options','NB','Broker Dealer, non-penny','','8','EDGO' from dual
 union all
	 select 'CBOE','NC','"Non-Customer, Non-Market-Maker, AIM Response, Non-Penny	"','','5','CBOE' from dual
 union all
	 select 'EDGX Options','NC','Customer, Removes liquidity, non-penny','','2','EDGO' from dual
 union all
	 select 'EDGX Options','NF','Firm, non-penny','','8','EDGO' from dual
 union all
	 select 'CBOE','NM','Market-Maker, NANOS','4','8','CBOE' from dual
 union all
	 select 'CBOE','NN','Non-Customer, Non-Market-Maker, NANOS','4','8','CBOE' from dual
 union all
	 select 'EDGX Options','NN','Away Market Maker, non-penny','','8','EDGO' from dual
 union all
	 select 'EDGX Options','NO','Joint Back Office, non-penny','','8','EDGO' from dual
 union all
	 select 'CBOE','NO','Customer, NANOS','4','8','CBOE' from dual
 union all
	 select 'EDGX Options','NP','Professional, non-penny','','8','EDGO' from dual
 union all
	 select 'EDGX Options','OC','Complex Trades at the Open','0','8','EDGO' from dual
 union all
	 select 'AMEX Pillar','OL','Limit orders and additional manual PRIN interest (Equities = NYSE DMM only)','4','Delete','AMEXP' from dual
 union all
	 select 'EDGX Options','PB','Broker Dealer, Penny','','8','EDGO' from dual
 union all
	 select 'EDGX Options','PC','Customer, Penny','','8','EDGO' from dual
 union all
	 select 'EDGX Options','PF','Firm, Penny','','8','EDGO' from dual
 union all
	 select 'EDGX Options','PN','Away Market Maker, Penny','','8','EDGO' from dual
 union all
	 select 'EDGX Options','PO','Joint Back Office, Penny','','8','EDGO' from dual
 union all
	 select 'EDGX Options','PP','Professional, Penny','','8','EDGO' from dual
 union all
	 select 'EDGX Options','QA','QCC Agency (Customer)','','5','EDGO' from dual
 union all
	 select 'CBOE','QC','Customer, Professional, QCC','','5','CBOE' from dual
 union all
	 select 'EDGX Options','QC','QCC Contra (Customer)','','5','EDGO' from dual
 union all
	 select 'EDGX Options','QM','QCC Agency (Non-Customer, Non-Professional)','','5','EDGO' from dual
 union all
	 select 'CBOE','QN','Non-Customer, Non-Professional, QCC','','5','CBOE' from dual
 union all
	 select 'EDGX Options','QN','QCC Contra (Non-Customer, Non-Professional)','','5','EDGO' from dual
 union all
	 select 'EDGX Options','QO','QCC Agency (Professional)','0','5','EDGO' from dual
 union all
	 select 'EDGX Options','QP','QCC Contra (Professional)','0','5','EDGO' from dual
 union all
	 select 'ARCA Pillar','RCOA','Initiating Complex Order Auction','2','4','ARCAP' from dual
 union all
	 select 'CBOE','RV','Reversal Trade','4','8','CBOE' from dual
 union all
	 select 'EDGX Options','SA','SAM Agency (Non-Customer, Non-Professional)','0','5','EDGO' from dual
 union all
	 select 'EDGX Options','SB','SAM Contra (Customer)','0','5','EDGO' from dual
 union all
	 select 'EDGX Options','SC','SAM Agency (Customer)','0','5','EDGO' from dual
 union all
	 select 'CBOE','SC','Compression Trade','','8','CBOE' from dual
 union all
	 select 'EDGX Options','SD','SAM Response, Penny','0','5','EDGO' from dual
 union all
	 select 'EDGX Options','SE','SAM Response, Non-Penny','0','5','EDGO' from dual
 union all
	 select 'EDGX Options','SF','SAM Contra (Non-Customer, Non-Professional)','4','5','EDGO' from dual
 union all
	 select 'EDGX Options','SG','SAM Agency (Professional)','0','5','EDGO' from dual
 union all
	 select 'EDGX Options','SH','SAM Contra (Professional)','0','5','EDGO' from dual
 union all
	 select 'CBOE','ST','Compression Service Trade','4','8','CBOE' from dual
 union all
	 select 'PHLX','U','Executed on PHLX - No maker/taker info ','3','8','PHLX' from dual
 union all
	 select 'CBOE','WA','Professional Customer, Manual','','6','CBOE' from dual
 union all
	 select 'CBOE','WR','RLG, RLV, RUI, UKXM','','8','CBOE' from dual
 union all
	 select 'CBOE','XB','Non-Customer, Non-Market-Maker, Electronic, Contra Non-Customer and Removing Liquidity, XSP, MRUT, DJX','2','8','CBOE' from dual
 union all
	 select 'CBOE','XC','Customer, XSP, MRUT, DJX, <10 contracts','4','8','CBOE' from dual
 union all
	 select 'CBOE','XF','Non-Customer, Non-Market-Maker, Electronic, Contra Customer or Contra Non-Customer and Adding Liquidity, XSP, MRUT, DJX','1','8','CBOE' from dual
 union all
	 select 'CBOE','XN','Non-Customer, Non-Market-Maker, Manual, XSP, MRUT, DJX','4','6','CBOE' from dual
 union all
	 select 'CBOE','YB','AIM Contra, Index','4','5','CBOE' from dual
 union all
	 select 'CBOE','YC','Non-Market Maker, AIM Contra, Flex Auction Responder, Equity, ETF','4','5','CBOE' from dual
 union all
	 select 'EDGX Options','ZA','"Complex order, Customer (contra Non-Customer), Penny	"','','8','EDGO' from dual
 union all
	 select 'EDGX Options','ZB','Complex order, Customer (contra Non-Customer), Non-Penny','','8','EDGO' from dual
 union all
	 select 'EDGX Options','ZC','Complex order, Customer (contra Customer)','','8','EDGO' from dual
 union all
	 select 'ARCA Pillar','ZC','Customer to Customer Cross','4','5','ARCAP' from dual
 union all
	 select 'AMEX Pillar','ZC','Customer to Customer Cross','4','5','AMEXP' from dual
 union all
	 select 'EDGX Options','ZD','Complex order legs into Simple Book, Customer','','8','EDGO' from dual
 union all
	 select 'EDGX Options','ZM','Complex order, Market Maker (contra Customer), Penny','','8','EDGO' from dual
 union all
	 select 'EDGX Options','ZN','Complex order, Market Maker (contra Customer), Non-Penny','','8','EDGO' from dual
 union all
	 select 'AMEX Pillar','ZOC','Outcry Complex','4','6','AMEXP' from dual
 union all
	 select 'AMEX Pillar','ZOS','Outcry Single Leg','4','6','AMEXP' from dual
 union all
	 select 'AMEX Pillar','ZPC','CUBE PI Contra','4','5','AMEXP' from dual
 union all
	 select 'AMEX Pillar','ZPI','CUBE PI Initiating','4','5','AMEXP' from dual
 union all
	 select 'AMEX Pillar','ZPR','CUBE PI - GTX Response','4','5','AMEXP' from dual
 union all
	 select 'AMEX Pillar','ZPRU','CUBE PI - Unrelated Response','4','5','AMEXP' from dual
 union all
	 select 'ARCA Pillar','ZQ','Qualified Contingent Cross (QCC)','4','5','ARCAP' from dual
 union all
	 select 'AMEX Pillar','ZQ','Qualified Contingent Cross (QCC)','4','5','AMEXP' from dual
 union all
	 select 'EDGX Options','ZR','Complex order, Non-Customer/Non-Market Maker (contra Customer), Non-Penny','','8','EDGO' from dual
 union all
	 select 'AMEX Pillar','ZSC','AON CUBE Contra','4','5','AMEXP' from dual
 union all
	 select 'AMEX Pillar','ZSI','AON CUBE Initiating','4','5','AMEXP' from dual
 union all
	 select 'AMEX Pillar','ZSR','AON CUBE - GTX Response','4','5','AMEXP' from dual
 union all
	 select 'AMEX Pillar','ZSRU','AON CUBE - Unrelated Response','4','5','AMEXP' from dual
 union all
	 select 'EDGX Options','ZT','Complex order, Non-Customer/Non-Market Maker (contra Customer), Penny','','8','EDGO' from dual
	 )
select * from ind;



create table  "GENESIS2_QA_20100601"."SO_TRASH_LIQUIDITY_INDICATOR"
as
select *
from "GENESIS2_QA_20100601"."LIQUIDITY_INDICATOR";

select * from "GENESIS2_QA_20100601"."SO_TRASH_LIQUIDITY_INDICATOR"
where EXCHANGE_ID = 'GMNIF' and TRADE_LIQUIDITY_INDICATOR = '51';

----------------------------------------

MERGE INTO "GENESIS2_QA_20100601"."SO_TRASH_LIQUIDITY_INDICATOR" t
USING (with ind ("Exchange Name", "Trade Liq Ind", "Description", "DASH Liq Ind Type", "Harrys revised answers", exchange_id)
         as (
	 select 'PHLX','1','Add/Maker','','1','PHLX' from dual
 union all
	 select 'PHLX','10','Routed Out','','3','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','11','Trade Report','2','8','GMNIF' from dual
 union all
	 select 'PHLX','11','Trade Report','','8','PHLX' from dual
 union all
	 select 'NASDAQ Texas Options','11','Trade Report','2','8','NQBXO' from dual
 union all
	 select 'ISE Fusion','11','Trade Report','2','8','ISEF' from dual
 union all
	 select 'ISE Mercury Fusion','11','Trade Report','2','8','MCRYF' from dual
 union all
	 select 'PHLX','12','Combo Maker Against Combo','','1','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','12','Combo Maker Against Combo','','1','GMNIF' from dual
 union all
	 select 'PHLX','13','Combo Taker Against Combo','','2','PHLX' from dual
 union all
	 select 'PHLX','14','Combo Response Against Combo','','4','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','15','Combo Hidden Against Combo','4','8','GMNIF' from dual
 union all
	 select 'NASDAQ Texas Options','15','Combo Hidden Against Combo','4','8','NQBXO' from dual
 union all
	 select 'ISE Fusion','15','Combo Hidden Against Combo','4','8','ISEF' from dual
 union all
	 select 'ISE Mercury Fusion','15','Combo Hidden Against Combo','4','8','MCRYF' from dual
 union all
	 select 'PHLX','15','Combo Hidden Against Combo','','8','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','16','Combo Opening Rotation','4','8','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','16','Combo Opening Rotation','4','8','MCRYF' from dual
 union all
	 select 'NASDAQ Texas Options','16','Combo Opening Rotation','4','8','NQBXO' from dual
 union all
	 select 'ISE Fusion','16','Combo Opening Rotation','4','8','ISEF' from dual
 union all
	 select 'PHLX','16','Combo Opening Rotation','','8','PHLX' from dual
 union all
	 select 'ISE Mercury Fusion','17','Combo Cross','4','5','MCRYF' from dual
 union all
	 select 'NASDAQ Texas Options','17','Combo Cross','4','5','NQBXO' from dual
 union all
	 select 'ISE Fusion','17','Combo Cross','4','5','ISEF' from dual
 union all
	 select 'PHLX','17','Combo Cross','','5','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','17','Combo Cross','4','5','GMNIF' from dual
 union all
	 select 'PHLX','18','Combo Taker Against Regular','','2','PHLX' from dual
 union all
	 select 'PHLX','19','Regular Maker Against Combo','','1','PHLX' from dual
 union all
	 select 'PHLX','20','Combo Taker Against IO','','2','PHLX' from dual
 union all
	 select 'PHLX','21','Regular Taker Against IO (incl. PIM)','','2','PHLX' from dual
 union all
	 select 'PHLX','22','IO Maker Against Combo','','1','PHLX' from dual
 union all
	 select 'PHLX','23','IO Maker Against Regular','','1','PHLX' from dual
 union all
	 select 'PHLX','24','Regular Maker Against IO Participant','','1','PHLX' from dual
 union all
	 select 'PHLX','25','IO Participant Taker Against Regular','','2','PHLX' from dual
 union all
	 select 'NASDAQ Texas Options','26','Broken Price Improvements','4','5','NQBXO' from dual
 union all
	 select 'PHLX','26','Broken Price Improvement§§','','5','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','26','Broken Price Improvement','4','5','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','26','Broken Price Improvement','4','5','MCRYF' from dual
 union all
	 select 'ISE Fusion','26','Broken Price Improvement','4','5','ISEF' from dual
 union all
	 select 'ISE Mercury Fusion','27','Broken Facilitation','4','5','MCRYF' from dual
 union all
	 select 'ISE Fusion','27','Broken Facilitation','4','5','ISEF' from dual
 union all
	 select 'NASDAQ Texas Options','27','Broken Facilitation','4','5','NQBXO' from dual
 union all
	 select 'PHLX','27','Broken Facilitation','','5','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','27','Broken Facilitation','4','5','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','28','Broken Solicitation','4','5','MCRYF' from dual
 union all
	 select 'ISE Fusion','28','Broken Solicitation','4','5','ISEF' from dual
 union all
	 select 'PHLX','28','Broken Solicitation','','5','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','28','Broken Solicitation','4','5','GMNIF' from dual
 union all
	 select 'NASDAQ Texas Options','28','Broken Solicitation','4','5','NQBXO' from dual
 union all
	 select 'NASDAQ Texas Options','29','Combo Broken Price Improvement','4','5','NQBXO' from dual
 union all
	 select 'ISE Gemini Fusion','29','Combo Broken Price Improvement','4','5','GMNIF' from dual
 union all
	 select 'PHLX','29','Combo Broken Price Improvement','','5','PHLX' from dual
 union all
	 select 'ISE Fusion','29','Combo Broken Price Improvement','4','5','ISEF' from dual
 union all
	 select 'ISE Mercury Fusion','29','Combo Broken Price Improvement','4','5','MCRYF' from dual
 union all
	 select 'PHLX','30','Combo Broken Facilitation','','5','PHLX' from dual
 union all
	 select 'NASDAQ Texas Options','30','Combo Broken Facilitation','4','5','NQBXO' from dual
 union all
	 select 'ISE Gemini Fusion','30','Combo Broken Facilitation','4','5','GMNIF' from dual
 union all
	 select 'ISE Fusion','30','Combo Broken Facilitation','4','5','ISEF' from dual
 union all
	 select 'ISE Mercury Fusion','30','Combo Broken Facilitation','4','5','MCRYF' from dual
 union all
	 select 'PHLX','31','Combo Broken Solicitation','','5','PHLX' from dual
 union all
	 select 'NASDAQ Texas Options','31','Combo Broken Solicitation','4','5','NQBXO' from dual
 union all
	 select 'ISE Mercury Fusion','31','Combo Broken Solicitation','4','5','MCRYF' from dual
 union all
	 select 'ISE Gemini Fusion','31','Combo Broken Solicitation','4','5','GMNIF' from dual
 union all
	 select 'ISE Fusion','31','Combo Broken Solicitation','4','5','ISEF' from dual
 union all
	 select 'PHLX','32','Block','','4','PHLX' from dual
 union all
	 select 'PHLX','33','Block Response','','4','PHLX' from dual
 union all
	 select 'PHLX','34','Directed Response','','8','PHLX' from dual
 union all
	 select 'NASDAQ Texas Options','34','Directed Response','','8','NQBXO' from dual
 union all
	 select 'ISE Fusion','34','Directed Response','','8','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','34','Directed Response','','8','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','34','Directed Response','','8','MCRYF' from dual
 union all
	 select 'ISE Mercury Fusion','35','Facilitation','4','5','MCRYF' from dual
 union all
	 select 'PHLX','35','Facilitation','','5','PHLX' from dual
 union all
	 select 'ISE Fusion','35','Facilitation','4','5','ISEF' from dual
 union all
	 select 'NASDAQ Texas Options','35','Facilitation','4','5','NQBXO' from dual
 union all
	 select 'ISE Gemini Fusion','35','Facilitation','4','5','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','36','Facilitation Response','4','5','MCRYF' from dual
 union all
	 select 'ISE Gemini Fusion','36','Facilitation Response','4','5','GMNIF' from dual
 union all
	 select 'NASDAQ Texas Options','36','Facilitation Response','4','5','NQBXO' from dual
 union all
	 select 'ISE Fusion','36','Facilitation Response','4','5','ISEF' from dual
 union all
	 select 'PHLX','36','Facilitation Response','','5','PHLX' from dual
 union all
	 select 'NASDAQ Texas Options','37','Price Improvement','1','5','NQBXO' from dual
 union all
	 select 'ISE Gemini Fusion','37','Price Improvement','1','5','GMNIF' from dual
 union all
	 select 'ISE Fusion','37','Price Improvement','1','5','ISEF' from dual
 union all
	 select 'PHLX','37','Price Improvement','','5','PHLX' from dual
 union all
	 select 'ISE Mercury Fusion','37','Price Improvement','1','5','MCRYF' from dual
 union all
	 select 'ISE Mercury Fusion','38','Price improvement Response','1','5','MCRYF' from dual
 union all
	 select 'NASDAQ Texas Options','38','Price Improvement Response','1','5','NQBXO' from dual
 union all
	 select 'ISE Gemini Fusion','38','Price improvement Response','1','5','GMNIF' from dual
 union all
	 select 'ISE Fusion','38','Price improvement Response','1','5','ISEF' from dual
 union all
	 select 'PHLX','38','Price improvement Response','','5','PHLX' from dual
 union all
	 select 'NASDAQ Texas Options','39','Solicitation','4','5','NQBXO' from dual
 union all
	 select 'ISE Gemini Fusion','39','Solicitation','4','5','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','39','Solicitation','4','5','MCRYF' from dual
 union all
	 select 'PHLX','39','Solicitation','','5','PHLX' from dual
 union all
	 select 'ISE Fusion','39','Solicitation','4','5','ISEF' from dual
 union all
	 select 'NASDAQ Texas Options','4','Response','2','4','NQBXO' from dual
 union all
	 select 'ISE Gemini Fusion','4','Response','2','4','GMNIF' from dual
 union all
	 select 'PHLX','4','Response','','4','PHLX' from dual
 union all
	 select 'ISE Fusion','4','Response','2','4','ISEF' from dual
 union all
	 select 'ISE Mercury Fusion','4','Response','2','4','MCRYF' from dual
 union all
	 select 'PHLX','40','Solicitation Response','','5','PHLX' from dual
 union all
	 select 'ISE Mercury Fusion','40','Solicitation Response','4','5','MCRYF' from dual
 union all
	 select 'ISE Fusion','40','Solicitation Response','4','5','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','40','Solicitation Response','4','5','GMNIF' from dual
 union all
	 select 'NASDAQ Texas Options','40','Solicitation Response','4','5','NQBXO' from dual
 union all
	 select 'PHLX','41','Qualified Contingent Cross','','5','PHLX' from dual
 union all
	 select 'ISE Fusion','41','Qualified Contingent Cross','4','5','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','41','Qualified Contingent Cross','4','5','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','41','Qualified Contingent Cross','4','5','MCRYF' from dual
 union all
	 select 'NASDAQ Texas Options','41','Qualified Contingent Cross','4','5','NQBXO' from dual
 union all
	 select 'NASDAQ Texas Options','42','Customer to Customer','4','5','NQBXO' from dual
 union all
	 select 'ISE Mercury Fusion','42','Customer to Customer','4','5','MCRYF' from dual
 union all
	 select 'ISE Gemini Fusion','42','Customer to Customer','4','5','GMNIF' from dual
 union all
	 select 'PHLX','42','Customer to Customer','','5','PHLX' from dual
 union all
	 select 'ISE Fusion','42','Customer to Customer','4','5','ISEF' from dual
 union all
	 select 'ISE Fusion','43','Combo Facilitation','4','5','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','43','Combo Facilitation','4','5','GMNIF' from dual
 union all
	 select 'NASDAQ Texas Options','43','Combo Facilitation','4','5','NQBXO' from dual
 union all
	 select 'PHLX','43','Combo Facilitation','','5','PHLX' from dual
 union all
	 select 'ISE Mercury Fusion','43','Combo Facilitation','4','5','MCRYF' from dual
 union all
	 select 'NASDAQ Texas Options','44','Combo Facilitation Response','4','5','NQBXO' from dual
 union all
	 select 'ISE Fusion','44','Combo Facilitation Response','4','5','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','44','Combo Facilitation Response','4','5','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','44','Combo Facilitation Response','4','5','MCRYF' from dual
 union all
	 select 'PHLX','44','Combo Facilitation Response','','5','PHLX' from dual
 union all
	 select 'PHLX','45','Combo Price Improvement','','5','PHLX' from dual
 union all
	 select 'ISE Fusion','45','Combo Price Improvement','','5','ISEF' from dual
 union all
	 select 'NASDAQ Texas Options','45','Combo Price Improvement','','5','NQBXO' from dual
 union all
	 select 'ISE Gemini Fusion','45','Combo Price Improvement','','5','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','45','Combo Price Improvement','1','5','MCRYF' from dual
 union all
	 select 'PHLX','46','Combo Price Improvement Response','','5','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','46','Combo Price Improvement Response','','5','GMNIF' from dual
 union all
	 select 'ISE Fusion','46','Combo Price Improvement Response','','5','ISEF' from dual
 union all
	 select 'NASDAQ Texas Options','46','Combo Price Improvement Response','','5','NQBXO' from dual
 union all
	 select 'ISE Mercury Fusion','46','Combo Price Improvement Response','1','5','MCRYF' from dual
 union all
	 select 'ISE Mercury Fusion','47','Combo Solicitation','4','5','MCRYF' from dual
 union all
	 select 'NASDAQ Texas Options','47','Combo Solicitation','','5','NQBXO' from dual
 union all
	 select 'PHLX','47','Combo Solicitation','','5','PHLX' from dual
 union all
	 select 'ISE Fusion','47','Combo Solicitation','4','5','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','47','Combo Solicitation','','5','GMNIF' from dual
 union all
	 select 'ISE Fusion','48','Combo Solicitation Response','4','5','ISEF' from dual
 union all
	 select 'NASDAQ Texas Options','48','Combo Solicitation Response','4','5','NQBXO' from dual
 union all
	 select 'PHLX','48','Combo Solicitation Response','','5','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','48','Combo Solicitation Response','4','5','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','48','Combo Solicitation Response','4','5','MCRYF' from dual
 union all
	 select 'ISE Mercury Fusion','49','Combo Qualified Contingent Cross','4','5','MCRYF' from dual
 union all
	 select 'PHLX','49','Combo Qualified Contingent Cross','','5','PHLX' from dual
 union all
	 select 'ISE Fusion','49','Combo Qualified Contingent Cross','4','5','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','49','Combo Qualified Contingent Cross','4','5','GMNIF' from dual
 union all
	 select 'NASDAQ Texas Options','49','Combo Qualified Contingent Cross','4','5','NQBXO' from dual
 union all
	 select 'ISE Mercury Fusion','5','Hidden','2','8','MCRYF' from dual
 union all
	 select 'PHLX','5','Hidden','','8','PHLX' from dual
 union all
	 select 'NASDAQ Texas Options','5','Hidden','2','8','NQBXO' from dual
 union all
	 select 'ISE Fusion','5','Hidden','2','8','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','5','Hidden','2','8','GMNIF' from dual
 union all
	 select 'ISE Fusion','50','Combo Customer to Customer','4','5','ISEF' from dual
 union all
	 select 'PHLX','50','Combo Customer to Customer','','5','PHLX' from dual
 union all
	 select 'NASDAQ Texas Options','50','Combo Customer to Customer','4','5','NQBXO' from dual
 union all
	 select 'ISE Mercury Fusion','50','Combo Customer to Customer','4','5','MCRYF' from dual
 union all
	 select 'ISE Gemini Fusion','50','Combo Customer to Customer','4','5','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','51','Sweep Routed Out','2','3','MCRYF' from dual
 union all
	 select 'ISE Fusion','51','Sweep Routed Out','2','3','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','51','Sweep Routed Out','2','3','GMNIF' from dual
 union all
	 select 'NASDAQ Texas Options','51','Sweep Routed Out','2','3','NQBXO' from dual
 union all
	 select 'PHLX','51','Sweep Routed Out','','3','PHLX' from dual
 union all
	 select 'PHLX','52','Sweep Trade Report','','2','PHLX' from dual
 union all
	 select 'PHLX','53','Combo Taker Against Regular – Thru NBBO','','2','PHLX' from dual
 union all
	 select 'PHLX','54','Combo Taker Against IO – Thru NBBO','','2','PHLX' from dual
 union all
	 select 'PHLX','55','Simple Exposure Order – Upon Receipt','','4','PHLX' from dual
 union all
	 select 'PHLX','56','Simple Exposure Order – Subsequent','','4','PHLX' from dual
 union all
	 select 'PHLX','57','Simple Exposure Order – Responder','','4','PHLX' from dual
 union all
	 select 'ISE Fusion','58','Flex Auction','','4','ISEF' from dual
 union all
	 select 'PHLX','58','Flex Auction','','4','PHLX' from dual
 union all
	 select 'ISE Mercury Fusion','58','Flex Auction','','4','MCRYF' from dual
 union all
	 select 'ISE Gemini Fusion','58','Flex Auction','','4','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','59','Flex Auction Responder','','8','MCRYF' from dual
 union all
	 select 'ISE Fusion','59','Flex Auction Responder','','8','ISEF' from dual
 union all
	 select 'PHLX','59','Flex Auction Responder','','8','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','59','Flex Auction Responder','','8','GMNIF' from dual
 union all
	 select 'NASDAQ Texas Options','6','Opening','','8','NQBXO' from dual
 union all
	 select 'PHLX','6','Opening','','8','PHLX' from dual
 union all
	 select 'ISE Mercury Fusion','6','Opening','1','8','MCRYF' from dual
 union all
	 select 'ISE Fusion','6','Opening','4','8','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','6','Opening','4','8','GMNIF' from dual
 union all
	 select 'PHLX','60','Flex Price Improvement','','5','PHLX' from dual
 union all
	 select 'ISE Mercury Fusion','60','Flex Price Improvement','','5','MCRYF' from dual
 union all
	 select 'ISE Fusion','60','Flex Price Improvement','','5','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','60','Flex Price Improvement','','5','GMNIF' from dual
 union all
	 select 'ISE Fusion','61','Flex Price Improvement Responder','','5','ISEF' from dual
 union all
	 select 'ISE Mercury Fusion','61','Flex Price Improvement Responder','','5','MCRYF' from dual
 union all
	 select 'ISE Gemini Fusion','61','Flex Price Improvement Responder','','5','GMNIF' from dual
 union all
	 select 'PHLX','61','Flex Price Improvement Responder','','5','PHLX' from dual
 union all
	 select 'ISE Fusion','62','Flex Broken Price Improvement','','5','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','62','Flex Broken Price Improvement','','5','GMNIF' from dual
 union all
	 select 'PHLX','62','Flex Broken Price Improvement','','5','PHLX' from dual
 union all
	 select 'ISE Mercury Fusion','62','Flex Broken Price Improvement','','5','MCRYF' from dual
 union all
	 select 'ISE Mercury Fusion','63','Flex Solicitation','','5','MCRYF' from dual
 union all
	 select 'ISE Fusion','63','Flex Solicitation','','5','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','63','Flex Solicitation','','5','GMNIF' from dual
 union all
	 select 'PHLX','63','Flex Solicitation','','5','PHLX' from dual
 union all
	 select 'ISE Fusion','64','Flex Solicitation Responder','','5','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','64','Flex Solicitation Responder','','5','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','64','Flex Solicitation Responder','','5','MCRYF' from dual
 union all
	 select 'PHLX','64','Flex Solicitation Responder','','5','PHLX' from dual
 union all
	 select 'ISE Mercury Fusion','65','Flex Broken Solicitation','','5','MCRYF' from dual
 union all
	 select 'PHLX','65','Flex Broken Solicitation','','5','PHLX' from dual
 union all
	 select 'ISE Fusion','65','Flex Broken Solicitation','','5','ISEF' from dual
 union all
	 select 'ISE Gemini Fusion','65','Flex Broker Soliciation','','5','GMNIF' from dual
 union all
	 select 'PHLX','66','Combo Flex Auction','','4','PHLX' from dual
 union all
	 select 'ISE Mercury Fusion','66','Combo Flex Auction','','4','MCRYF' from dual
 union all
	 select 'ISE Gemini Fusion','66','Combo Flex Auction','','4','GMNIF' from dual
 union all
	 select 'ISE Fusion','66','Combo Flex Auction','','4','ISEF' from dual
 union all
	 select 'ISE Fusion','67','Combo Flex Auction Responder','','8','ISEF' from dual
 union all
	 select 'PHLX','67','Combo Flex Auction Responder','','8','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','67','Combo Flex Auction Responder','','8','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','67','Combo Flex Auction Responder','','8','MCRYF' from dual
 union all
	 select 'ISE Mercury Fusion','68','Combo Flex Price Improvement','','5','MCRYF' from dual
 union all
	 select 'ISE Gemini Fusion','68','Combo Flex Price Improvement','','5','GMNIF' from dual
 union all
	 select 'ISE Fusion','68','Combo Flex Price Improvement','','5','ISEF' from dual
 union all
	 select 'PHLX','68','Combo Flex Price Improvement','','5','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','69','Combo Flex Price Improvement Responder','','5','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','69','Combo Flex Price Improvement Responder','','5','MCRYF' from dual
 union all
	 select 'ISE Fusion','69','Combo Flex Price Improvement Responder','','5','ISEF' from dual
 union all
	 select 'PHLX','69','Combo Flex Price Improvement Responder','','5','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','7','Cross','4','5','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','7','Cross','4','5','MCRYF' from dual
 union all
	 select 'ISE Fusion','7','Cross','4','5','ISEF' from dual
 union all
	 select 'NASDAQ Texas Options','7','Cross','4','5','NQBXO' from dual
 union all
	 select 'PHLX','7','Cross','','5','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','70','Combo Flex Broken Price Improvement','','5','GMNIF' from dual
 union all
	 select 'PHLX','70','Combo Flex Broken Price Improvement','','5','PHLX' from dual
 union all
	 select 'ISE Fusion','70','Combo Flex Broken Price Improvement Responder','','5','ISEF' from dual
 union all
	 select 'ISE Mercury Fusion','70','Combo Flex Broken Price Improvement','','5','MCRYF' from dual
 union all
	 select 'ISE Gemini Fusion','71','Combo Flex Solicitation','','5','GMNIF' from dual
 union all
	 select 'ISE Fusion','71','Combo Flex Solicitation','','5','ISEF' from dual
 union all
	 select 'PHLX','71','Combo Flex Solicitation','','5','PHLX' from dual
 union all
	 select 'ISE Mercury Fusion','71','Combo Flex Solicitation','','5','MCRYF' from dual
 union all
	 select 'ISE Fusion','72','Combo Flex Solicitation Responder','','5','ISEF' from dual
 union all
	 select 'PHLX','72','Combo Flex Solicitation Responder','','5','PHLX' from dual
 union all
	 select 'ISE Mercury Fusion','72','Combo Flex Solicitation Responder','','5','MCRYF' from dual
 union all
	 select 'ISE Gemini Fusion','72','Combo Flex Solicitation Responder','','5','GMNIF' from dual
 union all
	 select 'ISE Mercury Fusion','73','Combo Flex Broken Solicitation','','5','MCRYF' from dual
 union all
	 select 'ISE Fusion','73','Combo Flex Broken Solicitation','','5','ISEF' from dual
 union all
	 select 'PHLX','73','Combo Flex Broken Solicitation','','5','PHLX' from dual
 union all
	 select 'ISE Gemini Fusion','73','Combo Flex Broker Solicitation','','5','GMNIF' from dual
 union all
	 select 'PHLX','8','Flashed Order','','4','PHLX' from dual
 union all
	 select 'PHLX','9','Flash Response','','4','PHLX' from dual
 union all
	 select 'CBOE','B1','Customer, CBTX','4','8','CBOE' from dual
 union all
	 select 'CBOE','B2','Non-Customer, Manual, CBTX','4','6','CBOE' from dual
 union all
	 select 'EDGX Options','BA','AIM Agency (Non-Customer)','4','5','EDGO' from dual
 union all
	 select 'CBOE','BA','Broker-Dealer, Away Market-Maker, Manual','','6','CBOE' from dual
 union all
	 select 'CBOE','BB','Non-Customer, Non-Market-Maker, Non-Firm, Electronic, Penny','','8','CBOE' from dual
 union all
	 select 'EDGX Options','BB','AIM Contra, Penny','4','5','EDGO' from dual
 union all
	 select 'BATS Options','BC','"Adds or removes liquidity (Customer), RUT	"','4','8','BATO' from dual
 union all
	 select 'C2','BC','Public Customer ','4','8','C2OX' from dual
 union all
	 select 'CBOE','BC','Non-Customer, Non-Market-Maker, Non-Firm, Electronic, Non-Penny','','8','CBOE' from dual
 union all
	 select 'EDGX Options','BC','AIM Agency (Customer), Penny','4','5','EDGO' from dual
 union all
	 select 'EDGX Options','BD','AIM Response, Penny','4','5','EDGO' from dual
 union all
	 select 'CBOE','BD','Non-Customer, Non-Market-Maker, Non-Firm, AIM Agency','','5','CBOE' from dual
 union all
	 select 'CBOE','BE','Non-Customer, Non-Market-Maker, Non-Firm, Sector Indexes','','8','CBOE' from dual
 union all
	 select 'EDGX Options','BE','AIM Response, Non-Penny','4','5','EDGO' from dual
 union all
	 select 'EDGX Options','BF','AIM Contra, Non-Penny','4','5','EDGO' from dual
 union all
	 select 'CBOE','BG','Non-Customer, Non-Market-Maker, Non-Firm, MXACW, MXUSA, MXWLD','4','8','CBOE' from dual
 union all
	 select 'EDGX Options','BG','AIM Agency (Customer), Non-Penny','4','5','EDGO' from dual
 union all
	 select 'CBOE','BK','Non-Customer, Non-Market-Maker, Non-Firm, Electronic, Non-AIM, RUT Family','','8','CBOE' from dual
 union all
	 select 'BATS Options','BM','"Adds or removes liquidity (MM), RUT	"','4','8','BATO' from dual
 union all
	 select 'CBOE','BM','Non-Customer, Non-MarketMaker, Non-Firm, MRUT','4','8','CBOE' from dual
 union all
	 select 'C2','BM','C2 Market Maker ','4','8','C2OX' from dual
 union all
	 select 'C2','BN','All Non-Customer','4','8','C2OX' from dual
 union all
	 select 'BATS Options','BN','"Adds or removes liquidity (Non-Customer/Non-MM), RUT	"','4','8','BATO' from dual
 union all
	 select 'BATS Options','BO','"Trades on the Open, RUT	"','4','8','BATO' from dual
 union all
	 select 'CBOE','BR','Non-Customer, Non-Market-Maker, Non-Firm, OEX, XEO and VIX','','8','CBOE' from dual
 union all
	 select 'CBOE','BS','Non-Customer, Non-Market-Maker, Non-Firm, Manual, AIM, RUT Family','','5','CBOE' from dual
 union all
	 select 'CBOE','BT','Non-Customer, Non-Market-Maker, Non-Firm, SPX, SPESG','','8','CBOE' from dual
 union all
	 select 'C2','CA','Resting Simple Order Trades with Resting Complex Order','4','8','C2OX' from dual
 union all
	 select 'CBOE','CB','Customer, Index','','8','CBOE' from dual
 union all
	 select 'EDGX Options','CC','"AIM Customer-to-Customer Immediate Cross	"','4','5','EDGO' from dual
 union all
	 select 'CBOE','CC','Customer, XSP, >=10 contracts','','8','CBOE' from dual
 union all
	 select 'CBOE','CE','Customer, Adds liquidity, ETF','','1','CBOE' from dual
 union all
	 select 'CBOE','CG','Customer, MXACW, MXUSA, MXWLD','4','8','CBOE' from dual
 union all
	 select 'CBOE','CI','Customer, ProCustomer, Combo portion of an index combo order execution, VIX','4','8','CBOE' from dual
 union all
	 select 'CBOE','CK','Customer, Equity, ETF','','8','CBOE' from dual
 union all
	 select 'CBOE','CM','Customer, MXEA','','8','CBOE' from dual
 union all
	 select 'CBOE','CN','Customer, MXEF','','8','CBOE' from dual
 union all
	 select 'CBOE','CO','Customer, OEX, XEO','','8','CBOE' from dual
 union all
	 select 'CBOE','CP','Customer, Sector Indexes','','8','CBOE' from dual
 union all
	 select 'CBOE','CQ','Customer, MRUT','4','8','CBOE' from dual
 union all
	 select 'CBOE','CR','Customer, RUT family ','','8','CBOE' from dual
 union all
	 select 'CBOE','CS','Customer, Premium <$1.00, SPX, SPESG','','8','CBOE' from dual
 union all
	 select 'C2','CT','Resting Complex Orders Trades with Resting Simple Order','4','8','C2OX' from dual
 union all
	 select 'CBOE','CT','Customer, Premimum >=$1.00, SPX, SPESG','','8','CBOE' from dual
 union all
	 select 'CBOE','CV','Customer, Premium $0.00-$0.10, VIX, Simple','','8','CBOE' from dual
 union all
	 select 'CBOE','CW','Customer, Premium $0.11-$0.99, VIX, Simple','','8','CBOE' from dual
 union all
	 select 'CBOE','CX','Customer, Premium $1.00-$1.99, VIX, Simple ','','8','CBOE' from dual
 union all
	 select 'CBOE','CY','Customer, Premium >=$2.00, VIX, Simple','','8','CBOE' from dual
 union all
	 select 'CBOE','CZ','Customer, Premium $0.00-$0.10, VIX, Complex','','8','CBOE' from dual
 union all
	 select 'CBOE','DA','Customer, Premium, $0.11-$0.99, VIX, Complex','','8','CBOE' from dual
 union all
	 select 'CBOE','DB','Customer,Premium $1.00-$1.99, VIX, Complex','','8','CBOE' from dual
 union all
	 select 'C2','DC','Public Customer - DJX','4','8','C2OX' from dual
 union all
	 select 'CBOE','DC','Customer, Premium >=$2.00, VIX, Complex','','8','CBOE' from dual
 union all
	 select 'C2','DM','C2 Market Maker - DJX','4','8','C2OX' from dual
 union all
	 select 'C2','DN','All Non-Customer - DJX','4','8','C2OX' from dual
 union all
	 select 'C2','DO','"Trades at the Open - DJX	"','4','8','C2OX' from dual
 union all
	 select 'CBOE','E1','SPEQX, Customer','4','8','CBOE' from dual
 union all
	 select 'CBOE','E2','SPEQX, Non-Customer','4','8','CBOE' from dual
 union all
	 select 'EDGX Options','EF','Equity Leg - FOG','4','8','EDGO' from dual
 union all
	 select 'CBOE','EF','Equity Leg - FOG','4','8','CBOE' from dual
 union all
	 select 'CBOE','EL','Equity Leg - Libucki','4','8','CBOE' from dual
 union all
	 select 'EDGX Options','EL','Equity Leg - Libucki','4','8','EDGO' from dual
 union all
	 select 'CBOE','EP','Equity Leg - Penserra','4','8','CBOE' from dual
 union all
	 select 'EDGX Options','EP','Equity Leg - Penserra','4','8','EDGO' from dual
 union all
	 select 'EDGX Options','EQ','Equity Leg - Cowen (capped at $50/execution)','','8','EDGO' from dual
 union all
	 select 'CBOE','EQ','Equity Leg - Cowen (capped at $50/execution)','','8','CBOE' from dual
 union all
	 select 'EDGX Options','ES','Equity Leg - SRT','4','8','EDGO' from dual
 union all
	 select 'CBOE','ES','Equity Leg - SRT','4','8','CBOE' from dual
 union all
	 select 'CBOE','FA','Firm, Manual','','6','CBOE' from dual
 union all
	 select 'CBOE','FB','Firm, Electronic, Penny','','8','CBOE' from dual
 union all
	 select 'CBOE','FC','Firm, Electronic, Non-Penny','','8','CBOE' from dual
 union all
	 select 'CBOE','FD','Firm, AIM Agency ','','5','CBOE' from dual
 union all
	 select 'CBOE','FF','Firm Facilitation','4','5','CBOE' from dual
 union all
	 select 'CBOE','FG','Firm, MXACW, MXUSA, MXWLD','4','8','CBOE' from dual
 union all
	 select 'CBOE','FH','Firm, Underlying Symbol List A','','8','CBOE' from dual
 union all
	 select 'CBOE','FI','Firm, Sector Indexes','','8','CBOE' from dual
 union all
	 select 'CBOE','FK','Firm, VIX','','8','CBOE' from dual
 union all
	 select 'CBOE','FM','Firm, MRUT','4','8','CBOE' from dual
 union all
	 select 'CBOE','FS','Non-Customer, Manual, Merger, Short Stock Interest, Reversal, Conversion and Jelly Roll Strategies, Equity, ETF','4','6','CBOE' from dual
 union all
	 select 'CBOE','GA','Customer, Market-Maker, Firm, RUT, Flex Micro','4','8','CBOE' from dual
 union all
	 select 'CBOE','GB','Non-Customer, Non-Market-Maker, Non-Firm, Manual, AIM, RUT, Flex Micro','4','5','CBOE' from dual
 union all
	 select 'CBOE','GC','Non-Customer, Non-Market-Maker, Non-Firm, Electronic, Non-AIM, RUT, Flex Micro','4','8','CBOE' from dual
 union all
	 select 'CBOE','GD','Non-Customer, Non-Market-Maker, Non-Firm, SPX, Flex Micro','4','8','CBOE' from dual
 union all
	 select 'CBOE','GE','Customer, Firm, SPX, Flex Micro','4','8','CBOE' from dual
 union all
	 select 'CBOE','GF','Market-Maker, SPX, Flex Micro','4','8','CBOE' from dual
 union all
	 select 'CBOE','GG','Customer, MXEA, MXEF, DJX, Flex Micro','4','8','CBOE' from dual
 union all
	 select 'CBOE','GH','Market-Maker, MXEA, MXEF, DJX, Flex Micro','4','8','CBOE' from dual
 union all
	 select 'CBOE','GI','Non-Customer, Non-Market-Maker, MXEA, MXEF, Electronic, Flex Micro','4','8','CBOE' from dual
 union all
	 select 'CBOE','GJ','Non-Customer, Non-Market-Maker, DJX, Electronic, Flex Micro','4','8','CBOE' from dual
 union all
	 select 'CBOE','GK','Non-Customer, Non-Market-Maker, MXEA, MXEF, DJX, Manual, AIM Agency, Flex Micro','4','5','CBOE' from dual
 union all
	 select 'CBOE','GL','Non-Customer, MXEA, MXEF, DJX, AIM Contra, Flex Micro','4','5','CBOE' from dual
 union all
	 select 'CBOE','GM','Non-Customer, DJX, AIM Response, Flex Micro','4','5','CBOE' from dual
 union all
	 select 'CBOE','GN','Non-Customer, MXEA, MXEF, AIM Response, Flex Micro','4','5','CBOE' from dual
 union all
	 select 'CBOE','M1','Customer, MBTX','4','8','CBOE' from dual
 union all
	 select 'CBOE','M2','Non-Customer, MBTX','4','8','CBOE' from dual
 union all
	 select 'CBOE','MA','Market-Maker, Electronic','','8','CBOE' from dual
 union all
	 select 'CBOE','MB','Market-Maker, Manual','4','6','CBOE' from dual
 union all
	 select 'CBOE','MC','Market Maker, Electronic, Contra Customer, XSP, MRUT, DJX','4','8','CBOE' from dual
 union all
	 select 'CBOE','MD','Market-Maker, AIM Responder','4','5','CBOE' from dual
 union all
	 select 'CBOE','MG','Market-Maker, MXACW, MXUSA, MXWLD','4','8','CBOE' from dual
 union all
	 select 'CBOE','MI','Market-Maker, VIX, Contra Order Quantity >=5000 Contracts, >=3 Legs, Manual','4','6','CBOE' from dual
 union all
	 select 'CBOE','MM','Market-Maker, MRUT','4','8','CBOE' from dual
 union all
	 select 'CBOE','MP','Market Maker, Manual, XSP, MRUT, DJX','4','6','CBOE' from dual
 union all
	 select 'CBOE','MR','Market-Maker, OEX, XEO','','8','CBOE' from dual
 union all
	 select 'CBOE','MS','"Market-Maker, SPX, SPESG	"','','8','CBOE' from dual
 union all
	 select 'CBOE','MT','"Market-Maker, RUT only	"','','8','CBOE' from dual
 union all
	 select 'CBOE','MV','"Market-Maker, Premium $0.00-$0.10, VIX	"','','8','CBOE' from dual
 union all
	 select 'CBOE','MW','"Market-Maker, Premium >=$0.11, VIX	"','','8','CBOE' from dual
 union all
	 select 'CBOE','MX','Market Maker, Electronic, Contra Non-Customer and Adding Liquidity, XSP','','8','CBOE' from dual
 union all
	 select 'CBOE','MY','Market Maker, Electronic, Contra Non-Customer and Removing Liquidity, XSP, MRUT, DJX','2','8','CBOE' from dual
 union all
	 select 'PHLX','N','Executed on PHLX – Maker/Taker N/A','4','8','PHLX' from dual
 union all
	 select 'NASDAQ Options','N','Maker/Taker','','8','NSDQO' from dual
 union all
	 select 'NASDAQ BX Options','N','Maker/Taker','','8','NQBXO' from dual
 union all
	 select 'CBOE','NB','"Non-Customer, Non-Market-Maker, AIM Response, Penny	"','','5','CBOE' from dual
 union all
	 select 'EDGX Options','NB','Broker Dealer, non-penny','','8','EDGO' from dual
 union all
	 select 'CBOE','NC','"Non-Customer, Non-Market-Maker, AIM Response, Non-Penny	"','','5','CBOE' from dual
 union all
	 select 'EDGX Options','NC','Customer, Removes liquidity, non-penny','','2','EDGO' from dual
 union all
	 select 'EDGX Options','NF','Firm, non-penny','','8','EDGO' from dual
 union all
	 select 'CBOE','NM','Market-Maker, NANOS','4','8','CBOE' from dual
 union all
	 select 'CBOE','NN','Non-Customer, Non-Market-Maker, NANOS','4','8','CBOE' from dual
 union all
	 select 'EDGX Options','NN','Away Market Maker, non-penny','','8','EDGO' from dual
 union all
	 select 'EDGX Options','NO','Joint Back Office, non-penny','','8','EDGO' from dual
 union all
	 select 'CBOE','NO','Customer, NANOS','4','8','CBOE' from dual
 union all
	 select 'EDGX Options','NP','Professional, non-penny','','8','EDGO' from dual
 union all
	 select 'EDGX Options','OC','Complex Trades at the Open','0','8','EDGO' from dual
 union all
	 select 'EDGX Options','PB','Broker Dealer, Penny','','8','EDGO' from dual
 union all
	 select 'EDGX Options','PC','Customer, Penny','','8','EDGO' from dual
 union all
	 select 'EDGX Options','PF','Firm, Penny','','8','EDGO' from dual
 union all
	 select 'EDGX Options','PN','Away Market Maker, Penny','','8','EDGO' from dual
 union all
	 select 'EDGX Options','PO','Joint Back Office, Penny','','8','EDGO' from dual
 union all
	 select 'EDGX Options','PP','Professional, Penny','','8','EDGO' from dual
 union all
	 select 'EDGX Options','QA','QCC Agency (Customer)','','5','EDGO' from dual
 union all
	 select 'CBOE','QC','Customer, Professional, QCC','','5','CBOE' from dual
 union all
	 select 'EDGX Options','QC','QCC Contra (Customer)','','5','EDGO' from dual
 union all
	 select 'EDGX Options','QM','QCC Agency (Non-Customer, Non-Professional)','','5','EDGO' from dual
 union all
	 select 'CBOE','QN','Non-Customer, Non-Professional, QCC','','5','CBOE' from dual
 union all
	 select 'EDGX Options','QN','QCC Contra (Non-Customer, Non-Professional)','','5','EDGO' from dual
 union all
	 select 'EDGX Options','QO','QCC Agency (Professional)','0','5','EDGO' from dual
 union all
	 select 'EDGX Options','QP','QCC Contra (Professional)','0','5','EDGO' from dual
 union all
	 select 'ARCA Pillar','RCOA','Initiating Complex Order Auction','2','4','ARCAP' from dual
 union all
	 select 'CBOE','RV','Reversal Trade','4','8','CBOE' from dual
 union all
	 select 'EDGX Options','SA','SAM Agency (Non-Customer, Non-Professional)','0','5','EDGO' from dual
 union all
	 select 'EDGX Options','SB','SAM Contra (Customer)','0','5','EDGO' from dual
 union all
	 select 'EDGX Options','SC','SAM Agency (Customer)','0','5','EDGO' from dual
 union all
	 select 'CBOE','SC','Compression Trade','','8','CBOE' from dual
 union all
	 select 'EDGX Options','SD','SAM Response, Penny','0','5','EDGO' from dual
 union all
	 select 'EDGX Options','SE','SAM Response, Non-Penny','0','5','EDGO' from dual
 union all
	 select 'EDGX Options','SF','SAM Contra (Non-Customer, Non-Professional)','4','5','EDGO' from dual
 union all
	 select 'EDGX Options','SG','SAM Agency (Professional)','0','5','EDGO' from dual
 union all
	 select 'EDGX Options','SH','SAM Contra (Professional)','0','5','EDGO' from dual
 union all
	 select 'CBOE','ST','Compression Service Trade','4','8','CBOE' from dual
 union all
	 select 'PHLX','U','Executed on PHLX - No maker/taker info ','3','8','PHLX' from dual
 union all
	 select 'CBOE','WA','Professional Customer, Manual','','6','CBOE' from dual
 union all
	 select 'CBOE','WR','RLG, RLV, RUI, UKXM','','8','CBOE' from dual
 union all
	 select 'CBOE','XB','Non-Customer, Non-Market-Maker, Electronic, Contra Non-Customer and Removing Liquidity, XSP, MRUT, DJX','2','8','CBOE' from dual
 union all
	 select 'CBOE','XC','Customer, XSP, MRUT, DJX, <10 contracts','4','8','CBOE' from dual
 union all
	 select 'CBOE','XF','Non-Customer, Non-Market-Maker, Electronic, Contra Customer or Contra Non-Customer and Adding Liquidity, XSP, MRUT, DJX','1','8','CBOE' from dual
 union all
	 select 'CBOE','XN','Non-Customer, Non-Market-Maker, Manual, XSP, MRUT, DJX','4','6','CBOE' from dual
 union all
	 select 'CBOE','YB','AIM Contra, Index','4','5','CBOE' from dual
 union all
	 select 'CBOE','YC','Non-Market Maker, AIM Contra, Flex Auction Responder, Equity, ETF','4','5','CBOE' from dual
 union all
	 select 'EDGX Options','ZA','"Complex order, Customer (contra Non-Customer), Penny	"','','8','EDGO' from dual
 union all
	 select 'EDGX Options','ZB','Complex order, Customer (contra Non-Customer), Non-Penny','','8','EDGO' from dual
 union all
	 select 'EDGX Options','ZC','Complex order, Customer (contra Customer)','','8','EDGO' from dual
 union all
	 select 'ARCA Pillar','ZC','Customer to Customer Cross','4','5','ARCAP' from dual
 union all
	 select 'AMEX Pillar','ZC','Customer to Customer Cross','4','5','AMEXP' from dual
 union all
	 select 'EDGX Options','ZD','Complex order legs into Simple Book, Customer','','8','EDGO' from dual
 union all
	 select 'EDGX Options','ZM','Complex order, Market Maker (contra Customer), Penny','','8','EDGO' from dual
 union all
	 select 'EDGX Options','ZN','Complex order, Market Maker (contra Customer), Non-Penny','','8','EDGO' from dual
 union all
	 select 'AMEX Pillar','ZOC','Outcry Complex','4','6','AMEXP' from dual
 union all
	 select 'AMEX Pillar','ZOS','Outcry Single Leg','4','6','AMEXP' from dual
 union all
	 select 'AMEX Pillar','ZPC','CUBE PI Contra','4','5','AMEXP' from dual
 union all
	 select 'AMEX Pillar','ZPI','CUBE PI Initiating','4','5','AMEXP' from dual
 union all
	 select 'AMEX Pillar','ZPR','CUBE PI - GTX Response','4','5','AMEXP' from dual
 union all
	 select 'AMEX Pillar','ZPRU','CUBE PI - Unrelated Response','4','5','AMEXP' from dual
 union all
	 select 'ARCA Pillar','ZQ','Qualified Contingent Cross (QCC)','4','5','ARCAP' from dual
 union all
	 select 'AMEX Pillar','ZQ','Qualified Contingent Cross (QCC)','4','5','AMEXP' from dual
 union all
	 select 'EDGX Options','ZR','Complex order, Non-Customer/Non-Market Maker (contra Customer), Non-Penny','','8','EDGO' from dual
 union all
	 select 'AMEX Pillar','ZSC','AON CUBE Contra','4','5','AMEXP' from dual
 union all
	 select 'AMEX Pillar','ZSI','AON CUBE Initiating','4','5','AMEXP' from dual
 union all
	 select 'AMEX Pillar','ZSR','AON CUBE - GTX Response','4','5','AMEXP' from dual
 union all
	 select 'AMEX Pillar','ZSRU','AON CUBE - Unrelated Response','4','5','AMEXP' from dual
 union all
	 select 'EDGX Options','ZT','Complex order, Non-Customer/Non-Market Maker (contra Customer), Penny','','8','EDGO' from dual
	 )
select * from ind
) s
ON (t.TRADE_LIQUIDITY_INDICATOR = s."Trade Liq Ind" and t.EXCHANGE_ID = s.exchange_id)
WHEN MATCHED THEN
    UPDATE
    SET t.LIQUIDITY_INDICATOR_TYPE_ID = s."Harrys revised answers"
WHEN NOT MATCHED THEN
    INSERT (EXCHANGE_ID, TRADE_LIQUIDITY_INDICATOR, DESCRIPTION, LIQUIDITY_INDICATOR_TYPE_ID, IS_GREY, CREATE_TIME)
    VALUES (s.exchange_id, s."Trade Liq Ind", s."Description", "Harrys revised answers", 'N', CURRENT_TIMESTAMP);
