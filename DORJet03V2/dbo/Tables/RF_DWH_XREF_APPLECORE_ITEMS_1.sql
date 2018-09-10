CREATE TABLE [dbo].[RF_DWH_XREF_APPLECORE_ITEMS] (
    [item_id]              INT            NOT NULL,
    [item_name]            VARCHAR (1000) NOT NULL,
    [special_meal]         BIT            NULL,
    [discontinued]         BIT            NULL,
    [created_by_id]        INT            NULL,
    [created_on]           DATETIME       NULL,
    [modified_date]        DATETIME       NULL,
    [romance_name]         VARCHAR (500)  NULL,
    [package_type]         VARCHAR (50)   NULL,
    [changed_package_type] VARCHAR (100)  NULL,
    [changed_by]           VARCHAR (100)  NULL,
    PRIMARY KEY CLUSTERED ([item_id] ASC)
);

