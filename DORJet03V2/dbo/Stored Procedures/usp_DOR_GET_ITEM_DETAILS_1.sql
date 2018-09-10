

CREATE PROCEDURE [dbo].[usp_DOR_GET_ITEM_DETAILS]
 @item_id INT = NULL,        
 @search_tx VARCHAR(MAX) = null        
AS        
BEGIN        
         
 SET NOCOUNT ON; 
        
    If(@search_tx = '')     
	Begin
		Set @search_tx = NULL
	End  
 SELECT a.item_id AS item_id,        
     item_no AS item_no,         
     item_nm AS item_nm  
  --item_maketime_minutes as item_maketime_minutes  
 FROM   RF_DWH_ITEM a       
     
   WHERE 1 = 1        
    AND a.item_id = COALESCE(@item_id,a.item_id)        
 AND (
 @search_tx is null    
 OR LOWER(a.item_nm) like '%'+ LOWER(@search_tx) +'%'  
 OR CAST(a.item_no AS VARCHAR) =  @search_tx 
 OR a.item_no in (Select applecore_product_id From XREF_ITEM_PRODUCT_VARIATION   
 where CAST(applecore_variation_id AS VARCHAR) = @search_tx  and deleted_date IS NULL)   
  )        
  AND a.deleted_date IS NULL    
  Order by item_no   
               
END 
