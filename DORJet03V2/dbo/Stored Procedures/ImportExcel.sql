CREATE PROCEDURE [dbo].[ImportExcel]
 @TVP ImportExcelTableType READONLY,
 @error_message VARCHAR(MAX) OUTPUT   
AS   
    SET NOCOUNT ON  

BEGIN
BEGIN TRY
	
	IF EXISTS ( SELECT 1 FROM @TVP WHERE applecore_variation_id is null)
		return
	
	IF OBJECT_ID('TEMPDB..#Grade_id') IS NOT NULL          
     DROP TABLE  #Grade_id
	  IF OBJECT_ID('TEMPDB..#default_line') IS NOT NULL          
     DROP TABLE  #default_line
	 IF OBJECT_ID('TEMPDB..#category') IS NOT NULL          
     DROP TABLE  #category
	 IF OBJECT_ID('TEMPDB..#variation') IS NOT NULL          
     DROP TABLE  #variation
	  IF OBJECT_ID('TEMPDB..#occurance') IS NOT NULL		
 	 DROP TABLE #occurance
	   IF OBJECT_ID('TEMPDB..#tmp') IS NOT NULL		
 	 DROP TABLE #tmp
	 IF OBJECT_ID('TEMPDB..#tmp1') IS NOT NULL		
 	 DROP TABLE #tmp1

	Select B.build_grade_nm AS B_build_grade_nm,B.build_grade_id AS twin_build_grade_id ,B1.build_grade_nm AS B1_build_grade_nm, B1.build_grade_id AS single_build_grade_id ,B2.build_grade_nm AS B2_build_grade_nm,B2.build_grade_id AS flow_build_grade_id ,B3.build_grade_nm AS B3_build_grade_nm,B3.build_grade_id AS table_build_grade_id
	 INTO #Grade_id
	 From @TVP T LEFT JOIN RF_DWH_BUILD_GRADE B 
	ON LOWER(LTRIM(RTRIM(B.build_grade_nm))) = ISNULL(LOWER(LTRIM(RTRIM(T.twin_build_grade_id))) ,'Easy')
	LEFT JOIN RF_DWH_BUILD_GRADE B1
	ON LOWER(LTRIM(RTRIM(B1.build_grade_nm))) = ISNULL(LOWER(LTRIM(RTRIM(T.single_build_grade_id))),'Easy')
	LEFT JOIN RF_DWH_BUILD_GRADE B2 
	ON LOWER(LTRIM(RTRIM(B2.build_grade_nm))) =  ISNULL(LOWER(LTRIM(RTRIM(T.flow_build_grade_id))),'Easy')
	LEFT JOIN RF_DWH_BUILD_GRADE B3
	ON LOWER(LTRIM(RTRIM(B3.build_grade_nm))) =  ISNULL(LOWER(LTRIM(RTRIM(T.table_build_grade_id))),'Easy')
	

	SELECT line_id,L.line_nm AS line_nm INTO #default_line From RF_DWH_LINE L INNER JOIN @TVP T ON LTRIM(RTRIM(L.line_nm)) = ISNULL(LTRIM(RTRIM(T.default_line)),'Pack Out')

		;WITH CTE AS
	(
	SELECT DISTINCT LTRIM(RTRIM(T.category_id)) AS category_id ,
		getdate() AS inserted_date1 ,
		'superadmin' AS inserted_by1,
		ROW_NUMBER() OVER(PARTITION BY LTRIM(RTRIM(T.category_id)) ORDEr BY LTRIM(RTRIM(T.category_id))) AS RNK
		FROM @TVP T
		WHERE LTRIM(RTRIM(T.category_id)) IS NOT NULL AND NOT EXISTS
		(Select  1 From RF_DWH_CATEGORY C INNER JOIN @TVP T ON LTRIM(RTRIM(C.category_nm)) = LTRIM(RTRIM(T.category_id)) AND C.deleted_date IS NULL )
	)
		INSERT INTO RF_DWH_CATEGORY
		(	
			category_nm,
			inserted_date,
			inserted_by
		)
			SELECT category_id, inserted_date1,inserted_by1
			 FROM CTE
		WHERE RNK=1

		Declare @maxorderno Int =0
		Select @maxorderno = max(order_no) FROM RF_DWH_VARIATION_MASTER 
		

		SELECT LTRIM(RTRIM(C.category_id)) AS category_id,LTRIM(RTRIM(C.category_nm)) AS category_nm INTO #category FROM @TVP T LEFT JOIN  RF_DWH_CATEGORY C ON LTRIM(RTRIM(C.category_nm)) = LTRIM(RTRIM(T.category_id)) AND LTRIM(RTRIM(T.category_id)) IS NOT NULL AND C.deleted_date IS NULL
		
	

		;WITH CTE1 AS
		(
		SELECT DISTINCT LTRIM(RTRIM(T.variation_nm)) AS variation_nm,ROW_NUMBER () OVER (ORDER BY T.variation_nm,order_no ) +@maxorderno AS order_no,getdate() AS inserted_date1, 'superadmin' AS inserted_by1,
		ROW_NUMBER() OVER(PARTITION BY LTRIM(RTRIM(T.variation_nm)) ORDEr BY LTRIM(RTRIM(T.variation_nm))) AS RNK
		FROM  @TVP T LEFT JOIN RF_DWH_VARIATION_MASTER M 
		ON M.variation_nm = LTRIM(RTRIM(T.variation_nm))
		WHERE M.variation_nm IS NULL AND M.deleted_date IS NULL AND LTRIM(RTRIM(T.variation_nm)) IS NOT NULL
		)
	

		INSERT INTO RF_DWH_VARIATION_MASTER 
		(
			variation_nm,order_no,inserted_date,inserted_by

		)
		SELECT variation_nm ,order_no,inserted_date1,inserted_by1 
		FROM CTE1
		WHERE RNK=1
		
		SELECT  M.variation_id AS variation_id,M.variation_nm AS variation_nm INTO #variation FROM @TVP T LEFT JOIN RF_DWH_VARIATION_MASTER M ON LTRIM(RTRIM(M.variation_nm)) = LTRIM(RTRIM(T.variation_nm)) AND LTRIM(RTRIM(T.variation_nm)) IS NOT NULL

			SELECT applecore_product_id, productname,ROW_NUMBER() OVER (PARTITION BY LTRIM(RTRIM(T.productname)) ORDER BY LTRIM(RTRIM(T.productname))) AS rnk1
		INTO #occurance
		FROM
		(SELECT DISTINCT LTRIM(RTRIM(T.applecore_product_id)) AS applecore_product_id,LTRIM(RTRIM(T.productname)) AS productname
		FROM @TVP T) t

		IF EXISTS(SELECT 1 FROM #occurance WHERE rnk1 >1)
		BEGIN
		RAISERROR('Duplicate Item name occurrance found in the data',11,1)
        END
		ELSE
		BEGIN
	;WITH CTE2 AS 
	(SELECT LTRIM(RTRIM(T.applecore_product_id)) AS applecore_product_id,
	LTRIM(RTRIM(T.productname)) AS productname,
	getdate() AS inserted_date1,
	'SuperAdmin' as inserted_by1,
	ROW_NUMBER() OVER( PARTITION BY T.applecore_product_id ORDER BY T.applecore_product_id ) AS RNK
	FROM @TVP T LEFT JOIN RF_DWH_ITEM I
	ON (LTRIM(RTRIM(I.item_no)) = LTRIM(RTRIM(T.applecore_product_id))  OR LTRIM(RTRIM(I.item_nm )) = LTRIM(RTRIM(T.productname))) AND I.deleted_date IS NULL
	WHERE I.item_no IS NULL AND
	 ISNULL(T.productname ,'') <> '' )

	INSERT INTO RF_DWH_ITEM 
		(
			item_no,
			item_nm,
			inserted_date,
			inserted_by
		)
	SELECT applecore_product_id,productname,inserted_date1,inserted_by1
	FROM CTE2
	WHERE RNK =1 
	END

	SELECT DISTINCT LTRIM(RTRIM(T.applecore_product_id)) AS applecore_product_id,
		LTRIM(RTRIM(T.applecore_variation_id)) as applecore_variation_id,
		LTRIM(RTRIM(V.variation_id)) AS variationid ,
		LTRIM(RTRIM(T.pro_seal_twin_crew )) as pro_seal_twin_crew,
		LTRIM(RTRIM(T.pro_seal_twin_t_max )) as pro_seal_twin_t_max, 
		LTRIM(RTRIM(T.pro_seal_single_crew)) as pro_seal_single_crew,
		LTRIM(RTRIM(T.pro_seal_single_t_max)) as pro_seal_single_t_max,
		LTRIM(RTRIM(T.over_wrap_crew )) as over_wrap_crew,
		LTRIM(RTRIM(T.over_wrap_t_max)) as over_wrap_t_max,
		LTRIM(RTRIM(T.table_crew)) as table_crew,
		LTRIM(RTRIM(T.table_t_max)) as table_t_max,
		LTRIM(RTRIM(T.bulk_crew)) as bulk_crew,
		LTRIM(RTRIM(T.bulk_t_max)) as bulk_t_max,
		LTRIM(RTRIM(T.play_book)) as play_book,
		LTRIM(RTRIM(C.category_id)) AS category_id,
		LTRIM(RTRIM(G.twin_build_grade_id)) as twin_build_grade_id ,
		LTRIM(RTRIM(G.single_build_grade_id)) as single_build_grade_id,
		LTRIM(RTRIM(G.flow_build_grade_id)) as flow_build_grade_id,
		LTRIM(RTRIM(G.table_build_grade_id)) as table_build_grade_id,
		LTRIM(RTRIM(D.line_id)) AS default_line
	INTO #tmp
	FROM @TVP T LEFT JOIN #Grade_id G ON LOWER(LTRIM(RTRIM(G.B_build_grade_nm))) = ISNULL(LOWER(LTRIM(RTRIM(T.twin_build_grade_id))) ,'Easy')
AND LOWER(LTRIM(RTRIM(G.B1_build_grade_nm))) = ISNULL(LOWER(LTRIM(RTRIM(T.single_build_grade_id))),'Easy')
AND LOWER(LTRIM(RTRIM(G.B2_build_grade_nm))) = ISNULL(LOWER(LTRIM(RTRIM(T.flow_build_grade_id))),'Easy')
AND LOWER(LTRIM(RTRIM(G.B3_build_grade_nm))) = ISNULL(LOWER(LTRIM(RTRIM(T.table_build_grade_id))),'Easy')
LEFT JOIN #default_line D ON LTRIM(RTRIM(D.line_nm)) = ISNULL(LTRIM(RTRIM(T.default_line)),'Pack Out')
LEFT JOIN #variation V ON LTRIM(RTRIM(V.variation_nm)) = LTRIM(RTRIM(T.variation_nm))
LEFT JOIN #category C ON LTRIM(RTRIM(C.category_nm)) = LTRIM(RTRIM(T.category_id)) 

	select * ,ROW_NUMBER() OVER( PARTITION BY T.applecore_product_id, t.variationid ORDER BY T.applecore_product_id, t.variationid ) AS RNK 
into #tmp1
from #tmp t


IF EXISTS (
SELECT 1 FROM 
 #tmp1 t INNER JOIN XREF_ITEM_PRODUCT_VARIATION v
 ON t.applecore_product_id=v.applecore_product_id
 AND t.variationid = V.variation_id
 AND v.deleted_date IS NULL
 WHERE  RNK =1 
)
BEGIN
RAISERROR('Duplicate product_id, variation_id occurrance found in the data',11,1)
END
ELSE 
BEGIN 
IF EXISTS(
SELECT 1 FROM 
 #tmp1 t INNER JOIN XREF_ITEM_PRODUCT_VARIATION v
 ON t.applecore_variation_id=v.applecore_variation_id
 AND v.deleted_date IS NULL
 WHERE  RNK =1 )
 BEGIN
		RAISERROR('Duplicate applecore_variation_id occurrance found in the data',11,1)
 END
		ELSE
		BEGIN
			MERGE INTO XREF_ITEM_PRODUCT_VARIATION AS trg
			USING (  select * from #tmp1 where RNK =1
			)
			AS src
			--ON trg.applecore_product_id = src.applecore_product_id 
			--AND trg.variation_id = src.variationid 

			ON trg.applecore_product_id = src.applecore_product_id 
			AND trg.variation_id = src.variationid 
			AND  (src.variationid > 0 AND src.applecore_product_id > 0
			AND src.category_id > 0 AND isnull(src.applecore_variation_id,0) <> 0
			AND trg.deleted_date IS NULL
			) 
			OR (trg.deleted_date IS  NULL
			AND trg.applecore_variation_id = src.applecore_variation_id )
			
	  WHEN NOT MATCHED--BY TARGET AND 
	  --(src.variationid > 0 AND src.applecore_product_id > 0
			--AND src.category_id > 0 AND isnull(src.applecore_variation_id,0) <> 0) 
			
			THEN  
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
	    AND deleted_date IS NULL)
	    --AND src.variationid > 0 AND src.applecore_product_id > 0
	    --AND src.category_id > 0 AND isnull(src.applecore_variation_id,0) <> 0)	
	    OR ( trg.pro_seal_twin_crew <> src.pro_seal_twin_crew
	    OR trg.pro_seal_twin_t_max <> src.pro_seal_twin_t_max 
		OR trg.pro_seal_single_crew <> src.pro_seal_single_crew
		OR trg.pro_seal_single_t_max <> src.pro_seal_single_t_max
		OR trg.over_wrap_crew <> src.over_wrap_crew
		OR trg.over_wrap_t_max <> src.over_wrap_t_max
		OR trg.table_crew <> src.table_crew
		OR trg.table_t_max <> src.table_t_max
		OR trg.bulk_crew <> src.bulk_crew
		OR trg.bulk_t_max <> src.bulk_t_max
		OR trg.play_book <> src.play_book
		OR trg.category_id <> src.category_id
		OR trg.twin_build_grade_id <> src.twin_build_grade_id
		OR trg.single_build_grade_id <> src.single_build_grade_id
		OR trg.flow_build_grade_id <> src.flow_build_grade_id
		OR trg.table_build_grade_id <> src.table_build_grade_id
		OR trg.default_line_id <> src.default_line)
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
END
END
END TRY
BEGIN CATCH  
  
  SELECT @error_message = ERROR_MESSAGE();  
  
  IF @@TRANCOUNT > 0  
   ROLLBACK;  
  
 END CATCH  
   
 IF @@TRANCOUNT > 0  
  COMMIT;  
	
END

