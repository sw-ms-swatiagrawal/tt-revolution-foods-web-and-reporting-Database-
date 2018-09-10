
CREATE PROCEDURE [dbo].[USP_DOR_GET_USER_DETAILS_RESET_PASSWORD]        
(        
 @user_id INT  
)        
AS        
BEGIN        
         
 SET NOCOUNT ON;        
        
 OPEN SYMMETRIC KEY rf_user_symm_key        
 DECRYPTION BY CERTIFICATE rf_user_certi         
         
 DECLARE @vIsAdminCaller AS BIT;     
         
 SELECT a.[user_id],        
   a.user_nm,         
   CONVERT(VARCHAR(1000), DecryptByKey([password])) AS [password],        
   a.email_id,         
   a.is_admin,        
   a.is_active,      
   a.default_facility_id,    
   b.facility_nm    
 FROM dbo.RF_DWH_USERS AS a     
 left join RF_DWH_FACILITY as b on b.facility_id = a.default_facility_id       
 WHERE a.deleted_by IS NULL        
 AND a.[user_id] = @user_id  
   
     
END; 
