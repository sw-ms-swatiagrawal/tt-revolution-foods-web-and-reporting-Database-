CREATE TABLE [dbo].[RF_DWH_WASTE_TYPE] (
    [waste_type_id] INT          IDENTITY (1, 1) NOT NULL,
    [waste_type_cd] VARCHAR (5)  NULL,
    [waste_type_nm] VARCHAR (50) NOT NULL,
    [inserted_date] DATETIME     NOT NULL,
    [inserted_by]   VARCHAR (50) NOT NULL,
    [modified_date] DATETIME     NULL,
    [modified_by]   VARCHAR (50) NULL,
    [deleted_date]  DATETIME     NULL,
    [deleted_by]    VARCHAR (50) NULL,
    CONSTRAINT [PK_RF_DWH_WASTE_TYPE] PRIMARY KEY CLUSTERED ([waste_type_id] ASC),
    CONSTRAINT [Waste Type Code] UNIQUE NONCLUSTERED ([waste_type_cd] ASC, [deleted_date] ASC),
    CONSTRAINT [Waste Type Name] UNIQUE NONCLUSTERED ([waste_type_nm] ASC, [deleted_date] ASC)
);

