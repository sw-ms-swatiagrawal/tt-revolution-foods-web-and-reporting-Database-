
CREATE PROCEDURE [dbo].[usp_DOR_GET_USER_ROLES_DETAILS]
(
	@user_id INT = NULL,
	@user_nm VARCHAR(50) = NULL	
)
AS
BEGIN
	
	SET NOCOUNT ON;

	OPEN SYMMETRIC KEY rf_user_symm_key
	DECRYPTION BY CERTIFICATE rf_user_certi 

	SELECT	a.[user_id],
			a.user_nm, 
			CONVERT(VARCHAR(1000), DecryptByKey([password])) AS [password],
			a.email_id, 
			a.is_admin,
			a.is_active,
			c.facility_id,
			c.facility_cd,			
			ISNULL(b.insert_fg, 0) AS insert_fg,
			ISNULL(b.update_fg, 0) AS update_fg,
			ISNULL(b.delete_fg, 0) AS delete_fg,
			ISNULL(b.is_default, 0) AS is_default
	FROM dbo.RF_DWH_USERS AS a
	LEFT JOIN RF_DWH_FACILITY AS c 
		ON 1=1
	LEFT JOIN XREF_USER_FACILITY_ROLES AS b	
		ON c.facility_id = b.facility_id	
		AND a.[user_id] = b.[user_id]
	WHERE a.deleted_by IS NULL AND c.deleted_by IS NULL
	AND a.[user_id] = ISNULL(@user_id, a.[user_id])
	AND a.[user_nm] = ISNULL(@user_nm, a.[user_nm]) COLLATE SQL_Latin1_General_CP1_CI_AS;

END;
