CREATE PROCEDURE [dbo].[usp_DOR_GET_DTDETAILS_DETAILS]      
(      
 @dt_detail_id INT = NULL,      
 @facility_id INT = NULL,      
 @date DATETIME = NULL      
)      
AS      
BEGIN      
       
 SET NOCOUNT ON;      
      
    SELECT a.dt_detail_id      
     , YEAR(a.dt_date) AS year      
     , MONTH(a.dt_date) AS month      
     , DATEPART(WEEK,a.dt_date) AS week      
     , CAST(a.dt_date AS DATE) AS date      
     , b.shift_cd AS shift_cd      
     , b.shift_nm AS shift_nm          
     , a.shift_id AS shift_id      
     , c.line_cd AS line_cd      
     , c.line_nm AS line_nm       
     , a.line_id AS line_id      
     , d.item_no AS item_no      
     , d.item_nm AS item_nm      
     , a.item_id AS item_id      
     , e.dt_reason_cd AS dt_reason_cd      
     , e.dt_reason AS dt_reason      
     , e.dt_category AS dt_category      
     , a.reason_id      
     , a.occur      
     , a.[minutes]      
     , a.facility_id 
	 , g.facility_cd  
	 , a.item_product_variation_id   
  , vm.variation_nm    
   FROM RF_DWH_DTDETAILS AS a      
   JOIN RF_DWH_SHIFT AS b      
     ON a.shift_id = b.shift_id      
   JOIN RF_DWH_LINE c      
     ON c.line_id = a.line_id      
   JOIN RF_DWH_ITEM d      
     ON d.item_id = a.item_id      
   JOIN RF_DWH_DT_REASON_CATEGORY e      
     ON e.dt_reason_category_id = a.reason_id      
   JOIN RF_DWH_FACILITY g      
     ON g.facility_id = a.facility_id      
   LEFT JOIN XREF_ITEM_PRODUCT_VARIATION v   
  on v.applecore_product_id = d.item_no And a.item_product_variation_id = v.item_product_variation_id   
      Left Join RF_DWH_VARIATION_MASTER vm on vm.variation_id = v.variation_id            
  WHERE a.deleted_date IS NULL      
    AND a.dt_detail_id = COALESCE(@dt_detail_id, a.dt_detail_id)         
    AND g.facility_id = COALESCE(@facility_id,g.facility_id)      
    AND a.dt_date = COALESCE(@date,a.dt_date)      
    AND b.deleted_date IS NULL      
    AND c.deleted_date IS NULL      
    AND d.deleted_date IS NULL      
    AND e.deleted_date IS NULL      
 AND v.deleted_by IS NULL     
END;      

