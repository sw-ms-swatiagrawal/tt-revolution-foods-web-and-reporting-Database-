
CREATE Function [dbo].[fn_GetMaxSeqNumberForvarient]
(
@schedule_date as datetime,
@LineFacilityID as INT,
@ItemID as INT,
@isplaning as bit
)
RETURNS BIGINT
AS

BEGIN

	DECLARE @MaxSeqProductno BIGINT

	if (@ItemID is null)
		begin
			if (@isplaning = 1)
			begin
				set @MaxSeqProductno = (SELECT ISNULL(MAX(isnull(seq_no,0)), 0)
								FROM RF_DWH_SCHEDULE where CAST(schedule_date as date) = CAST(@schedule_date as date))
			end
		else if (@isplaning = 0)
			begin
				set @MaxSeqProductno = (SELECT ISNULL(MAX(isnull(seq_no_prod,0)), 0)
								FROM RF_DWH_SCHEDULE where CAST(schedule_date as date) = CAST(@schedule_date as date))
			end
		set @MaxSeqProductno = isnull(@MaxSeqProductno,0) + 1
		end
	else if (@ItemID is not null)
		begin
			if (@isplaning = 1)
			begin
				declare @ItemFound int = (SELECT count(*) FROM RF_DWH_SCHEDULE WHERE CAST(schedule_date as Date)
				 = CAST(@schedule_date as DATE) and line_facility_id = @LineFacilityID and item_id = @ItemID)
				set @ItemFound = isnull(@ItemFound,0)
				if (@ItemFound > 0)
					begin
						set @MaxSeqProductno = (SELECT ISNULL(MAX(isnull(nitemseqplaning,0)), 0)
							FROM RF_DWH_SCHEDULE WHERE CAST(schedule_date as Date) = CAST(@schedule_date as DATE) 
							and line_facility_id = @LineFacilityID and item_id = @ItemID)	
						set @MaxSeqProductno = isnull(@MaxSeqProductno,0)
					end
				else 
					begin
						set @MaxSeqProductno = (SELECT ISNULL(MAX(isnull(nitemseqplaning,0)), 0)
							FROM RF_DWH_SCHEDULE WHERE cast(schedule_date as DATE) = CAST(@schedule_date as DATE))
						set @MaxSeqProductno = isnull(@MaxSeqProductno,0) + 1
					end
			end
			else
				begin
					set @ItemFound = (SELECT count(*) FROM RF_DWH_SCHEDULE WHERE CAST(schedule_date as Date) 
					= CAST(@schedule_date as DATE) and production_line_facility_id = @LineFacilityID and item_id = @ItemID)
					set @ItemFound = isnull(@ItemFound,0)
					if (@ItemFound > 0)
						begin
							set @MaxSeqProductno = (SELECT ISNULL(MAX(isnull(nitemseqproduction,0)), 0)
								FROM RF_DWH_SCHEDULE WHERE CAST(schedule_date as Date) = CAST(@schedule_date as DATE) 
								and production_line_facility_id = @LineFacilityID and item_id = @ItemID)	
								set @MaxSeqProductno = isnull(@MaxSeqProductno,0)
						end
					else 
						begin
							set @MaxSeqProductno = (SELECT ISNULL(MAX(isnull(nitemseqproduction,0)), 0)
								FROM RF_DWH_SCHEDULE WHERE cast(schedule_date as DATE) = CAST(@schedule_date as DATE))
							set @MaxSeqProductno = isnull(@MaxSeqProductno,0) + 1
						end
						
				end
		end
RETURN ISNULL(@MaxSeqProductno,0)
END
