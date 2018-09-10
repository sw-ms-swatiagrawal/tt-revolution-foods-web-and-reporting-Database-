CREATE TABLE [dbo].[Error_log_DOR] (
    [ID]         INT           IDENTITY (1, 1) NOT NULL,
    [Email_from] VARCHAR (50)  NOT NULL,
    [Email_to]   VARCHAR (100) NOT NULL,
    [Subject]    VARCHAR (500) NOT NULL,
    [Body]       VARCHAR (500) NOT NULL,
    [Date_time]  DATETIME      NOT NULL
);

