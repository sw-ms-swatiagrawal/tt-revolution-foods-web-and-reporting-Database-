
CREATE PROCEDURE dbo.usp_DOR_USERS_MANAGE
( 
	@xml XML,
	@error_message VARCHAR(MAX) OUTPUT
)
AS
BEGIN
	
	SET NOCOUNT, XACT_ABORT ON;

	DECLARE @hDoc AS INT, @vUserId AS INT;
	
	BEGIN TRANSACTION

	BEGIN TRY

		OPEN SYMMETRIC KEY rf_user_symm_key
		DECRYPTION BY CERTIFICATE rf_user_certi 

		IF OBJECT_ID('tempdb..#tmp_user_rights') IS NOT NULL
			DROP TABLE #tmp_user_rights;

		EXEC sp_xml_preparedocument   @hDoc output, @xml;
		
		SELECT [user_id]
				, user_nm
				, CAST(EncryptByKey(Key_GUID('rf_user_symm_key'), [password]) AS VARBINARY(1024)) AS [password]
				, email_id
				, is_admin
				--, ISNULL(NULLIF(is_active, 0), 1) AS is_active
				, is_active
				, inserted_by, modified_by, deleted_by
				, NULLIF(facility_id, 0) AS facility_id
				, insert_fg
				, update_fg
				, delete_fg
				, is_default
		  INTO #tmp_user_rights
		FROM OPENXML(@hDoc, 'users/user/userrights') 
		WITH ([user_id] INT	'../user_id', 
			user_nm VARCHAR(100) '../user_nm',
			[password] VARCHAR(100) '../password',
			email_id VARCHAR(100) '../email_id',
			is_admin BIT '../is_admin',
			is_active BIT '../is_active',
			inserted_by VARCHAR(50) '../inserted_by', 
			modified_by VARCHAR(50) '../modified_by', 
			deleted_by VARCHAR(50) '../deleted_by',

			facility_id INT 'facility_id',
			insert_fg BIT 'insert_fg',
			update_fg BIT 'update_fg',
			delete_fg BIT 'delete_fg',
			is_default BIT 'is_default');

		EXEC sp_xml_removedocument @hDoc;		 
		
		MERGE INTO RF_DWH_USERS AS trg 
		USING (SELECT TOP 1 x.[user_id], x.user_nm, x.[password], x.email_id, x.is_admin, x.is_active,				
				--x.facility_id, x.insert_fg, x.update_fg, x.delete_fg, x.is_default,
				
				CASE WHEN x.inserted_by IS NULL 
					THEN NULL 
					ELSE GETDATE() 
				END AS inserted_date,
				x.inserted_by, 

				CASE WHEN x.modified_by IS NULL 
					THEN NULL 
					ELSE GETDATE() 
				END AS modified_date, 
				x.modified_by, 
				
				CASE WHEN x.deleted_by IS NULL 
					THEN NULL 
					ELSE GETDATE() 
				END AS deleted_date, 
				x.deleted_by
			FROM #tmp_user_rights AS x) AS src 
			ON trg.[user_id] = src.[user_id] 
		WHEN NOT MATCHED BY TARGET THEN 
			INSERT (user_nm, [password], email_id, is_admin, is_active, inserted_date, inserted_by) 
			VALUES(src.user_nm, src.[password], src.email_id, src.is_admin, src.is_active, src.inserted_date, src.inserted_by) 
		WHEN MATCHED THEN 
			UPDATE SET trg.user_nm = src.user_nm, 
						trg.[password] = src.[password],
						trg.email_id = src.email_id,
						trg.is_admin = src.is_admin,
						trg.is_active = src.is_active,						
						trg.modified_date = COALESCE(trg.modified_date, src.modified_date), 
						trg.modified_by = COALESCE(trg.modified_by, src.modified_by), 
						trg.deleted_date = CASE
												WHEN src.deleted_by IS NULL THEN NULL 
												ELSE src.deleted_date 
											END, 
						trg.deleted_by = src.deleted_by; 

		SET @vUserId = SCOPE_IDENTITY();

		MERGE INTO XREF_USER_FACILITY_ROLES AS trg 
		USING (SELECT ISNULL(x.[user_id], @vUserId) AS [user_id]				
					, x.facility_id, x.insert_fg, x.update_fg, x.delete_fg, x.is_default
			FROM #tmp_user_rights AS x) AS src 
			ON trg.[user_id] = src.[user_id] 
			AND trg.facility_id = src.facility_id
		WHEN NOT MATCHED BY TARGET THEN 
			INSERT ([user_id], facility_id, insert_fg, update_fg, delete_fg, is_default) 
			VALUES(src.[user_id], src.facility_id, src.insert_fg, src.update_fg, src.delete_fg, src.is_default) 
		WHEN MATCHED THEN 
			UPDATE SET trg.insert_fg = src.insert_fg,
						trg.update_fg = src.update_fg,						
						trg.delete_fg = src.delete_fg,	
						trg.is_default = src.is_default; 
		

	END TRY
	BEGIN CATCH

		SELECT @error_message = ERROR_MESSAGE();

		IF @@TRANCOUNT > 0
			ROLLBACK;

	END CATCH
	
	IF @@TRANCOUNT > 0
		COMMIT;

END
