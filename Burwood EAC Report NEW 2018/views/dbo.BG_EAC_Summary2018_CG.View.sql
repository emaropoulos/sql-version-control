USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_EAC_Summary2018_CG]    Script Date: 10/18/2019 4:57:42 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








--select * from BG_ProjectDashboard_Engagement_2018_CG where Project='Alliance Chicago UCS Upgrade and ASA Deployment'
--select * from BG_ProjectDashboard_Engagement_2018_CG where Project='Carle Foundation Hospital Cisco ISE Project 2017'
--select * from BG_EAC_Summary2018_CG where Project='Carle Foundation Hospital Cisco ISE Project 2017'


--select count(*) from BG_EAC_Summary2018_CG


CREATE view [dbo].[BG_EAC_Summary2018_CG] as
with a as (
select
	e.Region,
	e.Customer,
	e.Engagement,
	e.RequestType,
	c.ExpenseBillingType,
	e.EngagementId,
	e.Project,
	e.ProjectId,
	e.ProjectStatus,
	e.PendingClose,
	e.WorkflowProcess,
	e.BillingType,
	e.ProjectManager,
	e.AccountExecutive,
	EngagementType,
	BaselineStart,
	BaselineFinish,
	PlannedStart,
	PlannedFinish,
	PlannedFinishMax,
	ActualStart,
	ActualFinish,
	datediff(day, BaselineStart, PlannedStart) as StartDaysBetween,
	datediff(day, BaselineFinish, PlannedFinish) as FinishDaysBetween,
	EngagementCloseDate,
	ProjectDescription,
	max(LaborBudget) as LaborBudget,
	max(ContractAmount) as ContractAmount,
	--max(ExpenseBudget) as ExpenseBudget,
	max(OtherExpenseBudget) as OtherExpenseBudget,
	max(e.ContingencyAmount) as Contingency,
	--max(FixedFeeOverage) as FixedFeeOverage,
	max(e.AdjustmentToCloseProject) as AdjustmentToCloseProject,
	max(c.FixedFeeContractorPassThroughAmount) as ContractorPassThroughBudget,
	max(e.ContractorPassThroughAdjustment) as ContractorAdjustment,
	case when c.ExpenseBillingType='All Expenses' then 0 else max(c.ExpenseAmount) end as ExpenseBudget,
	case when c.ExpenseBillingType='All Expenses' then 0 else max(coalesce(ue.TotalExpense,0)) end as UnapprovedExpenses,
	max(e.ExpenseAdjustment) as ExpenseAdjustment,
	max(c.FixedFeeSubContractorMargin) ContractorMarginBudget,
	max(e.ContractorMarginAdjustment) as ContractorMarginAdjustment,
	max(e.OtherAdjustment) as OtherAdjustment,
	max(e.AdjustmentToCloseProject)+max(e.ContractorMarginAdjustment)+max(e.ContractorPassThroughAdjustment)+max(e.ExpenseAdjustment)+max(e.OtherAdjustment) as Adjustments,
	max(BaselineHours) as BaselineHours,
	max(PlannedHours) as PlannedHours,
	sum(ActualHours) as ActualHours,
	sum(PlannedRemainingHours) as PlannedRemainingHours,
	sum(ActualHours)+sum(PlannedRemainingHours) as EACHours,
	max(BaselineHours)-sum(ActualHours) as CurrentRemainingHoursInBudget,
	max(BaselineHours)-(sum(ActualHours)+sum(PlannedRemainingHours)) as ProjectedRemainingHoursInBudget,
	sum(coalesce(ActualFees,0)) as ActualFees,
	--sum(coalesce(ActualFees2,0)) as ActualFees2,
	case when e.ProjectStatus='Completed' then 0 else sum(coalesce(PlannedRemainingFees,0)) end as PlannedRemainingFees,
	sum(ExpectedFees) as ExpectedFees,
	max(ContractAmount)-sum(coalesce(ActualFees,0)) as ContractRemainingBudgetAmt,
	max(LaborBudget)-sum(coalesce(ActualFees,0)) as ServicesRemainingBudgetAmt,
	max(LaborBudget)-(sum(coalesce(ActualFees,0))+sum(coalesce(PlannedRemainingFees,0))) as PlannedRemainingBudgetAmt,
	sum(ExpectedInternalCost) as ExpectedInternalCost,
	case when e.BillingType='Hourly' and (max(ContractAmount)+max(AdjustmentToCloseProject)+max(ContractorMarginAdjustment)+max(e.ContingencyAmount)+max(ContractorPassThroughAdjustment)+max(ExpenseAdjustment)+max(OtherAdjustment)-sum(ExpectedFees))>0
		 then 0
		 else max(ContractAmount)+max(AdjustmentToCloseProject)+max(ContractorMarginAdjustment)+max(ContractorPassThroughAdjustment)+max(ExpenseAdjustment)+max(OtherAdjustment)-sum(ExpectedFees) 
	end as WriteUpWriteOff1,
	case when (sum(ActualHours)+sum(PlannedRemainingHours))=0 then 0 else max(LaborBudget)/(sum(ActualHours)+sum(PlannedRemainingHours)) end as ProjectRealization,
	max(BaselineProfitabilityCRM) as BaselineProfitabilityCRM,
	max(BaselineProfitabilityPercentCRM) as BaselineProfitabilityPercentCRM,
	max(LaborBudget)+max(e.ContingencyAmount)-sum(ExpectedInternalCost) as ProjectedProfitability,
	case when max(LaborBudget)=0 then 0 else (max(LaborBudget)+max(e.ContingencyAmount)-sum(ExpectedInternalCost))/max(LaborBudget) end as ProjectedProfitabilityPercent
from
	BG_EAC_SummaryDetail2018_CG e
		left outer join
	[BG_ProjectDashboard_CustomFields_CG] c with (nolock) on e.EngagementId=c.EngagementId and e.ProjectId=c.ProjectId
		left outer join
	BG_ProjectDashboard_UnapprovedExpensesSummary_CG ue with (nolock)  on e.EngagementId=ue.EngagementId and e.ProjectId=ue.ProjectId
group by
	e.Region,
	e.Customer,
	e.Engagement,
	e.RequestType,
	c.ExpenseBillingType,
	e.EngagementId,
	e.Project,
	e.ProjectId,
	e.ProjectStatus,
	e.PendingClose,
	e.WorkflowProcess,
	e.BillingType,
	e.ProjectManager,
	e.AccountExecutive,
	e.EngagementType,
	e.BaselineStart,
	e.BaselineFinish,
	e.PlannedStart,
	e.PlannedFinish,
	e.PlannedFinishMax,
	e.ActualStart,
	e.ActualFinish,
	e.EngagementCloseDate,
	e.ProjectDescription
),
b as (
select
	*,
	case when [ContractorPassThroughBudget]=0 then 0 else [ContractorPassThroughBudget]+[ContractorAdjustment] end as ContractorPassThroughForecast,
	[ContractorMarginBudget]+[ContractorMarginAdjustment] as ContractorMarginForecast,
	[ExpenseBudget]+[ExpenseAdjustment]-[UnapprovedExpenses] as ExpenseForecast
from
	a
)
select
	*,
	case when BillingType='Hourly' and ((ContractAmount)+(AdjustmentToCloseProject)+(ContractorMarginAdjustment)+(Contingency)+(ContractorAdjustment)+(ExpenseAdjustment)+(OtherAdjustment)-(ExpectedFees))>0
		 then 0
		 else ((ContractAmount)+(AdjustmentToCloseProject)+(ContractorMarginAdjustment)+(ContractorAdjustment)+(ExpenseAdjustment)+(OtherAdjustment))-(ExpectedFees) 
	end as WriteUpWriteOff,
		(LaborBudget+[ContractorPassThroughBudget]+[ContractorMarginBudget]+[ExpenseBudget]) --TotalBudget
	-	([ActualFees]+[PlannedRemainingFees])  --TotalFees
	-	(ContractorPassThroughForecast+ContractorMarginForecast+ExpenseForecast)
	+	[AdjustmentToCloseProject]
	as WriteUpWriteOffwithForecast
from
	b
--where
--	Project='Achates Power- Citrix Netscaler SD-WAN'





GO
