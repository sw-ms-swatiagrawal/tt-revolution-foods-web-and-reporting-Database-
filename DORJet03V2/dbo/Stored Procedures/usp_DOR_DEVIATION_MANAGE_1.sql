CREATE Procedure [dbo].[usp_DOR_DEVIATION_MANAGE]       
@shedule_id int,  
@accept_reject int, ---  0 For Accept, 1 For Reject , NULL No Action Taken  
@error_message varchar(MAX) output    
as    
Begin  
SET NOCOUNT ON;  
  
BEGIN TRANSACTION;    
BEGIN TRY  
DECLARE @status_id INT = (SELECT status_id from RF_DWH_STATUS WHERE status_desc= 'Not Completed')		-- Comments Moving Jet03 changes to Jet02 23/07/2018

 UPDATE RF_DWH_DEVIATION set accept_reject = @accept_reject  
 WHERE schedule_id = @shedule_id;  
   
 IF (@accept_reject = 0)  
  BEGIN  

	  DECLARE @Qty int = (SELECT TOP 1 isnull(deviation_qty,0) FROM RF_DWH_DEVIATION WHERE schedule_id = @shedule_id)  
	  ;WITH CTE_AcceptDevi as (
	  SELECT rfs.ncrewplaning as crew,
			 Convert(numeric(18,2),(isnull((CASE WHEN UPPER(e.line_cd) LIKE 'FLOW WRAP%' THEN pv.over_wrap_t_max              
			 WHEN UPPER(e.line_cd) LIKE 'SINGLE PRO%' THEN pv.pro_seal_single_t_max              
			 WHEN UPPER(e.line_cd) LIKE 'TWIN PRO%' THEN pv.pro_seal_twin_t_max              
			 WHEN UPPER(e.line_cd) LIKE 'TABLE' THEN pv.table_t_max              
			END),0))) as t_max , rfs.per ,qty , act_qty , rfs.ncrewplaning , rfs.ncrewproduction , rfs.nspeedplaning , rfs.nspeedproduction , 
			rfs.nlinehrsplaning , rfs.nlinehrsproduction 
			,rfs.status_id																				-- Comments Moving Jet03 changes to Jet02 23/07/2018
	  FROM RF_DWH_SCHEDULE rfs
	  LEFT JOIN RF_DWH_XREF_LINE_FACILITY b ON b.line_facility_id = rfs.line_facility_id 
	  LEFT JOIN RF_DWH_LINE  e ON e.line_id = b.line_id
	  LEFT JOIN XREF_ITEM_PRODUCT_VARIATION pv on pv.item_product_variation_id = rfs.item_product_variation_id   
	  WHERE schedule_id = @shedule_id  
	  )
	  Update CTE_AcceptDevi SET  qty = isnull(@Qty,0) , act_qty = isnull(@Qty,0) , ncrewplaning = crew , ncrewproduction = crew,
	  nspeedplaning = convert(numeric(18,2),t_max/60),nspeedproduction = convert(numeric(18,2),t_max/60),
	  nlinehrsplaning = CASE WHEN crew IS NOT NULL AND isnull(t_max,0) > 0 AND isnull(per,0) > 0 THEN CAST(((isnull(@Qty,0)/t_max) * (1.0/per)) * 100 AS DECIMAL(16,8))ELSE NULL END,
	  nlinehrsproduction = CASE WHEN crew IS NOT NULL AND isnull(t_max,0) > 0 AND isnull(per,0) > 0 THEN CAST(((isnull(@Qty,0)/t_max) * (1.0/per)) * 100 AS DECIMAL(16,8))ELSE NULL END,
	  status_id =@status_id																				-- Comments Moving Jet03 changes to Jet02 23/07/2018
	  
	  --select * from CTE_AcceptDevi
	  --UPDATE RF_DWH_SCHEDULE set qty = isnull(@Qty,0) , act_qty = isnull(@Qty,0)  
	  --WHERE schedule_id = @shedule_id;  
	  declare @schedule_date as datetime,@facility_id as INT,@From_line_facility_id AS INT,@From_seq_no as INT,@From_nitemseqplaning as INT
	  
	  select @schedule_date = s.schedule_date , @facility_id = lf.facility_id , @From_line_facility_id = s.line_facility_id , @From_seq_no = s.seq_no , @From_nitemseqplaning = s.nitemseqplaning 
	  from RF_DWH_SCHEDULE s
	  inner join RF_DWH_XREF_LINE_FACILITY lf on lf.line_facility_id = s.line_facility_id
	  where s.schedule_id = @shedule_id
	
	  /* -- Comment starts REVFOODDOR-104 06/18/2018
	  EXECUTE [dbo].[usp_DOR_SCHEDULE_Change_Start_End_Time_Planning] @typeofchanges = 'StartEndTimeChange', @TranType = 'VariationSeqChange' , @schedule_date = @schedule_date,@facility_id = @facility_id,
	  @From_line_FacilityID = @From_line_facility_id , @To_line_FacilityID = @From_line_facility_id,@SeqnoFrom = @From_seq_no , @Seqnoto = @From_seq_no,
	  @FromItemSeqNo = @From_nitemseqplaning,@ToItemSeqNo = @From_nitemseqplaning
	 */ -- Comment ends REVFOODDOR-104 06/18/2018
 END  
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
  
  End
