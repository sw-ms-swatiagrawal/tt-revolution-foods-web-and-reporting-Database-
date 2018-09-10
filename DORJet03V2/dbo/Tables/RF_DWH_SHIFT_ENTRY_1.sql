CREATE TABLE [dbo].[RF_DWH_SHIFT_ENTRY] (
    [shift_entry_id]   INT            IDENTITY (1, 1) NOT NULL,
    [schedule_id]      INT            NOT NULL,
    [start_time]       DATETIME       NULL,
    [stope_time]       DATETIME       NULL,
    [use_break]        BIT            NULL,
    [use_lunch]        BIT            NULL,
    [re_run_units]     INT            NULL,
    [over_run_units]   INT            NULL,
    [crew_size_actual] INT            NULL,
    [comments]         VARCHAR (1000) NULL,
    [inserted_date]    DATETIME       NOT NULL,
    [inserted_by]      VARCHAR (50)   NOT NULL,
    [modified_date]    DATETIME       NULL,
    [modified_by]      VARCHAR (50)   NULL,
    [deleted_date]     DATETIME       NULL,
    [deleted_by]       VARCHAR (50)   NULL,
    CONSTRAINT [PK_RF_DWH_SHIFT_ENTRY] PRIMARY KEY CLUSTERED ([shift_entry_id] ASC),
    CONSTRAINT [FK_RF_DWH_SHIFT_ENTRY_RF_DWH_SCHEDULE] FOREIGN KEY ([schedule_id]) REFERENCES [dbo].[RF_DWH_SCHEDULE] ([schedule_id])
);

