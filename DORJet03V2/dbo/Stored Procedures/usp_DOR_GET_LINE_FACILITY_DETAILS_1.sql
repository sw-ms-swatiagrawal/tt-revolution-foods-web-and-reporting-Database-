
CREATE PROCEDURE [dbo].[usp_DOR_GET_LINE_FACILITY_DETAILS]
( 
	@line_facility_id INT = NULL,	
	@line_id INT = NULL,
	@facility_id INT = NULL
)
AS
BEGIN
	
	SET NOCOUNT ON;
	
	SELECT a.line_facility_id, a.line_id, b.line_nm, a.facility_id, c.facility_nm
	FROM dbo.RF_DWH_XREF_LINE_FACILITY AS a	
	JOIN dbo.RF_DWH_LINE AS b
		ON b.line_id = a.line_id	
	JOIN RF_DWH_FACILITY AS c
		ON c.facility_id = a.facility_id
	WHERE b.deleted_date IS NULL
	AND c.deleted_date IS NULL
	AND a.line_facility_id = COALESCE(@line_facility_id, a.line_facility_id)	
	AND b.line_id = COALESCE(@line_id, b.line_id)
	AND c.facility_id = COALESCE(@facility_id, c.facility_id);

END





