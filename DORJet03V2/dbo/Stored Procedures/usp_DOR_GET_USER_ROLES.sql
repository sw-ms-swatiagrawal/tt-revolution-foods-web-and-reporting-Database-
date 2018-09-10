
CREATE Procedure dbo.usp_DOR_GET_USER_ROLES      
 @user_id int = NULL      
as      
Begin      
 Select Distinct      
   a.role_id   
 ,a.role_nm       
 From RF_DWH_ROLES  a      
 left join  RF_DWH_USER_ROLE b       
 on b.role_id = a.role_id      
  Where 1 =1      
  AND (@user_id is null OR b.user_id = COALESCE(@user_id,b.user_id))      
  And a.deleted_by is  NULL    
  And a.role_nm <> 'SuperAdmin'
End 
