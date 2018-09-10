CREATE TABLE [dbo].[RF_DWH_GEN_LOG] (
    [id]        INT            IDENTITY (1, 1) NOT NULL,
    [date]      DATETIME       NOT NULL,
    [thread]    VARCHAR (255)  NOT NULL,
    [level]     VARCHAR (20)   NOT NULL,
    [logger]    VARCHAR (255)  NOT NULL,
    [message]   VARCHAR (4000) NOT NULL,
    [exception] VARCHAR (8000) NULL
);

