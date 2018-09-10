
CREATE PROCEDURE [dbo].[usp_DOR_GET_REASON_CATEGORY_DETAILS]
(
	@dt_reason_category_id INT = NULL
)
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT a.dt_reason_category_id AS dt_reason_category_id
			, a.dt_reason_cd AS dt_reason_cd
			, a.dt_reason AS dt_reason
			, a.dt_category AS dt_category
	  FROM dbo.RF_DWH_DT_REASON_CATEGORY AS a
	 WHERE 1 = 1
	  AND a.dt_reason_category_id = COALESCE(@dt_reason_category_id, a.dt_reason_category_id) 
	  AND a.deleted_date IS NULL;

END;




