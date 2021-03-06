USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_Time_and_Writeoff_with_Effective_BillingRate_CG]    Script Date: 10/14/2019 3:40:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE view [dbo].[BG_Time_and_Writeoff_with_Effective_BillingRate_CG] as
with a as (
select
	e.Name as Engagement,
	r.Name as Resource,
	r.ResourceId,
	tw.TimeId,
	t.Name as Task,
	--ebr.Description as RoleType,
	Type as ViewSectionType,
	convert(date, tw.TimeDate) as TimeDate,
	--ebr.RateStartDate,
	--ebr.RateEndDate,
	coalesce(tw.RegularHours,0) as RegularHours,
	tw.AdjustedRegularHours,
	coalesce(tw.OvertimeHours,0) as OvertimeHours,
	tw.AdjustedOvertimeHours,
	tw.ApprovalStatus,
	tw.Billable,
	coalesce(tw.HourlyCostRate,0) as HourlyCostRate,
	coalesce(tw.CostRate,0) as CostRate,
	--coalesce(tw.RevRec,0) as tw_RevRec,
	coalesce(tw.RevRec,0) as RevRec,
	--case when coalesce(tw.AdjustedRegularHours,0)<0 then 0 else coalesce(tw.RevRec,0) end as RevRec,
	tw.BatchNumber,
	coalesce(tw.BillingRate,0) as tw_BillingRate,
	--case when tw.BillingRate =-1 then tw.BillingRate else coalesce(ebr.BillingRate,tw.BillingRate) end as BillingRate,
	--coalesce(ebr.BillingRate,0) as EngagementBillingRate,
	coalesce(tw.BillingRate,0) as TimeBillingRate,
	--coalesce((select top 1 ebr1.BillingRate from [BG_EngagementBillingRates_All_CG] ebr1 where tw.EngagementId=ebr1.EngagementId and ta.BillingRole=ebr1.BillingRoleId and convert(date, tw.TimeDate)>=convert(date, ebr1.RateStartDate) and convert(date, tw.TimeDate)<=convert(date, ebr1.RateEndDate)),tw.BillingRate) as BillingRate,
	--coalesce(ebr.BillingRate,tw.BillingRate) as BillingRate,
	(select BillingRate from [BG_EngagementBillingRate_CG](tw.EngagementId, ta.BillingRole, tw.TimeDate)) as eBillingRate,
	coalesce(tw.OvertimeBillingRate,0) as OvertimeBillingRate,
	coalesce(tw.AmountWrittenOff,0) as AmountWrittenOff,
	coalesce(tw.RateTimesHours,0) as tw_RateTimesHours,
	--(((coalesce(tw.RegularHours,0) + case when coalesce(tw.AdjustedRegularHours,0)<0 then 0 else coalesce(tw.AdjustedRegularHours,0) end) * (coalesce(ebr.BillingRate,tw.BillingRate))) + ((coalesce(tw.OvertimeHours,0) + coalesce(tw.AdjustedOvertimeHours,0)) * (coalesce(ebr.BillingRate,tw.BillingRate)) * ISNULL(e.OvertimePercentage, 100)/100)) AS RateTimesHours,
	--(((coalesce(tw.RegularHours,0) ) * (coalesce((select top 1 ebr1.BillingRate from [BG_EngagementBillingRates_All_CG] ebr1 where tw.EngagementId=ebr1.EngagementId and ta.BillingRole=ebr1.BillingRoleId and convert(date, tw.TimeDate)>=convert(date, ebr1.RateStartDate) and convert(date, tw.TimeDate)<=convert(date, ebr1.RateEndDate)),tw.BillingRate))) + ((coalesce(tw.OvertimeHours,0) ) * (coalesce((select top 1 ebr1.BillingRate from [BG_EngagementBillingRates_All_CG] ebr1 where tw.EngagementId=ebr1.EngagementId and ta.BillingRole=ebr1.BillingRoleId and convert(date, tw.TimeDate)>=convert(date, ebr1.RateStartDate) and convert(date, tw.TimeDate)<=convert(date, ebr1.RateEndDate)),tw.BillingRate)) * ISNULL(e.OvertimePercentage, 100)/100)) AS RateTimesHours,
	--(((coalesce(tw.RegularHours,0) ) * (coalesce(ebr.BillingRate,tw.BillingRate))) + ((coalesce(tw.OvertimeHours,0) ) * (coalesce(ebr.BillingRate,tw.BillingRate)) * ISNULL(e.OvertimePercentage, 100)/100)) AS RateTimesHours,
	e.OvertimePercentage,
	coalesce(e.OvertimePercentage,100) as CoalesceOvertimePercentage,
	ISNULL(e.OvertimePercentage, 100)/100 as calcOverTimePercentage,
	coalesce(tw.GrossProfit,0) as GrossProfit,
	tw.AdjustmentReasonCode,
	tw.CustomerId,
	tw.EngagementId,
	tw.ProjectId,
	tw.TaskId,
	ta.BillingRole,
	tw.ApprovalStatusDate,
      tw.InvoiceStatus,
      tw.BillableMultiplier,
      tw.RevRate,
      tw.RevTent,
      tw.RevRecDate,
      tw.DrGL,
      tw.CrGL,
      tw.JobCostCtr,
      tw.PartialRecognized,
      tw.Locked,
      tw.AdjustmentTimeStatus,
      tw.AdjustmentTimeParent,
      tw.FixedFeeId,
      tw.RevFixedFeeId,
      tw.BillingOfficeID,
      tw.InvoiceID,
      tw.AppliedRate,
      tw.ReasonID,
      tw.Description,
      tw.Year,
      tw.Month,
      tw.MonthName,
      tw.WeekNumber,
      tw.ResourceCostCenter,
      tw.ResourceCostCenterSegment2,
      tw.ResourceCostCenterSegment3,
      tw.ProjectCostCenter,
      tw.ProjectCostCenterSegment2,
      tw.ProjectCostCenterSegment3,
      tw.TransferFlag,
      tw.CostCenter,
	  tw.SubmittedForApproval,
	  tw.CertificationDate
from
	BG_Time_and_WriteOff_with_Type_TimeId_AdjTimeParent_VIEW tw with (nolock)
		join
	Engagement e with (nolock) on tw.EngagementId=e.EngagementId
		left outer join
	Tasks t with (nolock) on tw.EngagementId=t.EngagementId and tw.TaskId=t.TaskId	
		left outer join
	Resources r with (nolock) on tw.ResourceId=r.ResourceId  
		left outer join
	TaskAssignment ta with (nolock) on tw.TaskId=ta.TaskId and tw.ResourceId=ta.ResourceId and ta.Deleted=0
)
SELECT 
	   [Engagement]
      ,[Resource]
      ,[ResourceId]
      ,[TimeId]
      ,[Task]
      ,[ViewSectionType]
      ,[TimeDate]
      ,[RegularHours]
      ,[AdjustedRegularHours]
      ,[OvertimeHours]
      ,[AdjustedOvertimeHours]
      ,[ApprovalStatus]
      ,[Billable]
      ,[HourlyCostRate]
      ,[CostRate]
      ,[RevRec]
      ,[BatchNumber]
      ,[tw_BillingRate]
      ,[TimeBillingRate]
	  ,eBillingRate as EngagementBillingRate
      ,coalesce([eBillingRate], [tw_BillingRate]) as BillingRate
      ,[OvertimeBillingRate]
      ,[AmountWrittenOff]
      ,[tw_RateTimesHours]
	  ,	(((coalesce(RegularHours,0) ) * coalesce(eBillingRate,tw_BillingRate)) + ((coalesce(OvertimeHours,0) ) * coalesce(eBillingRate,tw_BillingRate) * ISNULL(OvertimePercentage, 100)/100)) AS RateTimesHours
	  --,	(((coalesce(RegularHours,0) ) * (coalesce([eBillingRate], tw_BillingRate))) + ((OvertimeHours ) * (coalesce([eBillingRate], tw_BillingRate)) * [calcOverTimePercentage])) AS RateTimesHours
      ,[OvertimePercentage]
      ,[CoalesceOvertimePercentage]
      ,[calcOverTimePercentage]
      ,[GrossProfit]
      ,[AdjustmentReasonCode]
      ,[CustomerId]
      ,[EngagementId]
      ,[ProjectId]
      ,[TaskId]
	  ,BillingRole
      ,[ApprovalStatusDate]
      ,[InvoiceStatus]
      ,[BillableMultiplier]
      ,[RevRate]
      ,[RevTent]
      ,[RevRecDate]
      ,[DrGL]
      ,[CrGL]
      ,[JobCostCtr]
      ,[PartialRecognized]
      ,[Locked]
      ,[AdjustmentTimeStatus]
      ,[AdjustmentTimeParent]
      ,[FixedFeeId]
      ,[RevFixedFeeId]
      ,[BillingOfficeID]
      ,[InvoiceID]
      ,[AppliedRate]
      ,[ReasonID]
      ,[Description]
      ,[Year]
      ,[Month]
      ,[MonthName]
      ,[WeekNumber]
      ,[ResourceCostCenter]
      ,[ResourceCostCenterSegment2]
      ,[ResourceCostCenterSegment3]
      ,[ProjectCostCenter]
      ,[ProjectCostCenterSegment2]
      ,[ProjectCostCenterSegment3]
      ,[TransferFlag]
      ,[CostCenter]
	  ,SubmittedForApproval
	  ,CertificationDate
  FROM a



GO
