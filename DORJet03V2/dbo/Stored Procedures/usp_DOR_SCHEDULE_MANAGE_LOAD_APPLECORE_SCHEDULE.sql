CREATE PROCEDURE [dbo].[usp_DOR_SCHEDULE_MANAGE_LOAD_APPLECORE_SCHEDULE]
 @xml XML,        
 @from_schedule_production bit = null, --  This parameter value is When From Planing than 1 , When From Production than 0       
 @error_message VARCHAR(MAX) OUTPUT   
AS        
BEGIN
 ----         
 SET NOCOUNT ON;        
 DECLARE @hDoc AS INT, @next_seq_no AS INT,	
@status_id INT = (select status_id from dbo.RF_DWH_STATUS where status_desc='Not Completed');   -- Comments Moving Jet03 changes to Jet02 23/07/2018      
            
 BEGIN TRANSACTION        
        
  BEGIN TRY        
   
   IF OBJECT_ID('TEMPDB..#shift_entry') IS NOT NULL        
   DROP TABLE  #shift_entry        
        
   CREATE TABLE #shift_entry        
   (        
    schedule_id INT,        
    deleted_date DATETIME,        
    deleted_by VARCHAR(50),        
    from_seq_no INT,        
    to_seq_no INT        
   );        
        
   IF OBJECT_ID('tempdb..#TempAppleCodeLoad') IS NOT NULL
	DROP TABLE #TempAppleCodeLoad
   
   --SELECT @next_seq_no = ISNULL(MAX(a.seq_no), 0) + 1         
   --FROM RF_DWH_SCHEDULE AS a;        
   
   SELECT @next_seq_no = ISNULL(MAX(a.seq_no), 0)
   FROM RF_DWH_SCHEDULE AS a;   
   
   EXEC sp_xml_preparedocument   @hDoc output, @xml         

   SELECT schedule_id,b.line_facility_id,shift_id,a.item_id,per,qty,         
       schedule_date,GETDATE() AS inserted_date,a.inserted_by,
	   CASE WHEN a.modified_by IS NULL THEN NULL ELSE GETDATE() END AS modified_date,         
       a.modified_by,CASE WHEN a.deleted_by IS NULL THEN NULL ELSE GETDATE() END AS deleted_date,         
       a.deleted_by,
	   --ISNULL(from_seq_no, 0) AS from_seq_no,
	   --ISNULL(to_seq_no, 0) AS to_seq_no,
	   ISNULL(from_seq_no, 0) AS from_seq_no,
	   ISNULL(to_seq_no, @next_seq_no + ROW_Number() OVER( ORDER BY schedule_date)) AS to_seq_no,
	   start_time,end_time,      
	   a.item_product_variation_id, act_qty , comment, production_comment,production_start_time,    
     production_end_time,
	 CASE WHEN UPPER(e.line_cd) LIKE 'FLOW WRAP%' THEN pv.over_wrap_crew              
     WHEN UPPER(e.line_cd) LIKE 'SINGLE PRO%' THEN pv.pro_seal_single_crew              
     WHEN UPPER(e.line_cd) LIKE 'TWIN PRO%' THEN pv.pro_seal_twin_crew              
     WHEN UPPER(e.line_cd) LIKE 'TABLE' THEN pv.table_crew              
	 END crew,
	 Convert(numeric(18,2),(isnull((CASE WHEN UPPER(e.line_cd) LIKE 'FLOW WRAP%' THEN pv.over_wrap_t_max              
     WHEN UPPER(e.line_cd) LIKE 'SINGLE PRO%' THEN pv.pro_seal_single_t_max              
     WHEN UPPER(e.line_cd) LIKE 'TWIN PRO%' THEN pv.pro_seal_twin_t_max              
     WHEN UPPER(e.line_cd) LIKE 'TABLE' THEN pv.table_t_max              
    END),0))) t_max,
	--CASE WHEN  a.inserted_by = 'AppleCore' 
	--THEN isnull([dbo].[fn_GetMaxSeqNumber](schedule_date,null,null,a.inserted_by),0) + (dense_rank() OVER(partition by schedule_date  ORDER BY schedule_date,a.line_facility_id,item_id)) 
	--ELSE 
		CASE WHEN isnull([dbo].[fn_GetMaxSeqNumber](schedule_date,b.line_facility_id,a.item_id,a.inserted_by),0) = 0
			THEN  isnull([dbo].[fn_GetMaxSeqNumber](schedule_date,null,null,a.inserted_by),0) + (dense_rank() OVER(partition by schedule_date  ORDER BY schedule_date,a.line_facility_id,im.item_nm)) --,vm.variation_nm))  --,item_id))
			ELSE isnull([dbo].[fn_GetMaxSeqNumber](schedule_date,b.line_facility_id,a.item_id,a.inserted_by),0) END 
	--END 
	AS ProductSqNo,
	--re_run,over_run,break_use,lunch_use,
	re_run_units,over_run_units,use_break,use_lunch,crew_size_actual
	into #TempAppleCodeLoad
	FROM   OPENXML(@hDoc, 'schedules/schedule', 3)         
        WITH ( [schedule_id]        [INT],        
         [line_id]    [INT],        
         [facility_id]   [INT],         
         [line_facility_id]      [INT],                  
         [shift_id]    [INT],         
         [item_id]    [INT],         
         [per]     [INT],         
         [qty]     [INT],         
         [schedule_date]   [DATETIME],                  
         [inserted_by]           [VARCHAR](50),         
         [modified_by]           [VARCHAR](50),         
         [deleted_by]            [VARCHAR](50),        
         [from_seq_no]   [INT],        
         [to_seq_no]    [INT] ,      
   [start_time] DateTime,      
   [end_time] DateTime,      
   [item_product_variation_id]    [INT] ,      
   [act_qty]    [INT],    
   comment varchar(1000),    
   production_comment varchar(1000),    
   [production_start_time] DateTime,      
   [production_end_time] DateTime,
       [production_line_id]    [INT],
	   [re_run_units]     [INT],
	   [over_run_units]    [INT],
	   [use_break]    BIT,
	   [use_lunch]    BIT,
	   [crew_size_actual] INT
	) AS a        
     LEFT JOIN RF_DWH_XREF_LINE_FACILITY b ON a.line_id = b.line_id AND a.facility_id = b.facility_id
	 LEFT JOIN RF_DWH_LINE  e ON e.line_id = b.line_id
	 LEFT JOIN XREF_ITEM_PRODUCT_VARIATION pv on pv.item_product_variation_id = a.item_product_variation_id            
     LEFT JOIN RF_DWH_ITEM im on a.item_id = im.item_id
	 LEFT JOIN RF_DWH_VARIATION_MASTER vm on vm.variation_id = pv.variation_id
   -------- Comment This Source Table and Inserted into Temp Table
   --(SELECT schedule_id,b.line_facility_id,shift_id,item_id,per,qty,         
 --      schedule_date,GETDATE() AS inserted_date,a.inserted_by,
	--   CASE WHEN a.modified_by IS NULL THEN NULL ELSE GETDATE() END AS modified_date,         
 --      a.modified_by,CASE WHEN a.deleted_by IS NULL THEN NULL ELSE GETDATE() END AS deleted_date,         
 --      a.deleted_by,
	--   --ISNULL(from_seq_no, 0) AS from_seq_no,
	--   --ISNULL(to_seq_no, 0) AS to_seq_no,
	--   ISNULL(from_seq_no, 0) AS from_seq_no,
	--   ISNULL(to_seq_no, @next_seq_no + ROW_Number() OVER( ORDER BY schedule_date)) AS to_seq_no,
	--   start_time,end_time,      
	--   a.item_product_variation_id, act_qty , comment, production_comment,production_start_time,    
 --    production_end_time,
	-- CASE WHEN UPPER(e.line_cd) LIKE 'FLOW WRAP%' THEN pv.over_wrap_crew              
 --    WHEN UPPER(e.line_cd) LIKE 'SINGLE PRO%' THEN pv.pro_seal_single_crew              
 --    WHEN UPPER(e.line_cd) LIKE 'TWIN PRO%' THEN pv.pro_seal_twin_crew              
 --    WHEN UPPER(e.line_cd) LIKE 'TABLE' THEN pv.table_crew              
	-- END crew,
	-- Convert(numeric(18,2),(isnull((CASE WHEN UPPER(e.line_cd) LIKE 'FLOW WRAP%' THEN pv.over_wrap_t_max              
 --    WHEN UPPER(e.line_cd) LIKE 'SINGLE PRO%' THEN pv.pro_seal_single_t_max              
 --    WHEN UPPER(e.line_cd) LIKE 'TWIN PRO%' THEN pv.pro_seal_twin_t_max              
 --    WHEN UPPER(e.line_cd) LIKE 'TABLE' THEN pv.table_t_max              
 --   END),0))) t_max,
	----CASE WHEN  a.inserted_by = 'AppleCore' 
	----THEN isnull([dbo].[fn_GetMaxSeqNumber](schedule_date,null,null,a.inserted_by),0) + (dense_rank() OVER(partition by schedule_date  ORDER BY schedule_date,a.line_facility_id,item_id)) 
	----ELSE 
	--	CASE WHEN isnull([dbo].[fn_GetMaxSeqNumber](schedule_date,b.line_facility_id,item_id,a.inserted_by),0) = 0
	--		THEN  isnull([dbo].[fn_GetMaxSeqNumber](schedule_date,null,null,a.inserted_by),0) + (dense_rank() OVER(partition by schedule_date  ORDER BY schedule_date,a.line_facility_id,item_id))
	--		ELSE isnull([dbo].[fn_GetMaxSeqNumber](schedule_date,b.line_facility_id,item_id,a.inserted_by),0) END 
	----END 
	--AS ProductSqNo,
	----re_run,over_run,break_use,lunch_use,
	--re_run_units,over_run_units,use_break,use_lunch,crew_size_actual
	--FROM   OPENXML(@hDoc, 'schedules/schedule', 3)         
 --       WITH ( [schedule_id]        [INT],        
 --        [line_id]    [INT],        
 --        [facility_id]   [INT],         
 --        [line_facility_id]      [INT],                  
 --        [shift_id]    [INT],         
 --        [item_id]    [INT],         
 --        [per]     [INT],         
 --        [qty]     [INT],         
 --        [schedule_date]   [DATETIME],                  
 --        [inserted_by]           [VARCHAR](50),         
 --        [modified_by]           [VARCHAR](50),         
 --        [deleted_by]            [VARCHAR](50),        
 --        [from_seq_no]   [INT],        
 --        [to_seq_no]    [INT] ,      
 --  [start_time] DateTime,      
 --  [end_time] DateTime,      
 --  [item_product_variation_id]    [INT] ,      
 --  [act_qty]    [INT],    
 --  comment varchar(1000),    
 --  production_comment varchar(1000),    
 --  [production_start_time] DateTime,      
 --  [production_end_time] DateTime,
 --      [production_line_id]    [INT],
	--   [re_run_units]     [INT],
	--   [over_run_units]    [INT],
	--   [use_break]    BIT,
	--   [use_lunch]    BIT,
	--   [crew_size_actual] INT
	--) AS a        
 --      LEFT JOIN RF_DWH_XREF_LINE_FACILITY b ON a.line_id = b.line_id AND a.facility_id = b.facility_id
	--   LEFT JOIN RF_DWH_LINE  e ON e.line_id = b.line_id
	--   LEFT JOIN XREF_ITEM_PRODUCT_VARIATION pv on pv.item_product_variation_id = a.item_product_variation_id            
 --  ) 
MERGE RF_DWH_SCHEDULE AS trg         
USING #TempAppleCodeLoad AS src         
ON trg.schedule_id = src.schedule_id         
WHEN NOT MATCHED BY TARGET          
THEN INSERT (line_facility_id,shift_id,item_id,per,qty,schedule_date,inserted_date,inserted_by,seq_no,start_time,      
end_time,item_product_variation_id,act_qty,comment,production_comment,production_start_time,production_end_time ,
production_line_facility_id ,ncrewplaning,nspeedplaning,nlinehrsplaning,ncrewproduction,nspeedproduction,nlinehrsproduction, 
nitemseqplaning,nitemseqproduction,seq_no_prod,re_run_planing,over_run_planing,break_use_planing,lunch_use_planing
,re_run_production,over_run_production,break_use_production,lunch_use_production,crew_size_actual_planing,crew_size_actual_production
,status_id)								-- Comments Moving Jet03 changes to Jet02 23/07/2018    
VALUES(src.line_facility_id,src.shift_id,src.item_id,src.per,src.qty,src.schedule_date,src.inserted_date,src.inserted_by,--@next_seq_no,
	  isnull(src.to_seq_no,@next_seq_no + 1),src.start_time,src.end_time,src.item_product_variation_id,      
	 0 -- src.act_qty   -- Added 0 for REVFOODDOR-104 06/18/2018
	  ,src.comment, src.production_comment,src.production_start_time,src.production_end_time,src.line_facility_id ,
	src.crew,convert(numeric(18,2),src.t_max/60),CASE WHEN src.crew IS NOT NULL AND isnull(src.t_max,0) > 0 AND isnull(src.per,0) > 0 
												 THEN CAST(((src.qty/src.t_max) * (1.0/src.per)) * 100 AS DECIMAL(16,8))
												 ELSE NULL END,
	src.crew,convert(numeric(18,2),src.t_max/60),CASE WHEN src.crew IS NOT NULL AND isnull(src.t_max,0) > 0 AND isnull(src.per,0) > 0 
												 THEN CAST(((src.act_qty/src.t_max) * (1.0/src.per)) * 100 AS DECIMAL(16,8))
												 ELSE NULL END,
	src.ProductSqNo,src.ProductSqNo,isnull(src.to_seq_no,@next_seq_no + 1),
	--src.re_run,src.over_run,src.break_use,src.lunch_use,
	src.re_run_units,src.over_run_units,src.use_break,src.use_lunch,
	src.re_run_units,src.over_run_units,src.use_break,src.use_lunch,
	src.crew_size_actual,src.crew_size_actual
	,@status_id					-- Comments Moving Jet03 changes to Jet02 23/07/2018
	--src.re_run,src.over_run,src.break_use,src.lunch_use
	)
	
	
	
	------------ Comment For Not Update Qty and Insert Match Data into other table
	--WHEN MATCHED AND (isnull(src.inserted_by,'') <> 'AppleCore') THEN         
	--UPDATE SET trg.line_facility_id = (CASE WHEN @from_schedule_production = 1 THEN src.line_facility_id ELSE isnull(trg.line_facility_id,src.line_facility_id) END) ,         
	--	 trg.shift_id = src.shift_id,         
	--	 trg.item_id = src.item_id,         
	--	 trg.per = src.per,         
	--	 trg.qty = src.qty,        
	--	 trg.act_qty = src.act_qty ,     
	--	 trg.schedule_date = src.schedule_date,             
	--	 --trg.modified_date = COALESCE(trg.modified_date, src.modified_date),         
	--	 --trg.modified_by = COALESCE(trg.modified_by, src.modified_by),         
	--	 trg.modified_date = COALESCE(src.modified_date, trg.modified_date),         
	--	 trg.modified_by = COALESCE(src.modified_by, trg.modified_by),         
		
	--	--trg.deleted_date = CASE         
	--	--     WHEN src.deleted_by IS NULL THEN NULL         
	--	--     ELSE src.deleted_date         
	--	--    END,         
	--	--trg.deleted_by = src.deleted_by,        
	--	--trg.seq_no =  IIF(isnull(src.to_seq_no,0) = 0 ,trg.seq_no,src.to_seq_no), 
		

	--	-- Added On Date 13042018
	--	trg.seq_no = (case when @from_schedule_production = 1 then 
	--						case when trg.line_facility_id <>  src.line_facility_id then ([dbo].[fn_GetMaxSeqNumberForvarient](src.schedule_date,src.line_facility_id,null,@from_schedule_production))   
	--						else trg.seq_no end 
	--					else trg.seq_no end) , 
	--	trg.seq_no_prod = (case when @from_schedule_production = 1 then 
	--						case when trg.line_facility_id <>  src.line_facility_id then ([dbo].[fn_GetMaxSeqNumberForvarient](src.schedule_date,src.line_facility_id,null,@from_schedule_production))
	--						else trg.seq_no_prod end
	--					   else 
	--						case when trg.production_line_facility_id <>  src.line_facility_id then ([dbo].[fn_GetMaxSeqNumberForvarient](src.schedule_date,src.line_facility_id,null,@from_schedule_production))
	--						else trg.seq_no_prod end
	--					   end) , 
		
	--	trg.nitemseqplaning = (case when @from_schedule_production = 1 then 
	--						case when trg.line_facility_id <>  src.line_facility_id then ([dbo].[fn_GetMaxSeqNumberForvarient](src.schedule_date,src.line_facility_id,src.item_id,@from_schedule_production))   
	--						else trg.nitemseqplaning end 
	--					else trg.nitemseqplaning end) , 
	--	trg.nitemseqproduction = (case when @from_schedule_production = 1 then 
	--						case when trg.line_facility_id <>  src.line_facility_id then ([dbo].[fn_GetMaxSeqNumberForvarient](src.schedule_date,src.line_facility_id,src.item_id,@from_schedule_production))
	--						else trg.nitemseqproduction end
	--					   else 
	--						case when trg.production_line_facility_id <>  src.line_facility_id then ([dbo].[fn_GetMaxSeqNumberForvarient](src.schedule_date,src.line_facility_id,src.item_id,@from_schedule_production))
	--						else trg.nitemseqproduction end
	--					   end),


	--	trg.start_time = src.start_time,      
	--	trg.end_time = src.end_time,      
	--	trg.item_product_variation_id = src.item_product_variation_id,      
	--	trg.comment = src.comment,    
	--	trg.production_comment = src.production_comment,    
	--	trg.production_start_time = src.production_start_time,      
	--	trg.production_end_time = src.production_end_time,  
	--	trg.production_line_facility_id = src.line_facility_id, --(CASE WHEN @from_schedule_production = 1 THEN src.line_facility_id ELSE trg.production_line_facility_id END) ,
	--	trg.ncrewplaning =  (CASE WHEN @from_schedule_production = 1 THEN src.crew ELSE trg.ncrewplaning END),
	--	trg.nspeedplaning = (CASE WHEN @from_schedule_production = 1 THEN convert(numeric(18,2),src.t_max/60) ELSE trg.nspeedplaning END),
	--	trg.nlinehrsplaning = (CASE WHEN @from_schedule_production = 1 THEN CASE WHEN src.crew IS NOT NULL AND isnull(src.t_max,0) > 0 AND isnull(src.per,0) > 0 THEN CAST(((src.qty/src.t_max) * (1.0/src.per)) * 100 AS DECIMAL(16,8))ELSE NULL END ELSE trg.nlinehrsplaning END),
	--	trg.ncrewproduction = src.crew,
	--	trg.nspeedproduction = convert(numeric(18,2),src.t_max/60),
	--	trg.nlinehrsproduction = CASE WHEN src.crew IS NOT NULL AND isnull(src.t_max,0) > 0 AND isnull(src.per,0) > 0 THEN CAST(((src.act_qty/src.t_max) * (1.0/src.per)) * 100 AS DECIMAL(16,8))ELSE NULL END,
	--	trg.isproductionchanged =  0,
	--	trg.re_run_planing = (CASE WHEN @from_schedule_production = 1 THEN src.re_run_units ELSE trg.re_run_planing END),
	--	trg.over_run_planing = (CASE WHEN @from_schedule_production = 1 THEN src.over_run_units ELSE trg.over_run_planing END),
	--	trg.break_use_planing = (CASE WHEN @from_schedule_production = 1 THEN src.use_break ELSE trg.break_use_planing END),
	--	trg.lunch_use_planing = (CASE WHEN @from_schedule_production = 1 THEN src.use_lunch ELSE trg.lunch_use_planing END),
	--	trg.re_run_production = src.re_run_units,
	--	trg.over_run_production = src.over_run_units,
	--	trg.break_use_production = src.use_break,
	--	trg.lunch_use_production = src.use_lunch,
	--	trg.crew_size_actual_planing = (CASE WHEN @from_schedule_production = 1 THEN src.crew_size_actual ELSE trg.crew_size_actual_planing END),
	--	trg.crew_size_actual_production = src.crew_size_actual
		

		--------------------------------------------------


		--Case When @from_schedule_production = 0 --@from_schedule_production = 1  
  --	      THEN  CASE WHEN 
		--  ( src.qty  = src.act_qty   AND  src.start_time =   src.production_start_time   AND  src.end_time =  src.production_end_time
		--  AND (trg.production_line_facility_id = src.line_facility_id)
		--  ) THEN 0 ELSE 1 END  
  --       ELSE  trg.isproductionchanged  END
		 --,trg.nitemseqproduction = CASE WHEN trg.nitemseqproduction is null THEN src.ProductSqNo ELSE (CASE WHEN @from_schedule_production = 1 THEN trg.nitemseqplaning ELSE isnull(trg.nitemseqproduction,src.ProductSqNo) END) END,
		--trg.nitemseqplaning = isnull(trg.nitemseqplaning,src.ProductSqNo)

	OUTPUT INSERTED.schedule_id,INSERTED.deleted_date,INSERTED.deleted_by, DELETED.seq_no, INSERTED.seq_no        
    INTO  #shift_entry;        
    

	MERGE RF_DWH_DEVIATION as trg
	USING ( 
		select tac.schedule_id , tac.schedule_date , tac.qty from  #TempAppleCodeLoad tac 
		INNER JOIN RF_DWH_SCHEDULE rfs on tac.schedule_id = rfs.schedule_id AND isnull(tac.qty,0) <> isnull(rfs.qty,0)
	) as src
	ON trg.schedule_id = src.schedule_id --AND trg.accept_reject IS NULL AND isnull(trg.deviation_qty,0) <> isnull(Src.qty,0)
	WHEN NOT MATCHED BY TARGET THEN
		INSERT(schedule_id,schedule_date,deviation_qty)
		VALUES(src.schedule_id,src.schedule_date,src.qty)
	WHEN MATCHED  --AND isnull(trg.deviation_qty,0) <> isnull(Src.qty,0) 
	THEN -- AND trg.accept_reject IS NULL
		Update set trg.deviation_qty = src.qty , trg.accept_reject = NULL;  -- Added  trg.accept_reject = NULL
	
	Declare @deleted_by varchar(30)    
    SELECT  top 1 @deleted_by = deleted_by    
     FROM   OPENXML(@hDoc, 'schedules/schedule',3)         
        WITH ( [deleted_by]        varchar(30)          
	) AS a     
    
	MERGE RF_DWH_APPLECORE_ITEM_NOT_FOUND  as trg
	USING (
		select acs.schedule_dt , acs.item_no , acs.variationID , acs.item_nm , MAX(acs.facility_cd) AS facility_cd , MAX(acs.qty) AS qty , MAX(f.facility_id) AS facility_id
		from [AppleCore_Stage] acs 
		inner join RF_DWH_ITEM im on im.item_no = acs.item_no
		Left join XREF_ITEM_PRODUCT_VARIATION pv on pv.applecore_product_id = acs.item_no AND pv.applecore_variation_id = acs.variationID  
		LEFT join RF_DWH_VARIATION_MASTER vm on vm.variation_id = pv.variation_id
		LEFT JOIN RF_DWH_FACILITY f on rtrim(ltrim(f.facility_cd)) = rtrim(ltrim(acs.facility_cd))
		WHERE vm.variation_nm is null 
		GROUP BY acs.schedule_dt , acs.item_no , acs.variationID , acs.item_nm 
	) as src
	ON cast(trg.schedule_dt as date) = cast(src.schedule_dt as date) AND trg.item_no = src.item_no AND trg.variationID = src.variationID AND trg.item_nm = src.item_nm
	AND trg.facility_id = src.facility_id
	WHEN NOT MATCHED BY TARGET THEN
		INSERT(schedule_dt,item_no,variationID,item_nm,facility_id,qty)
		VALUES(src.schedule_dt,src.item_no,src.variationID,src.item_nm,src.facility_id,src.qty)
	WHEN MATCHED THEN
		UPDATE set trg.qty = src.qty;





  if(@deleted_by IS NOT NULL OR @deleted_by <> '') 
  Begin    
     Update b Set b.deleted_date = getdate(),    
     b.deleted_by = @deleted_by    
     From RF_DWH_SCHEDULE b    
	 JOIN #shift_entry a    
     ON a.schedule_id = b.schedule_id       
     where  qty IS NULL AND act_qty IS NULL    
  End    
             
     --SELECT * FROM #shift_entry        
           
   IF EXISTS (SELECT 1 FROM #shift_entry)        
   BEGIN        
     UPDATE a        
       SET a.deleted_date = b.deleted_date,        
           a.deleted_by = b.deleted_by        
      FROM RF_DWH_SHIFT_ENTRY a        
      JOIN #shift_entry b        
        ON a.schedule_id = b.schedule_id        
        
    UPDATE a        
     SET a.seq_no = b.from_seq_no        
    FROM RF_DWH_SCHEDULE AS a        
    JOIN #shift_entry AS b        
     ON b.to_seq_no = a.seq_no        
    WHERE a.schedule_id != b.schedule_id;           
        
   END        
        
   EXEC sp_xml_removedocument @hDoc        
  END TRY        
  BEGIN CATCH        
        
   SELECT @error_message = ERROR_MESSAGE();        
        
   IF @@TRANCOUNT > 0        
   ROLLBACK;        
        
  END CATCH        
         
 IF @@TRANCOUNT > 0        
 COMMIT;        
END 
