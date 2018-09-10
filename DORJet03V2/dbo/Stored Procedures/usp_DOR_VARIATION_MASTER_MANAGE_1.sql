CREATE PROCEDURE [dbo].[usp_DOR_VARIATION_MASTER_MANAGE]
( 
	@xml XML,
	@error_message VARCHAR(MAX) OUTPUT
)
AS
BEGIN
	
	SET NOCOUNT, XACT_ABORT ON;

	DECLARE @hDoc AS INT
    
	BEGIN TRANSACTION

	BEGIN TRY
	  Declare @order_no Int
	  Select @order_no = (max(order_no) + 1)from RF_DWH_VARIATION_MASTER

		EXEC sp_xml_preparedocument   @hDoc output, @xml; 

		MERGE INTO RF_DWH_VARIATION_MASTER AS trg 
		USING (SELECT variation_id, 
					variation_nm, 
					order_no, 													
					GETDATE() AS inserted_date, 
					inserted_by, 
					CASE 
						WHEN modified_by IS NULL THEN NULL 
						ELSE GETDATE() 
					END AS modified_date, 
					modified_by, 
					CASE 
						WHEN deleted_by IS NULL THEN NULL 
						ELSE GETDATE() 
					END AS deleted_date, 
					deleted_by 
				FROM OPENXML(@hDoc, 'variations/variation', 3) 
				WITH (variation_id INT, 
						variation_nm VARCHAR(50), 									
						order_no Int,																	
						inserted_by VARCHAR(50), 
						modified_by VARCHAR(50), 
						deleted_by VARCHAR(50))) AS src 
			ON trg.variation_id = src.variation_id 
		WHEN NOT MATCHED BY TARGET THEN 
			--Declare @order_no Int
			--Select @order_no = max(order_no) from RF_DWH_VARIATION_MASTER
			INSERT (variation_nm, inserted_date, inserted_by, order_no) 
			VALUES(src.variation_nm, src.inserted_date, src.inserted_by, @order_no) 
		WHEN MATCHED THEN 
			UPDATE SET trg.variation_nm = src.variation_nm, 
						trg.order_no = src.order_no , --CASE
										--		WHEN src.deleted_by IS NOT NULL THEN NULL 
										--		ELSE src.order_no 
										--	END,
						trg.modified_date = COALESCE(trg.modified_date, src.modified_date), 
						trg.modified_by = COALESCE(trg.modified_by, src.modified_by), 
						trg.deleted_date = CASE
												WHEN src.deleted_by IS NULL THEN NULL 
												ELSE src.deleted_date 
											END, 
						trg.deleted_by = src.deleted_by; 

		EXEC sp_xml_removedocument @hDoc;

	END TRY
	BEGIN CATCH

		SELECT @error_message = ERROR_MESSAGE();

		IF @@TRANCOUNT > 0
			ROLLBACK;

	END CATCH
	
	IF @@TRANCOUNT > 0
		COMMIT;

END
