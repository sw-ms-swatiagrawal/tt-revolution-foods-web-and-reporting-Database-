CREATE TABLE [dbo].[RF_DWH_DTREASON] (
    [reason_id]     INT           IDENTITY (1, 1) NOT NULL,
    [reason_cd]     VARCHAR (50)  NULL,
    [reason_nm]     VARCHAR (500) NULL,
    [inserted_date] DATETIME      NOT NULL,
    [inserted_by]   VARCHAR (50)  NOT NULL,
    [modified_date] DATETIME      NULL,
    [modified_by]   VARCHAR (50)  NULL,
    [deleted_date]  DATETIME      NULL,
    [deleted_by]    VARCHAR (50)  NULL,
    CONSTRAINT [PK_RF_DWH_DTREASON] PRIMARY KEY CLUSTERED ([reason_id] ASC)
);

