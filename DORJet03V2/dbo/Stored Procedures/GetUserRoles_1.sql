CREATE Procedure [dbo].[GetUserRoles]      
 @user_id int,      
 @facility_id int = NULL,      
 @module_id int = NULL      
      
as      
Begin      
;With CTE as  (    
 Select c.role_id, a.user_id,e.facility_id ,d.module_id, d.view_fg, d.insert_fg, d.update_fg, d.delete_fg,
 d.edit_locked_record_fg,d.add_locked_record_fg  From RF_DWH_USERS a      
 join RF_DWH_USER_ROLE b on b.user_id = a.user_id      
 join RF_DWH_ROLES c on c.role_id = b.role_id      
 join RF_DWH_ROLES_MODULE d on d.role_id = b.role_id   
 join RF_DWH_ROLE_FACILITY e on e.role_id = c.role_id      
 where 1=1       
 And a.user_id = @user_id      
 And c.deleted_by IS NULL      
 and a.deleted_by  IS NULL      
 And (@module_id IS NULL OR d.module_id = @module_id)      
 And (@facility_id IS NULL OR e.facility_id = @facility_id)      
  )    
  Select top 1     
  cast((case when Exists(Select CTE.view_fg From CTE where CTE.view_fg = 1 ) Then 1 else 0 End)as bit)as view_fg,    
  cast((case when Exists(Select CTE.insert_fg From CTE where CTE.insert_fg = 1 ) Then 1 else 0 End)as bit)as insert_fg,    
  cast((case when Exists(Select CTE.update_fg From CTE where CTE.update_fg = 1 ) Then 1  else 0 End)as bit)as update_fg,    
  cast((case when Exists(Select CTE.delete_fg From CTE where CTE.delete_fg = 1 ) Then 1 else 0 End)as bit)as delete_fg,    
  cast((case when Exists(Select CTE.add_locked_record_fg From CTE where CTE.add_locked_record_fg = 1 ) Then 1 else 0 End)as bit)as 
  add_locked_record_fg,   
  cast((case when Exists(Select CTE.edit_locked_record_fg From CTE where CTE.edit_locked_record_fg = 1 ) Then 1 else 0 End)as bit)as 
  edit_locked_record_fg    
      
End  
GO
