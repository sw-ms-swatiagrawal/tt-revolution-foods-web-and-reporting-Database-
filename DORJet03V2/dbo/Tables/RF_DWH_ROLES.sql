CREATE TABLE [dbo].[RF_DWH_ROLES] (
    [role_id]       INT          IDENTITY (1, 1) NOT NULL,
    [role_cd]       VARCHAR (25) NOT NULL,
    [role_nm]       VARCHAR (50) NULL,
    [inserted_date] DATETIME     CONSTRAINT [DF_RF_DWH_ROLES_inserted_date] DEFAULT (getdate()) NOT NULL,
    [inserted_by]   VARCHAR (50) NULL,
    [modified_date] DATETIME     NULL,
    [modified_by]   VARCHAR (50) NULL,
    [deleted_date]  DATETIME     NULL,
    [deleted_by]    VARCHAR (50) NULL,
    CONSTRAINT [PK_RF_DWH_ROLES] PRIMARY KEY CLUSTERED ([role_id] ASC),
    CONSTRAINT [role_nm_unique] UNIQUE NONCLUSTERED ([role_nm] ASC, [deleted_date] ASC)
);

