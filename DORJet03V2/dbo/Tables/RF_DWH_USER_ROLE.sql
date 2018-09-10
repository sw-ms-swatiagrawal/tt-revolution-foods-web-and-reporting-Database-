CREATE TABLE [dbo].[RF_DWH_USER_ROLE] (
    [user_role_id] INT IDENTITY (1, 1) NOT NULL,
    [user_id]      INT NOT NULL,
    [role_id]      INT NOT NULL,
    CONSTRAINT [PK_RF_DWH_User_Role] PRIMARY KEY CLUSTERED ([user_role_id] ASC),
    CONSTRAINT [FK_RF_DWH_User_Role_RF_DWH_ROLES] FOREIGN KEY ([role_id]) REFERENCES [dbo].[RF_DWH_ROLES] ([role_id]),
    CONSTRAINT [FK_RF_DWH_User_Role_RF_DWH_User_Role] FOREIGN KEY ([user_role_id]) REFERENCES [dbo].[RF_DWH_USER_ROLE] ([user_role_id])
);

