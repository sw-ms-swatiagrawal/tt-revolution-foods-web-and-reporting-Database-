CREATE PROCEDURE [dbo].[usp_DOR_ROLES_MANAGE]          
(           
 @xml XML,          
 @error_message VARCHAR(MAX) OUTPUT          
)          
AS          
BEGIN          
           
 SET NOCOUNT, XACT_ABORT ON;          
          
 DECLARE @hDoc AS INT          
 DECLARE @vRole AS TABLE (role_id INT)           
              
 BEGIN TRANSACTION          
          
 BEGIN TRY          
  EXEC sp_xml_preparedocument   @hDoc output, @xml;           
          
  IF OBJECT_ID('tempdb..#RoleRightsData') IS NOT NULL          
   DROP TABLE #RoleRightsData;          
    
 IF OBJECT_ID('tempdb..#FacilityData') IS NOT NULL          
   DROP TABLE #FacilityData;       
             
  SELECT role_id,           
   role_cd,           
   role_nm,           
   module_id,          
   facility_id,          
   view_fg,          
   insert_fg,          
   update_fg,          
   delete_fg,           
   edit_locked_record_fg, 
   add_locked_record_fg,                       
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
   INTO #RoleRightsData          
  FROM OPENXML(@hDoc, 'roles/role/rolerights', 3)           
  WITH ( role_id INT  '../role_id',          
    role_cd VARCHAR(50) '../role_cd',           
    role_nm VARCHAR(500) '../role_nm',          
    module_id INT ,          
    facility_id INT '../facility_id',          
    view_fg BIT,          
    insert_fg BIT,          
    update_fg BIT,          
    delete_fg BIT,          
	edit_locked_record_fg BIT,
	add_locked_record_fg BIT,
    inserted_by VARCHAR(50) '../inserted_by',           
    modified_by VARCHAR(50) '../modified_by',           
    deleted_by VARCHAR(50) '../deleted_by')          
       
    SELECT facility_id,    
  role_id     
   INTO #FacilityData          
  FROM OPENXML(@hDoc, 'roles/role/facility', 3)     
  WITH ( facility_id INT  'facility_id',          
    role_id INT '../role_id')    
    
       
  EXEC sp_xml_removedocument @hDoc;          
          
  --> Save Roles          
  MERGE INTO RF_DWH_ROLES AS trg           
  USING (SELECT DISTINCT role_id, role_cd, role_nm,  inserted_date, inserted_by          
     , modified_date, modified_by, deleted_date, deleted_by          
    FROM #RoleRightsData) AS src           
   ON trg.role_id = src.role_id           
  WHEN NOT MATCHED BY TARGET THEN           
   INSERT (role_cd, role_nm,  inserted_date, inserted_by)           
   VALUES(src.role_cd, src.role_nm,  src.inserted_date, src.inserted_by)           
  WHEN MATCHED THEN           
   UPDATE SET trg.role_cd = src.role_cd,           
      trg.role_nm = src.role_nm,                      
      --trg.facility_id = src.facility_id,                
      trg.modified_date = COALESCE(trg.modified_date, src.modified_date),           
      trg.modified_by = COALESCE(trg.modified_by, src.modified_by),           
      trg.deleted_date = CASE          
            WHEN src.deleted_by IS NULL THEN NULL           
            ELSE src.deleted_date           
           END,           
      trg.deleted_by = src.deleted_by          
  OUTPUT INSERTED.role_id INTO @vRole;           
    
 --SET @vUserId = SCOPE_IDENTITY();        
           
            
  --> Save RF_DWH_ROLES_MODULE          
  MERGE INTO RF_DWH_ROLES_MODULE AS trg           
  USING (SELECT DISTINCT COALESCE(a.role_id, b.role_id) AS role_id, a.module_id, a.view_fg, a.insert_fg, a.update_fg, 
  a.delete_fg , a.edit_locked_record_fg ,a.add_locked_record_fg        
    FROM #RoleRightsData AS a          
    CROSS APPLY(SELECT x.role_id FROM @vRole AS x) AS b) AS src           
   ON trg.role_id = src.role_id   AND trg.module_id = src.module_id         
  WHEN NOT MATCHED BY TARGET THEN           
   INSERT (role_id, module_id, view_fg, insert_fg, update_fg, delete_fg,edit_locked_record_fg,add_locked_record_fg)           
   VALUES(src.role_id, src.module_id, src.view_fg, src.insert_fg, src.update_fg, src.delete_fg, src.edit_locked_record_fg, src.add_locked_record_fg)          
  WHEN MATCHED THEN           
   UPDATE SET trg.role_id = src.role_id,           
      trg.module_id = src.module_id,                
      trg.view_fg = src.view_fg,          
      trg.insert_fg = src.insert_fg,          
      trg.update_fg = src.update_fg,          
      trg.delete_fg = src.delete_fg,
	  trg.edit_locked_record_fg = src.edit_locked_record_fg,
	  trg.add_locked_record_fg = src.add_locked_record_fg;          
          
--> In case of Insert - automatically assign 'superadmin' user      
 Declare @Superadminuserid Int      
 Select  @Superadminuserid = user_id from RF_DWH_USERS where user_nm = 'superadmin'      
       
  MERGE INTO RF_DWH_USER_ROLE AS trg           
  USING (SELECT DISTINCT COALESCE(a.role_id, b.role_id) AS role_id        
    FROM #RoleRightsData AS a          
    CROSS APPLY(SELECT x.role_id FROM @vRole AS x) AS b) AS src           
   ON trg.role_id = src.role_id   AND trg.user_id = @Superadminuserid       
  WHEN NOT MATCHED BY TARGET THEN           
   INSERT (user_id,role_id)      
   VALUES(@Superadminuserid,src.role_id);      
  --WHEN MATCHED THEN           
   --UPDATE SET trg.role_id = src.role_id,           
   --   trg.module_id = src.module_id,                
   --   trg.view_fg = src.view_fg,          
   --   trg.insert_fg = src.insert_fg,          
   --   trg.update_fg = src.update_fg,          
   --   trg.delete_fg = src.delete_fg;       
    
--> RF_DWH_ROLE_FACILITY    
DELETE FROM RF_DWH_ROLE_FACILITY WHERE role_id IN (SELECT x.[role_id] AS [role_id] FROM #FacilityData AS x)      
    
MERGE INTO RF_DWH_ROLE_FACILITY AS trg           
  USING (SELECT DISTINCT COALESCE(a.role_id, b.role_id) AS role_id, a.facility_id    
    FROM #FacilityData AS a          
    CROSS APPLY(SELECT x.role_id FROM @vRole AS x) AS b) AS src           
   ON trg.role_id = src.role_id   AND trg.facility_id = src.facility_id         
  WHEN NOT MATCHED BY TARGET THEN           
   INSERT (role_id, facility_id)           
   VALUES(src.role_id, src.facility_id);          
  --WHEN MATCHED THEN           
  -- UPDATE SET trg.role_id = src.role_id,           
  --    trg.module_id = src.module_id,                
  --    trg.view_fg = src.view_fg,          
  --    trg.insert_fg = src.insert_fg,          
  --    trg.update_fg = src.update_fg,          
  --    trg.delete_fg = src.delete_fg;        
               
 END TRY          
 BEGIN CATCH          
          
  SELECT @error_message = ERROR_MESSAGE();          
          
  IF @@TRANCOUNT > 0          
   ROLLBACK;          
          
 END CATCH          
           
 IF @@TRANCOUNT > 0          
  COMMIT;          
          
END;   
