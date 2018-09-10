
CREATE PROCEDURE [dbo].[usp_DOR_SHIFT_ENTRY_MANAGE]
	@xml XML,
	@error_message VARCHAR(MAX) OUTPUT
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @hDoc AS INT
    
	BEGIN TRANSACTION

		BEGIN TRY
			EXEC sp_xml_preparedocument   @hDoc output, @xml 

			MERGE RF_DWH_SHIFT_ENTRY AS trg 
			USING (SELECT shift_entry_id, 
							schedule_id, 
							start_time, 
							stope_time, 
							use_break, 
							use_lunch, 
							re_run_units, 
							over_run_units, 
							crew_size_actual, 
							comments,							
							GETDATE() AS inserted_date, 
							inserted_by, 
							CASE 
							WHEN modified_by IS NULL THEN NULL 
							ELSE GETDATE() 
							END AS modified_date, 
							modified_by														
					FROM   OPENXML(@hDoc, 'shift_entries/shift_entry', 3) 
								WITH ( [shift_entry_id] [INT], 
									[schedule_id]		[INT], 
									[start_time]		[DATETIME], 
									[stope_time]		[DATETIME], 
									[use_break]			[BIT], 
									[use_lunch]			[BIT], 
									[re_run_units]		[DECIMAL](16, 8), 
									[over_run_units]	[DECIMAL](16, 8), 
									[crew_size_actual]	[DECIMAL](16, 8), 
									[comments]			[VARCHAR](MAX), 									
									[inserted_by]		[VARCHAR](50), 
									[modified_by]		[VARCHAR](50))
			) AS src 
			ON trg.[shift_entry_id] = src.[shift_entry_id] 
			WHEN NOT MATCHED BY TARGET  
			THEN 
				INSERT (schedule_id, 
						start_time, 
						stope_time, 
						use_break, 
						use_lunch, 
						re_run_units, 
						over_run_units, 
						crew_size_actual, 
						comments,		
						inserted_date, 
						inserted_by) 
				VALUES(src.schedule_id, 
						src.start_time, 
						src.stope_time, 
						src.use_break, 
						src.use_lunch, 
						src.re_run_units,
						src.over_run_units,
						src.crew_size_actual, 
						src.comments,						
						src.inserted_date, 
						src.inserted_by) 
			WHEN MATCHED
			THEN 
				UPDATE SET trg.schedule_id = src.schedule_id, 
							trg.start_time = src.start_time, 
							trg.stope_time = src.stope_time, 
							trg.use_break = src.use_break, 
							trg.use_lunch = src.use_lunch, 
							trg.re_run_units = src.re_run_units, 
							trg.over_run_units = src.over_run_units, 
							trg.crew_size_actual = src.crew_size_actual, 
							trg.comments = src.comments, 							
							trg.modified_date = COALESCE(trg.modified_date, src.modified_date), 
							trg.modified_by = COALESCE(trg.modified_by, src.modified_by);

			EXEC sp_xml_removedocument @hDoc
		END TRY
		BEGIN CATCH

			SELECT @error_message = ERROR_MESSAGE();

			IF @@TRANCOUNT > 0
			ROLLBACK;

		END CATCH
	
	IF @@TRANCOUNT > 0
	COMMIT;
END




