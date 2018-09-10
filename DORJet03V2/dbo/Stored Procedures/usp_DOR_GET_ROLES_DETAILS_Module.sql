CREATE PROCEDURE [dbo].[usp_DOR_GET_ROLES_DETAILS_Module]        
(        
 @role_id INT  
-- @facility_id INT        
)        
AS        
BEGIN        
         
 SET NOCOUNT ON;        
         
 ;With CTE        
 as(        
    SELECT  m.module_nm        
  ,r.role_id        
  , r.role_cd        
  , r.role_nm        
  , m.module_id        
 -- , r.facility_id        
  ,rm.view_fg        
  , rm.insert_fg        
  , rm.update_fg        
  , rm.delete_fg      
  , rm.edit_locked_record_fg 
  , rm.add_locked_record_fg 
 FROM  dbo.RF_DWH_ROLES AS r         
 join dbo.RF_DWH_ROLES_MODULE as rm    
 on rm.role_id = r.role_id    
  JOIN dbo.RF_DWH_MODULES AS m        
  ON m.module_id = rm.module_id      
  AND m.deleted_date IS NULL        
 --JOIN dbo.RF_DWH_FACILITY AS c        
 -- ON r.facility_id = c.facility_id        
  --AND c.deleted_date IS NULL        
 WHERE  r.role_id = ISNULL(@role_id, r.role_id)         
   AND r.deleted_date IS NULL        
  -- And r.facility_id = @facility_id        
   )        
          
    Select         
    CTE.role_id        
    ,m.module_nm        
  , m.module_id     
  --,CTE.facility_id       
  , isnull(cte.view_fg, 0) as view_fg        
  , isnull(cte.insert_fg, 0) as insert_fg        
  , isnull(cte.update_fg, 0) as update_fg        
  , isnull(cte.delete_fg, 0) as delete_fg        
  , isnull(cte.delete_fg, 0) as delete_fg        
  , isnull(cte.edit_locked_record_fg, 0) as edit_locked_record_fg 
  , ISNULL(CTE.add_locked_record_fg ,0) as add_locked_record_fg
    From dbo.RF_DWH_MODULES m        
    Left join CTE           
    on m.module_id = CTE.module_id        
    where m.deleted_date is null        
END;   
