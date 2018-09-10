CREATE TABLE [dbo].[RF_DWH_WASTEENTRY] (
    [waste_entry_id]            INT          IDENTITY (1, 1) NOT NULL,
    [waste_entry_date]          DATETIME     NULL,
    [shift_id]                  INT          NULL,
    [line_id]                   INT          NULL,
    [item_id]                   INT          NULL,
    [waste_type_id]             INT          NULL,
    [weight]                    FLOAT (53)   NULL,
    [inserted_date]             DATETIME     NOT NULL,
    [inserted_by]               VARCHAR (50) NOT NULL,
    [modified_date]             DATETIME     NULL,
    [modified_by]               VARCHAR (50) NULL,
    [deleted_date]              DATETIME     NULL,
    [deleted_by]                VARCHAR (50) NULL,
    [facility_id]               INT          NULL,
    [item_product_variation_id] INT          NULL,
    CONSTRAINT [PK_RF_DWH_WASTEENTRY] PRIMARY KEY CLUSTERED ([waste_entry_id] ASC),
    CONSTRAINT [FK_RF_DWH_WASTEENTRY_RF_DWH_ITEM] FOREIGN KEY ([item_id]) REFERENCES [dbo].[RF_DWH_ITEM] ([item_id]),
    CONSTRAINT [FK_RF_DWH_WASTEENTRY_RF_DWH_LINE] FOREIGN KEY ([line_id]) REFERENCES [dbo].[RF_DWH_LINE] ([line_id]),
    CONSTRAINT [FK_RF_DWH_WASTEENTRY_RF_DWH_SHIFT] FOREIGN KEY ([shift_id]) REFERENCES [dbo].[RF_DWH_SHIFT] ([shift_id]),
    CONSTRAINT [FK_RF_DWH_WASTEENTRY_RF_DWH_WASTE_TYPE] FOREIGN KEY ([waste_type_id]) REFERENCES [dbo].[RF_DWH_WASTE_TYPE] ([waste_type_id])
);

