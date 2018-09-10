
CREATE Procedure [dbo].[usp_DOR_GET_ROLES_FACILITY]
	@role_id int
as
begin
	set noCount on;
	select distinct b.facility_id from RF_DWH_ROLES a
	inner join RF_DWH_ROLE_FACILITY b on b.role_id = a.role_id
	inner join RF_DWH_FACILITY c on c.facility_id = b.facility_id
	where 1=1 
	and a.role_id = @role_id 
	and c.deleted_date is null
	and a.deleted_date is null


End
