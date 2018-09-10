Create Procedure [dbo].[USP_DOR_COPY_STANDARDS]
	@from_item_no INT,
	@to_item_no INT,
	@from_variation_id INT,
	@to_variation_id INT,
	@error_message VARCHAR(MAX) OUTPUT    
as
Begin
	
	BEGIN TRANSACTION    
    
  BEGIN TRY 

	UPDATE t
	SET t.pro_seal_twin_crew = f.pro_seal_twin_crew,
		t.pro_seal_twin_t_max = f.pro_seal_twin_t_max,
		t.pro_seal_single_crew = f.pro_seal_single_crew,
		t.pro_seal_single_t_max = f.pro_seal_single_t_max,
		t.over_wrap_crew  = f.over_wrap_crew ,
		t.over_wrap_t_max = f.over_wrap_t_max,
		t.table_crew = f.table_crew,
		t.table_t_max = f.table_t_max,
		t.bulk_crew = f.bulk_crew,
		t.bulk_t_max = f.bulk_t_max,
		t.play_book = f.play_book,
		t.category_id = f.category_id,
		t.twin_build_grade_id = f.twin_build_grade_id,
		t.single_build_grade_id = f.single_build_grade_id,
		t.flow_build_grade_id = f.flow_build_grade_id,
		t.table_build_grade_id = f.table_build_grade_id
	From [dbo].[XREF_ITEM_PRODUCT_VARIATION] t, [dbo].[XREF_ITEM_PRODUCT_VARIATION] f
	where f.applecore_product_id = @from_item_no  And f.item_product_variation_id = @from_variation_id
		AND t.applecore_product_id = @to_item_no And t.item_product_variation_id = @to_variation_id

END TRY    
  BEGIN CATCH    
    
   SELECT @error_message = ERROR_MESSAGE();    
    
   IF @@TRANCOUNT > 0    
   ROLLBACK;    
    
  END CATCH    
     
 IF @@TRANCOUNT > 0    
 COMMIT;    

End
