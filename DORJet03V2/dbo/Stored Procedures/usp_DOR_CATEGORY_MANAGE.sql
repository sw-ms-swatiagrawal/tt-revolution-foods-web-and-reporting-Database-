
CREATE PROCEDURE [dbo].[usp_DOR_CATEGORY_MANAGE]
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
		EXEC sp_xml_preparedocument   @hDoc output, @xml; 

		MERGE INTO RF_DWH_CATEGORY AS trg 
		USING (SELECT category_id, 					
					category_nm, 													
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
				FROM OPENXML(@hDoc, 'categorys/category', 3) 
				WITH (category_id INT, 						
						category_nm VARCHAR(500),																	
						inserted_by VARCHAR(50), 
						modified_by VARCHAR(50), 
						deleted_by VARCHAR(50))) AS src 
			ON trg.category_id = src.category_id 
		WHEN NOT MATCHED BY TARGET THEN 
			INSERT (category_nm, inserted_date, inserted_by) 
			VALUES(src.category_nm, src.inserted_date, src.inserted_by) 
		WHEN MATCHED THEN 
			UPDATE SET trg.category_nm = src.category_nm,
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




