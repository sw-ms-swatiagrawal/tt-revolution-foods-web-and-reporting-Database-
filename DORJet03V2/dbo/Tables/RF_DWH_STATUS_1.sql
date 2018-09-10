CREATE TABLE [dbo].[RF_DWH_STATUS] (
    [status_id]     INT          IDENTITY (1, 1) NOT NULL,
    [status_desc]   VARCHAR (50) NOT NULL,
    [inserted_by]   VARCHAR (50) NOT NULL,
    [inserted_date] DATETIME     NOT NULL,
    [modified_date] DATETIME     NULL,
    [modified_by]   VARCHAR (50) NULL,
    [deleted_date]  DATETIME     NULL,
    [deleted_by]    VARCHAR (50) NULL,
    CONSTRAINT [PK_RF_DWH_STATUS] PRIMARY KEY CLUSTERED ([status_id] ASC)
);

