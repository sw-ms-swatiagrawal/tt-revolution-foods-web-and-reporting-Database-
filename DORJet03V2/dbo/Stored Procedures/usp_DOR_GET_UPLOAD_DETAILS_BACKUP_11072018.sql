CREATE PROCEDURE [dbo].[usp_DOR_GET_UPLOAD_DETAILS_BACKUP_11072018]        
(        
  @facility_id INT,        
 @date DATETIME,        
 @end_date DATE = NULL,        
 @planned_labor_rate FLOAT = 11.9,        
 @page_no INT = 1,        
 @page_size INT = 50,        
 @all_page BIT = 0    
)        
AS        
BEGIN        
 SET NOCOUNT ON;                 
                
                   
 SET @end_date = ISNULL(@end_date, @date);                  
 SET @all_page = ISNULL(@all_page, 0);                  
                  
 SELECT @page_size = ISNULL(NULLIF(a.tot_row_count, 0), @page_size),                   
   @page_no = CASE WHEN ISNULL(a.tot_row_count, 0) = 0 THEN @page_no ELSE 1 END                  
 FROM (SELECT COUNT(1) AS tot_row_count FROM RF_DWH_ITEM AS x) AS a                  
 WHERE @all_page = 1;                  

SET @page_no = IIF(ISNULL(@page_no,0) = 0,1,@page_no)  
	            
 ;WITH shift_entry AS (                  
  SELECT shift_entry_id AS shift_entry_id, schedule_id AS schedule_id, line_id AS line_id                  
   , facility_id AS facility_id, line_facility_id AS line_facility_id, start_time AS start_time                  
   , stope_time AS stope_time, use_break AS use_break, use_lunch AS use_lunch , actual_run_time AS actual_run_time                  
   , required_run_time AS required_run_time , item_no AS item_no , item_nm AS item_nm , qty AS qty                  
   , re_run_units AS re_run_units , over_run_units AS over_run_units , crew AS size_crew_standard                  
   , crew_size_actual AS crew_size_actual , required_run_time * crew AS required_labor_hours                  
   , actual_run_time * crew_size_actual AS actual_labor_hours                  
   , CASE WHEN act_qty IS NOT NULL AND ISNULl(crew_size_actual,0) > 0 AND ISNULL(actual_run_time,0) > 0 
		  THEN CAST(((required_run_time * crew)/(actual_run_time * crew_size_actual)*100) AS DECIMAL(16,2))              
		  ELSE NULL 
		  END AS efficiency_per                  
   , CASE WHEN act_qty IS NOT NULL AND ISNULl(actual_run_time,0) >  0 
		  THEN CAST(((required_run_time)/(actual_run_time)*100) AS DECIMAL(16,2)) 
		  ELSE NULL 
		  END AS productivity_per                  
   , comments AS comments, shift_id AS shift_id, shift_cd AS shift_cd , shift_nm AS shift_nm                  
   , line_nm AS line_nm ,item_product_variation_id,category_id ,applecore_variation_id, variation_nm , act_qty  ,
   status_desc                  
  FROM (                  
   SELECT a.schedule_id as shift_entry_id , a.schedule_id AS schedule_id, b.line_id AS line_id                  
    , b.facility_id AS facility_id, b.line_facility_id AS line_facility_id                  
    , a.production_start_time AS start_time, a.production_end_time AS stope_time                  
    , a.break_use_production AS use_break, a.lunch_use_production AS use_lunch                                    
    , CASE WHEN a.break_use_production = 1 AND a.lunch_use_production = 0 
		   THEN ROUND((CONVERT(DECIMAL(18,8),a.production_end_time - a.production_start_time))*24, 2) - 0.1666                  
      WHEN a.lunch_use_production = 1 AND a.break_use_production = 0 
	       THEN ROUND((CONVERT(DECIMAL(18,8),a.production_end_time - a.production_start_time))*24, 2) - 0.50000                   
      WHEN a.lunch_use_production = 1 AND a.break_use_production = 1 
	       THEN (( ROUND((CONVERT(DECIMAL(18,8),a.production_end_time - a.production_start_time))*24, 2) - 0.1666 - 0.50000))                  
      ELSE ROUND((CONVERT(DECIMAL(18,8),a.production_end_time - a.production_start_time))*24, 2)                  
      END AS actual_run_time          
    , CASE WHEN UPPER(e.line_cd) LIKE 'FLOW WRAP%' THEN a.act_qty/ (CASE WHEN v.over_wrap_t_max = 0 THEN 1 ELSE v.over_wrap_t_max END)                  
      WHEN UPPER(e.line_cd) LIKE 'SINGLE PRO%' THEN a.act_qty/(CASE WHEN v.pro_seal_single_t_max = 0 THEN 1 ELSE v.pro_seal_single_t_max END)                  
      WHEN UPPER(e.line_cd) LIKE 'TWIN PRO%' THEN a.act_qty/(CASE WHEN v.pro_seal_twin_t_max = 0 THEN 1 ELSE v.pro_seal_twin_t_max END)                  
      WHEN UPPER(e.line_cd) LIKE 'TABLE' THEN a.act_qty/(CASE WHEN v.table_t_max = 0 THEN 1 ELSE v.table_t_max END)                  
      END AS required_run_time                      
    , c.item_no AS item_no, c.item_nm AS item_nm, a.qty AS qty, a.re_run_production AS re_run_units              
    , a.over_run_production AS over_run_units, ISNULL(a.ncrewproduction,0) AS crew           
	, a.crew_size_actual_production AS crew_size_actual	, a.production_comment AS comments                  
	, f.shift_id AS shift_id, f.shift_cd AS shift_cd , f.shift_nm AS shift_nm, e.line_nm AS line_nm
	,a.item_product_variation_id , v.category_id , v.applecore_variation_id, vm.variation_nm, a.act_qty   ,
	s.status_desc                 
   FROM RF_DWH_SCHEDULE a           
   JOIN XREF_ITEM_PRODUCT_VARIATION v on v.item_product_variation_id = a.item_product_variation_id                  
   LEFT Join RF_DWH_VARIATION_MASTER vm on vm.variation_id = v.variation_id          
   JOIN RF_DWH_XREF_LINE_FACILITY b ON a.line_facility_id = b.line_facility_id                  
   JOIN RF_DWH_ITEM c ON a.item_id = c.item_id                  
   JOIN RF_DWH_LINE e ON e.line_id = b.line_id                  
   JOIN RF_DWH_SHIFT f ON f.shift_id = a.shift_id 
   LEFT JOIN RF_DWH_STATUS s ON s.status_id = a.status_id                 
   WHERE 1 = 1                    
    AND b.facility_id = @facility_id AND CAST(a.schedule_date AS DATE) BETWEEN CAST(@date AS DATE) AND CAST(@end_date as Date)                  
    AND a.deleted_date IS NULL AND a.production_start_time IS NOT NULL AND a.production_end_time IS NOT NULL     
	AND s.status_desc = 'Completed'     
  ) AS t                  
  WHERE shift_entry_id IS NOT NULL           
  ANd isnull(act_qty,0) > 0 )                  
 SELECT *              
 FROM (                
 SELECT Distinct CONVERT(VARCHAR,ROW_NUMBER() OVER(ORDER BY entry_date ASC,nitemseqproduction, seq_no_prod)) AS upload_no , CONVERT(VARCHAR,facility_cd) AS facility_cd, CONVERT(VARCHAR,entry_date) AS entry_date                  
   , CONVERT(VARCHAR,entry_week_day) AS entry_week_day, CONVERT(VARCHAR,entry_day) AS entry_day, CONVERT(VARCHAR,entry_week) AS entry_week                  
   , CONVERT(VARCHAR,entry_month) AS entry_month, CONVERT(VARCHAR,entry_year) AS entry_year, CONVERT(VARCHAR,shift_nm) AS shift_nm                  
   , CONVERT(VARCHAR,line_nm) AS line_nm, CONVERT(VARCHAR(max),item_nm) AS item_nm, CONVERT(VARCHAR(max),variation_nm) AS variation_nm                   
   , CONVERT(VARCHAR,qty) AS qty, CONVERT(VARCHAR,CAST(line_act AS DECIMAL(16,2))) AS line_act, CONVERT(VARCHAR,CAST(line_std AS DECIMAL(16,2))) AS line_std                  
   , CONVERT(VARCHAR,CAST(crew_act AS DECIMAL(16,2))) AS crew_act, CONVERT(VARCHAR,CAST(crew_std AS DECIMAL(16,2)))AS crew_std                  
   , CONVERT(VARCHAR,CAST(labor_act AS DECIMAL(16,2))) AS labor_act, CONVERT(VARCHAR,CAST(labor_std  AS DECIMAL(16,2))) AS labor_std                  
   , CONVERT(VARCHAR,dt_mins) AS dt_mins, CONVERT(VARCHAR,waste) AS waste, CONVERT(VARCHAR,over_run) AS over_run
   , CONVERT(VARCHAR,CAST(or_labor_cost AS DECIMAL(16,2))) AS or_labor_cost, CONVERT(VARCHAR,CAST(or_line_time AS DECIMAL(16,2)))  AS or_line_time                  
   , CONVERT(VARCHAR,change_over) AS change_over, CONVERT(VARCHAR,re_run_units) AS re_run_units                  
   , CONVERT(VARCHAR,CAST(re_run_labor_cost AS DECIMAL(16,2))) AS re_run_labor_cost , CONVERT(VARCHAR,CAST(rr_line_time AS DECIMAL(16,2)) ) AS rr_line_time                  
   , CONVERT(VARCHAR,equip )  AS equip , CONVERT(VARCHAR,category )  AS category                  
   , CONVERT(VARCHAR,build_grade )  AS build_grade                  
   , CONVERT(VARCHAR,CAST((labor_std * (SELECT TOP 1 ISNULL(x.plan_per/100.00, 0) FROM RF_DWH_RE_RUN_RATE AS x               
   WHERE x.build_grade_id = t.build_grade_id AND x.deleted_date IS NULL) * 13.5) AS DECIMAL(16,2))) AS planned_labor_1350                  
   , CONVERT(VARCHAR,CAST((labor_std * (SELECT TOP 1 ISNULL(x.plan_per/100.00, 0) FROM RF_DWH_RE_RUN_RATE AS x               
   WHERE x.build_grade_id = t.build_grade_id AND x.deleted_date IS NULL) * ISNULL(@planned_labor_rate, 1)) AS DECIMAL(16,2)))               
   AS planned_labor_rate              
   , CONVERT(VARCHAR,CAST((CASE WHEN t.build_grade IS NULL THEN '' ELSE t.labor_act * ISNULL(@planned_labor_rate, 1) END)               
   AS DECIMAL(16,2))) AS actual_labor_rate                  
   , CONVERT(VARCHAR,CAST(t.scheduled_line_hours AS DECIMAL(16,2)))  AS scheduled_line_hours                  
   , CONVERT(VARCHAR,CAST((CASE WHEN t.item_nm IS NOT NULL THEN (t.crew_std * t.scheduled_line_hours) ELSE NULL END) AS DECIMAL(16,2)))               
   AS scheduled_labor_hours                  
   , CONVERT(VARCHAR,CAST((CASE WHEN t.item_nm IS NOT NULL THEN (t.crew_std * t.scheduled_line_hours) * ISNULL(@planned_labor_rate, 1)              
    ELSE NULL END) AS DECIMAL(16,2))) AS scheduled_labor_rate,            
 applecore_variation_id,  act_qty ,nitemseqproduction, seq_no_prod
  ,status_desc
 FROM (                  
  SELECT a.facility_cd AS facility_cd, e.schedule_id, CONVERT(VARCHAR, e.schedule_date, 101) AS entry_date                  
    , DATEPART(WEEKDAY,e.schedule_date) AS entry_week_day, DATENAME(WEEKDAY,e.schedule_date) AS entry_day                  
    , DATENAME(WEEK,e.schedule_date) AS entry_week, MONTH(e.schedule_date) AS entry_month, YEAR(e.schedule_date) AS entry_year                  
	, g.shift_nm AS shift_nm, c.line_nm AS line_nm, h.item_nm AS item_nm, e.qty AS qty                  
    , f.actual_run_time AS line_act, f.required_run_time AS line_std, f.crew_size_actual AS crew_act                  
    , f.size_crew_standard AS crew_std, f.actual_labor_hours AS labor_act, f.required_labor_hours AS labor_std                  
    , (CASE WHEN c.line_cd IS NULL THEN '' ELSE ISNULL(i.minutes_sum, 0) - ISNULL(j.minutes_sum, 0) END) AS dt_mins                  
    , (CASE WHEN c.line_cd IS NULL THEN '' ELSE ISNULL(k.weight_sum, 0) END) AS waste                  
    , f.over_run_units AS over_run                  
    , (CASE WHEN h.item_id IS NOT NULL THEN                   
			CASE WHEN ISNULL(f.over_run_units,0) = 0  And ISNULL(e.act_qty,0) = 0   THEN 0 
			ELSE 13.5*(((CAST(f.actual_run_time AS DECIMAL(16,2))/CAST(e.act_qty AS DECIMAL(16,2)))              
					*CAST(f.over_run_units AS DECIMAL(16,2)))*CAST(f.crew_size_actual AS DECIMAL(16,2)))	
			END                  
       ELSE 0 
	   END) AS or_labor_cost                  
    , (CASE WHEN h.item_id IS NOT NULL THEN
			CASE WHEN ISNULL(f.over_run_units,0) = 0   And  ISNULL(e.act_qty,0) = 0 THEN 0                  
			ELSE (((CAST(f.actual_run_time AS DECIMAL(16,2))/CAST(e.act_qty AS DECIMAL(16,2)))*f.over_run_units)*f.over_run_units)                  
			END                  
	   ELSE 0 END) AS or_line_time
    , (CASE WHEN h.item_id IS NULL THEN '' ELSE ISNULL(j.minutes_sum, 0) END) AS change_over                  
    , f.re_run_units                  
    , (CASE WHEN h.item_id IS NOT NULL THEN                   
			CASE WHEN  ISNULL(f.re_run_units,0) = 0  And ISNULL(e.act_qty,0) = 0 THEN 0                  
			ELSE 13.5*(((CAST(f.actual_run_time AS DECIMAL(16,2))/CAST(e.act_qty AS DECIMAL(16,2)))*f.re_run_units)*f.crew_size_actual)                  
			END                  
      ELSE 0 END) AS re_run_labor_cost                  
    , (CASE WHEN h.item_id IS NOT NULL THEN                   
		CASE WHEN ISNULL(f.re_run_units,0) = 0  AND  ISNULL(e.act_qty,0) = 0	THEN 0                  
        ELSE (((CAST(f.actual_run_time AS DECIMAL(16,2))/CAST(e.act_qty AS DECIMAL(16,2)))*f.re_run_units))                  
		END                  
      ELSE 0 END) AS rr_line_time                  

    , (CASE WHEN c.line_nm = '' THEN ''                  
			ELSE 
				CASE WHEN UPPER(c.line_cd) = UPPER('Twin Pro Seal') THEN 'Twin'                  
				ELSE CASE WHEN UPPER(c.line_cd) = UPPER('Single Pro Seal') THEN 'Single'                  
					ELSE CASE WHEN UPPER(c.line_cd) = UPPER('Table') THEN 'Table'                  
					ELSE 'Flow'                  
					END                  
				END                  
			END                           
      END) AS equip                  
    , hh.category_nm AS category                  
    , (CASE WHEN  UPPER(c.line_cd) = '' THEN ''                  
			ELSE CASE WHEN UPPER(c.line_cd) = UPPER('Twin Pro Seal')                  
			THEN h2.build_grade_nm                  
			ELSE CASE WHEN UPPER(c.line_cd) = UPPER('Single Pro Seal')                  
			THEN h3.build_grade_nm                  
			ELSE CASE WHEN UPPER(c.line_cd) = UPPER('Table')               
             THEN h4.build_grade_nm                  
             ELSE h5.build_grade_nm                  
            END                  
         END                  
       END                           
     END) AS build_grade                  
                  
    , (CASE WHEN UPPER(c.line_cd) = ''                  
      THEN 0                  
      ELSE CASE WHEN UPPER(c.line_cd) = UPPER('Twin Pro Seal')                  
        THEN h2.build_grade_id                  
        ELSE CASE WHEN UPPER(c.line_cd) = UPPER('Single Pro Seal')                  
THEN h3.build_grade_id                  
          ELSE CASE WHEN UPPER(c.line_cd) = UPPER('Table')                  
             THEN h4.build_grade_id                  
             ELSE h5.build_grade_id                  
            END                  
         END                  
       END                           
     END) AS build_grade_id                  
   , CAST(ISNULL(e.nlinehrsproduction,0) AS DECIMAL(16,2)) AS scheduled_line_hours          
   ,f.applecore_variation_id, f.variation_nm, f.act_qty  , e.seq_no_prod, e.nitemseqproduction                 
    ,status_desc
  FROM RF_DWH_FACILITY a                  
  JOIN RF_DWH_XREF_LINE_FACILITY b ON a.facility_id = b.facility_id AND a.deleted_by IS NULL                  
  JOIN RF_DWH_LINE c ON c.line_id = b.line_id                  
  JOIN RF_DWH_SCHEDULE e ON e.line_facility_id = b.line_facility_id AND e.deleted_by IS NULL                  
  JOIN shift_entry f ON f.schedule_id = e.schedule_id                     
  JOIN RF_DWH_SHIFT g ON g.shift_id = e.shift_id                  
  JOIN RF_DWH_ITEM h ON h.item_id = e.item_id AND f.item_no = h.item_no          
  join XREF_ITEM_PRODUCT_VARIATION v1 on v1.applecore_product_id = h.item_no and v1.deleted_by IS NULL                  
  AND v1.item_product_variation_id = f.item_product_variation_id And f.category_id = v1.category_id            
          
   LEFT JOIN RF_DWH_CATEGORY AS hh ON hh.category_id = v1.category_id AND hh.deleted_by IS NULL                  
   LEFT JOIN RF_DWH_BUILD_GRADE AS h2 ON h2.build_grade_id = v1.twin_build_grade_id AND h2.deleted_by IS NULL                  
   LEFT JOIN RF_DWH_BUILD_GRADE AS h3 ON h3.build_grade_id = v1.single_build_grade_id AND h3.deleted_by IS NULL                  
   LEFT JOIN RF_DWH_BUILD_GRADE AS h4 ON h4.build_grade_id = v1.table_build_grade_id AND h4.deleted_by IS NULL                  
   LEFT JOIN RF_DWH_BUILD_GRADE AS h5 ON h5.build_grade_id = v1.flow_build_grade_id AND h5.deleted_by IS NULL           
   AND h.deleted_by IS NULL                  
  OUTER APPLY(SELECT x.shift_id, x.line_id, x.item_id, SUM(x.minutes) AS minutes_sum                  
       FROM RF_DWH_DTDETAILS AS x                  
       WHERE x.deleted_by IS NULL                
       AND x.shift_id = g.shift_id                  
       AND x.line_id = c.line_id                  
       AND x.item_id = h.item_id                  
    And x.item_product_variation_id = v1.item_product_variation_id                
       GROUP BY x.shift_id, x.line_id, x.item_id) AS i                  
            
  OUTER APPLY
		(SELECT x.shift_id, x.line_id, x.item_id, x.reason_id, SUM(x.minutes) AS minutes_sum                  
			FROM RF_DWH_DTDETAILS AS x
			JOIN RF_DWH_DT_REASON_CATEGORY AS y ON x.reason_id = y.dt_reason_category_id AND y.deleted_by IS NULL                  
			WHERE x.deleted_by IS NULL AND x.shift_id = g.shift_id                  
			AND x.line_id = c.line_id AND x.item_id = h.item_id                  
			AND y.dt_reason = 'Product Changeover - Setup'                  
			GROUP BY x.shift_id, x.line_id, x.item_id, x.reason_id) AS j                  
                   
  OUTER APPLY
	  (	SELECT x.shift_id, x.line_id, x.item_id, SUM(x.weight) AS weight_sum                  
		FROM RF_DWH_WASTEENTRY AS x              
		WHERE x.deleted_by IS NULL AND x.shift_id = g.shift_id                  
		AND x.line_id = c.line_id AND x.item_id = h.item_id                    
		And x.facility_id = @facility_id AND x.item_product_variation_id = v1.item_product_variation_id            
		AND CAST(x.waste_entry_date AS DATE) BETWEEN CAST(@date AS DATE) AND CAST(@end_date as Date)          
		GROUP BY x.shift_id, x.line_id, x.item_id) AS k                  
          
  WHERE a.facility_id = @facility_id                  
    AND CAST(e.schedule_date AS DATE) BETWEEN CAST(@date AS DATE) AND CAST(@end_date as Date)                  
	AND e.production_start_time IS NOT NULL AND e.production_end_time IS NOT NULL        
	ANd isnull(e.act_qty,0) > 0        
) AS t                  
 WHERE 1=1                     
 ORDER BY t.entry_date,nitemseqproduction, seq_no_prod
 OFFSET @page_size * (@page_no - 1) ROWS                  
    FETCH NEXT @page_size ROWS ONLY                   
    ) AS Data         
	 --order by entry_date

	DECLARE @total INT =( SELECT ISNULL(SUM(rds.act_qty) ,0) 
	FROM RF_DWH_SCHEDULE rds 
	JOIN RF_DWH_XREF_LINE_FACILITY b ON rds.line_facility_id = b.line_facility_id
	 WHERE b.facility_id = @facility_id
	and CAST(rds.schedule_date AS DATE) BETWEEN CAST(@date AS DATE) AND CAST(@end_date as Date)    
	AND rds.deleted_date IS NULL )

	SELECT @total AS 'Total Items', ISNULL(SUM(act_qty),0) AS 'Complete Build' 
	from RF_DWH_SCHEDULE rds
	JOIN RF_DWH_XREF_LINE_FACILITY b ON rds.line_facility_id = b.line_facility_id
	 WHERE b.facility_id = @facility_id 
	and status_id IN (SELECT status_id FROM RF_DWH_STATUS WHERE status_desc = 'Completed')
	AND CAST(rds.schedule_date AS DATE) BETWEEN  CAST(@date AS DATE) AND CAST(@end_date as Date)   
	AND rds.deleted_date IS NULL 
END      




--go

--usp_DOR_GET_UPLOAD_DETAILS_BACKUP_11072018             
--  @facility_id =2,        
-- @date ='2018-03-01',        
-- @end_date  = '2018-07-01',        
-- @planned_labor_rate  = 11.9,        
-- @page_no  = 1,        
-- @page_size  = 50,        
-- @all_page  = 1
 
-- --select * from [dbo].[RF_DWH_GEN_LOG] order by date desc


-- <users><user><user_id>70</user_id><user_nm>deletetest1</user_nm><password>123</password><email_id>deletetest1@deletetest1.com</email_id><is_admin>false</is_admin><is_active>true</is_active><deleted_by>superadmin</deleted_by><userrights><role_id>75</role_id><role_nm>FacilityMasterall</role_nm></userrights><default_facility_id>1</default_facility_id></user></users>

-- AddUpdateDeleteVariationMaster
-- System.Data.SqlClient.SqlException (0x80131904): Column name or number of supplied values does not match table definition.     at System.Data.SqlClient.SqlConnection.OnError(SqlException exception, Boolean breakConnection, Action`1 wrapCloseInAction)     at System.Data.SqlClient.TdsParser.ThrowExceptionAndWarning(TdsParserStateObject stateObj, Boolean callerHasConnectionLock, Boolean asyncClose)     at System.Data.SqlClient.TdsParser.TryRun(RunBehavior runBehavior, SqlCommand cmdHandler, SqlDataReader dataStream, BulkCopySimpleResultSet bulkCopyHandler, TdsParserStateObject stateObj, Boolean& dataReady)     at System.Data.SqlClient.SqlDataReader.TryConsumeMetaData()     at System.Data.SqlClient.SqlDataReader.get_MetaData()     at System.Data.SqlClient.SqlCommand.FinishExecuteReader(SqlDataReader ds, RunBehavior runBehavior, String resetOptionsString, Boolean isInternal, Boolean forDescribeParameterEncryption)     at System.Data.SqlClient.SqlCommand.RunExecuteReaderTds(CommandBehavior cmdBehavior, RunBehavior runBehavior, Boolean returnStream, Boolean async, Int32 timeout, Task& task, Boolean asyncWrite, Boolean inRetry, SqlDataReader ds, Boolean describeParameterEncryptionRequest)     at System.Data.SqlClient.SqlCommand.RunExecuteReader(CommandBehavior cmdBehavior, RunBehavior runBehavior, Boolean returnStream, String method, TaskCompletionSource`1 completion, Int32 timeout, Task& task, Boolean& usedCache, Boolean asyncWrite, Boolean inRetry)     at System.Data.SqlClient.SqlCommand.RunExecuteReader(CommandBehavior cmdBehavior, RunBehavior runBehavior, Boolean returnStream, String method)     at System.Data.SqlClient.SqlCommand.ExecuteReader(CommandBehavior behavior, String method)     at System.Data.Common.DbDataAdapter.FillInternal(DataSet dataset, DataTable[] datatables, Int32 startRecord, Int32 maxRecords, String srcTable, IDbCommand command, CommandBehavior behavior)     at System.Data.Common.DbDataAdapter.Fill(DataSet dataSet, Int32 startRecord, Int32 maxRecords, String srcTable, IDbCommand command, CommandBehavior behavior)     at System.Data.Common.DbDataAdapter.Fill(DataSet dataSet)     at RevFoods_DataLayer.SqlHelper.ExecuteDataset(SqlConnection connection, CommandType commandType, String commandText, SqlParameter[] commandParameters) in D:\Projects\RevFoods\RevFood_WebApp\RevFoods_DataLayer\SqlHelper.cs:line 813     at RevFoods_DataLayer.SqlHelper.ExecuteDataset(String connectionString, CommandType commandType, String commandText, SqlParameter[] commandParameters) in D:\Projects\RevFoods\RevFood_WebApp\RevFoods_DataLayer\SqlHelper.cs:line 701     at RevFoods_DataLayer.ReportView.GetDetails(Int32 Facilityid, DateTime Dt, DateTime DtEndDate, Double PlabbedLabourRate, Int32 PageNo, Int32 PageSize) in D:\Projects\RevFoods\RevFood_WebApp\RevFoods_DataLayer\ReportView.cs:line 52  ClientConnectionId:d7f441e0-efdf-4703-ad9f-4d20b7c9c939  Error Number:213,State:7,Class:16
-- DeleteVariation SQL Error :Cannot insert the value NULL into column 'order_no', table 'RevFoodsWebCR.dbo.RF_DWH_VARIATION_MASTER'; column does not allow nulls. UPDATE fails., Variationid :25