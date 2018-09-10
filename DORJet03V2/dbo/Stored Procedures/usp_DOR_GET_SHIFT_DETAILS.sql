
CREATE PROCEDURE [dbo].[usp_DOR_GET_SHIFT_DETAILS]
(
	@shift_id INT = NULL
)
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT shift_id AS shift_id
		   , shift_cd AS shift_cd
		   , shift_nm AS shift_nm
	FROM dbo.RF_DWH_SHIFT
	WHERE 1 = 1
	  AND shift_id = COALESCE(@shift_id, shift_id) 
	  AND deleted_date IS NULL;

END;




