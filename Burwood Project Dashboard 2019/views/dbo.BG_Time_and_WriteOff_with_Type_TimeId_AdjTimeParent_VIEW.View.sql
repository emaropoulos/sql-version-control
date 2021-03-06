USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_Time_and_WriteOff_with_Type_TimeId_AdjTimeParent_VIEW]    Script Date: 9/30/2019 5:00:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO



















/****** Object:  View dbo.BG_Time_and_WriteOff_VIEW    Script Date: 6/20/2007 1:07:01 PM ******/
CREATE VIEW [dbo].[BG_Time_and_WriteOff_with_Type_TimeId_AdjTimeParent_VIEW] AS

SELECT 
	'Contractor Project Time' as Type,
	dbo.Time.TimeId,
	dbo.Time.RegularHours as RegHours,
	dbo.Time.OvertimeHours as OtHours,
	dbo.Time.AdjustedOvertimeHours,
	dbo.Time.CustomerId, 
	dbo.Time.EngagementId, 
	dbo.Time.ProjectId, 
	dbo.Time.TaskId, 
	dbo.Time.ResourceId, 
	dbo.Time.TimeDate, 
	(dbo.Time.RegularHours + dbo.Time.AdjustedRegularHours) AS RegularHours, 
	(dbo.Time.OvertimeHours + dbo.Time.AdjustedOvertimeHours) AS OvertimeHours, 
	dbo.Time.ApprovalStatus, 
	dbo.Time.ApprovalStatusDate, 
	dbo.Time.InvoiceStatus, 
	dbo.Time.Billable, 
	ISDATE(dbo.Time.RevRecDate) AS BillableMultiplier,
	dbo.Time.HourlyCostRate, 
	dbo.Time.RevRate, dbo.Time.RevTent, dbo.Time.RevRec, dbo.Time.RevRecDate, dbo.Time.DrGL, dbo.Time.CrGL, 
	dbo.Time.JobCostCtr, dbo.Time.BatchNumber, dbo.Time.PartialRecognized, dbo.Time.Locked, dbo.Time.AdjustmentTimeStatus, 
	dbo.Time.AdjustmentTimeParent, dbo.Time.AdjustedRegularHours, dbo.Time.BillingRate, (dbo.Time.BillingRate * ISNULL(dbo.Engagement.OvertimePercentage, 100)/100) AS OvertimeBillingRate, dbo.Time.CostRate, dbo.Time.FixedFeeId, 
	dbo.Time.RevFixedFeeId, dbo.WriteOffTime.BillingOfficeID, dbo.WriteOffTime.InvoiceID, dbo.WriteOffTime.AppliedRate, 
	(dbo.WriteOffTime.AmountWrittenOff * dbo.WriteOffTime.AppliedRate) AS AmountWrittenOff, dbo.WriteOffTime.ReasonID, NULL AS Description, YEAR(Time.TimeDate) AS Year, CAST (MONTH(Time.TimeDate) AS varchar(3)) AS Month,
	DATENAME(MONTH, Time.TimeDate) AS MonthName, ROUND(((DATEDIFF(day,5,Time.TimeDate))/7),0) AS WeekNumber, 
	(((dbo.Time.RegularHours + dbo.Time.AdjustedRegularHours) * dbo.Time.BillingRate) + ((dbo.Time.OvertimeHours + dbo.Time.AdjustedOvertimeHours) * dbo.Time.BillingRate * ISNULL(dbo.Engagement.OvertimePercentage, 100)/100)) AS RateTimesHours,
	ResourceCostCenters.[Name] AS ResourceCostCenter, ResourceCostCenters.[Segment2] AS ResourceCostCenterSegment2, ResourceCostCenters.[Segment3] AS ResourceCostCenterSegment3,
	ProjectCostCenters.[Name] AS ProjectCostCenter, ProjectCostCenters.[Segment2] AS ProjectCostCenterSegment2, ProjectCostCenters.[Segment3] AS ProjectCostCenterSegment3, 0 AS TransferFlag, ProjectCostCenters.[Name] AS CostCenter,
	((ISNULL(dbo.WriteOffTime.AmountWrittenOff,0) * ISNULL(dbo.WriteOffTime.AppliedRate,0))+ ISNULL(dbo.Time.RevRec,0) -(ISNULL((dbo.Time.RegularHours + dbo.Time.AdjustedRegularHours + dbo.Time.OvertimeHours + dbo.Time.AdjustedOvertimeHours),0) * ISNULL(dbo.Time.HourlyCostRate,0))) AS GrossProfit,
	NULL AS AdjustmentReasonCode,
	dbo.Time.SubmittedForApproval,
	cast(dbo.Time.CertificationDate as date) as CertificationDate
FROM dbo.Time  WITH (nolock) 
LEFT OUTER JOIN dbo.Engagement  WITH (nolock) ON dbo.Time.EngagementId = dbo.Engagement.EngagementId
LEFT OUTER JOIN dbo.WriteOffTime  WITH (nolock) ON dbo.Time.TimeId = dbo.WriteOffTime.TimeID
LEFT OUTER JOIN dbo.Resources WITH (nolock) ON dbo.Time.ResourceId = dbo.Resources.ResourceId
LEFT OUTER JOIN dbo.CostCenters ResourceCostCenters WITH (nolock) ON dbo.Resources.CostCenterId = ResourceCostCenters.CostCenter
LEFT OUTER JOIN dbo.Project WITH (nolock) ON dbo.Time.ProjectId = dbo.Project.ProjectId
LEFT OUTER JOIN dbo.CostCenters ProjectCostCenters WITH (nolock) ON dbo.Project.CostCenterId = ProjectCostCenters.CostCenter
WHERE ResourceCostCenters.[Name] <> ProjectCostCenters.[Name] AND Resources.EmployeeType = 'CO' AND Time.InvoiceStatus <3 AND [dbo].[Time].[AdjustmentTimeParent] IS NULL
UNION ALL

SELECT 
	'Burwood Project Time' as Type,
	dbo.Time.TimeId,
	dbo.Time.RegularHours as RegHours,
	dbo.Time.OvertimeHours as OtHours,
	dbo.Time.AdjustedOvertimeHours,
	dbo.Time.CustomerId, dbo.Time.EngagementId, dbo.Time.ProjectId, dbo.Time.TaskId, dbo.Time.ResourceId, dbo.Time.TimeDate, 
	(dbo.Time.RegularHours + dbo.Time.AdjustedRegularHours) AS RegularHours, (dbo.Time.OvertimeHours + dbo.Time.AdjustedOvertimeHours) AS OvertimeHours, 
	dbo.Time.ApprovalStatus, dbo.Time.ApprovalStatusDate, dbo.Time.InvoiceStatus, dbo.Time.Billable, ISDATE(dbo.Time.RevRecDate) AS BillableMultiplier,
	dbo.Time.HourlyCostRate, dbo.Time.RevRate, dbo.Time.RevTent, dbo.Time.RevRec, dbo.Time.RevRecDate, dbo.Time.DrGL, dbo.Time.CrGL, 
	dbo.Time.JobCostCtr, dbo.Time.BatchNumber, dbo.Time.PartialRecognized, dbo.Time.Locked, dbo.Time.AdjustmentTimeStatus, 
	dbo.Time.AdjustmentTimeParent, dbo.Time.AdjustedRegularHours, dbo.Time.BillingRate, (dbo.Time.BillingRate * ISNULL(dbo.Engagement.OvertimePercentage, 100)/100) AS OvertimeBillingRate, dbo.Time.CostRate, dbo.Time.FixedFeeId, 
	dbo.Time.RevFixedFeeId, dbo.WriteOffTime.BillingOfficeID, dbo.WriteOffTime.InvoiceID, dbo.WriteOffTime.AppliedRate, 
	(dbo.WriteOffTime.AmountWrittenOff * dbo.WriteOffTime.AppliedRate) AS AmountWrittenOff, dbo.WriteOffTime.ReasonID, NULL AS Description, YEAR(Time.TimeDate) AS Year, CAST (MONTH(Time.TimeDate) AS varchar(3)) AS Month,
	DATENAME(MONTH, Time.TimeDate) AS MonthName, ROUND(((DATEDIFF(day,5,Time.TimeDate))/7),0) AS WeekNumber, 
	(((dbo.Time.RegularHours + dbo.Time.AdjustedRegularHours) * dbo.Time.BillingRate) + ((dbo.Time.OvertimeHours + dbo.Time.AdjustedOvertimeHours) * dbo.Time.BillingRate * ISNULL(dbo.Engagement.OvertimePercentage, 100)/100)) AS RateTimesHours,
	ResourceCostCenters.[Name] AS ResourceCostCenter, ResourceCostCenters.[Segment2] AS ResourceCostCenterSegment2, ResourceCostCenters.[Segment3] AS ResourceCostCenterSegment3,
	ProjectCostCenters.[Name] AS ProjectCostCenter, ProjectCostCenters.[Segment2] AS ProjectCostCenterSegment2, ProjectCostCenters.[Segment3] AS ProjectCostCenterSegment3, 1 AS TransferFlag, ResourceCostCenters.[Name] AS CostCenter,
	((ISNULL(dbo.WriteOffTime.AmountWrittenOff,0) * ISNULL(dbo.WriteOffTime.AppliedRate,0))+ ISNULL(dbo.Time.RevRec,0) -(ISNULL((dbo.Time.RegularHours + dbo.Time.AdjustedRegularHours + dbo.Time.OvertimeHours + dbo.Time.AdjustedOvertimeHours),0) * ISNULL(dbo.Time.HourlyCostRate,0))) AS GrossProfit,
	NULL AS AdjustmentReasonCode,
	dbo.Time.SubmittedForApproval,
	cast(dbo.Time.CertificationDate as date) as CertificationDate
FROM dbo.Time  WITH (nolock) 
LEFT OUTER JOIN dbo.Engagement  WITH (nolock) ON dbo.Time.EngagementId = dbo.Engagement.EngagementId
LEFT OUTER JOIN dbo.WriteOffTime  WITH (nolock) ON dbo.Time.TimeId = dbo.WriteOffTime.TimeID
LEFT OUTER JOIN dbo.Resources WITH (nolock) ON dbo.Time.ResourceId = dbo.Resources.ResourceId
LEFT OUTER JOIN dbo.CostCenters ResourceCostCenters WITH (nolock) ON dbo.Resources.CostCenterId = ResourceCostCenters.CostCenter
LEFT OUTER JOIN dbo.Project WITH (nolock) ON dbo.Time.ProjectId = dbo.Project.ProjectId
LEFT OUTER JOIN dbo.CostCenters ProjectCostCenters WITH (nolock) ON dbo.Project.CostCenterId = ProjectCostCenters.CostCenter
WHERE 
	((ResourceCostCenters.[Name] <> ProjectCostCenters.[Name]) or ProjectCostCenters.[Name] is NULL)
	AND Resources.EmployeeType <> 'CO' 
	AND Time.InvoiceStatus <3 
	AND [dbo].[Time].[AdjustmentTimeParent] IS NULL
UNION ALL

SELECT 
	'Burwwod and Contractor Project Time' as Type,
	dbo.Time.TimeId,
	dbo.Time.RegularHours as RegHours,
	dbo.Time.OvertimeHours as OtHours,
	dbo.Time.AdjustedOvertimeHours,
	dbo.Time.CustomerId, 
	dbo.Time.EngagementId, 
	dbo.Time.ProjectId, 
	dbo.Time.TaskId, 
	dbo.Time.ResourceId, 
	dbo.Time.TimeDate, 
	(dbo.Time.RegularHours + dbo.Time.AdjustedRegularHours) AS RegularHours, 
	(dbo.Time.OvertimeHours + dbo.Time.AdjustedOvertimeHours) AS OvertimeHours, 
	dbo.Time.ApprovalStatus, 
	dbo.Time.ApprovalStatusDate, 
	dbo.Time.InvoiceStatus, 
	dbo.Time.Billable, ISDATE(dbo.Time.RevRecDate) AS BillableMultiplier,
	dbo.Time.HourlyCostRate, dbo.Time.RevRate, dbo.Time.RevTent, dbo.Time.RevRec, dbo.Time.RevRecDate, dbo.Time.DrGL, dbo.Time.CrGL, 
	dbo.Time.JobCostCtr, dbo.Time.BatchNumber, dbo.Time.PartialRecognized, dbo.Time.Locked, dbo.Time.AdjustmentTimeStatus, 
	dbo.Time.AdjustmentTimeParent, dbo.Time.AdjustedRegularHours, dbo.Time.BillingRate, (dbo.Time.BillingRate * ISNULL(dbo.Engagement.OvertimePercentage, 100)/100) AS OvertimeBillingRate, dbo.Time.CostRate, dbo.Time.FixedFeeId, 
	dbo.Time.RevFixedFeeId, dbo.WriteOffTime.BillingOfficeID, dbo.WriteOffTime.InvoiceID, dbo.WriteOffTime.AppliedRate, 
	(dbo.WriteOffTime.AmountWrittenOff * dbo.WriteOffTime.AppliedRate) AS AmountWrittenOff, dbo.WriteOffTime.ReasonID, NULL AS Description, YEAR(Time.TimeDate) AS Year, CAST (MONTH(Time.TimeDate) AS varchar(3)) AS Month,
	DATENAME(MONTH, Time.TimeDate) AS MonthName, ROUND(((DATEDIFF(day,5,Time.TimeDate))/7),0) AS WeekNumber, 
	(((dbo.Time.RegularHours + dbo.Time.AdjustedRegularHours) * dbo.Time.BillingRate) + ((dbo.Time.OvertimeHours + dbo.Time.AdjustedOvertimeHours) * dbo.Time.BillingRate * ISNULL(dbo.Engagement.OvertimePercentage, 100)/100)) AS RateTimesHours,
	ResourceCostCenters.[Name] AS ResourceCostCenter, ResourceCostCenters.[Segment2] AS ResourceCostCenterSegment2, ResourceCostCenters.[Segment3] AS ResourceCostCenterSegment3,
	ProjectCostCenters.[Name] AS ProjectCostCenter, ProjectCostCenters.[Segment2] AS ProjectCostCenterSegment2, ProjectCostCenters.[Segment3] AS ProjectCostCenterSegment3, 0 AS TransferFlag, ResourceCostCenters.[Name] AS CostCenter,
	((ISNULL(dbo.WriteOffTime.AmountWrittenOff,0) * ISNULL(dbo.WriteOffTime.AppliedRate,0))+ ISNULL(dbo.Time.RevRec,0) -(ISNULL((dbo.Time.RegularHours + dbo.Time.AdjustedRegularHours + dbo.Time.OvertimeHours + dbo.Time.AdjustedOvertimeHours),0) * ISNULL(dbo.Time.HourlyCostRate,0))) AS GrossProfit,
	NULL AS AdjustmentReasonCode,
	dbo.Time.SubmittedForApproval,
	cast(dbo.Time.CertificationDate as date) as CertificationDate
FROM dbo.Time  WITH (nolock) 
LEFT OUTER JOIN dbo.Engagement  WITH (nolock) ON dbo.Time.EngagementId = dbo.Engagement.EngagementId
LEFT OUTER JOIN dbo.WriteOffTime  WITH (nolock) ON dbo.Time.TimeId = dbo.WriteOffTime.TimeID
LEFT OUTER JOIN dbo.Resources WITH (nolock) ON dbo.Time.ResourceId = dbo.Resources.ResourceId
LEFT OUTER JOIN dbo.CostCenters ResourceCostCenters WITH (nolock) ON dbo.Resources.CostCenterId = ResourceCostCenters.CostCenter
LEFT OUTER JOIN dbo.Project WITH (nolock) ON dbo.Time.ProjectId = dbo.Project.ProjectId
LEFT OUTER JOIN dbo.CostCenters ProjectCostCenters WITH (nolock) ON dbo.Project.CostCenterId = ProjectCostCenters.CostCenter
WHERE ResourceCostCenters.[Name] = ProjectCostCenters.[Name] AND Time.InvoiceStatus <3 AND [dbo].[Time].[AdjustmentTimeParent] IS NULL

UNION ALL

SELECT 
	'RR Adjustment' as Type,
	NULL as TimeId,
	0 as RegHours,
	0 as OtHours,
	0 as AdjustedOvertimeHours,
	Engagement.CustomerId, 
	RevenueDetail.EngagementID, 
	NULL, 
	NULL, 
	'{903E91C5-3314-4159-B050-DC3FDEDA9A66}', 
	RevenueDetail.PostingDate, 
	0, 
	0, 
	NULL, 
	NULL, 
	NULL, 
	1, 1, 0, 0, NULL, RevenueDetail.RevenueAmount, RevenueDetail.PostingDate, RevenueDetail.DrGL, RevenueDetail.CrGL,
	NULL, 'RR Adjustment', NULL, NULL, NULL, NULL, 0, 0, 0, 0, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL,
	YEAR(RevenueDetail.PostingDate) AS Year, CAST (MONTH(RevenueDetail.PostingDate) AS varchar(3)) AS Month,
	DATENAME(MONTH, RevenueDetail.PostingDate) AS MonthName, ROUND(((DATEDIFF(day,5,RevenueDetail.PostingDate))/7),0) AS WeekNumber, 0,
	ProjectCostCenters.[Name] AS ResourceCostCenter, ProjectCostCenters.[Segment2] AS ResourceCostCenterSegment2, ProjectCostCenters.[Segment3] AS ResourceCostCenterSegment3,
	ProjectCostCenters.[Name] AS ProjectCostCenter, ProjectCostCenters.[Segment2] AS ProjectCostCenterSegment2, ProjectCostCenters.[Segment3] AS ProjectCostCenterSegment3, 0 AS TransferFlag, ProjectCostCenters.[Name] AS CostCenter,
	RevenueDetail.RevenueAmount AS GrossProfit, RevRecAdjCodes.Description, NULL,
	cast(RevenueDetail.PostingDate as date) as CertificationDate
FROM RevenueDetail WITH (nolock)
LEFT OUTER JOIN Engagement  WITH (nolock) ON RevenueDetail.EngagementID = Engagement.EngagementId
LEFT OUTER JOIN dbo.CostCenters ProjectCostCenters WITH (nolock) ON dbo.Engagement.CostCenterId = ProjectCostCenters.CostCenter
LEFT OUTER JOIN dbo.RevRecAdjCodes ON RevenueDetail.ReasonCode = RevRecAdjCodes.RRARCID
WHERE (RevenueDetail.AdjustmentType <> 0)
UNION ALL

SELECT 
	'PPC Recognition' as Type,
	NULL as TimeId,
	0 as RegHours,
	0 as OtHours,
	0 as AdjustedOvertimeHours,
	Engagement.CustomerId, 
	RevenueDetail.EngagementID, 
	NULL, 
	NULL, 
	'{903E91C5-3314-4159-B050-DC3FDEDA9A66}', 
	RevenueDetail.PostingDate, 
	0, 
	0, 
	NULL, 
	NULL, 
	NULL, 
	1, 1, 0, 0, NULL, RevenueDetail.RevenueAmount, RevenueDetail.PostingDate, RevenueDetail.DrGL, RevenueDetail.CrGL,
	NULL, 'PPC Recognition', NULL, NULL, NULL, NULL, 0, 0, 0, 0, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL,
	YEAR(RevenueDetail.PostingDate) AS Year, CAST (MONTH(RevenueDetail.PostingDate) AS varchar(3)) AS Month,
	DATENAME(MONTH, RevenueDetail.PostingDate) AS MonthName, ROUND(((DATEDIFF(day,5,RevenueDetail.PostingDate))/7),0) AS WeekNumber, 0,
	ProjectCostCenters.[Name] AS ResourceCostCenter, ProjectCostCenters.[Segment2] AS ResourceCostCenterSegment2, ProjectCostCenters.[Segment3] AS ResourceCostCenterSegment3,
	ProjectCostCenters.[Name] AS ProjectCostCenter, ProjectCostCenters.[Segment2] AS ProjectCostCenterSegment2, ProjectCostCenters.[Segment3] AS ProjectCostCenterSegment3, 0 AS TransferFlag, ProjectCostCenters.[Name] AS CostCenter,
	RevenueDetail.RevenueAmount AS GrossProfit, NULL AS AdjustmentReasonCode, NULL,
	cast(RevenueDetail.PostingDate as date) as CertificationDate
FROM RevenueDetail WITH (nolock)
LEFT OUTER JOIN Engagement  WITH (nolock) ON RevenueDetail.EngagementID = Engagement.EngagementId
LEFT OUTER JOIN FixedFeeSchedule  WITH (nolock) ON RevenueDetail.FixedFeeId = FixedFeeSchedule.FixedFeeId
LEFT OUTER JOIN dbo.CostCenters ProjectCostCenters WITH (nolock) ON dbo.Engagement.CostCenterId = ProjectCostCenters.CostCenter
WHERE (FixedFeeSchedule.RevenueMethod <> 1 AND RevenueDetail.AdjustmentType = 0)

UNION ALL



SELECT 
	'Standard Task Time' as Type,
	StandardTaskTime.TimeId as TimeId,
	dbo.StandardTaskTime.RegularHours as RegHours,
	dbo.StandardTaskTime.OvertimeHours as OtHours,
	dbo.StandardTaskTime.AdjustedOvertimeHours,
	Engagement.CustomerId, 
	Engagement.EngagementId, 
	NULL, 
	NULL, 
	StandardTaskTime.ResourceId, 
	StandardTaskTime.DateBooked, 
	(dbo.StandardTaskTime.RegularHours + dbo.StandardTaskTime.AdjustedRegularHours) AS RegularHours, 
	(dbo.StandardTaskTime.OvertimeHours + dbo.StandardTaskTime.AdjustedOvertimeHours) AS OvertimeHours, 
	StandardTaskTime.ApprovalStatus, 
	StandardTaskTime.ApprovalStatusDate, 
	NULL, 
	0, 
	0, CAST(SUBSTRING(MAX(CONVERT(char(8), ResourceRate.EffectiveDate, 112) + CONVERT(char(10), ResourceRate.HourlyCostRate)), 9, 10) AS Numeric) AS HourlyCostRate, 0, 0, 0 AS RevRec, NULL, NULL, NULL,
	NULL, StandardTask.Name, NULL, NULL, NULL AS AdjustmentStatus, NULL, StandardTaskTime.AdjustedRegularHours, 0, 0, CAST(SUBSTRING(MAX(CONVERT(char(8), ResourceRate.EffectiveDate, 112) + CONVERT(char(10), ResourceRate.HourlyCostRate)), 9, 10) AS Numeric) AS CostRate, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL,
	YEAR(StandardTaskTime.DateBooked) AS Year, CAST (MONTH(StandardTaskTime.DateBooked) AS varchar(3)) AS Month,
	DATENAME(MONTH, StandardTaskTime.DateBooked) AS MonthName, ROUND(((DATEDIFF(day,5,StandardTaskTime.DateBooked))/7),0) AS WeekNumber, 0,
	ResourceCostCenters.[Name] AS ResourceCostCenter, ResourceCostCenters.[Segment2] AS ResourceCostCenterSegment2, ResourceCostCenters.[Segment3] AS ResourceCostCenterSegment3,
	ProjectCostCenters.[Name] AS ProjectCostCenter, ProjectCostCenters.[Segment2] AS ProjectCostCenterSegment2, ProjectCostCenters.[Segment3] AS ProjectCostCenterSegment3, 1 AS TransferFlag, ResourceCostCenters.[Name] AS CostCenter, 0, NULL AS AdjustmentReasonCode,
	StandardTaskTime.SubmittedForApproval,
	cast(dbo.StandardTaskTime.CertificationDate as date) as CertificationDate
FROM StandardTaskTime WITH (nolock)
INNER JOIN StandardTask  WITH (nolock) ON StandardTaskTime.TaskId = StandardTask.TaskId
INNER JOIN dbo.Resources TimeApproverResource WITH (nolock) ON dbo.StandardTask.SecondLevelApprovalId = TimeApproverResource.ResourceId
INNER JOIN dbo.CostCenters ProjectCostCenters WITH (nolock) ON TimeApproverResource.CostCenterId = ProjectCostCenters.CostCenter
INNER JOIN dbo.Resources WITH (nolock) ON dbo.StandardTaskTime.ResourceId = dbo.Resources.ResourceId
INNER JOIN dbo.CostCenters ResourceCostCenters WITH (nolock) ON dbo.Resources.CostCenterId = ResourceCostCenters.CostCenter
LEFT OUTER JOIN dbo.ResourceRate WITH (nolock) ON StandardTaskTime.ResourceId = ResourceRate.ResourceId
LEFT OUTER JOIN dbo.UDFCode WITH (nolock) ON TimeApproverResource.ResourceId = UDFCode.EntityId AND UDFCode.ItemName = 'ResourceCode1'
LEFT OUTER JOIN dbo.CodeDetail WITH (nolock) ON UDFCode.UDFCode = CodeDetail.CodeDetail
LEFT OUTER JOIN dbo.BillingOffice WITH (nolock) ON CodeDetail.Description = BillingOffice.Description AND BillingOffice.Deleted = 0
LEFT OUTER JOIN dbo.Engagement WITH (nolock) ON BillingOffice.BillingOfficeId = Engagement.BillingOfficeId AND Engagement.Name LIKE 'Regional Promo-%' AND Engagement.EngagementStatus = 'W'
WHERE (StandardTask.VacationTask = 1 AND ResourceCostCenters.[Name] <> ProjectCostCenters.[Name] AND ResourceRate.Active = 1 AND ResourceRate.EffectiveDate <= StandardTaskTime.DateBooked AND [dbo].[StandardTaskTime].[AdjustmentTimeParent] IS NULL AND StandardTaskTime.ApprovalStatus = 'A')
GROUP BY dbo.StandardTaskTime.[AdjustmentTimeParent],
	StandardTaskTime.TimeId, Engagement.CustomerId, Engagement.EngagementId, StandardTaskTime.ResourceId, StandardTaskTime.DateBooked, StandardTaskTime.RegularHours, StandardTaskTime.OvertimeHours, StandardTaskTime.ApprovalStatus, StandardTaskTime.ApprovalStatusDate, StandardTaskTime.AdjustedRegularHours, AdjustedOvertimeHours, StandardTaskTime.DateBooked,
	ResourceCostCenters.[Name], ResourceCostCenters.[Segment2], ResourceCostCenters.[Segment3],
	ProjectCostCenters.[Name], ProjectCostCenters.[Segment2], ProjectCostCenters.[Segment3], StandardTask.Name, 	StandardTaskTime.SubmittedForApproval, convert(date, dbo.StandardTaskTime.CertificationDate)

UNION ALL


SELECT 
	'Contractor Request Time' as Type,
	dbo.RequestTime.RequestTimeId,
	dbo.RequestTime.RegularHours as RegHours,
	dbo.RequestTime.OvertimeHours as OtHours,
	dbo.RequestTime.AdjustedOvertimeHours,
	dbo.RequestTime.CustomerId, 
	dbo.RequestTime.EngagementId, 
	NULL, 
	NULL, 
	dbo.RequestTime.ResourceId, 
	dbo.RequestTime.StartTime, 
	(dbo.RequestTime.RegularHours + dbo.RequestTime.AdjustedRegularHours) AS RegularHours, 
	(dbo.RequestTime.OvertimeHours + dbo.RequestTime.AdjustedOvertimeHours) AS OvertimeHours, 
	dbo.RequestTime.ApprovalStatus, 
	dbo.RequestTime.ApprovalStatusDate, 
	dbo.RequestTime.InvoiceStatus, 
	dbo.RequestTime.Billable, ISDATE(dbo.RequestTime.RevRecDate) AS BillableMultiplier,
	dbo.RequestTime.HourlyCostRate, dbo.RequestTime.RevRate, dbo.RequestTime.RevTent, dbo.RequestTime.RevRec, dbo.RequestTime.RevRecDate, dbo.RequestTime.DrGL, dbo.RequestTime.CrGL, 
	dbo.RequestTime.JobCostCtr, 'Request', dbo.RequestTime.PartialRecognized, dbo.RequestTime.Locked, dbo.RequestTime.AdjustmentTimeStatus, 
	dbo.RequestTime.AdjustmentTimeParent, dbo.RequestTime.AdjustedRegularHours, dbo.RequestTime.BillingRate, (dbo.RequestTime.BillingRate * ISNULL(dbo.Engagement.OvertimePercentage, 100)/100) AS OvertimeBillingRate, dbo.RequestTime.CostRate, dbo.RequestTime.FixedFeeId, 
	dbo.RequestTime.FixedFeeId, NULL, NULL, NULL, NULL,
	NULL, NULL AS Description, YEAR(RequestTime.StartTime) AS Year, CAST (MONTH(RequestTime.StartTime) AS varchar(3)) AS Month,
	DATENAME(MONTH, RequestTime.StartTime) AS MonthName, ROUND(((DATEDIFF(day,5,RequestTime.StartTime))/7),0) AS WeekNumber, 
	(((dbo.RequestTime.RegularHours + dbo.RequestTime.AdjustedRegularHours) * dbo.RequestTime.BillingRate) + ((dbo.RequestTime.OvertimeHours + dbo.RequestTime.AdjustedOvertimeHours) * dbo.RequestTime.BillingRate * ISNULL(dbo.Engagement.OvertimePercentage, 100)/100)) AS RateTimesHours,
	ResourceCostCenters.[Name] AS ResourceCostCenter, ResourceCostCenters.[Segment2] AS ResourceCostCenterSegment2, ResourceCostCenters.[Segment3] AS ResourceCostCenterSegment3,
	ProjectCostCenters.[Name] AS ProjectCostCenter, ProjectCostCenters.[Segment2] AS ProjectCostCenterSegment2, ProjectCostCenters.[Segment3] AS ProjectCostCenterSegment3, 0 AS TransferFlag, ProjectCostCenters.[Name] AS CostCenter,
	((ISNULL(dbo.WriteOffRequestTime.AmountWrittenOff,0) * ISNULL(dbo.WriteOffRequestTime.AppliedRate,0))+ ISNULL(dbo.RequestTime.RevRec,0) -(ISNULL((dbo.RequestTime.RegularHours + dbo.RequestTime.AdjustedRegularHours + dbo.RequestTime.OvertimeHours + dbo.RequestTime.AdjustedOvertimeHours),0) * ISNULL(dbo.RequestTime.HourlyCostRate,0))) AS GrossProfit,
	NULL AS AdjustmentReasonCode,
	dbo.RequestTime.SubmittedForApproval,
	cast(dbo.RequestTime.CertificationDate as date) as CertificationDate
FROM dbo.RequestTime  WITH (nolock) 
LEFT OUTER JOIN dbo.Resources WITH (nolock) ON dbo.RequestTime.ResourceId = dbo.Resources.ResourceId
LEFT OUTER JOIN dbo.CostCenters ResourceCostCenters WITH (nolock) ON dbo.Resources.CostCenterId = ResourceCostCenters.CostCenter
LEFT OUTER JOIN dbo.Engagement WITH (nolock) ON dbo.RequestTime.EngagementId = dbo.Engagement.EngagementId
LEFT OUTER JOIN dbo.CostCenters ProjectCostCenters WITH (nolock) ON dbo.Engagement.CostCenterId = ProjectCostCenters.CostCenter
LEFT OUTER JOIN dbo.WriteOffRequestTime WITH (nolock) ON dbo.RequestTime.RequestTimeId = dbo.WriteOffRequestTime.RequestTimeID
WHERE ResourceCostCenters.[Name] <> ProjectCostCenters.[Name] AND Resources.EmployeeType = 'CO' AND RequestTime.InvoiceStatus <3 AND [dbo].[RequestTime].[AdjustmentTimeParent] IS NULL
UNION ALL

SELECT 
	'Burwood Request Time' as Type,
	dbo.RequestTime.RequestTimeId,
	dbo.RequestTime.RegularHours as RegHours,
	dbo.RequestTime.OvertimeHours as OtHours,
	dbo.RequestTime.AdjustedOvertimeHours,
	dbo.RequestTime.CustomerId, dbo.RequestTime.EngagementId, NULL, NULL, dbo.RequestTime.ResourceId, dbo.RequestTime.StartTime, 
	(dbo.RequestTime.RegularHours + dbo.RequestTime.AdjustedRegularHours) AS RegularHours, (dbo.RequestTime.OvertimeHours + dbo.RequestTime.AdjustedOvertimeHours) AS OvertimeHours, 
	dbo.RequestTime.ApprovalStatus, dbo.RequestTime.ApprovalStatusDate, dbo.RequestTime.InvoiceStatus, dbo.RequestTime.Billable, ISDATE(dbo.RequestTime.RevRecDate) AS BillableMultiplier,
	dbo.RequestTime.HourlyCostRate, dbo.RequestTime.RevRate, dbo.RequestTime.RevTent, dbo.RequestTime.RevRec, dbo.RequestTime.RevRecDate, dbo.RequestTime.DrGL, dbo.RequestTime.CrGL, 
	dbo.RequestTime.JobCostCtr, 'Request', dbo.RequestTime.PartialRecognized, dbo.RequestTime.Locked, dbo.RequestTime.AdjustmentTimeStatus, 
	dbo.RequestTime.AdjustmentTimeParent, dbo.RequestTime.AdjustedRegularHours, dbo.RequestTime.BillingRate, (dbo.RequestTime.BillingRate * ISNULL(dbo.Engagement.OvertimePercentage, 100)/100) AS OvertimeBillingRate, dbo.RequestTime.CostRate, dbo.RequestTime.FixedFeeId, 
	dbo.RequestTime.FixedFeeId, NULL, NULL, NULL, NULL,
	NuLL, NULL AS Description, YEAR(RequestTime.StartTime) AS Year, CAST (MONTH(RequestTime.StartTime) AS varchar(3)) AS Month,
	DATENAME(MONTH, RequestTime.StartTime) AS MonthName, ROUND(((DATEDIFF(day,5,RequestTime.StartTime))/7),0) AS WeekNumber, 
	(((dbo.RequestTime.RegularHours + dbo.RequestTime.AdjustedRegularHours) * dbo.RequestTime.BillingRate) + ((dbo.RequestTime.OvertimeHours + dbo.RequestTime.AdjustedOvertimeHours) * dbo.RequestTime.BillingRate * ISNULL(dbo.Engagement.OvertimePercentage, 100)/100)) AS RateTimesHours,
	ResourceCostCenters.[Name] AS ResourceCostCenter, ResourceCostCenters.[Segment2] AS ResourceCostCenterSegment2, ResourceCostCenters.[Segment3] AS ResourceCostCenterSegment3,
	ProjectCostCenters.[Name] AS ProjectCostCenter, ProjectCostCenters.[Segment2] AS ProjectCostCenterSegment2, ProjectCostCenters.[Segment3] AS ProjectCostCenterSegment3, 1 AS TransferFlag, ProjectCostCenters.[Name] AS CostCenter,
	((ISNULL(dbo.WriteOffRequestTime.AmountWrittenOff,0) * ISNULL(dbo.WriteOffRequestTime.AppliedRate,0))+ ISNULL(dbo.RequestTime.RevRec,0) -(ISNULL((dbo.RequestTime.RegularHours + dbo.RequestTime.AdjustedRegularHours + dbo.RequestTime.OvertimeHours + dbo.RequestTime.AdjustedOvertimeHours),0) * ISNULL(dbo.RequestTime.HourlyCostRate,0))) AS GrossProfit,
	NULL AS AdjustmentReasonCode,
	dbo.RequestTime.SubmittedForApproval,
	cast(dbo.RequestTime.CertificationDate as date) as CertificationDate
FROM dbo.RequestTime  WITH (nolock) 
LEFT OUTER JOIN dbo.Resources WITH (nolock) ON dbo.RequestTime.ResourceId = dbo.Resources.ResourceId
LEFT OUTER JOIN dbo.CostCenters ResourceCostCenters WITH (nolock) ON dbo.Resources.CostCenterId = ResourceCostCenters.CostCenter
LEFT OUTER JOIN dbo.Engagement WITH (nolock) ON dbo.RequestTime.EngagementId = dbo.Engagement.EngagementId
LEFT OUTER JOIN dbo.CostCenters ProjectCostCenters WITH (nolock) ON dbo.Engagement.CostCenterId = ProjectCostCenters.CostCenter
LEFT OUTER JOIN dbo.WriteOffRequestTime WITH (nolock) ON dbo.RequestTime.RequestTimeId = dbo.WriteOffRequestTime.RequestTimeID
WHERE ResourceCostCenters.[Name] <> ProjectCostCenters.[Name] AND Resources.EmployeeType <> 'CO' AND RequestTime.InvoiceStatus <3 AND [dbo].[RequestTime].[AdjustmentTimeParent] IS NULL
UNION ALL

SELECT 
	'Contractor and Burwood Request Time' as Type,
	dbo.RequestTime.RequestTimeId,
	dbo.RequestTime.RegularHours as RegHours,
	dbo.RequestTime.OvertimeHours as OtHours,
	dbo.RequestTime.AdjustedOvertimeHours,
	dbo.RequestTime.CustomerId, dbo.RequestTime.EngagementId, NULL, NULL, dbo.RequestTime.ResourceId, dbo.RequestTime.StartTime, 
	(dbo.RequestTime.RegularHours + dbo.RequestTime.AdjustedRegularHours) AS RegularHours, (dbo.RequestTime.OvertimeHours + dbo.RequestTime.AdjustedOvertimeHours) AS OvertimeHours, 
	dbo.RequestTime.ApprovalStatus, dbo.RequestTime.ApprovalStatusDate, dbo.RequestTime.InvoiceStatus, dbo.RequestTime.Billable, ISDATE(dbo.RequestTime.RevRecDate) AS BillableMultiplier,
	dbo.RequestTime.HourlyCostRate, dbo.RequestTime.RevRate, dbo.RequestTime.RevTent, dbo.RequestTime.RevRec, dbo.RequestTime.RevRecDate, dbo.RequestTime.DrGL, dbo.RequestTime.CrGL, 
	dbo.RequestTime.JobCostCtr, 'Request', dbo.RequestTime.PartialRecognized, dbo.RequestTime.Locked, dbo.RequestTime.AdjustmentTimeStatus, 
	dbo.RequestTime.AdjustmentTimeParent, dbo.RequestTime.AdjustedRegularHours, dbo.RequestTime.BillingRate, (dbo.RequestTime.BillingRate * ISNULL(dbo.Engagement.OvertimePercentage, 100)/100) AS OvertimeBillingRate, dbo.RequestTime.CostRate, dbo.RequestTime.FixedFeeId, 
	dbo.RequestTime.FixedFeeId, NULL, NULL, NULL, NULL,
	NULL, NULL AS Description, YEAR(RequestTime.StartTime) AS Year, CAST (MONTH(RequestTime.StartTime) AS varchar(3)) AS Month,
	DATENAME(MONTH, RequestTime.StartTime) AS MonthName, ROUND(((DATEDIFF(day,5,RequestTime.StartTime))/7),0) AS WeekNumber, 
	(((dbo.RequestTime.RegularHours + dbo.RequestTime.AdjustedRegularHours) * dbo.RequestTime.BillingRate) + ((dbo.RequestTime.OvertimeHours + dbo.RequestTime.AdjustedOvertimeHours) * dbo.RequestTime.BillingRate * ISNULL(dbo.Engagement.OvertimePercentage, 100)/100)) AS RateTimesHours,
	ResourceCostCenters.[Name] AS ResourceCostCenter, ResourceCostCenters.[Segment2] AS ResourceCostCenterSegment2, ResourceCostCenters.[Segment3] AS ResourceCostCenterSegment3,
	ProjectCostCenters.[Name] AS ProjectCostCenter, ProjectCostCenters.[Segment2] AS ProjectCostCenterSegment2, ProjectCostCenters.[Segment3] AS ProjectCostCenterSegment3, 0 AS TransferFlag, ProjectCostCenters.[Name] AS CostCenter,
	((ISNULL(dbo.WriteOffRequestTime.AmountWrittenOff,0) * ISNULL(dbo.WriteOffRequestTime.AppliedRate,0))+ ISNULL(dbo.RequestTime.RevRec,0) -(ISNULL((dbo.RequestTime.RegularHours + dbo.RequestTime.AdjustedRegularHours + dbo.RequestTime.OvertimeHours + dbo.RequestTime.AdjustedOvertimeHours),0) * ISNULL(dbo.RequestTime.HourlyCostRate,0))) AS GrossProfit,
	NULL AS AdjustmentReasonCode,
	dbo.RequestTime.SubmittedForApproval,
	cast(dbo.RequestTime.CertificationDate as date) as CertificationDate
FROM dbo.RequestTime  WITH (nolock) 
LEFT OUTER JOIN dbo.Resources WITH (nolock) ON dbo.RequestTime.ResourceId = dbo.Resources.ResourceId
LEFT OUTER JOIN dbo.CostCenters ResourceCostCenters WITH (nolock) ON dbo.Resources.CostCenterId = ResourceCostCenters.CostCenter
LEFT OUTER JOIN dbo.Engagement WITH (nolock) ON dbo.RequestTime.EngagementId = dbo.Engagement.EngagementId
LEFT OUTER JOIN dbo.CostCenters ProjectCostCenters WITH (nolock) ON dbo.Engagement.CostCenterId = ProjectCostCenters.CostCenter
LEFT OUTER JOIN dbo.WriteOffRequestTime WITH (nolock) ON dbo.RequestTime.RequestTimeId = dbo.WriteOffRequestTime.RequestTimeID
WHERE ResourceCostCenters.[Name] = ProjectCostCenters.[Name] AND RequestTime.InvoiceStatus <3 AND [dbo].[RequestTime].[AdjustmentTimeParent] IS NULL

UNION ALL

SELECT 
	'Managed Services Time' as Type,
	NULL,
	0 as RegHours,
	0 as OtHours,
	0 as AdjustedOvertimeHours,
	A.CustomerId, A.EngagementID, NULL, NULL, '{903E91C5-3314-4159-B050-DC3FDEDA9A66}', A.InvoiceDate, 0, 0, NULL, NULL, NULL, 1, 1, 0, 0, NULL, g.InvoicedCost, A.InvoiceDate, NULL, NULL,
	NULL, 'Managed Services Product', NULL, NULL, NULL, NULL, 0, 0, 0, 0, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL,
	YEAR(A.InvoiceDate) AS Year, CAST (MONTH(A.InvoiceDate) AS varchar(3)) AS Month,
	DATENAME(MONTH, A.InvoiceDate) AS MonthName, ROUND(((DATEDIFF(day,5,A.InvoiceDate))/7),0) AS WeekNumber, 0,
	NULL AS ResourceCostCenter, NULL AS ResourceCostCenterSegment2, NULL AS ResourceCostCenterSegment3,
	NULL AS ProjectCostCenter, NULL AS ProjectCostCenterSegment2, NULL AS ProjectCostCenterSegment3, 0 AS TransferFlag, NULL AS CostCenter,
	(g.InvoicedCost - (g.Quantity * h.ProductNegotiatedCost)) AS GrossProfit, NULL AS AdjustmentReasonCode, NULL,
	cast(A.InvoiceDate as date) as CertificationDate
	FROM 	[Changepoint].[dbo].[Invoice] A WITH (nolock), 
		[Changepoint].[dbo].[Engagement] E WITH (nolock), 
		[Changepoint].[dbo].[InvoicedProduct] G WITH (nolock), 
		[Changepoint].[dbo].[EngagementProduct] H  WITH (nolock)
WHERE A.EngagementId = E.EngagementId AND A.InvoiceId = G.InvoiceId AND G.EngagementProductId = H.EngagementProductId AND 
	(A.Status = 'C' OR A.Status = 'P' OR A.Status = 'PP' OR A.Status = 'S' OR A.Status = 'X') AND A.InvoiceDate > '10/1/2008' 
	
















GO
