USE [Changepoint2018]
GO
/****** Object:  View [dbo].[BG_ResourceWeeklySchedule_CG]    Script Date: 10/11/2019 1:49:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








--resourceinfo 'poc'--'Shear, Erik'


--select * from [BG_ResourceWeeklySchedule_CG] where resource like '%poc%'--where Resource='McKay, Scott'--group by Resource order by count(Task) desc --where Resource in (select Resource from BG_WorkgroupManagers_CG)



CREATE VIEW [dbo].[BG_ResourceWeeklySchedule_CG] AS
SELECT 
	c.Description as Region,
	wg.Name as Workgroup,
	r.ResourceId, 
	--r.TerminationDate,
	r.Name as Resource, 
	r.FirstName+' '+r.LastName as ResourceName,
	ra.EmailAddress as ResourceEmailAddress,
	m.Name as Manager,
	ma.EmailAddress as ManagerEmailAddress,
	ra.EmailAddress+', '+ma.EmailAddress as ResourceManagerEmailBurst,
	case when coalesce(ra.EmailAddress,'')='' then 'tshepherd@burwood.com' else ra.EmailAddress+', tshepherd@burwood.com' end as EmailBurst,
	'tshepherd@burwood.com' as TestBurst,
	w.Type, 
	w.PeriodStartDate,
	w.PeriodEndDate,
	cast(w.ProjectName as varchar(200)) as Project,
	t.Name as Task,
	cast(t.BaselineFinish as date) as BaselineFinish,
	cast(t.PlannedFinish as date) as PlannedFinish,
	w.PlannedHours as PlannedHours
FROM 
	BG_WeeklySchedule_VIEW w with (nolock)
		INNER JOIN 
	Resources r with (nolock) on r.ResourceId=w.ResourceId
		left outer join
	BG_ProjectManager_CG pm with (Nolock) on r.Name=pm.ProjectManager
		join
	ResourcePayroll rp with (nolock) on r.ResourceId=rp.ResourceId --and rp.CertificationHours>0
		inner join 
	UDFCode u1 with (nolock) on r.ResourceId=u1.EntityId and u1.ItemName='ResourceCode1'
		left outer join  
	CodeDetail c with (nolock) on u1.UDFCode=c.CodeDetail
		left outer join
	WorkgroupMember wm with (nolock) on wm.ResourceId=r.ResourceId and wm.Historical=0
		left outer join
	Workgroup wg with (nolock) on wg.WorkgroupId=wm.WorkgroupId
		left outer join
	ResourceAddress ra with (nolock) on ra.ResourceId=r.ResourceId
		left outer join
	Resources m with (nolock) on m.ResourceId=r.ReportsTo
		left outer join
	ResourceAddress ma with (nolock) on ma.ResourceId=m.ResourceId
		LEFT OUTER JOIN 
	TaskAssignment ta with (nolock) on ta.TaskAssignmentId=w.TaskAssignmentId
		LEFT OUTER JOIN 
	Tasks t with (nolock) on t.TaskId=w.TaskId
		LEFT OUTER JOIN 
	UDFText u  WITH (NOLOCK) ON u.ItemName='TaskText4' AND u.EntityId=ta.TaskAssignmentId 
		INNER JOIN 
	FiscalYear fy WITH (NOLOCK) on fy.BillingOfficeId = '{A688AC3B-03DA-44C3-8A05-CBE069E1A6F2}' 
				AND w.PeriodStartDate >= fy.StartDate 
				AND w.PeriodStartDate < fy.EndDate + 1  
				AND fy.Deleted = CAST(0 AS BIT)  
		INNER JOIN 
	FiscalPeriod fp WITH (NOLOCK) on fp.FiscalYearId = fy.FiscalYearId 
					AND w.PeriodStartDate >= fp.StartDate 
					AND w.PeriodStartDate < fp.EndDate + 1  
					AND fp.Deleted = CAST(0 AS BIT)  
WHERE 
	r.Name IS NOT NULL 
	and r.TerminationDate is null
	AND w.Type IS NOT NULL 
	AND w.ProjectName IS NOT NULL 
	--and w.ProjectName<>'Burwood Holiday'
	AND w.TaskName IS NOT NULL  
	AND w.PeriodStartDate IS NOT NULL  
	AND (( w.PeriodStartDate >= DATEADD(DAY, -2, DATEADD(WEEK, DATEDIFF(WEEK, 0, CURRENT_TIMESTAMP), 0)) --DATEADD(DD,-(DATEPART(DW,GETDATE())-7),GETDATE())
		AND w.PeriodStartDate <= DATEADD(DAY, 26, DATEADD(WEEK, DATEDIFF(WEEK, 0, CURRENT_TIMESTAMP), 0)) ))--DATEADD(DAY, 19, DATEADD(WEEK, DATEDIFF(WEEK, 0, CURRENT_TIMESTAMP), 0))  )) 
	--AND (   ( r.ResourceId = '{19902BB3-FBAD-4C79-9655-58C3CDAC5397}'  )   ) 
	AND w.PeriodStartDate IS NOT NULL  
	and r.EmployeeType<>'CO'
	and (rp.CertificationHours>0 or r.Name in ('Walder, Maggie', 'Kerstetter, Edward', 'Poczatek, Ellie'))
	--and pm.ProjectManager is null
	--and wg.Name not in ('Business Development-EA', 'Business Development-WE', 'Leave of Absence',	'Managed Services', 
	--					'Owners', 'Product Sales Operations', 'Product Sales Operations-EA', 'Burwood Corporate', 'Business Development-HL', 'Heartland Region',
	--					'Business Operations & Finance', 'Eastern Region', 'Marketing', 'Sales Engineers', 'Western Region')
	--and w.Type='Opportunity'
--GROUP BY 
--	r.ResourceId, 
--	r.Name, 
--	fp.FiscalPeriodId, 
--	CHECKSUM(r.ResourceId) 
--ORDER BY 
--	r.Name,
--	w.PeriodStartDate

union all

SELECT 
	'EA-Eastern Region' as Region,
	'Burwood Corporate' as Workgroup,
	'758C9CEA-15E2-445D-B80C-E7579ECC65F2' as ResourceId, 
	--NULL,
	'Shepherd, Teri' as Resource, 
	'Teri Shepherd' as ResourceName,
	'tshepherd@burwood.com' as ResourceEmailAddress,
	'Shepherd, Teri' as Manager,
	'tshepherd@burwood.com' as ManagerEmailAddress,
	'tshepherd@burwood.com' as EmailBurst,
	'tshepherd@burwood.com' as PilotBurst,
	'tshepherd@burwood.com' as TestBurst,
	w.Type, 
	w.PeriodStartDate,
	w.PeriodEndDate,
	cast(w.ProjectName as varchar(200)) as Project,
	t.Name as Task,
	cast(t.BaselineFinish as date) as BaselineFinish,
	cast(t.PlannedFinish as date) as PlannedFinish,
	w.PlannedHours as PlannedHours
FROM 
	BG_WeeklySchedule_VIEW w with (nolock)
		INNER JOIN 
	Resources r with (nolock) on r.ResourceId=w.ResourceId
		join
	ResourcePayroll rp with (nolock) on r.ResourceId=rp.ResourceId and rp.CertificationHours>0
		inner join 
	UDFCode u1 with (nolock) on r.ResourceId=u1.EntityId and u1.ItemName='ResourceCode1'
		left outer join  
	CodeDetail c with (nolock) on u1.UDFCode=c.CodeDetail
		left outer join
	WorkgroupMember wm with (nolock) on wm.ResourceId=r.ResourceId and wm.Historical=0
		left outer join
	Workgroup wg with (nolock) on wg.WorkgroupId=wm.WorkgroupId
		left outer join
	ResourceAddress ra with (nolock) on ra.ResourceId=r.ResourceId
		left outer join
	Resources m with (nolock) on m.ResourceId=r.ReportsTo
		left outer join
	ResourceAddress ma with (nolock) on ma.ResourceId=m.ResourceId
		LEFT OUTER JOIN 
	TaskAssignment ta with (nolock) on ta.TaskAssignmentId=w.TaskAssignmentId
		LEFT OUTER JOIN 
	Tasks t with (nolock) on t.TaskId=w.TaskId
		LEFT OUTER JOIN 
	UDFText u  WITH (NOLOCK) ON u.ItemName='TaskText4' AND u.EntityId=ta.TaskAssignmentId 
		INNER JOIN 
	FiscalYear fy WITH (NOLOCK) on fy.BillingOfficeId = '{A688AC3B-03DA-44C3-8A05-CBE069E1A6F2}' 
				AND w.PeriodStartDate >= fy.StartDate 
				AND w.PeriodStartDate < fy.EndDate + 1  
				AND fy.Deleted = CAST(0 AS BIT)  
		INNER JOIN 
	FiscalPeriod fp WITH (NOLOCK) on fp.FiscalYearId = fy.FiscalYearId 
					AND w.PeriodStartDate >= fp.StartDate 
					AND w.PeriodStartDate < fp.EndDate + 1  
					AND fp.Deleted = CAST(0 AS BIT)  
WHERE 
	r.Name='Rohrer, Scott'
	and r.TerminationDate is null
	AND w.Type IS NOT NULL 
	AND w.ProjectName IS NOT NULL 
	AND w.TaskName IS NOT NULL  
	AND w.PeriodStartDate IS NOT NULL  
	AND (( w.PeriodStartDate >= DATEADD(DAY, -2, DATEADD(WEEK, DATEDIFF(WEEK, 0, CURRENT_TIMESTAMP), 0)) --DATEADD(DD,-(DATEPART(DW,GETDATE())-7),GETDATE())
		AND w.PeriodStartDate <= DATEADD(DAY, 26, DATEADD(WEEK, DATEDIFF(WEEK, 0, CURRENT_TIMESTAMP), 0)) ))--DATEADD(DAY, 19, DATEADD(WEEK, DATEDIFF(WEEK, 0, CURRENT_TIMESTAMP), 0))  )) 
	--AND (   ( r.ResourceId = '{19902BB3-FBAD-4C79-9655-58C3CDAC5397}'  )   ) 
	AND w.PeriodStartDate IS NOT NULL  
	






GO
