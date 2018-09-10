CREATE PROCEDURE [dbo].[usp_DOR_SCHEDULE_STATUS_MANAGE]
(
@schedule_id INT,
@status_id INT,
@is_production BIT,
@modified_by VARCHAR(50) = NULL,
@error_message varchar(MAX) output  
)
AS
BEGIN
 SET NOCOUNT ON;   

 BEGIN TRANSACTION;
    
BEGIN TRY  

IF (@is_production = 1)
BEGIN


 UPDATE RF_DWH_SCHEDULE
 SET status_id = @status_id,
 modified_by = @modified_by,
 modified_date = GETDATE(),
 production_modifiedby = @modified_by
 WHERE schedule_id = @schedule_id


   END
 COMMIT TRANSACTION;  
END TRY  
BEGIN CATCH  
   SELECT @error_message = ERROR_MESSAGE();            
   if (XACT_STATE() = -1)    
  begin    
   ROLLBACK TRANSACTION;    
  end    
 if (XACT_STATE() = 1)    
  begin    
   COMMIT TRANSACTION;    
  end    
END CATCH  
  
  End

