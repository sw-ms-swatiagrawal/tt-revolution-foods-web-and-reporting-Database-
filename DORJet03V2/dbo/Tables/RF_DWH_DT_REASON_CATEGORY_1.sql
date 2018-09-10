CREATE TABLE [dbo].[RF_DWH_DT_REASON_CATEGORY] (
    [dt_reason_category_id] INT          IDENTITY (1, 1) NOT NULL,
    [dt_reason_cd]          INT          NULL,
    [dt_reason]             VARCHAR (50) NULL,
    [dt_category]           VARCHAR (50) NULL,
    [inserted_date]         DATETIME     NOT NULL,
    [inserted_by]           VARCHAR (50) NOT NULL,
    [modified_date]         DATETIME     NULL,
    [modified_by]           VARCHAR (50) NULL,
    [deleted_date]          DATETIME     NULL,
    [deleted_by]            VARCHAR (50) NULL,
    CONSTRAINT [PK_RF_DWH_DT_REASON_CATEGORY] PRIMARY KEY CLUSTERED ([dt_reason_category_id] ASC),
    CONSTRAINT [Reason] UNIQUE NONCLUSTERED ([dt_reason] ASC, [deleted_date] ASC)
);

