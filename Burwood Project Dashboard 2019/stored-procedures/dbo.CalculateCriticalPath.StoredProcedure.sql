USE [Changepoint]
GO
/****** Object:  StoredProcedure [dbo].[CalculateCriticalPath]    Script Date: 10/10/2019 2:41:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE  [dbo].[CalculateCriticalPath]  @ProjectId UNIQUEIDENTIFIER, @SessionId UNIQUEIDENTIFIER='00000000-0000-0000-0000-000000000000', @Validate	BIT=0, @TransactionXML XML=NULL
    AS 
BEGIN
	
	SET NOCOUNT ON
	DEClARE @PM_StartLogTime		DATETIME,  @Virtual BIT =0x0, 	@Count INT, @TempCount INT, @MaXDepLevel INT=500,  @DaysCount INT =10
	IF NOT @TransactionXML IS NULL	SET @PM_StartLogTime=GETUTCDATE()
	IF ISNULL(@SessionId,'00000000-0000-0000-0000-000000000000') <>'00000000-0000-0000-0000-000000000000'
	SET  @Virtual=0x1
	
	IF OBJECT_ID('tempdb..#CriticalPathProjects') IS NULL
		BEGIN
			CREATE TABLE #CriticalPathProjects
			(
				CriticalPathProjectId		UNIQUEIDENTIFIER, 
				PlannedStart				DATETIME	NULL, 
				MaxPlannedFinish			DATETIME NULL,
				AssociatedWorkgroup			UNIQUEIDENTIFIER,
				MAXWorkDate					DATETIME, 
				MAXID						INT DEFAULT 0
			)
			INSERT INTO #CriticalPathProjects (CriticalPathProjectId)
			SELECT ProjectId FROM Project with(nolock)
			WHERE ProjectId=@ProjectId AND CriticalPath=0x1 
			AND Deleted=0x0
		END
		IF OBJECT_ID('tempdb..#SubProjects') IS NOT NULL DROP TABLE #SubProjects
		CREATE TABLE #SubProjects 
		(
			CriticalPathProjectId	UNIQUEIDENTIFIER, 
			ProjectId				UNIQUEIDENTIFIER
		
		)
		IF OBJECT_ID('tempdb..#CR_WorkingDays') IS NOT NULL DROP TABLE #CR_WorkingDays
		CREATE TABLE #CR_WorkingDays
		(
			ID						INT IDENTITY,
			WorkgroupId				UNIQUEIDENTIFIER, 
			WorkingDate				DATETIME	
		)
		IF OBJECT_ID('tempdb..#CriticalPathTasks') IS NOT NULL DROP TABLE #CriticalPathTasks
		CREATE TABLE #CriticalPathTasks
		(
			CriticalPathProjectId	UNIQUEIDENTIFIER, 
			ProjectId				UNIQUEIDENTIFIER,
			TaskIdentity			INT, 
			TaskId					UNIQUEIDENTIFIER,
			Successor				BIT	DEFAULT 0x0,
			Processed				BIT	DEFAULT 0x0, 
			Completed				BIT	DEFAULT 0x0, 
			WBS						VARCHAR(510)
		)
		IF OBJECT_ID('tempdb..#CR_Tasks') IS  NOT NULL DROP TABLE #CR_Tasks
		CREATE TABLE #CR_Tasks
		(
			CriticalPathProjectId	UNIQUEIDENTIFIER, 
			ProjectId				UNIQUEIDENTIFIER,
			AssociatedWorkgroup		UNIQUEIDENTIFIER,
			TaskIdentity			INT, 
			TaskId					UNIQUEIDENTIFIER,
			PlannedFinish			DATETIME,
			PlannedStart			DATETIME,
			MAXID					INT,
			Slack					INT DEFAULT 0, 
			Critical				BIT DEFAULT 0x0, 
			Completed				BIT	DEFAULT 0x0, 
			WorkingDays				INT DEFAULT -1, 
			WBS						VARCHAR(510)
		)
		IF OBJECT_ID('tempdb..#InterProjects') IS NOT NULL DROP Table #InterProjects
		CREATE TABLE #InterProjects
		(
			CriticalPathProjectId	UNIQUEIDENTIFIER,
			ProjectId				UNIQUEIDENTIFIER,
			PlannedStart			DATETIME	NULL, 
			PlannedFinish			DATETIME	NULL,
			AssociatedWorkgroup		UNIQUEIDENTIFIER
		)
		IF OBJECT_ID('tempdb..#Dependency') IS not NULL DROP TABLE #Dependency 
		CREATE  TABLE #Dependency 
		(
			DP_Identity				INT IDENTITY,
			CriticalPathProjectId	UNIQUEIDENTIFIER,
			WorkgroupId				UNIQUEIDENTIFIER,
			Successor				INT,
			DepStart				DATETIME,
			DepEND					DATETIME,
			SuccessorWorkingDays	INT,
			Predecessor				INT, 
			PredecessorDate			DATETIME,
			DependencyType			CHAR(2),
			LagTime					INT,
			Critical				BIT DEFAULT 0
		) 
	
		IF @Virtual=0x0
			BEGIN 
				UPDATE #CriticalPathProjects
				SET PlannedStart = p.PlannedStart, MaxPlannedFinish=tt.MAXPlannedFinish, 
				AssociatedWorkgroup=e.AssociatedWorkgroup
				FROM #CriticalPathProjects i
				INNER JOIN Project p WITH (NOLOCK) ON i.CriticalPathProjectId=p.ProjectId
				INNER JOIN Engagement  e WITH (NOLOCK) ON p.EngagementId=e.EngagementId
				CROSS APPLY 
				(
					SELECT MAX(PlannedFinish) MAXPlannedFinish FROM Tasks  t WITH (NOLOCK)  WHERE t.ProjectId=p.ProjectId 
					AND t.Deleted=0x0 AND t.Completed=0
				) tt
			END 
		ELSE
			BEGIN 
				UPDATE #CriticalPathProjects
				SET PlannedStart = p.PlannedStart,
				AssociatedWorkgroup=e.AssociatedWorkgroup
				FROM #CriticalPathProjects i
				INNER JOIN Project p WITH (NOLOCK) ON i.CriticalPathProjectId=p.ProjectId
				INNER JOIN Engagement  e WITH (NOLOCK) ON p.EngagementId=e.EngagementId
			 END 
		INSERT INTO #SubProjects (CriticalPathProjectId, ProjectId)
		SELECT CriticalPathProjectId, CriticalPathProjectId
		FROM  #CriticalPathProjects
	
		
		INSERT INTO #SubProjects (CriticalPathProjectId, ProjectId)
		SELECT i.CriticalPathProjectId, s.SubProjectId
		FROM SubProject s with(nolock)
		INNER JOIN Project p with(nolock) ON s.SubProjectId=p.ProjectId AND p.IncludePlannedInRollup=0x1 and p.Deleted=0x0
		INNER JOIN #CriticalPathProjects i ON i.CriticalPathProjectId=s.ProjectId
		
		SET @Count=0
		SELECT @TempCount=COUNT(*) FROM #SubProjects
		WHILE @TempCount >@Count  
		BEGIN
			SET @Count=@TempCount
			
			INSERT INTO #SubProjects (CriticalPathProjectId, ProjectId)
			SELECT DISTINCT	tp.CriticalPathProjectId, s.SubProjectId
			FROM SubProject s with(nolock)
			INNER JOIN Project p with(nolock) ON s.SubProjectId=p.ProjectId and p.IncludePlannedInRollup=0x1 and p.Deleted=0x0
			INNER JOIN #SubProjects tp ON tp.ProjectId=s.ProjectId
			WHERE NOT EXISTS (SELECT TOP 1 1 FROM #SubProjects WHERE s.SubProjectId=ProjectId AND tp.CriticalPathProjectId=CriticalPathProjectId) 
		
			SELECT @TempCount=COUNT(*) FROM #SubProjects
		END
		
		
		INSERT INTO  #InterProjects(CriticalPathProjectId, ProjectId,PlannedStart, PlannedFinish,AssociatedWorkgroup)
		SELECT  DISTINCT  tt2.CriticalPathProjectId,  p.ProjectId, p.PlannedStart, p.PlannedFinish, e.AssociatedWorkgroup   
		FROM TaskRelation tr  WITH (NOLOCK) 
		INNER JOIN 
		(
			SELECT  DISTINCT  cr.CriticalPathProjectId,tr.GroupId 
			FROM  #CriticalPathProjects cr 
			INNER JOIN Tasks t WITH (NOLOCK) ON cr.CriticalPathProjectId=t.ProjectId AND t.Deleted=0x0  
			INNER JOIN TaskRelation tr  WITH (NOLOCK)  ON tr.TaskIdentity=t.TaskIdentity
		)tt2 ON tr.GroupId=tt2.GroupId
		INNER JOIN Tasks t WITH (NOLOCK) ON t.Deleted=0x0 AND  t.TaskIdentity=tr.TaskIdentity
		INNER JOIN  Project p WITH (NOLOCK) ON p.ProjectId=t.ProjectId
		INNER  JOIN Engagement e WITH  (NOLOCK)  ON e.EngagementId= p.EngagementId
		WHERE NOT EXISTS(SELECT TOP 1 1 FROM  #CriticalPathProjects cr WHERE cr.CriticalPathProjectId= t.ProjectId)
		IF @Virtual=0x1
		BEGIN 
			
		
			INSERT INTO #CR_Tasks(CriticalPathProjectId, ProjectId,AssociatedWorkgroup,TaskIdentity,TaskId,PlannedStart, PlannedFinish,Completed, WorkingDays, WBS)
			
			SELECT  @ProjectId, @ProjectId ,crp.AssociatedWorkgroup, ISNULL(t.TaskIdentity,pc.TaskIdentity),
			pc.EntityId, pe.PlannedStart,pe.PlannedFinish, 
			CASE WHEN comp.TaskId IS NULL THEN 0x0 ELSE 0x1 END, -1 WorkingDays, CASE WHEN ISNULL(pc.WBS,'') <>'' THEN  pc.WBS ELSE  ISNULL(t.WBS,'') END 
			FROM #CriticalPathProjects crp 
			INNER JOIN  PMEntityChanges  pc  WITH (NOLOCK) ON  pc.SessionId=@SessionId AND pc.ProjectId=crp.CriticalPathProjectId AND pc.EntityType='t' AND pc.EntityStatus  IN (0,1)
			INNER JOIN  PMEntityRollupChanges pe  WITH (NOlOCK)  ON   pe.SessionId=@SessionId AND pe.EntityId=pc.EntityId 
			LEFT JOIN Tasks t WITH (NOLOCK)  ON pc.EntityId=t.TaskId AND t.Deleted=0x0
			LEFT JOIN  PMTasksCompletedFlag  comp WITH (NOLOCK)  ON  comp.SessionId=@SessionId AND comp.TaskId=pc.EntityId
			UNION 
			
			SELECT @ProjectId, @ProjectId ,crp.AssociatedWorkgroup, t.TaskIdentity, t.TaskId, t.PlannedStart, t.PlannedFinish, t.Completed,  t.WorkingDays, t.WBS
			FROM #CriticalPathProjects crp
			INNER JOIN Tasks t  WITH (NOLOCK)  ON  t.ProjectId=crp.CriticalPathProjectId 
			AND t.Deleted=0x0 AND NOT EXISTS
			(SELECT TOP 1 1 FROM PMEntityRollupChanges pe WITH  (NOLOCK)  WHERE pe.SessionId=@SessionId AND t.TaskId=pe.EntityId)
			UNION 
			
			SELECT @ProjectId, tt.ProjectId, e.AssociatedWorkgroup, tt.TaskIdentity, tt.TaskId, tt.PlannedStart, tt.PlannedFinish, t.Completed, -1 WorkingDays, t.WBS
			FROM 
			(
				SELECT pt.ProjectId,pt.TaskIdentity, pt.Taskid, MIN(pt.NewPlannedStart) PlannedStart , MAX(pt.NewPlannedFinish) PlannedFinish
				FROM ProcessProjectTaskDependencies  pt  WITH (NOLOCK) WHERE pt.RequestId=@SessionId  AND pt.ProjectId<>@ProjectId
				GROUP BY  pt.ProjectId, pt.TaskIdentity, pt.Taskid
			) tt 
			INNER JOIN Tasks t ON t.TaskId=tt.Taskid
			INNER JOIN Project p WITH (NOLOCK) ON p.ProjectId=tt.ProjectId 
			INNER JOIN Engagement e WITH (NOLOCK) ON e.EngagementId=p.EngagementId
			UNION 
			
			SELECT @ProjectId, t.ProjectId, e.AssociatedWorkgroup, t.TaskIdentity, t.TaskId, t.PlannedStart, t.PlannedFinish, t.Completed, t.WorkingDays, t.WBS
			FROM PMProjectTaskDependencies  pd WITH (NOLOCK) 
			INNER JOIN Tasks t WITH (NOLOCK) ON pd.ParentTaskId=t.TaskId 
			INNER JOIN Project p WITH (NOLOCK) ON p.ProjectId=t.ProjectId 
			INNER JOIN Engagement e WITH (NOLOCK) ON e.EngagementId=p.EngagementId
			AND NOT EXISTS(SELECT TOP 1 1 FROM  ProcessProjectTaskDependencies pd2 WITH (NOLOCK) WHERE pd2.Requestid=@SessionId AND t.TaskId=pd2.TaskId)
			WHERE pd.SessionId=@SessionId 
			AND pd.ParentProjectId <> @ProjectId 
			
			
			INSERT INTO #CR_Tasks (CriticalPathProjectId, ProjectId, AssociatedWorkgroup,TaskIdentity, TaskId,PlannedFinish, Completed,WorkingDays,  WBS)
			SELECT ap.CriticalPathProjectId, ap.ProjectId, e.AssociatedWorkgroup, t.TaskIdentity, t.TaskId, t.PlannedFinish, t.Completed, t.WorkingDays, t.WBS
			FROM  #SubProjects ap 
			INNER JOIN Tasks t  WITH (NOLOCK)  ON ap.ProjectId=t.Projectid AND t.Deleted=0x0  
			INNER JOIN Engagement e WITH (NOLOCK) ON e.EngagementId=t.EngagementId
			AND NOT EXISTS(SELECT TOP  1 1 FROM   #CriticalPathTasks  ct WHERE ct.CriticalPathProjectId =ap.CriticalPathProjectId AND ct.TaskIdentity=t.TaskIdentity)
			WHERE ap.CriticalPathProjectId <> ap.ProjectId
			UPDATE #CriticalPathProjects
			SET MaxPlannedFinish=tt.MAXPlannedFinish
			FROM #CriticalPathProjects crp
			CROSS APPLY 
			(
				SELECT MAX(PlannedFinish) MAXPlannedFinish FROM #CR_Tasks  t WITH (NOLOCK)  WHERE t.ProjectId=crp.CriticalPathProjectId
				AND  t.Completed=0
			) tt
		END 
		
		SELECT @DaysCount = CASE WHEN  MAX(tt.LagTime) * 2  >  @DaysCount THEN  MAX(tt.LagTime) * 2  ELSE  @DaysCount END
		FROM 
		(
			SELECT pd.LagTime FROM #SubProjects ip 
			INNER JOIN ProjectTaskDependencies  pd WITH (NOLOCK)  ON ip.ProjectId =pd.ProjectId
			WHERE NOT EXISTS(SELECT TOP 1 1 FROM PMEntityChanges pc  WITH (NOLOCK)  WHERE pc.SessionId=@SessionId 
			AND  pc.ProjectId=pd.ProjectId)
			UNION 
			SELECT pd.LagTime FROM #InterProjects ip 
			INNER JOIN ProjectTaskDependencies  pd WITH (NOLOCK)  ON ip.ProjectId =pd.ProjectId
			UNION 
			SELECT LagTime FROM PMProjectTaskDependencies WITH (NOLOCK)  WHERE SessionId=@SessionId
		) tt
		INSERT INTO  #CR_WorkingDays(WorkgroupId, WorkingDate)
		SELECT  tt1.AssociatedWorkgroup, wd.WorkingDate FROM WorkingDays  wd  WITH (NOLOCK) 
		CROSS APPLY 
		(
				SELECT  ip.AssociatedWorkgroup FROM  #InterProjects ip 
				 UNION 
				SELECT ct.AssociatedWorkgroup FROM #CR_Tasks ct 
				 UNION 
				SELECT cp.AssociatedWorkgroup FROM #CriticalPathProjects cp
		) tt1
		CROSS APPLY 
		(
			SELECT  MIN(t.PlannedStart)  MINPlannedStart,  MAX(t.PlannedFinish) MAXPlannedFinish
			FROM 
			(
				SELECT cr.PlannedStart, cr.MaxPlannedFinish  PlannedFinish FROM  #CriticalPathProjects  cr
				UNION 
				SELECT ip.PlannedStart, ip.PlannedFinish FROM  #InterProjects ip  
			) t
		) tt
		WHERE	 wd.WorkingDate BETWEEN DATEADD(dd,- @DaysCount, tt.MINPlannedStart)  AND DATEADD(dd,@DaysCount,tt.MAXPlannedFinish)
		AND NOT EXISTS(SELECT TOP 1 1 FROM  WorkgroupNonWorkingDay nwd WITH (NOLOCK) WHERE nwd.WorkgroupId=tt1.AssociatedWorkgroup AND wd.WorkingDate=nwd.NonWorkingDate)
		ORDER BY  tt1.AssociatedWorkgroup, wd.WorkingDate
		
		UPDATE #CriticalPathProjects  SET MAXWorkDate=ISNULL(tt.MAXWorkingDate, cr.PlannedStart),  MAXID=ISNULL(tt.MAXID,0)
		FROM  #CriticalPathProjects cr
		CROSS APPLY 
		(
			SELECT  MAX(wd.WorkingDate) MAXWorkingDate, MAX(wd.ID)  MAXID FROM #CR_WorkingDays wd WHERE wd.WorkgroupId =cr.AssociatedWorkgroup  AND wd.WorkingDate <=cr.MaxPlannedFinish
		)tt
		
		INSERT INTO #CriticalPathTasks(CriticalPathProjectId, ProjectId	,TaskIdentity, TaskId, Successor, Completed, WBS)
		SELECT DISTINCT cr.CriticalPathProjectId,cr.CriticalPathProjectId,t.TaskIdentity, t.TaskId, 
		CASE WHEN pd.ParentTaskId IS NULL THEN 0x0 ELSE 0x1 END, t.Completed, t.WBS
		FROM #CriticalPathProjects cr 
		INNER JOIN #CR_Tasks t WITH (NOLOCK) ON t.ProjectId=cr.CriticalPathProjectId  AND  t.Completed=0x0 
		AND t.PlannedFinish >= cr.MAXWorkDate
		LEFT JOIN PMProjectTaskDependencies pd WITH (NOLOCK) ON  pd.SessionId=@SessionId AND  pd.TaskId=t.TaskId AND pd.MoveAffectedTaskDate=0x1 
		INSERT INTO #CriticalPathTasks(CriticalPathProjectId, ProjectId	,TaskIdentity, TaskId, Successor, Completed, WBS)
		SELECT DISTINCT cr.CriticalPathProjectId,af.ProjectId,t.TaskIdentity, t.TaskId, 
		CASE WHEN pd.ParentTaskId IS NULL THEN 0x0 ELSE 0x1 END, t.Completed, t.WBS
		FROM #CriticalPathProjects cr 
		INNER JOIN  #SubProjects af ON cr.CriticalPathProjectId=af.CriticalPathProjectId
		INNER JOIN Tasks t WITH (NOLOCK) ON t.ProjectId=af.ProjectId  AND t.Deleted=0x0 AND  t.Completed=0x0 
		AND t.PlannedFinish >= cr.MAXWorkDate
		LEFT JOIN ProjectTaskDependencies pd WITH (NOLOCK) ON pd.TaskId=t.TaskId AND pd.MoveAffectedTaskDate=0x1 
		WHERE NOT EXISTS(SELECT  TOP  1 1 FROM #CR_Tasks ct WHERE ct.TaskIdentity=t.TaskIdentity)
		AND NOT EXISTS (SELECT TOP 1 1 FROM PMEntityRollupChanges pe WITH  (NOLOCK)  WHERE pe.SessionId=@SessionId AND t.TaskId=pe.EntityId)
	
	
		UPDATE #CR_Tasks SET WorkingDays=  tt.MAXID +1 - tt2.MAXID
		FROM  #CR_Tasks crt
		CROSS APPLY 
		(
			SELECT MAX(wd.ID)  MAXID FROM #CR_WorkingDays wd WHERE wd.WorkgroupId =crt.AssociatedWorkgroup  AND wd.WorkingDate <=crt.PlannedFinish 
		)tt
		CROSS APPLY 
		(
			SELECT MIN(wd.ID)  MAXID FROM #CR_WorkingDays wd WHERE wd.WorkgroupId =crt.AssociatedWorkgroup  AND crt.PlannedStart <= wd.WorkingDate 
		)tt2
		WHERE crt.WorkingDays=-1
		
		IF EXISTS(SELECT TOP 1 1 FROM  #CriticalPathTasks   WHERE Successor=0x1) 
		BEGIN 
			SET @Count=0
			WHILE EXISTS(SELECT TOP 1 1 FROM  #CriticalPathTasks WHERE Successor=0x1 AND Processed=0x0) AND  @Count <=@MaXDepLevel
			BEGIN
				TRUNCATE TABLE  #Dependency
		
				INSERT INTO  #Dependency (CriticalPathProjectId, WorkgroupId, Successor,DepStart,DepEND, SuccessorWorkingDays, Predecessor, PredecessorDate, DependencyType,LagTime)
				SELECT ct.CriticalPathProjectId,  e.AssociatedWorkgroup , t.TaskIdentity, t.PlannedStart, t.PlannedFinish, t.WorkingDays, t2.TaskIdentity, 
				CASE WHEN pd.DependencyType  IN ('SS', 'SF') THEN  t2.PlannedStart  ELSE t2.PlannedFinish END,
				pd.DependencyType, pd.LagTime
				FROM   #CriticalPathTasks  ct 
				INNER JOIN Tasks t WITH (NOLOCK)  ON ct.TaskIdentity =t.TaskIdentity AND t.Deleted=0x0 
				INNER JOIN Engagement e WITH (NOLOCK)  ON t.EngagementId=e.EngagementId
				INNER JOIN ProjectTaskDependencies  pd WITH (NOLOCK) ON pd.TaskId=t.TaskId AND pd.MoveAffectedTaskDate=0x1
				INNER JOIN Tasks t2 WITH (NOLOCK)  ON pd.ParentTaskId =t2.TaskId AND t2.Deleted=0x0 
				WHERE ct.Successor=1 AND  Processed=0x0 AND NOT EXISTS(SELECT  TOP  1 1 FROM #CR_Tasks ct WHERE ct.TaskIdentity=t.TaskIdentity)
				AND NOT EXISTS(SELECT TOP  1 1 FROM PMEntityChanges pc WITH (NOLOCK) WHERE pc.SessionId=@SessionId AND t.ProjectId=pc.ProjectId)
				
				UNION 
				SELECT ct.CriticalPathProjectId, cp.AssociatedWorkgroup , t.TaskIdentity, t.PlannedStart, t.PlannedFinish, t.WorkingDays, t2.TaskIdentity, 
				CASE WHEN pd.DependencyType  IN ('SS', 'SF') THEN  t2.PlannedStart  ELSE t2.PlannedFinish END,
				pd.DependencyType, pd.LagTime
				FROM   #CriticalPathTasks  ct 
				INNER JOIN #CR_Tasks t WITH (NOLOCK)  ON ct.TaskIdentity =t.TaskIdentity 
				INNER JOIN  #CriticalPathProjects cp  ON ct.CriticalPathProjectId=cp.CriticalPathProjectId
				INNER JOIN PMProjectTaskDependencies  pd WITH (NOLOCK) ON  pd.SessionId=@SessionId  AND pd.TaskId=t.TaskId AND pd.MoveAffectedTaskDate=0x1
				INNER JOIN #CR_Tasks t2 WITH (NOLOCK)  ON pd.ParentTaskId =t2.TaskId 
				WHERE ct.Successor=1 AND  Processed=0x0 
				UPDATE   #CriticalPathTasks SET Processed=0x1 WHERE Successor=0x1 AND Processed=0x0
				
				
				UPDATE  #Dependency  SET Critical=0x1
				FROM  #Dependency dp WHERE NOT EXISTS(SELECT TOP 1 1 FROM #Dependency dp2 WHERE dp2.CriticalPathProjectId=dp.CriticalPathProjectId AND dp2.Successor=dp.Successor AND dp2.Predecessor<>dp.Predecessor)
				
				IF EXISTS(SELECT TOP  1 1 FROM  #Dependency WHERE  Critical=0x0)
				BEGIN 
					UPDATE #Dependency SET DepStart=PredecessorDate + (LagTime +1 )  WHERE DependencyType IN ('FS','SS') AND Critical=0x0
					
					UPDATE #Dependency  SET  DepStart=   CASE WHEN rq.DependencyType = 'FS' THEN wd.WorkingDate  ELSE rq.DepStart END, 
					DepEnd =CASE WHEN rq.DependencyType = 'FS' THEN   rq.DepEnd    ELSE   wd.WorkingDate END
					FROM #Dependency rq
					INNER JOIN #CR_WorkingDays wd WITH (NOLOCK) ON rq.WorkgroupId=wd.WorkgroupId  AND rq.LagTime > 0  
					INNER JOIN 
					(	SELECT tt.WorkgroupId,  wd.ID , tt.DP_Identity
						FROM #CR_WorkingDays wd WITH (NOLOCK)  
						INNER JOIN 
								(	SELECT MAX(wd.WorkingDate) WorkingDate , wd.WorkgroupId , rq.DP_Identity
									FROM #CR_WorkingDays wd  WITH (NOLOCK) 
									INNER JOIN #Dependency rq ON rq.WorkgroupId =wd.WorkgroupId 
									and wd.WorkingDate<=rq.PredecessorDate   
									AND rq.LagTime > 0
									GROUP BY wd.WorkgroupId , rq.DP_Identity
								) tt 
						ON tt.WorkgroupId=wd.WorkgroupId AND tt.WorkingDate=wd.WorkingDate	
					) tt1  
					ON tt1.WorkgroupId=wd.WorkgroupId AND  tt1.Dp_Identity=rq.DP_Identity 
					AND (tt1.ID + rq.LagTime + CASE WHEN rq.DependencyType='FS' THEN  1 ELSE 0 END )=wd.ID
					WHERE   rq.DependencyType IN  ('FS','FF') AND rq.Critical=0x0
					UPDATE #Dependency  SET DepStart=  CASE WHEN rq.DependencyType = 'FS' THEN wd.WorkingDate  ELSE rq.DepStart END, 
					DepEnd =CASE WHEN rq.DependencyType = 'FS' THEN   rq.DepEnd     ELSE  wd.WorkingDate END
					FROM #Dependency rq
					INNER JOIN #CR_WorkingDays wd WITH (NOLOCK) ON rq.WorkgroupId=wd.WorkgroupId  AND rq.LagTime < =0 
					INNER JOIN 
						(SELECT  tt.WorkgroupId,  wd.ID , tt.DP_Identity
							FROM #CR_WorkingDays wd WITH (NOLOCK)  
							INNER JOIN 
								(
									SELECT MIN(wd.WorkingDate) WorkingDate , wd.WorkgroupId, rq.DP_Identity
									FROM #CR_WorkingDays wd WITH (NOLOCK) 
									INNER JOIN #Dependency rq ON rq.WorkgroupId =wd.WorkgroupId 
									and wd.WorkingDate  > rq.PredecessorDate AND rq.LagTime < =0  
									GROUP BY wd.WorkgroupId , rq.DP_Identity
									) tt 
							ON tt.WorkgroupId=wd.WorkgroupId AND tt.WorkingDate=wd.WorkingDate
						) tt1  
					ON tt1.WorkgroupId=wd.WorkgroupId AND  tt1.Dp_Identity=rq.DP_Identity 
					AND (tt1.ID + rq.LagTime  - CASE WHEN rq.DependencyType='FS' THEN 0 ELSE 1 END )=wd.ID
					WHERE rq.DependencyType  IN ('FS','FF') AND  rq.Critical=0x0
					
					UPDATE #Dependency  SET DepEnd = CASE WHEN rq.DependencyType =  'SF'  THEN wd.WorkingDate  ELSE  rq.DepEND END, 
					DepStart=CASE WHEN rq.DependencyType =  'SS' THEN wd.WorkingDate ELSE  rq.DepStart END
					FROM #Dependency rq
					INNER JOIN #CR_WorkingDays wd WITH (NOLOCK) ON rq.WorkgroupId =wd.WorkgroupId 
					INNER JOIN 
						(SELECT tt.WorkgroupId,  wd.ID , tt.DP_Identity
							FROM  #CR_WorkingDays wd WITH (NOLOCK)  
							INNER JOIN 
									(
										SELECT MIN(wd.WorkingDate) WorkingDate , wd.WorkgroupId, rq.DP_Identity
										FROM #CR_WorkingDays wd WITH (NOLOCK) 
										INNER JOIN #Dependency rq ON rq.WorkgroupId =wd.WorkgroupId
										and wd.WorkingDate >=rq.PredecessorDate   
										GROUP BY wd.WorkgroupId , rq.DP_Identity
									) tt 
							ON tt.WorkgroupId=wd.WorkgroupId AND tt.WorkingDate=wd.WorkingDate
						)tt1 
						ON tt1.WorkgroupId=wd.WorkgroupId AND  tt1.DP_Identity=rq.DP_Identity  
					AND (tt1.ID + rq.LagTime - CASE WHEN rq.DependencyType='SF' THEN 1 ELSE 0 END   )=wd.ID
					WHERE   rq.DependencyType  IN ('SF','SS') AND rq.Critical=0x0
					
					UPDATE #Dependency  SET DepEnd=wd.WorkingDate 
					FROM #Dependency rq
					INNER JOIN #CR_WorkingDays wd WITH (NOLOCK) ON rq.WorkgroupId =wd.WorkgroupId 
					INNER JOIN 
						(SELECT tt.WorkgroupId,  wd.ID , tt.DP_Identity
							FROM #CR_WorkingDays wd WITH (NOLOCK)  
							INNER JOIN 
								(	SELECT MIN(wd.WorkingDate) WorkingDate , wd.WorkgroupId, rq.DP_Identity
									FROM #CR_WorkingDays wd  WITH (NOLOCK) 
									INNER JOIN #Dependency rq ON rq.WorkgroupId =wd.WorkgroupId 
									and wd.WorkingDate >=rq.DepStart  
									GROUP BY wd.WorkgroupId , rq.DP_Identity
								) tt 
							
							ON tt.WorkgroupId=wd.WorkgroupId AND tt.WorkingDate=wd.WorkingDate
						) tt1 
						ON  tt1.WorkgroupId=wd.WorkgroupId AND  tt1.DP_Identity=rq.DP_Identity  
					AND (tt1.ID + rq.SuccessorWorkingDays  - CASE WHEN rq.SuccessorWorkingDays > 0 THEN 1 ELSE 0 END)=wd.ID
					WHERE   rq.DependencyType  IN ('FS','SS')  AND rq.Critical=0x0
					UPDATE #Dependency SET Critical=1
					FROM #Dependency dp
					CROSS APPLY
					(
						SELECT  MAX(dp2.DepEnd)  MAXDepEnd
						FROM  #Dependency  dp2  WHERE dp2.Critical=0x0 AND dp.Successor=dp2.Successor  AND dp.CriticalPathProjectId=dp2.CriticalPathProjectId
							
					)tt
					WHERE dp.Critical=0x0 AND tt.MAXDepEnd=dp.DepEND
		
				END 
				INSERT INTO #CriticalPathTasks(CriticalPathProjectId, ProjectId	,TaskIdentity, TaskId,Successor, Completed,  WBS)
				SELECT DISTINCT cr.CriticalPathProjectId,t.ProjectId,t.TaskIdentity, t.TaskId, 
				CASE WHEN pd.ParentTaskId IS NULL THEN 0x0 ELSE 0x1 END, t.Completed, t.WBS
				FROM  #Dependency dp 
				INNER JOIN   #CriticalPathProjects cr ON  dp.Critical=1  AND dp.CriticalPathProjectId=cr.CriticalPathProjectId
				INNER JOIN Tasks t WITH (NOLOCK) ON t.TaskIdentity=dp.Predecessor AND t.Deleted=0x0 
				LEFT JOIN ProjectTaskDependencies pd WITH (NOLOCK) ON pd.TaskId=t.TaskId AND pd.MoveAffectedTaskDate=0x1
				WHERE NOT EXISTS(SELECT TOP 1 1 FROM   #CriticalPathTasks  cr2  WHERE  cr2.CriticalPathProjectId=cr.CriticalPathProjectId AND  cr2.TaskIdentity=t.TaskIdentity)
				AND NOT EXISTS(SELECT  TOP  1 1 FROM #CR_Tasks ct WHERE ct.TaskIdentity=t.TaskIdentity)
				AND NOT EXISTS(SELECT TOP  1 1 FROM PMEntityChanges pc WITH (NOLOCK) WHERE pc.SessionId=@SessionId
				AND t.ProjectId=pc.ProjectId)
				UNION 
				SELECT DISTINCT cr.CriticalPathProjectId,cr.CriticalPathProjectId,t.TaskIdentity, t.TaskId, 
				CASE WHEN pd.ParentTaskId IS NULL THEN 0x0 ELSE 0x1 END, t.Completed, t.WBS
				FROM   #Dependency dp
				INNER JOIN #CriticalPathProjects cr ON  dp.Critical=1  AND dp.CriticalPathProjectId=cr.CriticalPathProjectId
				INNER JOIN #CR_Tasks t WITH (NOLOCK) ON t.TaskIdentity=dp.Predecessor AND  t.Completed=0x0 
				LEFT JOIN PMProjectTaskDependencies pd WITH (NOLOCK) ON  pd.SessionId=@SessionId AND  pd.TaskId=t.TaskId AND pd.MoveAffectedTaskDate=0x1 
				WHERE NOT EXISTS(SELECT TOP 1 1 FROM   #CriticalPathTasks  cr2  WHERE  cr2.CriticalPathProjectId=cr.CriticalPathProjectId
				AND  cr2.TaskIdentity=t.TaskIdentity)
			
				SET @Count =@Count+1
				
			END
			
		END
		IF @Virtual=0x0 
			BEGIN 
				
				INSERT INTO #CR_Tasks (CriticalPathProjectId, ProjectId, AssociatedWorkgroup,TaskIdentity, TaskId,PlannedFinish, Completed, WBS)
				SELECT ap.CriticalPathProjectId, ap.ProjectId, e.AssociatedWorkgroup, t.TaskIdentity, t.TaskId, t.PlannedFinish, t.Completed, t.WBS
				FROM  #SubProjects ap 
				INNER JOIN Tasks t  WITH (NOLOCK)  ON ap.ProjectId=t.Projectid AND t.Deleted=0x0 
				INNER JOIN Engagement e WITH (NOLOCK) ON e.EngagementId=t.EngagementId
				AND NOT EXISTS(SELECT TOP  1 1 FROM   #CriticalPathTasks  ct WHERE ct.CriticalPathProjectId =ap.CriticalPathProjectId AND ct.TaskIdentity=t.TaskIdentity)
				INSERT INTO #CR_Tasks (CriticalPathProjectId, ProjectId,TaskIdentity, TaskId, Critical,Slack, WBS)
				SELECT ct.CriticalPathProjectId, ct.ProjectId, ct.TaskIdentity, ct.TaskId,
				CASE WHEN ct.Completed =0x0 THEN 0x1  ELSE 0x0 END, 0 , ct.WBS
				FROM  #CriticalPathTasks ct 
				
				UPDATE  #CR_Tasks SET Critical=0x1
				FROM  #CR_Tasks  tt
				WHERE tt.Completed=0x0 AND  EXISTS(SELECT TOP 1 1 FROM  #CR_Tasks tt2  WHERE tt2.ProjectId=tt.ProjectId  AND tt2.Critical=0x1 AND tt2.WBS LIKE tt.WBS +'.%'
	
				)
	
				UPDATE #CR_Tasks SET MAXID=tt.MAXID, Slack=cp.MAXID-tt.MAXID
				FROM  #CR_Tasks crt
				INNER JOIN  #CriticalPathProjects cp  ON crt.CriticalPathProjectId=cp.CriticalPathProjectId AND crt.Completed=0x0  AND  crt.Critical=0x0
				AND cp.MAXID IS NOT NULL 
				CROSS APPLY 
				(
					SELECT MAX(wd.ID)  MAXID FROM #CR_WorkingDays wd WHERE wd.WorkgroupId =cp.AssociatedWorkgroup  AND wd.WorkingDate <=crt.PlannedFinish
				)tt 
				WHERE tt.MAXID IS NOT NULL
				DELETE ProjectCriticalPath
				FROM ProjectCriticalPath p WITH (NOLOCK) 
				INNER JOIN  #CriticalPathProjects cp ON cp.CriticalPathProjectId=p.CriticalPathProjectId
	
				INSERT INTO  ProjectCriticalPath (CriticalPathProjectId,TaskId,Critical,Slack,CreatedOn)
				SELECT  DiSTINCT ct.CriticalPathProjectId,ct.TaskId,ct.Critical,CASE  WHEN ct.Slack  < 0 THEN 0 ELSE ct.Slack END,GETDATE()
				FROM  #CriticalPathProjects cp 
				INNER JOIN #CR_Tasks ct ON cp.CriticalPathProjectId=ct.CriticalPathProjectId AND ct.Completed=0x0
				
				UPDATE Project 
				SET RecalcCriticalPath=0x0
				FROM Project p INNER JOIN #CriticalPathProjects c ON p.ProjectId=c.CriticalPathProjectId	
				WHERE p.RecalcCriticalPath=0x1		
				
			END 
		ELSE
			BEGIN 
				UPDATE  #CR_Tasks SET Critical=0x1
				FROM  #CR_Tasks  tt
				INNER JOIN  #CriticalPathTasks  ct ON tt.Taskid=ct.TaskId
				
				UPDATE  #CR_Tasks SET Critical=0x1
				FROM  #CR_Tasks  tt
				WHERE tt.Completed=0x0 AND  EXISTS(SELECT TOP 1 1 FROM  #CR_Tasks tt2  WHERE tt2.ProjectId=tt.ProjectId  AND tt2.Critical=0x1 AND tt2.WBS LIKE tt.WBS +'.%'
				)
	
				
				UPDATE #CR_Tasks SET MAXID=tt.MAXID, Slack=cp.MAXID-tt.MAXID
				FROM  #CR_Tasks crt
				INNER JOIN  #CriticalPathProjects cp  ON crt.CriticalPathProjectId=cp.CriticalPathProjectId AND crt.Completed=0x0  AND  crt.Critical=0x0
				AND cp.MAXID IS NOT NULL 
				CROSS APPLY 
				(
					SELECT MAX(wd.ID)  MAXID FROM #CR_WorkingDays wd WHERE wd.WorkgroupId =cp.AssociatedWorkgroup  AND wd.WorkingDate <=crt.PlannedFinish
				)tt 
				WHERE tt.MAXID IS NOT NULL
			
				DELETE PMProjectCriticalPath
				FROM PMProjectCriticalPath p with(nolock) 
				INNER JOIN  #CriticalPathProjects cp ON cp.CriticalPathProjectId=p.CriticalPathProjectId
				WHERE p.SessionId=@SessionId
				INSERT INTO PMProjectCriticalPath (SessionId, CriticalPathProjectId, TaskId, Critical, Slack)
				SELECT @SessionId,  tt.CriticalPathProjectId, tt.TaskId, tt.Critical, CASE  WHEN tt.Slack  < 0 THEN 0 ELSE  tt.Slack END
				FROM  #CriticalPathProjects cp 
				INNER JOIN #CR_Tasks tt ON cp.CriticalPathProjectId=tt.CriticalPathProjectId AND tt.Completed=0x0
				
				IF @Validate=1 
					SELECT TaskId, Critical, Slack
					FROM PMProjectCriticalPath WITH (NOLOCK) 
					WHERE SessionId=@SessionId AND CriticalPathProjectId=@ProjectId
				IF NOT @TransactionXML IS NULL 
				EXEC SaveTransactionLog @@PROCID, @PM_StartLogTime, @TransactionXML
		END 
	DROP TABLE #CriticalPathProjects
	
	
	
	SET NOCOUNT OFF		
END

GO
