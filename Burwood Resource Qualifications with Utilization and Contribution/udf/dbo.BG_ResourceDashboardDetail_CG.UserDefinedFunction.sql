USE [Changepoint]
GO
/****** Object:  UserDefinedFunction [dbo].[BG_ResourceDashboardDetail_CG]    Script Date: 10/17/2019 3:12:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--select * from [BG_ResourceDashboardDetail_with_DatesAndMonthlyCostAndDaysBetween_CG]('20170101', '20170131')
--SE_Sales_Profit SE_SalesProfit_Share

CREATE FUNCTION [dbo].[BG_ResourceDashboardDetail_CG] 
(@StartDate date, @EndDate date)
RETURNS TABLE 
AS
RETURN 

SELECT 
	rr.Region,
	--Workgroup,
	rd.Resource,
	rd.ResourceId,
	m.Name as Manager,
	m.ResourceId as Manager_ResourceId,
	Terminated,
	sum(Resource_Hours) as BillableHours,
	sum(Resource_RevRec) as RevenueRecognized,
	sum(WO_Resource_WriteOff_WriteUp) as WriteUpWriteOff,
	sum(SE_SalesProfit_Share) as SE,
	sum(Sales_Profit_Share) as Sales,
	sum(PS_Actual1) as PS_Actual,
	sum(PS_Budget1) as PS_Budget,
	sum(HC_Margin) as HC_Margin,
	sum(HC_Budget) as HC_Budget,
	sum(MSMargin) as MSMargin,
	sum(IT_Revenue) as ManagedServicesRevenue,
	sum(IT_COGS) as ManagedServicesCOGS,
	sum(ContractorMargin) as ContractorMargin,
	sum(PracticeCost) as WorkgroupBudget,
	case when Month_Close=datepart(month, Month1Start) then max(Month1Cost)*(Month1DaysBetween) else 0 end as Month1Cost,
	case when Month_Close=datepart(month, Month2Start) then max(Month2Cost)*(Month2DaysBetween) else 0 end  as Month2Cost,
	case when Month_Close=datepart(month, Month3Start) then max(Month3Cost)*(Month3DaysBetween) else 0 end  as Month3Cost,
	case when Month_Close=datepart(month, Month4Start) then max(Month4Cost)*(Month4DaysBetween) else 0 end  as Month4Cost,
	case when Month_Close=datepart(month, Month5Start) then max(Month5Cost)*(Month5DaysBetween) else 0 end  as Month5Cost,
	case when Month_Close=datepart(month, Month6Start) then max(Month6Cost)*(Month6DaysBetween) else 0 end  as Month6Cost,
	case when Month_Close=datepart(month, Month7Start) then max(Month7Cost)*(Month7DaysBetween) else 0 end  as Month7Cost,
	case when Month_Close=datepart(month, Month8Start) then max(Month8Cost)*(Month8DaysBetween) else 0 end  as Month8Cost,
	case when Month_Close=datepart(month, Month9Start) then max(Month9Cost)*(Month9DaysBetween) else 0 end  as Month9Cost,
	case when Month_Close=datepart(month, Month10Start) then max(Month10Cost)*(Month10DaysBetween) else 0 end  as Month10Cost,
	case when Month_Close=datepart(month, Month11Start) then max(Month11Cost)*(Month11DaysBetween) else 0 end  as Month11Cost,
	case when Month_Close=datepart(month, Month12Start) then max(Month12Cost)*(Month12DaysBetween) else 0 end  as Month12Cost,
	--
	case when Month_Close=datepart(month, Month1Start) then max(NewMonth1Cost)*(Month1DaysBetween) else 0 end as NewMonth1Cost,
	case when Month_Close=datepart(month, Month2Start) then max(NewMonth2Cost)*(Month2DaysBetween) else 0 end  as NewMonth2Cost,
	case when Month_Close=datepart(month, Month3Start) then max(NewMonth3Cost)*(Month3DaysBetween) else 0 end  as NewMonth3Cost,
	case when Month_Close=datepart(month, Month4Start) then max(NewMonth4Cost)*(Month4DaysBetween) else 0 end  as NewMonth4Cost,
	case when Month_Close=datepart(month, Month5Start) then max(NewMonth5Cost)*(Month5DaysBetween) else 0 end  as NewMonth5Cost,
	case when Month_Close=datepart(month, Month6Start) then max(NewMonth6Cost)*(Month6DaysBetween) else 0 end  as NewMonth6Cost,
	case when Month_Close=datepart(month, Month7Start) then max(NewMonth7Cost)*(Month7DaysBetween) else 0 end  as NewMonth7Cost,
	case when Month_Close=datepart(month, Month8Start) then max(NewMonth8Cost)*(Month8DaysBetween) else 0 end  as NewMonth8Cost,
	case when Month_Close=datepart(month, Month9Start) then max(NewMonth9Cost)*(Month9DaysBetween) else 0 end  as NewMonth9Cost,
	case when Month_Close=datepart(month, Month10Start) then max(NewMonth10Cost)*(Month10DaysBetween) else 0 end  as NewMonth10Cost,
	case when Month_Close=datepart(month, Month11Start) then max(NewMonth11Cost)*(Month11DaysBetween) else 0 end  as NewMonth11Cost,
	case when Month_Close=datepart(month, Month12Start) then max(NewMonth12Cost)*(Month12DaysBetween) else 0 end  as NewMonth12Cost
FROM 
	[BG_ResourceDashboardDetail_with_DatesAndMonthlyCostAndDaysBetween_CG] (@StartDate, @EndDate) rd
		join
	Resources r with (nolock) on rd.ResourceId=r.ResourceId
		join
	BG_ResourceRegion_CG rr with (nolock) on rd.ResourceId=rr.ResourceId
		left outer join
	Resources m with (nolock) on r.ReportsTo=m.ResourceId
where
	r.EmployeeType<>'CO'
group by
	rr.Region,
	--Workgroup,
	rd.Resource,
	rd.ResourceId,
	m.Name,
	m.ResourceId,
	Terminated,
	Month_Close,
	Month1Start,
	Month2Start,
	Month3Start,
	Month4Start,
	Month5Start,
	Month6Start,
	Month7Start,
	Month8Start,
	Month9Start,
	Month10Start,
	Month11Start,
	Month12Start,
	Month1DaysBetween,
	Month2DaysBetween,
	Month3DaysBetween,
	Month4DaysBetween,
	Month5DaysBetween,
	Month6DaysBetween,
	Month7DaysBetween,
	Month8DaysBetween,
	Month9DaysBetween,
	Month10DaysBetween,
	Month11DaysBetween,
	Month12DaysBetween
GO
