
CREATE PROCEDURE [dbo].[usp_DOR_GET_RE_RUN_DETAILS]
(
	@re_run_id INT = NULL
)
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT a.re_run_id AS re_run_id,
		   a.re_run_type AS re_run_type, 
		   a.re_run_twin AS re_run_twin,
		   a.re_run_single AS re_run_single,
		   a.re_run_flow AS re_run_flow,
		   a.build_grade_id AS build_grade_id,
		   b.build_grade_nm AS build_grade_nm,
		   a.plan_per AS plan_per
	FROM RF_DWH_RE_RUN_RATE a
	JOIN RF_DWH_BUILD_GRADE b
	  ON a.build_grade_id = b.build_grade_id
	WHERE 1 = 1
	  AND a.re_run_id = COALESCE(@re_run_id, a.re_run_id) 
	  AND a.deleted_date IS NULL;

END;




