CREATE PROCEDURE [dbo].[usp_DOR_GET_SHIFT_ENTRY_DETAILS]        
 @shift_entry_id INT = NULL,        
 @line_id INT = NULL,        
 @facility_id INT,        
 @date DATETIME,        
 @schedule_id INT = NULL        
AS        
BEGIN        
 SET NOCOUNT ON;        
        
 ;WITH CTE1 (shift_entry_id, schedule_id, line_id, facility_id, line_facility_id, start_time,         
    stope_time, use_break, use_lunch, actual_run_time,required_run_time, item_no, item_nm, qty,        
    re_run_units, over_run_units, crew, crew_size_actual,comments, shift_id, shift_cd,   
 shift_nm,line_nm,item_id,item_product_variation_id, variation_nm,applecore_variation_id)        
 AS(        
  SELECT d.shift_entry_id AS shift_entry_id        
    , a.schedule_id AS schedule_id        
    , b.line_id AS line_id        
    , b.facility_id AS facility_id        
    , b.line_facility_id AS line_facility_id        
    , d.start_time AS start_time        
    , d.stope_time AS stope_time        
    , d.use_break AS use_break        
    , d.use_lunch AS use_lunch                          
    , CASE WHEN use_break = 1 AND d.use_lunch = 0 THEN ROUND((CONVERT(DECIMAL(18,8),d.stope_time     
   - d.start_time))*24, 2) - 0.1666        
      WHEN d.use_lunch = 1 AND use_break = 0 THEN ROUND((CONVERT(DECIMAL(18,8),d.stope_time     
    - d.start_time))*24, 2) - 0.50000         
      WHEN d.use_lunch = 1 AND use_break = 1 THEN (( ROUND((CONVERT(DECIMAL(18,8),d.stope_time     
    - d.start_time))*24, 2) - 0.1666 - 0.50000))        
      ELSE ROUND((CONVERT(DECIMAL(18,8),d.stope_time - d.start_time))*24, 2)        
      END AS actual_run_time        
    , CASE WHEN UPPER(e.line_cd) LIKE 'FLOW WRAP%' THEN a.qty/ NULLIF(v.over_wrap_t_max, 0)        
      WHEN UPPER(e.line_cd) LIKE 'SINGLE PRO%' THEN a.qty/ NULLIF(v.pro_seal_single_t_max, 0)        
      WHEN UPPER(e.line_cd) LIKE 'TWIN PRO%' THEN a.qty/ NULLIF(v.pro_seal_twin_t_max, 0)        
      WHEN UPPER(e.line_cd) LIKE 'TABLE' THEN a.qty/ NULLIF(v.table_t_max, 0)        
      END AS required_run_time            
    , c.item_no AS item_no        
    , c.item_nm AS item_nm        
    , a.qty AS qty        
    , d.re_run_units AS re_run_units        
    , d.over_run_units AS over_run_units        
    , CASE WHEN UPPER(e.line_cd) LIKE 'FLOW WRAP%' THEN v.over_wrap_crew        
      WHEN UPPER(e.line_cd) LIKE 'SINGLE PRO%' THEN v.pro_seal_single_crew        
      WHEN UPPER(e.line_cd) LIKE 'TWIN PRO%' THEN v.pro_seal_twin_crew        
      WHEN UPPER(e.line_cd) LIKE 'TABLE' THEN v.table_crew        
      END AS crew        
    , d.crew_size_actual AS crew_size_actual              
    , d.comments AS comments        
    , f.shift_id AS shift_id        
    , f.shift_cd AS shift_cd        
    , f.shift_nm AS shift_nm        
    , e.line_nm AS line_nm         
    ,a.item_id as item_id   
 ,a.item_product_variation_id   
 ,vm.variation_nm  
 ,v.applecore_variation_id       
   FROM RF_DWH_SCHEDULE a     
   Join XREF_ITEM_PRODUCT_VARIATION v on v.item_product_variation_id = a.item_product_variation_id       
   JOIN RF_DWH_XREF_LINE_FACILITY b        
    ON a.line_facility_id = b.line_facility_id        
   JOIN RF_DWH_ITEM c        
    ON a.item_id = c.item_id  And v.applecore_product_id = c.item_no      
   JOIN RF_DWH_LINE e        
    ON e.line_id = b.line_id        
   LEFT JOIN RF_DWH_SHIFT_ENTRY d        
    ON d.schedule_id = a.schedule_id        
   JOIN RF_DWH_SHIFT f        
    ON f.shift_id = a.shift_id   
 LEFT JOIN RF_DWH_VARIATION_MASTER vm        
    ON v.variation_id = vm.variation_id  
   WHERE 1 = 1        
    AND b.line_id = COALESCE(@line_id,b.line_id)        
    AND b.facility_id = @facility_id        
    AND CAST(a.schedule_date AS DATE) = CAST(@date AS DATE)        
    AND a.deleted_date IS NULL       
 AND v.deleted_date IS NULL       
    AND (COALESCE(d.shift_entry_id,0) = COALESCE(@shift_entry_id,COALESCE(shift_entry_id,0)))        
    AND (COALESCE(a.schedule_id,0) = COALESCE(@schedule_id,COALESCE(a.schedule_id,0)))        
 )        
 SELECT shift_entry_id AS shift_entry_id        
   , schedule_id AS schedule_id        
   , line_id AS line_id        
   , facility_id AS facility_id        
   , line_facility_id AS line_facility_id        
   , start_time AS start_time        
   , stope_time AS stope_time        
   , use_break AS use_break        
   , use_lunch AS use_lunch        
   , actual_run_time AS actual_run_time        
   , required_run_time AS required_run_time        
   , item_no AS item_no        
   , item_nm AS item_nm        
   , qty AS qty        
   , re_run_units AS re_run_units        
   , over_run_units AS over_run_units        
   , crew AS size_crew_standard        
   , crew_size_actual AS crew_size_actual        
   , required_run_time * crew AS required_labor_hours        
   , actual_run_time * crew_size_actual AS actual_labor_hours        
   , CASE WHEN qty IS NOT NULL THEN CAST(((required_run_time * crew)/NULLIF((actual_run_time * crew_size_actual), 0)*100)     
  AS DECIMAL(16,2)) ELSE NULL END AS efficiency_per        
   , CASE WHEN qty IS NOT NULL THEN CAST(((required_run_time)/NULLIF(actual_run_time, 0)*100) AS DECIMAL(16,2)) ELSE NULL     
 END AS productivity_per        
   , comments AS comments        
   , shift_id AS shift_id        
   , shift_cd AS shift_cd        
   , shift_nm AS shift_nm        
   , line_nm AS line_nm        
   , item_id as item_id   
   ,item_product_variation_id  
   ,variation_nm  
   ,applecore_variation_id     
  FROM CTE1;        
        
END;    
