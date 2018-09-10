CREATE PROCEDURE [dbo].[usp_DOR_LINESHIFT_START_ITEMS]      
(      
 @facility_id INT,      
 @date DATETIME,      
 @end_date DATE = NULL,      
 @planned_labor_rate FLOAT = 12.5      
)      
AS      
BEGIN      
SET NOCOUNT ON;  
 DECLARE @line_id INT =NULL    
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
  applecore_variation_id INT,act_qty  INT ,nitemseqproduction INT,seq_no_prod INT    , status_desc VARCHAR(50)     
 )      
      
 INSERT INTO #tmp_upload_details      
 EXEC usp_DOR_GET_UPLOAD_DETAILS_REPORT @facility_id = @facility_id, @date =  @date, @end_date = @end_date, @line_id = @line_id , @planned_labor_rate = @planned_labor_rate, @all_page = 1;      

	;WITH cte AS (      
  SELECT line_nm, item_nm, shift_nm, col_nms, sf_col      
  FROM (      
   SELECT a.line_nm, a.item_nm, a.shift_nm, a.effic_per, a.prod_per      
   FROM (       
    SELECT x.line_nm, x.item_nm, x.shift_nm,      
     ROUND(CAST(x.labor_std AS FLOAT) * 100/ IIF(isnull(CAST(x.labor_act AS FLOAT),1) = 0 , 1 , isnull(CAST(x.labor_act AS FLOAT),1)) , 2) AS effic_per ,
	 ROUND(CAST(x.line_std AS FLOAT) * 100/ IIF(ISNULL(CAST(x.line_act AS FLOAT),1) = 0 , 1 , ISNULL(CAST(x.line_act AS FLOAT),1)), 2) AS prod_per ,       
     ROW_NUMBER() OVER (PARTITION BY x.line_nm, x.item_nm, x.shift_nm ORDER BY x.entry_date ASC) AS sr_no      
    FROM #tmp_upload_details AS x      
   ) AS a      
   WHERE a.sr_no = 1      
  ) AS t      
  UNPIVOT       
  (      
   sf_col FOR col_nms IN ([effic_per], [prod_per])      
  ) AS upt      
 ),      
 cte_effic AS (       
  SELECT line_nm, item_nm, [Day] AS day_effic_per, [Night] AS night_effic_per      
  FROM (      
   SELECT a.*      
   FROM cte AS a      
   WHERE col_nms = 'effic_per'      
  ) AS t      
  PIVOT       
  (      
   MAX(sf_col) FOR shift_nm IN ([Day], [Night])      
  ) AS p      
 ),      
 cte_prod AS (       
  SELECT p.line_nm, p.item_nm, [Day] AS day_prod_per, [Night] AS night_prod_per      
  FROM (      
   SELECT a.*      
   FROM cte AS a      
   WHERE col_nms = 'prod_per'      
  ) AS t      
  PIVOT       
  (      
   MAX(sf_col) FOR shift_nm IN ([Day], [Night])      
  ) AS p      
 )      
 --SELECT b.* FROM cte_prod AS b      
 SELECT a.line_nm,       
   (CASE WHEN ISNULL(b.day_effic_per, c.day_prod_per) IS NULL THEN NULL ELSE b.item_nm END) AS day_item_nm,       
   CAST(b.day_effic_per AS VARCHAR) AS day_effic_per ,       
   CAST(c.day_prod_per AS VARCHAR) AS day_prod_per,      
   (CASE WHEN ISNULL( b.night_effic_per, c.night_prod_per) IS NULL THEN NULL ELSE c.item_nm END) AS night_item_nm,       
   CAST(b.night_effic_per AS VARCHAR) AS night_effic_per,       
   CAST(c.night_prod_per AS VARCHAR) AS night_prod_per      
 FROM (SELECT DISTINCT x.line_nm, x.item_nm  FROM cte AS x) AS a   
 LEFT JOIN cte_effic AS b      
  ON a.line_nm = b.line_nm      
  AND a.item_nm = b.item_nm      
 LEFT JOIN cte_prod AS c      
  ON a.line_nm = c.line_nm      
  AND a.item_nm = c.item_nm      
END; 
