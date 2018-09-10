CREATE TABLE [dbo].[RF_DWH_FACILITY] (
    [facility_id]          INT           IDENTITY (1, 1) NOT NULL,
    [facility_cd]          VARCHAR (50)  NOT NULL,
    [facility_nm]          VARCHAR (500) NOT NULL,
    [inserted_date]        DATETIME      NOT NULL,
    [inserted_by]          VARCHAR (50)  NOT NULL,
    [modified_date]        DATETIME      NULL,
    [modified_by]          VARCHAR (50)  NULL,
    [deleted_date]         DATETIME      NULL,
    [deleted_by]           VARCHAR (50)  NULL,
    [shift_start_time]     TIME (2)      NULL,
    [item_break_time]      INT           NULL,
    [variation_break_time] INT           NULL,
    [facility_profit_code] INT           NULL,
    CONSTRAINT [PK_RF_DWH_FACLITY] PRIMARY KEY CLUSTERED ([facility_id] ASC),
    CONSTRAINT [Facility Code] UNIQUE NONCLUSTERED ([facility_cd] ASC, [deleted_date] ASC),
    CONSTRAINT [Facility Name] UNIQUE NONCLUSTERED ([facility_nm] ASC, [deleted_date] ASC)
);

