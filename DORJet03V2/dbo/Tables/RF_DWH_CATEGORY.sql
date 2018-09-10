﻿CREATE TABLE [dbo].[RF_DWH_CATEGORY] (
    [category_id]   INT          IDENTITY (1, 1) NOT NULL,
    [category_nm]   VARCHAR (50) NOT NULL,
    [inserted_date] DATETIME     NOT NULL,
    [inserted_by]   VARCHAR (50) NOT NULL,
    [modified_date] DATETIME     NULL,
    [modified_by]   VARCHAR (50) NULL,
    [deleted_date]  DATETIME     NULL,
    [deleted_by]    VARCHAR (50) NULL,
    CONSTRAINT [PK_RF_DWH_CATEGORY] PRIMARY KEY CLUSTERED ([category_id] ASC),
    CONSTRAINT [Category Name] UNIQUE NONCLUSTERED ([category_nm] ASC, [deleted_date] ASC)
);

