
CREATE PROCEDURE [dbo].[usp_DOR_GET_BUILD_GRADE_DETAILS]
	@build_grade_id INT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT a.build_grade_id AS build_grade_id,
		   a.build_grade_nm AS build_grade_nm  
	  FROM RF_DWH_BUILD_GRADE a
	 WHERE 1 = 1
	   AND a.build_grade_id = COALESCE(@build_grade_id,a.build_grade_id)
	   AND a.deleted_date IS NULL
END




