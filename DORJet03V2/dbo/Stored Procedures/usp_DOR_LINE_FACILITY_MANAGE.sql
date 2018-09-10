
CREATE PROCEDURE [dbo].[usp_DOR_LINE_FACILITY_MANAGE]
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

		SELECT src.line_facility_id, src.line_id, src.facility_id, ISNULL(delete_fg, 0) AS delete_fg
		INTO #TMP_RF_DWH_XREF_LINE_FACILITY
		FROM OPENXML(@hDoc, 'line_facility_mapping/line_facility', 3) 
		WITH (line_facility_id INT, 						
				line_id INT,
				facility_id INT,
				delete_fg BIT) AS src;
		
		EXEC sp_xml_removedocument @hDoc; 

		SET @error_message = ''
		SELECT TOP 1 @error_message = CONCAT('Cannot assing Line and Facility as there is some scheduled created for the Date of ', CONVERT(VARCHAR, b.schedule_date, 106))
		FROM #TMP_RF_DWH_XREF_LINE_FACILITY AS a
		JOIN RF_DWH_SCHEDULE AS b
			ON a.line_facility_id = b.line_facility_id;
		
		IF @error_message != ''
			RAISERROR(@error_message, 16, 1);

		MERGE INTO RF_DWH_XREF_LINE_FACILITY AS trg 
		USING (SELECT x.line_facility_id, x.line_id, x.facility_id, x.delete_fg
				FROM #TMP_RF_DWH_XREF_LINE_FACILITY AS x) AS src 
			ON trg.line_facility_id = src.line_facility_id 
		WHEN NOT MATCHED BY TARGET THEN 
			INSERT (line_id, facility_id) 
			VALUES(src.line_id, src.facility_id) 
		WHEN MATCHED AND src.delete_fg = 0 THEN 
			UPDATE SET trg.line_id = src.line_id,
						trg.facility_id = src.facility_id
		WHEN MATCHED AND src.delete_fg = 1 THEN 
			DELETE; 
		

	END TRY
	BEGIN CATCH

		SELECT @error_message = ERROR_MESSAGE();

		IF @@TRANCOUNT > 0
			ROLLBACK;

	END CATCH
	
	IF @@TRANCOUNT > 0
		COMMIT;

END





