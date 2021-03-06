USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_WeeklyLoading_YTD_ContributionPercent_CG]    Script Date: 10/17/2019 3:05:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO












CREATE VIEW [dbo].[BG_WeeklyLoading_YTD_ContributionPercent_CG] AS
select
	Resource,
	ResourceId,
	ResourceMarginWithoutSales as Margin,
	ContributionPercent as 'Contribution%'
from
	BG_ResourceDashboardResourceSummary_CG(case when month(getdate())=1 then convert(date, DATEADD(yy,-1,DATEADD(yy,DATEDIFF(yy,0,GETDATE()),0))) else convert(date, DATEADD(yy, DATEDIFF(yy,0,getdate()), 0))end, case when month(getdate())=1 then Convert(date, dateadd(DD, -1, dateadd(YY,datediff(yy,0,getdate()),0))) else convert(date, getdate()) end)






GO
