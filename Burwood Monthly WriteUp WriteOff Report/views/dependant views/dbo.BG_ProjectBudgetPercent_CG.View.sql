USE [Changepoint2018]
GO
/****** Object:  View [dbo].[BG_ProjectBudgetPercent_CG]    Script Date: 10/11/2019 1:49:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[BG_ProjectBudgetPercent_CG] as 
select
	b.Description as Region,
	p.Name,
	pm.ProjectManager,
	pm.EmailAddress,
	p.LabourBudget as ServicesBudget,
	sum(tw.RateTimesHours) as RateTimesHours,
	case when p.LabourBudget=0 then 0 else sum(tw.RateTimesHours)/p.LabourBudget end as PercentComplete
from
	BG_Time_and_Writeoff_with_Effective_BillingRate_CG tw with (nolock)
		join
	Project p with (nolock) on tw.ProjectId=p.ProjectId
		join
	Engagement e with (nolock) on tw.EngagementId=e.EngagementId
		join
	BillingOffice b with (nolock) on e.BillingOfficeId=b.BillingOfficeId
		join
	BG_ProjectManager_CG pm with (nolock) on tw.ProjectId=pm.ProjectId
where
	p.ProjectStatus<>'C'
	and tw.Billable=1
	--and tw.ApprovalStatus='A'
group by
	b.Description,
	p.Name,
	pm.ProjectManager,
	pm.EmailAddress,
	p.LabourBudget

GO
