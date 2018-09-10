
CREATE PROCEDURE [dbo].[usp_DOR_GET_CATEGORY_DETAILS]
	@category_id INT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;

   SELECT a.category_id AS category_id,
		  a.category_nm AS category_nm
     FROM RF_DWH_CATEGORY a
	WHERE 1 = 1
	  AND a.category_id = COALESCE(@category_id,a.category_id)
	  AND a.deleted_date IS NULL
END




