CREATE PROCEDURE [dbo].[usp_DOR_SCHEDULE_Change_Line_Product]
(
@facility_id int,
@fromline_id int,
@toline_id int,
@schedule_date datetime,
@item_id as INT,
@isplaning bit,
@modified_by varchar(50) = null,
@error_message varchar(MAX) output
)

as

SET NOCOUNT ON;        
BEGIN TRANSACTION;

BEGIN TRY
	declare @fromline_facility_id int = (select top 1 line_facility_id from RF_DWH_XREF_LINE_FACILITY where facility_id = @facility_id and line_id = @fromline_id)
	declare @toline_facility_id int = (select top 1 line_facility_id from RF_DWH_XREF_LINE_FACILITY where facility_id = @facility_id and line_id = @toline_id) 
	DECLARE @ItemExistsID as INT, @MaxSeqno as INT ,@MaxProdSeqNo as int
	if @isplaning = 1
		begin
			declare @changeproduction as int = (select COUNT(*) from 
												RF_DWH_SCHEDULE SC INNER JOIN RF_DWH_XREF_LINE_FACILITY f on f.line_facility_id = sc.line_facility_id
												WHERE cast(sc.schedule_date as date) = cast(@schedule_date as date) AND sc.production_modifiedby IS NOT NULL
												AND f.facility_id = @facility_id ) 		
			
			DECLARE @SeqnoFrom AS INT = (select MIN(seq_no) from RF_DWH_SCHEDULE where cast(schedule_date as date) = cast(@schedule_date as date) 
										 AND line_facility_id = @fromline_facility_id AND item_id = @item_id AND qty IS NOT NULL)
			
			DECLARE @FromItemSeqNo AS INT = (select MIN(nitemseqplaning) from RF_DWH_SCHEDULE where cast(schedule_date as date) = cast(@schedule_date as date) 
										 AND line_facility_id = @fromline_facility_id AND item_id = @item_id AND qty IS NOT NULL)

			set @changeproduction = isnull(@changeproduction,0)	
			
			
			set @ItemExistsID = (select max(nitemseqplaning) from RF_DWH_SCHEDULE where cast(schedule_date as date) = cast(@schedule_date as date) AND  item_id = @item_id 
			AND line_facility_id = @toline_facility_id AND qty is not null )

			set @MaxSeqno = (select max(isnull(seq_no,0)) 
			from RF_DWH_SCHEDULE sc
			INNER JOIN RF_DWH_XREF_LINE_FACILITY lf on lf.line_facility_id = sc.line_facility_id 
			WHERE cast(sc.schedule_date as date) = cast(@schedule_date as date) AND sc.qty is not null AND lf.facility_id = @facility_id)
			
			
			if @ItemExistsID IS NULL
				BEGIN
					SET @MaxProdSeqNo = (select max(nitemseqplaning) from RF_DWH_SCHEDULE where cast(schedule_date as date) = cast(@schedule_date as date))
					SET @MaxProdSeqNo = isnull(@MaxProdSeqNo,0) + 1

				END
			ELSE	
				BEGIN
					SET @MaxProdSeqNo = @ItemExistsID
				END
			
			; WITH cte as (
			select  isnull(@MaxSeqno,0) + ROW_NUMBER() over (order by sc.nitemseqplaning,sc.seq_no) as NewSeqNo ,*
			from RF_DWH_SCHEDULE sc
			where sc.item_id = @item_id and cast(sc.schedule_date as date) =  cast(@schedule_date as date) and sc.line_facility_id = @fromline_facility_id and sc.qty is not null
			)
			Update cte set nitemseqplaning = @MaxProdSeqNo , line_facility_id = @toline_facility_id 
			, production_line_facility_id = IIF(isnull(@changeproduction,0) = 0, @toline_facility_id,production_line_facility_id) 
			, nitemseqproduction = IIF(isnull(@changeproduction,0) = 0, @MaxProdSeqNo,nitemseqproduction),
			seq_no = NewSeqNo, seq_no_prod = IIF(isnull(@changeproduction,0) = 0, NewSeqNo,seq_no_prod)
			
			--where item_id = @item_id and cast(schedule_date as date) =  cast(@schedule_date as date) and line_facility_id = @fromline_facility_id and qty is not null
			
			DECLARE @Seqnoto as INT = (select MIN(seq_no) from RF_DWH_SCHEDULE where cast(schedule_date as date) = cast(@schedule_date as date) 
										 AND line_facility_id = @toline_facility_id AND item_id = @item_id AND qty IS NOT NULL)
			
			DECLARE @ToItemSeqNo as INT = (select MIN(nitemseqplaning) from RF_DWH_SCHEDULE where cast(schedule_date as date) = cast(@schedule_date as date)
										 AND line_facility_id = @toline_facility_id AND item_id = @item_id AND qty IS NOT NULL)
			
			/* -- Comment ends REVFOODDOR-104 06/15/2018
			EXECUTE [dbo].[usp_DOR_SCHEDULE_Change_Start_End_Time_Planning] @typeofchanges = 'SeqChange', @TranType= 'ItemLineChange' , @schedule_date = @schedule_date ,
			@facility_id = @facility_id , @From_line_FacilityID = @fromline_facility_id , @To_line_FacilityID = @toline_facility_id ,
			@SeqnoFrom = @SeqnoFrom, @Seqnoto = @Seqnoto, @FromItemSeqNo = @FromItemSeqNo, @ToItemSeqNo = @ToItemSeqNo
			*/ -- Comment ends REVFOODDOR-104 06/15/2018

			--Update RF_DWH_SCHEDULE set nitemseqproduction = @MaxProdSeqNo , production_line_facility_id = @toline_facility_id 
			--where item_id = @item_id and cast(schedule_date as date) =  cast(@schedule_date as date) and line_facility_id = @fromline_facility_id
			--and act_qty is not null
		end
	else	
		begin
			
			
			SET @SeqnoFrom = (select MIN(seq_no_prod) from RF_DWH_SCHEDULE where cast(schedule_date as date) = cast(@schedule_date as date) 
										 AND production_line_facility_id = @fromline_facility_id AND item_id = @item_id AND act_qty IS NOT NULL)
			
			SET @FromItemSeqNo = (select MIN(nitemseqproduction) from RF_DWH_SCHEDULE where cast(schedule_date as date) = cast(@schedule_date as date) 
										 AND production_line_facility_id = @fromline_facility_id AND item_id = @item_id AND act_qty IS NOT NULL)

			
			set @ItemExistsID = (select max(nitemseqproduction) from RF_DWH_SCHEDULE where cast(schedule_date as date) = cast(@schedule_date as date) AND  item_id = @item_id 
			AND production_line_facility_id = @toline_facility_id AND act_qty is not null )
			
			if @ItemExistsID IS NULL
				BEGIN
					set @MaxProdSeqNo = (select max(nitemseqproduction) from RF_DWH_SCHEDULE where cast(schedule_date as date)= cast(@schedule_date as date))
					set @MaxProdSeqNo = isnull(@MaxProdSeqNo,0) + 1
				END
			ELSE	
				BEGIN
					SET @MaxProdSeqNo = @ItemExistsID
				END
			
			set @MaxSeqno = (select max(isnull(seq_no,0)) 
			from RF_DWH_SCHEDULE sc
			INNER JOIN RF_DWH_XREF_LINE_FACILITY lf on lf.line_facility_id = sc.production_line_facility_id 
			WHERE cast(sc.schedule_date as date) = cast(@schedule_date as date) AND sc.act_qty is not null AND lf.facility_id = @facility_id)

			
			; WITH cte as (
			select  isnull(@MaxSeqno,0) + ROW_NUMBER() over (order by sc.nitemseqproduction,sc.seq_no_prod) as NewSeqNo ,*
			from RF_DWH_SCHEDULE sc
			where item_id = @item_id and cast(schedule_date as date) =  cast(@schedule_date as date) and production_line_facility_id = @fromline_facility_id
			and act_qty is not null
			)
			Update cte set nitemseqproduction = @MaxProdSeqNo , production_line_facility_id = @toline_facility_id 
			,seq_no_prod = NewSeqNo

			--Update RF_DWH_SCHEDULE set nitemseqproduction = @MaxProdSeqNo , production_line_facility_id = @toline_facility_id 
			--where item_id = @item_id and cast(schedule_date as date) =  cast(@schedule_date as date) and production_line_facility_id = @fromline_facility_id
			--and act_qty is not null

			
			---- This is For UPdate All Line Facility ID production_modifiedby

			Update a set a.production_modifiedby = @modified_by
			FROM RF_DWH_SCHEDULE a
			where a.production_line_facility_id = @fromline_facility_id
			AND CAST(a.schedule_date as date) = CAST (@schedule_date AS date)
			and a.act_qty IS NOT NULL

			Update a set a.production_modifiedby = @modified_by
			FROM RF_DWH_SCHEDULE a
			where a.production_line_facility_id = @toline_facility_id
			AND CAST(a.schedule_date as date) = CAST (@schedule_date AS date)
			and a.act_qty IS NOT NULL


			Set @Seqnoto = (select MIN(seq_no_prod) from RF_DWH_SCHEDULE where cast(schedule_date as date) = cast(@schedule_date as date) 
										 AND production_line_facility_id = @toline_facility_id AND item_id = @item_id AND act_qty IS NOT NULL)
			
			Set @ToItemSeqNo = (select MIN(nitemseqproduction) from RF_DWH_SCHEDULE where cast(schedule_date as date) = cast(@schedule_date as date)
										 AND production_line_facility_id = @toline_facility_id AND item_id = @item_id AND act_qty IS NOT NULL)
			 /*-- Comment starts REVFOODDOR-104 06/14/2018
			EXECUTE [dbo].[usp_DOR_SCHEDULE_Change_Start_End_Time_Production] @typeofchanges = 'SeqChange', @TranType= 'ItemLineChange' , @schedule_date = @schedule_date ,
			@facility_id = @facility_id , @From_line_FacilityID = @fromline_facility_id , @To_line_FacilityID = @toline_facility_id ,
			@SeqnoFrom = @SeqnoFrom, @Seqnoto = @Seqnoto, @FromItemSeqNo = @FromItemSeqNo, @ToItemSeqNo = @ToItemSeqNo
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
