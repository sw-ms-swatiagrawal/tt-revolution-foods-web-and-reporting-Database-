

CREATE PROCEDURE [dbo].[ImportExcel_backup_20180806]
	@applecore_product_id INT,
	@applecore_variation_id INT,
	@productname varchar(max) = NULL,
	@variation_nm varchar(max) = NULL, 
	@pro_seal_twin_crew INT,
	@pro_seal_twin_t_max Decimal(18,4), 
	@pro_seal_single_crew INT,
	@pro_seal_single_t_max  Decimal(18,4),
	@over_wrap_crew INT,
	@over_wrap_t_max Decimal(18,4),
	@table_crew INT,
	@table_t_max  Decimal(18,4),
	@bulk_crew INT,
	@bulk_t_max Decimal(18,4),
	@play_book varchar(max),
	@category varchar(max),
	@twin_build_grade_id varchar(50),
	@single_build_grade_id varchar(50),
	@flow_build_grade_id varchar(50),
	@table_build_grade_id varchar(50),
	@default_line varchar(500)
as
Begin
	
	--select @applecore_variation_id
	if @applecore_variation_id is null
		return

	--Select @applecore_variation_id

	Select @twin_build_grade_id = build_grade_id From RF_DWH_BUILD_GRADE where LOWER(LTRIM(RTRIM(build_grade_nm))) = LOWER(LTRIM(RTRIM(@twin_build_grade_id)))
	Select @single_build_grade_id = build_grade_id From RF_DWH_BUILD_GRADE where LOWER(LTRIM(RTRIM(build_grade_nm))) = LOWER(LTRIM(RTRIM(@single_build_grade_id)))
	Select @flow_build_grade_id = build_grade_id From RF_DWH_BUILD_GRADE where LOWER(LTRIM(RTRIM(build_grade_nm))) = LOWER(LTRIM(RTRIM(@flow_build_grade_id)))
	Select @table_build_grade_id = build_grade_id From RF_DWH_BUILD_GRADE where LOWER(LTRIM(RTRIM(build_grade_nm))) = LOWER(LTRIM(RTRIM(@table_build_grade_id)))
	Set @default_line = (Select line_id From RF_DWH_LINE where LTRIM(RTRIM(line_nm)) = LTRIM(RTRIM(@default_line)))


	Set @variation_nm = LTRIM(RTRIM(@variation_nm))

	Declare @category_id int = 0
	Select top 1 @category_id = category_id From RF_DWH_CATEGORY where deleted_date IS NULL and category_nm = @category

	if(@category_id = 0)
	Begin
		Insert Into RF_DWH_CATEGORY
		(	
			category_nm,
			inserted_date,
			inserted_by
		)
		values
		(
		@category,
		getdate(),
		'superadmin'
		)
		SET @category_id =  SCOPE_IDENTITY()

	End

	Declare @variationid int = 0
	if  Exists(select 1 From RF_DWH_VARIATION_MASTER where variation_nm = @variation_nm 
	and deleted_date is NULL)
	begin
		Select @variationid = variation_id from RF_DWH_VARIATION_MASTER where variation_nm = @variation_nm
	End
	else
	Begin
		Declare @maxorderno Int
		Select @maxorderno = (max(order_no) + 1)from RF_DWH_VARIATION_MASTER 
		Insert into RF_DWH_VARIATION_MASTER 
		(
			variation_nm,order_no,inserted_date,inserted_by

		)
		values
		(
		@variation_nm,
		@maxorderno,getdate(), 'superadmin'
		)
		
		SET @variationid = SCOPE_IDENTITY()
	End

	If Not Exists(Select 1 From RF_DWH_ITEM where item_no = @applecore_product_id)
	Begin
		Insert Into RF_DWH_ITEM 
		(
			item_no,
			item_nm,
			inserted_date,
			inserted_by
		)
		values
		(
		@applecore_product_id,
		@productname,
		getdate(),
		'SuperAdmin'
		)

	End
	
--	Select * From XREF_ITEM_PRODUCT_VARIATION Where applecore_product_id = @applecore_product_id  And variation_id = @variationid 
--Select @applecore_product_id,@variationid, @applecore_variation_id,  @variationid,@category_id 
SELECT  @applecore_product_id AS applecore_product_id,
			@applecore_variation_id AS applecore_variation_id,
			@variationid AS variationid , 
			@pro_seal_twin_crew AS pro_seal_twin_crew,
			@pro_seal_twin_t_max AS pro_seal_twin_t_max , 
			@pro_seal_single_crew AS pro_seal_single_crew,
			@pro_seal_single_t_max AS pro_seal_single_t_max,
			@over_wrap_crew AS over_wrap_crew,
			@over_wrap_t_max AS over_wrap_t_max,
			@table_crew AS table_crew,
			@table_t_max AS table_t_max,
			@bulk_crew AS bulk_crew,
			@bulk_t_max AS bulk_t_max,
			@play_book AS play_book,
			@category_id AS category_id,
			@twin_build_grade_id AS twin_build_grade_id,
			@single_build_grade_id AS single_build_grade_id,
			@flow_build_grade_id AS flow_build_grade_id,
			@table_build_grade_id AS table_build_grade_id,
			@default_line AS default_line
			INTO #SRC

MERGE INTO XREF_ITEM_PRODUCT_VARIATION AS trg
USING #SRC AS src
			ON trg.applecore_product_id = src.applecore_product_id 
			AND trg.variation_id = src.variationid 
			
	  WHEN NOT MATCHED BY TARGET AND (src.variationid > 0 AND src.applecore_product_id > 0
			AND src.category_id > 0 AND isnull(src.applecore_variation_id,0) <> 0) THEN  
	  INSERT
	  (
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
		inserted_date,
		inserted_by,
		default_line_id
	  ) VALUES
	  (
			src.applecore_product_id ,
			src.applecore_variation_id ,
			src.variationid , 
			src.pro_seal_twin_crew ,
			src.pro_seal_twin_t_max , 
			src.pro_seal_single_crew,
			src.pro_seal_single_t_max ,
			src.over_wrap_crew ,
			src.over_wrap_t_max,
			src.table_crew ,
			src.table_t_max,
			src.bulk_crew ,
			src.bulk_t_max,
			src.play_book ,
			src.category_id,
			src.twin_build_grade_id,
			src.single_build_grade_id,
			src.flow_build_grade_id,
			src.table_build_grade_id,
			getdate(),
			'superadmin',
			src.default_line
	  )
	  WHEN MATCHED AND 
	  ( trg.applecore_variation_id <> src.applecore_variation_id 
	    AND deleted_date IS NULL
	    AND src.variationid > 0 AND src.applecore_product_id > 0
	    AND src.category_id > 0 AND isnull(src.applecore_variation_id,0) <> 0)	
	    OR trg.pro_seal_twin_crew <> src.pro_seal_twin_crew
	    OR trg.pro_seal_twin_t_max = src.pro_seal_twin_t_max 
		OR trg.pro_seal_single_crew = src.pro_seal_single_crew
		OR trg.pro_seal_single_t_max = src.pro_seal_single_t_max
		OR trg.over_wrap_crew = src.over_wrap_crew
		OR trg.over_wrap_t_max = src.over_wrap_t_max
		OR trg.table_crew =src.table_crew
		OR trg.table_t_max = src.table_t_max
		OR trg.bulk_crew = src.bulk_crew
		OR trg.bulk_t_max = src.bulk_t_max
		OR trg.play_book = src.play_book
		OR trg.category_id = src.category_id
		OR trg.twin_build_grade_id = src.twin_build_grade_id
		OR trg.single_build_grade_id = src.single_build_grade_id
		OR trg.flow_build_grade_id =src.flow_build_grade_id
		OR trg.table_build_grade_id = src.table_build_grade_id
		OR trg.default_line_id = src.default_line
	   THEN
	   Update  
		Set 	
		variation_id = src.variationid, 
		pro_seal_twin_crew = src.pro_seal_twin_crew,
		pro_seal_twin_t_max = src.pro_seal_twin_t_max, 
		pro_seal_single_crew = src.pro_seal_single_crew,
		pro_seal_single_t_max = src.pro_seal_single_t_max,
		over_wrap_crew = src.over_wrap_crew,
		over_wrap_t_max = src.over_wrap_t_max,
		table_crew =src.table_crew,
		table_t_max = src.table_t_max,
		bulk_crew = src.bulk_crew,
		bulk_t_max = src.bulk_t_max,
		play_book = src.play_book,
		category_id = src.category_id,
		twin_build_grade_id = src.twin_build_grade_id,
		single_build_grade_id = src.single_build_grade_id,
		flow_build_grade_id =src.flow_build_grade_id,
		table_build_grade_id = src.table_build_grade_id,
		default_line_id = src.default_line,
		modified_date =  getdate(),
		modified_by = 'superadmin';


	--If not Exists(Select 1  From XREF_ITEM_PRODUCT_VARIATION where applecore_product_id = @applecore_product_id 
	--And variation_id = @variationid 
	----And applecore_variation_id = @applecore_variation_id
	--And @variationid > 0 And @applecore_product_id > 0
	--And @category_id > 0 And isnull(@applecore_variation_id,0) <> 0)
	--		Insert Into XREF_ITEM_PRODUCT_VARIATION   
	--		(applecore_product_id, 
	--	applecore_variation_id,
	--	variation_id, 
	--	pro_seal_twin_crew,
	--	pro_seal_twin_t_max, 
	--	pro_seal_single_crew,
	--	pro_seal_single_t_max,
	--	over_wrap_crew,
	--	over_wrap_t_max,
	--	table_crew,
	--	table_t_max,
	--	bulk_crew,
	--	bulk_t_max,
	--	play_book,
	--	category_id,
	--	twin_build_grade_id,
	--	single_build_grade_id,
	--	flow_build_grade_id,
	--	table_build_grade_id,
	--	inserted_date,
	--	inserted_by,
	--	default_line_id)
	--	values
	--	(
	--	@applecore_product_id ,
	--		@applecore_variation_id ,
	--		@variationid , 
	--		@pro_seal_twin_crew ,
	--		@pro_seal_twin_t_max , 
	--		@pro_seal_single_crew,
	--		@pro_seal_single_t_max ,
	--		@over_wrap_crew ,
	--		@over_wrap_t_max,
	--		@table_crew ,
	--		@table_t_max,
	--		@bulk_crew ,
	--		@bulk_t_max,
	--		@play_book ,
	--		@category_id,
	--		@twin_build_grade_id,
	--		@single_build_grade_id,
	--		@flow_build_grade_id,
	--		@table_build_grade_id,
	--		getdate(),
	--		'superadmin',
	--		@default_line
	--	)
	--else if Exists(Select 1 from XREF_ITEM_PRODUCT_VARIATION where  applecore_product_id = @applecore_product_id  
	--and  applecore_variation_id = @applecore_variation_id 
	--and deleted_date IS NULL
	--And @variationid > 0 And @applecore_product_id > 0
	--And @category_id > 0 And isnull(@applecore_variation_id,0) <> 0)	
	--BEgin

	----Select * from XREF_ITEM_PRODUCT_VARIATION where  applecore_product_id = @applecore_product_id  
	----and  applecore_variation_id = @applecore_variation_id 
	----and deleted_date IS NULL
	----And @variationid > 0 And @applecore_product_id > 0
	----And @category_id > 0 And isnull(@applecore_variation_id,0) <> 0

	--	--@applecore_product_id
	--	Update XREF_ITEM_PRODUCT_VARIATION 
	--	Set 

		
	--	variation_id = @variationid, 
	--	pro_seal_twin_crew = @pro_seal_twin_crew,
	--	pro_seal_twin_t_max = @pro_seal_twin_t_max, 
	--	pro_seal_single_crew = @pro_seal_single_crew,
	--	pro_seal_single_t_max = @pro_seal_single_t_max,
	--	over_wrap_crew = @over_wrap_crew,
	--	over_wrap_t_max = @over_wrap_t_max,
	--	table_crew =@table_crew,
	--	table_t_max = @table_t_max,
	--	bulk_crew = @bulk_crew,
	--	bulk_t_max = @bulk_t_max,
	--	play_book = @play_book,
	--	category_id = @category_id,
	--	twin_build_grade_id = @twin_build_grade_id,
	--	single_build_grade_id = @single_build_grade_id,
	--	flow_build_grade_id =@flow_build_grade_id,
	--	table_build_grade_id = @table_build_grade_id,
	--	default_line_id = @default_line
	--	where applecore_product_id = @applecore_product_id  
	--and  applecore_variation_id = @applecore_variation_id and deleted_date IS NULL



	
End
