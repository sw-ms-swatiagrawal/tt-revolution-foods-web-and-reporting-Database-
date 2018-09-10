CREATE PROCEDURE dbo.usp_DOR_GET_ROLES_DETAILS        
(        
 @role_id INT = NULL        
)        
AS        
BEGIN        
         
 SET NOCOUNT ON;    
   
   SELECT Distinct        
 a.role_id  
   ,a.role_cd        
  , a.role_nm        
  , a.inserted_date
  , (SELECT facility_nm + ',' FROM RF_DWH_ROLE_FACILITY b
			JOIN RF_DWH_FACILITY AS C ON c.facility_id = b.facility_id
			WHERE b.role_id = a.role_id   AND c.deleted_date IS NULL FOR XML PATH ('')) AS facility_nm
 FROM dbo.RF_DWH_ROLES AS a        
 join RF_DWH_ROLE_FACILITY d on d.role_id = a.role_id      
 WHERE 1=1     
 And a.role_id = ISNULL(@role_id, a.role_id)         
 AND a.deleted_date IS NULL
  And a.role_nm <> 'SuperAdmin'
   Order by a.inserted_date Desc;

    
        
END;   
