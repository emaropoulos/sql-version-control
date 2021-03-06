USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_ProjectDashboard_BillingRoleHours_CG]    Script Date: 9/30/2019 5:00:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--select count(*) from [BG_ProjectDashboard_BillingRoleHours_CG] 

--select Project, Resource, count(BillingRole) as CountRoles from [BG_ProjectDashboard_BillingRoleHours_CG] where ProjectStatus<>'C' group by Project, Resource having count(BillingRole)>1 order by Project, Resource




CREATE view [dbo].[BG_ProjectDashboard_BillingRoleHours_CG] as 
select
	p.EngagementId,
	p.ProjectId,
	p.Name as Project,
	p.ProjectStatus,
	r.ResourceId,
	r.Name as Resource,
	ta.BillingRole as BillingRole,
	br.Description as BillingRoleName,
	max(t.PlannedHours) as TaskPlannedHours,
	sum(ta.PlannedHours) as ta_PlannedHours,
	sum(ta.ActualHours) as ActualHours,
	sum(ta.RemainingHours) as RemainingHours,
	sum(ta.PlannedRemainingHours) as PlannedRemainingHours
from
	Project p with (nolock)
		join
	Tasks t with (nolock) on p.ProjectId=t.ProjectId
		join
	TaskAssignment ta with (nolock) on t.ProjectId=ta.ProjectId and t.TaskId=ta.TaskId
		join
	Resources r with (nolock) on ta.ResourceId=r.ResourceId
		left outer join
	EngagementBillingRates eb with (nolock) on ta.BillingRole=eb.BillingRoleId and ta.EngagementId=eb.EngagementId
		left outer join
	BillingRole br with (nolock) on eb.BillingRoleId=br.BillingRoleId and br.Deleted=0
where
	t.Deleted=0
	and ta.Deleted=0
	--and p.Name='AMITA Health - Genesys Integration'
	--p.ProjectId='949CFD9A-7EF6-4A34-AEEE-C57BD401A9AF'
group by
	p.EngagementId,
	p.ProjectId,
	p.Name,
	p.ProjectStatus,
	r.ResourceId,
	r.Name,
	ta.BillingRole,
	br.Description

GO
