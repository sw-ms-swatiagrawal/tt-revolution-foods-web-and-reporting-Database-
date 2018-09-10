CREATE TABLE [dbo].[RF_DWH_DEVIATION] (
    [deviation_id]  INT      IDENTITY (1, 1) NOT NULL,
    [schedule_id]   INT      NOT NULL,
    [schedule_date] DATETIME NULL,
    [deviation_qty] INT      NULL,
    [accept_reject] INT      NULL,
    CONSTRAINT [PK_RF_DWH_DEVIATION] PRIMARY KEY CLUSTERED ([deviation_id] ASC),
    CONSTRAINT [FK_RF_DWH_DEVIATION_RF_DWH_SCHEDULE] FOREIGN KEY ([schedule_id]) REFERENCES [dbo].[RF_DWH_SCHEDULE] ([schedule_id])
);

