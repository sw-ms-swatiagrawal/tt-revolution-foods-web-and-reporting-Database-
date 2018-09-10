CREATE TABLE [dbo].[RF_DWH_USERS] (
    [user_id]             INT              IDENTITY (1, 1) NOT NULL,
    [user_nm]             VARCHAR (50)     NOT NULL,
    [inserted_date]       DATETIME         NOT NULL,
    [inserted_by]         VARCHAR (50)     NOT NULL,
    [modified_date]       DATETIME         NULL,
    [modified_by]         VARCHAR (50)     NULL,
    [deleted_date]        DATETIME         NULL,
    [deleted_by]          VARCHAR (50)     NULL,
    [password]            VARBINARY (1024) NULL,
    [email_id]            VARCHAR (255)    NULL,
    [is_admin]            BIT              NULL,
    [is_active]           BIT              CONSTRAINT [DF_RF_DWH_USER_ISACTIVE] DEFAULT ((1)) NULL,
    [default_facility_id] INT              NULL,
    CONSTRAINT [PK_RF_DWH_USERS] PRIMARY KEY CLUSTERED ([user_id] ASC),
    CONSTRAINT [Email Id] UNIQUE NONCLUSTERED ([email_id] ASC),
    CONSTRAINT [User Name] UNIQUE NONCLUSTERED ([user_nm] ASC, [deleted_date] ASC)
);

