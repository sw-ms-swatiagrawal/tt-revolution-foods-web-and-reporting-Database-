CREATE PROCEDURE [dbo].[usp_DOR_SCHEDULE_DELETE_ITEM]
(
@schedule_date datetime,
@line_facility_id as INT,
@item_id as INT,
@isplaning bit,
@deleted_by varchar(50),
@error_message varchar(MAX) output
)
as

SET NOCOUNT ON;        
BEGIN TRANSACTION;
BEGIN TRY   
	if (@isplaning = 1)
		begin
			declare @changeproduction as int = (select COUNT(*) from RF_DWH_SCHEDULE SC WHERE cast(sc.schedule_date as date) = cast(@schedule_date as date) AND sc.status_id <> 1 --sc.production_modifiedby IS NOT NULL
												AND item_id = @item_id and line_facility_id = @line_facility_id) --AND isnull(SC.act_qty,0) > 0)
			
			IF isnull(@changeproduction,0) = 0
				begin
					Update RF_DWH_SCHEDULE set qty = null, act_qty = null
					where cast(schedule_date as date)= cast(@schedule_date as date) and item_id = @item_id and line_facility_id = @line_facility_id

					Update RF_DWH_SCHEDULE set deleted_by =  @deleted_by , deleted_date = GETDATE()
					WHERE cast(schedule_date as date)= cast(@schedule_date as date) and item_id = @item_id and line_facility_id = @line_facility_id
					and act_qty is null	
				end
			ELSE
				begin
					set @error_message = 'Production is over!'
				END
		end
	else if(@isplaning = 0)
		begin
			Update RF_DWH_SCHEDULE set act_qty = null
			where cast(schedule_date as date)= cast(@schedule_date as date) and item_id = @item_id and production_line_facility_id = @line_facility_id

			Update RF_DWH_SCHEDULE set deleted_by =  @deleted_by , deleted_date = GETDATE()
			WHERE cast(schedule_date as date)= cast(@schedule_date as date) and item_id = @item_id and production_line_facility_id = @line_facility_id
			and qty is null
		end 

	COMMIT TRANSACTION;
ENd TRY
BEGIN CATCH
	SELECT @error_message = ERROR_MESSAGE();        
   if (XACT_STATE() = -1)
		BEGIN
			ROLLBACK TRANSACTION;
		END
	if (XACT_STATE() = 1)
		BEGIN
			COMMIT TRANSACTION;
		END   
END CATCH
