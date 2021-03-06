USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_ProjectDashboard_Engagement_Old_CG]    Script Date: 10/14/2019 3:21:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO













--select * from [BG_ProjectDashboard_Engagement_CG] where ProjectPotentialFees<>EngagementPotentialFees


CREATE VIEW [dbo].[BG_ProjectDashboard_Engagement_Old_CG] AS
with en as 
(
select
	e.Name as Engagement,
	e.EngagementId,
	e.EngagementStatus,
	p.Name as Project,
	p.ProjectId,
	coalesce(p.LabourBudget,0) as LaborBudget,
	coalesce(p.ExpenseBudget,0) as ExpenseBudget,
	coalesce(p.OtherExpenseBudget,0) as OtherExpenseBudget,
	coalesce(p.BaselineHours,0) as BaselineHours,
	coalesce(p.ActualHours,0) as ActualHours,
	coalesce(p.PlannedHours,0) as PlannedHours,
	coalesce(convert(decimal(10,2), u.UDFText),0) as ContingencyAmount,
	e.ContractNumber,
	e.ContractAmount,
	coalesce(e.RevRec,0) as RevRec,
	e.RevAdjTotal,
	(select BillableHours from [BG_ProjectDashboard_ProjectBillableHoursPotentialFeesRevenueRecognized3test_CG](e.EngagementId)) as ProjectBillableHours,
	(select PotentialFees from [BG_ProjectDashboard_ProjectBillableHoursPotentialFeesRevenueRecognized3test_CG](e.EngagementId)) as ProjectPotentialFees,
	(select RevenueRecognized from [BG_ProjectDashboard_ProjectBillableHoursPotentialFeesRevenueRecognized3test_CG](e.EngagementId)) as ProjectRevenueRecognized,
	(select Adjustments from [BG_ProjectDashboard_ProjectBillableHoursPotentialFeesRevenueRecognized3test_CG](e.EngagementId)) as Adjustments,
	(select WriteUpWriteOff from [BG_ProjectDashboard_ProjectBillableHoursPotentialFeesRevenueRecognized3test_CG](e.EngagementId)) as WriteUpWriteOff,
	--(select BillableHours from BG_ProjectDashboard_EngagementBillableHoursPotentialFeesRevenueRecognized_CG(e.EngagementId)) as EngagementBillableHours,
	--(select PotentialFees from BG_ProjectDashboard_EngagementBillableHoursPotentialFeesRevenueRecognized_CG(e.EngagementId)) as EngagementPotentialFees,
	--(select RevenueRecognized from BG_ProjectDashboard_EngagementBillableHoursPotentialFeesRevenueRecognized_CG(e.EngagementId)) as EngagementRevenueRecognized,
	coalesce(f.ForecastHours,0) as ForecastHours,
	coalesce(f.ForecastRevenue,0) as ForecastRevenue,
	e.RevRecDate,
	e.ContractAmount-e.RevRec-e.RevAdjTotal as RemainingContractAmount,
	bt.Description as BillingType,
	pt.Description as PaymentTerms,
	e.OtherBillingInformation,
	ebt.Description as ExpenseBillingType,
	fv.POContractAmountCalculated,
      fv.ServicesAmount,
      fv.ExpenseAmount,
      fv.FixedFeeContractorPassThroughAmount,
      fv.FixedFeeSubContractorMargin,
      fv.EstimationCost,
      fv.EstimationSell,
      fv.PlannedMarginPercent,
      fv.PlannedCostBudget,
      fv.PlannedProfitability,
      fv.[Risk$],
      fv.[Risk%],
      fv.NumberOfProjects,
      fv.MultipleProjects,
      fv.POContractAmountDifference,
      fv.POContractAmountMatches,
      fv.MultipleProjectsDisplay,
	  (select sum(ExpectedInternalCost) from [BG_EAC_Summary_CG] eac where eac.EngagementId=e.EngagementId) as ExpectedInternalCost
from
	dbo.Engagement e with (nolock)
		join
	BG_ProjectDashboard_FinancialValues_CG fv with (nolock) on e.EngagementId=fv.EngagementId
		join
	dbo.BillingType bt with (nolock) on e.BillingType=bt.Code
		join
	dbo.PaymentTerms pt with (nolock) on e.PaymentTerms=pt.Code
		join
	dbo.Project p with (nolock) on e.EngagementId=p.EngagementId
		join
	ExpenseBillingType ebt with (nolock) on e.ExpenseBillingType=ebt.Code
		left outer join
	BG_ProjectDashboard_ForecastSummary_CG f with (nolock) on e.EngagementId=f.EngagementId and p.ProjectId=f.ProjectId
		left outer join
	UDFText u with (nolock) on u.EntityId=e.EngagementId and u.ItemName='EngagementText7'
		
	--where p.Name='UCHC NHT Project'
--where p.Name='Wake Forest - Avaya to Cisco Refresh'
--where e.EngagementId='ACD68E26-0684-4A28-9333-F7BBEB38FF8F'
)
select
	Engagement,
	EngagementId,
	BillingType,
	PaymentTerms,
	OtherBillingInformation,
	ExpenseBillingType,
	EngagementStatus,
	Project,
	ProjectId,
	LaborBudget,
	ExpenseBudget,
	OtherExpenseBudget,
	BaselineHours,
	ActualHours,
	PlannedHours,
	ForecastHours,
	ContingencyAmount,
	ContractNumber,
	ContractAmount,
	RevRec,
	Adjustments as RevAdjTotal,
	ProjectBillableHours,
	ProjectPotentialFees,
	ProjectRevenueRecognized,
	--EngagementBillableHours,
	--EngagementPotentialFees,
	--EngagementRevenueRecognized,
	ForecastRevenue,
	RevRecDate,
	RemainingContractAmount as RemainingContractAmount1,
	ContractAmount-ProjectPotentialFees+Adjustments as RemainingContractAmount,
	WriteUpWriteOff as ForecastRemainingContractAmount,
	LaborBudget-ProjectPotentialFees as ProjectRemainingAmount,
	LaborBudget-ProjectPotentialFees-ForecastRevenue ProjectPlannedRemainingAmount,
	--ContractAmount-EngagementPotentialFees+Adjustments-ForecastRevenue as EngagementWriteUpWriteOff,
	WriteUpWriteOff as TheRealWriteUpWriteOff,
	LaborBudget-ProjectPotentialFees-ForecastRevenue as NewWriteUpWriteOff,  --ProjectWriteUpWriteOff Amount
	--case when ActualHours=0 
	--	 then 0 
	--	 else (case when EngagementRevenueRecognized=0 then coalesce(RevRec,0)+coalesce(RevAdjTotal,0) else EngagementRevenueRecognized end )/ActualHours 
	--end as EngagementRealizationRate,
	case when ActualHours=0 
		 then 0 
		 else (coalesce(ProjectRevenueRecognized,0)+coalesce(ForecastRevenue,0))/(ActualHours+ForecastHours) 
	end as ProjectRealizationRate,
	POContractAmountCalculated,
	ServicesAmount,
      ExpenseAmount,
      FixedFeeContractorPassThroughAmount,
      FixedFeeSubContractorMargin,
      EstimationCost,
      EstimationSell,
      PlannedMarginPercent,
      PlannedCostBudget,
      PlannedProfitability,
      [Risk$],
      [Risk%],
      NumberOfProjects,
      MultipleProjects,
      POContractAmountDifference,
      POContractAmountMatches,
      MultipleProjectsDisplay,
	  ExpectedInternalCost,
	  case when ( ((-[ProjectPotentialFees])+(-[ForecastRevenue])) *-1 )=0 then 0 else ( ( ((-[ProjectPotentialFees])+(-[ForecastRevenue])) *-1 ) - ExpectedInternalCost ) / ( ((-[ProjectPotentialFees])+(-[ForecastRevenue])) *-1 ) end as CPInputMargin,
	  case when LaborBudget=0 then 0 else (LaborBudget-ProjectPotentialFees-ForecastRevenue)/LaborBudget end as ServicesDifference,
	  case when BillingType='Hourly' and ExpenseBillingType='No expenses' 
		   then 'Invalid Expense Configuration'
		   when BillingType='Fixed Fee' and ExpenseBillingType='No expenses' and ExpenseBudget=0 
		   then 'No Expense Budget Defined'
		   else 'OK'
	  end as BillingTypeErrorCheck,
	  case when BillingType='Hourly' and (LaborBudget+ExpenseBudget)=ContractAmount 
		   then 'Customer PO amount includes expenses'
		   when BillingType='Hourly' and LaborBudget=ContractAmount
		   then 'Customer PO only includes services'
		   else ''
	  end as ContractAmountIncludesErrorCheck
from
	en
--where
--	Engagement='Western Digital - WD Firewall Standardization - Phases 1-4'

















GO
