USE [Changepoint2018]
GO
/****** Object:  View [dbo].[BG_EAC_Summary_CG]    Script Date: 10/11/2019 1:49:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




--select * from [BG_EAC_Summary_CG] where Region='EA-Eastern Region' --Project='Carle Foundation Hospital Fields Infrastructure Build'
--select * from [BG_ProjectDashboard_Engagement_CG] where Project='Carle Foundation Hospital Fields Infrastructure Build'


CREATE view [dbo].[BG_EAC_Summary_CG] as
select
	Region,
	Customer,
	Engagement,
	EngagementId,
	Project,
	ProjectId,
	ProjectStatus,
	BillingType,
	ProjectManager,
	AccountExecutive,
	EngagementType,
	BaselineStart,
	BaselineFinish,
	PlannedStart,
	PlannedFinish,
	ActualStart,
	ActualFinish,
	datediff(day, BaselineStart, PlannedStart) as StartDaysBetween,
	datediff(day, BaselineFinish, PlannedFinish) as FinishDaysBetween,
	EngagementCloseDate,
	ProjectDescription,
	max(LaborBudget) as LaborBudget,
	max(ContractAmount) as ContractAmount,
	max(ExpenseBudget) as ExpenseBudget,
	max(OtherExpenseBudget) as OtherExpenseBudget,
	max(ContingencyAmount) as Contingency,
	max(FixedFeeOverage) as FixedFeeOverage,
	max(ContractorAdjustment) as ContractorAdjustment,
	max(ExpenseAdjustment) as ExpenseAdjustment,
	max(OtherAdjustment) as OtherAdjustment,
	max(ContractorAdjustment)+max(ExpenseAdjustment)+max(OtherAdjustment) as Adjustments,
	max(BaselineHours) as BaselineHours,
	max(PlannedHours) as PlannedHours,
	sum(ActualHours) as ActualHours,
	sum(PlannedRemainingHours) as PlannedRemainingHours,
	sum(ActualHours)+sum(PlannedRemainingHours) as EACHours,
	max(BaselineHours)-sum(ActualHours) as CurrentRemainingHoursInBudget,
	max(BaselineHours)-(sum(ActualHours)+sum(PlannedRemainingHours)) as ProjectedRemainingHoursInBudget,
	--sum(coalesce(tw_ActualFees,0)) as tw_ActualFees,
	sum(coalesce(ActualFees,0)) as ActualFees,
	sum(PlannedFees) as PlannedFees,
	sum(PlannedFees1) as PlannedFees1,
	sum(coalesce(PlannedRemainingFees,0)) as PlannedRemainingFees,
	sum(PlannedRemainingFees1) as PlannedRemainingFees1,
	sum(coalesce(ActualFees,0))+sum(coalesce(PlannedRemainingFees1,0)) as New_ExpectedFees,
	sum(coalesce(ActualFees,0))+sum(coalesce(PlannedRemainingFees1,0)) as ExpectedFees,
	sum(ExpectedFees1) as ExpectedFees1,
	max(ContractAmount)-sum(coalesce(ActualFees,0)) as ContractRemainingBudgetAmt,
	max(ContractAmount)-sum(ActualFees) as ContractRemainingBudgetAmt1,
	max(LaborBudget)-sum(coalesce(ActualFees,0)) as ServicesRemainingBudgetAmt,
	max(LaborBudget)-sum(ActualFees) as ServicesRemainingBudgetAmt1,
	max(LaborBudget)-(sum(coalesce(ActualFees,0))+sum(coalesce(PlannedRemainingFees,0))) as PlannedRemainingBudgetAmt,
	max(LaborBudget)-(sum(coalesce(ActualFees,0))+sum(coalesce(PlannedRemainingFees1,0))) as PlannedRemainingBudgetAmt2,
	max(LaborBudget)-sum(ExpectedFees1) as PlannedRemainingBudgetAmt1,
	sum(ExpectedInternalCost) as ExpectedInternalCost,
	case when BillingType='Hourly' and (max(LaborBudget)+max(ContingencyAmount))-(sum(coalesce(ActualFees,0))+sum(coalesce(PlannedRemainingFees1,0)))>0
		 then 0
		 else (max(LaborBudget)+max(ContingencyAmount))-(sum(coalesce(ActualFees,0))+sum(coalesce(PlannedRemainingFees1,0))) 
	end as WriteUpWriteOffWithContingency,
	case when BillingType='Hourly' and (max(ContractAmount)+max(ContractorAdjustment)+max(ExpenseAdjustment)+max(OtherAdjustment)-(sum(coalesce(ActualFees,0))+sum(coalesce(PlannedRemainingFees1,0))))>0
		 then 0
		 else max(ContractAmount)+max(ContractorAdjustment)+max(ExpenseAdjustment)+max(OtherAdjustment)-(sum(coalesce(ActualFees,0))+sum(coalesce(PlannedRemainingFees1,0))) 
	end as WriteUpWriteOffWithAdjustments,
	case when BillingType='Hourly' and (max(LaborBudget)-(sum(coalesce(ActualFees,0))+sum(coalesce(PlannedRemainingFees1,0))))>0 
		 then 0
		 else max(LaborBudget)-(sum(coalesce(ActualFees,0))+sum(coalesce(PlannedRemainingFees1,0)))
	end as WriteUpWriteOff,
	case when BillingType='Hourly' and (max(LaborBudget)+max(ContingencyAmount))-sum(ExpectedFees1)>0
		 then 0
		 else (max(LaborBudget)+max(ContingencyAmount))-sum(ExpectedFees1) 
	end as WriteUpWriteOffWithContingency1,
	case when BillingType='Hourly' and (max(ContractAmount)+max(ContingencyAmount)+max(ContractorAdjustment)+max(ExpenseAdjustment)+max(OtherAdjustment)-sum(ExpectedFees1))>0
		 then 0
		 else max(ContractAmount)+max(ContractorAdjustment)+max(ExpenseAdjustment)+max(OtherAdjustment)-sum(ExpectedFees1) 
	end as WriteUpWriteOffWithContingency2,
	case when BillingType='Hourly' and (max(ContractAmount)+max(ContractorAdjustment)+max(ExpenseAdjustment)+max(OtherAdjustment)-sum(ExpectedFees1))>0
		 then 0
		 else max(ContractAmount)+max(ContractorAdjustment)+max(ExpenseAdjustment)+max(OtherAdjustment)-sum(ExpectedFees1) 
	end as WriteUpWriteOffWithAdjustments1,
	case when BillingType='Hourly' and (max(LaborBudget)-sum(ExpectedFees1))>0 
		 then 0
		 else max(LaborBudget)-sum(ExpectedFees1)
	end as WriteUpWriteOff1,
	case when (sum(ActualHours)+sum(PlannedRemainingHours))=0 then 0 else max(LaborBudget)/(sum(ActualHours)+sum(PlannedRemainingHours)) end as ProjectRealization,
	max(BaselineProfitabilityCRM) as BaselineProfitabilityCRM,
	max(BaselineProfitabilityPercentCRM) as BaselineProfitabilityPercentCRM,
	max(LaborBudget)+max(ContingencyAmount)-sum(ExpectedInternalCost) as ProjectedProfitability,
	case when max(LaborBudget)=0 then 0 else (max(LaborBudget)+max(ContingencyAmount)-sum(ExpectedInternalCost))/max(LaborBudget) end as ProjectedProfitabilityPercent
from
	BG_EAC_SummaryDetail_CG
group by
	Region,
	Customer,
	Engagement,
	EngagementId,
	Project,
	ProjectId,
	ProjectStatus,
	BillingType,
	ProjectManager,
	AccountExecutive,
	EngagementType,
	BaselineStart,
	BaselineFinish,
	PlannedStart,
	PlannedFinish,
	ActualStart,
	ActualFinish,
	EngagementCloseDate,
	ProjectDescription







GO
