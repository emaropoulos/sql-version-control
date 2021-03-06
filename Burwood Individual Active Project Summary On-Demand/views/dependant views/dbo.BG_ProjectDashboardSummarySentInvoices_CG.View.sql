USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_ProjectDashboardSummarySentInvoices_CG]    Script Date: 10/14/2019 11:52:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE view [dbo].[BG_ProjectDashboardSummarySentInvoices_CG] as 
select
	--'Burwood Group Inc.' as Company,
	p.*,
	si.Invoice as SentInvoice,
	si.InvoiceID as SentInvoiceId,
	si.InvoiceDate as SentInvoiceDate,
	coalesce(si.InvoiceTotal,0) as SentInvoiceTotal,
	si.Status as SentStatus,
	si.Paid as SentPaidStatus
from
	BG_ProjectDashboardSummaryScheduled_CG p with (nolock)
		join
	(select * from BG_ProjectDashboard_Invoices_CG where [Status] in ('Paid', 'Sent to Great Plains', 'Partially paid')) si on p.ProjectId=si.ProjectId
where
	p.ProjectStatus<>'C'
	--and p.Project='Akorn Pharmaceuticals- Network Services Staff Augmentation October 2017 (Stephen Lotho)'--'LACCD-UC District Wide Design and Oversight'
	--and f.FFSort<>1

GO
