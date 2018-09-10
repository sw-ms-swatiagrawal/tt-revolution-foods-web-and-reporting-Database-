
CREATE PROCEDURE [dbo].[usp_DOR_GET_SCHEDULE_DETAILS_backup_18_06_2018]
 @schedule_id INT = NULL,                    
 @facility_id INT,                    
 @date DATETIME,                    
 @line_id INT = NULL,        
 @IsPlanning bit = NULL,  
 @search_tx varchar(max) = NULL                   
AS                    
BEGIN                    
   
      If(@search_tx = '')     
	Begin
		Set @search_tx = NULL
	End                
 IF OBJECT_ID('TEMPDB..#schedule') IS NOT NULL                        
 DROP TABLE  #schedule                      
                   
                    
 CREATE TABLE #schedule                    
 (                    
  schedule_id INT,                    
  line_id INT,                    
  line_facility_id INT,                    
  item_id INT,                    
  shift_id INT,                    
  shift_cd VARCHAR(10),                    
  shift_nm VARCHAR(50),                    
  item_no INT,                    
  item_nm VARCHAR(500),                    
  build_grade_nm VARCHAR(50),                    
  plan_per INT,                    
  per INT,                    
  qty INT,                    
  crew INT,                    
  speed DECIMAL(16,8),                    
  line_hrs DECIMAL(16,8),                    
  schedule_date DATE,                    
  facility_id INT,                    
  seq_no INT,                    
  line_nm VARCHAR(500),                  
   variation_id INT,                      
  variation_nm VARCHAR(500),                      
  item_product_variation_id INT,                      
  start_time Datetime,                      
  end_time Datetime,                      
  act_qty INT ,              
  applecore_variation_id INT,          
  comment varchar(1000) ,        
  production_comment varchar(1000),        
  order_no INT,        
  production_start_time Datetime,                      
  production_end_time Datetime,      
  isproductionchanged bit ,      
  nitemseq INT,      
  re_run_units INT,      
  over_run_units INT,      
  use_break BIT,      
  use_lunch BIT,      
  crew_size_actual INT  ,
    status_id INT,
  status_desc VARCHAR(50)    
   )             
       
 ;WITH CTE1 (facility_id,item_id,line_id,line_nm,line_facility_id, item_no,item_nm,line_cd)--build_grade_id,crew,t_max)                    
 AS                    
 (                    
  SELECT d.facility_id AS facility_id,                    
      c.item_id AS item_id,                    
      d.line_id AS line_id,                    
      e.line_nm AS line_nm,                    
      d.line_facility_id AS line_facility_id,      
   c.item_no AS item_no,                    
      c.item_nm AS item_nm,                     
 e.line_cd as line_cd          
             
    --  CASE WHEN UPPER(e.line_cd) LIKE 'FLOW WRAP%' THEN c.flow_build_grade_id                    
    -- WHEN UPPER(e.line_cd) LIKE 'SINGLE PRO%' THEN c.single_build_grade_id                    
    -- WHEN UPPER(e.line_cd) LIKE 'TWIN PRO%' THEN c.twin_build_grade_id                    
    -- WHEN UPPER(e.line_cd) LIKE 'TABLE' THEN c.table_build_grade_id                    
    --END build_grade_id,                        
    --CASE WHEN UPPER(e.line_cd) LIKE 'FLOW WRAP%' THEN c.over_wrap_crew                    
    -- WHEN UPPER(e.line_cd) LIKE 'SINGLE PRO%' THEN c.pro_seal_single_crew                    
    -- WHEN UPPER(e.line_cd) LIKE 'TWIN PRO%' THEN c.pro_seal_twin_crew                    
    -- WHEN UPPER(e.line_cd) LIKE 'TABLE' THEN c.table_crew                    
    --END crew,                    
    --CASE WHEN UPPER(e.line_cd) LIKE 'FLOW WRAP%' THEN c.over_wrap_t_max                    
    -- WHEN UPPER(e.line_cd) LIKE 'SINGLE PRO%' THEN c.pro_seal_single_t_max                    
    -- WHEN UPPER(e.line_cd) LIKE 'TWIN PRO%' THEN c.pro_seal_twin_t_max                    
    -- WHEN UPPER(e.line_cd) LIKE 'TABLE' THEN c.table_t_max                    
    --END t_max          
                   
FROM RF_DWH_ITEM c       
 JOIN RF_DWH_XREF_LINE_FACILITY d ON d.facility_id = @facility_id                  
    JOIN RF_DWH_LINE e ON e.line_id = d.line_id       
    WHERE 1 = 1 AND c.deleted_date IS NULL AND e.deleted_date IS NULL      
 )                    
 , CTE2 (schedule_id,line_id,line_facility_id,item_id,                  
 shift_id, shift_cd,shift_nm,item_no,                 
 item_nm,line_cd,build_grade_id, crew,t_max,per,qty,                  
  schedule_date,facility_id,seq_no ,line_nm,item_product_variation_id,applecore_variation_id ,comment,isproductionchanged) as                  
  (                  
 SELECT DISTINCT a.schedule_id AS schedule_id,                    
     c.line_id AS line_id,           
     c.line_facility_id AS line_facility_id,                    
     c.item_id AS item_id,                    
     b.shift_id AS shift_id,                    
     b.shift_cd AS shift_cd,                    
     b.shift_nm AS shift_nm,                    
     c.item_no AS item_no,                    
     c.item_nm AS item_nm,                    
  c.line_cd,                  
      CASE WHEN UPPER(c.line_cd) LIKE 'FLOW WRAP%' THEN e.flow_build_grade_id                    
     WHEN UPPER(c.line_cd) LIKE 'SINGLE PRO%' THEN e.single_build_grade_id                    
     WHEN UPPER(c.line_cd) LIKE 'TWIN PRO%' THEN e.twin_build_grade_id                    
     WHEN UPPER(c.line_cd) LIKE 'TABLE' THEN e.table_build_grade_id                    
    END build_grade_id,                        
    CASE WHEN UPPER(c.line_cd) LIKE 'FLOW WRAP%' THEN e.over_wrap_crew                    
     WHEN UPPER(c.line_cd) LIKE 'SINGLE PRO%' THEN e.pro_seal_single_crew                    
     WHEN UPPER(c.line_cd) LIKE 'TWIN PRO%' THEN e.pro_seal_twin_crew                    
     WHEN UPPER(c.line_cd) LIKE 'TABLE' THEN e.table_crew                    
    END crew,      
    CASE WHEN UPPER(c.line_cd) LIKE 'FLOW WRAP%' THEN e.over_wrap_t_max                    
     WHEN UPPER(c.line_cd) LIKE 'SINGLE PRO%' THEN e.pro_seal_single_t_max                    
     WHEN UPPER(c.line_cd) LIKE 'TWIN PRO%' THEN e.pro_seal_twin_t_max                    
     WHEN UPPER(c.line_cd) LIKE 'TABLE' THEN e.table_t_max                    
    END t_max,                     
     --d.build_grade_nm AS build_grade_nm,                    
     --e.plan_per AS plan_per,                    
     a.per AS per,                    
     a.qty AS qty,                    
     --c.crew AS crew,                    
     --(c.t_max / 60.00) AS speed,                    
     --CASE WHEN c.crew IS NOT NULL THEN CAST(((a.qty/c.t_max) * (1.0/a.per)) * 100 AS DECIMAL(16,8))ELSE NULL END AS line_hrs,                    
     a.schedule_date AS schedule_date,                    
     c.facility_id,                    
     a.seq_no  ,                    
     c.line_nm,                  
  e.item_product_variation_id ,              
  e.applecore_variation_id,            
  a.comment ,      
  a.isproductionchanged                
   FROM RF_DWH_SCHEDULE a                    
   LEFT JOIN RF_DWH_SHIFT b  ON a.shift_id = b.shift_id                     
   JOIN CTE1 c ON c.item_id = a.item_id AND c.line_facility_id = (case when @IsPlanning = 1 then a.line_facility_id else a.production_line_facility_id  end)        
   Inner JOIN XREF_ITEM_PRODUCT_VARIATION e on e.item_product_variation_id = a.item_product_variation_id                  
   --LEFT JOIN RF_DWH_BUILD_GRADE d                    
   --  ON d.build_grade_id = e.build_grade_id                    
   --LEFT JOIN RF_DWH_RE_RUN_RATE f                    
   --  ON f.build_grade_id = e.build_grade_id                    
  WHERE 1 = 1                    
    AND c.facility_id = @facility_id                    
    AND CAST(a.schedule_date AS DATE) = CAST(@date AS DATE)                    
    AND a.schedule_id = COALESCE(@schedule_id,a.schedule_id)                    
    AND a.deleted_date IS NULL                    
    --AND d.deleted_date IS NULL                    
    AND e.deleted_date IS NULL          
 And         
 (        
  (@IsPlanning IS NULL AND (a.act_qty IS NOT NULL OR a.qty IS NOT NULL))        
  OR     
  (@IsPlanning = 1 And a.qty IS NOT NULL)        
  OR        
  (@IsPlanning = 0 And a.act_qty IS NOT NULL)        
 )        
)                  
      
      
      
INSERT INTO #schedule (schedule_id, line_id, line_facility_id, item_id,shift_id, shift_cd, shift_nm,                     
 item_no, item_nm, build_grade_nm, plan_per, per, qty, crew, speed, line_hrs, schedule_date,                     
 facility_id, seq_no, line_nm,variation_id, variation_nm,item_product_variation_id,                    
 start_time,end_time,act_qty,applecore_variation_id,comment,production_comment,order_no,        
 production_start_time, production_end_time,isproductionchanged,nitemseq,      
 --re_run,over_run,break_use,lunch_use      
 re_run_units, over_run_units, use_break, use_lunch,crew_size_actual,status_id,status_desc )                        
 SELECT DISTINCT a.schedule_id AS schedule_id,                        
     c.line_id AS line_id,                        
     c.line_facility_id AS line_facility_id,                        
     c.item_id AS item_id,                        
     b.shift_id AS shift_id,                        
     b.shift_cd AS shift_cd,                        
   b.shift_nm AS shift_nm,                        
     c.item_no AS item_no,                        
     c.item_nm AS item_nm,                      
     d.build_grade_nm AS build_grade_nm,                        
     e.plan_per AS plan_per,                        
     a.per AS per,                        
     a.qty AS qty,                        
          
 -- c.crew AS crew,                        
 --(c.t_max / 60.00) AS speed,                        
 --    CASE WHEN c.crew IS NOT NULL THEN CAST(((a.qty/c.t_max) * (1.0/a.per)) * 100 AS DECIMAL(16,8))ELSE NULL END AS line_hrs,                        
 IIF(@IsPlanning = 1,a.ncrewplaning,a.ncrewproduction) as crew,      
 IIF(@IsPlanning = 1,a.nspeedplaning,a.nspeedproduction) as speed,      
 IIF(@IsPlanning = 1,a.nlinehrsplaning,a.nlinehrsproduction) aS  line_hrs,      
 a.schedule_date AS schedule_date,                        
     c.facility_id,                        
     IIF(@IsPlanning = 1 , a.seq_no,a.seq_no_prod) as  seq_no ,                        
     c.line_nm,                      
  g.variation_id,                      
  g.variation_nm,                   
  f.item_product_variation_id,                      
  a.start_time ,                      
  a.end_time,                      
  a.act_qty ,              
  c.applecore_variation_id ,            
  a.comment,        
  a.production_comment,        
  g.order_no,        
  a.production_start_time,                   
  a.production_end_time ,      
  a.isproductionchanged ,      
      
(case when @IsPlanning = 1 then a.nitemseqplaning else a.nitemseqproduction  end),      
      
      
(case when @IsPlanning = 1 then a.re_run_planing else a.re_run_production  end) as re_run_units,      
(case when @IsPlanning = 1 then a.over_run_planing else a.over_run_production  end) as over_run_units,      
(case when @IsPlanning = 1 then a.break_use_planing else a.break_use_production  end) as use_break,      
(case when @IsPlanning = 1 then a.lunch_use_planing else a.lunch_use_production  end) as use_lunch,      
(case when @IsPlanning = 1 then a.crew_size_actual_planing else a.crew_size_actual_production  end) as crew_size_actual  ,    
a.status_id,
s.status_desc 
FROM RF_DWH_SCHEDULE a       
   LEFT JOIN RF_DWH_SHIFT b ON a.shift_id = b.shift_id       
   JOIN CTE2 c ON c.item_id = a.item_id AND c.line_facility_id = (case when @IsPlanning = 1 then a.line_facility_id else a.production_line_facility_id  end)       
   AND c.shift_id = b.shift_id AND c.item_product_variation_id = a.item_product_variation_id       
   LEFT JOIN RF_DWH_BUILD_GRADE d ON d.build_grade_id = c.build_grade_id                        
   LEFT JOIN RF_DWH_RE_RUN_RATE e ON e.build_grade_id = c.build_grade_id                       
   LEFT JOIN XREF_ITEM_PRODUCT_VARIATION f on f.item_product_variation_id = a.item_product_variation_id      
   LEFT JOIN RF_DWH_VARIATION_MASTER g on g.variation_id = f.variation_id   
   LEFT JOIN RF_DWH_STATUS s on a.status_id =s.status_id                    
   WHERE 1 = 1                        
    AND c.facility_id = @facility_id                        
    AND CAST(a.schedule_date AS DATE) = CAST(@date AS DATE)                        
    AND a.schedule_id = COALESCE(@schedule_id,a.schedule_id)                        
    AND a.deleted_date IS NULL                        
    AND d.deleted_date IS NULL                        
    AND e.deleted_date IS NULL                           
 AND f.deleted_date IS NULL             
 And         
 (        
  (@IsPlanning IS NULL AND (a.act_qty IS NOT NULL OR a.qty IS NOT NULL))        
  OR        
  (@IsPlanning = 1 And a.qty IS NOT NULL)        
  OR        
  (@IsPlanning = 0 And a.act_qty IS NOT NULL)        
 )  
 AND (@search_tx is null      
 OR LOWER(c.item_nm) like '%'+ LOWER(@search_tx) +'%'
 OR CAST(c.item_no AS VARCHAR) =  CAST(@search_tx  AS VARCHAR)
 --OR c.line_nm like '%' + @search_tx + '%'        
 OR c.item_no in (Select applecore_product_id From XREF_ITEM_PRODUCT_VARIATION     
 where CAST(applecore_variation_id AS VARCHAR) =  @search_tx and deleted_date IS NULL)    
 --OR c.item_no in (Select applecore_product_id From XREF_ITEM_PRODUCT_VARIATION xiv  
 --inner join RF_DWH_VARIATION_MASTER vmin on vmin.variation_id = xiv.variation_id  
 --where vmin.variation_nm  like '%' + @search_tx + '%' and vmin.deleted_date IS NULL)    
  )              
            
 SELECT schedule_id AS schedule_id,line_id AS line_id,line_facility_id AS line_facility_id,item_id AS item_id,shift_id AS shift_id,                     
     shift_cd AS shift_cd,shift_nm AS shift_nm,item_no AS item_no,item_nm AS item_nm,build_grade_nm AS build_grade_nm,plan_per AS plan_per,                     
     per AS per,qty AS qty,crew AS crew,speed AS speed,line_hrs AS line_hrs,schedule_date AS schedule_date,facility_id AS facility_id,                    
     seq_no,line_nm,variation_id,variation_nm,item_product_variation_id,start_time ,end_time,act_qty,applecore_variation_id,            
  comment,production_comment,order_no,production_start_time ,production_end_time ,isproductionchanged,nitemseq,      
  --re_run,over_run,break_use,lunch_use      
  re_run_units,over_run_units,use_break,use_lunch,crew_size_actual  ,status_id,status_desc     
 FROM #schedule                    
   order by nitemseq,seq_no      
      
;WITH CTE3 (line_id, line_cd, line_nm)                    
 AS                    
 (                    
  SELECT b.line_id AS line_id,b.line_cd AS line_cd,b.line_nm AS line_nm                    
    FROM RF_DWH_XREF_LINE_FACILITY a    
 JOIN RF_DWH_LINE b ON a.line_id = b.line_id                    
   WHERE 1 = 1 AND a.facility_id = @facility_id AND b.deleted_date IS NULL                    
 )                    
 SELECT b.line_id AS line_id, b.line_cd AS line_cd, b.line_nm AS line_nm                    
 --, COUNT(a.schedule_id) AS items    
 ,COUNT(DISTINCT a.item_id) AS items     
 ,CASE @IsPlanning WHEN NULL THEN SUM(isnull(a.qty,0))         
 WHEN 1 THEN SUM(isnull(a.qty,0))         
 WHEN 0 THEN  SUM(isnull(a.act_qty,0))         
 END AS units    
 , MAX(isnull(a.crew,0)) AS crew, SUM(isnull(a.line_hrs,0)) AS line_hrs                    
 , a.facility_id AS facility_id                    
 FROM #schedule a                    
 RIGHT JOIN CTE3 b ON a.line_id = b.line_id                  
 JOIN RF_DWH_LINE c ON b.line_id = c.line_id                           
 GROUP BY a.facility_id, b.line_id, b.line_cd,b.line_nm         
 END; 
