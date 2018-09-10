
CREATE PROCEDURE dbo.usp_DOR_GET_MODULES_DETAILS  
(  
 @module_id INT = NULL  
)  
AS  
BEGIN  
   
 SET NOCOUNT ON;  
  
    SELECT a.module_id  
  , a.module_cd  
  , a.module_nm  
  , a.inserted_date  
  , a.inserted_by  
  , a.modified_date  
  , a.modified_by  
  , a.deleted_date  
  , a.deleted_by  
 FROM dbo.RF_DWH_MODULES AS a  
 WHERE a.module_id = ISNULL(@module_id, a.module_id)   
   AND a.deleted_date IS NULL;  
  
END;  
