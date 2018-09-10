CREATE PROCEDURE [dbo].[usp_DOR_VARIATION_MANAGE]  
 @xml XML,  
 @error_message VARCHAR(MAX) OUTPUT  
AS  
BEGIN  
   
 SET NOCOUNT ON;  
  
 DECLARE @hDoc AS INT  
      
 BEGIN TRANSACTION  
  
  BEGIN TRY  
   EXEC sp_xml_preparedocument   @hDoc output, @xml   
	
   MERGE XREF_ITEM_PRODUCT_VARIATION AS trg   
   USING (SELECT 
   item_product_variation_id,
   applecore_product_id,   
       applecore_variation_id,
	   variation_id,
       pro_seal_twin_crew,   
       pro_seal_twin_t_max,   
       pro_seal_single_crew,   
       pro_seal_single_t_max,   
       over_wrap_crew,   
       over_wrap_t_max,   
       table_crew,   
       table_t_max,   
       bulk_crew,   
       bulk_t_max,   
       play_book,   
       category_id,   
       twin_build_grade_id,   
       single_build_grade_id,   
       flow_build_grade_id,   
       table_build_grade_id,   
       GETDATE() AS inserted_date,   
       inserted_by,   
       CASE WHEN modified_by IS NULL THEN NULL ELSE GETDATE() END AS modified_date,   
       modified_by,   
       CASE WHEN deleted_by IS NULL THEN NULL ELSE GETDATE() END AS deleted_date,   
       deleted_by,
	   default_line_id   
     FROM   OPENXML(@hDoc, 'item_master/item', 3)   
        WITH ( 
		[item_product_variation_id]               [INT],   
		[applecore_product_id]               [INT],   
         [applecore_variation_id]               [INT],   
         [variation_id]                 [INT],      
         [pro_seal_twin_crew]    [INT],   
         [pro_seal_twin_t_max]   [DECIMAL](18, 4),   
         [pro_seal_single_crew]  [INT],   
         [pro_seal_single_t_max] [DECIMAL](18, 4),   
         [over_wrap_crew]        [INT],   
         [over_wrap_t_max]       [DECIMAL](18, 4),   
         [table_crew]            [INT],   
         [table_t_max]           [DECIMAL](18, 4),   
         [bulk_crew]             [INT],   
         [bulk_t_max]            [DECIMAL](18, 4),   
         [play_book]             [VARCHAR](1000),   
         [category_id]           [INT],   
         [twin_build_grade_id]   [INT],   
         [single_build_grade_id] [INT],   
         [flow_build_grade_id]   [INT],   
         [table_build_grade_id]  [INT],   
         [inserted_by]           [VARCHAR](50),   
         [modified_by]           [VARCHAR](50),   
         [deleted_by]            [VARCHAR](50),
		 [default_line_id]		 int
		 )  
   ) AS src   
   ON trg.item_product_variation_id = src.item_product_variation_id   
   WHEN NOT MATCHED BY TARGET    
   THEN   
    INSERT (applecore_product_id,   
      applecore_variation_id, 
	    variation_id, 
      pro_seal_twin_crew,   
      pro_seal_twin_t_max,   
      pro_seal_single_crew,   
      pro_seal_single_t_max,   
      over_wrap_crew,   
      over_wrap_t_max,   
      table_crew,   
      table_t_max,   
      bulk_crew,   
      bulk_t_max,   
      play_book,   
      category_id,   
      twin_build_grade_id,   
      single_build_grade_id,   
      flow_build_grade_id,   
      table_build_grade_id,   
      inserted_date,   
      inserted_by,default_line_id)   
    VALUES(src.applecore_product_id,   
      src.applecore_variation_id,   
	  src.variation_id,   
      src.pro_seal_twin_crew,   
      src.pro_seal_twin_t_max,   
      src.pro_seal_single_crew,   
      src.pro_seal_single_t_max,   
      src.over_wrap_crew,   
      src.over_wrap_t_max,   
      src.table_crew,   
      src.table_t_max,   
      src.bulk_crew,   
      src.bulk_t_max,   
      src.play_book,   
      src.category_id,   
      src.twin_build_grade_id,   
      src.single_build_grade_id,   
      src.flow_build_grade_id,   
      src.table_build_grade_id,   
      src.inserted_date,   
      src.inserted_by,src.default_line_id)   
   WHEN MATCHED  
   THEN   
    UPDATE SET trg.applecore_product_id = src.applecore_product_id,   
       trg.applecore_variation_id = src.applecore_variation_id,   
	   trg.variation_id = src.variation_id,   
       trg.pro_seal_twin_crew = src.pro_seal_twin_crew,   
       trg.pro_seal_twin_t_max = src.pro_seal_twin_t_max,   
       trg.pro_seal_single_crew = src.pro_seal_single_crew,   
       trg.pro_seal_single_t_max = src.pro_seal_single_t_max,   
       trg.over_wrap_crew = src.over_wrap_crew,   
       trg.over_wrap_t_max = src.over_wrap_t_max,   
       trg.table_crew = src.table_crew,   
       trg.table_t_max = src.table_t_max,   
       trg.bulk_crew = src.bulk_crew,   
       trg.bulk_t_max = src.bulk_t_max,   
       trg.play_book = src.play_book,   
       trg.category_id = src.category_id,   
       trg.twin_build_grade_id = src.twin_build_grade_id,   
       trg.single_build_grade_id = src.single_build_grade_id,   
       trg.flow_build_grade_id = src.flow_build_grade_id,   
       trg.table_build_grade_id = src.table_build_grade_id,   
       trg.modified_date = COALESCE(trg.modified_date, src.modified_date),   
       trg.modified_by = COALESCE(trg.modified_by, src.modified_by),   
       trg.deleted_date = CASE   
            WHEN src.deleted_by IS NULL THEN NULL   
            ELSE src.deleted_date   
           END,   
       trg.deleted_by = src.deleted_by,
	   trg.default_line_id = src.default_line_id;   
  
  EXEC sp_xml_removedocument @hDoc  
  END TRY  
  BEGIN CATCH  
  
   SELECT @error_message = ERROR_MESSAGE();  
  
   IF @@TRANCOUNT > 0  
   ROLLBACK;  
  
  END CATCH  
   
 IF @@TRANCOUNT > 0  
 COMMIT;  
END  
