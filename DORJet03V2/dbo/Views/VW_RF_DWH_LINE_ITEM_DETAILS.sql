CREATE VIEW [dbo].[VW_RF_DWH_LINE_ITEM_DETAILS]
AS

	SELECT d.facility_id AS facility_id,
			c.item_id AS item_id,
			d.line_id AS line_id,
			d.line_facility_id AS line_facility_id,
			c.item_no AS item_no,
			c.item_nm AS item_nm,			   
			CASE WHEN UPPER(e.line_cd) LIKE 'FLOW WRAP%' THEN c.flow_build_grade_id
				WHEN UPPER(e.line_cd) LIKE 'SINGLE PRO%' THEN c.single_build_grade_id
				WHEN UPPER(e.line_cd) LIKE 'TWIN PRO%' THEN c.twin_build_grade_id
				WHEN UPPER(e.line_cd) LIKE 'TABLE' THEN c.table_build_grade_id
			END build_garde_id,				
			CASE WHEN UPPER(e.line_cd) LIKE 'FLOW WRAP%' THEN c.over_wrap_crew
				WHEN UPPER(e.line_cd) LIKE 'SINGLE PRO%' THEN c.pro_seal_single_crew
				WHEN UPPER(e.line_cd) LIKE 'TWIN PRO%' THEN c.pro_seal_twin_crew
				WHEN UPPER(e.line_cd) LIKE 'TABLE' THEN c.table_crew
			END crew,
			CASE WHEN UPPER(e.line_cd) LIKE 'FLOW WRAP%' THEN c.over_wrap_t_max
				WHEN UPPER(e.line_cd) LIKE 'SINGLE PRO%' THEN c.pro_seal_single_t_max
				WHEN UPPER(e.line_cd) LIKE 'TWIN PRO%' THEN c.pro_seal_twin_t_max
				WHEN UPPER(e.line_cd) LIKE 'TABLE' THEN c.table_t_max
			END t_max				
		FROM RF_DWH_ITEM c			
		JOIN RF_DWH_XREF_LINE_FACILITY d
			JOIN RF_DWH_LINE e
				ON e.line_id = d.line_id	
		ON 1 = 1
