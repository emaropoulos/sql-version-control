USE [Changepoint2018]
GO
/****** Object:  View [dbo].[BG_WIP_2018_CG]    Script Date: 10/11/2019 1:49:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--select * from BG_WIP_2018_CG where Region='EA-Eastern Region'


CREATE view [dbo].[BG_WIP_2018_CG] as
with a as (
select
	distinct
	coalesce(b.Description, 'No Assigned Region') as Region,
	c.Name as Customer,
	coalesce(p.Name, 'No Practice Assigned') as Practice,
	coalesce(w.Name, 'No Assigned Workgroup') as Workgroup,
	coalesce(et.EngagementType, 'No Engagement Type Assigned') as EngagementType,
	o.AccountOwner,
	o.OpportunityOwner,
	e.Name as Engagement,
	e.EngagementId,
	pj.Name as Project,
	--pj.Deleted,
	case when coalesce(fp.ServicesAmount,0)=0 
		 then e.ContractAmount  
		 when coalesce(fp.ServicesAmount,0)<>0 and coalesce(e.ContractAmount,0)=0
		 then fp.ServicesAmount
		 when coalesce(fp.ServicesAmount,0)=0 and coalesce(e.ContractAmount,0)=0 
		 then 0
		 else fp.ServicesAmount
	end as ServicesAmount
FROM 
	BG_SummaryInvoiceAndRR_VIEW s
		join
	Engagement e with (nolock) on s.EngagementId=e.EngagementId
		left outer join
	Project pj with (nolock) on e.EngagementId=pj.EngagementId
		join
	Customer AS c  WITH (NOLOCK) ON e.CustomerId = c.CustomerId 
		left outer join
	Workgroup w with (nolock) on e.AssociatedWorkgroup=w.WorkgroupId
		left outer join
	CostCenters p with (nolock) on e.CostCenterId=p.CostCenter
		join
	BillingOffice b with (nolock) on e.BillingOfficeId=b.BillingOfficeId
		left outer join
	BG_EngagementTypeUDF_CG et with (nolock) on e.EngagementId=et.EngagementId
		left outer join
	EngagementStatus ests with (nolock) on e.EngagementStatus=ests.Code
		left outer join
	BG_WIP_UnBilledRevenue_CG u with (nolock) on s.EngagementId=u.EngagementId
		left outer join
	BG_AccountOpportunityOwners_CG o with (nolock) on e.EngagementId=o.EngagementId
		left outer join
	[BG_ProjectDashboard_FinancialValues_CG] fp with (nolock) on pj.EngagementId=fp.EngagementId and pj.ProjectId=fp.ProjectId
WHERE 
	e.BILLABLE = 1 
	AND e.EngagementStatus = 'W'  
	AND coalesce(e.DELETED,0)=0
	and coalesce(p.Deleted,0)=0
	and e.CustomerId not in ('3E09B148-69D8-4023-9F75-2AF9852D753E')
	and e.EngagementId not in ('185D1688-106F-4FA0-B31B-2BE9C18CF606', '54C58FE1-57F4-41F3-A771-0D67C84EEFF4', '4B009190-F3AC-41FA-9474-FF3A050001BB', '9F24B4FB-212C-4359-87E5-DA52BB6F61F6')
	--and b.Description='CS-Cloud Services'
),
b as (
SELECT 
	b.Description as Region,
	coalesce(p.Name, 'No Assigned Practice') as Practice,
	w.Name as Workgroup,
	case when et.EngagementType='' or et.EngagementType is NULL then 'Undefined' else et.EngagementType end as [Engagement Type],
	c.Name as Customer,
	case when e.Name='Carrier Services Support' then 'Account, CRM' else o.AccountOwner end as AccountOwner,
	o.OpportunityOwner,
	e.Name as Engagement,
	ests.Description as [Engagement Status],
	--(select max(PlannedFinish) from Project p1 where p1.EngagementId=e.EngagementId) as PlannedFinish,
	(select count(distinct Engagement) from a where a.Region=coalesce(b.Description, 'No Assigned Region')) as [# Engagements by Region],
	(select count(distinct Engagement) from a where a.Practice=coalesce(p.Name, 'No Practice Assigned')) as [# Engagements by Practice],
	(select count(distinct Engagement) from a where a.Workgroup=coalesce(w.Name, 'No Assigned Workgroup')) as [# Engagements by Workgroup],
	(select count(distinct Engagement) from a where a.EngagementType=coalesce(et.EngagementType, 'No Engagement Type Assigned')) as [# Engagements by Engagement Type],
	(select count(distinct Engagement) from a where a.Customer=c.Name) as [# Engagements by Customer],
	(select count(distinct Project) from a where a.Region=coalesce(b.Description, 'No Assigned Region')) as [# Projects by Region],
	(select count(distinct Project) from a where a.Practice=coalesce(p.Name, 'No Practice Assigned')) as [# Projects by Practice],
	(select count(distinct Project) from a where a.Workgroup=coalesce(w.Name, 'No Assigned Workgroup')) as [# Projects by Workgroup],
	(select count(distinct Project) from a where a.EngagementType=coalesce(et.EngagementType, 'No Engagement Type Assigned')) as [# Projects by Engagement Type],
	(select count(distinct Project) from a where a.Customer=c.Name) as [# Projects by Customer],
	
	--(select count(distinct Engagement) from a where a.Practice=coalesce(p.Name, 'No Practice Assigned')) as [# Engagements by Practice],
	--(select count(distinct Engagement.EngagementId) from Engagement join Workgroup on AssociatedWorkgroup=WorkgroupId where Engagement.Deleted=0 and Engagement.Billable=1 and EngagementStatus='W' and coalesce(Workgroup.Name, 'No Assigned Workgroup')=coalesce(w.Name, 'No Assigned Workgroup')) as [# Engagements by Workgroup],
	--(select count(distinct Engagement.EngagementId) from Engagement left outer join BG_EngagementTypeUDF_CG on BG_EngagementTypeUDF_CG.EngagementId=Engagement.EngagementId where Engagement.Deleted=0 and Engagement.Billable=1 and Engagement.EngagementStatus='W' and coalesce(BG_EngagementTypeUDF_CG.EngagementType, 'Undefined')=case when et.EngagementType='' or et.EngagementType is NULL then 'Undefined' else et.EngagementType end) as [# Engagements by Engagement Type],
	--(select count(distinct Engagement.EngagementId) from Engagement join Customer on Customer.CustomerId=Engagement.CustomerId where Engagement.Deleted=0 and Engagement.Billable=1 and EngagementStatus='W' and Customer.Name=c.Name) as [# Engagements by Customer],
	--(select count(distinct Engagement.EngagementId) from Engagement join BillingOffice on Engagement.BillingOfficeId=BillingOfice.BillingOfficeId where Engagement.Deleted=0 and Engagement.Billable=1 and EngagementStatus='W' and coalesce(BillingOffice.Description, 'No Assigned Region')=coalesce(b.Description, 'No Assigned Region')) as [# Engagements by Region],
	--(select count(*) from Engagement ec where pj.EngagementId=e.EngagementId and pj.Deleted=0 and pj.Billable=1) as [# Projects],
	(select count(*) from Project pj where pj.EngagementId=e.EngagementId and pj.Deleted=0 and pj.Billable=1) as [# Projects],
	(select count(distinct Engagement) from a where a.AccountOwner=o.AccountOwner) as [# Engagements by Account Owner],
	(select count(distinct Engagement) from a where a.OpportunityOwner=o.OpportunityOwner) as [# Engagements by Opportunity Owner],
	(select count(distinct Project) from a where a.AccountOwner=o.AccountOwner) as [# Projects by Account Owner],
	(select count(distinct Project) from a where a.OpportunityOwner=o.OpportunityOwner) as [# Projects by Opportunity Owner],
	--(select count(distinct ao.Engagement) from BG_AccountOpportunityOwners_CG ao where ao.EngagementStatus='W' and ao.AccountOwner=o.AccountOwner) as [AccountOwner#Engagements],
	--(select count(distinct ao.Project) from BG_AccountOpportunityOwners_CG ao where ao.EngagementStatus='W' and ao.ProjectStatus<>'C' and ao.AccountOwner=o.AccountOwner) as [AccountOwner#Projects],
	--(select count(distinct ao.Engagement) from BG_AccountOpportunityOwners_CG ao where ao.EngagementStatus='W' and ao.OpportunityOwner=o.OpportunityOwner) as [OppOwner#Engagements],
	--(select count(distinct ao.Project) from BG_AccountOpportunityOwners_CG ao where ao.EngagementStatus='W' and ao.ProjectStatus<>'C' and ao.OpportunityOwner=o.OpportunityOwner) as [OppOwner#Projects],
	convert(date, e.CreatedOn) as [Engagement Created On],
	o.WonDate as [Won Date],
	--(select WonDate from [chil-crm-04].[BurwoodGroupInc_MSCRM].dbo.BG_OpportunityProjectType_CG where OpportunityId=e.OpportunityId) as [Won Date],
	(select max(convert(date, p.PlannedFinish)) from Project p with (nolock) where p.EngagementId=e.EngagementId) as [Planned Finish],
	(select sum(ServicesAmount) from a p1 with (nolock) where p1.EngagementId=e.EngagementId) as ServicesAmount,
	SUM(e.ContractAmount) [PO/Contract Amount], 
	SUM(s.InvoiceAmount) [Hourly Amount],
	SUM(s.RRAmount) [Fixed Fee Amount],
	sum((coalesce(e.ContractAmount,0))-(coalesce(s.InvoiceAmount,0)+coalesce(s.RRAmount,0))) as WIP,
	sum((coalesce(s.InvoiceAmount,0)+coalesce(s.RRAmount,0))) as TotalAmountBilled,
	sum((coalesce(s.InvoiceAmount,0)+coalesce(s.RRAmount,0)+coalesce(u.RateTimesHours,0))) as TotalAmountwithUnbilled,
	sum(coalesce(u.RateTimesHours,0)) as UnbilledAmount,
	sum((coalesce(e.ContractAmount,0))-(coalesce(s.InvoiceAmount,0)+coalesce(s.RRAmount,0)+coalesce(u.RateTimesHours,0))) as WIPWithUnbilled,
	coalesce((select sum(f.ForecastRevenue) from BG_ProjectDashboard_ForecastSummary_CG f where e.EngagementId=f.EngagementId),0) as ForecastRevenue

	--SUM((( ISNULL(e.ContractAmount,  0) ) -(  ( ISNULL(s.InvoiceAmount,  0) ) + ( ISNULL(s.RRAmount,  0) ) ))) WIP
FROM 
	BG_SummaryInvoiceAndRR_VIEW s
		join
	Engagement e with (nolock) on s.EngagementId=e.EngagementId
		join
	Customer AS c  WITH (NOLOCK) ON e.CustomerId = c.CustomerId 
		left outer join
	Workgroup w with (nolock) on e.AssociatedWorkgroup=w.WorkgroupId
		left outer join
	CostCenters p with (nolock) on e.CostCenterId=p.CostCenter
		join
	BillingOffice b with (nolock) on e.BillingOfficeId=b.BillingOfficeId
		left outer join
	BG_EngagementTypeUDF_CG et with (nolock) on e.EngagementId=et.EngagementId
		left outer join
	EngagementStatus ests with (nolock) on e.EngagementStatus=ests.Code
		left outer join
	BG_WIP_UnBilledRevenue_CG u with (nolock) on s.EngagementId=u.EngagementId
		left outer join
	BG_AccountOpportunityOwners_CG o with (nolock) on e.EngagementId=o.EngagementId
	--	left outer join
	--BG_WIP_EngagementProjectCounts_CG cnt with (nolock) on (cnt.TypeEP='Engagement' and cnt.Type='Workgroup' and cnt.ID=e.AssociatedWorkgroup) or (cnt.TypeEP='Engagement' and cnt.Type='Region' and cnt.ID=e.BillingOfficeId) or (cnt.TypeEP='Engagement' and cnt.Type='Practice' and cnt.ID=e.CostCenterId) or (cnt.TypeEP='Engagement' and cnt.Type='Customer' and cnt.ID=e.CustomerId) or (cnt.TypeEP='Engagement' and cnt.Type='Workgroup' and cnt.ID=e.AssociatedWorkgroup)
WHERE 
	e.BILLABLE = 1 
	AND e.EngagementStatus = 'W'  
	AND coalesce(e.DELETED,0) = 0
	and e.CustomerId not in ('3E09B148-69D8-4023-9F75-2AF9852D753E')
	and e.EngagementId not in ('185D1688-106F-4FA0-B31B-2BE9C18CF606', '54C58FE1-57F4-41F3-A771-0D67C84EEFF4', '4B009190-F3AC-41FA-9474-FF3A050001BB', '9F24B4FB-212C-4359-87E5-DA52BB6F61F6')
	--and b.Description='CS-Cloud Services'
	--and e.EngagementId='54EB00D0-CB99-4F92-B34D-50FCC836BB42'
	--and w.Name='Data Center (Wons)'
GROUP BY 
	b.Description,
	p.Name,
	w.Name,
	et.EngagementType,
	c.Name,
	o.AccountOwner,
	o.OpportunityOwner,
	o.WonDate,
	e.Name,
	e.EngagementId,
	e.OpportunityId,
	e.CreatedOn,
	ests.Description
)
select
	*,
	((coalesce(ServicesAmount,0))-(coalesce([Hourly Amount],0)+coalesce([Fixed Fee Amount],0)+coalesce(UnbilledAmount,0))) as WIPServicesUnbilled
from
	b
--having 
--	SUM(s.InvoiceAmount)>0
--	and SUM(s.RRAmount)>0



GO
