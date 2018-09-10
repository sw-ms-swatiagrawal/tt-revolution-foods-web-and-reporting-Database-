CREATE Procedure [dbo].[usp_DOR_GET_VARIATION_MASTER]
	@variation_id Int = NULL
as
Begin
Select v.variation_id,v.variation_nm, v.order_no
From RF_DWH_VARIATION_MASTER v
where 1 =1 
And (v.variation_nm is not null AND v.variation_nm  <> ' ')
And (@variation_id IS NULL OR v.variation_id = @variation_id)
And v.deleted_date IS NULL
Order by v.order_no, v.variation_nm, v.variation_id
End
