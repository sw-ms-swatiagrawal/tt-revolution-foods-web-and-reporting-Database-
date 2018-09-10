CREATE PROCEDURE [dbo].[usp_DOR_DTDETAILS_MANAGE]  
(   
 @xml XML,  
 @error_message VARCHAR(MAX) OUTPUT  
)  
AS  
BEGIN  
   
 SET NOCOUNT, XACT_ABORT ON;  
  
 DECLARE @hDoc AS INT  
      
 BEGIN TRANSACTION  
  
 BEGIN TRY  
  EXEC sp_xml_preparedocument   @hDoc output, @xml;   
  
  MERGE INTO RF_DWH_DTDETAILS AS trg   
  USING (SELECT dt_detail_id,   
     dt_date, shift_id, line_id, item_id, reason_id, occur, [minutes],  
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
     END AS deleted_date,   
     deleted_by,  
     facility_id,
	 item_product_variation_id   
    FROM OPENXML(@hDoc, 'dtdetails/dt', 3)   
    WITH (dt_detail_id INT,   
      dt_date DATETIME,            
      shift_id INT,  
      line_id INT,  
      item_id INT,  
      reason_id INT,  
      occur INT,  
      [minutes] INT,  
      inserted_by VARCHAR(50),   
      modified_by VARCHAR(50),   
      deleted_by VARCHAR(50),  
      facility_id INT,
	  item_product_variation_id INT  
     )) AS src   
   ON trg.dt_detail_id = src.dt_detail_id   
  WHEN NOT MATCHED BY TARGET THEN   
   INSERT (dt_date, shift_id, line_id, item_id, reason_id, occur, [minutes], inserted_date, 
   inserted_by, facility_id,item_product_variation_id)   
   VALUES(src.dt_date, src.shift_id, src.line_id, src.item_id, src.reason_id, src.occur, src.[minutes], src.inserted_date,
    src.inserted_by, src.facility_id, src.item_product_variation_id)   
  WHEN MATCHED THEN   
   UPDATE SET trg.dt_date = src.dt_date,   
      trg.shift_id = src.shift_id,  
      trg.line_id = src.line_id,  
      trg.item_id = src.item_id,  
      trg.reason_id = src.reason_id,  
      trg.occur = src.occur,  
      trg.[minutes] = src.[minutes],  
      trg.modified_date = COALESCE(trg.modified_date, src.modified_date),   
      trg.modified_by = COALESCE(trg.modified_by, src.modified_by),   
      trg.deleted_date = CASE  
            WHEN src.deleted_by IS NULL THEN NULL   
            ELSE src.deleted_date   
           END,   
      trg.deleted_by = src.deleted_by,  
      trg.facility_id = src.facility_id,
	  trg.item_product_variation_id = src.item_product_variation_id;   
  
  EXEC sp_xml_removedocument @hDoc;  
  
 END TRY  
 BEGIN CATCH  
  
  SELECT @error_message = ERROR_MESSAGE();  
  
  IF @@TRANCOUNT > 0  
   ROLLBACK;  
  
 END CATCH  
   
 IF @@TRANCOUNT > 0  
  COMMIT;  
  
END  
