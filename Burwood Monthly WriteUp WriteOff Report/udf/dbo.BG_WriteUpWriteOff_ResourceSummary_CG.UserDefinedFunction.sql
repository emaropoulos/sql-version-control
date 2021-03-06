USE [Changepoint2018]
GO
/****** Object:  UserDefinedFunction [dbo].[BG_WriteUpWriteOff_ResourceSummary_CG]    Script Date: 10/11/2019 2:18:05 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--select * from [BG_WriteUpWriteOff_Summary_CG]('20180901', '20180930') order by Engagement


CREATE function [dbo].[BG_WriteUpWriteOff_ResourceSummary_CG](@StartDate date, @EndDate date)
returns table
as
return

select
	BillingOffice as Region,
	(select top 1 pm.ProjectManager from BG_ProjectManager_CG pm where tw.EngagementId=pm.EngagementId) as ProjectManager,
	o.Owner as AccountExecutive,
	Engagement,
	EngagementStatus,
	BillingType,
	Resource,
	Engagement+'-'+Resource as EngagementResource,
	sum(RateTimesHours) as RateTimesHours,
	--sum(PotentialFeesNew) as PotentialFeesNew,
	sum(PotentialFees) as PotentialFees,
	--sum(PotentialFees1) as PotentialFees1,
	sum(RevenueRecognized) as RevenueRecognized,
	sum(AmountWrittenOff) as AmountWrittenOff,
	sum(FixedFeeOverage) as FixedFeeOverage,
	sum(OldFixedFeeOverage) as OldFixedFeeOverage,
	sum(Contractor) as ContractorAdjustments,
	sum(Expenses) as ExpenseAdjustments,
	sum(Other) as OtherAdjustments,
	sum(TotalWriteUpWriteOff) as TotalWriteUpWriteOff,
	sum(OldTotalWriteUpWriteOff) as OldTotalWriteUpWriteOff,
	sum(OldTotalWriteUpWriteOff)+sum(Contractor)+sum(Expenses)+sum(Other) as OldWriteUpWriteOff,
	sum(TotalWriteUpWriteOff)+sum(Contractor)+sum(Expenses)+sum(Other) as WriteUpWriteOff,
	sum(PotentialFees)-sum(RevenueRecognized) as FixedFeeOverageCalculatedwithPotentialFees,
	sum(RateTimesHours)-sum(RevenueRecognized) as FixedFeeOverageCalculatedwithRateTimesHours,
	-(sum(PotentialFees)-sum(RevenueRecognized))+sum(AmountWrittenOff) as WriteUpWriteOff_WITHOUT_Adjustments,
	-(sum(PotentialFees)-sum(RevenueRecognized))+sum(AmountWrittenOff)+sum(Contractor)+sum(Expenses)+sum(Other)  as WriteUpWriteOff_WITH_Adjustments

from
	BG_Time_and_WriteOff_Category_withEngStatus_CG tw
		left outer join
	[chil-crm-04].[BurwoodGroupInc_MSCRM].dbo.BG_Opportunity_Resources_CG o with (nolock) on tw.OpportunityId=o.OpportunityId
where
	TimeDate>=@StartDate
	and TimeDate<=@EndDate
group by
	BillingOffice,
	Engagement,
	EngagementStatus,
	BillingType,
	o.Owner,
	EngagementId,
	Resource
	
GO
