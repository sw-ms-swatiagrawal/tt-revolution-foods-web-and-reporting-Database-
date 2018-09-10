CREATE TABLE [dbo].[XREF_USER_FACILITY_ROLES] (
    [user_id]     INT NOT NULL,
    [facility_id] INT NOT NULL,
    [insert_fg]   BIT NULL,
    [update_fg]   BIT NULL,
    [delete_fg]   BIT NULL,
    [is_default]  BIT NULL,
    CONSTRAINT [User And Facility] PRIMARY KEY CLUSTERED ([user_id] ASC, [facility_id] ASC),
    CONSTRAINT [FK_XREF_USER_FACILITY_ROLES_RF_DWH_FACILITY] FOREIGN KEY ([facility_id]) REFERENCES [dbo].[RF_DWH_FACILITY] ([facility_id]),
    CONSTRAINT [FK_XREF_USER_FACILITY_ROLES_RF_DWH_USERS] FOREIGN KEY ([user_id]) REFERENCES [dbo].[RF_DWH_USERS] ([user_id])
);

