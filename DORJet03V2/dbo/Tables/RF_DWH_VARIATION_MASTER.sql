CREATE TABLE [dbo].[RF_DWH_VARIATION_MASTER] (
    [variation_id]  INT          IDENTITY (1, 1) NOT NULL,
    [variation_nm]  VARCHAR (50) NOT NULL,
    [order_no]      INT          DEFAULT ((0)) NOT NULL,
    [inserted_date] DATETIME     NULL,
    [inserted_by]   VARCHAR (50) NULL,
    [modified_date] DATETIME     NULL,
    [modified_by]   VARCHAR (50) NULL,
    [deleted_date]  DATETIME     NULL,
    [deleted_by]    VARCHAR (50) NULL,
    CONSTRAINT [PK_RF_DWH_VARIATION_MASTER] PRIMARY KEY CLUSTERED ([variation_id] ASC)
);

