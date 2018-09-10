CREATE PROCEDURE [dbo].[usp_DOR_FACILITY_MANAGE]   
 @xml XML,  
 @error_message VARCHAR(MAX) OUTPUT  
AS  
BEGIN  
   
 SET NOCOUNT ON;  
  
 DECLARE @hDoc AS INT  
	DECLARE @vFacility AS TABLE (facility_id INT)
 BEGIN TRANSACTION  
  
  BEGIN TRY  
   EXEC sp_xml_preparedocument   @hDoc output, @xml   

   MERGE RF_DWH_FACILITY AS trg   
   USING (SELECT facility_id,   
       facility_cd,   
       facility_nm,                
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
       END          AS deleted_date,   
       deleted_by,
	   item_break_time,  variation_break_time,  shift_start_time,
	   facility_profit_code
     FROM   OPENXML(@hDoc, 'facility', 3)   
        WITH ( [facility_id]        [INT],   
         [facility_cd]   [VARCHAR](50),            
         [facility_nm]   [VARCHAR](500),                   
         [inserted_by]           [VARCHAR](50),   
         [modified_by]           [VARCHAR](50),   
         [deleted_by]            [VARCHAR](50),
		 [item_break_time] [INT],
		 [variation_break_time] [INT],
		 [shift_start_time] [DateTime],
		 [facility_profit_code] [INT]
		  )  
   ) AS src   
   ON trg.facility_id = src.facility_id   
   WHEN NOT MATCHED BY TARGET    
   THEN   
    INSERT ( facility_cd,   
       facility_nm,                
       inserted_date,   
       inserted_by,
	   item_break_time,
	   variation_break_time,
	   shift_start_time,
	   facility_profit_code)   
    VALUES(src.facility_cd,   
      src.facility_nm,         
      src.inserted_date,   
      src.inserted_by,
	   src.item_break_time,
	   src.variation_break_time,
	   src.shift_start_time,
	   src.facility_profit_code)   
   WHEN MATCHED  
   THEN   
    UPDATE SET trg.facility_cd = src.facility_cd,   
       trg.facility_nm = src.facility_nm,                
       trg.modified_date = COALESCE(trg.modified_date, src.modified_date),   
       trg.modified_by = COALESCE(trg.modified_by, src.modified_by),   
       trg.deleted_date = CASE   
            WHEN src.deleted_by IS NULL THEN NULL   
            ELSE src.deleted_date   
           END,   
       trg.deleted_by = src.deleted_by,
	   trg.item_break_time = src.item_break_time,
	   trg.variation_break_time = src.variation_break_time,
	   trg.shift_start_time = src.shift_start_time,
	   trg.facility_profit_code = src.facility_profit_code
	 OUTPUT INSERTED.facility_id INTO @vFacility; 
  
  Declare @superadminroleid Int    
  Select  @superadminroleid = role_id from RF_DWH_ROLES where role_nm = 'SuperAdmin'    

   --RF_DWH_ROLE_FACILITY
  MERGE INTO RF_DWH_ROLE_FACILITY AS trg         
   USING (SELECT facility_id FROM @vFacility ) AS src   
   ON trg.facility_id = src.[facility_id]  And  trg.role_id = @superadminroleid
   WHEN NOT MATCHED BY TARGET    
   THEN   
    INSERT ( facility_id,   
       role_id
     )   
    VALUES(src.facility_id,   
      @superadminroleid); 

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

