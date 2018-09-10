
CREATE PROCEDURE [dbo].[usp_DOR_GET_LINE_DETAILS]
(
	@LINE_id INT = NULL
)
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT line_id, line_cd, line_nm
	FROM dbo.RF_DWH_LINE
	WHERE line_id = COALESCE(@line_id, line_id) 
	AND deleted_date IS NULL;

END;




