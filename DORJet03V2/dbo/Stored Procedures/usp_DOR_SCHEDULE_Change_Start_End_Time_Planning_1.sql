CREATE PROCEDURE [dbo].[usp_DOR_SCHEDULE_Change_Start_End_Time_Planning]   
(
@typeofchanges AS VARCHAR(50),
@TranType AS VARCHAR(50),
@schedule_date AS DATETIME,
@facility_id AS INT,
@From_line_FacilityID AS INT,
@To_line_FacilityID AS INT,
@SeqnoFrom AS INT,
@Seqnoto AS INT,
@FromItemSeqNo AS INT,
@ToItemSeqNo AS INT
) 

AS 

SET NOCOUNT ON;

Declare @ProductionEditCount as INT = (select count(1) from RF_DWH_SCHEDULE where schedule_date = @schedule_date AND production_modifiedby is not null)
Declare @LastTranDateTime as datetime, @PreviousItemId as int,@AddBreakTime as INT


IF @TranType IN ('VariationSeqChange','ItemSeqChange')
	BEGIN
		  
		IF OBJECT_ID('tempdb..#TempstartTimeEndTime') is not null
			BEGIN
				drop table #TempstartTimeEndTime
			END
		IF OBJECT_ID('tempdb..#TempstartTimeEndTimeFullTable') is not null
			BEGIN
				DROP TABLE #TempstartTimeEndTimeFullTable
			END
		IF OBJECT_ID('tempdb..#TempStartTableUpdate') IS NOT NULL
			BEGIN
				DROP TABLE #TempStartTableUpdate
			END
			
		  DECLARE @LessSeqNo as INT = (CASE WHEN @SeqnoFrom <= @Seqnoto THEN @SeqnoFrom ELSE @Seqnoto END)
		  DECLARE @LessItemSeqNo as INT = (CASE WHEN @FromItemSeqNo <= @ToItemSeqNo THEN @FromItemSeqNo ELSE @ToItemSeqNo END)
		  
		  SELECT s.schedule_id, Convert(numeric(18,0),(isnull(s.nlinehrsplaning,0) * 60)) as nlinehrsplaning, s.item_id, s.item_product_variation_id,s.nitemseqplaning , s.line_facility_id , lf.facility_id  
		  ,f.shift_start_time , f.item_break_time , f.variation_break_time --, s.start_time , s.end_time,  
		  ,cast(@schedule_date as datetime) as timefordate  
		  ,DATETIMEFROMPARTS(DATEPART(YEAR,@schedule_date),DATEPART(MONTH,@schedule_date),DATEPART(DAY,@schedule_date), DATEPART(HOUR,f.shift_start_time),DATEPART(MINUTE,f.shift_start_time),DATEPART(SECOND,f.shift_start_time),00) as StartDatetime  
		  , ROW_NUMBER() over (order by lf.facility_id,s.line_facility_id,s.nitemseqplaning,s.item_id , s.seq_no) as TotalRecordsFull  
		  ,CASE WHEN LAG(item_id,1,null) over (order by lf.facility_id,s.line_facility_id,s.nitemseqplaning,s.item_id , s.seq_no) = item_id THEN variation_break_time  ELSE item_break_time END as breaktime,  
		  start_time , end_time , production_start_time , production_end_time ,S.seq_no
		  
		  ,ROW_NUMBER() over (partition by s.line_facility_id,s.item_id order by lf.facility_id,s.line_facility_id,s.nitemseqplaning,s.item_id , s.seq_no) as ItemRowNumbner_Full

		  INTO #TempstartTimeEndTimeFullTable
		  FROM RF_DWH_SCHEDULE s  
		  INNER JOIN RF_DWH_XREF_LINE_FACILITY lf on lf.line_facility_id = s.line_facility_id  
		  INNER JOIN RF_DWH_FACILITY f on f.facility_id = lf.facility_id
		  WHERE cast(schedule_date as date) = cast(@schedule_date as date) AND f.facility_id = @facility_id
		  AND s.line_facility_id IN (@From_line_FacilityID) AND qty IS NOT NULL
		  --AND s.nitemseqplaning = (CASE WHEN  @TranType = 'VariationSeqChange' THEN  @LessItemSeqNo ELSE  s.nitemseqplaning END)
		  
		  

		  Declare @RowNumber_From_Max as INT
		   SET @RowNumber_From_Max = ( 
						select TOP 1 TotalRecordsFull 
						from #TempstartTimeEndTimeFullTable where seq_no >= @LessSeqNo AND nitemseqplaning >= @LessItemSeqNo
						ORDER BY TotalRecordsFull)
		  
		  --select *,@RowNumber_From_Max from #TempstartTimeEndTimeFullTable
		  declare @MinMissMatch as INT 
		  declare @ItemRownumber as INT
		  declare @currItemId as INT
		  
		  IF @typeofchanges = 'StartEndTimeChange'
			BEGIN
				  set @LastTranDateTime = ( SELECT TOP 1 start_time 
							from #TempstartTimeEndTimeFullTable WHERE TotalRecordsFull = @RowNumber_From_Max)	
				   set @PreviousItemId = ( SELECT TOP 1 item_id
						from #TempstartTimeEndTimeFullTable WHERE TotalRecordsFull = (Case WHEN @RowNumber_From_Max = 1 THEN  1 Else @RowNumber_From_Max - 1 END) )
				
				set @ItemRownumber = (select TOP 1 ItemRowNumbner_Full from #TempstartTimeEndTimeFullTable where TotalRecordsFull = @RowNumber_From_Max)
				set @currItemId = (select TOP 1 item_id from #TempstartTimeEndTimeFullTable where TotalRecordsFull = @RowNumber_From_Max)
				
				IF @ItemRownumber > 1 
					BEGIN
						SET @MinMissMatch = (select TOP 1 isnull(item_break_time,0) - isnull(variation_break_time,0) from #TempstartTimeEndTimeFullTable where TotalRecordsFull = @RowNumber_From_Max )
						set @MinMissMatch = isnull(@MinMissMatch,0)
					END
				ELSE
					begin
						set @MinMissMatch = 0 
					end
						--set @MinMissMatch = 0
			END
		ELSE IF @typeofchanges = 'SeqChange'
			BEGIN
				set @ItemRownumber = (select TOP 1 ItemRowNumbner_Full from #TempstartTimeEndTimeFullTable where TotalRecordsFull = @RowNumber_From_Max)
				set @currItemId = (select TOP 1 item_id from #TempstartTimeEndTimeFullTable where TotalRecordsFull = @RowNumber_From_Max)
				
				IF @ItemRownumber > 1 
					BEGIN
						SET @MinMissMatch = (select TOP 1 isnull(item_break_time,0) - isnull(variation_break_time,0) from #TempstartTimeEndTimeFullTable where TotalRecordsFull = @RowNumber_From_Max )
						set @MinMissMatch = isnull(@MinMissMatch,0)
					END
				ELSE
					begin
						set @MinMissMatch = 0 
					end
				set @LastTranDateTime = ( SELECT TOP 1 CASE WHEN @RowNumber_From_Max = 1 THEN  StartDatetime ELSE end_time END  
							from #TempstartTimeEndTimeFullTable WHERE TotalRecordsFull = CASE WHEN @RowNumber_From_Max = 1 THEN 1 ELSE @RowNumber_From_Max - 1 END )	
				  set @PreviousItemId = ( SELECT TOP 1 item_id
						from #TempstartTimeEndTimeFullTable WHERE TotalRecordsFull = CASE WHEN @RowNumber_From_Max = 1 THEN 1 ELSE @RowNumber_From_Max - 1 END )
			END

		   SELECT * 
		   , ROW_NUMBER() OVER (ORDER BY TotalRecordsFull) as TotalRecords
		   , ROW_NUMBER() OVER (PARTITION BY line_facility_id order by TotalRecordsFull) as RowNunmber_Facility_Id  
		   , SUM(isnull((nlinehrsplaning),0)) OVER (PARTITION BY line_facility_id ORDER BY TotalRecordsFull ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING)  as  nLinehrsPlaningtotal
           into #TempstartTimeEndTime from #TempstartTimeEndTimeFullTable
		   WHERE TotalRecordsFull >= @RowNumber_From_Max --- 1 
		   AND nitemseqplaning = (CASE WHEN  @TranType = 'VariationSeqChange' AND @typeofchanges = 'SeqChange' THEN  @LessItemSeqNo ELSE  nitemseqplaning END)
         
		-- if @TranType = 'VariationSeqChange' 
		--	BEGIN
		--		set @AddBreakTime = (select sum(breaktime) from #TempstartTimeEndTimeFullTable where TotalRecordsFull < @RowNumber_From_Max)
		--		set @AddBreakTime = isnull(@AddBreakTime,0)
		--	END
		--ELSe
		--	BEGIN
		--		set @AddBreakTime = 0
		--	END


		  
		 
		--select *,@LastTranDateTime,@PreviousItemId from #TempstartTimeEndTime
		--select   * from #TempstartTimeEndTimeFullTable WHERE TotalRecordsFull = @RowNumber_From_Max - 1
		  IF @From_line_FacilityID = @To_line_FacilityID
			BEGIN
				
			;WITH CTE1 as (  
				SELECT ROW_NUMBER() OVER (order by TotalRecords) as NewRowNumbner
				,schedule_id , nlinehrsplaning , item_id , line_facility_id , item_break_time , variation_break_time ,StartDatetime , TotalRecords , RowNunmber_Facility_Id    
				, CASE WHEN TotalRecords = 1 THEN StartDateTimeNew ELSE   
					--NULL
					CASE WHEN RowNunmber_Facility_Id = 2 THEN StartDateTimeNew ELSE NULL END  
					END as StartTime  

				   , CASE WHEN TotalRecords = 1 THEN DATEADD(MINUTE, Convert(numeric(18,0),nlinehrsplaning) ,StartDateTimeNew) ELSE   
					--NULL
					 CASE WHEN  RowNunmber_Facility_Id = 2 THEN DATEADD(MINUTE, Convert(numeric(18,0),nlinehrsplaning) ,StartDateTimeNew)  ELSE NULL END  
					END as EndTime 

				   --,nLinehrsPlaningtotal - (select TOP 1 nlinehrsplaning From #TempstartTimeEndTime WHERE TotalRecords = 1) as nLinehrsPlaningtotal  
                   --,breaktimeTotal -  (select TOP 1 breaktime From #TempstartTimeEndTime WHERE TotalRecords = 1) as breaktimeTotal  

				   ,nLinehrsPlaningtotal as nLinehrsPlaningtotal  
                   ,breaktimeTotal --+ (select TOP 1 CASE  breaktime from #TempstartTimeEndTimeFullTable WHERE TotalRecordsFull = @RowNumber_From_Max - 1)
				   --,breaktimeTotal as breaktimeTotal  

				   , breaktime, start_time , end_time , production_start_time , production_end_time  
				   ,ROW_NUMBER() over (partition by line_facility_id,item_id order by TotalRecords) as ItemRowNumbner
				   , MAX(StartDateTimeNew) over (order by TotalRecords) as StartDateTimeNew
                   ,seq_no,nitemseqplaning  
				   ,DENSE_RANK() over (order by nitemseqplaning) as NewRank
				from (
						select * ,
						CASE WHEN TotalRecords > 1 THEN NULL ELSE 
							CASE WHEN @typeofchanges = 'StartEndTimeChange' THEN
								DATEADD(MINUTE,0 ,@LastTranDateTime)
							ELSE
								CASE WHEN @PreviousItemId = item_id 
									THEN  DATEADD(MINUTE,CASE WHEN @RowNumber_From_Max = 1 THEN 0 ELSe variation_break_time END ,@LastTranDateTime)
									ELSE  DATEADD(MINUTE,CASE WHEN @RowNumber_From_Max = 1 THEN 0 ELSe item_break_time END,@LastTranDateTime) 
								END 
							END
						
							
						END as StartDateTimeNew

						,SUM(isnull(breaktime,0)) OVER (PARTITION BY line_facility_id  ORDER BY TotalRecords ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) as breaktimeTotal
						from #TempstartTimeEndTime

				 ) as D )

				
				SELECT *
				,CASE WHEN StartTime IS NULL THEN   
				DATEADD(MINUTE, (isnull(nLinehrsPlaningtotal,0)) + isnull(breaktimeTotal,0) +  
					CASE WHEN ItemRowNumbner <> 1 then isnull(variation_break_time,0) - isnull(item_break_time,0) else 0 END + 
					CASE WHEN @TranType = 'VariationSeqChange' THEN @MinMissMatch ELSE 0 END
					  
					,StartDateTimeNew)   
				
				  ELSE StartTime END as NewStartTime, 
				  CASE WHEN EndTime IS NULL THEN   
				DATEADD(MINUTE, ((isnull(nLinehrsPlaningtotal,0) + isnull(nlinehrsplaning,0))) + isnull(breaktimeTotal,0) +  
					CASE WHEN ItemRowNumbner <> 1 then isnull(variation_break_time,0) - isnull(item_break_time,0) else 0 END +
					CASE WHEN @TranType = 'VariationSeqChange' THEN @MinMissMatch ELSE 0 END
					    
				,StartDateTimeNew)   
				
				 ELSE EndTime   
				 END   as NewEndTime
				 INTO #TempStartTableUpdate 
				FROM CTE1
				--where TotalRecords > 1
				Order by TotalRecords
				
				--select * from #TempStartTableUpdate
				--Order by NewRowNumbner

				Update s set s.start_time = temp.NewStartTime , s.end_time = temp.NewEndTime
				 ,production_start_time = CASE WHEN @ProductionEditCount <> 0 THEN s.production_start_time ELSE temp.NewStartTime END
				 ,production_end_time = CASE WHEN @ProductionEditCount <> 0 THEN s.production_end_time ELSE temp.NewEndTime END
				FROM RF_DWH_SCHEDULE s
				INNER JOIN #TempStartTableUpdate temp on temp.schedule_id = s.schedule_id
				----WHERE temp.TotalRecords > 1
				


				IF OBJECT_ID('tempdb..#TempstartTimeEndTime') is not null
					BEGIN
						drop table #TempstartTimeEndTime
					END
				IF OBJECT_ID('tempdb..#TempstartTimeEndTimeFullTable') is not null
					BEGIN
						DROP TABLE #TempstartTimeEndTimeFullTable
					END
				IF OBJECT_ID('tempdb..#TempStartTableUpdate') IS NOT NULL
					BEGIN
						DROP TABLE #TempStartTableUpdate
					END


			END
	END
ELSE IF @TranType IN ('ItemLineChange')
	BEGIN
		 IF OBJECT_ID('tempdb..#TempstartTimeEndTimeLineFrom') is not null
			BEGIN
				drop table #TempstartTimeEndTimeLineFrom
			END
		IF OBJECT_ID('tempdb..#TempstartTimeEndTimeFullTableLineFrom') is not null
			BEGIN
				DROP TABLE #TempstartTimeEndTimeFullTableLineFrom
			END
		IF OBJECT_ID('tempdb..#TempStartTableUpdateLineFrom') IS NOT NULL
			BEGIN
				DROP TABLE #TempStartTableUpdateLineFrom
			END
 
		  ------- >>>>>>>>>>>>>>>>>>>  Update All Records From Line Facility
		  SELECT s.schedule_id, Convert(numeric(18,0),(isnull(s.nlinehrsplaning,0) * 60)) as nlinehrsplaning, s.item_id, s.item_product_variation_id,s.nitemseqplaning , s.line_facility_id , lf.facility_id  
		  ,f.shift_start_time , f.item_break_time , f.variation_break_time 
		  ,cast(@schedule_date as datetime) as timefordate  
		  ,DATETIMEFROMPARTS(DATEPART(YEAR,@schedule_date),DATEPART(MONTH,@schedule_date),DATEPART(DAY,@schedule_date), DATEPART(HOUR,f.shift_start_time),DATEPART(MINUTE,f.shift_start_time),DATEPART(SECOND,f.shift_start_time),00) as StartDatetime  
		  , ROW_NUMBER() over (order by lf.facility_id,s.line_facility_id,s.nitemseqplaning,s.item_id , s.seq_no) as TotalRecordsFull  
		  ,CASE WHEN LAG(item_id,1,null) over (order by lf.facility_id,s.line_facility_id,s.nitemseqplaning,s.item_id , s.seq_no) = item_id THEN variation_break_time  ELSE item_break_time END as breaktime,  
		  start_time , end_time , production_start_time , production_end_time ,S.seq_no
		  INTO #TempstartTimeEndTimeFullTableLineFrom
		  FROM RF_DWH_SCHEDULE s  
		  INNER JOIN RF_DWH_XREF_LINE_FACILITY lf on lf.line_facility_id = s.line_facility_id  
		  INNER JOIN RF_DWH_FACILITY f on f.facility_id = lf.facility_id
		  WHERE cast(schedule_date as date) = cast(@schedule_date as date) AND f.facility_id = @facility_id
		  AND s.line_facility_id IN (@From_line_FacilityID) AND qty IS NOT NULL

		   SET @RowNumber_From_Max = ( select TOP 1 TotalRecordsFull 
				from #TempstartTimeEndTimeFullTableLineFrom where (nitemseqplaning >= @FromItemSeqNo OR seq_no >= @SeqnoFrom) ORDER BY TotalRecordsFull)
           
		   SET @LastTranDateTime = ( SELECT TOP 1 CASE WHEN @RowNumber_From_Max = 1 THEN  StartDatetime ELSE end_time END  
					from #TempstartTimeEndTimeFullTableLineFrom WHERE TotalRecordsFull = CASE WHEN @RowNumber_From_Max = 1 THEN 1 ELSE @RowNumber_From_Max - 1 END )	
		   
		   SET @PreviousItemId = ( SELECT TOP 1 item_id
				from #TempstartTimeEndTimeFullTableLineFrom WHERE TotalRecordsFull = CASE WHEN @RowNumber_From_Max = 1 THEN 1 ELSE @RowNumber_From_Max - 1 END )
		  
		  select * 
		  , ROW_NUMBER() over (order by TotalRecordsFull) as TotalRecords
		  ,ROW_NUMBER() over (partition by line_facility_id order by TotalRecordsFull) as RowNunmber_Facility_Id  
		  ,SUM(isnull((nlinehrsplaning),0)) OVER (PARTITION BY line_facility_id ORDER BY TotalRecordsFull ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING)  as  nLinehrsPlaningtotal
          into #TempstartTimeEndTimeLineFrom from #TempstartTimeEndTimeFullTableLineFrom
		  WHERE TotalRecordsFull >= @RowNumber_From_Max --- 1 


		  ;WITH CTE1 as (  
				select 
				ROW_NUMBER() OVER (order by TotalRecords) as NewRowNumbner
				,schedule_id , nlinehrsplaning , item_id , line_facility_id , item_break_time , variation_break_time ,StartDatetime , TotalRecords , RowNunmber_Facility_Id    
				   , CASE WHEN TotalRecords = 1 THEN StartDateTimeNew ELSE   
					CASE WHEN RowNunmber_Facility_Id = 2 THEN StartDateTimeNew ELSE NULL END  
					END as StartTime  
				   , CASE WHEN TotalRecords = 1 THEN DATEADD(MINUTE, Convert(numeric(18,0),nlinehrsplaning) ,StartDateTimeNew) ELSE   
					 CASE WHEN  RowNunmber_Facility_Id = 2 THEN DATEADD(MINUTE, Convert(numeric(18,0),nlinehrsplaning) ,StartDateTimeNew)  ELSE NULL END  
					END as EndTime 

				   --,nLinehrsPlaningtotal - (select TOP 1 nlinehrsplaning From #TempstartTimeEndTimeLineFrom WHERE TotalRecords = 1) as nLinehrsPlaningtotal  
				   --,breaktimeTotal -  (select TOP 1 breaktime From #TempstartTimeEndTimeLineFrom WHERE TotalRecords = 1) as breaktimeTotal  
				   ,nLinehrsPlaningtotal as nLinehrsPlaningtotal  
				   ,breaktimeTotal as breaktimeTotal  
				   , breaktime, start_time , end_time , production_start_time , production_end_time  
				   ,ROW_NUMBER() over (partition by line_facility_id,item_id order by TotalRecords) as ItemRowNumbner
				   , MAX(StartDateTimeNew) over (order by TotalRecords) as StartDateTimeNew
                   ,seq_no,nitemseqplaning
				   
				from (
						select * ,
						CASE WHEN TotalRecords > 1 THEN NULL ELSE 
							CASE WHEN @PreviousItemId = item_id 
								THEN  DATEADD(MINUTE,CASE WHEN @RowNumber_From_Max = 1 THEN 0 ELSe variation_break_time END ,@LastTranDateTime)
								ELSE  DATEADD(MINUTE,CASE WHEN @RowNumber_From_Max = 1 THEN 0 ELSe item_break_time END,@LastTranDateTime) 
							END 
						END as StartDateTimeNew
						
						--CASE WHEN TotalRecords > 2 THEN NULL ELSE 
						--	CASE WHEN LAG(item_id,1,null) over (order by TotalRecords) = item_id 
						--	THEN  DATEADD(MINUTE,variation_break_time,LAG(end_time,1,null) over (order by TotalRecords))
						--	ELSE  DATEADD(MINUTE,item_break_time,LAG(end_time,1,null) over (order by TotalRecords)) END 
						--END as StartDateTimeNew

						,SUM(isnull(breaktime,0)) OVER (PARTITION BY line_facility_id  ORDER BY TotalRecords ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) as breaktimeTotal
						from #TempstartTimeEndTimeLineFrom
				 ) as D )
				
				SELECT *
				,CASE WHEN StartTime IS NULL THEN   
				DATEADD(MINUTE, (isnull(nLinehrsPlaningtotal,0)) + isnull(breaktimeTotal,0) +  CASe WHEN ItemRowNumbner <> 1 then isnull(variation_break_time,0) - isnull(item_break_time,0) else 0 END     ,StartDateTimeNew)   
				  ELSE StartTime END as NewStartTime, 
				  CASE WHEN EndTime IS NULL THEN   
				DATEADD(MINUTE, ((isnull(nLinehrsPlaningtotal,0) + isnull(nlinehrsplaning,0))) + isnull(breaktimeTotal,0) +  CASe WHEN ItemRowNumbner <> 1 then isnull(variation_break_time,0) - isnull(item_break_time,0) else 0 END   ,StartDateTimeNew)   
				 ELSE EndTime   
				 END   as NewEndTime
				 INTO #TempStartTableUpdateLineFrom
				FROM CTE1
				--where TotalRecords > 1
				Order by TotalRecords
				
				--select * from #TempStartTableUpdateLineFrom
				--Order by NewRowNumbner

				Update s set s.start_time = temp.NewStartTime , s.end_time = temp.NewEndTime
				 ,production_start_time = CASE WHEN @ProductionEditCount <> 0 THEN s.production_start_time ELSE temp.NewStartTime END
				 ,production_end_time = CASE WHEN @ProductionEditCount <> 0 THEN s.production_end_time ELSE temp.NewEndTime END
				FROM RF_DWH_SCHEDULE s
				INNER JOIN #TempStartTableUpdateLineFrom temp on temp.schedule_id = s.schedule_id
				----WHERE temp.TotalRecords > 1
		
				IF OBJECT_ID('tempdb..#TempstartTimeEndTimeLineFrom') is not null
					BEGIN
						drop table #TempstartTimeEndTimeLineFrom
					END
				IF OBJECT_ID('tempdb..#TempstartTimeEndTimeFullTableLineFrom') is not null
					BEGIN
						DROP TABLE #TempstartTimeEndTimeFullTableLineFrom
					END
				IF OBJECT_ID('tempdb..#TempStartTableUpdateLineFrom') IS NOT NULL
					BEGIN
						DROP TABLE #TempStartTableUpdateLineFrom
					END
			
			-------->>>>>>>>>>>>>>> From Sectuiion Update <<<<<<<<<<<<<<< ------------------------
		   IF OBJECT_ID('tempdb..#TempstartTimeEndTimeLineTo') is not null
				BEGIN
					drop table #TempstartTimeEndTimeLineTo
				END
			IF OBJECT_ID('tempdb..#TempstartTimeEndTimeFullTableLineTo') is not null
				BEGIN
					DROP TABLE #TempstartTimeEndTimeFullTableLineTo
				END
			IF OBJECT_ID('tempdb..#TempStartTableUpdateLineTo') IS NOT NULL
				BEGIN
					DROP TABLE #TempStartTableUpdateLineTo
				END


		  SELECT s.schedule_id, Convert(numeric(18,0),(isnull(s.nlinehrsplaning,0) * 60)) as nlinehrsplaning, s.item_id, s.item_product_variation_id,s.nitemseqplaning , s.line_facility_id , lf.facility_id  
		  ,f.shift_start_time , f.item_break_time , f.variation_break_time 
		  ,cast(@schedule_date as datetime) as timefordate  
		  ,DATETIMEFROMPARTS(DATEPART(YEAR,@schedule_date),DATEPART(MONTH,@schedule_date),DATEPART(DAY,@schedule_date), DATEPART(HOUR,f.shift_start_time),DATEPART(MINUTE,f.shift_start_time),DATEPART(SECOND,f.shift_start_time),00) as StartDatetime  
		  , ROW_NUMBER() over (order by lf.facility_id,s.line_facility_id,s.nitemseqplaning,s.item_id , s.seq_no) as TotalRecordsFull  
		  ,CASE WHEN LAG(item_id,1,null) over (order by lf.facility_id,s.line_facility_id,s.nitemseqplaning,s.item_id , s.seq_no) = item_id THEN variation_break_time  ELSE item_break_time END as breaktime,  
		  start_time , end_time , production_start_time , production_end_time ,S.seq_no
		  INTO #TempstartTimeEndTimeFullTableLineTo
		  FROM RF_DWH_SCHEDULE s  
		  INNER JOIN RF_DWH_XREF_LINE_FACILITY lf on lf.line_facility_id = s.line_facility_id  
		  INNER JOIN RF_DWH_FACILITY f on f.facility_id = lf.facility_id
		  WHERE cast(schedule_date as date) = cast(@schedule_date as date) AND f.facility_id = @facility_id
		  AND s.line_facility_id IN (@To_line_FacilityID) AND qty IS NOT NULL

		  
		  
			 SET @RowNumber_From_Max = ( 
				   select TOP 1 TotalRecordsFull 
					from #TempstartTimeEndTimeFullTableLineTo where (nitemseqplaning >= @ToItemSeqNo OR seq_no >= @Seqnoto)
					ORDER BY TotalRecordsFull
			  )
			 set @LastTranDateTime = (
					SELECT TOP 1 CASE WHEN @RowNumber_From_Max = 1 THEN  StartDatetime ELSE end_time END  
					from #TempstartTimeEndTimeFullTableLineTo WHERE TotalRecordsFull = CASE WHEN @RowNumber_From_Max = 1 THEN 1 ELSE @RowNumber_From_Max - 1 END 
				)	
			set @PreviousItemId = (
				SELECT TOP 1 item_id
				from #TempstartTimeEndTimeFullTableLineTo WHERE TotalRecordsFull = CASE WHEN @RowNumber_From_Max = 1 THEN 1 ELSE @RowNumber_From_Max - 1 END 
			)
		  
			
		  
		  select * 
		  , ROW_NUMBER() over (order by TotalRecordsFull) as TotalRecords
		  ,ROW_NUMBER() over (partition by line_facility_id order by TotalRecordsFull) as RowNunmber_Facility_Id  
		  ,SUM(isnull((nlinehrsplaning),0)) OVER (PARTITION BY line_facility_id ORDER BY TotalRecordsFull ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING)  as  nLinehrsPlaningtotal
          into #TempstartTimeEndTimeLineTo from #TempstartTimeEndTimeFullTableLineTo
		  WHERE TotalRecordsFull >= @RowNumber_From_Max --- 1 
		  ORDER BY TotalRecordsFull

		  
		  
		  
		  ;WITH CTE1 as (  
				select 
				ROW_NUMBER() OVER (order by TotalRecords) as NewRowNumbner
				,schedule_id , nlinehrsplaning , item_id , line_facility_id , item_break_time , variation_break_time ,StartDatetime , TotalRecords , RowNunmber_Facility_Id    
				   
				   , CASE WHEN TotalRecords = 1 THEN StartDateTimeNew ELSE   
					CASE WHEN RowNunmber_Facility_Id = 2 THEN StartDateTimeNew ELSE NULL END  
					END as StartTime  
				  
				   , CASE WHEN TotalRecords = 1 THEN DATEADD(MINUTE, Convert(numeric(18,0),nlinehrsplaning) ,StartDateTimeNew) ELSE   
					 CASE WHEN  RowNunmber_Facility_Id = 2 THEN DATEADD(MINUTE, Convert(numeric(18,0),nlinehrsplaning) ,StartDateTimeNew)  ELSE NULL END  
					END as EndTime 

				   --,nLinehrsPlaningtotal - (select TOP 1 nlinehrsplaning From #TempstartTimeEndTimeLineTo WHERE TotalRecords = 1) as nLinehrsPlaningtotal  
				  --,breaktimeTotal -  (select TOP 1 breaktime From #TempstartTimeEndTimeLineTo WHERE TotalRecords = 1) as breaktimeTotal  
				   ,nLinehrsPlaningtotal as nLinehrsPlaningtotal  
                   ,breaktimeTotal as breaktimeTotal  
				   , breaktime, start_time , end_time , production_start_time , production_end_time  
				   ,ROW_NUMBER() over (partition by line_facility_id,item_id order by TotalRecords) as ItemRowNumbner
				   , MAX(StartDateTimeNew) over (order by TotalRecords) as StartDateTimeNew
                   ,seq_no,nitemseqplaning
				   
				from (
						select * ,
						CASE WHEN TotalRecords > 1 THEN NULL ELSE 
							CASE WHEN @PreviousItemId = item_id 
								THEN  DATEADD(MINUTE,CASE WHEN @RowNumber_From_Max = 1 THEN 0 ELSe variation_break_time END ,@LastTranDateTime)
								ELSE  DATEADD(MINUTE,CASE WHEN @RowNumber_From_Max = 1 THEN 0 ELSe item_break_time END,@LastTranDateTime) 
							END 
						END as StartDateTimeNew

						--CASE WHEN TotalRecords > 2 THEN NULL ELSE 
						--	CASE WHEN LAG(item_id,1,null) over (order by TotalRecords) = item_id 
						--	THEN  DATEADD(MINUTE,variation_break_time,LAG(end_time,1,null) over (order by TotalRecords))
						--	ELSE  DATEADD(MINUTE,item_break_time,LAG(end_time,1,null) over (order by TotalRecords)) END 
						--END as StartDateTimeNew

						,SUM(isnull(breaktime,0)) OVER (PARTITION BY line_facility_id  ORDER BY TotalRecords ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) as breaktimeTotal
						from #TempstartTimeEndTimeLineTo
				 ) as D )
				
				SELECT *
				,CASE WHEN StartTime IS NULL THEN   
				DATEADD(MINUTE, (isnull(nLinehrsPlaningtotal,0)) + isnull(breaktimeTotal,0) +  CASe WHEN ItemRowNumbner <> 1 then isnull(variation_break_time,0) - isnull(item_break_time,0) else 0 END     ,StartDateTimeNew)   
				  ELSE StartTime END as NewStartTime, 
				  CASE WHEN EndTime IS NULL THEN   
				DATEADD(MINUTE, ((isnull(nLinehrsPlaningtotal,0) + isnull(nlinehrsplaning,0))) + isnull(breaktimeTotal,0) +  CASe WHEN ItemRowNumbner <> 1 then isnull(variation_break_time,0) - isnull(item_break_time,0) else 0 END   ,StartDateTimeNew)   
				 ELSE EndTime   
				 END   as NewEndTime
				 INTO #TempStartTableUpdateLineTo
				FROM CTE1
				--where TotalRecords > 1
				Order by TotalRecords
				
				--select * from #TempStartTableUpdateLineTo
				--Order by NewRowNumbner

				Update s set s.start_time = temp.NewStartTime , s.end_time = temp.NewEndTime
				 ,production_start_time = CASE WHEN @ProductionEditCount <> 0 THEN s.production_start_time ELSE temp.NewStartTime END
				 ,production_end_time = CASE WHEN @ProductionEditCount <> 0 THEN s.production_end_time ELSE temp.NewEndTime END
				FROM RF_DWH_SCHEDULE s
				INNER JOIN #TempStartTableUpdateLineTo temp on temp.schedule_id = s.schedule_id
				----WHERE temp.TotalRecords > 1

			IF OBJECT_ID('tempdb..#TempstartTimeEndTimeLineTo') is not null
				BEGIN
					drop table #TempstartTimeEndTimeLineTo
				END
			IF OBJECT_ID('tempdb..#TempstartTimeEndTimeFullTableLineTo') is not null
				BEGIN
					DROP TABLE #TempstartTimeEndTimeFullTableLineTo
				END
			IF OBJECT_ID('tempdb..#TempStartTableUpdateLineTo') IS NOT NULL
				BEGIN
					DROP TABLE #TempStartTableUpdateLineTo
				END
			--------------------------------------------------------------------------------------------------------------------------------------------------------


	END

