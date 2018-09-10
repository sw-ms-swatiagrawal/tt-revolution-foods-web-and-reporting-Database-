
CREATE  Function [dbo].[fn_GetMaxSeqNumber]
(
@schedule_date as datetime,
@LineFacilityID as INT,
@ItemID as INT,
@UserType as varchar(50)
)
RETURNS BIGINT
AS
BEGIN
	
	DECLARE @MaxSeqProductno BIGINT

	if (@ItemID IS NULL and @LineFacilityID IS NULL)
		begin
			set @MaxSeqProductno = (SELECT ISNULL(MAX(isnull(nitemseqplaning,0)), 0)
							FROM RF_DWH_SCHEDULE WHERE cast(schedule_date as DATE) = CAST(@schedule_date as DATE))
		end
	else 
		begin
			set @MaxSeqProductno = (SELECT ISNULL(MAX(isnull(nitemseqplaning,0)), 0)
							FROM RF_DWH_SCHEDULE WHERE CAST(schedule_date as Date) = CAST(@schedule_date as DATE) 
							and line_facility_id = @LineFacilityID and item_id = @ItemID)
		end	
	RETURN ISNULL(@MaxSeqProductno,0)
END



