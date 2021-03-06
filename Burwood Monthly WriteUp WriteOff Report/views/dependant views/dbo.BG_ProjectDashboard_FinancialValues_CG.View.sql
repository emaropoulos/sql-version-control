USE [Changepoint2018]
GO
/****** Object:  View [dbo].[BG_ProjectDashboard_FinancialValues_CG]    Script Date: 10/11/2019 1:49:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






--select * from [BG_EngagementProjectFinancialValues_CG] where EngagementStatus='Work in Progress'


-- add union to engagements with multiple projects total line
CREATE view [dbo].[BG_ProjectDashboard_FinancialValues_CG] as
with a as (
select
	cst.Name as Customer,
	cst.CustomerId,
	e.EngagementId,
	e.OpportunityId,
	r.Description as Region,
	e.Name as Engagement,
	ests.Description as EngagementStatus,
	bt.Description as BillingType,
	eb.Description as ExpenseBillingType,
	er.RequestType,
	p.Name as Project,
	p.ProjectId,
	pms.ProjectManager,
	ps.Description as ProjectStatus,
	coalesce(e.ContractAmount,0) as POContractAmount,
	--coalesce(p.LabourBudget,0)+coalesce(p.ExpenseBudget,0)+coalesce(p.OtherExpenseBudget,0)+coalesce(convert(numeric(38,2), c.UDFText),0) as POContractAmountCalculated,
	case when e.ExpenseBillingType='N' 
		 then coalesce(p.LabourBudget,0)+coalesce(p.ExpenseBudget,0)+coalesce(p.OtherExpenseBudget,0)+coalesce(fm.UDFNumber,0)+coalesce(convert(numeric(38,2), c.UDFText),0)
		 when e.ExpenseBillingTYpe='A' and e.BillingType='F'
		 then coalesce(p.LabourBudget,0)+coalesce(p.OtherExpenseBudget,0)+coalesce(fm.UDFNumber,0)+coalesce(convert(numeric(38,2), c.UDFText),0) 
		 when e.ExpenseBillingTYpe='A' and e.BillingType='H'
		 then coalesce(p.LabourBudget,0)+coalesce(p.ExpenseBudget,0)+coalesce(p.OtherExpenseBudget,0)+coalesce(fm.UDFNumber,0)+coalesce(convert(numeric(38,2), c.UDFText),0) 
		 else coalesce(p.LabourBudget,0)+coalesce(p.ExpenseBudget,0)+coalesce(p.OtherExpenseBudget,0)+coalesce(fm.UDFNumber,0)+coalesce(convert(numeric(38,2), c.UDFText),0)
	end as POContractAmountCalculated,
	--e.ContractAmount-(coalesce(p.LabourBudget,0)+coalesce(p.ExpenseBudget,0)+coalesce(p.OtherExpenseBudget,0)+coalesce(fm.UDFNumber,0)+coalesce(convert(numeric(38,2), c.UDFText),0)) as 'Difference',
	coalesce(p.LabourBudget,0) as ServicesAmount,
	coalesce(p.ExpenseBudget,0) as ExpenseAmount,
	coalesce(p.OtherExpenseBudget,0) as FixedFeeContractorPassThroughAmount,
	coalesce(convert(numeric(38,2), c.UDFText),0) as ContingencyAmount,
	coalesce(fm.UDFNumber,0) as FixedFeeSubContractorMargin,
	coalesce(ec.UDFNumber,0) as EstimationCost,
	coalesce(es.UDFNumber,0) as EstimationSell,
	coalesce(pm.UDFNumber,0) as PlannedMarginPercent,
	coalesce(pc.UDFNumber,0) as PlannedCostBudget,
	coalesce(pp.UDFNumber,0) as PlannedProfitability,
	coalesce(rd.UDFNumber,0) as 'Risk$',
	coalesce(rp.UDFNumber,0) as 'Risk%',
	--p.ProjectId,
	(select count(*) from Project where EngagementId=e.EngagementId) NumberOfProjects,
	case when (select count(*) from Project where EngagementId=e.EngagementId) >1 then 'Yes' else 'No' end as MultipleProjects,
	convert(decimal(10,2), coalesce(eh.UDFNumber,0)) as EstimatedHours
from
	Engagement e with (nolock)
		join
	EngagementStatus ests with (nolock) on e.EngagementStatus=ests.Code
		left outer join
	ExpenseBillingType eb with (nolock) on e.ExpenseBillingType=eb.Code
		left outer join
	BillingType bt with (nolock) on e.BillingType=bt.Code
		LEFT OUTER JOIN
	EngRequestBillingRule er WITH (NOLOCK) ON e.EngagementId=er.EngagementId
		join
	Customer cst with (nolock) on e.CustomerId=cst.CustomerId
		join
	BillingOffice r with (nolock) on e.BillingOfficeId=r.BillingOfficeId
		join
	Project p with (nolock) on e.EngagementId=p.EngagementId
		left outer join
	BG_ProjectManager_CG pms with (nolock) on p.ProjectId=pms.ProjectId
		left outer join
	ProjectStatus ps with (nolock) on p.ProjectStatus=ps.Code
		left outer join
	UDFText c with (nolock) on c.EntityId=p.ProjectId and c.ItemName='ProjectText1'
		left outer join
	UDFNumber fp with (nolock) on fp.EntityId=p.ProjectId and fp.ItemName='ProjectText5'
		left outer join
	UDFNumber fm with (nolock) on fm.EntityId=p.ProjectId and fm.ItemName='ProjectText4'
		left outer join
	UDFNumber ec with (nolock) on ec.EntityId=p.ProjectId and ec.ItemName='ProjectText6'
		left outer join
	UDFNumber es with (nolock) on es.EntityId=p.ProjectId and es.ItemName='ProjectText7'
		left outer join
	UDFNumber pm with (nolock) on pm.EntityId=p.ProjectId and pm.ItemName='ProjectText8'
		left outer join
	UDFNumber pc with (nolock) on pc.EntityId=p.ProjectId and pc.ItemName='ProjectText9'
		left outer join
	UDFNumber pp with (nolock) on pp.EntityId=p.ProjectId and pp.ItemName='ProjectText10'
		left outer join
	UDFNumber rd with (nolock) on rd.EntityId=p.ProjectId and rd.ItemName='ProjectText11'
		left outer join
	UDFNumber rp with (nolock) on rp.EntityId=p.ProjectId and rp.ItemName='ProjectText12'
		left outer join
	UDFNumber eh with (nolock) on eh.EntityId=e.OpportunityId and eh.ItemName='OpportunityText31'

where
	e.Deleted=0
	and p.Deleted=0
	and cst.CustomerId not in ('D6FCCBED-6B49-4914-BA89-9CB554DB1165', '921E8672-8A4B-482E-85D3-8D545E5D1C2A')
	and e.Name  not in ('Promo Account-Western Digital', 'Rasmussen Promo Bucket')
	--and p.Name='Allscripts SBH Health Systems Core Switch Replacement'

	--select * from Engagement where Name='Sales Promo-Presales (Varone)'
),
b as (
select
	Customer,
	CustomerId,
	EngagementId,
	OpportunityId,
	Region,
	Engagement,
	EngagementStatus,
	BillingType,
	ExpenseBillingType,
	NULL as RequestType,
	NULL as Project,
	NULL as ProjectId,
	NULL as ProjectManager,
	NULL as ProjectStatus,
	max(coalesce(POContractAmount,0)) as POContractAmount,
	case when ExpenseBillingType='N' 
		 then sum(ServicesAmount)+sum(ExpenseAmount)+sum(FixedFeeContractorPassThroughAmount)+sum(FixedFeeSubContractorMargin)+sum(ContingencyAmount)
		 when ExpenseBillingTYpe='A' and BillingType='F'
		 then sum(ServicesAmount)+sum(FixedFeeContractorPassThroughAmount)+sum(FixedFeeSubContractorMargin)+sum(ContingencyAmount)
		 when ExpenseBillingTYpe='A' and BillingType='H'
		 then sum(ServicesAmount)+sum(ExpenseAmount)+sum(FixedFeeContractorPassThroughAmount)+sum(FixedFeeSubContractorMargin)+sum(ContingencyAmount)
		 else sum(ServicesAmount)+sum(ExpenseAmount)+sum(FixedFeeContractorPassThroughAmount)+sum(FixedFeeSubContractorMargin)+sum(ContingencyAmount)
	end as POContractAmountCalculated,
	sum(ServicesAmount) as ServicesAmount,
	sum(ExpenseAmount) as ExpenseAmount,
	sum(FixedFeeContractorPassThroughAmount) as FixedFeeContractorPassThroughAmount,
	sum(ContingencyAmount) as ContingencyAmount,
	sum(FixedFeeSubContractorMargin) as FixedFeeSubContractorMargin,
	sum(EstimationCost) as EstimationCost,
	sum(EstimationSell) as EstimationSell,
	max(PlannedMarginPercent) as PlannedMarginPercent,
	sum(PlannedCostBudget) as PlannedCostBudget,
	sum(PlannedProfitability) as PlannedProfitability,
	sum(Risk$) as Risk$,
	max([Risk%]) as 'Risk%',
	max(NumberOfProjects) as NumberOfProjects,
	MultipleProjects,
	EstimatedHours
from
	a
where MultipleProjects='Yes'
group by
	Customer,
	Region,
	Engagement,
	EngagementStatus,
	BillingTYpe,
	ExpenseBillingType,
	CustomerId,
	EngagementId,
	OpportunityId,
	MultipleProjects,
	EstimatedHours
),
c as (
select
	1 as TypeCode,
	'Project' as Type,
	a.*,
	POContractAmount-POContractAmountCalculated as POContractAmountDifference,
	case when POContractAmount-POContractAmountCalculated <>0 
	then 'No'
	else 'Yes'
	end as POContractAmountMatches,
	MultipleProjects+' - '+convert(varchar(10), NumberofProjects) as MultipleProjectsDisplay,
	convert(numeric(23,2), coalesce(o.ContractAmount,0)) as POContractAmountCRM,
	convert(numeric(38,2), coalesce(o.ServicesAmount,0)) as ServicesAmountCRM,
	convert(numeric(38,2), coalesce(o.ExpenseAmount,0)) as ExpenseAmountCRM,
	convert(numeric(38,2), coalesce(o.FixedFeeContractorPassThroughAmount,0)) as FixedFeeContractorPassThroughAmountCRM,
	convert(numeric(38,4), coalesce(o.FixedFeeSubcontractorMargin,0)) as FixedFeeSubcontractorMarginCRM,
	convert(numeric(38,4), coalesce(o.EstimationCost,0)) as EstimationCostCRM,
	convert(numeric(38,4), coalesce(o.EstimationSell,0)) as EstimationSellCRM,
	convert(numeric(38,4), coalesce(o.EstimatedHours,0)) as EstimatedHoursCRM,
	convert(numeric(28,4), coalesce(o.EstimatedProfitability,0)) as PlannedMarginPercentCRM,
	convert(numeric(38,4), coalesce(o.EstimatedServicesMargin,0)) as PlannedProfitabilityCRM,
	coalesce(a.ServicesAmount,0)*convert(numeric(28,4), coalesce(o.EstimatedProfitability,0)) as PlannedCostBudgetCRM,
	case when a.POContractAmount=convert(numeric(23,2), coalesce(o.ContractAmount,0))
		 then 'Yes'
		 else 'No'
	end as POContractAmountMatchesCRM,
	case when a.ServicesAmount=convert(numeric(38,2), coalesce(o.ServicesAmount,0))
		 then 'Yes'
		 else 'No'
	end as ServicesAmountMatches,
	case when a.ExpenseAmount=convert(numeric(38,2), coalesce(o.ExpenseAmount,0))
		 then 'Yes'
		 else 'No'
	end as ExpenseAmountMatches,
	case when a.FixedFeeContractorPassThroughAmount=convert(numeric(38,2), coalesce(o.FixedFeeContractorPassThroughAmount,0))
		 then 'Yes'
		 else 'No'
	end as FixedFeeContractorPassThroughAmountMatches,
	case when a.FixedFeeSubContractorMargin=convert(numeric(38,4), coalesce(o.FixedFeeSubcontractorMargin,0))
		 then 'Yes'
		 else 'No'
	end as FixedFeeSubContractorMarginMatches,
	case when a.EstimationCost=convert(numeric(38,4), coalesce(o.EstimationCost,0))
		 then 'Yes'
		 else 'No'
	end as EstimationCostMatches,
	case when a.EstimationSell=convert(numeric(38,4), coalesce(o.EstimationSell,0))
		 then 'Yes'
		 else 'No'
	end as EstimationSellMatches,
	case when a.EstimatedHours=convert(numeric(38,4), coalesce(o.EstimatedHours,0))
		 then 'Yes'
		 else 'No'
	end as EstimatedHoursMatches,
	case when a.PlannedMarginPercent=convert(numeric(28,4), coalesce(o.EstimatedProfitability,0))
		 then 'Yes'
		 else 'No'
	end as PlannedMarginPercentMatches,
	case when a.PlannedProfitability=convert(numeric(38,4), coalesce(o.EstimatedServicesMargin,0))
		 then 'Yes'
		 else 'No'
	end as PlannedProfitabilityMatches,
	case when a.PlannedCostBudget=coalesce(a.ServicesAmount,0)*convert(numeric(28,4), coalesce(o.EstimatedProfitability,0))
		 then 'Yes'
		 else 'No'
	end as PlannedCostBudgetMatches,
	o.OppURL,
	o.Opportunity,
	o.TechnicalArchitect,
	o.TechnicalArchitect2,
	o.TechnicalArchitect3
from
	a
		left outer join
	[chil-crm-04].[BurwoodGroupInc_MSCRM].[dbo].[BG_ChangepointServicesFields_CG] o with (nolock) on a.OpportunityId=o.OpportunityId
--where MultipleProjects='Yes'

union all 

select
	2 as TypeCode,
	'Engagement' as Type,
	b.*,
	POContractAmount-POContractAmountCalculated as POContractAmountDifference,
	case when POContractAmount-POContractAmountCalculated <>0 
	then 'No'
	else 'Yes'
	end as POContractAmountMatches,
	MultipleProjects+' - '+convert(varchar(10), NumberofProjects) as MultipleProjectsDisplay,
	convert(numeric(23,2), coalesce(o.ContractAmount,0)) as POContractAmountCRM,
	convert(numeric(38,2), coalesce(o.ServicesAmount,0)) as ServicesAmountCRM,
	convert(numeric(38,2), coalesce(o.ExpenseAmount,0)) as ExpenseAmountCRM,
	convert(numeric(38,2), coalesce(o.FixedFeeContractorPassThroughAmount,0)) as FixedFeeContractorPassThroughAmountCRM,
	convert(numeric(38,4), coalesce(o.FixedFeeSubcontractorMargin,0)) as FixedFeeSubcontractorMarginCRM,
	convert(numeric(38,4), coalesce(o.EstimationCost,0)) as EstimationCostCRM,
	convert(numeric(38,4), coalesce(o.EstimationSell,0)) as EstimationSellCRM,
	convert(numeric(38,4), coalesce(o.EstimatedHours,0)) as EstimatedHoursCRM,
	convert(numeric(28,4), coalesce(o.EstimatedProfitability,0)) as PlannedMarginPercentCRM,
	convert(numeric(38,4), coalesce(o.EstimatedServicesMargin,0)) as PlannedProfitabilityCRM,
	coalesce(b.ServicesAmount,0)*convert(numeric(28,4), coalesce(o.EstimatedProfitability,0)) as PlannedCostBudgetCRM,
	case when b.POContractAmount=convert(numeric(23,2), coalesce(o.ContractAmount,0))
		 then 'Yes'
		 else 'No'
	end as POContractAmountMatchesCRM,
	case when b.ServicesAmount=convert(numeric(38,2), coalesce(o.ServicesAmount,0))
		 then 'Yes'
		 else 'No'
	end as ServicesAmountMatches,
	case when b.ExpenseAmount=convert(numeric(38,2), coalesce(o.ExpenseAmount,0))
		 then 'Yes'
		 else 'No'
	end as ExpenseAmountMatches,
	case when b.FixedFeeContractorPassThroughAmount=o.FixedFeeContractorPassThroughAmount
		 then 'Yes'
		 else 'No'
	end as FixedFeeContractorPassThroughAmountMatches,
	case when b.FixedFeeSubContractorMargin=convert(numeric(38,4), coalesce(o.FixedFeeSubcontractorMargin,0))
		 then 'Yes'
		 else 'No'
	end as FixedFeeSubContractorMarginMatches,
	case when b.EstimationCost=convert(numeric(38,4), coalesce(o.EstimationCost,0))
		 then 'Yes'
		 else 'No'
	end as EstimationCostMatches,
	case when b.EstimationSell=convert(numeric(38,4), coalesce(o.EstimationSell,0))
		 then 'Yes'
		 else 'No'
	end as EstimationSellMatches,
	case when b.EstimatedHours=convert(numeric(38,4), coalesce(o.EstimatedHours,0))
		 then 'Yes'
		 else 'No'
	end as EstimatedHoursMatches,
	case when b.PlannedMarginPercent=convert(numeric(28,4), coalesce(o.EstimatedProfitability,0))
		 then 'Yes'
		 else 'No'
	end as PlannedMarginPercentMatches,
	case when b.PlannedProfitability=convert(numeric(38,4), coalesce(o.EstimatedServicesMargin,0))
		 then 'Yes'
		 else 'No'
	end as PlannedProfitabilityMatches,
	case when b.PlannedCostBudget=coalesce(b.ServicesAmount,0)*convert(numeric(28,4), coalesce(o.EstimatedProfitability,0))
		 then 'Yes'
		 else 'No'
	end as PlannedCostBudgetMatches,
	o.OppURL,
	o.Opportunity,
	o.TechnicalArchitect,
	o.TechnicalArchitect2,
	o.TechnicalArchitect3
from
	b
		left outer join
	[chil-crm-04].[BurwoodGroupInc_MSCRM].[dbo].[BG_ChangepointServicesFields_CG] o with (nolock) on b.OpportunityId=o.OpportunityId
	)
select
	c.*
	--convert(decimal(10,2), coalesce(o.new_EstimatedHours,0)) as EstimatedHours
from
	c
	--	left outer join
	--[chil-crm-04].[BurwoodGroupInc_MSCRM].dbo.OpportunityBase o with (nolock) on  o.OpportunityId=c.OpportunityId
--where MultipleProjects='Yes'






GO
