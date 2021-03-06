USE [Changepoint]
GO
/****** Object:  StoredProcedure [dbo].[PND_SaveWorkDaysConvToDay]    Script Date: 10/14/2019 2:31:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PND_SaveWorkDaysConvToDay] 
(
	@ResourceId				UNIQUEIDENTIFIER,
	@SessionId				UNIQUEIDENTIFIER,
	@AssociatedWorkgroup	UNIQUEIDENTIFIER= NULL, 
	@TransactionXML			XML=NULL
)
	
         AS 
	
BEGIN
	DEClARE @PM_StartLogTime	DATETIME
	IF NOT @TransactionXML IS NULL SET @PM_StartLogTime=GETUTCDATE()
	DECLARE @CalculateWorkingDays BIT , @CalculateConversionDay    BIT,   @PNDSetting  CHAR(1), @NULLID UNIQUEIDENTIFIER
	CREATE TABLE #PND_WorkingDaysConversionDay 
	(
		LevelType			CHAR(1) NOT NULL,
		LevelTypeId			UNIQUEIDENTIFIER  NOT NULL,
		EntityId			UNIQUEIDENTIFIER  NOT NULL,
		FiscalPeriodId		UNIQUEIDENTIFIER,
		StartPeriod			DATETIME,
		EndPeriod			DATETIME,
		WorkingDays			INT DEFAULT 0,
		ConversionToDay		NUMERIC (5,3) DEfAULT 0, 
		ResourceId			UNIQUEIDENTIFIER
	)
	SET @CalculateWorkingDays=0x1 SET @CalculateConversionDay=0x1
	SET @NULLID='00000000-0000-0000-0000-000000000000'
	
    UPDATE TaskAssignmentRequest
	SET TaskAssignmentId = NewId()
	WHERE RequestId=@SessionId and ISNULL(TaskAssignmentId,@NULLID)=@NULLID
	
	
	TRUNCATE TABLE #PND_WorkingDaysConversionDay
	INSERT INTO #PND_WorkingDaysConversionDay (LevelType, LevelTypeId, EntityId, FiscalPeriodId, StartPeriod, EndPeriod)
	SELECT CASE WHEN ISNULL(r.ResourceId,@NULLID)<>@NULLID  THEN 'r' ELSE 
				CASE WHEN ISNULL(e.AssociatedWorkgroup,@NULLID)=@NULLID THEN 's' ELSE 'w' END END, 
			CASE WHEN ISNULL(r.ResourceId,@NULLID)<>@NULLID THEN r.ResourceId 
				ELSE ISNULL(e.AssociatedWorkgroup,@NULLID) END, TaskAssignmentId, NULL, NewStart, NewEnd
	FROM TaskAssignmentRequest r WITH(NOLOCK)
	LEFT OUTER JOIN Tasks t WITH(NOLOCK) ON t.TaskId=ISNULL(r.OldTaskId,r.TaskId)
	LEFT OUTER JOIN Engagement e WITH(NOLOCK) ON e.EngagementId=t.EngagementId
	WHERE r.RequestId=@SessionId 
	INSERT INTO #PND_WorkingDaysConversionDay (LevelType, LevelTypeId, EntityId, FiscalPeriodId, StartPeriod, EndPeriod)
	SELECT CASE WHEN ISNULL(r.ResourceId,@NULLID)<>@NULLID  THEN 'r' ELSE 
			CASE WHEN ISNULL(e.AssociatedWorkgroup,@NULLID)=@NULLID THEN 's' ELSE 'w' END END, 
		CASE WHEN ISNULL(r.ResourceId,@NULLID)<>@NULLID THEN r.ResourceId 
			ELSE ISNULL(e.AssociatedWorkgroup,@NULLID) END, ProjectTeamId, NULL, StartDate, FinishDate
	FROM ProjectTeamRequest r WITH(NOLOCK)
	INNER JOIN Project p WITH(NOLOCK) ON p.ProjectId=r.ProjectId
	INNER JOIN Engagement e WITH(NOLOCK) ON e.EngagementId=p.EngagementId
	WHERE r.LevRequestId=@SessionId 
	INSERT INTO #PND_WorkingDaysConversionDay (LevelType, LevelTypeId, EntityId, FiscalPeriodId, StartPeriod, EndPeriod)
	SELECT CASE WHEN ISNULL(e.AssociatedWorkgroup,@NULLID)=@NULLID THEN 's' ELSE 'w' END, 
		ISNULL(e.AssociatedWorkgroup,@NULLID), p.TaskId, NULL, p.NewPlannedStart, p.NewPlannedFinish
	FROM
		(SELECT MIN(NewPlannedStart) NewPlannedStart, MAX(NewPlannedFinish) NewPlannedFinish, ISNULL(OldTaskId,TaskId) TaskId, ProjectId
			FROM ProcessProjectTaskDependencies  WITH (NOLOCK) 
			WHERE RequestId=@SessionId
			GROUP BY ISNULL(OldTaskId,TaskId), ProjectId
		) p 
	INNER JOIN Project pr WITH(NOLOCK) ON p.ProjectId=pr.ProjectId
	INNER JOIN Engagement e WITH(NOLOCK) ON e.EngagementId=pr.EngagementId
	
	EXEC dbo.PND_WorkingDaysConversionDay @CalculateWorkingDays, @CalculateConversionDay
	UPDATE ProcessProjectTaskDependencies
	SET WorkingDays = p.WorkingDays, ConversionToDay = p.ConversionToDay
	FROM #PND_WorkingDaysConversionDay p 
	INNER JOIN ProcessProjectTaskDependencies t ON p.EntityId =ISNULL(t.OldTaskId,t.TaskId) AND t.RequestId = @SessionId
	WHERE RequestId=@SessionId
	UPDATE TaskAssignmentRequest
	SET WorkingDays = p.WorkingDays, ConversionToDay = p.ConversionToDay
	FROM #PND_WorkingDaysConversionDay p 
	INNER JOIN TaskAssignmentRequest t ON p.EntityId = t.TaskAssignmentId AND t.RequestId = @SessionId
	WHERE RequestId=@SessionId
	UPDATE ProjectTeamRequest
	SET WorkingDays = p.WorkingDays, ConversionToDay = p.ConversionToDay
	FROM #PND_WorkingDaysConversionDay p 
	INNER JOIN ProjectTeamRequest r ON p.EntityId = r.ProjectTeamId AND r.LevRequestId = @SessionId
	WHERE LevRequestId=@SessionId
	TRUNCATE TABLE #PND_WorkingDaysConversionDay
	IF NOT @TransactionXML IS NULL 
		EXEC SaveTransactionLog @@PROCID, @PM_StartLogTime, @TransactionXML
	
END

GO
