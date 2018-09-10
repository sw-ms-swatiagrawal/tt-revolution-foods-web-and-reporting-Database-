
CREATE PROCEDURE [dbo].[usp_DOR_BOTTOM_THREE_PERFORMERS_REPORT]    
(    
 @facility_id INT,    
 @date DATETIME,    
 @end_date DATE = NULL,    
 @planned_labor_rate FLOAT = 12.5    
)    
AS    
BEGIN    
  DECLARE @line_id INT =NULL   
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
  change_over VARCHAR(30),re_run_units VARCHAR(30),re_run_labor_cost VARCHAR(30),    
  rr_line_time VARCHAR(30),equip VARCHAR(30),category VARCHAR(30),build_grade VARCHAR(30),    
  planned_labor_1350 VARCHAR(30),planned_labor_rate VARCHAR(30),actual_labor_rate VARCHAR(30),    
  scheduled_line_hours VARCHAR(30),scheduled_labor_hours VARCHAR(30),scheduled_labor_rate VARCHAR(30),  
  applecore_variation_id INT,act_qty  INT  ,nitemseqproduction INT,seq_no_prod INT  , status_desc VARCHAR(50)    
 )    

 --INSERT INTO #tmp_upload_details    
 EXEC usp_DOR_GET_UPLOAD_DETAILS_REPORT @facility_id = @facility_id, @date =  @date, @end_date = @end_date, @line_id = @line_id , @planned_labor_rate = @planned_labor_rate, @all_page = 1;    
    
  --> Bottom Three Performers - Day Shift     
SELECT TOP 3 cast(t.facility_cd AS VARCHAR) as facility_cd    
 , cast(t.shift_nm AS VARCHAR) as shift_nm    
 , cast(t.line_nm AS VARCHAR)   as line_nm    
 , cast(t.item_nm  AS VARCHAR)  as item_nm    
 , cast(t.qty  AS VARCHAR) as qty    
 , cast(t.crew_std  AS VARCHAR)  as crew_std    
 , cast(t.crew_act  AS VARCHAR) as crew_act    
 , cast(t.effic  AS VARCHAR) as effic    
 , cast(prod AS VARCHAR) prod--, t.prod2    
 FROM (    
  SELECT facility_cd, shift_nm, line_nm, item_nm, qty    
    , ROUND(crew_std, 0) AS crew_std    
    , ROUND(crew_act, 0) AS crew_act    
    , CONVERT(DECIMAL(18,0), ROUND((ISNULL(CAST(labor_std AS FLOAT), 0) * 100/ IIF(ISNULL(CAST(labor_act AS FLOAT), 1) = 0 ,1,ISNULL(CAST(labor_act AS FLOAT), 1))), 0)) AS effic    
    , CONVERT(DECIMAL(18,0), ROUND((ISNULL(CAST(line_std AS FLOAT), 0) * 100/ IIF(ISNULL(CAST(line_act AS FLOAT), 1) = 0 , 1 ,ISNULL(CAST(line_act AS FLOAT), 1))), 0)) AS prod    
    , CASE WHEN ISNULL(qty, 0) > 150     
      THEN CONVERT(DECIMAL(18,2), ROUND((ISNULL(CAST(line_std AS FLOAT), 0) * 100/ IIF(ISNULL(CAST(line_act AS FLOAT), 1) = 0 , 1 , ISNULL(CAST(line_act AS FLOAT), 1))), 2))     
      ELSE 0    
      END AS prod2    
  FROM #tmp_upload_details    
 ) AS t    
 WHERE ISNULL(prod2, 0) != 0    
 AND t.shift_nm = 'Day'    
 ORDER BY t.shift_nm, t.prod2    
    
 --> Bottom Three Performers - Night Shift     
  SELECT TOP 3 cast(t.facility_cd AS VARCHAR) as facility_cd    
 , cast(t.shift_nm AS VARCHAR) as shift_nm    
 , cast(t.line_nm AS VARCHAR)   as line_nm    
 , cast(t.item_nm  AS VARCHAR)  as item_nm    
 , cast(t.qty  AS VARCHAR) as qty    
 , cast(t.crew_std  AS VARCHAR)  as crew_std    
 , cast(t.crew_act  AS VARCHAR) as crew_act    
 , cast(t.effic  AS VARCHAR) as effic    
 , cast(prod AS VARCHAR) prod--, t.prod2    
 FROM (    
  SELECT facility_cd, shift_nm, line_nm, item_nm, qty    
    , ROUND(crew_std, 0) AS crew_std    
    , ROUND(crew_act, 0) AS crew_act    
    , CONVERT(DECIMAL(18,0), ROUND((ISNULL(CAST(labor_std AS FLOAT), 0) * 100/   IIF(ISNULL(CAST(labor_act AS FLOAT), 1) = 0 , 1 , ISNULL(CAST(labor_act AS FLOAT), 1))   ), 0)) AS effic    
    , CONVERT(DECIMAL(18,0), ROUND((ISNULL(CAST(line_std AS FLOAT), 0) * 100/  IIF(ISNULL(CAST(line_act AS FLOAT), 1) = 0 , 1 , ISNULL(CAST(line_act AS FLOAT), 1))), 0)) AS prod    
    , CASE WHEN ISNULL(qty, 0) > 150     
      THEN CONVERT(DECIMAL(18,2), ROUND((ISNULL(CAST(line_std AS FLOAT), 0) * 100/ IIF(ISNULL(CAST(line_act AS FLOAT), 1) = 0 , 1 , ISNULL(CAST(line_act AS FLOAT), 1))), 2))     
      ELSE 0    
      END AS prod2    
  FROM #tmp_upload_details    
 ) AS t    
 WHERE ISNULL(prod2, 0) != 0    
 AND t.shift_nm = 'Night'    
 ORDER BY t.shift_nm, t.prod2    
    
END;    

