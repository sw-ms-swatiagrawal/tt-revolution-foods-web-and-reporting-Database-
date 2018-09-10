CREATE TABLE [dbo].[RF_DWH_DTDETAILS] (
    [dt_detail_id]              INT          IDENTITY (1, 1) NOT NULL,
    [dt_date]                   DATETIME     NULL,
    [shift_id]                  INT          NULL,
    [line_id]                   INT          NULL,
    [item_id]                   INT          NULL,
    [reason_id]                 INT          NULL,
    [occur]                     INT          NULL,
    [minutes]                   INT          NULL,
    [inserted_date]             DATETIME     NOT NULL,
    [inserted_by]               VARCHAR (50) NOT NULL,
    [modified_date]             DATETIME     NULL,
    [modified_by]               VARCHAR (50) NULL,
    [deleted_date]              DATETIME     NULL,
    [deleted_by]                VARCHAR (50) NULL,
    [facility_id]               INT          NULL,
    [item_product_variation_id] INT          NULL,
    CONSTRAINT [PK_RF_DWH_DTDETAILS] PRIMARY KEY CLUSTERED ([dt_detail_id] ASC),
    CONSTRAINT [FK_RF_DWH_DTDETAILS_RF_DWH_DTREASON] FOREIGN KEY ([reason_id]) REFERENCES [dbo].[RF_DWH_DT_REASON_CATEGORY] ([dt_reason_category_id]),
    CONSTRAINT [FK_RF_DWH_DTDETAILS_RF_DWH_FACILITY_1] FOREIGN KEY ([facility_id]) REFERENCES [dbo].[RF_DWH_FACILITY] ([facility_id]),
    CONSTRAINT [FK_RF_DWH_DTDETAILS_RF_DWH_LINE] FOREIGN KEY ([line_id]) REFERENCES [dbo].[RF_DWH_LINE] ([line_id]),
    CONSTRAINT [FK_RF_DWH_DTDETAILS_RF_DWH_SHIFT] FOREIGN KEY ([shift_id]) REFERENCES [dbo].[RF_DWH_SHIFT] ([shift_id])
);

