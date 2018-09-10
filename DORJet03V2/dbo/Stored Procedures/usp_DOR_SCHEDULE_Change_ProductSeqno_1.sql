CREATE PROCEDURE [dbo].[usp_DOR_SCHEDULE_Change_ProductSeqno]  
(  
@fromitem_id int,  
@toitem_id int,  
@schedule_date datetime,  
@line_facility_id as INT,  
@isplaning bit,  
@modified_by varchar(50) = null,
@error_message varchar(MAX) output  
)  
  
as  
  
SET NOCOUNT ON;          
BEGIN TRANSACTION;  
  
BEGIN TRY     
   
      
 if @isplaning = 1  
  begin 
   declare @changeproduction as int = (select COUNT(*) from 
												RF_DWH_SCHEDULE SC INNER JOIN RF_DWH_XREF_LINE_FACILITY f on f.line_facility_id = sc.line_facility_id
												WHERE cast(sc.schedule_date as date) = cast(@schedule_date as date) AND sc.production_modifiedby IS NOT NULL
												AND f.facility_id = (select TOP 1 facility_id from RF_DWH_XREF_LINE_FACILITY where  line_facility_id = @line_facility_id))
	set @changeproduction = isnull(@changeproduction,0)

   declare @SeqnoFrom int  = (select min(ISNULl(nitemseqplaning,0)) from RF_DWH_SCHEDULE where item_id = @fromitem_id and CAST(schedule_date as date) = CAST(@schedule_date as date) and line_facility_id = @line_facility_id AND qty is not null)
   declare @Seqnoto int  = (select min(ISNULl(nitemseqplaning,0)) from RF_DWH_SCHEDULE where item_id = @toitem_id and CAST(schedule_date as date) = CAST(@schedule_date as date) and line_facility_id = @line_facility_id AND qty is not null)
   
   --select @SeqnoFrom,@Seqnoto

	Update RF_DWH_SCHEDULE set nitemseqplaning = @Seqnoto , nitemseqproduction = IIF(isnull(@changeproduction,0) = 0 , @Seqnoto , nitemseqproduction)
    where item_id = @fromitem_id and CAST(schedule_date as date) = CAST(@schedule_date as date) and line_facility_id = @line_facility_id  
    
    Update RF_DWH_SCHEDULE set nitemseqplaning = @SeqnoFrom , nitemseqproduction = IIF(isnull(@changeproduction,0) = 0 , @SeqnoFrom , nitemseqproduction) 
    where item_id = @toitem_id and CAST(schedule_date as date) = CAST(@schedule_date as date) and line_facility_id = @line_facility_id  
   
    declare @FromItemSeqNo as int = (select min(ISNULl(seq_no,0)) from RF_DWH_SCHEDULE where item_id = @fromitem_id and CAST(schedule_date as date) = CAST(@schedule_date as date) and line_facility_id = @line_facility_id AND qty is not null)
	declare @ToItemSeqNo as int = (select min(ISNULl(seq_no,0)) from RF_DWH_SCHEDULE where item_id = @toitem_id and CAST(schedule_date as date) = CAST(@schedule_date as date) and line_facility_id = @line_facility_id AND qty is not null)

    DECLARE @facility_id as INT = (SELECT min(fl.facility_id) FROM RF_DWH_SCHEDULE s
											INNER JOIN RF_DWH_XREF_LINE_FACILITY fl ON fl.line_facility_id = s.line_facility_id
											WHERE item_id = @fromitem_id AND qty is not null)
   /*-- Comment starts REVFOODDOR-104 06/15/2018
   EXECUTE [dbo].[usp_DOR_SCHEDULE_Change_Start_End_Time_Planning] @typeofchanges = 'SeqChange', @TranType= 'ItemSeqChange' , @schedule_date = @schedule_date ,
   @facility_id = @facility_id , @From_line_FacilityID = @line_facility_id , @To_line_FacilityID = @line_facility_id ,
   @SeqnoFrom = @FromItemSeqNo, @Seqnoto = @ToItemSeqNo, @FromItemSeqNo = @SeqnoFrom, @ToItemSeqNo = @Seqnoto
	*/-- Comment ends REVFOODDOR-104 06/15/2018
   
   --Update RF_DWH_SCHEDULE set nitemseqproduction = @Seqnoto  
   --where item_id = @fromitem_id and CAST(schedule_date as date) = CAST(@schedule_date as date) and line_facility_id   = @line_facility_id  
   --Update RF_DWH_SCHEDULE set nitemseqproduction = @SeqnoFrom  
   --where item_id = @toitem_id and CAST(schedule_date as date) = CAST(@schedule_date as date) and line_facility_id = @line_facility_id  


  end  
 else   
  begin  
   SET @SeqnoFrom  = (select min(Isnull(nitemseqproduction,0)) from RF_DWH_SCHEDULE where item_id = @fromitem_id and CAST(schedule_date as date) = CAST(@schedule_date as date) and production_line_facility_id = @line_facility_id AND act_qty is not null)
   SET @Seqnoto = (select min(isnull(nitemseqproduction,0)) from RF_DWH_SCHEDULE where item_id = @toitem_id and CAST(schedule_date as date) = CAST(@schedule_date as date) and production_line_facility_id = @line_facility_id AND act_qty is not null)
   
   Update RF_DWH_SCHEDULE set nitemseqproduction = @Seqnoto  
   where item_id = @fromitem_id and CAST(schedule_date as date) = CAST(@schedule_date as date) and production_line_facility_id = @line_facility_id  
  
   Update RF_DWH_SCHEDULE set nitemseqproduction = @SeqnoFrom  
   where item_id = @toitem_id and CAST(schedule_date as date) = CAST(@schedule_date as date) and production_line_facility_id = @line_facility_id
   
   ---- This is For UPdate All Line Facility ID production_modifiedby

   Update a set a.production_modifiedby = @modified_by
   FROM RF_DWH_SCHEDULE a
   where a.production_line_facility_id = @line_facility_id
   AND CAST(a.schedule_date as date) = CAST (@schedule_date AS date)
   AND a.act_qty IS NOT NULL
   
   SET @FromItemSeqNo = (select min(ISNULl(seq_no_prod,0)) from RF_DWH_SCHEDULE where item_id = @fromitem_id and CAST(schedule_date as date) = CAST(@schedule_date as date) and production_line_facility_id = @line_facility_id AND act_qty IS not null)
   SET @ToItemSeqNo = (select min(ISNULl(seq_no_prod,0)) from RF_DWH_SCHEDULE where item_id = @toitem_id and CAST(schedule_date as date) = CAST(@schedule_date as date) and production_line_facility_id = @line_facility_id AND act_qty IS not null)
  
   SET @facility_id = (SELECT min(fl.facility_id) FROM RF_DWH_SCHEDULE s
						INNER JOIN RF_DWH_XREF_LINE_FACILITY fl ON fl.line_facility_id = s.line_facility_id
						WHERE item_id = @fromitem_id AND act_qty is not null)
   
   /*-- Comment starts REVFOODDOR-104 06/14/2018
   EXECUTE [dbo].[usp_DOR_SCHEDULE_Change_Start_End_Time_Production] @typeofchanges = 'SeqChange',@TranType= 'ItemSeqChange' , @schedule_date = @schedule_date ,
   @facility_id = @facility_id , @From_line_FacilityID = @line_facility_id , @To_line_FacilityID = @line_facility_id ,
   @SeqnoFrom = @FromItemSeqNo, @Seqnoto = @ToItemSeqNo, @FromItemSeqNo = @SeqnoFrom, @ToItemSeqNo = @Seqnoto
   */ -- Comment ends REVFOODDOR-104 06/14/2018
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

