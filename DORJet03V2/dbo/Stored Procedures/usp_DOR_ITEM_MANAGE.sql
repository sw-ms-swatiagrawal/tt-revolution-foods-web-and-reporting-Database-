CREATE PROCEDURE [dbo].[usp_DOR_ITEM_MANAGE]  
 @xml XML,  
 @error_message VARCHAR(MAX) OUTPUT  
AS  
BEGIN  
   
 SET NOCOUNT ON;  
  
 DECLARE @hDoc AS INT  
      
 BEGIN TRANSACTION  
  
  BEGIN TRY  
   EXEC sp_xml_preparedocument   @hDoc output, @xml   
  
  -- Added by REVFOODDOR-102 06/15/2018 starts
    CREATE TABLE  #TEMPOUT 
	(
		Inserted_item_no int,
		Deleted_item_no int
	)
-- Added by REVFOODDOR-102 06/15/2018 ends

   MERGE RF_DWH_ITEM AS trg   
   USING (SELECT item_id,   
       item_no,   
       item_nm,   
       --pro_seal_twin_crew,   
       --pro_seal_twin_t_max,   
       --pro_seal_single_crew,   
       --pro_seal_single_t_max,   
       --over_wrap_crew,   
       --over_wrap_t_max,   
       --table_crew,   
       --table_t_max,   
       --bulk_crew,   
       --bulk_t_max,   
       --play_book,   
       --category_id,   
       --twin_build_grade_id,   
       --single_build_grade_id,   
       --flow_build_grade_id,   
       --table_build_grade_id,   
       GETDATE() AS inserted_date,   
       inserted_by,   
       CASE   
       WHEN modified_by IS NULL THEN NULL   
       ELSE GETDATE()   
       END AS modified_date,   
       modified_by,   
       CASE   
       WHEN deleted_by IS NULL THEN NULL   
       ELSE GETDATE()   
       END          AS deleted_date,   
       deleted_by   
     FROM   OPENXML(@hDoc, 'item_master/item', 3)   
        WITH ( [item_id]               [INT],   
         [item_no]               [INT],   
         [item_nm]               [VARCHAR](1000),   
         --[pro_seal_twin_crew]    [INT],   
         --[pro_seal_twin_t_max]   [DECIMAL](18, 4),   
         --[pro_seal_single_crew]  [INT],   
         --[pro_seal_single_t_max] [DECIMAL](18, 4),   
         --[over_wrap_crew]        [INT],   
         --[over_wrap_t_max]       [DECIMAL](18, 4),   
         --[table_crew]            [INT],   
         --[table_t_max]           [DECIMAL](18, 4),   
         --[bulk_crew]             [INT],   
         --[bulk_t_max]            [DECIMAL](18, 4),   
         --[play_book]             [VARCHAR](1000),   
         --[category_id]           [INT],   
         --[twin_build_grade_id]   [INT],   
         --[single_build_grade_id] [INT],   
         --[flow_build_grade_id]   [INT],   
         --[table_build_grade_id]  [INT],   
         [inserted_by]           [VARCHAR](50),   
         [modified_by]           [VARCHAR](50),   
         [deleted_by]            [VARCHAR](50) )  
   ) AS src   
   ON trg.item_id = src.item_id   
   WHEN NOT MATCHED BY TARGET    
   THEN   
    INSERT (item_no,   
      item_nm,   
      --pro_seal_twin_crew,   
      --pro_seal_twin_t_max,   
      --pro_seal_single_crew,   
      --pro_seal_single_t_max,   
      --over_wrap_crew,   
      --over_wrap_t_max,   
      --table_crew,   
      --table_t_max,   
      --bulk_crew,   
      --bulk_t_max,   
      --play_book,   
      --category_id,   
      --twin_build_grade_id,   
      --single_build_grade_id,   
      --flow_build_grade_id,   
      --table_build_grade_id,   
      inserted_date,   
      inserted_by)   
    VALUES(src.item_no,   
      src.item_nm,   
      --src.pro_seal_twin_crew,   
      --src.pro_seal_twin_t_max,   
      --src.pro_seal_single_crew,   
      --src.pro_seal_single_t_max,   
      --src.over_wrap_crew,   
      --src.over_wrap_t_max,   
      --src.table_crew,   
      --src.table_t_max,   
      --src.bulk_crew,   
      --src.bulk_t_max,   
      --src.play_book,   
      --src.category_id,   
      --src.twin_build_grade_id,   
      --src.single_build_grade_id,   
      --src.flow_build_grade_id,   
      --src.table_build_grade_id,   
      src.inserted_date,   
      src.inserted_by)   
   WHEN MATCHED  
   THEN   
    UPDATE SET trg.item_no = src.item_no,   
       trg.item_nm = src.item_nm,   
       --trg.pro_seal_twin_crew = src.pro_seal_twin_crew,   
       --trg.pro_seal_twin_t_max = src.pro_seal_twin_t_max,   
       --trg.pro_seal_single_crew = src.pro_seal_single_crew,   
       --trg.pro_seal_single_t_max = src.pro_seal_single_t_max,   
       --trg.over_wrap_crew = src.over_wrap_crew,   
       --trg.over_wrap_t_max = src.over_wrap_t_max,   
       --trg.table_crew = src.table_crew,   
       --trg.table_t_max = src.table_t_max,   
       --trg.bulk_crew = src.bulk_crew,   
       --trg.bulk_t_max = src.bulk_t_max,   
       --trg.play_book = src.play_book,   
       --trg.category_id = src.category_id,   
       --trg.twin_build_grade_id = src.twin_build_grade_id,   
       --trg.single_build_grade_id = src.single_build_grade_id,   
       --trg.flow_build_grade_id = src.flow_build_grade_id,   
       --trg.table_build_grade_id = src.table_build_grade_id,   
       trg.modified_date = COALESCE(trg.modified_date, src.modified_date),   
       trg.modified_by = COALESCE(trg.modified_by, src.modified_by),   
       trg.deleted_date = CASE   
            WHEN src.deleted_by IS NULL THEN NULL   
            ELSE src.deleted_date   
           END,   
       trg.deleted_by = src.deleted_by   
  -- Added by REVFOODDOR-102 06/15/2018 starts
   OUTPUT INSERTED.item_no,DELETED.item_no
	   INTO #TEMPOUT;
		

	declare @OLD_ID as int,@New_ID as int
	

	set @New_ID = (select top 1 Inserted_item_no from #TEMPOUT)
	set @OLD_ID = (select top 1 Deleted_item_no from #TEMPOUT)


	if @New_ID <> @OLD_ID
		BEGIN
			Update XREF_ITEM_PRODUCT_VARIATION set applecore_product_id = @New_ID
			WHERE applecore_product_id = @OLD_ID
		END

		-- Added by REVFOODDOR-102 06/15/2018 ends

	Declare @deleted_by varchar(30)
	Declare @item_no INT
	  SELECT  top 1  @deleted_by = deleted_by,@item_no =  item_no
     FROM   OPENXML(@hDoc, 'item_master/item',3)     
        WITH (   
		[deleted_by]        varchar(30) ,
		item_no INT     
		) AS a 


		if(@deleted_by IS NOT NULL OR @deleted_by <> '')
		Begin
			Update XREF_ITEM_PRODUCT_VARIATION Set deleted_by = @deleted_by,
			deleted_date = getdate()
			where applecore_product_id = @item_no
			AND deleted_date IS NULL
		End

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
