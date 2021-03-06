USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_TimeReport_VIEW]    Script Date: 10/17/2019 3:05:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO




/****** Object:  View dbo.BG_TimeReport_VIEW    Script Date: 6/20/2007 1:07:01 PM ******/
CREATE VIEW [dbo].[BG_TimeReport_VIEW]
AS
SELECT '**BILLABLE CLIENT TIME**' AS TimeType,  [dbo].[Time].[CustomerId], [dbo].[Time].[EngagementId], [dbo].[Time].[ProjectId], [dbo].[Time].[TaskId], [dbo].[Time].[WorkgroupId], [dbo].[Time].[ResourceId], [dbo].[Time].[TimeDate], ([dbo].[Time].[RegularHours] + [dbo].[Time].[AdjustedRegularHours] + [dbo].[Time].[OvertimeHours] + [dbo].[Time].[AdjustedOvertimeHours]) AS RegularHours, [dbo].[Time].[ApprovalStatus], [dbo].[Time].[Billable], CAST((CEILING((CAST([Time].[TimeDate] AS Numeric)+3) / 7)*7)-3 AS DateTime) AS WeekEnding, [dbo].[Time].[CertificationDate], DATEADD (Hour, 30, CAST((CEILING((CAST([Time].[TimeDate] AS Numeric)+3) / 7)*7)-3 AS DateTime)) AS DueDate, [Tasks].[AffectUtilization], CAST ([dbo].[Time].[Description] AS Varchar(200)) AS Description
FROM [dbo].[Time], [dbo].[Tasks] WITH (nolock)
WHERE  [dbo].[Time].[TaskId] = [dbo].[Tasks].[TaskId] AND [dbo].[Time].[Billable] = 1 AND  [dbo].[Time].[AdjustmentTimeParent] IS NULL
UNION
SELECT '**PROMOTIONAL CLIENT TIME**' AS TimeType,  [dbo].[Time].[CustomerId], [dbo].[Time].[EngagementId], [dbo].[Time].[ProjectId], [dbo].[Time].[TaskId], [dbo].[Time].[WorkgroupId], [dbo].[Time].[ResourceId], [dbo].[Time].[TimeDate], ([dbo].[Time].[RegularHours] + [dbo].[Time].[AdjustedRegularHours] + [dbo].[Time].[OvertimeHours] + [dbo].[Time].[AdjustedOvertimeHours]) AS RegularHours, [dbo].[Time].[ApprovalStatus], [dbo].[Time].[Billable], CAST((CEILING((CAST([Time].[TimeDate] AS Numeric)+3) / 7)*7)-3 AS DateTime) AS WeekEnding, [dbo].[Time].[CertificationDate], DATEADD (Hour, 30, CAST((CEILING((CAST([Time].[TimeDate] AS Numeric)+3) / 7)*7)-3 AS DateTime)) AS DueDate, [Tasks].[AffectUtilization], CAST ([dbo].[Time].[Description] AS Varchar(200)) AS Description
FROM [dbo].[Time], [dbo].[Tasks] WITH (nolock)
WHERE  [dbo].[Time].[TaskId] = [dbo].[Tasks].[TaskId] AND [dbo].[Time].[Billable] = 0 AND  [dbo].[Time].[AdjustmentTimeParent] IS NULL
UNION
SELECT [dbo].[StandardTask].[Name] AS TimeType,  '{921E8672-8A4B-482E-85D3-8D545E5D1C2A}' AS CustomerId, '{00000000-0000-0000-0000-000000000000}' AS EngagementId, '{00000000-0000-0000-0000-000000000000}' AS ProjectId, '{00000000-0000-0000-0000-000000000000}' AS [TaskId], [dbo].[StandardTaskTime].[WorkgroupId], [dbo].[StandardTaskTime].[ResourceId], [dbo].[StandardTaskTime].[DateBooked], ([dbo].[StandardTaskTime].[RegularHours] + [dbo].[StandardTaskTime].[AdjustedRegularHours] + [dbo].[StandardTaskTime].[OvertimeHours] + [dbo].[StandardTaskTime].[AdjustedOvertimeHours]) AS RegularHours, [dbo].[StandardTaskTime].[ApprovalStatus], 0 AS Billable, CAST((CEILING((CAST([StandardTaskTime].[DateBooked] AS Numeric)+3) / 7)*7)-3 AS DateTime) AS WeekEnding, [dbo].[StandardTaskTime].[CertificationDate], DATEADD (Hour, 30, CAST((CEILING((CAST([StandardTaskTime].[DateBooked] AS Numeric)+3) / 7)*7)-3 AS DateTime)) AS DueDate, [StandardTask].[AffectUtilization], CAST ([dbo].[StandardTaskTime].[Description] AS Varchar(200)) AS Description
FROM [dbo].[StandardTaskTime] WITH (nolock)
LEFT OUTER JOIN [dbo].[StandardTask] WITH (nolock)
ON [dbo].[StandardTaskTime].[TaskId] = [dbo].[StandardTask].[TaskId]
WHERE  [dbo].[StandardTaskTime].[AdjustmentTimeParent] IS NULL
UNION
SELECT '**SUPPORT REQUEST TIME**' AS TimeType,  [dbo].[RequestTime].[CustomerId], [dbo].[RequestTime].[EngagementId], '{00000000-0000-0000-0000-000000000000}' AS ProjectId, '{00000000-0000-0000-0000-000000000000}' AS [TaskId], [dbo].[RequestTime].[WorkgroupId], [dbo].[RequestTime].[ResourceId], [dbo].[RequestTime].[StartTime], ([dbo].[RequestTime].[RegularHours] + [dbo].[RequestTime].[AdjustedRegularHours] + [dbo].[RequestTime].[OvertimeHours] + [dbo].[RequestTime].[AdjustedOvertimeHours]) AS RegularHours, [dbo].[RequestTime].[ApprovalStatus], [dbo].[RequestTime].[Billable], CAST((CEILING((CAST([RequestTime].[StartTime] AS Numeric)+3) / 7)*7)-3 AS DateTime) AS WeekEnding, [dbo].[RequestTime].[CertificationDate], DATEADD (Hour, 30, CAST((CEILING((CAST([RequestTime].[StartTime] AS Numeric)+3) / 7)*7)-3 AS DateTime)) AS DueDate, 1 AS AffectUtilization, CAST ([dbo].[RequestTime].[Description] AS Varchar(200)) AS Description
FROM [dbo].[RequestTime] WITH (nolock)
WHERE  [dbo].[RequestTime].[Billable] = 1 AND  [dbo].[RequestTime].[AdjustmentTimeParent] IS NULL
UNION
SELECT '**INTERNAL SUPPORT TIME**' AS TimeType,  [dbo].[RequestTime].[CustomerId], [dbo].[RequestTime].[EngagementId], '{00000000-0000-0000-0000-000000000000}' AS ProjectId, '{00000000-0000-0000-0000-000000000000}' AS [TaskId], [dbo].[RequestTime].[WorkgroupId], [dbo].[RequestTime].[ResourceId], [dbo].[RequestTime].[StartTime], ([dbo].[RequestTime].[RegularHours] + [dbo].[RequestTime].[AdjustedRegularHours] + [dbo].[RequestTime].[OvertimeHours] + [dbo].[RequestTime].[AdjustedOvertimeHours]) AS RegularHours, [dbo].[RequestTime].[ApprovalStatus], [dbo].[RequestTime].[Billable], CAST((CEILING((CAST([RequestTime].[StartTime] AS Numeric)+3) / 7)*7)-3 AS DateTime) AS WeekEnding, [dbo].[RequestTime].[CertificationDate], DATEADD (Hour, 30, CAST((CEILING((CAST([RequestTime].[StartTime] AS Numeric)+3) / 7)*7)-3 AS DateTime)) AS DueDate, 0 AS AffectUtilization, CAST ([dbo].[RequestTime].[Description] AS Varchar(200)) AS Description
FROM [dbo].[RequestTime] WITH (nolock)
WHERE  [dbo].[RequestTime].[Billable] = 0 AND  [dbo].[RequestTime].[AdjustmentTimeParent] IS NULL





















GO
