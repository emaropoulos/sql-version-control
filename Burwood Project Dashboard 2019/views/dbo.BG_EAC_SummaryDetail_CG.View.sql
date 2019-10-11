USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_EAC_SummaryDetail_CG]    Script Date: 10/10/2019 1:56:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE view [dbo].[BG_EAC_SummaryDetail_CG] as 
select
	r.Description as Region,
	c.Name as Customer,
	e.Name as Engagement,
	p.Name as Project,
	t.Name as Task,
	ta.BillingRole,
	convert(nvarchar(2048), p.Description) as ProjectDescription,
	case when ps.Description='Completed' then 'Completed' else 'Active' end as ProjectStatus,
	bt.Description as BillingType,
	pm.ProjectManager,
	convert(date, p.BaselineStart) BaselineStart,
	convert(date, p.ActualStart) ActualStart,
	convert(date, coalesce(p.BaselineFinish, p.PlannedFinish)) as BaselineFinish,
	convert(date, p.PlannedStart) as PlannedStart,
	convert(date, p.PlannedFinish) as PlannedFinish,
	convert(date, p.ActualFinish) as ActualFinish,
	adj.CloseDate as EngagementCloseDate,
	coalesce(ae.FullName, ae2.FullName) as AccountExecutive,
	coalesce(cd.Description, 'Undefined') as EngagementType,
	coalesce(e.ContractAmount,0) as ContractAmount,
	coalesce(p.LabourBudget,0) as LaborBudget,
	coalesce(p.ExpenseBudget,0) as ExpenseBudget,
	coalesce(p.OtherExpenseBudget,0) as OtherExpenseBudget,
	coalesce(rd.UDFNumber,0) as ContingencyAmount,
	--coalesce(convert(decimal(10,2), u2.UDFText),0) as ContingencyAmount,
	--coalesce(convert(decimal(10,2), u.UDFText),0) as EngagementContingencyAmount,
	coalesce(adj.FixedFeeOverage,0) as FixedFeeOverage,
	coalesce(adj.ContractorAdjustment,0) as ContractorAdjustment,
	coalesce(adj.ExpenseAdjustment,0) as ExpenseAdjustment,
	coalesce(adj.OtherAdjustment,0) as OtherAdjustment,
	coalesce(o.New_cpEstimatedServiceMargin,o2.New_cpEstimatedServiceMargin) BaselineProfitabilityCRM,
	coalesce(o.New_EstimatedProfitability,o2.New_EstimatedProfitability)/100 as BaselineProfitabilityPercentCRM,
	coalesce(p.BaselineHours,0) as BaselineHours,
	coalesce(p.PlannedHours,0) as PlannedHours,
	rsc.Name as Resource,
	(select BillingRate from [BG_EngagementBillingRate_CG](ta.EngagementId, ta.BillingRole, convert(date, ta.ActualStart))) as NegotiatedRate,
	(select BillingRate from [BG_EngagementBillingRate_CG](ta.EngagementId, ta.BillingRole, convert(date, ta.ForecastStart))) as ForecastNegotiatedRate,
	coalesce(ebr.NegotiatedRate,0) as NegotiatedRate1,
	coalesce(ta.ActualHours,0) as ActualHours,
	(select sum(RegularHours+OvertimeHours) from BG_Time_and_Writeoff_with_Effective_BillingRate_CG tw where tw.ResourceId=ta.ResourceId and tw.TaskId=ta.TaskId) as ActualHours1,
	coalesce(ta.PlannedHours,0)*(select BillingRate from [BG_EngagementBillingRate_CG](ta.EngagementId, ta.BillingRole, convert(date, ta.ForecastStart))) as PlannedFees,
	coalesce(ta.PlannedHours,0)*coalesce(ebr.NegotiatedRate,0) as PlannedFees1,
	coalesce(ta.PlannedRemainingHours,0) as PlannedRemainingHours,
	coalesce(ta.PlannedRemainingHours,0)*coalesce((select BillingRate from [BG_EngagementBillingRate_CG](ta.EngagementId, ta.BillingRole, convert(date, ta.ForecastStart))),0) as PlannedRemainingFees,
	coalesce(ta.PlannedRemainingHours,0)*coalesce(ebr.NegotiatedRate,0) as PlannedRemainingFees1,
	
	--(select sum(case when coalesce(RateTimesHours,0)<>0 and round(coalesce(RateTimesHours,0),2)<> coalesce(RevRec,0)
	--	 then RevRec 
	--	 else round(RateTimesHours,2)
	--end) from BG_Time_and_Writeoff_with_Effective_BillingRate_CG tw where tw.ResourceId=ta.ResourceId and tw.TaskId=ta.TaskId) as ActualFees,
	(select sum(RateTimesHours) from BG_Time_and_Writeoff_with_Effective_BillingRate_CG tw where tw.ResourceId=ta.ResourceId and tw.TaskId=ta.TaskId) as ActualFees,
	--coalesce(ta.ActualHours,0)*(select BillingRate from [BG_EngagementBillingRate_CG](ta.EngagementId, ta.BillingRole, convert(date, ta.ActualStart))) as ActualFees,
	coalesce(ta.ActualHours,0)*coalesce(ebr.NegotiatedRate,0) as ActualFees1,
	((coalesce(ta.ActualHours,0)*(select BillingRate from [BG_EngagementBillingRate_CG](ta.EngagementId, ta.BillingRole, convert(date, ta.ActualStart))))+(coalesce(ta.PlannedRemainingHours,0))*coalesce((select BillingRate from [BG_EngagementBillingRate_CG](ta.EngagementId, ta.BillingRole, convert(date, ta.ForecastStart))),0)) as ExpectedFees,
	(coalesce(ta.ActualHours,0)+coalesce(ta.PlannedRemainingHours,0))*coalesce(ebr.NegotiatedRate,0) as ExpectedFees1,
	(coalesce(ta.ActualHours,0)+coalesce(ta.PlannedRemainingHours,0))*coalesce(rr.HourlyCostRate,0) as ExpectedInternalCost,
	e.EngagementId,
	e.OpportunityId,
	p.ProjectId
from
	Project p with (nolock)
		left outer join
	UDFNumber rd with (nolock) on rd.EntityId=p.ProjectId and rd.ItemName='ProjectText11'
		join
	BG_ProjectManager_CG pm with (nolock) on p.ProjectId=pm.ProjectId
		join
	Engagement e with (nolock) on p.EngagementId=e.EngagementId
		join
	BillingOffice r with (nolock) on e.BillingOfficeId=r.BillingOfficeId
		join
	Customer c with (nolock) on e.CustomerId=c.CustomerId
		join
	Tasks t with (nolock) on p.ProjectId=t.ProjectId
		left outer join
	TaskAssignment ta with (nolock) on t.ProjectId=ta.ProjectId and t.TaskId=ta.TaskId
		left outer join
	Resources rsc with (nolock) on ta.ResourceId=rsc.ResourceId
		left outer join 
	dbo.EngagementBillingRates ebr WITH (NOLOCK) on ta.EngagementId=ebr.EngagementId AND ta.BillingRole=ebr.BillingRoleId
		left outer join 
	dbo.DS_AllResourceRate rr WITH (NOLOCK) on ta.ResourceId=rr.ResourceId and rr.EffectiveDate=(select EffectiveDate from dbo.DS_CurrentEffectiveDate where rr.ResourceId=dbo.DS_CurrentEffectiveDate.ResourceId)
		left outer join
	[chil-crm-04].[BurwoodGroupInc_MSCRM].[dbo].[OpportunityBase] o with (nolock) on e.OpportunityId=o.OpportunityId
		left outer join
	[chil-crm-04].[BurwoodGroupInc_MSCRM].[dbo].[SystemUserBase] ae with (nolock) on o.OwnerId=ae.SystemUserId
		left outer join
	[chil-crm-04].[BurwoodGroupInc_MSCRM].[dbo].[OpportunityBase] o2 with (nolock) on e.Name=o2.Name and o.OpportunityId is NULL and o.StateCode=1
		left outer join
	[chil-crm-04].[BurwoodGroupInc_MSCRM].[dbo].[SystemUserBase] ae2 with (nolock) on o2.OwnerId=ae2.SystemUserId
		left outer join
	UDFText u with (nolock) on u.EntityId=e.EngagementId and u.ItemName='EngagementText7'
		left outer join
	UDFText u2 with (nolock) on u2.EntityId=p.ProjectId and u2.ItemName='ProjectText1'
		left outer join
	UDFCode udf with (nolock) on p.ProjectId=udf.EntityId and udf.ItemName='ProjectCode3'
		left outer join
	CodeDetail cd with (nolock) on udf.UDFCode=cd.CodeDetail
		LEFT OUTER JOIN
	EngRequestBillingRule er WITH (NOLOCK) ON e.EngagementId=er.EngagementId
		left outer join
	BillingType bt with (nolock) on e.BillingType=bt.Code
		left outer join
	BG_Engagement_Adjustments_CG adj with (nolock) on e.EngagementId=adj.EngagementId
		left outer join
	ProjectStatus ps with (nolock) on p.ProjectStatus=ps.Code
where
	e.Deleted=0
	and e.Billable=1
	AND e.EngagementStatus IN ('F', 'W', 'P')
	and er.RequestType is NULL
	and coalesce(t.Deleted,0)=0
	and e.EngagementId not in ('9F24B4FB-212C-4359-87E5-DA52BB6F61F6', '4B009190-F3AC-41FA-9474-FF3A050001BB')
	and ta.Deleted=0
	and t.Deleted=0
	--and p.Name='HUB International - Enterprise Data Analytics Strategy Development'
	--and e.EngagementId='8B6D8061-09B2-4A8B-80EE-1A428823445A'
	--and t.TaskId='6236B1A8-192B-4768-8106-06A113DC192C'
	--and t.projectid='E3F87BB5-FC68-4DB5-8B31-1117BAE01BD8'
	--and p.ProjectId='7AB6D00F-F241-4F01-97E6-BC9626E3B0F0'
--order by
--	coalesce(ta.ActualHours,0)















GO
