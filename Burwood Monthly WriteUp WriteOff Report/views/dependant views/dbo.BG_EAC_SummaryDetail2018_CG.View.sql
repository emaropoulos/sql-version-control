USE [Changepoint2018]
GO
/****** Object:  View [dbo].[BG_EAC_SummaryDetail2018_CG]    Script Date: 10/11/2019 1:49:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





--select * from Customer where Name like 'Test%'


--select count(*) from [BG_EAC_SummaryDetail2018_CG] where ProjectStatus<>'Completed'


CREATE view [dbo].[BG_EAC_SummaryDetail2018_CG] as 
with a as (
select
	r.Description as Region,
	c.Name as Customer,
	e.Name as Engagement,
	er.RequestType,
	p.Name as Project,
	t.Name as Task,
	ta.BillingRole,
	convert(nvarchar(2048), p.Description) as ProjectDescription,
	case when ps.Description='Completed' then 'Completed' else 'Active' end as ProjectStatus,
	case when p.ProjectStatus='A'
		 then 'No'
		 when p.ProjectStatus='C' and wp.WorkflowProcess in ('Verify Time & Expense Approval', 'Pending Close')
		 then 'Yes'
	End as PendingClose,
	wp.WorkflowProcess,
	bt.Description as BillingType,
	pm.ProjectManager,
	convert(date, p.BaselineStart) BaselineStart,
	convert(date, p.ActualStart) ActualStart,
	convert(date, coalesce(p.BaselineFinish, p.PlannedFinish)) as BaselineFinish,
	convert(date, p.PlannedStart) as PlannedStart,
	convert(date, p.PlannedFinish) as PlannedFinish,
	case when mp.MaxGreaterThanProjectFinish='Yes'
		 then mp.MaxPlannedFinish
		 else convert(date, p.PlannedFinish)
	end as PlannedFinishMax,
	convert(date, p.ActualFinish) as ActualFinish,
	adj.CloseDate as EngagementCloseDate,
	o.AccountExecutive,
	coalesce(cd.Description, 'Undefined') as EngagementType,
	coalesce(e.ContractAmount,0) as ContractAmount,
	coalesce(p.LabourBudget,0) as LaborBudget,
	coalesce(p.ExpenseBudget,0) as ExpenseBudget,
	coalesce(p.OtherExpenseBudget,0) as OtherExpenseBudget,
	coalesce(rd.UDFNumber,0) as ContingencyAmount,
	--coalesce(adj.FixedFeeOverage,0) as FixedFeeOverage,
	coalesce(adj.[Adjustment to Close a Project],0) as AdjustmentToCloseProject,
	coalesce(adj.[Contractor Margin Adjustment],0) as ContractorMarginAdjustment,
	coalesce(adj.[Contractor Pass-through Adjustment],0) as ContractorPassThroughAdjustment,
	coalesce(adj.[Expense Recognition Adjustment],0) as ExpenseAdjustment,
	coalesce(adj.[Other Adjustment],0) as OtherAdjustment,
	--coalesce(adj.FixedFeeOverage,0) as FixedFeeOverage,
	--coalesce(adj.ContractorAdjustment,0) as ContractorAdjustment,
	--coalesce(adj.ExpenseAdjustment,0) as ExpenseAdjustment,
	--coalesce(adj.OtherAdjustment,0) as OtherAdjustment,
	o.EstimatedServicesMargin as BaselineProfitabilityCRM,
	o.EstimatedProfitability/100 as BaselineProfitabilityPercentCRM,
	coalesce(p.BaselineHours,o.EstimatedHours) as BaselineHours,
	coalesce(p.PlannedHours,0) as PlannedHours,
	rsc.Name as Resource,
	coalesce(ebr.NegotiatedRate,0) as CurrentEngagementNegotiatedRate,
	(select BillingRate from [BG_EngagementBillingRate_CG](ta.EngagementId, ta.BillingRole, convert(date, ta.ActualStart))) as NegotiatedRate,
	ta.ForecastStart,
	ta.PercentComplete/100 as PercentComplete,
	convert(date, ta.PlannedStart) as ta_PlannedStart,
	convert(date, ta.PlannedFinish) as ta_PlannedFinish,
	coalesce(t.BaselineHours,0) as TaskBaselineHours,
	t.PlannedHours TaskPlannedHours,
	t.PlannedRemainingHours TaskPlannedRemaining,
	coalesce(ta.ActualHours,0)+coalesce(ta.PlannedRemainingHours,0) as EACHours,
	--CostRates
	coalesce(rr.HourlyCostRate,0) as ResourceHourlyCostRate,
	coalesce(ta.ActualHours,0) as ActualHours,
	coalesce(ta.PlannedRemainingHours,0) as PlannedRemainingHours,
	--Planned Remaining Fees
	coalesce(ta.PlannedRemainingHours,0)*coalesce(ebr.NegotiatedRate,0) as PlannedRemainingFees,
	--Actual Fees
	(select 
		sum(case when tw.AdjustmentReasonCode is not null
		 then round(0,2)
		 when tw.AdjustmentReasonCode IS NULL 
		  and coalesce(tw.RevRec,0)<>0 
		  and round(coalesce(tw.RateTimesHours,0),2)<> coalesce(tw.RevRec,0)
		 then case when coalesce(tw.AdjustmentTimeStatus,'')='P' and tw.RegularHours<>0
		 then (coalesce(tw.RegularHours,0)+coalesce(tw.OvertimeHours,0))*tw.RevRate
		 when coalesce(tw.AdjustmentTimeStatus,'')='P' and tw.RegularHours=0
		 then (coalesce(tw.RegularHours,0)+coalesce(tw.OvertimeHours,0))*tw.RevRate
		 else tw.RevRec end
		 else round(coalesce(tw.RateTimesHours,0),2)
	end) 
	 from 
		BG_Time_and_Writeoff_with_Effective_BillingRate_CG tw 
	 where 
		tw.Billable=1
		and coalesce(tw.ApprovalStatus, '')<>'R'
		and(tw.AdjustmentTimeStatus <> 'A' OR tw.AdjustmentTimeStatus is null)
		and tw.ProjectId=p.ProjectId
		and tw.ResourceId=ta.ResourceId 
		and tw.TaskId=ta.TaskId)
	as ActualFees,
	--(select 
	--	sum(case when tw.AdjustmentReasonCode is not null
	--	 then round(0,2)
	--	 when tw.AdjustmentReasonCode IS NULL 
	--	  and coalesce(tw.RevRec,0)<>0 
	--	  and round(coalesce(tw.RateTimesHours,0),2)<> coalesce(tw.RevRec,0)
	--	 then coalesce(tw.RevRec,0)
	--	 else round(coalesce(tw.RateTimesHours,0),2)
	--end) 
	-- from 
	--	BG_Time_and_Writeoff_with_Effective_BillingRate_CG tw 
	-- where 
	--	tw.Billable=1
	--	and coalesce(tw.ApprovalStatus, '')<>'R'
	--	and(tw.AdjustmentTimeStatus <> 'A' OR tw.AdjustmentTimeStatus is null)
	--	and tw.ProjectId=p.ProjectId
	--	and tw.ResourceId=ta.ResourceId 
	--	and tw.TaskId=ta.TaskId)
	--as ActualFees,

	--(select 
	--	sum(case when coalesce(RateTimesHours,0)<>0 and round(coalesce(RateTimesHours,0),2)<> coalesce(RevRec,0) 
	--			 then RevRec 
	--			 else round(RateTimesHours,2) 
	--		end) 
	-- from 
	--	BG_Time_and_Writeoff_with_Effective_BillingRate_CG tw 
	-- where 
	--	tw.ResourceId=ta.ResourceId 
	--	and tw.TaskId=ta.TaskId)
	--as ActualFees,
	--(select sum(round(RateTimesHours,2)) from BG_Time_and_Writeoff_with_Effective_BillingRate_CG tw where tw.ResourceId=ta.ResourceId and tw.TaskId=ta.TaskId) as ActualRateTimesHours,
	--(select sum(RevRec) from BG_Time_and_Writeoff_with_Effective_BillingRate_CG tw where tw.ResourceId=ta.ResourceId and tw.TaskId=ta.TaskId) as ActualRevRec,
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
	[chil-crm-04].[BurwoodGroupInc_MSCRM].[dbo].[BG_ChangepointServicesFields_CG] o with (nolock) on e.OpportunityId=o.OpportunityId
		left outer join
	UDFCode udf with (nolock) on p.ProjectId=udf.EntityId and udf.ItemName='ProjectCode3'
		left outer join
	CodeDetail cd with (nolock) on udf.UDFCode=cd.CodeDetail
		LEFT OUTER JOIN
	EngRequestBillingRule er WITH (NOLOCK) ON e.EngagementId=er.EngagementId
		left outer join
	BillingType bt with (nolock) on e.BillingType=bt.Code
		left outer join
	BG_ProjectDashboard_AdjustmentsByType_byEngagement_CG adj with (nolock) on e.EngagementId=adj.EngagementId
		left outer join
	ProjectStatus ps with (nolock) on p.ProjectStatus=ps.Code
		left outer join
	BG_EAC_ProjectPendingClose_CG wp with (nolock) on p.ProjectId=wp.ProjectId
		left outer join
	BG_EAC_ProjectMaxPlannedFinish_CG mp with (nolock) on p.ProjectId=mp.ProjectId
where
	e.Deleted=0
	and e.Billable=1
	AND (e.EngagementStatus IN ('F', 'W', 'P') or (p.ProjectStatus='C' and wp.WorkflowProcess in ('Verify Time & Expense Approval', 'Pending Close')))
	--and er.RequestType is NULL
	and coalesce(t.Deleted,0)=0
	and e.EngagementId not in ('9F24B4FB-212C-4359-87E5-DA52BB6F61F6', '4B009190-F3AC-41FA-9474-FF3A050001BB')
	and ta.Deleted=0
	and t.Deleted=0
	and e.CustomerId<>'3E09B148-69D8-4023-9F75-2AF9852D753E'
	--and e.Name='Imagine Print Solutions - Citrix Netscaler Assessment'
)
select
		a.Region,
	a.Customer,
	a.Engagement,
	a.RequestType,
	a.Project,
	a.Task,
	a.BillingRole,
	a.ProjectDescription,
	a.ProjectStatus,
	a.PendingClose,
	a.WorkflowProcess,
	a.BillingType,
	a.ProjectManager,
	a.BaselineStart,
	a.ActualStart,
	a.BaselineFinish,
	a.PlannedStart,
	a.PlannedFinish,
	a.PlannedFinishMax,
	a.ActualFinish,
	a.EngagementCloseDate,
	a.AccountExecutive,
	a.EngagementType,
	a.ContractAmount,
	a.LaborBudget,
	a.ExpenseBudget,
	a.OtherExpenseBudget,
	a.ContingencyAmount,
	--a.FixedFeeOverage,
	a.AdjustmentToCloseProject,
	a.ContractorMarginAdjustment,
	a.ContractorPassThroughAdjustment,
	a.ExpenseAdjustment,
	a.OtherAdjustment,
	a.BaselineProfitabilityCRM,
	a.BaselineProfitabilityPercentCRM,
	a.BaselineHours,
	a.PlannedHours,
	a.Resource,
	a.CurrentEngagementNegotiatedRate,
	a.NegotiatedRate,
	a.ForecastStart,
	a.PercentComplete,
	a.ta_PlannedStart,
	a.ta_PlannedFinish,
	a.TaskBaselineHours,
	a.TaskPlannedHours,
	a.TaskPlannedRemaining,
	a.EACHours,
	a.ResourceHourlyCostRate,
	a.ActualHours,
	a.PlannedRemainingHours,
	coalesce(a.PlannedRemainingFees,0) as PlannedRemainingFees,
	coalesce(a.ActualFees,0) as ActualFees,
	--coalesce(a.ActualFees2,0) as ActualFees2,
	(coalesce(a.ActualFees,0))+(coalesce(a.PlannedRemainingFees,0)) as ExpectedFees,
	(ActualHours*ResourceHourlyCostRate)+(PlannedRemainingHours*ResourceHourlyCostRate) as ExpectedInternalCost,
	a.EngagementId,
	a.OpportunityId,
	a.ProjectId
	
from
	a













GO
