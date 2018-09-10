CREATE TABLE [dbo].[RF_DWH_XREF_LINE_FACILITY] (
    [line_facility_id] INT IDENTITY (1, 1) NOT NULL,
    [line_id]          INT NOT NULL,
    [facility_id]      INT NOT NULL,
    CONSTRAINT [PK_XREF_LINE_FACILITY] PRIMARY KEY CLUSTERED ([line_facility_id] ASC),
    CONSTRAINT [FK_XREF_LINE_FACILITY_RF_DWH_FACLITY] FOREIGN KEY ([facility_id]) REFERENCES [dbo].[RF_DWH_FACILITY] ([facility_id]),
    CONSTRAINT [FK_XREF_LINE_FACILITY_RF_DWH_LINE] FOREIGN KEY ([line_id]) REFERENCES [dbo].[RF_DWH_LINE] ([line_id]),
    CONSTRAINT [Line and Facility] UNIQUE NONCLUSTERED ([line_id] ASC, [facility_id] ASC)
);

