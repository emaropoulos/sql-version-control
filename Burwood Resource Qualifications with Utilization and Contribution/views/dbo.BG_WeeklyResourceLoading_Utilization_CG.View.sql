USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_WeeklyResourceLoading_Utilization_CG]    Script Date: 10/17/2019 3:05:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO










CREATE VIEW [dbo].[BG_WeeklyResourceLoading_Utilization_CG] AS
select 
	c.Description as Region,
	w.Name as Workgroup,
	cc.Name as Practice,
	r.Name as Resource,
	r.ResourceId,
	fy.Name as FYear,
	fy.Name+' ['+LEFT(CONVERT(VARCHAR, fy.StartDate, 120), 10)+' - '+LEFT(CONVERT(VARCHAR, fy.EndDate, 120), 10)+']' as FiscalYear,
	fp.Period+' ['+LEFT(CONVERT(VARCHAR, fp.StartDate, 120), 10)+' - '+LEFT(CONVERT(VARCHAR, fp.EndDate, 120), 10)+']' as FiscalPeriod,
	cast(fp.StartDate as date) as PeriodStartDate,
	cast(fp.EndDate as date) as PeriodEndDate,
	sum(t.RegularHours) as RegularHours,
	sum(t.RegularHours*t.AffectUtilization) as UtilizationHours,
	max(case when rp.AnnualTargetHours=0 or rp.AnnualTargetHours is NULL then 1912 else rp.AnnualTargetHours end /52) as WeekHours
from
	BG_TimeReport_VIEW t
		join
	FiscalYear fy with (nolock) on fy.BillingOfficeId = '{A688AC3B-03DA-44C3-8A05-CBE069E1A6F2}' AND t.TimeDate>=fy.StartDate and t.TimeDate<fy.EndDate + 1 AND fy.Deleted = CAST(0 AS BIT)
		join
	FiscalPeriod fp with (nolock) on fp.FiscalYearId = fy.FiscalYearId AND t.TimeDate >= fp.StartDate AND t.TimeDate < fp.EndDate + 1  AND fp.Deleted = CAST(0 AS BIT) 
		join
	Resources r with (nolock) on t.ResourceId=r.ResourceId
		left outer join
	ResourcePayroll rp with (nolock) on r.ResourceId=rp.ResourceId
		left outer join
	WorkgroupMember wm with (nolock) on r.ResourceId=wm.ResourceId and Historical=0	
		left outer join
	Workgroup w with (nolock) on wm.WorkgroupId=w.WorkgroupId
		left outer join
	CostCenters cc with (nolock) on r.CostCenterId=cc.CostCenter
		left outer join 
	UDFCode u with (nolock) on r.ResourceId=u.EntityId and u.ItemName='ResourceCode1'
		left outer join  
	CodeDetail c with (nolock) on u.UDFCode=c.CodeDetail
where
	datepart(year, fy.EndDate) >= 2015
	and r.Deleted=0
	and r.TerminationDate is NULL
group by
	c.Description,
	w.Name,
	cc.Name,
	r.Name,
	r.ResourceId,
	fy.Name,
	fy.Name+' ['+LEFT(CONVERT(VARCHAR, fy.StartDate, 120), 10)+' - '+LEFT(CONVERT(VARCHAR, fy.EndDate, 120), 10)+']',
	fp.Period+' ['+LEFT(CONVERT(VARCHAR, fp.StartDate, 120), 10)+' - '+LEFT(CONVERT(VARCHAR, fp.EndDate, 120), 10)+']',
	cast(fp.StartDate as date),
	cast(fp.EndDate as date)







GO
