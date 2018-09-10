
CREATE PROCEDURE [dbo].[usp_DOR_WASTE_TYPE_MANAGE]
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

		MERGE INTO RF_DWH_WASTE_TYPE AS trg 
		USING (SELECT waste_type_id, 
					waste_type_cd, 
					waste_type_nm, 													
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
				FROM OPENXML(@hDoc, 'wastetypes/wastetype', 3) 
				WITH (waste_type_id INT, 
						waste_type_cd VARCHAR(50), 									
						waste_type_nm VARCHAR(500),																	
						inserted_by VARCHAR(50), 
						modified_by VARCHAR(50), 
						deleted_by VARCHAR(50))) AS src 
			ON trg.waste_type_id = src.waste_type_id 
		WHEN NOT MATCHED BY TARGET THEN 
			INSERT (waste_type_cd, waste_type_nm, inserted_date, inserted_by) 
			VALUES(src.waste_type_cd, src.waste_type_nm, src.inserted_date, src.inserted_by) 
		WHEN MATCHED AND trg.inserted_by IS NOT NULL THEN 
			UPDATE SET trg.waste_type_cd = src.waste_type_cd, 
						trg.waste_type_nm = src.waste_type_nm,
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




