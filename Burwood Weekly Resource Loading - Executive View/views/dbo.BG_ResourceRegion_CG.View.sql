USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_ResourceRegion_CG]    Script Date: 10/17/2019 4:18:07 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO








CREATE VIEW [dbo].[BG_ResourceRegion_CG] AS

select
	distinct
	r.Name as Resource,
	r.ResourceId,
	c.Description as Region,
	r.Deleted,
	r.TerminationDate
from
	Resources r with (nolock)
		left outer join 
	UDFCode u with (nolock) on r.ResourceId=u.EntityId and u.ItemName='ResourceCode1'
		left outer join  
	CodeDetail c with (nolock) on u.UDFCode=c.CodeDetail
where
	c.Description <>'LA-LATAM Region'



GO
