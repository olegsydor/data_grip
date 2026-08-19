TABLE Blaze7.dbo.TLegs_EDW
ExpirationDate datetime NULL,
	MinDateTime datetime NULL,
	MaxDateTime datetime NULL,
	FirstFillDateTime datetime NULL,
	LastFillDateTime datetime NULL,

Blaze7.dbo.TOrderMisc1_EDW
ReceiveTime datetime2(3) NULL,
GoodTillDate datetime2(3) NULL,
	CATUpdate datetime NULL,
	CallTime datetime NULL,
OrderEventTime datetime2(3) NULL,


Blaze7.dbo.TOrder_EDW (
	CreateDateTime datetime NULL,
	ApprovedDateTime datetime NULL,
	dtClearBookDateTime datetime NULL,
	FirstFillDateTime datetime NULL,
	LastFillDateTime datetime NULL,
	UpdateDateTime datetime NULL,
	CompletedDateTime datetime NULL,
	WriteDateTime datetime NULL,

Blaze7.dbo.TPrices_EDW

Blaze7.dbo.TReports_EDW
TransactionDateTime datetime NULL,
MaturityDate datetime NULL,
TransmitDateTime datetime2(3) NULL,
ManualExecutionTime datetime NULL,
	NYSETOApproveTime datetime NULL,
	NYSETOExecutionTime datetime NULL,
	CallTime datetime NULL,