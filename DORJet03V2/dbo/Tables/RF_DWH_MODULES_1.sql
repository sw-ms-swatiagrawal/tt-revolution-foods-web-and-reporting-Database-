CREATE TABLE [dbo].[RF_DWH_MODULES] (
    [module_id]     INT          IDENTITY (1, 1) NOT NULL,
    [module_cd]     VARCHAR (25) NOT NULL,
    [module_nm]     VARCHAR (50) NULL,
    [inserted_date] DATETIME     CONSTRAINT [DF_RF_DWH_MODULES_inserted_date] DEFAULT (getdate()) NOT NULL,
    [inserted_by]   VARCHAR (50) NULL,
    [modified_date] DATETIME     NULL,
    [modified_by]   DATETIME     NULL,
    [deleted_date]  DATETIME     NULL,
    [deleted_by]    VARCHAR (50) NULL,
    CONSTRAINT [PK_RF_DWH_MODULES] PRIMARY KEY CLUSTERED ([module_id] ASC),
    CONSTRAINT [UK_Modules_ModuleCd] UNIQUE NONCLUSTERED ([module_cd] ASC)
);

