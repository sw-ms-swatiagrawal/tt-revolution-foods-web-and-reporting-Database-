CREATE PROCEDURE [dbo].[usp_DOR_SCHEDULE_Change_VarientSeqno]
(
@fromschedule_id int,
@toschedule_id int,
@isplaning bit,
@modified_by varchar(50) = null,
@error_message varchar(MAX) output
)

as

SET NOCOUNT ON;        
BEGIN TRANSACTION;

BEGIN TRY    
	DECLARE @schedule_date datetime

	if (@isplaning = 1)
		BEGIN
			declare @changeproduction as int = (select COUNT(*) from 
												RF_DWH_SCHEDULE SC INNER JOIN RF_DWH_XREF_LINE_FACILITY f on f.line_facility_id = sc.line_facility_id
												WHERE cast(sc.schedule_date as date) = cast((select TOP 1 schedule_date from RF_DWH_SCHEDULE WHERE schedule_id = @fromschedule_id)  as date) AND sc.production_modifiedby IS NOT NULL
												AND f.facility_id = (select TOP 1 facility_id from RF_DWH_XREF_LINE_FACILITY where  line_facility_id = (select TOP 1 line_facility_id from RF_DWH_SCHEDULE WHERE schedule_id = @fromschedule_id)))
			set @changeproduction = isnull(@changeproduction,0)
			declare @SeqnoFrom int  = (select seq_no from RF_DWH_SCHEDULE where schedule_id = @fromschedule_id)
			declare @Seqnoto int  = (select seq_no from RF_DWH_SCHEDULE where schedule_id = @toschedule_id)
			
			Update RF_DWH_SCHEDULE set seq_no = @Seqnoto
			where schedule_id = @fromschedule_id
			
			Update RF_DWH_SCHEDULE set seq_no = @SeqnoFrom
			where schedule_id = @toschedule_id

			if isnull(@changeproduction,0) = 0
				begin
					Update RF_DWH_SCHEDULE set seq_no_prod = @Seqnoto
					where schedule_id = @fromschedule_id

					Update RF_DWH_SCHEDULE set seq_no_prod = @SeqnoFrom
					where schedule_id = @toschedule_id			
				end
            
			
			SET @schedule_date = (select TOP 1 schedule_date from RF_DWH_SCHEDULE where schedule_id = @fromschedule_id)
			DECLARE @facility_id as INT = (SELECT TOP 1 fl.facility_id FROM RF_DWH_SCHEDULE s
											INNER JOIN RF_DWH_XREF_LINE_FACILITY fl ON fl.line_facility_id = s.line_facility_id
											WHERE schedule_id = @fromschedule_id)
			DECLARE @fromline_facility_id as INT = (select TOP 1 line_facility_id from RF_DWH_SCHEDULE where schedule_id = @fromschedule_id)
			DECLARE @FromItemSeqNo as INT = (select min(nitemseqplaning) from RF_DWH_SCHEDULE where schedule_id in (@fromschedule_id,@toschedule_id) )
			

			--SELECT 'SeqChange','VariationSeqChange' ,@schedule_date ,@facility_id ,@fromline_facility_id , @fromline_facility_id ,
			--@SeqnoFrom, @Seqnoto, @FromItemSeqNo, @FromItemSeqNo

			/*-- Comment starts REVFOODDOR-104 06/15/2018
			EXECUTE [dbo].[usp_DOR_SCHEDULE_Change_Start_End_Time_Planning] @typeofchanges = 'SeqChange',@TranType= 'VariationSeqChange' , @schedule_date = @schedule_date ,
			@facility_id = @facility_id , @From_line_FacilityID = @fromline_facility_id , @To_line_FacilityID = @fromline_facility_id ,
			@SeqnoFrom = @SeqnoFrom, @Seqnoto = @Seqnoto, @FromItemSeqNo = @FromItemSeqNo, @ToItemSeqNo = @FromItemSeqNo
			*/-- Comment ends REVFOODDOR-104 06/15/2018
		END
	ELSE 
	BEGIN
		DECLARE @production_line_facility_id INT 
		select top 1 @production_line_facility_id = production_line_facility_id , @schedule_date = schedule_date
		FROM RF_DWH_SCHEDULE where  schedule_id = @fromschedule_id
		
		set @SeqnoFrom   = (select seq_no_prod from RF_DWH_SCHEDULE where schedule_id = @fromschedule_id)
		set @Seqnoto = (select seq_no_prod from RF_DWH_SCHEDULE where schedule_id = @toschedule_id)
	
		Update RF_DWH_SCHEDULE set seq_no_prod = @Seqnoto
		where schedule_id = @fromschedule_id

		Update RF_DWH_SCHEDULE set seq_no_prod = @SeqnoFrom
		where schedule_id = @toschedule_id

		---- This is For UPdate All Line Facility ID production_modifiedby
		
		Update a set a.production_modifiedby = @modified_by
		FROM RF_DWH_SCHEDULE a
		where a.production_line_facility_id = @production_line_facility_id
		AND CAST(a.schedule_date as date) = CAST (@schedule_date AS date)
		and a.act_qty IS NOT NULL


		SET @facility_id = (SELECT TOP 1 fl.facility_id FROM RF_DWH_SCHEDULE s
									INNER JOIN RF_DWH_XREF_LINE_FACILITY fl ON fl.line_facility_id = s.production_line_facility_id
		 							WHERE schedule_id = @fromschedule_id)
		--SET @fromline_facility_id = (select TOP 1 production_line_facility_id from RF_DWH_SCHEDULE where schedule_id = @fromschedule_id)

		SET @fromline_facility_id = @production_line_facility_id
		SET @FromItemSeqNo = (select min(nitemseqproduction) from RF_DWH_SCHEDULE where schedule_id in (@fromschedule_id,@toschedule_id) )
		
		--SELECT 'SeqChange','VariationSeqChange' , @schedule_date ,@facility_id , @fromline_facility_id , @fromline_facility_id ,@SeqnoFrom, @Seqnoto, @FromItemSeqNo, @FromItemSeqNo
		/*-- Comment starts REVFOODDOR-104 06/14/2018
		EXECUTE [dbo].[usp_DOR_SCHEDULE_Change_Start_End_Time_Production] @typeofchanges = 'SeqChange',@TranType= 'VariationSeqChange' , @schedule_date = @schedule_date ,
		@facility_id = @facility_id , @From_line_FacilityID = @fromline_facility_id , @To_line_FacilityID = @fromline_facility_id ,
		@SeqnoFrom = @SeqnoFrom, @Seqnoto = @Seqnoto, @FromItemSeqNo = @FromItemSeqNo, @ToItemSeqNo = @FromItemSeqNo
		*/ -- Comment ends REVFOODDOR-104 06/14/2018
	end

	COMMIT TRANSACTION;
END TRY

BEGIN CATCH        
        
   SELECT @error_message = ERROR_MESSAGE();        
   
   IF (XACT_STATE() = -1)
	begin
		ROLLBACK TRANSACTION;
	end
	IF (XACT_STATE() = 1)
	begin
		COMMIT TRANSACTION;
	end
END CATCH

