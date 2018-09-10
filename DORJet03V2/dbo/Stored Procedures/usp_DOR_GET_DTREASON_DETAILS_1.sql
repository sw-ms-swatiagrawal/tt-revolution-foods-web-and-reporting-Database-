
CREATE PROCEDURE [dbo].[usp_DOR_GET_DTREASON_DETAILS]
(
	@reason_id INT = NULL
)
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT a.reason_id, a.reason_cd, a.reason_nm
	FROM dbo.RF_DWH_DTREASON AS a
	WHERE a.reason_id = COALESCE(@reason_id, a.reason_id) 
	AND a.deleted_date IS NULL;

END;




