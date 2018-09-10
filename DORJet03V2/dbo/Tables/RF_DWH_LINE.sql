CREATE TABLE [dbo].[RF_DWH_LINE] (
    [line_id]       INT           IDENTITY (1, 1) NOT NULL,
    [line_cd]       VARCHAR (500) NULL,
    [line_nm]       VARCHAR (500) NOT NULL,
    [inserted_date] DATETIME      NOT NULL,
    [inserted_by]   VARCHAR (50)  NOT NULL,
    [modified_date] DATETIME      NULL,
    [modified_by]   VARCHAR (50)  NULL,
    [deleted_date]  DATETIME      NULL,
    [deleted_by]    VARCHAR (50)  NULL,
    CONSTRAINT [PK_RF_DWH_LINE] PRIMARY KEY CLUSTERED ([line_id] ASC),
    CONSTRAINT [Line Name] UNIQUE NONCLUSTERED ([line_nm] ASC, [deleted_date] ASC)
);

