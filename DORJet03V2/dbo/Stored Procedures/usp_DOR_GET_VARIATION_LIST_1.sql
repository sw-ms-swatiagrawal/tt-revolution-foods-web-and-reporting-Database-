  
CREATE Procedure [dbo].[usp_DOR_GET_VARIATION_LIST]    
 @item_no int    
as    
begin    
    
 Select     
 a.item_product_variation_id,    
 a.applecore_variation_id,    
 a.variation_id,    
 a.applecore_product_id,  
 a.pro_seal_twin_crew AS pro_seal_twin_crew,       
     CAST(a.pro_seal_twin_t_max AS INT) AS pro_seal_twin_t_max,       
     a.pro_seal_single_crew AS pro_seal_single_crew,       
     CAST(a.pro_seal_single_t_max AS INT ) AS pro_seal_single_t_max,       
     a.over_wrap_crew AS over_wrap_crew,       
     CAST(a.over_wrap_t_max AS INT ) AS over_wrap_t_max,       
     a.table_crew AS table_crew,       
     CAST(a.table_t_max AS INT) AS table_t_max,       
     a.bulk_crew AS bulk_crew,       
     CAST(a.bulk_t_max AS INT)AS bulk_t_max,       
    
 a.play_book,    
 a.category_id,    
 a.twin_build_grade_id,    
 a.single_build_grade_id,    
 a.flow_build_grade_id,    
 a.table_build_grade_id,    
 b.variation_nm,    
 c.item_nm,
 b.order_no
  From XREF_ITEM_PRODUCT_VARIATION a    
  left join RF_DWH_VARIATION_MASTER b on b.variation_id = a.variation_id    
  left join RF_DWH_ITEM c on c.item_no = a.applecore_product_id    
  Where 1=1 
  And a.applecore_product_id = @item_no    
  And a.deleted_by is  null  
  And b.deleted_date is  null  
  And c.deleted_date is null
End 
