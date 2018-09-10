CREATE TABLE [dbo].[RF_DWH_ROLES_MODULE] (
    [role_module_id]        INT IDENTITY (1, 1) NOT NULL,
    [role_id]               INT NOT NULL,
    [module_id]             INT NOT NULL,
    [view_fg]               BIT NOT NULL,
    [insert_fg]             BIT NOT NULL,
    [update_fg]             BIT NOT NULL,
    [delete_fg]             BIT NOT NULL,
    [edit_locked_record_fg] BIT DEFAULT ((0)) NOT NULL,
    [add_locked_record_fg]  BIT DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_RF_DWH_ROLES_MODULE] PRIMARY KEY CLUSTERED ([role_module_id] ASC),
    CONSTRAINT [FK_RF_DWH_ROLES_MODULE_RF_DWH_MODULES] FOREIGN KEY ([module_id]) REFERENCES [dbo].[RF_DWH_MODULES] ([module_id]),
    CONSTRAINT [FK_RF_DWH_ROLES_MODULE_RF_DWH_ROLES] FOREIGN KEY ([role_id]) REFERENCES [dbo].[RF_DWH_ROLES] ([role_id])
);

