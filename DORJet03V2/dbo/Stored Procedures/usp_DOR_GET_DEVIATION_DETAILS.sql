CREATE PROCEDURE [dbo].[usp_DOR_GET_DEVIATION_DETAILS]
@schedule_date datetime,      
@facility_id int,
@search_text varchar(max) = null      
as      
  begin    
  
  if @search_text = ''
	begin
		set @search_text = null
	end


  SELECT rfs.schedule_id , rff.facility_id , rff.facility_nm , rff.facility_cd , rfd.deviation_qty , rfs.qty , rfs.act_qty ,  
   rfvm.variation_id , rfvm.variation_nm,      
  rfi.item_id , rfi.item_no ,rfi.item_nm ,rfpv.applecore_variation_id , rflf.line_id , rflf.line_facility_id , rfl.line_nm ,   
  rfd.accept_reject , rflfpr.line_facility_id as production_line_facility_id , rflpr.line_nm as production_line_nm  
  FROM RF_DWH_DEVIATION rfd      
  INNER JOIN RF_DWH_SCHEDULE rfs on rfs.schedule_id = rfd.schedule_id      
  LEFT JOIN RF_DWH_XREF_LINE_FACILITY rflf on rflf.line_facility_id = rfs.line_facility_id      
  LEFT JOIN RF_DWH_FACILITY rff on rff.facility_id = rflf.facility_id      
  LEFT JOIN XREF_ITEM_PRODUCT_VARIATION rfpv on rfpv.item_product_variation_id = rfs.item_product_variation_id      
  LEFT JOIN RF_DWH_VARIATION_MASTER rfvm on rfvm.variation_id = rfpv.variation_id      
  LEFT JOIN RF_DWH_ITEM rfi on rfi.item_id = rfs.item_id     
  LEFT JOIN RF_DWH_LINE rfl on rfl.line_id = rflf.line_id      
  -- For Production Line Number  
  LEFT JOIN RF_DWH_XREF_LINE_FACILITY rflfpr on rflfpr.line_facility_id = rfs.production_line_facility_id      
  LEFT JOIN RF_DWH_FACILITY rffpr on rffpr.facility_id = rflfpr.facility_id      
  LEFT JOIN RF_DWH_LINE rflpr on rflpr.line_id = rflfpr.line_id      
  
  WHERE cast(rfs.schedule_date as date) = cast(@schedule_date as date)  
  And (@search_text is null 
		OR rfi.item_no like '%' + @search_text + '%'  
		OR rfi.item_nm like  '%' + @search_text + '%' 
		OR rfi.item_no in (Select applecore_product_id From XREF_ITEM_PRODUCT_VARIATION where applecore_variation_id like '%' + @search_text + '%' and deleted_date IS NULL))       
  AND rff.facility_id = @facility_id  
  AND rfs.deleted_date IS NULL   
  AND rff.deleted_date IS NULL   
  AND rfpv.deleted_date IS NULL  
  AND rfvm.deleted_date IS NULL  
  AND rfi.deleted_date IS NULL  
  AND rfl.deleted_date IS NULL  
  --And rfd.accept_reject IS NULL  
     order by rfs.nitemseqproduction,rfs.seq_no_prod        


;WITH CTE (line_id, line_cd, line_nm, line_facility_id)                      
 AS                      
 (                      
  SELECT b.line_id AS line_id,b.line_cd AS line_cd,b.line_nm AS line_nm  
  , a.line_facility_id                    
    FROM RF_DWH_XREF_LINE_FACILITY a      
 JOIN RF_DWH_LINE b ON a.line_id = b.line_id                      
   WHERE 1 = 1 AND a.facility_id = @facility_id AND b.deleted_date IS NULL                      
 )  
 
 --Select * FROM CTE3                    
 SELECT
  b.line_id AS line_id,  c.line_nm AS line_nm                      
 FROM CTE c
 Inner join RF_DWH_XREF_LINE_FACILITY b on b.line_facility_id = c.line_facility_id
 Left join RF_DWH_SCHEDULE a on a.line_facility_id = c.line_facility_id
 --Inner join RF_DWH_ITEM d on d.item_id = a.item_id 
 --Inner join  XREF_ITEM_PRODUCT_VARIATION e on e.item_product_variation_id = a.item_product_variation_id

 GROUP BY b.line_id, c.line_nm
  


 select item_not_id,schedule_dt,item_no,variationID,item_nm,qty from RF_DWH_APPLECORE_ITEM_NOT_FOUND
 where cast(schedule_dt as date) =  cast(@schedule_date as date)
 AND facility_id = @facility_id

End    
