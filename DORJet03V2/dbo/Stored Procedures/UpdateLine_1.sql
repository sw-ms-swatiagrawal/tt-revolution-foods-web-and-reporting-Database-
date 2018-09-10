
CREATE Procedure [dbo].[UpdateLine]
	@machine varchar(50),
	@product_id int,
	@variation_id int
as
Begin



	if(@machine ='Packout')
	Begin
		Set @machine = 'Pack Out'
	End
	else if (@machine = 'FlowWrap1')
	Begin
		Set @machine = 'Flow Wrap #1'
	End
	else if (@machine = 'FlowWrap2')
	Begin
		Set @machine = 'Flow Wrap #2'
	End
	else if (@machine = 'ProSeal1')
	Begin
		Set @machine = 'Single Pro Seal #1'
	End
	else if (@machine = 'ProSeal2')
	Begin
		Set @machine = 'Single Pro Seal #2'
	End
	
	    Update  XREF_ITEM_PRODUCT_VARIATION Set 
		default_line_id = (Select Top 1 line_id From RF_DWH_LINE Where LOWER(line_nm) = LOWER(@machine)),
		modified_by = 'superadmin',
		modified_date = getdate()
		Where applecore_product_id = @product_id
		And applecore_variation_id= @variation_id
	
End


