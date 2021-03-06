USE [Changepoint]
GO
/****** Object:  StoredProcedure [dbo].[BalanceProjectTeamDemand]    Script Date: 10/10/2019 2:41:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[BalanceProjectTeamDemand]
(
	@RequestId		UNIQUEIDENTIFIER, 
	@Type			VARCHAR(3),
	@TransactionXML XML=NULL
)
	
AS
BEGIN
	
	DEClARE @PM_StartLogTime		DATETIME
	IF NOT @TransactionXML IS NULL SET @PM_StartLogTime=GETUTCDATE()	
	CREATE TABLE #PM_DailyHours 
	(
			TaskAssignmentId			UNIQUEIDENTIFIER,
			WorkingDate					DATETIME,
			PlannedHours				NUMERIC(12,5)
	)
	CREATE TABLE #PM_Assignments_1
	(
		ID					BIGINT	 DEFAULT 0, 
		ProjectId			UNIQUEIDENTIFIER,
		TaskId				UNIQUEIDENTIFIER,
		TaskAssignmentId	UNIQUEIDENTIFIER,
		ResourceId			UNIQUEIDENTIFIER,	
		Changed				BIT DEFAULT 0,
		Deleted				BIT DEFAULT 0,
		NewDailyExists		BIT DEFAULT 0,
		LoadingMethod		TINYINT	DEFAULT 1,
		PlannedStart		DATETIME
		
	)
	
	
	DECLARE @NUllId UNIQUEIDENTIFIER
	DECLARE @iMax INT 
	DECLARE @iTemp INT 
	DECLARE @Diff NUMERIC(12,5)
	DECLARE @TempDiff NUMERIC(12,5)
	DECLARE @PTID INT, @FLOOR  INT
	
	SET @FLOOR=100000
	SET @NullId = '{00000000-0000-0000-0000-000000000000}'
	DECLARE @TaskAssignment TABLE
	(
		TaskAssignmentId		UNIQUEIDENTIFIER,
		ProjectId				UNIQUEIDENTIFIER
		
	)
	DECLARE @FiscalPeriod  TABLE 
	(
		TaskAssignmentId 		UNIQUEIDENTIFIER,
		FiscalPeriodId			UNIQUEIDENTIFIER,
		WorkingDays				INT,
		PlannedHours			NUMERIC(12,5),
		PStart					DATETIME,
		PEND					DATETIME,
		LASTDATE				DATETIME,
		LastDateValue			NUMERIC (12,5) DEFAULT 0,
		RegularDateValue		NUMERIC (12,5) DEFAULT 0
										
	)
	
	DECLARE @DemandTaskAssignment TABLE
	(
		ProjectId				UNIQUEIDENTIFIER,
	 	TaskAssignmentId  		UNIQUEIDENTIFIER,
		ResourceId				UNIQUEIDENTIFIER,	
	 	WorkingDays   			INT, 
	 	PlannedHours   			NUMERIC (12,5), 
	 	PStart    				DATETIME,
	 	PEnd    				DATETIME, 
	 	LastDate   				DATETIME,
	 	LastDateValue   		NUMERIC (12,5) DEFAULT 0,
	 	RegularDateValue  		NUMERIC (12,5) DEFAULT 0
	)
	
	DECLARE @ProjectTeamDiff  TABLE
	(
		ProjectId				UNIQUEIDENTIFIER,
		ResourceId				UNIQUEIDENTIFIER,
		Diff					NUMERIC(12,5)
	)
	DECLARE @ProjectTeamBalance  TABLE
	(
		PTBalanceId				INT IDENTITY,
		PTID					INT DEFAULT 0,
		ProjectTeamId			UNIQUEIDENTIFIER,
		ProjectId				UNIQUEIDENTIFIER,
		ResourceId				UNIQUEIDENTIFIER,
		EstimateHours			NUMERIC(12,5),
		AssignmentHours			NUMERIC(12,5),
		AssignmentDiff			NUMERIC(12,5)
		
	)
	DECLARE @ProcessProjectTeam  TABLE 
	(
		PTID				INT IDENTITY, 
		ProjectId			UNIQUEIDENTIFIER,
		ResourceId			UNIQUEIDENTIFIER,
		StartDate			DATETIME,
		FinishDate			DATETIME,
		Recalc				BIT DEFaULT 0 ,
		Diff				NUMERIC(12,5) DEFAULT 0 
	)
	IF @Type NOT IN ('PRT','DEL', 'PW','PSW')
	BEGIN
		DELETE   ProjectTeamRequest FROM  ProjectTeamRequest ptr  WHERE  ptr.LevRequestId=@RequestId
		AND NOT EXISTS(
		SELECT  tr.ProjectId, tr.ResourceId FROM TaskAssignmentRequest tr  WITH (NOLOCK)  WHERE RequestId=@RequestId
		AND ptr.ProjectId=tr.ProjectId  AND ptr.ResourceId=tr.ResourceId)
		AND NOT EXISTS(
		SELECT ta.ProjectId, ta.ResourceId  FROM TaskAssignmentDeleteRequest tdr  WITH (NOLOCK)  
		INNER JOIN TaskAssignment ta  WITH (NOLOCK)  ON tdr.RequestId =@RequestId AND tdr.TaskAssignmentId=ta.TaskAssignmentId 
		AND ptr.ProjectId=ta.ProjectId  AND ptr.ResourceId=ta.ResourceId) 
		AND NOT EXISTS(
		SELECT  msp.ProjectID, msp.CPResourceId  FROM MSPPrepareAssignment msp  WITH (NOLOCK)  WHERE RequestId=@RequestId
		AND ptr.ProjectId=msp.ProjectId  AND ptr.ResourceId=msp.CPResourceId AND msp.UpdateComplete=1)
		
	END 	
	IF @Type ='DEL'
	BEGIN
	
		UPDATE ProjectTeamRequest  SET ChangedFromOut=1
		FROM ProjectTeamRequest ptr   WITH (NOLOCK)   WHERE ptr.LevRequestId<>@RequestId 
		AND EXISTS(SELECT TOP 1 * FROM ProjectTeamRequest ptr1  WITH (NOLOCK)  WHERE ptr1.LevRequestId=@RequestId AND ptr.ProjectTeamId=ptr1.ProjectTeamId) 
		Update TaskDepRequest SET  Changed=1
		FROM TaskDepRequest tdr  WITH (NOLOCK) 
		INNER JOIN
		(SELECT DISTINCT LevRequestId FROM ProjectTeamRequest ptr1  WITH (NOLOCK)   WHERE ChangedFromOut=1) tt ON tt.LevRequestId=tdr.RequestId
	END  
	IF EXISTS(SELECT TOP 1 * FROM ProjectTeamRequest  WITH (NOLOCK)  WHERE LevRequestId=@RequestId)
	BEGIN
				
			UPDATE ProjectTeamRequest SET DemandHours=EstimatedHours WHERE LevRequestId=@RequestId 
				
			UPDATE ProjectTeamRequest SET PTCount= 2
			FROM ProjectTeamRequest ptr  WITH (NOLOCK)  WHERE ptr.LevRequestId=@RequestId AND ptr.Cancel=0 
			AND EXISTS(SELECT * FROM ProjectTeamRequest ptr1  WITH (NOLOCK)  WHERE ptr1.LevRequestId=@RequestId AND ptr1.Cancel=0 
			AND ptr1.ProjectId=ptr.ProjectId AND ptr1.ResourceId=ptr.ResourceId  AND ptr1.ProjectTeamId<>ptr.ProjectTeamId)
			
			UPDATE ProjectTeamRequest SET DemandHours =(ptr.DemandHours- tt.PlannedHours)
			FROM ProjectTeamRequest ptr  WITH (NOLOCK)  
			INNER JOIN 
			(	SELECT SUM(tc.PlannedHours) PlannedHours, tc.ProjectId, tc.ResourceId  
				FROM TaskAssignmentRequest tc  WITH (NOLOCK)  
				INNER JOIN ProjectTeamRequest ptr  WITH (NOLOCK)  ON tc.RequestId=@RequestId AND ptr.LevRequestId=@RequestId 
				AND ptr.ptCount=1 AND ptr.Cancel=0 AND ptr.ProjectId=tc.ProjectId  AND ptr.ResourceId=tc.ResourceId 
				AND NOT EXISTS(SELECT TOP 1 * FROM TaskAssignmentDeleteRequest tdr  WITH (NOLOCK)  WHERE tdr.RequestId=@RequestId
				AND tdr.TaskAssignmentId=tc.TaskAssignmentId)
				GROUP BY  tc.ProjectId, tc.ResourceId 
			) tt 
			ON ptr.LevRequestId=@RequestId AND ptr.ptCount=1 AND ptr.ProjectId=tt.ProjectId  AND ptr.Cancel=0  AND ptr.ResourceId=tt.ResourceId AND @TYPe NOT IN ('PRT','DEL')
				
			
			UPDATE ProjectTeamRequest SET DemandHours =(ptr.DemandHours- tt.PlannedHours)
			FROM ProjectTeamRequest ptr  WITH (NOLOCK)  
			INNER JOIN 
			(	SELECT SUM(msp.PlannedHours) PlannedHours, msp.ProjectId, msp.CPResourceId  
				FROM MSPPrepareAssignment msp   WITH (NOLOCK)  
				INNER JOIN ProjectTeamRequest ptr  WITH (NOLOCK)  ON msp.RequestId=@RequestId AND ptr.LevRequestId=@RequestId AND msp.UpdateComplete=1
				AND ptr.ptCount=1 AND ptr.Cancel=0  AND ptr.ProjectId=msp.ProjectId  AND ptr.ResourceId=msp.CPResourceId
				AND NOT EXISTS(SELECT TOP 1 * FROM TaskAssignmentDeleteRequest tdr  WITH (NOLOCK)  WHERE tdr.RequestId=@RequestId
				AND tdr.TaskAssignmentId=msp.CPAssignmentId)
			GROUP BY  msp.ProjectId, msp.CPResourceId   
			) tt 
			ON ptr.LevRequestId=@RequestId AND ptr.ptCount=1 AND ptr.ProjectId=tt.ProjectId  AND ptr.Cancel=0  AND ptr.ResourceId=tt.CPResourceId AND  @TYPe='MSP'
			
			
				UPDATE ProjectTeamRequest SET DemandHours =(ptr.DemandHours- tt.PlannedHours)
				FROM ProjectTeamRequest ptr  WITH (NOLOCK)  
				INNER JOIN 
				(	SELECT SUM(pr.PlannedHours) PlannedHours, pc.ProjectId, pc.ResourceId  
					FROM PMEntityChanges pc WITH (NOLOCK)
					INNER JOIN PMEntityRollupChanges pr  WITH (NOLOCK) ON pc.SessionId=@RequestId AND pr.SessionId=@RequestId
					AND pc.EntityId=pr.EntityId  AND pc.EntityType='ta' AND pc.EntityStatus<>2
					INNER JOIN ProjectTeamRequest ptr  WITH (NOLOCK)  ON  ptr.LevRequestId=@RequestId 
					AND ptr.ptCount=1 AND ptr.Cancel=0  AND ptr.ProjectId=pc.ProjectId  AND ptr.ResourceId=pc.ResourceId
					AND NOT EXISTS(SELECT TOP 1 * FROM TaskAssignmentRequest tr  WITH (NOLOCK)  WHERE tr.RequestId=@RequestId
					AND tr.TaskAssignmentId=pc.EntityId)
				GROUP BY  pc.ProjectId, pc.ResourceId    
			) tt 
			ON ptr.LevRequestId=@RequestId AND ptr.ptCount=1 AND ptr.ProjectId=tt.ProjectId  AND ptr.Cancel=0  AND ptr.ResourceId=tt.ResourceId AND  @TYPe IN ('PW','PSW')
			
	
			UPDATE ProjectTeamRequest SET DemandHours =(ptr.DemandHours- tt.PlannedHours)
			FROM ProjectTeamRequest ptr  WITH (NOLOCK)  
			INNER JOIN 
			(	SELECT SUM(ta.PlannedHours) PlannedHours, ta.ProjectId, ta.ResourceId  
				FROM TaskAssignment ta  WITH (NOLOCK)  
				INNER JOIN ProjectTeamRequest ptr  WITH (NOLOCK)  ON  ptr.LevRequestId=@RequestId 
				AND ptr.ptCount=1 AND ptr.Cancel=0  AND ptr.ProjectId=ta.ProjectId  AND ptr.ResourceId=ta.ResourceId AND ta.Deleted=0
				AND NOT EXISTS(SELECT TOP 1 * FROM TaskAssignmentDeleteRequest tdr  WITH (NOLOCK)  WHERE tdr.RequestId=@RequestId
				AND tdr.TaskAssignmentId=ta.TaskAssignmentId)
				AND NOT EXISTS(SELECT TOP 1 * FROM TaskAssignmentRequest tc  WITH (NOLOCK)  WHERE tc.RequestId=@RequestId
				AND tc.TaskAssignmentId=ta.TaskAssignmentId)
				AND NOT EXISTS(SELECT TOP 1 * FROM  MSPPrepareAssignment msp  WITH (NOLOCK)  WHERE msp.RequestId=@RequestId AND msp.UpdateComplete=1
				AND msp.CPAssignmentId=ta.TaskAssignmentId)
				AND NOT EXISTS(SELECT TOP 1 1 FROM  PMEntityRollupChanges pc  WITH (NOLOCK)  WHERE pc.SessionId=@RequestId 
				AND pc.EntityId=ta.TaskAssignmentId)
				
			GROUP BY  ta.ProjectId, ta.ResourceId 
			) tt 
			ON ptr.LevRequestId=@RequestId AND ptr.ptCount=1 AND ptr.ProjectId=tt.ProjectId  AND ptr.ResourceId=tt.ResourceId AND ptr.Cancel=0 
	
			
			IF EXISTS(SELECT TOP 1 * FROM ProjectTeamRequest  WITH (NOLOCK)  WHERE LevRequestId=@RequestId  AND DemandHours < 0  AND Cancel=0  AND @Type<>'DEL')
				GOTO GOTONEXT 
				UPDATE ProjectTeamRequest SET DemandHours=0 WHERE LevRequestId=@RequestId AND DemandHours< 0 
		
		IF EXISTS(SELECT TOP 1 * FROM ProjectTeamRequest  WITH (NOLOCK)  WHERE LevRequestId=@RequestId AND ptCount=2 )
				BEGIN
				
					INSERT INTO @TaskAssignment(TaskAssignmentId, ProjectId)
					SELECT msp.CPAssignmentId, msp.ProjectId FROM MSPPrepareAssignment msp   WITH (NOLOCK) 
					INNER JOIN 
					(SELECT DISTINCT ProjectId, ResourceId FROM  ProjectTeamRequest  WITH (NOLOCK)  WHERE LevRequestId=@RequestId AND ptCount=2 ) tt
					ON @Type='MSP' AND msp.RequestId=@RequestId AND tt.ProjectId=msp.ProjectId AND tt.ResourceId=msp.CPResourceId AND msp.UpdateComplete=1
					AND NOT EXISTS(SELECT TOP 1 * FROM TaskAssignmentDeleteRequest tdr  WITH (NOLOCK)  WHERE tdr.RequestId=@RequestId
					AND tdr.TaskAssignmentId=msp.CPAssignmentId)
				
					INSERT INTO @TaskAssignment(TaskAssignmentId, ProjectId)
					SELECT tc.TaskAssignmentId, tc.ProjectId FROM TaskassignmentRequest tc  WITH (NOLOCK) 
					INNER JOIN 
					(SELECT DISTINCT ProjectId, ResourceId FROM  ProjectTeamRequest  WITH (NOLOCK)  WHERE LevRequestId=@RequestId AND ptCount=2 ) tt
					ON @Type NOT IN ('PRT','DEL') AND  tc.RequestId=@RequestId AND tt.ProjectId=tc.ProjectId AND tt.ResourceId=tc.ResourceId 
					AND NOT EXISTS(SELECT TOP 1 * FROM TaskAssignmentDeleteRequest tdr  WITH (NOLOCK)  WHERE tdr.RequestId=@RequestId
					AND tdr.TaskAssignmentId=tc.TaskAssignmentId)
					AND NOT EXISTS(SELECT TOP 1 1 FROM @TaskAssignment ta1 WHERE ta1.TaskAssignmentId=tc.TaskAssignmentId)
				
					INSERT INTO @TaskAssignment(TaskAssignmentId, ProjectId)
					SELECT pe.EntityId, pe.ProjectId FROM PMEntityChanges pe  WITH (NOLOCK) 
					INNER JOIN 
					(SELECT DISTINCT ProjectId, ResourceId FROM  ProjectTeamRequest  WITH (NOLOCK)  WHERE LevRequestId=@RequestId AND ptCount=2 ) tt
					ON @Type  IN ('PW','PSW') AND  pe.SessionId=@RequestId AND tt.ProjectId=pe.ProjectId AND tt.ResourceId=pe.ResourceId 
					AND pe.EntityType='ta' AND pe.EntityStatus<>2
					AND NOT EXISTS(SELECT TOP 1 1 FROM @TaskAssignment ta1 WHERE ta1.TaskAssignmentId=pe.EntityId)
				
					INSERT INTO @TaskAssignment(TaskAssignmentId,  ProjectId)
					SELECT ta.TaskAssignmentId, ta.ProjectId FROM TaskAssignment ta  WITH (NOLOCK) 
					INNER JOIN 
					(SELECT DISTINCT ProjectId, ResourceId FROM  ProjectTeamRequest WHERE LevRequestId=@RequestId AND ptCount=2 ) tt
					ON tt.ProjectId=ta.ProjectId AND tt.ResourceId=ta.ResourceId AND ta.Deleted=0 
					AND NOT EXISTS(SELECT TOP 1 * FROM TaskAssignmentDeleteRequest tdr  WITH (NOLOCK)  WHERE RequestId=@RequestId
					AND tdr.TaskAssignmentId=ta.TaskAssignmentId)
					AND NOT EXISTS(SELECT TOP 1 1 FROM @TaskAssignment ta1 WHERE ta1.TaskAssignmentId=ta.TaskAssignmentId)
					AND NOT EXISTS(SELECT TOP 1 1 FROM PMEntityChanges pe  WITH (NOLOCK)  WHERE pe.SessionId=@RequestId AND  pe.EntityType='ta' 
					AND pe.EntityId=ta.TaskAssignmentId)
					 
					DELETE @TaskAssignment FROM  @TaskAssignment ta
					WHERE @Type NOT IN ('PRT','DEL')  AND EXISTS(SELECT  TOP 1 1 FROM ProjectTeamBalance ptb  WITH (NOLOCK)  WHERE ptb.RequestId=@RequestId
					AND ptb.SubItemId=ta.TaskAssignmentId)  
					
					IF @TYPE='MSP'
					BEGIN
					
				
						
						INSERT INTO ProjectTeamBalance (RequestId, Type, ProjectId, ResourceId, SubItemId, ResDate,  AssignmentHours )
						SELECT @RequestId,'PRJ', msp.ProjectId, msp.CPResourceId, msp.CPAssignmentId, dar.StartDate, dar.Effort
						FROM  MSPPrepareAssignment msp  WITH (NOLOCK)  
						INNER JOIN  @TaskAssignment ta ON msp.RequestId=@RequestId  AND ta.TaskAssignmentId=msp.CPAssignmentId AND msp.UpdateComplete=1
						INNER JOIN DailyAllocationRequest  dar  WITH (NOLOCK)  ON dar.RequestId=@RequestId AND  dar.TaskId=msp.CPTaskId AND dar.ResourceId=msp.CPResourceId
						INSERT INTO @DemandTaskAssignment (ProjectId,TaskAssignmentId,ResourceId,WorkingDays,PlannedHours,PStart,PEnd,LastDate)	
						SELECT msp.ProjectId,msp.CPAssignmentId,msp.CPResourceId,
						(SELECT	COUNT(wd.WorkingDate)FROM	WorkingDays wd  WITH (NOLOCK) WHERE msp.PlannedStart -1 < wd.WorkingDate AND  msp.PlannedFinish +1 > wd.WorkingDate
						AND NOT EXISTS (SELECT TOP 1  1 FROM  ResourceNonWorkingDays rnwd   WITH (NOLOCK)  WHERE  rnwd.ResourceId =ISNULL(msp.CPResourceId, @NUllId) AND rnwd.NonWorkingDate  = wd.WorkingDate)),
						msp.PlannedHours, msp.PlannedStart, msp.PlannedFinish,
						(SELECT	MAX(wd.WorkingDate)FROM	WorkingDays wd  WITH (NOLOCK)  WHERE	msp.PlannedStart -1 < wd.WorkingDate AND  msp.PlannedFinish +1 > wd.WorkingDate
						AND NOT EXISTS (SELECT TOP 1  1 FROM  ResourceNonWorkingDays rnwd   WITH (NOLOCK)  WHERE  rnwd.ResourceId =ISNULL(msp.CPResourceId, @NUllId) AND rnwd.NonWorkingDate  = wd.WorkingDate))
						FROM @TaskAssignment ta 
						INNER JOIN  MSPPrepareAssignment msp  WITH (NOLOCK)   ON msp.RequestId=@RequestId AND msp.CPAssignmentId=ta.TaskAssignmentId 	AND msp.UpdateComplete=1
						AND NOT EXISTS(SELECT TOP 1 * FROM DailyAllocationRequest  dar  WITH (NOLOCK)  WHERE dar.RequestId=@RequestId 
						AND  dar.TaskId=msp.CPTaskId AND dar.ResourceId=msp.CPResourceId)
						
						DELETE @TaskAssignment FROM  @TaskAssignment ta
						WHERE EXISTS(SELECT  TOP 1 * FROM ProjectTeamBalance ptb  WITH (NOLOCK)  WHERE ptb.RequestId=@RequestId
						AND ptb.SubItemId=ta.TaskAssignmentId) 
						DELETE @TaskAssignment 
						FROM  @TaskAssignment ta
						INNER JOIN @DemandTaskAssignment dta ON ta.TaskAssignmentId=dta.TaskAssignmentId
					END 
					IF @Type IN ('PW','PSW')
					BEGIN
							
							INSERT INTO #PM_Assignments_1 (ProjectId,TaskId,TaskAssignmentId, ResourceId, Changed,Deleted)
							SELECT pc.ProjectId, pc.TaskId, pc.EntityId, 
							pc.ResourceId,CASE WHEN ISNULL(pc.Changed,0)=1 THEN 1 ELSE 0 END ,
							CASE WHEN ISNULL(pc.EntityStatus,0)=2 THEN 1 ELSE 0 END
							FROM PMEntityChanges pc WITH (NOLOCK) 
							INNER JOIN @TaskAssignment tt ON pc.SessionId=@RequestId AND  LOWER(pc.EntityType)='ta' 
							AND tt.ProjectId= pc.ProjectId AND tt.TaskAssignmentId =pc.EntityId 
				
							INSERT INTO #PM_Assignments_1 (ProjectId,TaskId,TaskAssignmentId, ResourceId, Changed,Deleted)
							SELECT ta.ProjectId, ta.TaskId, ta.TaskAssignmentid, ta.ResourceId, 0, 0
							FROM TaskAssignment ta WITH (NOLOCK)
							INNER JOIN @TaskAssignment tt ON ta.Deleted=0 AND ta.ProjectId=tt.ProjectId AND ta.TaskAssignmentId =tt.TaskAssignmentId
							AND NOT EXISTS(SELECT TOP 1 1 FROM #PM_Assignments_1 pa WHERE pa.TaskAssignmentId=ta.TaskAssignmentid)
							EXEC dbo.PM_GetDailyData @RequestId, @TransactionXML
							
							INSERT INTO ProjectTeamBalance (RequestId, Type, ProjectId, ResourceId, SubItemId, ResDate, AssignmentHours )			
							SELECT @RequestId, 'PRJ', pa.ProjectId, pa.ResourceId, pa.TaskAssignmentId, pd.WorkingDate, pd.PlannedHours
							FROM #PM_Assignments_1  pa
							INNER JOIN #PM_DailyHours pd ON pa.TaskAssignmentId=pd.TaskAssignmentId
							
					END 
					
					
					IF EXISTS(SELECT TOP 1 * FROM  @TaskAssignment ) AND @Type NOT IN ('PRT','DEL', 'PW','PSW')
					BEGIN 
						
						UPDATE TaskassignmentFiscalRequest  SET ChangedType=0 
						FROM TaskassignmentFiscalRequest tfr  WITH (NOLOCK)  
						INNER JOIN @TaskAssignment ta ON tfr.RequestId=@RequestId AND ta.TaskAssignmentId=tfr.TaskAssignmentId
						
						UPDATE TaskassignmentFiscalRequest  SET ChangedType=1
						FROM TaskassignmentFiscalRequest tfr  WITH (NOLOCK)  
						INNER JOIN @TaskAssignment ta ON tfr.RequestId=@RequestId AND ta.TaskAssignmentId=tfr.TaskAssignmentId
						AND tfr.Changed=0 AND EXISTS (SELECT TOP 1 1  FROM DemandItems di  WITH (NOLOCK)  WHERE di.EntityId=tfr.TaskAssignmentId )
						UPDATE TaskassignmentFiscalRequest  SET ChangedType=2
						FROM TaskassignmentFiscalRequest tfr  WITH (NOLOCK)  
						INNER JOIN @TaskAssignment ta ON tfr.ChangedType=0 AND tfr.RequestId=@RequestId AND ta.TaskAssignmentId=tfr.TaskAssignmentId
						INNER JOIN FiscalPeriod fp  WITH (NOLOCK)  ON fp.FiscalPeriodId=tfr.FiscalPeriodId AND fp.Deleted=0 
						AND EXISTS
						(SELECT TOP 1 * FROM DailyAllocationRequest dar  WITH (NOLOCK)  
						WHERE dar.RequestId=@RequestId AND dar.TaskId=tfr.TaskId AND  dar.ResourceId=tfr.ResourceId AND 
						dar.StartDate > fp.StartDate -1 AND fp.EndDate +1 > dar.StartDate )    
						INSERT INTO ProjectTeamBalance (RequestId, Type, ProjectId, ResourceId, SubItemId, ResDate,  AssignmentHours )
						SELECT @RequestId,'PRJ', ta.ProjectId, tfr.ResourceId, tfr.TaskAssignmentId, da.DemandDate, da.DemandHours 
						FROM TaskassignmentFiscalRequest tfr  WITH (NOLOCK)  
						INNER JOIN  @TaskAssignment ta ON tfr.RequestId=@RequestId AND tfr.ChangedType=1  AND ta.TaskAssignmentId=tfr.TaskAssignmentId
						CROSS APPLY 
						(
							SELECT MAX(di.Id) ID, di.EntityId  FROM  DemandItems di WITH (NOLOCK) WHERE di.EntityId=ta.TaskAssignmentId
							GROUP BY di.EntityId
						) tt 
						INNER JOIN  DailyDistribution da   WITH (NOLOCK)   ON tt.ID=da.ID
						ORDER BY da.DemandDate
						
						INSERT INTO ProjectTeamBalance (RequestId, Type, ProjectId, ResourceId, SubItemId, ResDate, AssignmentHours )
						SELECT @RequestId,'PRJ', ta.ProjectId, tfr.ResourceId, tfr.TaskAssignmentId, dar.StartDate, dar.Effort
						FROM TaskassignmentFiscalRequest tfr  WITH (NOLOCK)  
						INNER JOIN FiscalPeriod fp  WITH (NOLOCK)  ON fp.FiscalPeriodId=tfr.FiscalPeriodId AND fp.Deleted=0 
						INNER JOIN  @TaskAssignment ta ON tfr.RequestId=@RequestId AND tfr.ChangedType=2  AND ta.TaskAssignmentId=tfr.TaskAssignmentId
						INNER JOIN DailyAllocationRequest dar  WITH (NOLOCK)  ON dar.RequestId=@RequestId AND dar.TaskId=tfr.TaskId AND  dar.ResourceId=tfr.ResourceId AND 
						dar.StartDate > fp.StartDate -1 AND fp.EndDate +1 > dar.StartDate 
					
						IF EXISTS(SELECT TOP 1 * FROM TaskassignmentFiscalRequest  WITH (NOLOCK)  WHERE RequestId=@RequestId AND ChangedType=0)
						BEGIN
						
							INSERT INTO @FiscalPeriod(TaskAssignmentId,FiscalPeriodId,WorkingDays,PlannedHours,PStart,PEND,LASTDATE)
							SELECT tr.TaskAssignmentId, fp.FiscalPeriodId,
							(SELECT COUNT(wd.WorkingDate)FROM   WorkingDays wd  WITH (NOLOCK) 
							WHERE  DATEDIFF(dd,CASE WHEN DATEDIFF(dd,fp.StartDate,tr.NewStart) > 0 THEN tr.NewStart ELSE fp.StartDate END,wd.WorkingDate) >= 0
							AND DATEDIFF(dd,wd.WorkingDate,CASE WHEN DATEDIFF(dd,fp.EndDate,tr.NewEnd) > 0 THEN fp.EndDate ELSE tr.NewEnd END) >= 0
							AND NOT EXISTS (SELECT TOP 1  1 FROM  ResourceNonWorkingDays rnwd   WITH (NOLOCK)  WHERE  rnwd.ResourceId =ISNULL(tr.ResourceId, @NUllId)  AND rnwd.NonWorkingDate = wd.WorkingDate)),
							tfr.FPPlannedHours,
							CASE WHEN DATEDIFF(dd,fp.StartDate,tr.NewStart) > 0 THEN tr.NewStart ELSE fp.StartDate END,
							CASE WHEN DATEDIFF(dd,fp.EndDate,tr.NewEnd) > 0 THEN fp.EndDate ELSE tr.NewEnd END,
							(SELECT Max(wd.WorkingDate) FROM   WorkingDays wd  WITH (NOLOCK)  WHERE  DATEDIFF(dd,CASE WHEN DATEDIFF(dd,fp.StartDate,tr.NewStart) > 0 THEN tr.NewStart ELSE fp.StartDate END,wd.WorkingDate) >= 0
							AND DATEDIFF(dd,wd.WorkingDate,CASE WHEN DATEDIFF(dd,fp.EndDate,tr.NewEnd) > 0 THEN fp.EndDate ELSE tr.NewEnd END) >= 0
							AND NOT EXISTS (SELECT TOP 1  1 FROM  ResourceNonWorkingDays rnwd   WITH (NOLOCK)  WHERE  rnwd.ResourceId =ISNULL(tr.ResourceId, @NUllId) AND rnwd.NonWorkingDate  = wd.WorkingDate))
							FROM   @TaskAssignment ta 
							INNER JOIN TaskassignmentFiscalRequest tfr  WITH (NOLOCK)  ON tfr.RequestId=@RequestId AND tfr.ChangedType=0  AND ta.TaskAssignmentId=tfr.TaskAssignmentId
							INNER JOIN TaskassignmentRequest tr  WITH (NOLOCK)    ON tr.RequestId=@RequestId AND tfr.TaskAssignmentId=tr.TaskAssignmentId 
							INNER JOIN FiscalPeriod fp  WITH (NOLOCK)  ON tfr.FiscalPeriodId = fp.FiscalPeriodId AND fp.Deleted = 0 
							
							
							UPDATE @FiscalPeriod SET RegularDateValue= FLOOR((PlannedHours/WorkingDays)*@FLOOR)/@FLOOR,
							LastDateValue=PlannedHours - ((FLOOR((PlannedHours/WorkingDays)*@FLOOR)/@FLOOR)* WorkingDays)
							WHERE   WorkingDays> 0 AND PlannedHours> 0
			
							INSERT INTO ProjectTeamBalance (RequestId, Type, ProjectId, ResourceId, SubItemId, ResDate, AssignmentHours )
							SELECT  @RequestId,'PRJ', tr.ProjectId, tr.ResourceId, tr.TaskAssignmentId, wd.WorkingDate, CASE WHEN  wd.WorkingDate =fpa.LastDate THEN (fpa.RegularDateValue+fpa.LastDateValue)ELSE fpa.RegularDateValue END
							FROM @FiscalPeriod fpa
							INNER JOIN TaskassignmentRequest tr  WITH (NOLOCK)    ON tr.RequestId=@RequestId AND fpa.TaskAssignmentId=tr.TaskAssignmentId 
							INNER JOIN WorkingDays wd  WITH (NOLOCK)  ON  fpa.PStart -1 < wd.WorkingDate AND  fpa.PEnd +1 > wd.WorkingDate 
							AND NOT EXISTS (SELECT TOP 1 1 FROM  ResourceNonWorkingDays rnwd   WITH (NOLOCK)  WHERE  rnwd.ResourceId =ISNULL(tr.ResourceId, @NUllId) AND rnwd.NonWorkingDate  = wd.WorkingDate)
							WHERE  	fpa.PlannedHours> 0 AND  fpa.WorkingDays> 0 
						END 
					
						IF EXISTS(SELECT TOP 1 * FROM TaskassignmentRequest tc  WITH (NOLOCK)  
						INNER JOIN @TaskAssignment ta ON tc.RequestId=@RequestId  AND ta.TaskAssignmentId=tc.TaskAssignmentId AND 
						NOT EXISTS (SELECT TOP 1 * FROM TaskassignmentFiscalRequest tfr  WITH (NOLOCK)  WHERE  tfr.RequestId=@RequestId AND
						tc.TaskAssignmentId=tfr.TaskAssignmentId))
						BEGIN
									
							INSERT INTO @DemandTaskAssignment (ProjectId,TaskAssignmentId,ResourceId,WorkingDays,PlannedHours,PStart,PEnd,LastDate)	
							SELECT ta.ProjectId,tc.TaskAssignmentId,tc.ResourceId,
							(SELECT	COUNT(wd.WorkingDate)FROM	WorkingDays wd  WITH (NOLOCK) WHERE	tc.NewStart -1 < wd.WorkingDate AND  tc.NewEnd +1 > wd.WorkingDate
							AND NOT EXISTS (SELECT TOP 1  1 FROM  ResourceNonWorkingDays rnwd   WITH (NOLOCK)  WHERE  rnwd.ResourceId =ISNULL(tc.ResourceId,@NUllId) AND rnwd.NonWorkingDate  = wd.WorkingDate)),
							tc.PlannedHours,tc.NewStart,tc.NewEnd,
							(SELECT	MAX(wd.WorkingDate)FROM	WorkingDays wd  WITH (NOLOCK)  WHERE	tc.NewStart -1 < wd.WorkingDate AND  tc.NewEnd +1 > wd.WorkingDate
							AND NOT EXISTS (SELECT TOP 1   1 FROM  ResourceNonWorkingDays rnwd   WITH (NOLOCK)  WHERE  rnwd.ResourceId=ISNULL(tc.ResourceId,@NUllId) AND rnwd.NonWorkingDate  = wd.WorkingDate))
							FROM @TaskAssignment ta 
							INNER JOIN TaskassignmentRequest tc  WITH (NOLOCK)   ON tc.RequestId=@RequestId AND tc.TaskAssignmentId=ta.TaskAssignmentId 
							AND NOT EXISTS(SELECT TOP 1 * FROM TaskassignmentFiscalRequest tfr  WITH (NOLOCK)  WHERE  tfr.RequestId=@RequestId AND 
							tc.TaskAssignmentId=tfr.TaskAssignmentId)
						
						END 
					  
				END 
				IF @Type NOT IN ('PW', 'PSW') AND EXISTS(SELECT TOP 1 * FROM @TaskAssignment ta WHERE NOT EXISTS(SELECT TOP 1 * FROM TaskassignmentRequest tc  WITH (NOLOCK)  
				WHERE tc.RequestId=@RequestId AND tc.TaskAssignmentId =ta.TaskAssignmentId))
					BEGIN
						
						DELETE DemandItemRequest WHERE RequestId=@RequestId
						INSERT INTO DemandItemRequest (RequestId, ItemId)
						SELECT @RequestId, ta.TaskAssignmentId FROM @TaskAssignment ta 
						WHERE 
						NOT EXISTS(SELECT TOP 1 * FROM TaskassignmentRequest tc  WITH (NOLOCK)  WHERE tc.RequestId=@RequestId AND tc.TaskAssignmentId =ta.TaskAssignmentId)
						AND 
						NOT EXISTS(SELECT TOP 1 * FROM  MSPPrepareAssignment msp   WITH (NOLOCK)  WHERE msp.RequestId=@RequestId AND msp.CPAssignmentId =ta.TaskAssignmentId AND msp.UpdateComplete=1)
						
						EXEC dbo.GetTaskAssigEffort @RequestId, NULL, NULL, '', 'PTL', 0x0, 0x0, @TransactionXML
						
									
					END 
				
				IF  @Type NOT IN ('PW', 'PSW') AND EXISTS(SELECT TOP 1 * FROM  @DemandTaskAssignment)
					BEGIN
						UPDATE @DemandTaskAssignment SET RegularDateValue=FLOOR((PlannedHours/WorkingDays)*@FLOOR)/@FLOOR,
						LastDateValue=PlannedHours - ((FLOOR((PlannedHours/WorkingDays)*@FLOOR)/@FLOOR) * WorkingDays)
						WHERE   WorkingDays> 0   AND PlannedHours> 0
								
						INSERT INTO ProjectTeamBalance (RequestId, Type, ProjectId, ResourceId, SubItemId, ResDate, AssignmentHours )
						SELECT  @RequestId,'PRJ', da.ProjectId, da.ResourceId, da.TaskAssignmentId, 
						wd.WorkingDate, CASE WHEN  wd.WorkingDate =da.LastDate THEN (da.RegularDateValue+da.LastDateValue)ELSE da.RegularDateValue END  
						FROM @DemandTaskAssignment da 
						INNER JOIN WorkingDays wd  WITH (NOLOCK)  ON da.PStart -1 < wd.WorkingDate AND  da.PEnd +1 > wd.WorkingDate 
						AND NOT EXISTS (SELECT TOP 1  1  FROM  ResourceNonWorkingDays rnwd   WITH (NOLOCK)  WHERE  rnwd.ResourceId =ISNULL(da.ResourceId,@NUllId) AND rnwd.NonWorkingDate  = wd.WorkingDate)
						WHERE   da.PlannedHours> 0 AND  da.WorkingDays> 0 
					END 
			
				
				
				IF EXISTS(SELECT TOP 1 1 FROM ProjectTeamRequest  ptr  WITH (NOLOCK)  
				 INNER JOIN 
				(SELECT DISTINCT ProjectId, ResourceId FROM ProjectTeamBalance ptb  WITH (NOLOCK)  WHERE RequestId=@RequestId) tt
				ON ptr.LevRequestId=@RequestId  AND ptr.PTcount=2 AND ptr.Cancel=0 AND tt.ProjectId=ptr.ProjectId AND tt.ResourceId=ptr.ResourceId)
					BEGIN	
								IF @Type<>'PRT'
									BEGIN
										DELETE DemandItemRequest WHERE RequestId=@RequestId
										INSERT INTO DemandItemRequest (RequestId, ItemId)
										SELECT @RequestId, ProjectTeamId FROM ProjectTeamRequest ptr  WITH (NOLOCK)  
										INNER JOIN 
										(SELECT DISTINCT ProjectId, ResourceId FROM ProjectTeamBalance ptb  WITH (NOLOCK)  WHERE RequestId=@RequestId) tt
										ON ptr.LevRequestId=@RequestId  AND ptr.PTcount=2 AND tt.ProjectId=ptr.ProjectId AND tt.ResourceId=ptr.ResourceId
										
										EXEC dbo.GetProjecTeamEffort @RequestId, NULL, NULL, '', 'PTL', 0, @TransactionXML
									END
								ELSE
									BEGIN
										DELETE  @DemandTaskAssignment
										INSERT INTO @DemandTaskAssignment (ProjectId,TaskAssignmentId,ResourceId,WorkingDays,PlannedHours,PStart,PEnd,LastDate)	
										SELECT ptr.ProjectId,ptr.ProjectTeamId,ptr.ResourceId,
										(SELECT	COUNT(wd.WorkingDate)FROM	WorkingDays wd  WITH (NOLOCK) 
										WHERE	ptr.StartDate -1 < wd.WorkingDate AND  ptr.FinishDate +1 > wd.WorkingDate
										AND NOT EXISTS (SELECT TOP 1  1 FROM  ResourceNonWorkingDays rnwd   WITH (NOLOCK)  WHERE  rnwd.ResourceId =ISNULL(ptr.ResourceId,@NUllId) AND rnwd.NonWorkingDate  = wd.WorkingDate)),
										ptr.EstimatedHours,ptr.StartDate,ptr.FinishDate,
										(SELECT	MAX(wd.WorkingDate)FROM	WorkingDays wd  WITH (NOLOCK)  WHERE	ptr.StartDate -1 < wd.WorkingDate AND  ptr.FinishDate +1 > wd.WorkingDate
										AND NOT EXISTS (SELECT TOP 1  1 FROM  ResourceNonWorkingDays rnwd   WITH (NOLOCK)  WHERE  rnwd.ResourceId =ISNULL(ptr.ResourceId,@NUllId) AND rnwd.NonWorkingDate  = wd.WorkingDate))
										FROM ProjectTeamRequest ptr  WITH (NOLOCK) WHERE ptr.LevRequestId=@RequestId
										
										UPDATE @DemandTaskAssignment SET RegularDateValue=FLOOR((PlannedHours/WorkingDays)*@FLOOR)/@FLOOR, 
	
										LastDateValue=PlannedHours - ((FLOOR((PlannedHours/WorkingDays)*@FLOOR)/@FLOOR) * WorkingDays)
										WHERE   WorkingDays> 0   AND PlannedHours> 0
								
										INSERT INTO ProjectTeamBalance (RequestId, Type, ProjectId, ResourceId, SubItemId, ResDate, EstimatedHours )
										SELECT  @RequestId,'PRT', da.ProjectId, da.ResourceId, da.TaskAssignmentId, 
										wd.WorkingDate, CASE WHEN  wd.WorkingDate =da.LastDate THEN (da.RegularDateValue+da.LastDateValue)ELSE da.RegularDateValue END  
										FROM @DemandTaskAssignment da 
										INNER JOIN WorkingDays wd  WITH (NOLOCK)  ON da.PStart -1 < wd.WorkingDate AND  da.PEnd +1 > wd.WorkingDate 
										AND NOT EXISTS (SELECT TOP 1  1 FROM  ResourceNonWorkingDays rnwd   WITH (NOLOCK)  WHERE  rnwd.ResourceId =ISNULL(da.ResourceId,@NUllId) AND rnwd.NonWorkingDate  = wd.WorkingDate)
										WHERE   da.PlannedHours> 0 AND  da.WorkingDays> 0  
									END 
								SELECT SUM(AssignmentHours)  TotalAssignmentHours, ProjectId, ResourceId, ResDate INTO #tta
								FROM ProjectTeamBalance  WITH (NOLOCK)   WHERE Type='PRJ' AND RequestId=@RequestId
								GROUP BY ProjectId, ResourceId, ResDate
								SELECT SUM(ptb.EstimatedHours) TotEstimatedHours, ptb.ProjectId, ptb.ResourceId, ptb.ResDate INTO #ttp
								FROM ProjectTeamBalance ptb  WITH (NOLOCK)  
								INNER JOIN ProjectTeamRequest  ptr  WITH (NOLOCK)   ON ptb.ProjectId=ptr.ProjectId AND ptb.ResourceId=ptr.ResourceId AND ptb.SubItemId=ptr.ProjectTeamId
								WHERE ptb.RequestId=@RequestId  AND ptb.TYPE='PRT'  AND ptr.LevRequestId=@RequestId  AND ptr.PTCount=2 AND ptr.Cancel=0
								GROUP BY ptb.ProjectId, ptb.ResourceId, ResDate
								
								
								UPDATE ProjectTeamBalance SET AssignmentHours=FLOOR((( tta.TotalAssignmentHours * ptb.EstimatedHours)/ttp.TotEstimatedHours)*@FLOOR)/@FLOOR
								FROM ProjectTeamBalance ptb  WITH (NOLOCK) 
								INNER JOIN ProjectTeamRequest  ptr  WITH (NOLOCK)  ON ptb.ProjectId=ptr.ProjectId AND ptb.ResourceId=ptr.ResourceId
								INNER JOIN 
								#tta  tta
								ON ptb.ProjectId=tta.ProjectId AND ptb.ResourceId=tta.ResourceId AND ptb.ResDate=tta.ResDate
								INNER JOIN 
								#ttp  ttp
								ON ptb.ProjectId=ttp.ProjectId AND ptb.ResourceId=ttp.ResourceId AND ptb.ResDate=ttp.ResDate
								WHERE  ptr.LevRequestId=@RequestId  AND ptr.PTCount=2 AND ptr.Cancel=0 
								AND ptb.RequestId=@RequestId AND ptb.Type='PRT' AND ptb.EstimatedHours>0 
								INSERT INTO @ProjectTeamDiff(ProjectId, ResourceId, Diff)
								SELECT ptr.ProjectId, ptr.ResourceId, (ta.TotalAssignmentHours - tm.TotalDeductedHours)
								FROM 
								(SELECT DISTINCT ptr.ProjectId, ptr.ResourceId  FROM ProjectTeamRequest  ptr  WITH (NOLOCK)   
								WHERE ptr.LevRequestId=@RequestId  AND ptr.PTCount=2 AND ptr.Cancel=0 ) ptr 
								INNER JOIN 
								(	SELECT  ptb.ProjectId, ptb.ResourceId, SUM(ptb.AssignmentHours) TotalAssignmentHours  
									FROM ProjectTeamBalance  ptb  WITH (NOLOCK)  WHERE ptb.RequestId=@RequestId  AND Type='PRJ'
									GROUP BY ptb.ProjectId, ptb.ResourceId ) ta  
								ON ptr.ProjectId=ta.ProjectId AND ptr.ResourceId=ta.ResourceId 
								INNER JOIN 
								(	SELECT  ptb.ProjectId, ptb.ResourceId, SUM(ptb.AssignmentHours) TotalDeductedHours  
									FROM ProjectTeamBalance  ptb  WITH (NOLOCK)  WHERE ptb.RequestId=@RequestId AND Type='PRT'
									GROUP BY ptb.ProjectId, ptb.ResourceId ) tm 
								ON ptr.ProjectId=tm.ProjectId AND ptr.ResourceId=tm.ResourceId 
								
								
								IF EXISTS(SELECT TOP 1 * FROM @ProjectTeamDiff)
								BEGIN
									INSERT INTO @ProjectTeamBalance (ProjectTeamId,ProjectId,ResourceId,EstimateHours,AssignmentHours)
									SELECT  ptb.SubItemId, ptb.ProjectId, ptb.ResourceId, SUM(ptb.EstimatedHours), SUM(ptb.AssignmentHours)  
									FROM @ProjectTeamDiff ptd
									INNER JOIN ProjectTeamBalance  ptb   WITH (NOLOCK)  ON ptb.RequestId=@RequestId  AND ptb.TYPE='PRT' AND ptb.ProjectId=ptd.ProjectId AND ptd.ResourceId=ptb.ResourceId 
									INNER JOIN ProjectTeamRequest  ptr  WITH (NOLOCK)   ON   ptr.LevRequestId=@RequestId  AND ptr.PTCount=2 AND ptr.Cancel=0 
									AND ptb.ProjectId=ptr.ProjectId AND ptb.ResourceId=ptr.ResourceId AND ptb.SubItemId=ptr.ProjectTeamId 
									GROUP BY ptb.SubItemId, ptb.ProjectId, ptb.ResourceId
									
									ORDER BY (10000 + SUM(ptb.EstimatedHours)- SUM(ptb.AssignmentHours)) DESC
		
									SELECT  @iTemp =1, @iMax = MAX(PTBalanceId) FROM @ProjectTeamBalance
									
									WHILE @iTemp <= @iMax
										BEGIN
											SET @Diff=0 
											SET @TempDiff=0 
											SELECT @TempDiff =(ptb.EstimateHours - ptb.AssignmentHours), @Diff=ptd.Diff  
											FROM @ProjectTeamBalance  ptb 
											INNER JOIN @ProjectTeamDiff ptd ON ptb.PTBalanceId=@iTemp AND ptb.ProjectId=ptd.ProjectId AND 
											ptb.ResourceId=ptd.ResourceId 
											IF @Diff <= 0  GOTO NEXTTEAM 
											IF @TempDiff > @Diff
												SET @TempDiff=@Diff
											
											UPDATE @ProjectTeamBalance SET AssignmentHours=(AssignmentHours + @TempDiff) WHERE PTBalanceId=@iTemp
									
											UPDATE @ProjectTeamDiff SET Diff=(@Diff - @TempDiff) 
											FROM @ProjectTeamBalance  ptb 
											INNER JOIN @ProjectTeamDiff ptd ON ptb.PTBalanceId=@iTemp AND ptb.ProjectId=ptd.ProjectId AND 
											ptb.ResourceId=ptd.ResourceId 
											 
											NEXTTEAM:
											SET @iTemp=@iTemp+1
									
										END  
								END 
								
								IF EXISTS(SELECT  TOP 1 * FROM @ProjectTeamDiff WHERE Diff > 0 )
								BEGIN
										UPDATE @ProjectTeamBalance SET AssignmentHours=ptb.AssignmentHours + ptd.Diff
										FROM @ProjectTeamBalance ptb 
										INNER JOIN @ProjectTeamDiff ptd ON ptb.ProjectId=ptd.ProjectId AND 
										ptb.ResourceId=ptd.ResourceId AND ptd.Diff> 0
										AND NOT EXISTS(SELECT TOP 1 * FROM @ProjectTeamBalance ptb1 WHERE ptb.ProjectId=ptb1.ProjectId AND 
										ptb.ResourceId=ptb1.ResourceId AND ptb.PTBalanceId<ptb1.PTBalanceId)
								END 
								
								IF EXISTS(SELECT TOP 1 * FROM @ProjectTeamBalance WHERE AssignmentHours >EstimateHours)
								BEGIN
										
											INSERT INTO @ProcessProjectTeam (ProjectId, ResourceId, StartDate)
											SELECT DISTINCT  ptr.ProjectId, ptr.ResourceId, ptr.StartDate  
											FROM ProjectTeamRequest ptr  WITH (NOLOCK) 
											INNER JOIN @ProjectTeamBalance ptb  ON ptr.LevRequestId=@RequestId  AND  ptr.ProjectId=ptb.ProjectId
											AND ptr.ResourceId=ptb.ResourceId AND ptr.PTCount=2 AND ptr.Cancel=0
											AND NOT EXISTS
											(SELECT TOP 1 * FROM ProjectTeamRequest  ptr2  WITH (NOLOCK)  
											WHERE ptr2.LevRequestId=@RequestId AND  ptr.ProjectTeamId<>ptr2.ProjectTeamId AND ptr2.PTCount=2 AND ptr2.Cancel=0
											AND ptr.ProjectId=ptr2.ProjectId AND ptr.ResourceId=ptr2.ResourceId
											AND ptr.StartDate BETWEEN DATEADD(dd,1,ptr2.StartDate) AND DATEADD(dd,1,ptr2.FinishDate)) 
											
											INSERT INTO @ProcessProjectTeam (ProjectId, ResourceId, FinishDate)
											SELECT DISTINCT  ptr.ProjectId, ptr.ResourceId, ptr.FinishDate  
											FROM ProjectTeamRequest ptr  WITH (NOLOCK) 
											INNER JOIN @ProjectTeamBalance ptb  ON ptr.LevRequestId=@RequestId  AND  ptr.ProjectId=ptb.ProjectId
											AND ptr.ResourceId=ptb.ResourceId AND ptr.PTCount=2 AND ptr.Cancel=0
											AND NOT EXISTS
											(SELECT TOP 1 * FROM ProjectTeamRequest  ptr2  WITH (NOLOCK)  
											WHERE ptr2.LevRequestId=@RequestId AND ptr.ProjectTeamId<>ptr2.ProjectTeamId AND ptr2.PTCount=2 AND ptr2.Cancel=0
											AND ptr.ProjectId=ptr2.ProjectId AND ptr.ResourceId=ptr2.ResourceId
											AND ptr.FinishDate BETWEEN DATEADD(dd,-1,ptr2.StartDate) AND DATEADD(dd,-1,ptr2.FinishDate)) 
											
											UPDATE @ProcessProjectTeam SET FinishDate=tt.FinishDate FROM @ProcessProjectTeam pt  INNER JOIN 
											(SELECT ProjectId, ResourceId, FinishDate FROM @ProcessProjectTeam pt  WHERE  pt.FinishDate IS NOT NULL) tt
											ON pt.StartDate IS NOT NULL AND pt.ProjectId=tt.ProjectId AND pt.ResourceId=tt.ResourceId AND tt.FinishDate>=pt.StartDate
											AND NOT EXISTS(SELECT TOP 1 * FROM @ProcessProjectTeam pt2  WHERE  pt2.ProjectId=pt.ProjectId AND pt2.ResourceId=pt.ResourceId
											AND tt.FinishDate>=pt2.StartDate AND pt2.StartDate> pt.StartDate) 
											
											DELETE @ProcessProjectTeam  WHERE  StartDate IS NULL 
											UPDATE @ProjectTeamBalance  SET PTID=ppt.PTID
											FROM @ProjectTeamBalance ptb 
											INNER JOIN ProjectTeamRequest  ptr  WITH (NOLOCK)   ON ptr.LevRequestId=@RequestId  AND  ptr.ProjectId=ptb.ProjectId
											AND ptr.ResourceId=ptb.ResourceId AND ptr.PTCount=2 AND ptr.Cancel=0 AND ptr.ProjectTeamId=ptb.ProjectTeamId 
											INNER JOIN @ProcessProjectTeam ppt ON  ptr.FinishDate >=ppt.StartDate AND ptr.StartDate <=ppt.FinishDate
											AND ppt.ProjectId=ptr.ProjectId AND ppt.ResourceId=ptr.ResourceId 
											UPDATE @ProcessProjectTeam SET Recalc=1 FROM @ProcessProjectTeam ppt WHERE EXISTS
											(SELECT TOP 1 * FROM  @ProjectTeamBalance ptb  WHERE  ptb.PTID=ppt.PTID AND ptb.EstimateHours < ptb.AssignmentHours)
											UPDATE @ProcessProjectTeam SET Diff=(a.AssignmentHours - e.EstimateHours)
											FROM @ProcessProjectTeam ppt 
											INNER JOIN
											(SELECT  PTID,  SUM(CASE WHEN EstimateHours > AssignmentHours THEN  AssignmentHours ELSE EstimateHours END)   EstimateHours 
											FROM @ProjectTeamBalance GROUP BY PTID 
											)e ON ppt.PTID =e.PTID 
											INNER JOIN 
											(
												SELECT ppt.PTID,  SUM(ptb.AssignmentHours) AssignmentHours FROM ProjectTeamBalance  ptb   WITH (NOLOCK)  
												INNER JOIN @ProcessProjectTeam ppt ON ptb.RequestId=@RequestId  AND ptb.TYPE='PRJ'
												AND ptb.ProjectId=ppt.ProjectId AND ptb.ResourceId=ppt.ResourceId AND ptb.ResDate BETWEEN ppt.StartDate AND ppt.FinishDate
												GROUP BY ppt.PTID
											)a ON ppt.PTID =a.PTID 
											 
											UPDATE @ProjectTeamBalance SET AssignmentHours =EstimateHours WHERE AssignmentHours > EstimateHours
											SELECT  @iTemp =1
											WHILE @iTemp <= @iMax
											BEGIN
												SET @Diff=0 
												SET @TempDiff=0 
												SELECT @PTID =ppt.PTID, @TempDiff =(ptb.EstimateHours - ptb.AssignmentHours), @Diff=ppt.Diff  
												FROM @ProjectTeamBalance  ptb 
												INNER JOIN @ProcessProjectTeam ppt ON ptb.PTBalanceId=@iTemp  AND ptb.PTID=ppt.PTID
												AND (ptb.EstimateHours - ptb.AssignmentHours)> 0  AND ppt.Diff > 0 
					
												IF ISNULL(@Diff,0) <= 0  GOTO NEXTTEAM1 
												IF @TempDiff > @Diff
													SET @TempDiff=@Diff
												UPDATE @ProjectTeamBalance SET AssignmentHours=(AssignmentHours + @TempDiff) WHERE PTBalanceId=@iTemp
												UPDATE @ProcessProjectTeam SET Diff=(@Diff - @TempDiff)  WHERE PTID=@PTID
												NEXTTEAM1:
											SET @iTemp=@iTemp+1
									
										END  
										IF EXISTS(SELECT  TOP 1 * FROM @ProcessProjectTeam WHERE Diff > 0 )
										BEGIN
												UPDATE @ProjectTeamBalance SET AssignmentHours=ptb.AssignmentHours + ppt.Diff
												FROM @ProjectTeamBalance ptb 
												INNER JOIN @ProcessProjectTeam ppt ON ptb.PTID=ppt.PTID AND ppt.Diff> 0
												AND NOT EXISTS(SELECT TOP 1 * FROM @ProjectTeamBalance ptb1 WHERE ptb.ProjectId=ptb1.ProjectId AND 
												ptb.ResourceId=ptb1.ResourceId AND ptb.PTBalanceId<ptb1.PTBalanceId)
										END 
											
								END 
								UPDATE ProjectTeamRequest SET DemandHours=(ptr.DemandHours - ptb.AssignmentHours)
								FROM ProjectTeamRequest ptr  WITH (NOLOCK)  
								INNER JOIN @ProjectTeamBalance ptb ON  ptr.LevRequestId=@RequestId AND ptb.ProjectTeamId=ptr.ProjectTeamId  AND ptr.Cancel=0  AND ptr.PTCount=2
								
					END 
				GOTONEXT:
				
					
			END 
		END 
	IF NOT @TransactionXML IS NULL 
		EXEC SaveTransactionLog @@PROCID, @PM_StartLogTime, @TransactionXML
END

GO
