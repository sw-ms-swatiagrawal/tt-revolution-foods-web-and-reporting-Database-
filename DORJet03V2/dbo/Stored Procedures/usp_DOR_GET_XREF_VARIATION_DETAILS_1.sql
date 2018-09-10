CREATE PROCEDURE [dbo].[usp_DOR_GET_XREF_VARIATION_DETAILS]      
 @item_product_variation_id int      
as      
Begin      
      
 Select       
  i.item_id AS item_id,        
     item_no AS item_no,         
     item_nm AS item_nm,       
  a.applecore_product_id,    
  a.applecore_variation_id,    
  a.variation_id,    
  a.item_product_variation_id,  
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
     a.play_book AS play_book,        
     a.category_id AS category_id,        
     b.category_nm AS category_nm,         
     a.twin_build_grade_id AS twin_build_grade_id,        
     c.build_grade_nm AS twin_build_grade,        
     a.single_build_grade_id AS single_build_grade_id,         
     d.build_grade_nm AS single_build_grade,        
     a.flow_build_grade_id AS flow_build_grade_id,         
     e.build_grade_nm AS flow_build_grade,        
     a.table_build_grade_id AS table_build_grade_id,        
     f.build_grade_nm AS table_build_grade,
	 a.default_line_id as    default_line_id
From XREF_ITEM_PRODUCT_VARIATION  a      
   Inner JOIN RF_DWH_ITEM i         
   ON i.item_no = a.applecore_product_id      
 LEFT JOIN RF_DWH_CATEGORY b         
   ON a.category_id = b.category_id         
 LEFT JOIN RF_DWH_BUILD_GRADE c         
   ON c.build_grade_id = a.twin_build_grade_id         
 LEFT JOIN RF_DWH_BUILD_GRADE d         
   ON d.build_grade_id = a.single_build_grade_id         
 LEFT JOIN RF_DWH_BUILD_GRADE e         
   ON e.build_grade_id = a.flow_build_grade_id         
 LEFT JOIN RF_DWH_BUILD_GRADE f         
   ON f.build_grade_id = a.table_build_grade_id 
   LEFT JOIN RF_DWH_LINE g         
   ON g.line_id = a.default_line_id
where 1 =1       
And a.item_product_variation_id = @item_product_variation_id      
And a.deleted_by is  null  
      
End 
