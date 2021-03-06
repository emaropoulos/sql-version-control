USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_ProjectDashboard_CRMValueCheck_CG]    Script Date: 9/30/2019 5:00:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[BG_ProjectDashboard_CRMValueCheck_CG] as 
with a as (
select
	e.EngagementId,
	e.OpportunityId,
	e.Name as Engagement,
	ests.Description as EngagementStatus,
	bt.Description as BillingType,
	eb.Description as ExpenseBillingType,
	er.RequestType,
	p.Name as Project,
	p.ProjectId,
	pms.ProjectManager,
	ps.Description as ProjectStatus,
	e.ContractAmount as POContractAmount,
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
	(select count(*) from Project where EngagementId=e.EngagementId) NumberOfProjects,
	case when (select count(*) from Project where EngagementId=e.EngagementId) >1 then 'Yes' else 'No' end as MultipleProjects,
	convert(decimal(10,2), eh.UDFNumber) as EstimatedHours
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
)
select
	a.Engagement,
	a.Project,
	a.POContractAmount,
	o.ContractAmount as POContractAmountCRM,
	a.ServicesAmount,
	o.ServicesAmount as ServicesAmountCRM,
	a.ExpenseAmount,
	o.ExpenseAmount as ExpenseAmountCRM,
	a.FixedFeeContractorPassThroughAmount,
	o.FixedFeeContractorPassThroughAmount as FixedFeeContractorPassThroughAmountCRM,
	a.FixedFeeSubContractorMargin,
	o.FixedFeeSubcontractorMargin as FixedFeeSubcontractorMarginCRM,
	a.EstimationCost,
	o.EstimationCost as EstimationCostCRM,
	a.EstimationSell,
	o.EstimationSell as EstimationSellCRM,
	a.EstimatedHours,
	o.EstimatedHours as EstimatedHoursCRM,
	a.PlannedMarginPercent,
	o.EstimatedProfitability as PlannedMarginPercentCRM,
	a.PlannedProfitability,
	o.EstimatedServicesMargin as PlannedProfitabilityCRM,
	
	case when a.POContractAmount=o.ContractAmount
		 then 'Yes'
		 else 'No'
	end as POContractAmountMatches,
	case when a.ServicesAmount=o.ServicesAmount
		 then 'Yes'
		 else 'No'
	end as ServicesAmountMatches,
	case when a.ExpenseAmount=o.ExpenseAmount
		 then 'Yes'
		 else 'No'
	end as ExpenseAmountMatches,
	case when a.FixedFeeContractorPassThroughAmount=o.FixedFeeContractorPassThroughAmount
		 then 'Yes'
		 else 'No'
	end as FixedFeeContractorPassThroughAmountMatches,
	case when a.FixedFeeSubContractorMargin=o.FixedFeeSubContractorMargin
		 then 'Yes'
		 else 'No'
	end as FixedFeeSubContractorMarginMatches,
	case when a.EstimationCost=o.EstimationCost
		 then 'Yes'
		 else 'No'
	end as EstimationCostMatches,
	case when a.EstimationSell=o.EstimationSell
		 then 'Yes'
		 else 'No'
	end as EstimationSellMatches,
	case when a.EstimatedHours=o.EstimatedHours
		 then 'Yes'
		 else 'No'
	end as EstimatedHoursMatches,
	case when a.PlannedMarginPercent=(case when o.EstimationSell=0 then 0 else (o.EstimationSell-o.EstimationCost)/o.EstimationSell end)
		 then 'Yes'
		 else 'No'
	end as PlannedMarginPercentMatches,
	case when a.PlannedProfitability=(o.ServicesAmount*(case when o.EstimationSell=0 then 0 else (o.EstimationSell-o.EstimationCost)/o.EstimationSell end))
		 then 'Yes'
		 else 'No'
	end as PlannedProfitabilityMatches,
	a.ExpenseBillingType,
	o.ExpenseOption,
	o.new_expenseoptions,
	a.RequestType,
	a.EngagementId,
	a.ProjectId,
	a.OpportunityId


	
from
	a
		join
	[chil-crm-04].[BurwoodGroupInc_MSCRM].[dbo].[BG_ChangepointServicesFields_CG] o with (nolock) on a.OpportunityId=o.OpportunityId



GO
