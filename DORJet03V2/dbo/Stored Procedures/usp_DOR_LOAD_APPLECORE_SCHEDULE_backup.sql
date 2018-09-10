CREATE PROCEDURE [dbo].[usp_DOR_LOAD_APPLECORE_SCHEDULE_backup]      
AS      
BEGIN      
 DECLARE @max_schedule_date DATETIME      
 DECLARE @min_schedule_date DATETIME      
 DECLARE @xml XML , @error_message VARCHAR(MAX)      
      
 BEGIN TRANSACTION      
 BEGIN TRY
	
	Declare @nyj_facility_id int
	Select @nyj_facility_id = facility_id from RF_DWH_FACILITY where LOWER(facility_cd) = 'nyj' and deleted_date IS NULL
	Update  AppleCore_Stage Set facility_id = @nyj_facility_id ,facility_cd = 'NYJ' where LOWER(facility_cd) = 'dmv'

	IF OBJECT_ID('TEMPDB..#schedule') IS NOT NULL      
   DROP TABLE  #schedule      
      
  ;WITH CTE (facility_id,shift_id, [item_id], [item_no],qty,[schedule_date],line_cd,build_grade_id,variationID,default_line_id)      
  AS      
  (      
   SELECT b.facility_id AS facility_id           
		, e.shift_id AS shift_id      
		, c.item_id AS [item_id]           
		, c.item_no AS [item_no]           
		, a.qty AS qty      
		, a.schedule_dt AS [schedule_date]      
		, (      
		  CASE WHEN pv.over_wrap_crew  IS NOT NULL THEN UPPER('Flow Wrap')      
			WHEN pv.pro_seal_single_crew  IS NOT NULL THEN UPPER('Single Pro Seal')      
			WHEN pv.pro_seal_twin_crew IS NOT NULL THEN UPPER('Twin Pro Seal')      
			WHEN pv.table_crew IS NOT NULL THEN UPPER('Table')      
		  END      
		)AS line_cd      
		 ,(      
		  CASE WHEN pv.over_wrap_crew  IS NOT NULL THEN pv.flow_build_grade_id      
		   WHEN pv.pro_seal_single_crew  IS NOT NULL THEN pv.single_build_grade_id      
		   WHEN pv.pro_seal_twin_crew IS NOT NULL THEN pv.twin_build_grade_id      
		   WHEN pv.table_crew IS NOT NULL THEN pv.table_build_grade_id      
		  END      
		 ) AS  build_grade_id    
	  ,a.variationID,pv.default_line_id    
        
     FROM [AppleCore_Stage] a      
     JOIN RF_DWH_FACILITY b ON UPPER(b.facility_cd) = UPPER(a.facility_cd)           
     JOIN RF_DWH_ITEM c ON c.item_no = a.item_no      
     LEFT JOIN RF_DWH_SHIFT e ON e.shift_cd = 'D'  
	 Left join XREF_ITEM_PRODUCT_VARIATION pv on pv.applecore_product_id = c.item_no 
	 and pv.applecore_variation_id = a.variationID    
     WHERE 1 = 1      
     AND b.deleted_date IS NULL AND c.deleted_date IS NULL AND e.deleted_date IS NULL          
  ),      
  CTE1  (line_id, line_cd, line_nm, sequ_no)      
  AS      
  (      
	 SELECT lm.line_id,lm.line_cd,lm.line_nm, ROW_NUMBER() OVER(PARTITION BY lm.line_cd ORDER BY lm.line_nm) sequ_no      
     FROM RF_DWH_LINE lm
	 WHERE 1 = 1 
	 AND deleted_by IS NULL      
  )      
  SELECT COALESCE(a.default_line_id,b.line_id) AS line_id      
	--a.default_line_id as line_id
    ,a.facility_id AS facility_id      
    ,c.line_facility_id AS line_facility_id      
    ,a.shift_id AS shift_id      
    ,a.item_id AS item_id      
    , AVG(d.plan_per)  AS per      
    , SUM(CAST(a.qty AS INT)) AS qty      
    ,a.schedule_date AS schedule_date      
	,a.variationID    
	,a.item_no    
	,v.item_product_variation_id    
    INTO #schedule      
    FROM CTE a      
    JOIN CTE1 b ON UPPER(a.line_cd) = UPPER(b.line_cd) AND b.sequ_no = 1      
    JOIN RF_DWH_XREF_LINE_FACILITY c ON c.facility_id = a.facility_id AND c.line_id = COALESCE(a.default_line_id,b.line_id) --a.default_line_id
    JOIN RF_DWH_RE_RUN_RATE d ON d.build_grade_id = a.build_grade_id       
    Left join  XREF_ITEM_PRODUCT_VARIATION v on v.applecore_product_id = a.item_no and a.variationID = v.applecore_variation_id    

	GROUP BY a.default_line_id, 
	b.line_id,  a.facility_id, c.line_facility_id, a.shift_id,a.item_id, a.schedule_date,a.variationID ,a.item_no,v.item_product_variation_id    
    
	
	
	SELECT @max_schedule_date = MAX(schedule_date)      
      ,@min_schedule_date = MIN(schedule_date)       
    FROM #schedule       
      
  IF OBJECT_ID('TEMPDB..#insert_schedule') IS NOT NULL      
   DROP TABLE  #insert_schedule      
      
  SELECT b.schedule_id AS schedule_id      
      ,a.line_id AS line_id      
      ,a.facility_id AS facility_id      
      ,a.line_facility_id AS line_facility_id      
      ,a.shift_id AS shift_id      
      ,a.item_id AS item_id      
      ,a.per AS per      
      ,a.qty AS qty      
	  ,a.qty AS act_qty    
      ,a.schedule_date AS schedule_date      
      ,'AppleCore' AS inserted_by      
      ,b.seq_no AS from_seq_no      
      ,b.seq_no AS to_seq_no    
    ,a.item_product_variation_id  ,
	b.line_facility_id as    ddd
    INTO #insert_schedule      
    FROM #schedule a      
    LEFT JOIN RF_DWH_SCHEDULE b ON a.line_facility_id = b.line_facility_id 	AND 
	a.item_id = b.item_id AND a.schedule_date = b.schedule_date    
	And a.item_product_variation_id = b.item_product_variation_id     
	WHERE 1 = 1      
    AND b.deleted_date IS NULL       
   And (b.modified_by IS NULL OR b.modified_by = 'AppleCore')  
      
	  
       
  SET @xml = (SELECT schedule_id, line_id,facility_id,line_facility_id,shift_id,item_id,per,qty,act_qty,schedule_date,    
   inserted_by,from_seq_no,to_seq_no,item_product_variation_id       
     FROM (SELECT ROW_NUMBER() OVER (PARTITION BY schedule_id ORDER BY schedule_date DESC) AS srno, *       
       FROM #insert_schedule AS x) AS a --where a.item_product_variation_id IS NOT NULL   
     --WHERE a.srno = 1       
     FOR XML PATH('schedule'),ROOT('schedules'));     
      
   --Print  @xml       
   
  --EXEC usp_DOR_SCHEDULE_MANAGE @xml = @xml, @error_message = @error_message OUTPUT      
  -- Added on Date 17/04/2018 For Deviation Screen
  EXECUTE [dbo].[usp_DOR_SCHEDULE_MANAGE_LOAD_APPLECORE_SCHEDULE] @xml = @xml, @error_message = @error_message OUTPUT
   

	-------- This is For Set Start Time and End Time Data
	declare cur_scdate cursor for
	select DISTINCT CAST(schedule_date as date) from 
	#insert_schedule

	declare @schedule_date as datetime
	declare @ChekEditby as INT
	 OPEN cur_scdate
	 FETCH NEXT FROM cur_scdate into @schedule_date

	 WHILE (@@FETCH_STATUS = 0)
		BEGIN
			SET @ChekEditby = (SELECT count(1) from dbo.RF_DWH_SCHEDULE WHERE CAST(schedule_date AS DATE) = CAST(@schedule_date AS DATE) AND start_time IS NOT NULL)
			IF @ChekEditby = 0
				BEGIN
					EXECUTE [dbo].[usp_DOR_SCHEDULE_STARTTIME_ENDTIME] @schedule_date = @schedule_date,@isplaning = 1 
				END
			ELSE
				BEGIN
					EXECUTE [dbo].[usp_DOR_SCHEDULE_STARTTIME_ENDTIME] @schedule_date = @schedule_date,@isplaning = 2 
				END
			FETCH NEXT FROM cur_scdate INTO @schedule_date
		END
	
	CLOSE cur_scdate
	DEALLOCATE cur_scdate

  /*    
  IF OBJECT_ID('TEMPDB..#schedule') IS NOT NULL      
   DROP TABLE  #schedule      
      
  ;WITH CTE (facility_id,shift_id, [item_id], qty,[schedule_date],line_cd,build_grade_id)      
  AS      
  (      
   SELECT  b.facility_id AS facility_id           
       , e.shift_id AS shift_id      
       , c.item_id AS [item_id]           
       , a.qty AS qty      
       , a.schedule_dt AS [schedule_date]      
       , (      
      CASE WHEN c.over_wrap_crew  IS NOT NULL THEN UPPER('Flow Wrap')      
        WHEN c.pro_seal_single_crew  IS NOT NULL THEN UPPER('Single Pro Seal')      
        WHEN c.pro_seal_twin_crew IS NOT NULL THEN UPPER('Twin Pro Seal')      
        WHEN c.table_crew IS NOT NULL THEN UPPER('Table')      
      END      
     )AS line_cd      
     ,(      
      CASE WHEN c.over_wrap_crew  IS NOT NULL THEN c.flow_build_grade_id      
       WHEN c.pro_seal_single_crew  IS NOT NULL THEN c.single_build_grade_id      
       WHEN c.pro_seal_twin_crew IS NOT NULL THEN c.twin_build_grade_id      
       WHEN c.table_crew IS NOT NULL THEN c.table_build_grade_id      
      END      
     ) AS  build_grade_id      
     FROM [AppleCore_Stage] a      
     JOIN RF_DWH_FACILITY b      
    ON UPPER(b.facility_cd) = UPPER(a.facility_cd)           
    JOIN RF_DWH_ITEM c      
     -- JOIN (SELECT UPPER(x.item_name) AS item_name      
     --   , UPPER(CASE WHEN LEN(SUBSTRING(x.item_name, 1, CHARINDEX('-', x.item_name))) > 0       
     --         THEN REPLACE(SUBSTRING(x.item_name, 1, CHARINDEX('-', x.item_name)), '-', '')      
     --         ELSE SUBSTRING(x.item_name, 1, CHARINDEX(':', x.item_name)-1)      
     --        END) AS item_nm      
     --  FROM RF_DWH_XREF_APPLECORE_ITEMS AS x      
     --  WHERE x.package_type = 'production') AS ix      
     -- ON ix.item_nm = UPPER(c.item_nm)      
     --ON ix.item_name = UPPER(a.item_nm)      
     ----   JOIN RF_DWH_XREF_APPLECORE_ITEM_IDS ix      
     ----     ON ix.item_no = c.item_no      
     ----ON ix.applecore_no = a.item_no      
     ON c.item_no = a.item_no      
     LEFT JOIN RF_DWH_SHIFT e      
    ON e.shift_cd = 'D'      
    WHERE 1 = 1      
      AND b.deleted_date IS NULL      
      AND c.deleted_date IS NULL      
      AND e.deleted_date IS NULL          
  ),      
  CTE1  (line_id, line_cd, line_nm, sequ_no)      
  AS      
  (      
   SELECT line_id,line_cd,line_nm, ROW_NUMBER() OVER(PARTITION BY line_cd ORDER BY line_nm) sequ_no      
     FROM RF_DWH_LINE      
    WHERE 1 = 1      
      AND deleted_by IS NULL      
  )      
  SELECT b.line_id AS line_id      
    ,a.facility_id AS facility_id      
    ,c.line_facility_id AS line_facility_id      
    ,a.shift_id AS shift_id      
    ,a.item_id AS item_id      
    , AVG(d.plan_per)  AS per      
    , SUM(CAST(a.qty AS INT)) AS qty      
  ,a.schedule_date AS schedule_date      
    INTO #schedule      
    FROM CTE a      
    JOIN CTE1 b      
   ON UPPER(a.line_cd) = UPPER(b.line_cd)       
     AND b.sequ_no = 1      
    JOIN RF_DWH_XREF_LINE_FACILITY c      
   ON c.facility_id = a.facility_id      
     AND c.line_id = b.line_id      
    JOIN RF_DWH_RE_RUN_RATE d      
   ON d.build_grade_id = a.build_grade_id       
  GROUP BY b.line_id, a.facility_id, c.line_facility_id, a.shift_id,a.item_id, a.schedule_date       
      
  SELECT @max_schedule_date = MAX(schedule_date)      
      ,@min_schedule_date = MIN(schedule_date)       
    FROM #schedule       
      
  IF OBJECT_ID('TEMPDB..#delete_schedule') IS NOT NULL      
   DROP TABLE  #delete_schedule      
      
  SELECT b.schedule_id AS schedule_id      
      ,c.line_id AS line_id      
      ,c.facility_id AS facility_id      
      ,b.line_facility_id AS line_facility_id      
      ,b.shift_id AS shift_id      
      ,b.item_id AS item_id      
      ,b.per AS per      
      ,b.qty AS qty      
      ,b.schedule_date AS schedule_date      
      ,'AppleCore' AS deleted_by      
      ,b.seq_no AS from_seq_no      
      ,b.seq_no AS to_seq_no      
    INTO #delete_schedule      
    FROM #schedule a      
    RIGHT JOIN RF_DWH_SCHEDULE b      
    JOIN RF_DWH_XREF_LINE_FACILITY c      
      ON c.line_facility_id = b.line_facility_id      
   ON a.line_facility_id = b.line_facility_id      
     AND a.item_id = b.item_id          
     AND a.schedule_date = b.schedule_date      
   WHERE 1 = 1         
     AND a.facility_id IS NULL      
     AND b.schedule_date BETWEEN @min_schedule_date AND @max_schedule_date      
     AND b.deleted_date IS NULL      
     AND b.inserted_by = 'AppleCore'      
     AND b.modified_by = 'AppleCore'      
      
  IF OBJECT_ID('TEMPDB..#update_schedule') IS NOT NULL      
   DROP TABLE  #update_schedule      
      
  SELECT b.schedule_id AS schedule_id      
      ,a.line_id AS line_id      
      ,a.facility_id AS facility_id      
      ,a.line_facility_id AS line_facility_id      
      ,a.shift_id AS shift_id      
      ,a.item_id AS item_id      
      ,a.per AS per      
      ,a.qty AS qty      
      ,a.schedule_date AS schedule_date      
      ,'AppleCore' AS modified_by      
      ,b.seq_no AS from_seq_no      
      ,b.seq_no AS to_seq_no      
    INTO #update_schedule      
    FROM #schedule a      
    JOIN RF_DWH_SCHEDULE b      
   ON a.line_facility_id = b.line_facility_id      
     AND a.item_id = b.item_id      
     AND a.schedule_date = b.schedule_date      
   WHERE 1 = 1      
     AND b.deleted_date IS NULL      
      
    DELETE a      
    FROM #schedule a      
    JOIN RF_DWH_SCHEDULE b      
   ON a.line_facility_id = b.line_facility_id      
     AND a.item_id = b.item_id      
     AND a.schedule_date = b.schedule_date      
   WHERE 1 = 1      
     AND b.deleted_date IS NULL      
      
      
  IF OBJECT_ID('TEMPDB..#insert_schedule') IS NOT NULL      
   DROP TABLE  #insert_schedule      
      
  SELECT b.schedule_id AS schedule_id      
      ,a.line_id AS line_id      
      ,a.facility_id AS facility_id      
      ,a.line_facility_id AS line_facility_id      
      ,a.shift_id AS shift_id      
      ,a.item_id AS item_id      
      ,a.per AS per      
      ,a.qty AS qty      
      ,a.schedule_date AS schedule_date      
      ,'AppleCore' AS inserted_by      
      ,b.seq_no AS from_seq_no      
      ,b.seq_no AS to_seq_no      
    INTO #insert_schedule      
    FROM #schedule a      
    LEFT JOIN RF_DWH_SCHEDULE b      
   ON a.line_facility_id = b.line_facility_id      
     AND a.item_id = b.item_id      
     AND a.schedule_date = b.schedule_date      
   WHERE 1 = 1      
     AND b.deleted_date IS NULL       
       
      
  SET @xml = (SELECT schedule_id, line_id,facility_id,line_facility_id,shift_id,item_id,per,qty,schedule_date,deleted_by,from_seq_no,to_seq_no        
     FROM (SELECT ROW_NUMBER() OVER (PARTITION BY schedule_id ORDER BY schedule_date DESC) AS srno, *       
       FROM #delete_schedule  AS x) AS a      
     WHERE a.srno = 1       
     FOR XML PATH('schedule'),ROOT('schedules'));       
  EXEC usp_DOR_SCHEDULE_MANAGE @xml = @xml, @error_message = @error_message OUTPUT  */    
      
      
  --SET @xml = (SELECT schedule_id, line_id,facility_id,line_facility_id,shift_id,item_id,per,qty,schedule_date,modified_by,from_seq_no,to_seq_no       
  --   FROM (SELECT ROW_NUMBER() OVER (PARTITION BY schedule_id ORDER BY schedule_date DESC) AS srno, *       
  --     FROM #update_schedule AS x) AS a      
  --   WHERE a.srno = 1      
  --   FOR XML PATH('schedule'),ROOT('schedules'));      
  --EXEC usp_DOR_SCHEDULE_MANAGE @xml = @xml, @error_message = @error_message OUTPUT      
      
        
  --SET @xml = (SELECT schedule_id, line_id,facility_id,line_facility_id,shift_id,item_id,per,qty,schedule_date, inserted_by,from_seq_no,to_seq_no       
  --   FROM (SELECT ROW_NUMBER() OVER (PARTITION BY schedule_id ORDER BY schedule_date DESC) AS srno, *       
  --     FROM #insert_schedule AS x) AS a      
  --   --WHERE a.srno = 1       
  --   FOR XML PATH('schedule'),ROOT('schedules'));         
  --EXEC usp_DOR_SCHEDULE_MANAGE @xml = @xml, @error_message = @error_message OUTPUT      
      
 END TRY      
 BEGIN CATCH      
      
  SELECT @error_message  "ERROR_MESSAGE";      
      
  IF @@trancount > 0      
   ROLLBACK TRANSACTION;      
      
      
 END CATCH      
       
 IF @@trancount > 0      
 COMMIT TRANSACTION;      
      
END 
