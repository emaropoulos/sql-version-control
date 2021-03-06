USE [Changepoint]
GO
/****** Object:  View [dbo].[D_Utilizatoin_ResourcesByWorkgroup]    Script Date: 2/11/2020 4:26:58 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO













CREATE VIEW [dbo].[D_Utilizatoin_ResourcesByWorkgroup]
AS
-- Add resources that are assigned directly to a workgroup
SELECT IIF(r.EmployeeType = 'CO', 'Contractor', 'Burwood Employee') AS ResourceType, rg.Description as Region, cc.Name AS CostCenter, r.Title AS Title, w.WorkgroupId, w.Name AS Workgroup, NULL AS ChildWorkgroup, r.Name AS ResourceName,
		r.EmployeeType, r.ResourceId, whm.EffectiveDate AS HireDate, ISNULL(whm.EndDate, '2099-12-31') AS TerminationDate, rp.AnnualTargetHours, rr.Rate1 AS LoadedAnnualSalary,
		IIF(ISNULL(r.TerminationDate, '2099-12-31') = '2099-12-31', 0, 1) AS Terminated, r.name + CAST(whm.HistoryId AS VARCHAR(36)) AS WorkgroupResourceId, ra.EmailAddress AS WorkgroupOwnerEmail
FROM Workgroup w WITH (nolock)
LEFT OUTER JOIN WorkgroupHistoryMember whm WITH (nolock) ON w.WorkgroupId = whm.WorkgroupId AND DateDiff(d, whm.EffectiveDate, ISNULL(whm.EndDate, '2099-12-31')) > 1
LEFT OUTER JOIN Resources r WITH (nolock) ON whm.ResourceId = r.ResourceId AND r.Deleted = 0
JOIN CostCenters cc ON cc.CostCenter = r.CostCenterId
JOIN UDFCode u ON u.EntityId=r.ResourceID
LEFT OUTER JOIN ResourcePayroll rp WITH (nolock) ON r.ResourceId = rp.ResourceId 
LEFT OUTER JOIN ResourceRate rr WITH (nolock) ON r.ResourceId = rr.ResourceId  AND rr.Active = 1
LEFT OUTER JOIN WorkgroupResourceManagers wrm ON w.workgroupid = wrm.workgroupid
LEFT OUTER JOIN resourceaddress ra on ra.resourceid = wrm.ResourceId
JOIN CodeDetail rg on u.UDFCode=rg.CodeDetail and u.ItemName=rg.CodeType
WHERE w.Deleted = 0 AND r.ResourceId IS NOT NULL
AND u.ItemName='ResourceCode1'

UNION ALL

-- Add resourcess that are assigned to a child workgroup
SELECT IIF(r.EmployeeType = 'CO', 'Contractor', 'Burwood Employee') AS ResourceType, rg.Description as Region, cc.Name AS CostCenter, r.Title AS Title, w.WorkgroupId, w.Name AS Workgroup, NULL AS ChildWorkgroup, r.Name AS ResourceName,
		r.EmployeeType, r.ResourceId, whm.EffectiveDate AS HireDate, ISNULL(whm.EndDate, '2099-12-31') AS TerminationDate, rp.AnnualTargetHours, rr.Rate1 AS LoadedAnnualSalary,
		IIF(ISNULL(r.TerminationDate, '2099-12-31') = '2099-12-31', 0, 1) AS Terminated, r.name + CAST(whm.HistoryId AS VARCHAR(36)) AS WorkgroupResourceId, ra.EmailAddress AS WorkgroupOwnerEmail
FROM Workgroup w WITH (nolock)
LEFT OUTER JOIN Workgroup wc WITH (nolock) ON w.WorkgroupId = wc.Parent AND wc.Deleted = 0
LEFT OUTER JOIN WorkgroupHistoryMember whm WITH (nolock) ON wc.WorkgroupId = whm.WorkgroupId AND DateDiff(d, whm.EffectiveDate, ISNULL(whm.EndDate, '2099-12-31')) > 1
LEFT OUTER JOIN Resources r WITH (nolock) ON whm.ResourceId = r.ResourceId AND r.Deleted = 0
JOIN CostCenters cc ON cc.CostCenter = r.CostCenterId
JOIN UDFCode u ON u.EntityId=r.ResourceID
LEFT OUTER JOIN ResourcePayroll rp WITH (nolock) ON r.ResourceId = rp.ResourceId 
LEFT OUTER JOIN ResourceRate rr WITH (nolock) ON r.ResourceId = rr.ResourceId  AND rr.Active = 1
LEFT OUTER JOIN WorkgroupResourceManagers wrm ON w.workgroupid = wrm.workgroupid
LEFT OUTER JOIN resourceaddress ra on ra.resourceid = wrm.ResourceId
JOIN CodeDetail rg on u.UDFCode=rg.CodeDetail and u.ItemName=rg.CodeType
WHERE w.Deleted = 0 AND r.ResourceId IS NOT NULL
AND u.ItemName='ResourceCode1'

UNION ALL

-- Add resourcess that are assigned to a child of a child workgroup
SELECT IIF(r.EmployeeType = 'CO', 'Contractor', 'Burwood Employee') AS ResourceType, rg.Description as Region, cc.Name AS CostCenter, r.Title AS Title, wp.WorkgroupId, wp.Name AS Workgroup, w.Name AS ChildWorkgroup, r.Name AS ResourceName,
		r.EmployeeType, r.ResourceId, whm.EffectiveDate AS HireDate, ISNULL(whm.EndDate, '2099-12-31') AS TerminationDate, rp.AnnualTargetHours, rr.Rate1 AS LoadedAnnualSalary,
		IIF(ISNULL(r.TerminationDate, '2099-12-31') = '2099-12-31', 0, 1) AS Terminated, r.name + CAST(whm.HistoryId AS VARCHAR(36)) AS WorkgroupResourceId, ra.EmailAddress AS WorkgroupOwnerEmail
FROM Workgroup w WITH (nolock)
LEFT OUTER JOIN Workgroup wc WITH (nolock) ON w.WorkgroupId = wc.Parent AND wc.Deleted = 0
LEFT OUTER JOIN WorkgroupHistoryMember whm WITH (nolock) ON wc.WorkgroupId = whm.WorkgroupId AND DateDiff(d, whm.EffectiveDate, ISNULL(whm.EndDate, '2099-12-31')) > 1
LEFT OUTER JOIN Workgroup wp WITH (nolock) ON wp.WorkgroupId = w.Parent AND w.Deleted = 0
LEFT OUTER JOIN Resources r WITH (nolock) ON whm.ResourceId = r.ResourceId AND r.Deleted = 0
JOIN CostCenters cc ON cc.CostCenter = r.CostCenterId
JOIN UDFCode u ON u.EntityId=r.ResourceID
LEFT OUTER JOIN ResourcePayroll rp WITH (nolock) ON r.ResourceId = rp.ResourceId 
LEFT OUTER JOIN ResourceRate rr WITH (nolock) ON r.ResourceId = rr.ResourceId  AND rr.Active = 1
LEFT OUTER JOIN WorkgroupResourceManagers wrm ON w.workgroupid = wrm.workgroupid
LEFT OUTER JOIN resourceaddress ra on ra.resourceid = wrm.ResourceId
JOIN CodeDetail rg on u.UDFCode=rg.CodeDetail and u.ItemName=rg.CodeType
WHERE w.Deleted = 0 AND r.ResourceId IS NOT NULL
AND u.ItemName='ResourceCode1'

UNION ALL

--Add all workgroups and associate to a generic userid to allow non-workgroup Associates and FF contractors to be supported
SELECT 'Other' AS ResourceType, NULL AS Region, NULL AS CostCenter, NULL AS Title,  w.WorkgroupId, w.Name AS Workgroup, NULL AS ChildWorkgroup, NULL AS ResourceName, NULL AS EmployeeType, 
		'00000000-0000-0000-0000-000000000000' AS ResourceId, '2014-01-01' AS HireDate, '2099-12-31' AS TerminationDate, 0 AS AnnualTargetHours, 0 AS LoadedAnnualSalary, 0 AS Terminated,
		'00000000-0000-0000-0000-000000000000' AS WorkgroupResourceId, ra.EmailAddress AS WorkgroupOwnerEmail
FROM Workgroup w WITH (nolock)
LEFT OUTER JOIN WorkgroupResourceManagers wrm ON w.workgroupid = wrm.workgroupid
LEFT OUTER JOIN resourceaddress ra on ra.resourceid = wrm.ResourceId
WHERE w.Deleted = 0


GO
