USE [Changepoint]
GO
/****** Object:  StoredProcedure [dbo].[PND_WorkingDaysConversionDay]    Script Date: 10/14/2019 2:31:43 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PND_WorkingDaysConversionDay]   @CalculateWorkingDays BIT , @CalculateRate BIT ,  @TransactionXML		XML=NULL
 AS
BEGIN
	DEClARE @PM_StartLogTime		DATETIME
	IF NOT @TransactionXML IS NULL SET @PM_StartLogTime=GETUTCDATE()
	
	
	DECLARE @NULLID  UNIQUEIDENTIFIER, @ConversionToDay  NUMERIC (5,3)
	SET  @NULLID='00000000-0000-0000-0000-000000000000'
	
	UPDATE  #PND_WorkingDaysConversionDay  SET LevelType ='s', LevelTypeId=@NULLID 
	FROM #PND_WorkingDaysConversionDay pnd  WHERE pnd.LevelType='w'
	AND NOT EXISTS(SELECT TOP 1 1 FROM Workgroup wp WITH (NOLOCK) WHERE wp.Deleted=0x0 AND wp.WorkgroupId=pnd.LevelTypeId)
	IF @CalculateWorkingDays=0x1
		BEGIN 
			IF EXISTS(SELECT TOP 1 1 FROM #PND_WorkingDaysConversionDay pnd WHERE pnd.LevelType IN ('r', 's'))
			BEGIN
				SELECT pnd.LevelTypeId, MIN(pnd.StartPeriod) MinStart, MAX(pnd.EndPeriod) MaxFinish INTO #CTE_Resource 
				FROM #PND_WorkingDaysConversionDay pnd
				WHERE pnd.LevelType IN ('r', 's')
				GROUP BY pnd.LevelTypeId
			
				SELECT rd.ResourceId, rd.NonWorkingDate INTO #CTE_ResourceNonWorkingDays
				FROM #CTE_Resource r
				INNER JOIN ResourceNonWorkingDays rd WITH (NOLOCK) ON 
					r.LevelTypeId = rd.ResourceId
					AND rd.NonWorkingDate BETWEEN r.MinStart AND r.MaxFinish
			
				CREATE INDEX IX_CTE_ResourceNonWorkingDays ON #CTE_ResourceNonWorkingDays (ResourceId, NonWorkingDate)
	
				UPDATE #PND_WorkingDaysConversionDay SET 
					WorkingDays = DATEDIFF(dd,pnd.StartPeriod,pnd.EndPeriod) + 1 - tt.CNT
				FROM #PND_WorkingDaysConversionDay pnd
				CROSS APPLY
				(
					SELECT COUNT(1) CNT FROM #CTE_ResourceNonWorkingDays rd WITH (NOLOCK)
					WHERE pnd.StartPeriod - 1 < rd.NonWorkingDate AND pnd.EndPeriod + 1 > rd.NonWorkingDate 
					AND rd.ResourceId = pnd.LevelTypeId
				) tt
				WHERE pnd.LevelType IN ('r', 's')
			END
			IF EXISTS(SELECT TOP 1 1 FROM #PND_WorkingDaysConversionDay pnd WHERE pnd.LevelType = 'w')
			BEGIN
				SELECT wnwd.WorkgroupId, wnwd.NonWorkingDate INTO #CTE_WorkgroupNonWorkingDays
				FROM 
				(
					SELECT DISTINCT pnd.LevelTypeId AS WorkgroupId FROM #PND_WorkingDaysConversionDay pnd WHERE pnd.LevelType = 'w'
				) w
				INNER JOIN WorkgroupNonWorkingDay wnwd WITH (NOLOCK) ON w.WorkgroupId = wnwd.WorkgroupId
				CREATE INDEX IX_CTE_WorkgroupNonWorkingDays ON #CTE_WorkgroupNonWorkingDays (WorkgroupId, NonWorkingDate)
			
				UPDATE #PND_WorkingDaysConversionDay SET
					WorkingDays = DATEDIFF(dd,pnd.StartPeriod,pnd.EndPeriod) + 1 - tt.CNT
				FROM #PND_WorkingDaysConversionDay pnd
				CROSS APPLY
				(
					SELECT COUNT(1) CNT FROM #CTE_WorkgroupNonWorkingDays rd WITH (NOLOCK)   
					WHERE pnd.StartPeriod < rd.NonWorkingDate + 1 AND pnd.EndPeriod > rd.NonWorkingDate - 1
					AND rd.WorkgroupId = pnd.LevelTypeId
				) tt
				WHERE pnd.LevelType = 'w'
			END
		END 
	ELSE 
		BEGIN
			UPDATE #PND_WorkingDaysConversionDay SET WorkingDays = 1
		END
	
	IF @CalculateRate=0x1
		BEGIN
			SELECT  @ConversionToDay=ConversionToDay FROM  ServerSettings WITH (NOLOCK)
			IF ISNULL(@ConversionToDay,0)=0  SET @ConversionToDay= 8.0
			
			
			UPDATE  #PND_WorkingDaysConversionDay SET ConversionToDay=rp.ConversionToDay
			FROM  #PND_WorkingDaysConversionDay pnd 
			INNER JOIN ResourcePayroll  rp WITH (NOLOCK) ON pnd.LevelType='r' AND pnd.LevelTypeId=rp.ResourceId 
			AND ISNULL(rp.ConversionToDay,0)<>0 
			
			
			UPDATE  #PND_WorkingDaysConversionDay SET LevelType='w', LevelTypeId=w.WorkgroupId, ResourceId=pnd.LevelTypeId,
				ConversionToDay = CASE WHEN ISNULL(w.ConversionToDay, 0) <> 0 THEN w.ConversionToDay ELSE 0 END
			FROM #PND_WorkingDaysConversionDay pnd
			CROSS APPLY 
			(
				SELECT TOP 1 WorkgroupId FROM ResourceWorkgroup  wm WITH (NOLOCK) WHERE pnd.ConversionToDay=0 AND pnd.LevelType='r'
				AND wm.ResourceId=pnd.LevelTypeId 
			) wm1
			INNER JOIN Workgroup w ON w.WorkgroupId=wm1.WorkgroupId AND pnd.ConversionToDay=0 AND pnd.LevelType='r'
		
			UPDATE  #PND_WorkingDaysConversionDay SET ConversionToDay=wgp.ConversionToDay
			FROM  #PND_WorkingDaysConversionDay pnd 
			INNER JOIN Workgroup w WITH (NOLOCK) ON pnd.LevelType='w' AND pnd.LevelTypeId=w.WorkgroupId
			AND ISNULL(pnd.ConversionToDay,0)=0 
			CROSS APPLY
			(
				SELECT TOP 1 ConversionToDay FROM  Workgroup wgp WITH (NOLOCK) WHERE   ISNULL(wgp.ConversionToDay,0)<>0
				AND wgp.Deleted=0x0   AND (wgp.WorkgroupId=w.WorkgroupId OR (wgp.IncludeChildren=0x1 AND wgp.OBS =  LEFT(w.OBS,LEN(wgp.OBS))))
				ORDER BY LEN(wgp.OBS)  DESC 
			)wgp
			
			UPDATE  #PND_WorkingDaysConversionDay SET ConversionToDay=@ConversionToDay
			WHERE ISNULL(ConversionToDay,0)=0
			
			UPDATE  #PND_WorkingDaysConversionDay SET LevelType='r', LevelTypeId= pnd.ResourceId
			FROM #PND_WorkingDaysConversionDay pnd WHERE NOT  pnd.ResourceId   IS NULL
		END 
	ELSE
		BEGIN 
			UPDATE #PND_WorkingDaysConversionDay SET ConversionToDay = 1
		END 
		
	IF NOT @TransactionXML IS NULL 
		EXEC SaveTransactionLog @@PROCID, @PM_StartLogTime, @TransactionXML
END 

GO
