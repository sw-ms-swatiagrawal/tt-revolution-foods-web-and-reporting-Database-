
CREATE PROCEDURE [dbo].[usp_DOR_REP_DTPARETTO]
( 
	@facility_id INT = NULL,
	@line_id INT = NULL,
	@reason_id INT = NULL,
	@date DATETIME = NULL
)
AS
BEGIN
	
	SET NOCOUNT ON;
	
	;WITH CTE (dt_date,facility_id,reason_id,line_id, minutes)
	AS
	(
		SELECT a.dt_date,a.facility_id,a.reason_id,a.line_id,SUM(a.minutes) AS minutes
		  FROM RF_DWH_DTDETAILS a
		 WHERE 1 = 1
		   AND a.deleted_date IS NULL
		   AND a.facility_id = COALESCE(@facility_id,a.facility_id)
		   AND a.dt_date = COALESCE(@date,a.dt_date)
		   AND a.line_id = COALESCE(@line_id,a.line_id)
		   AND a.reason_id = COALESCE(@reason_id,a.reason_id)
		 GROUP BY a.dt_date,a.facility_id,a.reason_id,a.line_id	
	) 
	
	SELECT b.facility_cd,a.dt_date,c.dt_reason,d.line_nm, a.minutes
	  FROM CTE a
	  JOIN RF_DWH_FACILITY b 
	    ON a.facility_id = b.facility_id
	  JOIN RF_DWH_DT_REASON_CATEGORY c
	    ON c.dt_reason_category_id = a.reason_id
	  JOIN RF_DWH_LINE d
	    ON d.line_id = a.line_id
	 WHERE 1 = 1
	   AND b.deleted_date IS NULL
	   AND c.deleted_date IS NULL
	   AND d.deleted_date IS NULL

END;
