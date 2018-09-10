CREATE PROCEDURE [dbo].[usp_DOR_GET_USER_AUTHENTICATE]      
(      
 @username varchar(50) = NULL,      
 @password varchar(1000) = NULL,      
 @error_message VARCHAR(MAX) = NULL OUTPUT      
)      
AS      
BEGIN      
       
 SET NOCOUNT ON;      
      
 DECLARE @vUserId AS INT, @vUserNm AS VARCHAR(50), @vEmailId AS VARCHAR(255), @vIsAdmin AS BIT, @vIsActive AS BIT, @vDefaultFacilityId int;      
      
 BEGIN TRY      
      
  OPEN SYMMETRIC KEY rf_user_symm_key      
  DECRYPTION BY CERTIFICATE rf_user_certi       
      
  SET @vUserNm = NULL;      
      
  SELECT @vUserId = a.[user_id],      
    @vUserNm = a.user_nm,       
    @vEmailId =  a.email_id,       
    @vIsAdmin =  a.is_admin,      
    @vIsActive = a.is_active  ,    
 @vDefaultFacilityId =a.default_facility_id    
  FROM dbo.RF_DWH_USERS AS a      
  WHERE user_nm = @username COLLATE SQL_Latin1_General_CP1_CI_AS      
  AND CONVERT(VARCHAR(1000), DecryptByKey([password])) = @password      
  and deleted_by is null;      
      
  IF @vUserNm IS NULL      
   SET @error_message = 'Either Username or Password is incorrect!';      
      
  IF @vUserNm IS NOT NULL AND @vIsActive = 0      
   SET @error_message = 'The user is not in Active state!';      
      
  IF @vUserNm IS NOT NULL AND @vIsActive = 1      
   SELECT @vUserId AS [user_id], @vUserNm AS user_nm, @vEmailId AS email_id, @vIsAdmin AS is_admin, @vDefaultFacilityId as default_facility_id;      
      
 END TRY      
 BEGIN CATCH      
  SET @error_message = ERROR_MESSAGE();      
 END CATCH      
      
END;   
