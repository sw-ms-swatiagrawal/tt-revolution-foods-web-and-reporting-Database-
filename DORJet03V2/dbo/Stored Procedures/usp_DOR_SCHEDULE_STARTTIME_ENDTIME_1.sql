CREATE PROCEDURE [dbo].[usp_DOR_SCHEDULE_STARTTIME_ENDTIME]  
(  
@schedule_date AS DATETIME,  
@isplaning int  
)  
AS  
--declare @schedule_date as datetime = '2018-04-27'  
declare @ProductionEditCount int  
IF @isplaning = 1  
 BEGIN  
  
  set @ProductionEditCount = (select count(1) from RF_DWH_SCHEDULE where CAST(schedule_date AS Date) = CAST(@schedule_date as Date) AND production_modifiedby is not null )  
  set @ProductionEditCount = isnull(@ProductionEditCount,0)  
  
  ;WITH CTE1 as (  
  select schedule_id , nlinehrsplaning , item_id , line_facility_id , item_break_time , variation_break_time ,StartDatetime , TotalRecords , RowNunmber_Facility_Id    
  , CASE WHEN TotalRecords = 1 THEN StartDatetime ELSE   
    CASE WHEN RowNunmber_Facility_Id = 1 THEN  StartDatetime ELSE NULL END  
    END as StartTime  
  , CASE WHEN TotalRecords = 1 THEN DATEADD(MINUTE,nlinehrsplaning * 60,StartDatetime) ELSE   
     CASE WHEN  RowNunmber_Facility_Id = 1 THEN DATEADD(MINUTE,nlinehrsplaning * 60,StartDatetime)  ELSE NULL END  
    END as EndTime, nLinehrsPlaningtotal,  
  SUM(isnull(breaktime,0)) OVER (PARTITION BY line_facility_id  ORDER BY TotalRecords ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) as breaktimeTotal, breaktime,   
  start_time , end_time , production_start_time , production_end_time  
  ,ROW_NUMBER() over (partition by line_facility_id,item_id order by TotalRecords) as ItemRowNumbner   
  from (  
  SELECT s.schedule_id, isnull(s.nlinehrsplaning,0) as nlinehrsplaning, s.item_id, s.item_product_variation_id,s.nitemseqplaning , s.line_facility_id , lf.facility_id  
  ,f.shift_start_time , f.item_break_time , f.variation_break_time --, s.start_time , s.end_time,  
  ,cast(@schedule_date as datetime) as timefordate  
  
  ,DATETIMEFROMPARTS(DATEPART(YEAR,@schedule_date),DATEPART(MONTH,@schedule_date),DATEPART(DAY,@schedule_date), DATEPART(HOUR,f.shift_start_time),DATEPART(MINUTE,f.shift_start_time),DATEPART(SECOND,f.shift_start_time),00) as StartDatetime  

  , ROW_NUMBER() over (order by lf.facility_id,s.line_facility_id,s.nitemseqplaning,s.item_id , s.seq_no) as TotalRecords  
  , ROW_NUMBER() over (partition by s.line_facility_id order by lf.facility_id,s.line_facility_id,s.nitemseqplaning,s.item_id , s.seq_no) as RowNunmber_Facility_Id  
  ,SUM(isnull(s.nlinehrsplaning,0)) OVER (PARTITION BY  s.line_facility_id   
         ORDER BY lf.facility_id,s.line_facility_id,s.nitemseqplaning,s.item_id , s.seq_no ROWS BETWEEN UNBOUNDED PRECEDING   
            AND 1 PRECEDING)   
  AS nLinehrsPlaningtotal,  
  CASE WHEN LAG(item_id,1,null) over (order by lf.facility_id,s.line_facility_id,s.nitemseqplaning,s.item_id , s.seq_no) = item_id THEN variation_break_time  ELSE item_break_time END as breaktime,  
  start_time , end_time , production_start_time , production_end_time 
  FROM RF_DWH_SCHEDULE s  
  INNER JOIN RF_DWH_XREF_LINE_FACILITY lf on lf.line_facility_id = s.line_facility_id  
  INNER JOIN RF_DWH_FACILITY f on f.facility_id = lf.facility_id  
  WHERE cast(schedule_date as date) = cast(@schedule_date as date)  
  AND qty > 0  
  ) as D )  
  
  --select schedule_id , nlinehrsplaning, item_id , line_facility_id , item_break_time , variation_break_time , TotalRecords , RowNunmber_Facility_Id ,  
  --nLinehrsPlaningtotal,breaktimeTotal,  
  ----CASE WHEN StartTime IS NULL THEN DATEADD(MINUTE, (isnull(nLinehrsPlaningtotal,0) * 60) + isnull(breaktimeTotal,0) +  CASe WHEN ItemRowNumbner <> 1 then isnull(variation_break_time,0) - isnull(item_break_time,0) else 0 END   ,StartDatetime) ELSE StartTime END AS StartTime,  
  ----CASE WHEN EndTime IS NULL THEN DATEADD(MINUTE, ((isnull(nLinehrsPlaningtotal,0) + isnull(nlinehrsplaning,0))  * 60) + isnull(breaktimeTotal,0) +  CASe WHEN ItemRowNumbner <> 1 then isnull(variation_break_time,0) - isnull(item_break_time,0) else 0 END  ,StartDatetime) ELSE EndTime END AS EndTime
  --CASE WHEN StartTime IS NULL THEN DATEADD(MINUTE, (isnull(nLinehrsPlaningtotal,0) * 60) + isnull(breaktimeTotal,0) +  CASe WHEN ItemRowNumbner <> 1 then isnull(variation_break_time,0) - isnull(item_break_time,0) else 0 END ,StartDatetime) ELSE StartTime END AS StartTime,  
  --CASE WHEN EndTime IS NULL THEN DATEADD(MINUTE, ((isnull(nLinehrsPlaningtotal,0) + isnull(nlinehrsplaning,0))  * 60) + isnull(breaktimeTotal,0) +  CASe WHEN ItemRowNumbner <> 1 then isnull(variation_break_time,0) - isnull(item_break_time,0) else 0 END  ,StartDatetime) ELSE EndTime END AS EndTime  
  --from CTE1  
  --order by TotalRecords
  

  UPDATE  CTE1 set start_time = CASE WHEN start_time IS NULL THEN 
						CASE WHEN StartTime IS NULL THEN   
							DATEADD(MINUTE, (isnull(nLinehrsPlaningtotal,0) * 60) + isnull(breaktimeTotal,0) +  CASe WHEN ItemRowNumbner <> 1 then isnull(variation_break_time,0) - isnull(item_break_time,0) else 0 END     ,StartDatetime)   
						ELSE StartTime   END  
		   ELSE start_time END
		   /*-- Comment starts REVFOODDOR-104 06/14/2018
		,production_start_time = CASE WHEN production_start_time IS NOT NULL    
             THEN production_start_time ELSE   
               CASE WHEN StartTime IS NULL THEN   
                  DATEADD(MINUTE, (isnull(nLinehrsPlaningtotal,0) * 60) + isnull(breaktimeTotal,0) +  CASe WHEN ItemRowNumbner <> 1 then isnull(variation_break_time,0) - isnull(item_break_time,0) else 0 END  ,StartDatetime)       
               ELSE StartTime   
               END   
            END  
			*/ -- Comment ends REVFOODDOR-104 06/14/2018
	  --,production_start_time = CASE WHEN @ProductionEditCount <> 0   
   --          THEN production_start_time ELSE   
   --            CASE WHEN StartTime IS NULL THEN   
   --               DATEADD(MINUTE, (isnull(nLinehrsPlaningtotal,0) * 60) + isnull(breaktimeTotal,0) +  CASe WHEN ItemRowNumbner <> 1 then isnull(variation_break_time,0) - isnull(item_break_time,0) else 0 END  ,StartDatetime)       
   --            ELSE StartTime   
   --            END   
   --         END  
      ,end_time = CASE WHEN  start_time IS NULL THEN
						CASE WHEN EndTime IS NULL THEN   
							DATEADD(MINUTE, ((isnull(nLinehrsPlaningtotal,0) + isnull(nlinehrsplaning,0))  * 60) + isnull(breaktimeTotal,0) +  CASe WHEN ItemRowNumbner <> 1 then isnull(variation_break_time,0) - isnull(item_break_time,0) else 0 END   ,StartDatetime)   
						ELSE EndTime  END
				  ELSE end_time END
				  /*-- Comment starts REVFOODDOR-104 06/14/2018
	  ,production_end_time =  CASE WHEN production_end_time IS NOT NULL
              THEN production_end_time ELSE   
                CASE WHEN EndTime IS NULL THEN   
                  DATEADD(MINUTE, ((isnull(nLinehrsPlaningtotal,0) + isnull(nlinehrsplaning,0))  * 60) + isnull(breaktimeTotal,0) +  CASe WHEN ItemRowNumbner <> 1 then isnull(variation_break_time,0) - isnull(item_break_time,0) else 0 END   ,StartDatetime)   
                ELSE EndTime   
                END   
            END  
			*/-- Comment ends REVFOODDOR-104 06/14/2018
      --,production_end_time =  CASE WHEN @ProductionEditCount <> 0   
      --        THEN production_end_time ELSE   
      --          CASE WHEN EndTime IS NULL THEN   
      --            DATEADD(MINUTE, ((isnull(nLinehrsPlaningtotal,0) + isnull(nlinehrsplaning,0))  * 60) + isnull(breaktimeTotal,0) +  CASe WHEN ItemRowNumbner <> 1 then isnull(variation_break_time,0) - isnull(item_break_time,0) else 0 END   ,StartDatetime)   
      --          ELSE EndTime   
      --          END   
      --      END  
  
  --Order by TotalRecords  
 END  
IF @isplaning = 2  
 BEGIN  
  
  
  set @ProductionEditCount = (select count(1) from RF_DWH_SCHEDULE where CAST(schedule_date AS Date) = CAST(@schedule_date as Date) AND production_modifiedby is not null )  
  set @ProductionEditCount = isnull(@ProductionEditCount,0)  
  
  ;WITH CTE1 as (  
  select schedule_id , nlinehrsplaning , item_id , line_facility_id , item_break_time , variation_break_time ,StartDatetime , TotalRecords , RowNunmber_Facility_Id    
  
  , CASE WHEN TotalRecords = 1 THEN case when StartDatetime is null then StartDatetimeDefault ELSE StartDatetime END ELSE   
    CASE WHEN RowNunmber_Facility_Id = 1 THEN  case when StartDatetime is null then StartDatetimeDefault ELSE StartDatetime END  ELSE NULL END  
    END as StartTime  
	
  ,CASE WHEN TotalRecords = 1 THEN DATEADD(MINUTE,nlinehrsplaning * 60, case when StartDatetime is null then StartDatetimeDefault ELSE StartDatetime END ) ELSE   
     CASE WHEN  RowNunmber_Facility_Id = 1 THEN DATEADD(MINUTE,nlinehrsplaning * 60, case when StartDatetime is null then StartDatetimeDefault ELSE StartDatetime END )  ELSE NULL END  
    END as EndTime
	
	--, nLinehrsPlaningtotal  

  ,SUM(isnull(nlinehrsplaning,0)) OVER (PARTITION BY  line_facility_id   
         ORDER BY TotalRecords ROWS BETWEEN UNBOUNDED PRECEDING   
            AND 1 PRECEDING)   
  AS nLinehrsPlaningtotal,  

  SUM(isnull(breaktime,0)) OVER (PARTITION BY line_facility_id  ORDER BY TotalRecords ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) as breaktimeTotal, breaktime,   
  start_time , end_time , production_start_time , production_end_time  
  ,ROW_NUMBER() over (partition by line_facility_id,item_id order by TotalRecords) as ItemRowNumbner
  ,ROW_NUMBER() over (order by TotalRecords) as NewTotalNumber

  from (  

  SELECT s.schedule_id, isnull(s.nlinehrsplaning,0) as nlinehrsplaning, s.item_id, s.item_product_variation_id,s.nitemseqplaning , s.line_facility_id , lf.facility_id  
  ,f.shift_start_time , f.item_break_time , f.variation_break_time --, s.start_time , s.end_time,  
  ,cast(@schedule_date as datetime) as timefordate  
  ,(select MAX(end_time) from RF_DWH_SCHEDULE se where se.line_facility_id = s.line_facility_id AND se.schedule_date = s.schedule_date) as StartDatetime
  , ROW_NUMBER() over (order by lf.facility_id,s.line_facility_id,s.nitemseqplaning,s.item_id , s.seq_no) as TotalRecords  
  , ROW_NUMBER() over (partition by s.line_facility_id order by lf.facility_id,s.line_facility_id,s.nitemseqplaning,s.item_id , s.seq_no) as RowNunmber_Facility_Id  
  ,CASE WHEN LAG(item_id,1,null) over (order by lf.facility_id,s.line_facility_id,s.nitemseqplaning,s.item_id , s.seq_no) = item_id THEN variation_break_time  ELSE item_break_time END as breaktime,  
  start_time , end_time , production_start_time , production_end_time 
  ,DATETIMEFROMPARTS(DATEPART(YEAR,@schedule_date),DATEPART(MONTH,@schedule_date),DATEPART(DAY,@schedule_date), DATEPART(HOUR,f.shift_start_time),DATEPART(MINUTE,f.shift_start_time),DATEPART(SECOND,f.shift_start_time),00) as StartDatetimeDefault  
  FROM RF_DWH_SCHEDULE s  
  INNER JOIN RF_DWH_XREF_LINE_FACILITY lf on lf.line_facility_id = s.line_facility_id  
  INNER JOIN RF_DWH_FACILITY f on f.facility_id = lf.facility_id  
  WHERE cast(schedule_date as date) = cast(@schedule_date as date)  
  AND qty > 0 
  AND (start_time IS NULL AND end_time IS NULL)
  ) as D 
	--WHERE (start_time IS NULL AND end_time IS NULL)
  )  
 -- select *,CASE WHEN StartTime IS NULL THEN   
	--			DATEADD(MINUTE, (select breaktime from CTE1 WHERE NewTotalNumber = 1) + (isnull(nLinehrsPlaningtotal,0) * 60) + isnull(breaktimeTotal,0) +  CASe WHEN ItemRowNumbner <> 1 then isnull(variation_break_time,0) - isnull(item_break_time,0) else 0 END     ,StartDatetime)   
	--		ELSE StartTime   END   as NewStartTime
	--		,CASE WHEN EndTime IS NULL THEN   
	--			DATEADD(MINUTE, (select breaktime from CTE1 WHERE NewTotalNumber = 1) + ((isnull(nLinehrsPlaningtotal,0) + isnull(nlinehrsplaning,0))  * 60) + isnull(breaktimeTotal,0) +  CASe WHEN ItemRowNumbner <> 1 then isnull(variation_break_time,0) - isnull(item_break_time,0) else 0 END   ,StartDatetime)   
	--		ELSE EndTime  END as NewEndTime
	--FROM CTE1

  UPDATE  CTE1 set start_time = CASE WHEN start_time IS NULL THEN 
						CASE WHEN StartTime IS NULL THEN   
							DATEADD(MINUTE, (select breaktime from CTE1 WHERE NewTotalNumber = 1) + (isnull(nLinehrsPlaningtotal,0) * 60) + isnull(breaktimeTotal,0) +  CASe WHEN ItemRowNumbner <> 1 then isnull(variation_break_time,0) - isnull(item_break_time,0) else 0 END     ,StartDatetime)   
						ELSE StartTime   END  
		   ELSE start_time END
		/*   -- Comment starts REVFOODDOR-104 06/14/2018
		,production_start_time = CASE WHEN production_start_time IS NOT NULL    
             THEN production_start_time ELSE   
               CASE WHEN StartTime IS NULL THEN   
                  DATEADD(MINUTE,  (select breaktime from CTE1 WHERE NewTotalNumber = 1) + (isnull(nLinehrsPlaningtotal,0) * 60) + isnull(breaktimeTotal,0) +  CASe WHEN ItemRowNumbner <> 1 then isnull(variation_break_time,0) - isnull(item_break_time,0) else 0 END  ,StartDatetime)       
               ELSE StartTime   
               END   
            END  
		*/	-- Comment ends REVFOODDOR-104 06/14/2018
	  ,end_time = CASE WHEN  end_time IS NULL THEN
						CASE WHEN EndTime IS NULL THEN   
							DATEADD(MINUTE, (select breaktime from CTE1 WHERE NewTotalNumber = 1) + ((isnull(nLinehrsPlaningtotal,0) + isnull(nlinehrsplaning,0))  * 60) + isnull(breaktimeTotal,0) +  CASe WHEN ItemRowNumbner <> 1 then isnull(variation_break_time,0) - isnull(item_break_time,0) else 0 END   ,StartDatetime)   
						ELSE EndTime  END
				  ELSE end_time END
			/*	  -- Comment starts REVFOODDOR-104 06/14/2018
	  ,production_end_time =  CASE WHEN production_end_time IS NOT NULL
              THEN production_end_time ELSE   
                CASE WHEN EndTime IS NULL THEN   
                  DATEADD(MINUTE, (select breaktime from CTE1 WHERE NewTotalNumber = 1) +  ((isnull(nLinehrsPlaningtotal,0) + isnull(nlinehrsplaning,0))  * 60) + isnull(breaktimeTotal,0) +  CASe WHEN ItemRowNumbner <> 1 then isnull(variation_break_time,0) - isnull(item_break_time,0) else 0 END   ,StartDatetime)   
                ELSE EndTime   
                END   
            END  
		*/	-- Comment ends REVFOODDOR-104 06/14/2018
     --Order by TotalRecords
 END

