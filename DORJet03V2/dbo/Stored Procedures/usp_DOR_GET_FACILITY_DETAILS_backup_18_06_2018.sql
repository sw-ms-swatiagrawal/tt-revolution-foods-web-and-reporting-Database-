CREATE PROCEDURE [dbo].[usp_DOR_GET_FACILITY_DETAILS_backup_18_06_2018]   
 @facility_id INT = NULL  
AS  
BEGIN  
   
 SET NOCOUNT ON;  
  
    SELECT facility_id AS facility_id  
     ,facility_cd AS facility_cd  
     ,facility_nm AS facility_nm  
	 ,shift_start_time
	 ,item_break_time
	 ,variation_break_time
   FROM RF_DWH_FACILITY  
  WHERE 1 = 1      
    AND facility_id = COALESCE(@facility_id,facility_id)   
    AND deleted_date IS NULL  
END  
