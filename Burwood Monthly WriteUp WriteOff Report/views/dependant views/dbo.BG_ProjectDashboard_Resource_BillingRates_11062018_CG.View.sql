USE [Changepoint2018]
GO
/****** Object:  View [dbo].[BG_ProjectDashboard_Resource_BillingRates_11062018_CG]    Script Date: 10/11/2019 1:49:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO














--select * from [BG_ProjectDashboard_Resource_BillingRates_SAVE_CG] where Project='Rush University Medical Center - Cybersecurity Strategy'


--select top 100 * from BG_ProjectDashboard_CustomFields_CG

--select * from BG_ProjectDashboard_Resource_BillingRates_CG where ProjectId='7B818865-8410-4A31-8D71-D42A19A8ADF3'

--select count(*) from [BG_ProjectDashboard_Resource_BillingRates_CG]

CREATE VIEW [dbo].[BG_ProjectDashboard_Resource_BillingRates_11062018_CG] AS


with a as (
select
	b.Description as Region,
	cc.Name as Practice,
	w.Name as Workgroup,
	p.Name as Project,
	bt.Description as BillingType,
	p.ProjectStatus,
	cast(p.ActualFinish as date) as ActualFinish,
	cast(p.PlannedFinish as date) as PlannedFinish,
	--p.EngagementId,
	p.ProjectId,
	r.Name as Resource,
	case when r.EmployeeType='CO' then 2 else 1 end as EmployeeTypeSort,
	r.ResourceId,
	(select rr.HourlyBillRate from ResourceRate rr where rr.Active=1 and rr.ResourceId=r.ResourceId and rr.EffectiveDate=(select max(r2.EffectiveDate) from ResourceRate r2 where rr.ResourceId=r2.ResourceId)) 
	as StandardHourlyBillRate,
	(select rr2.HourlyCostRate from ResourceRate rr2 where rr2.Active=1 and rr2.ResourceId=r.ResourceId and rr2.EffectiveDate=(select max(r2.EffectiveDate) from ResourceRate r2 where rr2.ResourceId=r2.ResourceId)) 
	as StandardHourlyCostRate,
	eb.BillingRate as ProjectBillingRate,
	eb.RateStartDate,
	eb.EndDate as RateEndDate,
	--min(bt.BillingRate) as coalesce(ProjectBillingRate,0),
	e.OvertimePercentage/100 as OvertimePercentage,
	br.BillingRoleId,
	br.Description as BillingRole,
	r.Title,
	eb.CostRate as EngagementCostRate,
	coalesce(c.PlannedMarginPercent,0) as PlannedMarginPercent,
	ta.Task,
	ta.TaskId
from 
	Project p with (nolock)
		left outer join
	BG_ProjectDashboard_CustomFields_CG c with (nolock) on p.ProjectId=c.ProjectId and p.EngagementId=c.EngagementId
		join
	(select distinct t.Name as Task, t.TaskId, ta1.EngagementId, ta1.ProjectId, ta1.BillingRole, ta1.ResourceId from TaskAssignment ta1 with (nolock) join Tasks t with (nolock) on ta1.TaskId=t.TaskId where ta1.Deleted=0 and t.Billable=1) as ta on p.ProjectId=ta.ProjectId
		join
	Resources r with (nolock) on ta.ResourceId=r.ResourceId
		join
	[BG_EngagementBillingRates_withEffectiveDates_CG] eb with (nolock) on ta.BillingRole=eb.BillingRoleId and ta.EngagementId=eb.EngagementId
		join
	BillingRole br with (nolock) on eb.BillingRoleId=br.BillingRoleId and br.Deleted=0
		join
	dbo.Engagement e with (nolock) on p.EngagementId=e.EngagementId
		join 
	BillingType bt on e.BillingType=bt.Code
		left outer join
	BillingOffice b with (nolock) on e.BillingOfficeId=b.BillingOfficeId
		left outer join
	CostCenters cc with (nolock) on e.CostCenterId=cc.CostCenter
		left outer join
	Workgroup w with (nolock) on e.AssociatedWorkgroup=w.WorkgroupId
--where
--	p.Name ='HUB International NetAPP ONTAP AWS Migration Phase 1'--in ('Rush University Medical Center - Cybersecurity Strategy', 'Wahl Power BI Phase 2')
--	and r.Name='LEVY, DAVID'
),
n as (
select
	p.ProjectId,
	r.ResourceId,
	count(ta.BillingRole) as NumberResourceRoles
from 
	Project p with (nolock)
		join
	(select distinct ta1.ProjectId, ta1.BillingRole, ta1.ResourceId from TaskAssignment ta1 with (nolock) join Tasks t with (nolock) on ta1.TaskId=t.TaskId where ta1.Deleted=0 and t.Billable=1) as ta on p.ProjectId=ta.ProjectId
		join
	Resources r with (nolock) on ta.ResourceId=r.ResourceId
--where
--	p.Name='ACC West Coast University - Disaster Recovery- Zerto Azure Deployment'
group by
	p.Name,
	p.ProjectStatus,
	p.ProjectId,
	r.Name,
	r.ResourceId
),
b as (
select
	a.*,
	coalesce(b.TaskPlannedHours,0) as TaskPlannedHours,
	coalesce(b.ta_PlannedHours,0) as ta_PlannedHours,
	coalesce(b.ActualHours,0) as ActualHours,
	coalesce(b.RemainingHours,0) as RemainingHours,
	coalesce(b.PlannedRemainingHours,0) as PlannedRemainingHours,
	(coalesce(b.ActualHours,0)+coalesce(b.RemainingHours,0)) as EACHours,
	round((coalesce(b.ActualHours,0))*coalesce(ProjectBillingRate,0),2) as ActualRateTimesHours,
	(coalesce(b.RemainingHours,0))*coalesce(ProjectBillingRate,0) as RemainingRateTimesHours,
	(coalesce(b.PlannedRemainingHours,0))*coalesce(ProjectBillingRate,0) as PlannedRemainingRateTimesHours,
	(coalesce(b.ActualHours,0)+coalesce(b.RemainingHours,0))*coalesce(ProjectBillingRate,0) as EACRateTimesHours,
	coalesce(ProjectBillingRate,0)-EngagementCostRate as EngagementMarginRate,
	coalesce(ProjectBillingRate,0)-coalesce(StandardHourlyCostRate,0) as ResourceMarginRate,
	case when coalesce(ProjectBillingRate,0)=0 then 0 else (coalesce(ProjectBillingRate,0)-EngagementCostRate)/coalesce(ProjectBillingRate,0) end as 'EngagementRateMarginDecimal',
	case when coalesce(ProjectBillingRate,0)=0 then 0 else round((((coalesce(ProjectBillingRate,0)-EngagementCostRate)/coalesce(ProjectBillingRate,0))*100),2) end as 'EngagementRateMargin%',
	case when coalesce(ProjectBillingRate,0)=0 then 0 else (coalesce(ProjectBillingRate,0)-coalesce(StandardHourlyCostRate,0))/coalesce(ProjectBillingRate,0) end as 'ResourceRateMarginDecimal',
	case when coalesce(ProjectBillingRate,0)=0 then 0 else round((((coalesce(ProjectBillingRate,0)-coalesce(StandardHourlyCostRate,0))/coalesce(ProjectBillingRate,0))*100),2) end as 'ResourceRateMargin%',
	(PlannedMarginPercent*100) as 'PlannedMargin%'
from
	a
		join
	BG_ProjectDashboard_BillingRoleHours_CG b with (nolock) on a.ProjectId=b.ProjectId and a.ResourceId=b.ResourceId and a.BillingRoleId=b.BillingRole
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
,
x as (
select
	b.[Project],
	b.[BillingType],
	b.[ProjectStatus],
	b.[ActualFinish],
	b.[PlannedFinish],
	b.[ProjectId],
	b.[Resource],
	b.[EmployeeTypeSort],
	b.[ResourceId],
	coalesce(b.[StandardHourlyBillRate],0) as StandardHourlyBillRate,
	coalesce(b.[StandardHourlyCostRate],0) as StandardHourlyCostRate,
	b.[OvertimePercentage],
	b.[BillingRoleId],
	b.BillingRole,
	b.[Title],
	b.[EngagementCostRate],
	b.[PlannedMarginPercent],
	b.[Task],
	b.[TaskId],
	b.[TaskPlannedHours],
	b.[ta_PlannedHours],
	b.[ActualHours],
	b.[RemainingHours],
	b.[PlannedRemainingHours],
	b.[EACHours],
	b.[RemainingRateTimesHours],
	b.[PlannedRemainingRateTimesHours],
	b.[EACRateTimesHours],
	b.[EngagementMarginRate],
	b.[ResourceMarginRate],
	b.[EngagementRateMarginDecimal],
	b.[EngagementRateMargin%],
	b.[ResourceRateMarginDecimal],
	b.[ResourceRateMargin%],
	b.[PlannedMargin%],
	n.NumberResourceRoles,
	
	case when ([ResourceRateMargin%]-[PlannedMargin%])<0 then -([ResourceRateMargin%]-[PlannedMargin%]) else ([ResourceRateMargin%]-[PlannedMargin%]) end as ResourceMarginDiff,
	case when (case when ([ResourceRateMargin%]-[PlannedMargin%])<0 then -([ResourceRateMargin%]-[PlannedMargin%]) else ([ResourceRateMargin%]-[PlannedMargin%]) end)>=0
				and (case when ([ResourceRateMargin%]-[PlannedMargin%])<0 then -([ResourceRateMargin%]-[PlannedMargin%]) else ([ResourceRateMargin%]-[PlannedMargin%]) end)<=.03
		 then 'Yes'
		 else 'No'
	end as 'MarginWithInExpectedRange',
	b.RateStartDate,
	b.RateEndDate,
	r.TimeDate,
	r.ApprovalStatus,
	r.RevRecDate,
	b.ProjectBillingRate,
	r.EngagementBillingRate,
	r.BillingRate,
	r.RevRate as RevRecRate,
	coalesce(r.BillableHours,0) as twBillableHours,
	
	b.[ActualRateTimesHours] as TaskActualRateTimesHours,
	coalesce(r.BillableHours,0)*EngagementBillingRate as TimeActualRateTimesHours,
	round(r.RateTimesHours,2) as RateTimesHours,
	coalesce(r.RevenueRecognized,0) as RevenueRecognized,
	case when round(round((coalesce(r.BillableHours,0))*coalesce(EngagementBillingRate,0),2),0)=round(coalesce(r.RevenueRecognized,0),0) then 'Yes'
		 when round(round((coalesce(r.BillableHours,0))*coalesce(EngagementBillingRate,0),2),0)<round(coalesce(r.RevenueRecognized,0),0) then 'No'

		 else 'Revenue Recognized Less Than'
	end as RevRecMatches2,
	case when round(r.RateTimesHours,0)=round(coalesce(r.RevenueRecognized,0),0) then 'Yes'
		 when round(r.RateTimesHours,0)<round(coalesce(r.RevenueRecognized,0),0) then 'No'
		 when coalesce(r.RevenueRecognized,0)=0 and r.RevRecDate is NULL
		 then 'Revenue Not Yet Recognized'
		 else 'Revenue Recognized Less Than'
	end as RevRecMatches,
	case when EngagementBillingRate<>r.BillingRate
		 then 'Time Bill Rate Does Not Match Project Billing Rate'
		 when EngagementBillingRate<>r.BillingRate and r.BillingRate<>r.RevRate
		 then 'Time and Project Rate Does Not Match RevRec Rate'
		 when r.BillingRate<>r.RevRate and r.BillingRate=EngagementBillingRate
		 then 'Project and Time Rate Match BUT Rev Rec Rate does not match'
		 when EngagementBillingRate=r.BillingRate and r.BillingRate=r.RevRate
		 then 'All Rates Match'
		 when coalesce(r.RevRate,0)=0 and r.RevRecDate is null
		 then 'Revenue Not Yet Recognized'
	end as RatesMatch
from
	b
		left outer join
	n on b.ProjectId=n.ProjectId and b.ResourceId=n.ResourceId
		join
	r on b.ProjectId=r.ProjectId and b.ResourceId=r.ResourceId and b.BillingRoleId=r.BillingRole and r.TaskId=b.TaskId and r.TimeDate>=b.RateStartDate and r.TimeDate<=b.RateEndDate
)
--select * from x --where RatesMatch is null
--)
select
	Project,
	ProjectId,
	ProjectStatus,
	Resource,
	Task,
	BillingRole,
	RateStartDate,
	RateEndDate,
	
	--BillingRate,
	ProjectBillingRate,
	min(TimeDate) as MinimumTimeDate,
	max(TimeDate) as MaximumTimeDate,
	max(ActualHours) as BillableHours,
	sum(twBillableHours) as twBillableHours,
	sum(RateTimesHours) as RateTimesHours,

	sum(TimeActualRateTimesHours) as TimeActualRateTimesHours,
	max(TaskActualRateTimesHours) as TaskActualRateTimesHours,
	sum(RevenueRecognized) as RevenueRecognized
from	
	x
group by
	Project,
	ProjectId,
	ProjectStatus,
	Resource,
	Task,
	BillingRole,
	RateStartDate,
	RateEndDate,

	--Task,
	--BillingRate,
	ProjectBillingRate
		--TimeDate


GO
