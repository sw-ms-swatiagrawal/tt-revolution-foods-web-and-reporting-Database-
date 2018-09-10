
CREATE PROCEDURE [dbo].[usp_DOR_GET_WASTE_TYPE_DETAILS]
(
	@waste_type_id INT = NULL
)
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT a.waste_type_id, a.waste_type_cd, a.waste_type_nm
	FROM dbo.RF_DWH_WASTE_TYPE AS a
	WHERE a.waste_type_id = COALESCE(@waste_type_id, a.waste_type_id) 
	AND a.deleted_date IS NULL;

END;




