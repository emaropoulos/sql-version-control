USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_EAC_ProjectMaxPlannedFinish_CG]    Script Date: 10/18/2019 4:57:42 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[BG_EAC_ProjectMaxPlannedFinish_CG] as 
with a as (
select
	p.Name as Project,
	p.ProjectStatus,
	p.ProjectId,
	max(convert(date, p.PlannedFinish)) as ProjectPlannedFinish,

	case when max(convert(date, ta.ActualFinish))>max(convert(date, p.PlannedFinish))
		 then max(convert(date, ta.ActualFinish))
		 when max(convert(date, ta.BaselineFinish))>max(convert(date, p.PlannedFinish))
		 then max(convert(date, ta.BaselineFinish))
		 when max(convert(date, ta.ForecastFinish))>max(convert(date, p.PlannedFinish))
		 then max(convert(date, ta.ForecastFinish))
		 when max(convert(date, ta.PlannedFinish))>max(convert(date, p.PlannedFinish))
		 then max(convert(date, ta.PlannedFinish))
		 when max(convert(date, t.BaselineFinish))>max(convert(date, p.PlannedFinish))
		 then max(convert(date, t.BaselineFinish))
		 when max(convert(date, t.PlannedFinish))>max(convert(date, p.PlannedFinish))
		 then max(convert(date, t.PlannedFinish))
		 when max(convert(date, t.RollupActualFinish))>max(convert(date, p.PlannedFinish))
		 then max(convert(date, t.RollupActualFinish))
		 when max(convert(date, t.RollupFinishDate))>max(convert(date, p.PlannedFinish))
		 then max(convert(date, t.RollupFinishDate))
		 when max(convert(date, t.RollupForecastFinish))>max(convert(date, p.PlannedFinish))
		 then max(convert(date, t.RollupForecastFinish))
		 else max(convert(date, p.PlannedFinish))
	end as MaxPlannedFinish,




	max(convert(date, t.BaselineFinish)) as TaskBaselineFinish,
	max(convert(date, t.PlannedFinish)) as TaskPlannedFinish,
	max(convert(date, t.RollupActualFinish)) as TaskRollupActualFinish,
	max(convert(date, t.RollupFinishDate)) as TaskRollupFinishDate,
	max(convert(date, t.RollupForecastFinish)) as TaskRollupForecastFinish,

	max(convert(date, ta.ActualFinish)) as TaskAssignmentActualFinish,
	max(convert(date, ta.BaselineFinish)) as TaskAssignmentBaselineFinish,
	max(convert(date, ta.ForecastFinish)) as TaskAssignmentForecastFinish,
	max(convert(date, ta.PlannedFinish)) as TaskAssignmentPlannedFinish
	
	
from
	Project p with (nolock)
		join
	Tasks t with (nolock) on p.ProjectId=t.ProjectId
		left outer join
	TaskAssignment ta with (nolock) on p.ProjectId=ta.ProjectId
where
	p.ProjectStatus<>'C'
	--and month(p.PlannedFinish)=10
group by
	p.Name,
	p.ProjectStatus,
	p.ProjectId
--having
--	max(convert(date, ta.ActualFinish))>max(convert(date, p.PlannedFinish))
--	or max(convert(date, ta.BaselineFinish))>max(convert(date, p.PlannedFinish))
--	or max(convert(date, ta.ForecastFinish))>max(convert(date, p.PlannedFinish))
--	or max(convert(date, ta.PlannedFinish))>max(convert(date, p.PlannedFinish))
--	or max(convert(date, t.BaselineFinish))>max(convert(date, p.PlannedFinish))
--	or max(convert(date, t.PlannedFinish))>max(convert(date, p.PlannedFinish))
--	or max(convert(date, t.RollupActualFinish))>max(convert(date, p.PlannedFinish))
--	or max(convert(date, t.RollupFinishDate))>max(convert(date, p.PlannedFinish))
--	or max(convert(date, t.RollupForecastFinish))>max(convert(date, p.PlannedFinish))
)
select
	*,
	case when ProjectPlannedFinish<>MaxPlannedFinish
		 then 'Yes'
		 else 'No'
	end as MaxGreaterThanProjectFinish
from
	a
--where
--	ProjectPlannedFinish<>MaxPlannedFinish


GO
