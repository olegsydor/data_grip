USE [Blaze7]
GO

INSERT INTO [dbo].[TPrices_EDW]
           ([Status]
           ,[orderidint]
           ,[reportidint]
           ,[OrderID]
           ,[ReportID]
           ,[LegNumber]
           ,[DashSecurityId]
           ,[ContractID]
           ,[UserID]
           ,[ExchangeConnectionID]
           ,[ExchangeName]
           ,[Destination]
           ,[SystemID]
           ,[Generation]
           ,[ULBid]
           ,[ULAsk]
           ,[ULBidSz]
           ,[ULAskSz]
           ,[NBBOBid]
           ,[NBBOAsk]
           ,[NBBOBidSz]
           ,[NBBOAskSz]
           ,[BidA]
           ,[AskA]
           ,[BidSzA]
           ,[AskSzA]
           ,[BidB]
           ,[AskB]
           ,[BidSzB]
           ,[AskSzB]
           ,[BidC]
           ,[AskC]
           ,[BidSzC]
           ,[AskSzC]
           ,[BidI]
           ,[AskI]
           ,[BidSzI]
           ,[AskSzI]
           ,[BidP]
           ,[AskP]
           ,[BidSzP]
           ,[AskSzP]
           ,[BidX]
           ,[AskX]
           ,[BidSzX]
           ,[AskSzX]
           ,[BidQ]
           ,[AskQ]
           ,[BidSzQ]
           ,[AskSzQ]
           ,[BidZ]
           ,[AskZ]
           ,[BidSzZ]
           ,[AskSzZ]
           ,[BidW]
           ,[AskW]
           ,[BidSzW]
           ,[AskSzW]
           ,[BidT]
           ,[AskT]
           ,[BidSzT]
           ,[AskSzT]
           ,[BidM]
           ,[AskM]
           ,[BidSzM]
           ,[AskSzM]
           ,[BidH]
           ,[AskH]
           ,[BidSzH]
           ,[AskSzH]
           ,[BidJ]
           ,[AskJ]
           ,[BidSzJ]
           ,[AskSzJ]
           ,[BidE]
           ,[AskE]
           ,[BidSzE]
           ,[AskSzE]
           ,[BidR]
           ,[AskR]
           ,[BidSzR]
           ,[AskSzR]
           ,[BidD]
           ,[AskD]
           ,[BidSzD]
           ,[AskSzD]
           ,[bidea]
           ,[askea]
           ,[bidszea]
           ,[askszea]
           ,[bidep]
           ,[askep]
           ,[bidszep]
           ,[askszep]
           ,[bidez]
           ,[askez]
           ,[bidszez]
           ,[askszez]
           ,[bidey]
           ,[askey]
           ,[bidszey]
           ,[askszey]
           ,[bidej]
           ,[askej]
           ,[bidszej]
           ,[askszej]
           ,[bidek]
           ,[askek]
           ,[bidszek]
           ,[askszek]
           ,[bideq]
           ,[askeq]
           ,[bidszeq]
           ,[askszeq]
           ,[bideb]
           ,[askeb]
           ,[bidszeb]
           ,[askszeb]
           ,[biden]
           ,[asken]
           ,[bidszen]
           ,[askszen]
           ,[bidex]
           ,[askex]
           ,[bidszex]
           ,[askszex]
           ,[bidei]
           ,[askei]
           ,[bidszei]
           ,[askszei]
           ,[bidec]
           ,[askec]
           ,[bidszec]
           ,[askszec]
           ,[bidem]
           ,[askem]
           ,[bidszem]
           ,[askszem]
           ,[bideu]
           ,[askeu]
           ,[bidszeu]
           ,[askszeu]
           ,[bided]
           ,[asked]
           ,[bidszed]
           ,[askszed]
           ,[pg_order_id]
           ,[pg_chain_id]
           ,[pg_db_create_time]
           ,[db_create_time]
           ,[exec_id]
           ,[date_id]
           ,[pg_entity]
           ,[BidU]
           ,[AskU]
           ,[BidSzU]
           ,[AskSzU]
           ,[BidS]
           ,[AskS]
           ,[BidSzS]
           ,[AskSzS])
     VALUES
           (<Status, varchar(32),>
           ,<orderidint, varchar(32),>
           ,<reportidint, varchar(32),>
           ,<OrderID, uniqueidentifier,>
           ,<ReportID, uniqueidentifier,>
           ,<LegNumber, int,>
           ,<DashSecurityId, varchar(64),>
           ,<ContractID, bigint,>
           ,<UserID, int,>
           ,<ExchangeConnectionID, varchar(16),>
           ,<ExchangeName, varchar(64),>
           ,<Destination, varchar(64),>
           ,<SystemID, int,>
           ,<Generation, int,>
           ,<ULBid, money,>
           ,<ULAsk, money,>
           ,<ULBidSz, int,>
           ,<ULAskSz, int,>
           ,<NBBOBid, money,>
           ,<NBBOAsk, money,>
           ,<NBBOBidSz, int,>
           ,<NBBOAskSz, int,>
           ,<BidA, money,>
           ,<AskA, money,>
           ,<BidSzA, int,>
           ,<AskSzA, int,>
           ,<BidB, money,>
           ,<AskB, money,>
           ,<BidSzB, int,>
           ,<AskSzB, int,>
           ,<BidC, money,>
           ,<AskC, money,>
           ,<BidSzC, int,>
           ,<AskSzC, int,>
           ,<BidI, money,>
           ,<AskI, money,>
           ,<BidSzI, int,>
           ,<AskSzI, int,>
           ,<BidP, money,>
           ,<AskP, money,>
           ,<BidSzP, int,>
           ,<AskSzP, int,>
           ,<BidX, money,>
           ,<AskX, money,>
           ,<BidSzX, int,>
           ,<AskSzX, int,>
           ,<BidQ, money,>
           ,<AskQ, money,>
           ,<BidSzQ, int,>
           ,<AskSzQ, int,>
           ,<BidZ, money,>
           ,<AskZ, money,>
           ,<BidSzZ, int,>
           ,<AskSzZ, int,>
           ,<BidW, money,>
           ,<AskW, money,>
           ,<BidSzW, int,>
           ,<AskSzW, int,>
           ,<BidT, money,>
           ,<AskT, money,>
           ,<BidSzT, int,>
           ,<AskSzT, int,>
           ,<BidM, money,>
           ,<AskM, money,>
           ,<BidSzM, int,>
           ,<AskSzM, int,>
           ,<BidH, money,>
           ,<AskH, money,>
           ,<BidSzH, int,>
           ,<AskSzH, int,>
           ,<BidJ, money,>
           ,<AskJ, money,>
           ,<BidSzJ, int,>
           ,<AskSzJ, int,>
           ,<BidE, money,>
           ,<AskE, money,>
           ,<BidSzE, int,>
           ,<AskSzE, int,>
           ,<BidR, money,>
           ,<AskR, money,>
           ,<BidSzR, int,>
           ,<AskSzR, int,>
           ,<BidD, money,>
           ,<AskD, money,>
           ,<BidSzD, int,>
           ,<AskSzD, int,>
           ,<bidea, money,>
           ,<askea, money,>
           ,<bidszea, int,>
           ,<askszea, int,>
           ,<bidep, money,>
           ,<askep, money,>
           ,<bidszep, int,>
           ,<askszep, int,>
           ,<bidez, money,>
           ,<askez, money,>
           ,<bidszez, int,>
           ,<askszez, int,>
           ,<bidey, money,>
           ,<askey, money,>
           ,<bidszey, int,>
           ,<askszey, int,>
           ,<bidej, money,>
           ,<askej, money,>
           ,<bidszej, int,>
           ,<askszej, int,>
           ,<bidek, money,>
           ,<askek, money,>
           ,<bidszek, int,>
           ,<askszek, int,>
           ,<bideq, money,>
           ,<askeq, money,>
           ,<bidszeq, int,>
           ,<askszeq, int,>
           ,<bideb, money,>
           ,<askeb, money,>
           ,<bidszeb, int,>
           ,<askszeb, int,>
           ,<biden, money,>
           ,<asken, money,>
           ,<bidszen, int,>
           ,<askszen, int,>
           ,<bidex, money,>
           ,<askex, money,>
           ,<bidszex, int,>
           ,<askszex, int,>
           ,<bidei, money,>
           ,<askei, money,>
           ,<bidszei, int,>
           ,<askszei, int,>
           ,<bidec, money,>
           ,<askec, money,>
           ,<bidszec, int,>
           ,<askszec, int,>
           ,<bidem, money,>
           ,<askem, money,>
           ,<bidszem, int,>
           ,<askszem, int,>
           ,<bideu, money,>
           ,<askeu, money,>
           ,<bidszeu, int,>
           ,<askszeu, int,>
           ,<bided, money,>
           ,<asked, money,>
           ,<bidszed, int,>
           ,<askszed, int,>
           ,<pg_order_id, bigint,>
           ,<pg_chain_id, int,>
           ,<pg_db_create_time, datetime,>
           ,<db_create_time, datetime,>
           ,<exec_id, varchar(30),>
           ,<date_id, int,>
           ,<pg_entity, varchar(10),>
           ,<BidU, money,>
           ,<AskU, money,>
           ,<BidSzU, int,>
           ,<AskSzU, int,>
           ,<BidS, money,>
           ,<AskS, money,>
           ,<BidSzS, int,>
           ,<AskSzS, int,>)
GO

