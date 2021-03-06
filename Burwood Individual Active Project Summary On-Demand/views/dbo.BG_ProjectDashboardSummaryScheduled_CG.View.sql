USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_ProjectDashboardSummaryScheduled_CG]    Script Date: 10/14/2019 11:47:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



--select count(distinct Project) from [BG_ProjectDashboardSummaryScheduled_CG] where ProjectStatus<>'C'-- group by ProjectManager, ProjectStatus



CREATE view [dbo].[BG_ProjectDashboardSummaryScheduled_CG] as 
select
	e.Name as Engagement,
	bt.Description as BillingType,
	p.Name as Project,
	pm.ProjectManager,
	e.ContractAmount as POContractAmount,
	p.LabourBudget as ServicesAmount,
	pm.EmailAddress,
	p.ProjectStatus,
	i.BilledAmount,
	i.UnBilledAmount,
	i.ScheduledInvoicedAmount as TotalInvoiceAmount,
	coalesce(pd.WriteUpWriteOffwithForecast,0) as WriteUpWriteOff,
	--coalesce(pd.WUWO,0) as WriteUpWriteOff,
	pd.PlannedMarginPercent,
	pd.[ActualBillingMargin%],
	pd.[ActualBillingMargin%Check],
	p.ProjectId,
	e.EngagementId,
	'tshepherd@burwood.com' as TestBurst,
	pm.EmailAddress+', tshepherd@burwood.com' as EmailBurst,
	--'mlow@burwood.com' as EmailBurstTest,
	'mwalder@burwood.com, tshepherd@burwood.com, epoczatek@burwood.com, mlow@burwood.com' as EmailBurstTest,
	'jcourtney@burwood.com, rgibson@burwood.com, tshepherd@burwood.com' as VPEmailBurst,
	u.OverallProjectRisk

from
	Engagement e with (nolock)
		join
	Project p with (nolock) on e.EngagementId=p.EngagementId
		join
	BillingType bt with (nolock) on e.BillingType=bt.Code
		join
	BG_ProjectManager_CG pm with (nolock) on p.ProjectId=pm.ProjectId
		left outer join
	[BG_ProjectDashboardSummary_Invoice_BilledvsUnbilled_CG] i with (nolock) on i.ProjectId=p.ProjectId
		left outer join
	--BG_ProjectDashboard_Engagement_2018_CG pd with (nolock) on p.EngagementId=pd.EngagementId and p.ProjectId=pd.ProjectId
	BG_ProjectDashboard_Engagement_Table_CG pd with (nolock) on p.EngagementId=pd.EngagementId and p.ProjectId=pd.ProjectId
		left outer join
	(select c.EntityId, d.Description as OverallProjectRisk from UDFCode c with (nolock) left outer join CodeDetail d with (nolock) on c.ItemName=d.CodeType and c.UDFCode=d.CodeDetail where c.Entity='PRJ' and c.ItemName='ProjectCode2' and d.CodeTypeSummary='E73F3CB9-CC0C-4E4C-A690-83EE92C09735')
	 u on p.ProjectId=u.EntityId
where
	e.CustomerId<>'921E8672-8A4B-482E-85D3-8D545E5D1C2A' --Burwood Group Inc.
	and e.CustomerId<>'D6FCCBED-6B49-4914-BA89-9CB554DB1165'
	and e.Deleted=0

	--and p.ProjectStatus<>'C'
GO
