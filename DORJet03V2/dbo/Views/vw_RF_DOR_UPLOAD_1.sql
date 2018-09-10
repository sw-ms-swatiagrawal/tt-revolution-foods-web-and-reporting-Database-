
CREATE VIEW [dbo].[vw_RF_DOR_UPLOAD]
AS

	SELECT a.facility_cd AS facility_cd
		   , CONVERT(VARCHAR, e.schedule_date, 101) AS entry_date
		   , DATEPART(WEEKDAY,e.schedule_date) AS entry_week_day
		   , DATENAME(WEEKDAY,e.schedule_date) AS entry_day
		   , DATENAME(WEEK,e.schedule_date) AS entry_week
		   , MONTH(e.schedule_date) AS entry_month
		   , YEAR(e.schedule_date) AS entry_year
		   , g.shift_nm AS shift_nm
		   , c.line_nm AS line_nm
	  FROM RF_DWH_FACILITY a
	  JOIN RF_DWH_XREF_LINE_FACILITY b
		   JOIN RF_DWH_LINE c
		     ON c.line_id = b.line_id
	    ON a.facility_id = b.facility_id
	  JOIN RF_DWH_SCHEDULE e
	    ON e.line_facility_id = b.line_facility_id
	  JOIN RF_DWH_SHIFT_ENTRY f
	    ON f.schedule_id = e.schedule_id
	  JOIN RF_DWH_SHIFT g
	    ON g.shift_id = e.shift_id
