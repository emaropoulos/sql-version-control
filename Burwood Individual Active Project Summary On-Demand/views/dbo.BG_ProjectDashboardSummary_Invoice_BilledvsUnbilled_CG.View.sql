USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_ProjectDashboardSummary_Invoice_BilledvsUnbilled_CG]    Script Date: 10/14/2019 11:47:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[BG_ProjectDashboardSummary_Invoice_BilledvsUnbilled_CG] as
with a as (
SELECT 
	f.EngagementID,
	f.ProjectId,
	f.Project,
	case when f.Billed=1 
		 then InvoicedAmount
		 else 0
	end as BilledAmount,
	case when coalesce(f.Billed,0)=0 and f.FFSort<>1
		 then BillingAmount
		 else 0
	end as UnBilledAmount,
	case when f.FFSort<>1
		 then BillingAmount
		 else 0
	end as InvoicedAmount
from
	BG_ProjectDashboard_FixedFeeSchedule_CG f with (nolock)
),
b as (
select 
	f.Project,
	f.ProjectId,
	f.EngagementID,
	sum(f.InvoiceTotal) as BilledAmount,
	max(f.POContractAmount)- sum(f.InvoiceTotal) as UnBilledAmount,
	max(f.POContractAmount) as InvoicedAmount
from
	BG_ProjectDashboard_Invoices2018_CG f with (nolock) --on p.ProjectId=f.ProjectId
where
	f.Project not in (select distinct Project from BG_ProjectDashboard_FixedFeeSchedule_CG)
	and f.Status not in ('Credited', 'Discarded')
group by
	f.Project,
	f.ProjectId,
	f.EngagementID
)
select
	'Fixed Fee' as Type,
	Project,
	ProjectId,
	EngagementID,
	sum(InvoicedAmount) as ScheduledInvoicedAmount,
	sum(BilledAmount) as BilledAmount,
	sum(UnBilledAmount) as UnBilledAmount
from
	a
group by
	Project,
	ProjectId,
	EngagementID

union all

select
	'Hourly' as Type,
	Project,
	ProjectId,
	EngagementID,
	coalesce(InvoicedAmount,0) as InvoicedAmount,
	coalesce(BilledAmount,0) as BilledAmount,
	coalesce(UnBilledAmount,0) as UnBilledAmount
from
	b

GO
