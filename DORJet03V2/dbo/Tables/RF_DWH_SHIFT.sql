CREATE TABLE [dbo].[RF_DWH_SHIFT] (
    [shift_id]      INT          IDENTITY (1, 1) NOT NULL,
    [shift_cd]      VARCHAR (5)  NULL,
    [shift_nm]      VARCHAR (15) NOT NULL,
    [inserted_date] DATETIME     NOT NULL,
    [inserted_by]   VARCHAR (50) NOT NULL,
    [modified_date] DATETIME     NULL,
    [modified_by]   VARCHAR (50) NULL,
    [deleted_date]  DATETIME     NULL,
    [deleted_by]    VARCHAR (50) NULL,
    CONSTRAINT [PK_RF_DWH_SHIFT] PRIMARY KEY CLUSTERED ([shift_id] ASC),
    CONSTRAINT [Shift Code] UNIQUE NONCLUSTERED ([shift_cd] ASC, [deleted_date] ASC),
    CONSTRAINT [Shift Name] UNIQUE NONCLUSTERED ([shift_nm] ASC, [deleted_date] ASC)
);

