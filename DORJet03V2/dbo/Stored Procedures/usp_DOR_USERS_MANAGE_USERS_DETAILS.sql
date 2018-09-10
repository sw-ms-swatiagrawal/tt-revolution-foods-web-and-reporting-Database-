
CREATE Procedure [dbo].[usp_DOR_USERS_MANAGE_USERS_DETAILS]
	@xml XML,      
 @error_message VARCHAR(MAX) OUTPUT   
as
Begin

 SET NOCOUNT, XACT_ABORT ON;      
      
 DECLARE @hDoc AS INT, @vUserId AS INT;      
       
 BEGIN TRANSACTION      
      
 BEGIN TRY      
        
    
   EXEC sp_xml_preparedocument   @hDoc output, @xml     
   
   OPEN SYMMETRIC KEY rf_user_symm_key      
  DECRYPTION BY CERTIFICATE rf_user_certi   

  IF OBJECT_ID('tempdb..#tmp_user_rights') IS NOT NULL      
   DROP TABLE #tmp_user_rights;      
      
  EXEC sp_xml_preparedocument   @hDoc output, @xml;      
        
  SELECT [user_id]      
    , user_nm      
    , CAST(EncryptByKey(Key_GUID('rf_user_symm_key'), [password]) AS VARBINARY(1024)) AS [password]   
	,modified_by
    INTO #tmp_user_rights      
  FROM OPENXML(@hDoc, 'users/user')       
  WITH ([user_id] INT 'user_id'     
   ,user_nm VARCHAR(100) 'user_nm'      
   ,[password] VARCHAR(100) 'password' 
   ,modified_by VARCHAR(100) 'modified_by' 
   );      
      
  EXEC sp_xml_removedocument @hDoc;  
  
    MERGE INTO RF_DWH_USERS AS trg       
  USING (SELECT TOP 1 x.[user_id], x.user_nm, x.[password],x.modified_by
   FROM #tmp_user_rights AS x) AS src       
   ON trg.[user_id] = src.[user_id]       
  WHEN MATCHED THEN       
   UPDATE SET trg.user_nm = src.user_nm,trg.modified_by = src.modified_by,
    trg.modified_date = getdate()       
      ,trg.[password] = src.[password];
     
   SELECT @error_message = ERROR_MESSAGE()  
    
	END TRY      
 BEGIN CATCH      
      
  SELECT @error_message = ERROR_MESSAGE();      
      
  IF @@TRANCOUNT > 0      
   ROLLBACK;      
     
      
 END CATCH      
       
 IF @@TRANCOUNT > 0      
  COMMIT;      
      
END 
