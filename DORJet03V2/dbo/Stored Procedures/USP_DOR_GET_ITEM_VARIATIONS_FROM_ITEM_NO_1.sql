
Create Procedure [dbo].[USP_DOR_GET_ITEM_VARIATIONS_FROM_ITEM_NO]    
 @item_no int    
as    
begin    
    
 Set NoCount on;    
    
 Select distinct c.variation_id, c.variation_nm,b.item_id,b.item_no,a.item_product_variation_id,
 c.order_no
  from XREF_ITEM_PRODUCT_VARIATION as a    
 left join  RF_DWH_ITEM b on b.item_no = a.applecore_product_id    
 left join  RF_DWH_VARIATION_MASTER c on c.variation_id = a.variation_id    
 where 1= 1 
 And b.deleted_date IS NULL 
 And a.deleted_date IS NULL 
 And b.item_no = @item_no   
 And c.deleted_date IS NULL 
 
 group by c.variation_id, c.variation_nm,b.item_id,b.item_no,a.item_product_variation_id,order_no  
 Order by c.order_no   
End  
