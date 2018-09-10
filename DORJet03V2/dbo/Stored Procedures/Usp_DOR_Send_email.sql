    
CREATE PROCEDURE [dbo].[Usp_DOR_Send_email]           
(  
 @Subject  varchar(500)  
)           
as              
set nocount on              
declare @from varchar(100) = 'noreply@revolutionfoods.com',
 @to varchar(100) = 'swati.agrawal@softwebsolutions.com'+';'+'maksud.belim@softwebsolutions.com',
 @body varchar(500) = @Subject,
 @profile_name varchar(100)  = 'JET02_SQLAdmin',
--'Hi Team,
--The package Package_to_send_email_task has failed in Jet03 server with below error 
--Error Code: '+ CAST(@Error_code as varchar) +'
--Error Desciption: '+ @Error_description  +'
--Error Source: Package_to_send_email_task

--Thank you 
--Revolution foods Team', 
 @smtpserver varchar(100) = 'mail.revolutionfoods.com',             
 @Email_CC varchar(500) = 'maksud.belim@softwebsolutions.com'          
                                      
Begin              
    BEGIN TRY          
                     
    EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile_name               
    ,  @recipients = @to                
    ,  @copy_recipients = @Email_CC          
    ,  @subject = @subject              
    ,  @body =  @body 
	,  @from_address  = @from             
                      
    
  INSERT INTO Error_log_DOR
  SELECT @from, @to,@subject,@body, GETDATE()
            
 END TRY          
BEGIN CATCH          
 
RAISERROR ('Send Email Process Failed' , -- Message text.  
               16, -- Severity.  
               1 -- State.  
               );                 
          
END CATCH                         
              
End              
