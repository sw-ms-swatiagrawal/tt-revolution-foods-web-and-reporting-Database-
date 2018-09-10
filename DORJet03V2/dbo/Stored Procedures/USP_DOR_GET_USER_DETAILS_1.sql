      
CREATE PROCEDURE [dbo].[USP_DOR_GET_USER_DETAILS]      
(      
 @caller_id INT = NULL,      
 @user_id INT = NULL,      
 @user_nm varchar(50) = NULL       
)      
AS      
BEGIN      
       
 SET NOCOUNT ON;      
      
 OPEN SYMMETRIC KEY rf_user_symm_key      
 DECRYPTION BY CERTIFICATE rf_user_certi       
       
 DECLARE @vIsAdminCaller AS BIT;      
      
 SELECT @vIsAdminCaller = ISNULL(x.is_admin, 0)      
 FROM  dbo.RF_DWH_USERS AS x      
 WHERE x.user_id = @caller_id      
 AND x.user_nm != 'superadmin';      
       
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
 AND [user_id] = ISNULL(@user_id, a.user_id)      
 AND a.[user_nm] = ISNULL(@user_nm, a.[user_nm]) COLLATE SQL_Latin1_General_CP1_CI_AS       
 AND [user_id] NOT IN (SELECT (CASE WHEN (@vIsAdminCaller = 1 AND x.is_admin = 1) OR @vIsAdminCaller = 0 OR x.user_nm = 'superadmin'      
         THEN x.user_id       
         ELSE 0       
          END) AS [admin_user_id]      
       FROM  dbo.RF_DWH_USERS AS x)      
END; 
