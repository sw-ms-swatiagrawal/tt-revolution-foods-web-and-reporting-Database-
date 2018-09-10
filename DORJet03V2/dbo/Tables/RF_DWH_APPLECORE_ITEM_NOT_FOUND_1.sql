CREATE TABLE [dbo].[RF_DWH_APPLECORE_ITEM_NOT_FOUND] (
    [item_not_id] NUMERIC (18)  IDENTITY (1, 1) NOT NULL,
    [schedule_dt] DATETIME      NULL,
    [item_no]     VARCHAR (50)  NULL,
    [variationID] INT           NULL,
    [item_nm]     VARCHAR (500) NULL,
    [facility_id] INT           NULL,
    [qty]         INT           NULL,
    CONSTRAINT [PK_RF_DWH_APPLECORE_ITEM_NOT_FOUND] PRIMARY KEY CLUSTERED ([item_not_id] ASC)
);

