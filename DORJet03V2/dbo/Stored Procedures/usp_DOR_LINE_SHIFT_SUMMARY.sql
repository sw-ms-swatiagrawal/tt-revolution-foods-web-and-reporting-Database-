CREATE PROCEDURE [dbo].[usp_DOR_LINE_SHIFT_SUMMARY]      
(      
 @facility_id INT,      
 @date DATETIME,      
 @end_date DATE = NULL,      
 @planned_labor_rate FLOAT = 12.5      
)      
AS      
BEGIN      
SET NOCOUNT ON;      
IF OBJECT_ID('tempdb..#tmp_upload_details') IS NOT NULL       
  DROP TABLE #tmp_upload_details;      
CREATE TABLE #tmp_upload_details      
 (      
  upload_no VARCHAR(30),facility_cd VARCHAR(30),entry_date VARCHAR(30),entry_week_day  VARCHAR(30),      
  entry_day VARCHAR(30),entry_week VARCHAR(30),entry_month VARCHAR(30),entry_year VARCHAR(30),      
  shift_nm VARCHAR(30),line_nm VARCHAR(1000),item_nm VARCHAR(1000),variation_nm varchar(30),         
  qty VARCHAR(30),line_act VARCHAR(30),line_std VARCHAR(30),crew_act VARCHAR(30),      
  crew_std VARCHAR(30),labor_act VARCHAR(30),labor_std VARCHAR(30),dt_mins VARCHAR(30),      
  waste VARCHAR(30),over_run VARCHAR(30),or_labor_cost VARCHAR(30),or_line_time VARCHAR(30),      
  change_over VARCHAR(30),re_run_units VARCHAR(30),re_run_labor_cost VARCHAR(30),rr_line_time VARCHAR(30),      
  equip VARCHAR(30),category VARCHAR(30),build_grade VARCHAR(30),planned_labor_1350 VARCHAR(30),      
  planned_labor_rate VARCHAR(30),actual_labor_rate VARCHAR(30),scheduled_line_hours VARCHAR(30),      
  scheduled_labor_hours VARCHAR(30),scheduled_labor_rate VARCHAR(30),applecore_variation_id INT,     
  act_qty  INT ,nitemseqproduction INT, seq_no_prod INT , status_desc VARCHAR(50) 
 )      
      
 INSERT INTO #tmp_upload_details      
 EXEC usp_DOR_GET_UPLOAD_DETAILS_REPORT @facility_id = @facility_id, @date =  @date, @end_date = @end_date, @planned_labor_rate = @planned_labor_rate, @all_page = 1;      
        
 ;WITH cte AS (      
  SELECT line_nm, SUM(CAST(qty AS FLOAT)) AS sum_qty      
  FROM #tmp_upload_details      
  GROUP BY line_nm      
 ),      
 cte_line_std AS (      
  SELECT p.line_nm, [Day] AS day_line_std, [Night] AS night_line_std      
  FROM (      
   SELECT line_nm,shift_nm, SUM(CAST(line_std AS FLOAT)) AS sum_line_std      
   FROM #tmp_upload_details      
   GROUP BY line_nm,shift_nm      
  ) AS t      
  PIVOT      
  (      
   MAX(sum_line_std) FOR shift_nm IN ([Day], [Night])      
  ) AS p      
 ),      
 cte_line_act AS (      
  SELECT p.line_nm, [Day] AS day_line_act, [Night] AS night_line_act      
  FROM (      
   SELECT line_nm,shift_nm, SUM(CAST(line_act AS FLOAT)) AS sum_line_act      
   FROM #tmp_upload_details      
   GROUP BY line_nm,shift_nm      
  ) AS t      
  PIVOT      
  (      
   MAX(sum_line_act) FOR shift_nm IN ([Day], [Night])      
  ) AS p      
 ),      
 cte_labor_std AS (      
  SELECT p.line_nm, [Day] AS day_labor_std, [Night] AS night_labor_std      
  FROM (      
   SELECT line_nm,shift_nm, SUM(CAST(labor_std AS FLOAT)) AS sum_labor_std      
   FROM #tmp_upload_details      
   GROUP BY line_nm,shift_nm      
  ) AS t      
  PIVOT      
  (      
   MAX(sum_labor_std) FOR shift_nm IN ([Day], [Night])      
  ) AS p      
 ),      
 cte_labor_act AS (      
  SELECT a.line_nm, a.day_labor_act, a.night_labor_act      
   , CONVERT(DECIMAL(18,2), ROUND(((a.day_labor_act * ISNULL(@planned_labor_rate, 1))/IIF(ISNULL(b.sum_qty, 1) = 0 , 1 , ISNULL(b.sum_qty, 1))), 2)) day_dollor_per_meal      
   , CONVERT(DECIMAL(18,2), ROUND(((a.night_labor_act * ISNULL(@planned_labor_rate, 1))/ IIF(ISNULL(b.sum_qty, 1) = 0 , 1 , ISNULL(b.sum_qty, 1))), 2)) night_dollor_per_meal      
  FROM (      
   SELECT p.line_nm, [Day] AS day_labor_act, [Night] AS night_labor_act      
   FROM (      
    SELECT line_nm,shift_nm, SUM(CAST(labor_act AS FLOAT)) AS sum_labor_act      
    FROM #tmp_upload_details      
    GROUP BY line_nm,shift_nm      
   ) AS t      
   PIVOT      
   (      
    MAX(sum_labor_act) FOR shift_nm IN ([Day], [Night])      
   ) AS p      
  ) AS a      
  JOIN cte AS b      
   ON a.line_nm = b.line_nm      
 ),      
 cte_target AS (       
  SELECT p.line_nm, [Day] AS day_target, [Night] AS night_target      
  FROM (      
   SELECT line_nm,shift_nm, SUM(CAST(planned_labor_rate AS FLOAT)) AS sum_target      
   FROM #tmp_upload_details      
   GROUP BY line_nm,shift_nm      
  ) AS t      
  PIVOT      
  (      
   MAX(sum_target) FOR shift_nm IN ([Day], [Night])      
  ) AS p      
 )      
 SELECT t.line_nm,       
  CAST(t.day_line_std AS VARCHAR) AS day_line_std,       
  CAST(t.day_line_act AS VARCHAR) AS day_line_act,       
  CAST(t.day_prod AS VARCHAR) AS day_prod,       
  CAST(t.day_labor_std AS VARCHAR) AS day_labor_std,       
  CAST(t.day_labor_act AS VARCHAR) AS day_labor_act,       
  CAST(t.day_effic AS VARCHAR) AS day_effic,       
  CAST(t.day_target AS VARCHAR) AS day_target,       
  CAST(t.day_dollor_per_meal AS VARCHAR) AS day_dollor_per_meal,       
  CAST(t.night_line_std AS VARCHAR) AS night_line_std,       
  CAST(t.night_line_act AS VARCHAR) AS night_line_act,       
  CAST(t.night_prod AS VARCHAR) AS night_prod,       
  CAST(t.night_labor_std AS VARCHAR) AS night_labor_std,       
  CAST(t.night_labor_act AS VARCHAR) AS night_labor_act,       
  CAST(t.night_effic AS VARCHAR) AS night_effic,       
  CAST(t.night_target AS VARCHAR) AS night_target,       
  CAST(t.night_dollor_per_meal AS VARCHAR) AS night_dollor_per_meal,      
  CAST(t.total_line_std AS VARCHAR) AS total_line_std,       
  CAST(t.total_line_act AS VARCHAR) AS total_line_act,       
  CAST(CONVERT(DECIMAL(18,0), ROUND((ISNULL(t.total_line_std, 0) * 100/ ISNULL(CASE WHEN t.total_line_act = 0 THEN 1 ELSE t.total_line_act END , 1)), 0)) AS VARCHAR) AS total_prod,      
  CAST(t.total_labor_std AS VARCHAR) AS total_labor_std,       
  CAST(t.total_labor_act AS VARCHAR) AS total_labor_act,       
  CAST(CONVERT(DECIMAL(18,0), ROUND((ISNULL(t.total_labor_std, 0) * 100/ ISNULL(CASE WHEN t.total_line_act = 0 THEN 1 ELSE t.total_line_act END, 1)), 0)) AS VARCHAR) AS total_effic,      
  CAST(t.total_target AS VARCHAR) AS total_target,       
  CAST(t.total_dollor_per_meal AS VARCHAR) AS total_dollor_per_meal      
 FROM (      
  SELECT a.line_nm,       
   b.day_line_std, c.day_line_act, CONVERT(DECIMAL(18,0), ROUND((ISNULL(b.day_line_std, 0) * 100/ ISNULL(CASE WHEN c.day_line_act = 0 THEN 1 ELSE c.day_line_act END, 1)), 0)) AS day_prod,      
   d.day_labor_std, e.day_labor_act, CONVERT(DECIMAL(18,0), ROUND((ISNULL(d.day_labor_std, 0) * 100/ ISNULL(CASE WHEN e.day_labor_act = 0 THEN 1 ELSE e.day_labor_act END, 1)), 0)) AS day_effic,      
   f.day_target, e.day_dollor_per_meal,      
       
   b.night_line_std, c.night_line_act, CONVERT(DECIMAL(18,0), ROUND((ISNULL(b.night_line_std, 0) * 100/ ISNULL(CASE WHEN c.night_line_act = 0 THEN 1 ELSE c.night_line_act END, 1)), 0)) AS night_prod,      
   d.night_labor_std, e.night_labor_act, CONVERT(DECIMAL(18,0), ROUND((ISNULL(d.night_labor_std, 0) * 100/ ISNULL(CASE WHEN e.night_labor_act = 0 THEN 1 ELSE e.night_labor_act END , 1)), 0)) AS night_effic,      
   f.night_target, e.night_dollor_per_meal,      
      
   (ISNULL(b.day_line_std, 0) + ISNULL(b.night_line_std, 0)) AS total_line_std,      
   (ISNULL(c.day_line_act, 0) + ISNULL(c.night_line_act, 0)) AS total_line_act,      
        
   (ISNULL(d.day_labor_std, 0) + ISNULL(d.night_labor_std, 0)) AS total_labor_std,      
   (ISNULL(e.day_labor_act, 0) + ISNULL(e.night_labor_act, 0)) AS total_labor_act,      
      
   (ISNULL(f.day_target, 0) + ISNULL(f.night_target, 0)) AS total_target,      
   (ISNULL(e.day_dollor_per_meal, 0) + ISNULL(e.night_dollor_per_meal, 0)) AS total_dollor_per_meal      
  FROM cte AS a      
  LEFT JOIN cte_line_std AS b      
   ON a.line_nm = b.line_nm      
  LEFT JOIN cte_line_act AS c      
   ON a.line_nm = c.line_nm      
  LEFT JOIN cte_labor_std AS d      
   ON a.line_nm = d.line_nm      
  LEFT JOIN cte_labor_act AS e      
   ON a.line_nm = e.line_nm      
  LEFT JOIN cte_target AS f      
   ON a.line_nm = f.line_nm      
 ) AS t      
      
END;      
