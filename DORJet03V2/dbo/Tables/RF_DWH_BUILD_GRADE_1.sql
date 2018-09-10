CREATE TABLE [dbo].[RF_DWH_BUILD_GRADE] (
    [build_grade_id] INT          IDENTITY (1, 1) NOT NULL,
    [build_grade_nm] VARCHAR (50) NOT NULL,
    [inserted_date]  DATETIME     NOT NULL,
    [inserted_by]    VARCHAR (50) NOT NULL,
    [modified_date]  DATETIME     NULL,
    [modified_by]    VARCHAR (50) NULL,
    [deleted_date]   DATETIME     NULL,
    [deleted_by]     VARCHAR (50) NULL,
    CONSTRAINT [PK_RF_DWH_BUILD_GRADE] PRIMARY KEY CLUSTERED ([build_grade_id] ASC),
    CONSTRAINT [Build Grade Name] UNIQUE NONCLUSTERED ([build_grade_nm] ASC, [deleted_date] ASC)
);

