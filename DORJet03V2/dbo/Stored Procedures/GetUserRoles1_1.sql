--Exec [GetUserRoles1] 37, 2, NULL  
--Select * From RF_DWH_USERS  
CREATE Procedure [dbo].[GetUserRoles1]  
 @user_id int,  
 @facility_id int = NULL,  
 @module_id int = NULL  
  
as  
Begin  
 Select  a.user_id,c.facility_id ,d.module_id,
 (Select Top 1 d.view_fg From RF_DWH_USERS a  
 join RF_DWH_USER_ROLE b on b.user_id = a.user_id  
 join RF_DWH_ROLES c on c.role_id = b.role_id  
 join RF_DWH_ROLES_MODULE d on d.role_id = b.role_id
 Where 1= 1
 And a.user_id = @user_id  
 And c.deleted_by IS NULL  
 and a.deleted_by  IS NULL  
 And @module_id IS NULL OR d.module_id = @module_id  
 And @facility_id IS NULL OR c.facility_id = @facility_id ) as view_fg, 
 d.insert_fg, d.update_fg, d.delete_fg  From RF_DWH_USERS a  
 join RF_DWH_USER_ROLE b on b.user_id = a.user_id  
 join RF_DWH_ROLES c on c.role_id = b.role_id  
 join RF_DWH_ROLES_MODULE d on d.role_id = b.role_id  
 where 1=1   
 And a.user_id = @user_id  
 And c.deleted_by IS NULL  
 and a.deleted_by  IS NULL  
 And @module_id IS NULL OR d.module_id = @module_id  
 And @facility_id IS NULL OR c.facility_id = @facility_id  
  
End  
  