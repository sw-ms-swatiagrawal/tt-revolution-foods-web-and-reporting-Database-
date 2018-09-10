CREATE PROCEDURE [dbo].[usp_DOR_GET_WASTEENTRY_DETAILS]        
(        
 @waste_entry_id INT = NULL,       
 @date DATETIME = null,      
    @facility_id INT = NULL,     
 @shift_id INT = NULL,        
 @line_id INT = NULL,        
 @item_id INT = NULL        
)        
AS        
BEGIN        
         
 SET NOCOUNT ON;        
        
    SELECT a.waste_entry_id, a.waste_entry_date,         
   a.shift_id, b.shift_nm,         
   a.line_id, c.line_nm,         
   a.item_id, d.item_no, d.item_nm,         
   a.waste_type_id, e.waste_type_nm,         
   a.[weight],     
   a.facility_id,  
   vm.variation_nm,  
   a.item_product_variation_id  
 FROM dbo.RF_DWH_WASTEENTRY AS a        
 JOIN dbo.RF_DWH_SHIFT AS b ON a.shift_id = b.shift_id        
 JOIN dbo.RF_DWH_LINE AS c ON c.line_id = a.line_id        
 JOIN dbo.RF_DWH_ITEM AS d ON d.item_id = a.item_id        
 JOIN dbo.RF_DWH_WASTE_TYPE AS e ON e.waste_type_id = a.waste_type_id  
 JOIN dbo.XREF_ITEM_PRODUCT_VARIATION pv on pv.item_product_variation_id = a.item_product_variation_id  
 JOIN dbo.RF_DWH_VARIATION_MASTER vm on vm.variation_id = pv.variation_id      
  
WHERE 1=1 
AND a.deleted_date IS NULL        
 AND a.waste_entry_id = COALESCE(@waste_entry_id, a.waste_entry_id)        
 AND a.shift_id = COALESCE(@shift_id, a.shift_id)        
 AND a.line_id = COALESCE(@line_id, a.line_id)        
 AND a.item_id = COALESCE(@item_id, a.item_id)        
 AND a.facility_id = COALESCE(@facility_id, a.facility_id)        
   AND (@date IS NULL OR CAST(a.waste_entry_date AS DATE) = CAST(@date AS DATE));       
      
END;     
