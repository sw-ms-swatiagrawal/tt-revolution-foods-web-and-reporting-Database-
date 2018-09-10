CREATE TABLE [dbo].[RF_DWH_RE_RUN_RATE] (
    [re_run_id]      INT          IDENTITY (1, 1) NOT NULL,
    [re_run_type]    VARCHAR (50) NULL,
    [re_run_twin]    INT          NULL,
    [re_run_single]  INT          NULL,
    [re_run_flow]    INT          NULL,
    [build_grade_id] INT          NULL,
    [plan_per]       INT          NULL,
    [inserted_date]  DATETIME     NOT NULL,
    [inserted_by]    VARCHAR (50) NOT NULL,
    [modified_date]  DATETIME     NULL,
    [modified_by]    VARCHAR (50) NULL,
    [deleted_date]   DATETIME     NULL,
    [deleted_by]     VARCHAR (50) NULL,
    CONSTRAINT [PK_RF_DWH_RE_RUN_RATE] PRIMARY KEY CLUSTERED ([re_run_id] ASC),
    CONSTRAINT [Build Grade] UNIQUE NONCLUSTERED ([build_grade_id] ASC, [deleted_date] ASC)
);

