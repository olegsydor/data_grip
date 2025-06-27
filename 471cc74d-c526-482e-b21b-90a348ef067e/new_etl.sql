use [so_Blaze7]

CREATE TABLE [dbo].[TOrder_EDW]
(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[SystemID] [varchar](255) NULL,
	[SystemOrderID] [varchar](255) NULL,
	[SystemOrderTypeID] [varchar](255) NULL,
	[OrderID] [uniqueidentifier] NULL,
	[ParentOrderID] [uniqueidentifier] NULL,
	[CancelOrderID] [uniqueidentifier] NULL,
	[ContraOrderID] [uniqueidentifier] NULL,
	[OrigOrderID] [uniqueidentifier] NULL,
	[ReplaceOrderID] [uniqueidentifier] NULL,
	[Status] [varchar](255) NULL,
	[CreateDateTime] [datetime] NULL,
	[ApprovedDateTime] [datetime] NULL,
	[dtClearBookDateTime] [datetime] NULL,
	[FirstFillDateTime] [datetime] NULL,
	[LastFillDateTime] [datetime] NULL,
	[UpdateDateTime] [datetime] NULL,
	[CompletedDateTime] [datetime] NULL,
	[WriteDateTime] [datetime] NULL,
	[UserID] [int] NULL,
	[OwnerID] [int] NULL,
	[PreviousOwnerID] [int] NULL,
	[SendingUserID] [int] NULL,
	[CompanyID] [varchar](255) NULL,
	[DestinationCompanyID] [varchar](255) NULL,
	[ExchangeConnectionID] [char](1) NULL,
	[ContractDesc] [varchar](255) NULL,
	[AssetClass] [varchar](255) NULL,
	[LegCount] [int] NULL,
	[Price] [money] NULL,
	[Quantity] [int] NULL,
	[Filled] [int] NULL,
	[AvgPrice] [decimal](20, 8) NULL,
	[StockQuantity] [bigint] NULL,
	[StockOpenQuantity] [int] NULL,
	[StockFilled] [int] NULL,
	[StockCancelled] [bigint] NULL,
	[OptionQuantity] [int] NULL,
	[OptionOpenQuantity] [int] NULL,
	[OptionFilled] [int] NULL,
	[OptionCancelled] [int] NULL,
	[Invested] [numeric](38, 6) NULL,
	[AccountAlias] [varchar](255) NULL,
	[Account] [varchar](255) NULL,
	[SubAccount] [varchar](255) NULL,
	[SubAccount2] [varchar](255) NULL,
	[subAccount3] [varchar](255) NULL,
	[Comment] [varchar](255) NULL,
	[ForWhom] [varchar](255) NULL,
	[GiveUpFirm] [varchar](60) NULL,
	[CMTAFirm] [varchar](60) NULL,
	[MPID] [varchar](60) NULL,
	[sSTKCLID] [varchar](60) NULL,
	[isCapStrategy] [varchar](255) NULL,
	[isCrossLate] [varchar](255) NULL,
	[isFBSAmexOverRidePrice] [varchar](255) NULL,
	[isFBSAmexRatioSpread] [varchar](255) NULL,
	[isQCC] [varchar](255) NULL,
	[isLinked] [varchar](255) NULL,
	[isTargetedResplsMM] [varchar](255) NULL,
	[isTargetedResponse] [varchar](255) NULL,
	[isAuctionOrder] [varchar](255) NULL,
	[isSolicited] [varchar](255) NULL,
	[isAllorNone] [varchar](255) NULL,
	[isNotHeld] [varchar](255) NULL,
	[isTiedtoStock] [varchar](255) NULL,
	[PriceQualifier] [varchar](255) NULL,
	[TimeInForceCode] [varchar](255) NULL,
	[BoothIDOverride] [varchar](60) NULL,
	[LinkOrderID] [uniqueidentifier] NULL,
	[lTargetResponseID] [varchar](60) NULL,
	[sATPid] [varchar](60) NULL,
	[sCrossBadgeIDs] [varchar](60) NULL,
	[ReasonCode] [varchar](255) NULL,
	[ParentOrderIDINT] [varchar](255) NULL,
	[CancelOrderIDINT] [varchar](255) NULL,
	[ContraOrderIDINT] [varchar](255) NULL,
	[OrigOrderIDINT] [varchar](255) NULL,
	[Generation] [int] NULL,
	[ChildOrders] [int] NULL,
	[Capacity] [varchar](255) NULL,
	[Portfolio] [varchar](255) NULL,
	[ExDestination] [varchar](32) NULL,
	[PrevFillQuantity] [int] NULL,
	[StockPrevFillQuantity] [int] NULL,
	[OptionPrevFillQuantity] [int] NULL,
	[pg_order_id] [bigint] NULL,
	[pg_chain_id] [bigint] NULL,
	[pg_db_create_time] [datetime] NULL,
	[db_create_time] [datetime] NOT NULL,
	[date_id] [int] NULL,
	[pg_entity] [varchar](10) NULL,
	[TradeDate] [date] NULL,
	[order_trade_date_id] [int] NULL,
 CONSTRAINT [PK_TOrder_EDW_SO] PRIMARY KEY ([ID] ASC)
 WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[TOrder_EDW] ADD  DEFAULT (getdate()) FOR [db_create_time]
GO


CREATE TRIGGER [dbo].[ORDER_UPSERT]
    ON [dbo].[TOrder_EDW]
    INSTEAD OF INSERT
    AS
BEGIN
    INSERT INTO [dbo].[TOrder_EDW]
    ( [SystemID]
    , [SystemOrderID]
    , [SystemOrderTypeID]
    , [OrderID]
    , [ParentOrderID]
    , [CancelOrderID]
    , [ContraOrderID]
    , [OrigOrderID]
    , [ReplaceOrderID]
    , [Status]
    , [CreateDateTime]
    , [ApprovedDateTime]
    , [dtClearBookDateTime]
    , [FirstFillDateTime]
    , [LastFillDateTime]
    , [UpdateDateTime]
    , [CompletedDateTime]
    , [WriteDateTime]
    , [UserID]
    , [OwnerID]
    , [PreviousOwnerID]
    , [SendingUserID]
    , [CompanyID]
    , [DestinationCompanyID]
    , [ExchangeConnectionID]
    , [ContractDesc]
    , [AssetClass]
    , [LegCount]
    , [Price]
    , [Quantity]
    , [Filled]
    , [AvgPrice]
    , [StockQuantity]
    , [StockOpenQuantity]
    , [StockFilled]
    , [StockCancelled]
    , [OptionQuantity]
    , [OptionOpenQuantity]
    , [OptionFilled]
    , [OptionCancelled]
    , [Invested]
    , [AccountAlias]
    , [Account]
    , [SubAccount]
    , [SubAccount2]
    , [subAccount3]
    , [Comment]
    , [ForWhom]
    , [GiveUpFirm]
    , [CMTAFirm]
    , [MPID]
    , [sSTKCLID]
    , [isCapStrategy]
    , [isCrossLate]
    , [isFBSAmexOverRidePrice]
    , [isFBSAmexRatioSpread]
    , [isQCC]
    , [isLinked]
    , [isTargetedResplsMM]
    , [isTargetedResponse]
    , [isAuctionOrder]
    , [isSolicited]
    , [isAllorNone]
    , [isNotHeld]
    , [isTiedtoStock]
    , [PriceQualifier]
    , [TimeInForceCode]
    , [BoothIDOverride]
    , [LinkOrderID]
    , [lTargetResponseID]
    , [sATPid]
    , [sCrossBadgeIDs]
    , [ReasonCode]
    , [ParentOrderIDINT]
    , [CancelOrderIDINT]
    , [ContraOrderIDINT]
    , [OrigOrderIDINT]
    , [Generation]
    , [ChildOrders]
    , [Capacity]
    , [Portfolio]
    , [ExDestination]
    , [PrevFillQuantity]
    , [StockPrevFillQuantity]
    , [OptionPrevFillQuantity]
    , [pg_order_id]
    , [pg_chain_id]
    , [pg_db_create_time]
    , [db_create_time]
    , [date_id]
    , [pg_entity]
    , [TradeDate]
    , [order_trade_date_id])
    SELECT [SystemID]
         , [SystemOrderID]
         , [SystemOrderTypeID]
         , [OrderID]
         , [ParentOrderID]
         , [CancelOrderID]
         , [ContraOrderID]
         , [OrigOrderID]
         , [ReplaceOrderID]
         , [Status]
         , [CreateDateTime]
         , [ApprovedDateTime]
         , [dtClearBookDateTime]
         , [FirstFillDateTime]
         , [LastFillDateTime]
         , [UpdateDateTime]
         , [CompletedDateTime]
         , [WriteDateTime]
         , [UserID]
         , [OwnerID]
         , [PreviousOwnerID]
         , [SendingUserID]
         , [CompanyID]
         , [DestinationCompanyID]
         , [ExchangeConnectionID]
         , [ContractDesc]
         , [AssetClass]
         , [LegCount]
         , [Price]
         , [Quantity]
         , [Filled]
         , [AvgPrice]
         , [StockQuantity]
         , [StockOpenQuantity]
         , [StockFilled]
         , [StockCancelled]
         , [OptionQuantity]
         , [OptionOpenQuantity]
         , [OptionFilled]
         , [OptionCancelled]
         , [Invested]
         , [AccountAlias]
         , [Account]
         , [SubAccount]
         , [SubAccount2]
         , [subAccount3]
         , [Comment]
         , [ForWhom]
         , [GiveUpFirm]
         , [CMTAFirm]
         , [MPID]
         , [sSTKCLID]
         , [isCapStrategy]
         , [isCrossLate]
         , [isFBSAmexOverRidePrice]
         , [isFBSAmexRatioSpread]
         , [isQCC]
         , [isLinked]
         , [isTargetedResplsMM]
         , [isTargetedResponse]
         , [isAuctionOrder]
         , [isSolicited]
         , [isAllorNone]
         , [isNotHeld]
         , [isTiedtoStock]
         , [PriceQualifier]
         , [TimeInForceCode]
         , [BoothIDOverride]
         , [LinkOrderID]
         , [lTargetResponseID]
         , [sATPid]
         , [sCrossBadgeIDs]
         , [ReasonCode]
         , [ParentOrderIDINT]
         , [CancelOrderIDINT]
         , [ContraOrderIDINT]
         , [OrigOrderIDINT]
         , [Generation]
         , [ChildOrders]
         , [Capacity]
         , [Portfolio]
         , [ExDestination]
         , [PrevFillQuantity]
         , [StockPrevFillQuantity]
         , [OptionPrevFillQuantity]
         , [pg_order_id]
         , [pg_chain_id]
         , [pg_db_create_time]
         , [db_create_time]
         , [date_id]
         , [pg_entity]
         , [TradeDate]
         , [order_trade_date_id]
    FROM inserted I
    where not exists (select 1 from dbo.TOrder_EDW L where L.OrderID = I.orderid and L.pg_entity = I.pg_entity);
    UPDATE [dbo].[TOrder_EDW]
    SET [SystemID]               = I.SystemID
      , [SystemOrderID]          = I.SystemOrderID
      , [SystemOrderTypeID]      = I.SystemOrderTypeID
      , [OrderID]                = I.OrderID
      , [ParentOrderID]          = I.ParentOrderID
      , [CancelOrderID]          = I.CancelOrderID
      , [ContraOrderID]          = I.ContraOrderID
      , [OrigOrderID]            = I.OrigOrderID
      , [ReplaceOrderID]         = I.ReplaceOrderID
      , [Status]                 = I.Status
      , [CreateDateTime]         = I.CreateDateTime
      , [ApprovedDateTime]       = I.ApprovedDateTime
      , [dtClearBookDateTime]    = I.dtClearBookDateTime
      , [FirstFillDateTime]      = I.FirstFillDateTime
      , [LastFillDateTime]       = I.LastFillDateTime
      , [UpdateDateTime]         = I.UpdateDateTime
      , [CompletedDateTime]      = I.CompletedDateTime
      , [WriteDateTime]          = I.WriteDateTime
      , [UserID]                 = I.UserID
      , [OwnerID]                = I.OwnerID
      , [PreviousOwnerID]        = I.PreviousOwnerID
      , [SendingUserID]          = I.SendingUserID
      , [CompanyID]              = I.CompanyID
      , [DestinationCompanyID]   = I.DestinationCompanyID
      , [ExchangeConnectionID]   = I.ExchangeConnectionID
      , [ContractDesc]           = I.ContractDesc
      , [AssetClass]             = I.AssetClass
      , [LegCount]               = I.LegCount
      , [Price]                  = I.Price
      , [Quantity]               = I.Quantity
      , [Filled]                 = I.Filled
      , [AvgPrice]               = I.AvgPrice
      , [StockQuantity]          = I.StockQuantity
      , [StockOpenQuantity]      = I.StockOpenQuantity
      , [StockFilled]            = I.StockFilled
      , [StockCancelled]         = I.StockCancelled
      , [OptionQuantity]         = I.OptionQuantity
      , [OptionOpenQuantity]     = I.OptionOpenQuantity
      , [OptionFilled]           = I.OptionFilled
      , [OptionCancelled]        = I.OptionCancelled
      , [Invested]               = I.Invested
      , [AccountAlias]           = I.AccountAlias
      , [Account]                = I.Account
      , [SubAccount]             = I.SubAccount
      , [SubAccount2]            = I.SubAccount2
      , [subAccount3]            = I.subAccount3
      , [Comment]                = I.Comment
      , [ForWhom]                = I.ForWhom
      , [GiveUpFirm]             = I.GiveUpFirm
      , [CMTAFirm]               = I.CMTAFirm
      , [MPID]                   = I.MPID
      , [sSTKCLID]               = I.sSTKCLID
      , [isCapStrategy]          = I.isCapStrategy
      , [isCrossLate]            = I.isCrossLate
      , [isFBSAmexOverRidePrice] = I.isFBSAmexOverRidePrice
      , [isFBSAmexRatioSpread]   = I.isFBSAmexRatioSpread
      , [isQCC]                  = I.isQCC
      , [isLinked]               = I.isLinked
      , [isTargetedResplsMM]     = I.isTargetedResplsMM
      , [isTargetedResponse]     = I.isTargetedResponse
      , [isAuctionOrder]         = I.isAuctionOrder
      , [isSolicited]            = I.isSolicited
      , [isAllorNone]            = I.isAllorNone
      , [isNotHeld]              = I.isNotHeld
      , [isTiedtoStock]          = I.isTiedtoStock
      , [PriceQualifier]         = I.PriceQualifier
      , [TimeInForceCode]        = I.TimeInForceCode
      , [BoothIDOverride]        = I.BoothIDOverride
      , [LinkOrderID]            = I.LinkOrderID
      , [lTargetResponseID]      = I.lTargetResponseID
      , [sATPid]                 = I.sATPid
      , [sCrossBadgeIDs]         = I.sCrossBadgeIDs
      , [ReasonCode]             = I.ReasonCode
      , [ParentOrderIDINT]       = I.ParentOrderIDINT
      , [CancelOrderIDINT]       = I.CancelOrderIDINT
      , [ContraOrderIDINT]       = I.ContraOrderIDINT
      , [OrigOrderIDINT]         = I.OrigOrderIDINT
      , [Generation]             = I.Generation
      , [ChildOrders]            = I.ChildOrders
      , [Capacity]               = I.Capacity
      , [Portfolio]              = I.Portfolio
      , [ExDestination]          = I.ExDestination
      , [PrevFillQuantity]       = I.PrevFillQuantity
      , [StockPrevFillQuantity]  = I.StockPrevFillQuantity
      , [OptionPrevFillQuantity] = I.OptionPrevFillQuantity
      , [pg_order_id]            = I.pg_order_id
      , [pg_chain_id]            = I.pg_chain_id
      , [pg_db_create_time]      = I.pg_db_create_time
--      ,[db_create_time] = I.db_create_time
      , [date_id]                = I.date_id
      , [pg_entity]              = I.pg_entity
      , [TradeDate]              = I.TradeDate
      , [order_trade_date_id]    = I.order_trade_date_id
    FROM Inserted I
    WHERE TOrder_EDW.[OrderID] = I.OrderID
      and TOrder_EDW.pg_entity = I.pg_entity;
end;
GO

CREATE INDEX SO_TOrder_EDW_date_id ON [dbo].[TOrder_EDW] ([date_id] ASC) INCLUDE([pg_db_create_time])

CREATE NONCLUSTERED INDEX [SO_TOrder_EDW_OrderID] ON [dbo].[TOrder_EDW] (
	[OrderID] ASC,
	[pg_entity] ASC
)
GO

