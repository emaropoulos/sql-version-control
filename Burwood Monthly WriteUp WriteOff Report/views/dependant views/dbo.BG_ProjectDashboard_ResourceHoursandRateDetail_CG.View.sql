USE [Changepoint2018]
GO
/****** Object:  View [dbo].[BG_ProjectDashboard_ResourceHoursandRateDetail_CG]    Script Date: 10/11/2019 1:49:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE view [dbo].[BG_ProjectDashboard_ResourceHoursandRateDetail_CG] as 
with a as (
select
	b.Description as Region,
	cc.Name as Practice,
	w.Name as Workgroup,
	p.Name as Project,
	cast(p.ActualFinish as date) as ActualFinish,
	cast(p.PlannedFinish as date) as PlannedFinish,
	p.ProjectId,
	r.Name as Resource,
	case when r.EmployeeType='CO' then 2 else 1 end as EmployeeTypeSort,
	r.ResourceId,
	(select rr.HourlyBillRate from ResourceRate rr where rr.Active=1 and rr.ResourceId=r.ResourceId and rr.EffectiveDate=(select max(r2.EffectiveDate) from ResourceRate r2 where rr.ResourceId=r2.ResourceId)) 
	as StandardHourlyBillRate,
	(select rr2.HourlyCostRate from ResourceRate rr2 where rr2.Active=1 and rr2.ResourceId=r.ResourceId and rr2.EffectiveDate=(select max(r2.EffectiveDate) from ResourceRate r2 where rr2.ResourceId=r2.ResourceId)) 
	as StandardHourlyCostRate,
	eb.BillingRate as ProjectBillingRate,
	--eb.NegotiatedRate as ProjectBillingRate,
	eb.RateStartDate,
	eb.EndDate as RateEndDate,
	--min(bt.BillingRate) as ProjectBillingRate,
	e.OvertimePercentage/100 as OvertimePercentage,
	br.BillingRoleId,
	br.Description as BillingRole,
	r.Title,
	eb.CostRate as EngagementCostRate,
	c.PlannedMarginPercent
from 
	Project p with (nolock)
		left outer join
	BG_ProjectDashboard_CustomFields_CG c with (nolock) on p.ProjectId=c.ProjectId and p.EngagementId=c.EngagementId
		join
	(select distinct EngagementId, ProjectId, BillingRole, ResourceId from TaskAssignment with (nolock)) as ta on p.ProjectId=ta.ProjectId
		join
	Resources r with (nolock) on ta.ResourceId=r.ResourceId
		join
	[BG_EngagementBillingRates_withEffectiveDates_CG] eb with (nolock) on ta.BillingRole=eb.BillingRoleId and ta.EngagementId=eb.EngagementId
		join
	BillingRole br with (nolock) on eb.BillingRoleId=br.BillingRoleId and br.Deleted=0
		join
	dbo.Engagement e with (nolock) on p.EngagementId=e.EngagementId
		left outer join
	BillingOffice b with (nolock) on e.BillingOfficeId=b.BillingOfficeId
		left outer join
	CostCenters cc with (nolock) on e.CostCenterId=cc.CostCenter
		left outer join
	Workgroup w with (nolock) on e.AssociatedWorkgroup=w.WorkgroupId
--where
--	p.Name ='Carle Foundation Hospital Cisco ISE Project 2017'--in ('Rush University Medical Center - Cybersecurity Strategy', 'Wahl Power BI Phase 2')
),
b as (
select
	p.EngagementId,
	p.ProjectId,
	p.Name as Project,
	r.ResourceId,
	r.Name as Resource,
	ta.BillingRole,
	t.Name as Task,
	t.TaskId,
	sum(ta.PlannedHours) as PlannedHours,
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
--where
--	p.ProjectId='949CFD9A-7EF6-4A34-AEEE-C57BD401A9AF'
group by
	p.EngagementId,
	p.ProjectId,
	p.Name,
	r.ResourceId,
	r.Name,
	ta.BillingRole,
	t.Name,
	t.TaskId
),
c as (
select
	a.*,
	b.Task,
	b.TaskId,
	coalesce(b.PlannedHours,0) as PlannedHours,
	coalesce(b.ActualHours,0) as ActualHours,
	coalesce(b.RemainingHours,0) as RemainingHours,
	coalesce(b.PlannedRemainingHours,0) as PlannedRemainingHours,
	(coalesce(b.ActualHours,0)+coalesce(b.RemainingHours,0)) as EACHours,
	(coalesce(b.PlannedHours,0))*ProjectBillingRate as PlannedRateTimesHours,
	(coalesce(b.ActualHours,0))*ProjectBillingRate as ActualRateTimesHours,
	(coalesce(b.RemainingHours,0))*ProjectBillingRate as RemainingRateTimesHours,
	(coalesce(b.PlannedRemainingHours,0))*ProjectBillingRate as PlannedRemainingRateTimesHours,
	(coalesce(b.ActualHours,0)+coalesce(b.RemainingHours,0))*ProjectBillingRate as EACRateTimesHours,
	ProjectBillingRate-EngagementCostRate as EngagementMarginRate,
	ProjectBillingRate-StandardHourlyCostRate as ResourceMarginRate,
	case when ProjectBillingRate=0 then 0 else (ProjectBillingRate-EngagementCostRate)/ProjectBillingRate end as 'EngagementRateMarginDecimal',
	case when ProjectBillingRate=0 then 0 else round((((ProjectBillingRate-EngagementCostRate)/ProjectBillingRate)*100),2) end as 'EngagementRateMargin%',
	case when ProjectBillingRate=0 then 0 else (ProjectBillingRate-StandardHourlyCostRate)/ProjectBillingRate end as 'ResourceRateMarginDecimal',
	case when ProjectBillingRate=0 then 0 else round((((ProjectBillingRate-StandardHourlyCostRate)/ProjectBillingRate)*100),2) end as 'ResourceRateMargin%',
	(PlannedMarginPercent*100) as 'PlannedMargin%'
from
	a
		join
	b  on a.ProjectId=b.ProjectId and a.ResourceId=b.ResourceId and a.BillingRoleId=b.BillingRole
),
r as (
select
	Engagement,
	EngagementId,
	ProjectId,
	Resource,
	ResourceId,
	TaskId,
	BillingRole,
	TimeDate,
	BillingRate as BillingRate,
	EngagementBillingRate,
	RevRate,
	convert(date, RevRecDate) as RevRecDate,
	case when ApprovalStatus='A'
		 then 'Approved'
		 when ApprovalStatus='P'
		 then 'Pending'
		 when ApprovalStatus='P2'
		 then 'Pending second approval'
		 when ApprovalStatus='R'
		 then 'Rejected'
		 else 'Unapproved'
	end as ApprovalStatus,
	sum(RegularHours+OvertimeHours) as BillableHours,
	sum(round(coalesce(RateTimesHours,0),2)) as RateTimesHours,
	sum(RevRec) as RevenueRecognized
from
	BG_Time_and_Writeoff_with_Effective_BillingRate_CG with (nolock)
	--select * from BG_Time_and_Writeoff_with_Effective_BillingRate_CG where ProjectId='A9356206-DC0F-4A6A-B695-D1A3D043A58F' and ResourceId='DC4F7711-48F7-4F24-BDFE-A3D187D134DA'
where
	Billable=1
	and coalesce(ApprovalStatus, '')<>'R'
	and(AdjustmentTimeStatus <> 'A' OR AdjustmentTimeStatus is null)
	--and EngagementId='8BBC144D-B895-4429-AA41-66E22ED0F5E0'
	--or ProjectId='7B818865-8410-4A31-8D71-D42A19A8ADF3'
group by
	Engagement,
	EngagementId,
	ProjectId,
	Resource,
	ResourceId,
	TaskId,
	BillingRole,
	TimeDate,
	BillingRate,
	EngagementBillingRate,
	RevRate,
	convert(date, RevRecDate),
	ApprovalStatus
)

select
	Region,
	Practice,
	Workgroup,
	Project,
	c.ProjectId,
	c.Resource,
	Task,
	c.BillingRole,
	RateStartDate,
	RateEndDate,
	ProjectBillingRate,
	min(TimeDate) as MinimumTimeDate,
	max(TimeDate) as MaximumTimeDate,
	sum(PlannedHours) as PlannedHours,
	sum(ActualHours) as ActualHours,
	sum(PlannedRateTimesHours) as PlannedFees,
	sum(ActualRateTimesHours) as ActualFees,
	sum(PlannedRemainingHours) as PlannedRemainingHours,
	sum(PlannedRemainingRateTimesHours) as PlannedRemainingFees,
		sum(RateTimesHours) as RateTimesHours,

	--sum(TimeActualRateTimesHours) as TimeActualRateTimesHours,
	--max(TaskActualRateTimesHours) as TaskActualRateTimesHours,
	sum(RevenueRecognized) as RevenueRecognized,
	case when sum(PlannedHours)=0 then 0 else sum(ActualHours)/sum(PlannedHours) end as BurnRate
from
	c
		join
	r on c.ProjectId=r.ProjectId and c.ResourceId=r.ResourceId and c.BillingRoleId=r.BillingRole and r.TaskId=c.TaskId and r.TimeDate>=c.RateStartDate and r.TimeDate<=c.RateEndDate
--where
--	Project='HUB International NetAPP ONTAP AWS Migration Phase 1'
group by
	Region,
	Practice,
	Workgroup,
	Project,
	c.ProjectId,
	c.Resource,
	Task,
	c.BillingRole,
	RateStartDate,
	RateEndDate,

	ProjectBillingRate

GO
