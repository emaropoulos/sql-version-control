USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_EAC_CG]    Script Date: 10/10/2019 1:56:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









CREATE View [dbo].[BG_EAC_CG] as
select 
	w.Name as WorkGroup,
	r.Name as 'Resource',
	datepart(year, getdate()) as Current_Year,
	datepart(month, getdate())-1 as Last_Month,
	t.CostCenter,
	t.Customer,
	t.Engagement,
	t.Practice,
	t.EngagementManager,
	t.Engagement_Status,
	t.ExpenseBudget,
	t.OtherExpenseBudget,
	t.ContractAmount,
	t.Region,
	t.Sales_Contact,
--Project------------------------------------------------------------------
	t.Project,
	t.ProjectDescription,
	t.ProjectManager,
	t.Project_Status,
	t.Project_Baseline_Start,
	t.Project_Baseline_Finish,  
	t.Project_Baseline_Hours, 
	t.Project_Planned_Start,
	t.Project_Planned_Finish,
	t.Project_Planned_Hours,
	t.Project_Planned_Remaining_Hours,
	t.Project_Actual_Start,
	t.Project_Actual_Finish,
	t.Project_Actual_Hours,   
	t.Project_Labor_Budget,  
	o.name,
	o.New_cpEstimatedServiceMargin,
	o.New_EstimatedProfitability,
	t.Project_Rollup_Forecast_Start,
	t.Project_Rollup_Forecast_Finish,
	t.Project_Rollup_Remaining_Hours,
--Rates-----------------------------------------------
	t.BillingType,
	case when ebr.NegotiatedRate is null
		 then 0
		 else ebr.NegotiatedRate
	end as Negotiated_Rate,
	rr.HourlyBillRate,  
	rr.HourlyCostRate,  
	rr.DailyBillRate,  
	rr.DailyCostRate,  
	rr.OvertimeCostRate,  
	rr.OvertimeBillRate,  
	rr.Rate1,  
	rr.Rate2,  
	rr.Rate3,  
	rr.Description,  
	rr.Currency,  
--Tasks 1st Level---------------------------------
	t.Task,
	t.Task0_WBS,
	t.Task0_BaselineFinish,
	t.Task0_ForecastFinish,
	t.Task0_BaselineHours,
	t.Task0_ActualHours,
	t.Task0_PlannedHours,
	t.Task0_PlannedRemainingHours,
	t.Task0_RemainingHours,
--Tasks 2nd Level
	t2.Name as Task1,
	t2.WBS Task1_WBS,
	case when (substring((convert(varchar(10), t2.WBS)),0,charindex('.',(convert(varchar(10), t2.WBS)))))=' '
		 then t2.WBS
		 else substring((convert(varchar(10), t2.WBS)),0,charindex('.',(convert(varchar(10), t2.WBS)))) 
	end as WBS_Floor,
	t2.BaselineFinish Task1_BaselineFinish,
	t2.RollupForecastFinish Task1_ForecastFinish,
	case when t2.BaselineHours is null
		 then 0
		 else t2.BaselineHours
	end as Task1_BaselineHours,
	case when t2.RollupActualHours is null
		 then 0
		 else t2.RollupActualHours
	end as Task1_ActualHours,
	case when t2.PlannedHours is null
		 then 0
		 else t2.PlannedHours
	end as Task1_PlannedHours,
	case when t2.PlannedRemainingHours is null
		 then 0
		 else t2.PlannedRemainingHours
	end as Task1_PlannedRemainingHours,
	case when t2.RollupRemainingHours is null
		 then 0
		 else t2.RollupRemainingHours
	end as Task1_RemainingHours,
--TaskAssignment
	ta.ActualStart Task_Actual_Start,
	ta.ActualFinish Task_Actual_Finish,
	case when ta.ActualHours is null
		 then 0
		 else ta.ActualHours
	end as Task_Actual_Hours,
	ta.ForecastStart Task_Forecast_Start,
	ta.ForecastFinish Task_Forecast_Finish,
	ta.PlannedStart Task_Planned_Start,
	ta.PlannedFinish Task_Planned_Finish,
	ta.PlannedHours Task_Planned_Hours,
	ta.BaselineStart Task_Baseline_Start,
	ta.BaselineFinish Task_Baseline_Finish,
	case when ta.BaselineHours is null
		 then 0
		 else ta.BaselineHours
	end as Task_Baseline_Hours,
	case when ta.RemainingHours is null 
		 then 0
		 else ta.RemainingHours
	end as Task_Remaining_Hours,
	case when ta.PlannedRemainingHours is null 
		 then 0
		 else ta.PlannedRemainingHours
	end as Task_Planned_Remaining_Hours,
	ta.Statused Task_Statused,
	ta.StatusDate Task_Last_Status_Date,
	ta.TaskStatus Task_Status,
	ta.PercentComplete Task_Percent_Complete,
	ta.TaskId as Task_Id,
-----------------------------------------------
	r.TerminationDate Res_Term_Date,
	t.Project_ProjectId,
	t.EngagementId,
	r.ResourceId,
	t.CostCenterId,
	t.CustomerId,
	t.OpportunityId

from 
	dbo.BG_EAC_Tasks_CG t (nolock)
		left outer join
	[chil-crm-04].[BurwoodGroupInc_MSCRM].[dbo].[OpportunityBase] o with (nolock) on t.OpportunityId=o.OpportunityId
		left outer join 
	Tasks t2 (nolock) on t.Project_ProjectId=t2.ProjectId 
					 and t.Task0_WBS=(case when (substring((convert(varchar(10), t2.WBS)),0,charindex('.',(convert(varchar(10), t2.WBS)))))=' '
										   then t2.WBS
										   else substring((convert(varchar(10), t2.WBS)),0,charindex('.',(convert(varchar(10), t2.WBS)))) end)
		left outer join 
	dbo.TaskAssignment ta (nolock) on t.Project_ProjectId=ta.ProjectId and t2.TaskId=ta.TaskId
		left outer join 
	dbo.Resources r (nolock) on ta.ResourceId=r.ResourceId
		left outer join 
	dbo.EngagementBillingRates ebr WITH (NOLOCK) on ta.EngagementId=ebr.EngagementId AND ta.BillingRole=ebr.BillingRoleId
		left outer join 
	dbo.WorkgroupMember wgm WITH (NOLOCK) on r.resourceId=wgm.resourceId AND wgm.Historical = 0 
		left outer join 
	dbo.Workgroup w WITH (NOLOCK) on wgm.WorkgroupId=w.WorkgroupId
		left outer join 
	dbo.DS_AllResourceRate rr WITH (NOLOCK) on ta.ResourceId=rr.ResourceId 
										 and rr.EffectiveDate=(select EffectiveDate 
																					from dbo.DS_CurrentEffectiveDate 
																					where rr.ResourceId=dbo.DS_CurrentEffectiveDate.ResourceId)

where 
	(t2.deleted=0 or t2.deleted is NULL)
	--and ta.TaskStatus is not null
	and (ta.deleted = 0 or ta.deleted is NULL)
	--and t.Engagement='Reyes Holdings - Disaster Recovery Technical PM'



















GO
