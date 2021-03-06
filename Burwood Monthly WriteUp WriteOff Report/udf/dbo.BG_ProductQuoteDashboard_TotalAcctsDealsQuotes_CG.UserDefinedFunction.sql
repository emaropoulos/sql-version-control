USE [BurwoodGroupInc_MSCRM]
GO
/****** Object:  UserDefinedFunction [dbo].[BG_ProductQuoteDashboard_TotalAcctsDealsQuotes_CG]    Script Date: 10/11/2019 3:03:31 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[BG_ProductQuoteDashboard_TotalAcctsDealsQuotes_CG] (@StartDate date, @EndDate date)
returns table
as
return
with d (AccountExecutive, NumberDeals) as
(
select
	ae.BDM as AccountExecutive,
	cast(count(distinct o.OpportunityId) as decimal(10,2)) as NumberDeals
from 
	dbo.BG_Opportunity_Resources_CG o with (nolock)
		join
	[chil-sql-01].[Changepoint].dbo.BG_AccountExecutives_CG ae with (nolock) on o.Owner collate database_default=ae.BDM
		join
	OpportunityBase ob with (nolock) on o.OpportunityId=ob.OpportunityId
where
	convert(date, o.wondate)>=@StartDate
	and convert(date, o.wondate)<=@EndDate
	and ob.new_Products=1
group by
	ae.BDM
	),
a (AccountExecutive, NumberAccounts) as
(
select
	ae.BDM as AccountExecutive,
	cast(count(distinct o.[Account Name]) as decimal(10,2)) as NumberAccounts
from 
	dbo.BG_Opportunity_Resources_CG o with (nolock)
		join
	[chil-sql-01].[Changepoint].dbo.BG_AccountExecutives_CG ae with (nolock) on o.Owner collate database_default=ae.BDM
			join
	OpportunityBase ob with (nolock) on o.OpportunityId=ob.OpportunityId
where
	convert(date, o.wondate)>=@StartDate
	and convert(date, o.wondate)<=@EndDate
	and ob.new_Products=1
group by
	ae.BDM
),
q(AccountExecutive, NumberQuotes) as
(
select
	ae.BDM as AccountExecutive,
	cast(count(distinct qt.DocNo) as decimal(10,2)) as NumberQuotes
from
	[fpdc-sql-01].[QuoteWerks].[dbo].[BG_QuoteSummary_CG] qt with (nolock)
		join
	[chil-sql-01].[Changepoint].dbo.BG_AccountExecutives_CG ae with (nolock) on qt.AccountExecutive collate database_default=ae.BDM
where
	qt.CreatedOn>=@StartDate
	and qt.CreatedOn<=@EndDate
group by
	ae.BDM

)

select
	ae.BDM as AccountExecutive,
	ae.Region,
	a.NumberAccounts,
	d.NumberDeals,
	q.NumberQuotes,
	d.NumberDeals/q.NumberQuotes as WinRate
from
	[chil-sql-01].[Changepoint].dbo.BG_AccountExecutives_CG ae with (nolock)
		join
	a on ae.BDM collate database_default=a.AccountExecutive
		join
	d on ae.BDM collate database_default=d.AccountExecutive
		join
	q on ae.BDM collate database_default=q.AccountExecutive
		

GO
