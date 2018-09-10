
CREATE PROCEDURE [dbo].[usp_DOR_RE_RUN_MANAGE]
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

		MERGE INTO RF_DWH_RE_RUN_RATE AS trg 
		USING (SELECT re_run_id,
					re_run_type,
					re_run_twin,
					re_run_single,
					re_run_flow,
					build_grade_id,
					plan_per,
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
				FROM OPENXML(@hDoc, 're_run_units/re_run', 3) 
				WITH (re_run_id			INT, 
						re_run_type		VARCHAR(50), 									
						re_run_twin		INT,																	
						re_run_single	INT,
						re_run_flow		INT,
						build_grade_id	INT,
						plan_per		INT,
						inserted_by		VARCHAR(50),
						modified_by		VARCHAR(50), 
						deleted_by		VARCHAR(50))) AS src 
			ON trg.re_run_id = src.re_run_id 
		WHEN NOT MATCHED BY TARGET THEN 
			INSERT (re_run_type, re_run_twin, re_run_single, re_run_flow, build_grade_id, plan_per, inserted_date, inserted_by) 
			VALUES(src.re_run_type, src.re_run_twin, src.re_run_single, src.re_run_flow, src.build_grade_id, src.plan_per, src.inserted_date, src.inserted_by) 
		WHEN MATCHED THEN 
			UPDATE SET trg.re_run_type = src.re_run_type, 
						trg.re_run_twin = src.re_run_twin,
						trg.re_run_single = src.re_run_single,
						trg.re_run_flow = src.re_run_flow,
						trg.build_grade_id = src.build_grade_id,
						trg.plan_per = src.plan_per,						
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




