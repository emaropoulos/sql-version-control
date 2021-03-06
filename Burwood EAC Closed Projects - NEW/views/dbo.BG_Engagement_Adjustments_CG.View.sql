USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_Engagement_Adjustments_CG]    Script Date: 10/14/2019 3:40:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[BG_Engagement_Adjustments_CG] as 
select
	Engagement,
	EngagementId,
	convert(date, d.UDFDate) as CloseDate,
	sum(PotentialFees) as PotentialFees,
	sum(RevenueRecognized) as RevenueRecognized,
	sum(FixedFeeOverage) as FixedFeeOverage,
	sum(Contractor) as ContractorAdjustment,
	sum(Expenses) as ExpenseAdjustment,
	sum(Other) as OtherAdjustment,
	sum(TotalWriteUpWriteOff) as WriteUpWriteOff
from
	[BG_Time_and_WriteOff_Category_CG] tw with (nolock)
		left outer join 
	UDFDate d with (nolock) on tw.EngagementId=d.EntityId and d.ItemName='EngagementText1'
group by
	Engagement, 
	EngagementId,
	d.UDFDate


GO
