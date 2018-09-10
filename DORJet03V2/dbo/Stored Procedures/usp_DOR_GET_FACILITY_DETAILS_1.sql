
CREATE PROCEDURE [dbo].[usp_DOR_GET_FACILITY_DETAILS]   
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
	 ,facility_profit_code
   FROM RF_DWH_FACILITY  
  WHERE 1 = 1      
    AND facility_id = COALESCE(@facility_id,facility_id)   
    AND deleted_date IS NULL  
END  
 
