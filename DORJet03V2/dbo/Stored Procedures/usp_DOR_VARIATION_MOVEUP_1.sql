

CREATE Procedure [dbo].[usp_DOR_VARIATION_MOVEUP]
	@variation_id INT,
	@own_order_no INT,
	@previous_element_variation_id INT,
	@previous_element_order_no INT,
	@updated_by varchar(100),
	@error_message VARCHAR(MAX) OUTPUT
as
begin
	
	SET NOCOUNT, XACT_ABORT ON;

	DECLARE @hDoc AS INT
    
	BEGIN TRANSACTION

	BEGIN TRY
		Update RF_DWH_VARIATION_MASTER Set order_no = @previous_element_order_no, 
		modified_by =  @updated_by,modified_date = getdate()  where variation_id = @variation_id
		Update RF_DWH_VARIATION_MASTER Set order_no = @own_order_no,
		modified_by =  @updated_by,modified_date = getdate() where variation_id = @previous_element_variation_id

	END TRY
	BEGIN CATCH

		SELECT @error_message = ERROR_MESSAGE();

		IF @@TRANCOUNT > 0
			ROLLBACK;

	END CATCH
	
	IF @@TRANCOUNT > 0
		COMMIT;

End
