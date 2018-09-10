CREATE PROCEDURE [dbo].[usp_DOR_SCHEDULE_MANAGE_08272018]  
 @xml XML,          
 @from_schedule_production bit = null, --  This parameter value is When From Planing than 1 , When From Production than 0         
 @error_message VARCHAR(MAX) OUTPUT     
AS          
BEGIN  
 SET NOCOUNT ON;          
 DECLARE @hDoc AS INT, @next_seq_no AS INT,
  @status_id INT = (SELECT status_id from RF_DWH_STATUS WHERE status_desc= 'Not Completed');          
              
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
    to_seq_no INT,
	modified_by varchar(50),
	del_production_line_facility_id int,
	int_production_line_facility_id int,
	
	-- Added on date 21052018 
	del_start_time datetime,
	del_end_time datetime,
	int_start_time datetime,
	int_end_time datetime,
	del_line_facility_id INT,
	int_line_facility_id INT,
	del_seq_no INT,
	int_seq_no INT,
	del_itemseqno INT,
	int_itemseqno INT,
	trantype varchar(250)
	);          
          
   --SELECT @next_seq_no = ISNULL(MAX(a.seq_no), 0) + 1           
   --FROM RF_DWH_SCHEDULE AS a;          
     
   SELECT @next_seq_no = ISNULL(MAX(a.seq_no), 0)  
   FROM RF_DWH_SCHEDULE AS a;     
     
   EXEC sp_xml_preparedocument   @hDoc output, @xml           
  
   MERGE RF_DWH_SCHEDULE AS trg           
   USING (SELECT schedule_id,b.line_facility_id,shift_id,item_id,per,qty,           
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
  CASE WHEN isnull([dbo].[fn_GetMaxSeqNumber](schedule_date,b.line_facility_id,item_id,a.inserted_by),0) = 0  
   THEN  isnull([dbo].[fn_GetMaxSeqNumber](schedule_date,null,null,a.inserted_by),0) + (dense_rank() OVER(partition by schedule_date 
    ORDER BY schedule_date,a.line_facility_id,item_id))  
   ELSE isnull([dbo].[fn_GetMaxSeqNumber](schedule_date,b.line_facility_id,item_id,a.inserted_by),0) END   
 --END   
 AS ProductSqNo,  
 --re_run,over_run,break_use,lunch_use,  
 re_run_units,over_run_units,use_break,use_lunch,crew_size_actual  ,status_id
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
         [deleted_by]            [VARCHAR](50),                   [from_seq_no]   [INT],          
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
    [crew_size_actual] INT ,
	[status_id] INT 
 ) AS a          
       LEFT JOIN RF_DWH_XREF_LINE_FACILITY b ON a.line_id = b.line_id AND a.facility_id = b.facility_id  
    LEFT JOIN RF_DWH_LINE  e ON e.line_id = b.line_id  
    LEFT JOIN XREF_ITEM_PRODUCT_VARIATION pv on pv.item_product_variation_id = a.item_product_variation_id              
   ) AS src           
   ON trg.schedule_id = src.schedule_id           
   WHEN NOT MATCHED BY TARGET            
   THEN           
    INSERT ( line_facility_id,shift_id,item_id,per,qty,schedule_date,inserted_date,inserted_by,seq_no,start_time,        
 end_time,item_product_variation_id,act_qty,comment,production_comment,production_start_time,production_end_time ,  
 production_line_facility_id ,ncrewplaning,nspeedplaning,nlinehrsplaning,ncrewproduction,nspeedproduction,nlinehrsproduction,   
 nitemseqplaning,nitemseqproduction,seq_no_prod,re_run_planing,over_run_planing,break_use_planing,lunch_use_planing  
 ,re_run_production,over_run_production,break_use_production,lunch_use_production,crew_size_actual_planing,crew_size_actual_production,
 production_createdby , production_modifiedby ,status_id
    )           
    VALUES(src.line_facility_id,src.shift_id,src.item_id,src.per,src.qty,src.schedule_date,           
      src.inserted_date,src.inserted_by,  
   --@next_seq_no,  
   isnull(src.to_seq_no,@next_seq_no + 1),  
   src.start_time,src.end_time,src.item_product_variation_id,        
   src.act_qty ,src.comment, src.production_comment,src.production_start_time,src.production_end_time,src.line_facility_id ,  
 src.crew,convert(numeric(18,2),src.t_max/60),CASE WHEN src.crew IS NOT NULL AND isnull(src.t_max,0) > 0 AND isnull(src.per,0) > 0 
 THEN CAST(((src.qty/src.t_max) * (1.0/src.per)) * 100 AS DECIMAL(16,8))ELSE NULL END,  
 src.crew,convert(numeric(18,2),src.t_max/60),CASE WHEN src.crew IS NOT NULL AND isnull(src.t_max,0) > 0 AND isnull(src.per,0) > 0 
 THEN CAST(((src.act_qty/src.t_max) * (1.0/src.per)) * 100 AS DECIMAL(16,8))ELSE NULL END,  
 src.ProductSqNo,src.ProductSqNo,isnull(src.to_seq_no,@next_seq_no + 1),  
 --src.re_run,src.over_run,src.break_use,src.lunch_use,  
 src.re_run_units,src.over_run_units,src.use_break,src.use_lunch,  
 src.re_run_units,src.over_run_units,src.use_break,src.use_lunch,  
 src.crew_size_actual,src.crew_size_actual , IIF(@from_schedule_production = 1 , NULL , src.inserted_by)  
 , IIF(@from_schedule_production = 1 , NULL , src.inserted_by)  
 , IIF(@from_schedule_production = 1 , @status_id ,COALESCE(src.status_id, @status_id)) 				-- Added by REVFOODDOR-104 06/14/2018
 --,@status_id   -- Commented by REVFOODDOR-104 06/14/2018
 --src.re_run,src.over_run,src.break_use,src.lunch_use  
 )  
 WHEN MATCHED AND (isnull(src.inserted_by,'') <> 'AppleCore') THEN           
    UPDATE SET trg.line_facility_id = (CASE WHEN @from_schedule_production = 1 THEN src.line_facility_id ELSE isnull(trg.line_facility_id,src.line_facility_id) END) ,           
   trg.shift_id = src.shift_id,           
   trg.item_id = src.item_id,           
   trg.per = src.per,           
   
   trg.qty = (case when src.deleted_by is not null then 
				CASE WHEN @from_schedule_production = 1 AND trg.production_modifiedby IS NOT NULL AND isnull(trg.act_qty,0) > 0 THEN trg.qty ELSE src.qty END 
				else src.qty end)   ,          
   
   trg.act_qty = (CASE WHEN @from_schedule_production = 1 
					  THEN CASE WHEN trg.production_modifiedby IS NULL THEN src.qty ELSE trg.act_qty END 
					  ELSE src.act_qty 
					  END) ,       
   trg.schedule_date = src.schedule_date,               
   
   trg.modified_date = COALESCE(src.modified_date, trg.modified_date),           
   trg.modified_by = COALESCE(src.modified_by, trg.modified_by),           
  
  -- Added On Date 13042018  
  trg.seq_no = (case when @from_schedule_production = 1 then   
       case when trg.line_facility_id <>  src.line_facility_id then ([dbo].[fn_GetMaxSeqNumberForvarient](src.schedule_date,src.line_facility_id,null
	   ,@from_schedule_production))     
       else trg.seq_no end   
      else trg.seq_no end) ,   
  trg.seq_no_prod = (case when @from_schedule_production = 1 then   
		   case when trg.line_facility_id <>  src.line_facility_id AND trg.production_modifiedby IS NULL then ([dbo].[fn_GetMaxSeqNumberForvarient](src.schedule_date,src.line_facility_id,null
		   ,@from_schedule_production))  
		   else trg.seq_no_prod end  
         else   
		   case when trg.production_line_facility_id <>  src.line_facility_id then ([dbo].[fn_GetMaxSeqNumberForvarient](src.schedule_date,src.line_facility_id
		   ,null,@from_schedule_production))  
		   else trg.seq_no_prod end  
         end) ,   
    
  trg.nitemseqplaning = (case when @from_schedule_production = 1 then   
       case when trg.line_facility_id <>  src.line_facility_id then ([dbo].[fn_GetMaxSeqNumberForvarient](src.schedule_date,src.line_facility_id,src.item_id
	   ,@from_schedule_production))     
       else trg.nitemseqplaning end   
      else trg.nitemseqplaning end) ,   
  
  trg.nitemseqproduction = (case when @from_schedule_production = 1 then   
		   case when trg.line_facility_id <>  src.line_facility_id AND trg.production_modifiedby IS NULL then ([dbo].[fn_GetMaxSeqNumberForvarient](src.schedule_date,src.line_facility_id,src.item_id
		   ,@from_schedule_production))  
		   else trg.nitemseqproduction end  
         else   
		   case when trg.production_line_facility_id <>  src.line_facility_id then ([dbo].[fn_GetMaxSeqNumberForvarient](src.schedule_date,src.line_facility_id,
		   src.item_id,@from_schedule_production))  
		   else trg.nitemseqproduction end  
         end),  
  
  
  trg.start_time = src.start_time,        
  trg.end_time = src.end_time,        
  trg.item_product_variation_id = src.item_product_variation_id,        
  trg.comment = src.comment,      
  trg.production_comment = src.production_comment,      
  
  trg.production_start_time = (CASE WHEN @from_schedule_production = 1 
								THEN CASE WHEN trg.production_modifiedby IS NULL THEN src.production_start_time ELSE trg.production_start_time END
								ELSE src.production_start_time END),        

  trg.production_end_time = (CASE WHEN @from_schedule_production = 1 
								THEN CASE WHEN trg.production_modifiedby IS NULL THEN src.production_end_time ELSE trg.production_end_time END
								ELSE src.production_end_time END),
    
  trg.production_line_facility_id =   (CASE WHEN @from_schedule_production = 1 
								THEN CASE WHEN trg.production_modifiedby IS NULL THEN src.line_facility_id ELSE trg.production_line_facility_id END
								ELSE src.line_facility_id END)   , --(CASE WHEN @from_schedule_production = 1 THEN src.line_facility_id ELSE trg.production_line_facility_id END) ,  

  trg.ncrewplaning =  (CASE WHEN @from_schedule_production = 1 THEN src.crew ELSE trg.ncrewplaning END),  
  trg.nspeedplaning = (CASE WHEN @from_schedule_production = 1 THEN convert(numeric(18,2),src.t_max/60) ELSE trg.nspeedplaning END),  
  
  trg.nlinehrsplaning = (CASE WHEN @from_schedule_production = 1 THEN CASE WHEN src.crew IS NOT NULL AND isnull(src.t_max,0) > 0 AND isnull(src.per,0) > 0 
  THEN CAST((( COALESCE(src.qty,trg.qty) / src.t_max) * (1.0/src.per)) * 100 AS DECIMAL(16,8))ELSE NULL END ELSE trg.nlinehrsplaning END),  

  trg.ncrewproduction =   (CASE WHEN @from_schedule_production = 1 
								THEN CASE WHEN trg.production_modifiedby IS NULL THEN src.crew ELSE trg.ncrewproduction END
								ELSE src.crew END)  ,  
  trg.nspeedproduction =    (CASE WHEN @from_schedule_production = 1 
								THEN CASE WHEN trg.production_modifiedby IS NULL THEN convert(numeric(18,2),src.t_max/60) ELSE trg.nspeedproduction END
								ELSE convert(numeric(18,2),src.t_max/60) END) ,
  
  trg.nlinehrsproduction =  (CASE WHEN @from_schedule_production = 1 
								THEN CASE WHEN trg.production_modifiedby IS NULL THEN (CASE WHEN src.crew IS NOT NULL AND isnull(src.t_max,0) > 0 AND isnull(src.per,0) > 0 THEN CAST(((src.act_qty/src.t_max) * (1.0/src.per)) * 100 
										AS DECIMAL(16,8))ELSE NULL END) ELSE trg.nlinehrsproduction END
								ELSE (CASE WHEN src.crew IS NOT NULL AND isnull(src.t_max,0) > 0 AND isnull(src.per,0) > 0 THEN CAST(((src.act_qty/src.t_max) * (1.0/src.per)) * 100 
										AS DECIMAL(16,8))ELSE NULL END) END),  
  trg.isproductionchanged =  0,  

  trg.re_run_planing = (CASE WHEN @from_schedule_production = 1 THEN src.re_run_units ELSE trg.re_run_planing END),  
  trg.over_run_planing = (CASE WHEN @from_schedule_production = 1 THEN src.over_run_units ELSE trg.over_run_planing END),  
  trg.break_use_planing = (CASE WHEN @from_schedule_production = 1 THEN src.use_break ELSE trg.break_use_planing END),  
  trg.lunch_use_planing = (CASE WHEN @from_schedule_production = 1 THEN src.use_lunch ELSE trg.lunch_use_planing END),  
  trg.crew_size_actual_planing = (CASE WHEN @from_schedule_production = 1 THEN src.crew_size_actual ELSE trg.crew_size_actual_planing END),  

  
  trg.re_run_production = (CASE WHEN @from_schedule_production = 1 
								THEN CASE WHEN trg.production_modifiedby IS NULL THEN src.re_run_units ELSE trg.re_run_production END
								ELSE src.re_run_units END),  
  trg.over_run_production =  (CASE WHEN @from_schedule_production = 1 
								THEN CASE WHEN trg.production_modifiedby IS NULL THEN src.over_run_units ELSE trg.over_run_production END
								ELSE src.over_run_units END),  
  trg.break_use_production = (CASE WHEN @from_schedule_production = 1 
								THEN CASE WHEN trg.production_modifiedby IS NULL THEN src.use_break ELSE trg.break_use_production END
								ELSE src.use_break END),  
  trg.lunch_use_production = (CASE WHEN @from_schedule_production = 1 
								THEN CASE WHEN trg.production_modifiedby IS NULL THEN src.use_lunch ELSE trg.lunch_use_production END
								ELSE src.use_lunch END),  
  trg.crew_size_actual_production = (CASE WHEN @from_schedule_production = 1 
								THEN CASE WHEN trg.production_modifiedby IS NULL THEN src.crew_size_actual ELSE trg.crew_size_actual_production END
								ELSE src.crew_size_actual END),
 
  trg.production_modifiedby = (CASE WHEN @from_schedule_production = 1 THEN trg.production_modifiedby ELSE src.modified_by END) ,
   trg.status_id = (CASE WHEN @from_schedule_production = 1 THEN trg.status_id ELSE src.status_id END)   
    
  --Case When @from_schedule_production = 0 --@from_schedule_production = 1    
  --       THEN  CASE WHEN   
  --  ( src.qty  = src.act_qty   AND  src.start_time =   src.production_start_time   AND  src.end_time =  src.production_end_time  
  --  AND (trg.production_line_facility_id = src.line_facility_id)  
  --  ) THEN 0 ELSE 1 END    
  --       ELSE  trg.isproductionchanged  END  
   --,trg.nitemseqproduction = CASE WHEN trg.nitemseqproduction is null THEN src.ProductSqNo ELSE (CASE WHEN @from_schedule_production = 1 THEN trg.nitemseqplaning ELSE isnull(trg.nitemseqproduction,src.ProductSqNo) END) END,  
  --trg.nitemseqplaning = isnull(trg.nitemseqplaning,src.ProductSqNo)  
  
 OUTPUT 
 INSERTED.schedule_id,INSERTED.deleted_date,INSERTED.deleted_by, DELETED.seq_no, INSERTED.seq_no, INSERTED.modified_by, 
 DELETED.production_line_facility_id , INSERTED.production_line_facility_id
 ,case when @from_schedule_production = 1 then DELETED.start_time ELSE DELETED.production_start_time END
 ,case when @from_schedule_production = 1 then DELETED.end_time ELSE DELETED.production_end_time END   
 ,case when @from_schedule_production = 1 then INSERTED.start_time ELSE INSERTED.production_start_time END
 ,case when @from_schedule_production = 1 then INSERTED.end_time ELSE INSERTED.production_end_time END  
 ,case when @from_schedule_production = 1 then DELETED.line_facility_id ELSE DELETED.production_line_facility_id END  
 ,case when @from_schedule_production = 1 then INSERTED.line_facility_id ELSE INSERTED.production_line_facility_id END  
 ,case when @from_schedule_production = 1 then DELETED.seq_no ELSE DELETED.seq_no_prod END  
 ,case when @from_schedule_production = 1 then INSERTED.seq_no ELSE INSERTED.seq_no_prod END  
 ,case when @from_schedule_production = 1 then DELETED.nitemseqplaning ELSE DELETED.nitemseqproduction END  
 ,case when @from_schedule_production = 1 then INSERTED.nitemseqplaning ELSE INSERTED.nitemseqproduction END 
 ,$action
 INTO  #shift_entry;          

--select * from #shift_entry

Declare @deleted_by varchar(30),@IS_Delete int,@schedule_date datetime,@modified_by varchar(250),@inserted_by varchar(250)

SELECT  top 1 @deleted_by = a.deleted_by  ,@IS_Delete = (case when a.deleted_by is not null then 
						CASE WHEN @from_schedule_production = 1 AND b.production_modifiedby IS NOT NULL AND isnull(b.act_qty,0) > 0 THEN 1 ELSE 0 END 
				else 0 end),@schedule_date = a.schedule_date,@modified_by = a.modified_by,@inserted_by = a.inserted_by


	FROM   OPENXML(@hDoc, 'schedules/schedule',3)           
        WITH ( [deleted_by]        varchar(30),
		          [schedule_id] INT,
				  [schedule_date]   [DATETIME],
				  [modified_by]   varchar(30),
				  [inserted_by]		varchar(30)
				    
 ) AS a 
  INNER JOIN RF_DWH_SCHEDULE b   ON a.schedule_id = b.schedule_id    
 


  if(@deleted_by IS NOT NULL OR @deleted_by <> '')   
  Begin
	
	-- This Condition Is for Planing not Delete When Production is Done
	if (@IS_Delete > 0)
		begin
			SET @error_message = 'Production is over!'
		end
	 
	 Update b Set b.deleted_date = getdate(),      
     b.deleted_by = @deleted_by      
     From RF_DWH_SCHEDULE b      
	 JOIN #shift_entry a      
     ON a.schedule_id = b.schedule_id         
     where qty IS NULL AND act_qty IS NULL      
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
   
  IF  (@from_schedule_production <> 1) 
	begin
		
		
		--;with CTE_Update as(
		--	select lf.facility_id , line_facility_id from RF_DWH_SCHEDULE s
		--	INNER JOIN RF_DWH_XREF_LINE_FACILITY lf on lf.line_facility_id =  s.production_line_facility_id
		--	where schedule_id = (select TOP 1 schedule_id from #shift_entry) 
		--),
		--cte_OrgRecord as
		--(
		--	select * from RF_DWH_SCHEDULE s
			
		--)
		--select * from CTE_Update 

		
		Update a set a.production_modifiedby = @modified_by
		FROM RF_DWH_SCHEDULE a
		where a.production_line_facility_id IN (select int_production_line_facility_id from #shift_entry) 
		AND CAST(a.schedule_date as date) = CAST (@schedule_date AS date)
		and a.act_qty IS NOT NULL
		
		Update a set a.production_modifiedby = @modified_by
		FROM RF_DWH_SCHEDULE a
		where a.production_line_facility_id IN (select del_production_line_facility_id from #shift_entry) 
		AND CAST(a.schedule_date as date) = CAST (@schedule_date AS date)
		and a.act_qty IS NOT NULL
	end

	declare  @Old_start_time  Datetime
			,@Old_end_time Datetime
			,@New_start_time Datetime
			,@New_end_time Datetime
			,@From_line_facility_id INT
			,@To_line_facility_id INT
			,@From_seq_no INT
			,@To_seq_no INT
			,@From_nitemseqplaning INT
			,@To_nitemseqplaning INT
			,@TranType varchar(250)
			,@Querytype varchar(20)
			,@typeofchanges varchar(50),@facility_id as INT



	select TOP 1  @Old_start_time = del_start_time,@Old_end_time = del_end_time,@New_start_time=int_start_time,@New_end_time=int_end_time
	,@From_line_facility_id = del_line_facility_id,@To_line_facility_id = int_line_facility_id, @From_seq_no = del_seq_no , @To_seq_no= int_seq_no
	,@From_nitemseqplaning = del_itemseqno, @To_nitemseqplaning = int_itemseqno, @TranType = trantype
	from  #shift_entry
	

/* -- Comment starts REVFOODDOR-104 06/15/2018
	IF @TranType = 'UPDATE'
		BEGIN
			IF ((@Old_start_time <> @New_start_time) OR (@From_line_facility_id <> @To_line_facility_id ))
			BEGIN
				SET @facility_id = (select TOP 1 facility_id  from RF_DWH_XREF_LINE_FACILITY where line_facility_id = @From_line_facility_id )
				SET @typeofchanges = 'StartEndTimeChange'
				if (@From_line_facility_id <> @To_line_facility_id)
					begin
						set @Querytype = 'ItemLineChange'
					end
				Else
					begin
						set @Querytype = 'VariationSeqChange'
					end
				
				IF @from_schedule_production = 1 
					BEGIN
						--print 'planing'  

						--SELECT @typeofchanges,@Querytype , @schedule_date,@facility_id,@From_line_facility_id , @To_line_facility_id,@From_seq_no ,@To_seq_no,
						--@From_nitemseqplaning,@To_nitemseqplaning
						
						EXECUTE [dbo].[usp_DOR_SCHEDULE_Change_Start_End_Time_Planning] @typeofchanges = @typeofchanges, @TranType = @Querytype , @schedule_date = @schedule_date,@facility_id = @facility_id,
						@From_line_FacilityID = @From_line_facility_id , @To_line_FacilityID = @To_line_facility_id,@SeqnoFrom = @From_seq_no , @Seqnoto = @To_seq_no,
						@FromItemSeqNo = @From_nitemseqplaning,@ToItemSeqNo = @To_nitemseqplaning

					END
					/*	-- Added for REVFOODDOR-104 06/14/2018
				ELSE
					begin
						--print 'Production'
						
						EXECUTE [dbo].[usp_DOR_SCHEDULE_Change_Start_End_Time_Production] @typeofchanges = @typeofchanges, @TranType = @Querytype , @schedule_date = @schedule_date,@facility_id = @facility_id,
						@From_line_FacilityID = @From_line_facility_id , @To_line_FacilityID = @To_line_facility_id,@SeqnoFrom = @From_seq_no , @Seqnoto = @To_seq_no,
						@FromItemSeqNo = @From_nitemseqplaning,@ToItemSeqNo = @To_nitemseqplaning
					end

				*/	-- Added for REVFOODDOR-104 06/14/2018	
				
			END
		END
*/ -- Comment ends REVFOODDOR-104 06/15/2018
	--IF (@inserted_by is not null AND @from_schedule_production = 1)
	--	BEGIN
	--		Update a set a.production_modifiedby = @inserted_by
	--		FROM RF_DWH_SCHEDULE a
	--		where a.production_line_facility_id IN (select int_production_line_facility_id from #shift_entry) 
	--		AND CAST(a.schedule_date as date) = CAST (@schedule_date AS date)
	--		and a.act_qty IS NOT NULL

	--	END
	
	EXEC sp_xml_removedocument @hDoc
   COMMIT TRANSACTION;  
   
   END TRY          
   BEGIN CATCH          
   SELECT @error_message = ERROR_MESSAGE();          
   
   if (XACT_STATE() = -1)  
	  begin  
	   ROLLBACK TRANSACTION;  
	  end  
	 if (XACT_STATE() = 1)  
	  begin  
	   COMMIT TRANSACTION;  
	  end  
  END CATCH          
           
 --IF @@TRANCOUNT > 0          
 --COMMIT;          
END   
