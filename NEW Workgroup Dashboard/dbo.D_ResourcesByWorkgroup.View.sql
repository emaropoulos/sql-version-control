USE [Changepoint]
GO
/****** Object:  View [dbo].[D_ResourcesByWorkgroup]    Script Date: 2/11/2020 4:26:58 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









CREATE VIEW [dbo].[D_ResourcesByWorkgroup]
AS
-- Add resources that are assigned directly to a workgroup
SELECT IIF(r.EmployeeType = 'CO', 'Contractor', 'Burwood Employee') AS ResourceType, w.WorkgroupId, w.Name AS Workgroup, NULL AS ChildWorkgroup, r.Name AS ResourceName,
		r.EmployeeType, r.ResourceId, whm.EffectiveDate AS HireDate, ISNULL(whm.EndDate, '2099-12-31') AS TerminationDate, rp.AnnualTargetHours, rr.Rate1 AS LoadedAnnualSalary,
		IIF(ISNULL(r.TerminationDate, '2099-12-31') = '2099-12-31', 0, 1) AS Terminated, r.name + CAST(whm.HistoryId AS VARCHAR(36)) AS WorkgroupResourceId, ra.EmailAddress AS WorkgroupOwnerEmail
FROM Workgroup w WITH (nolock)
LEFT OUTER JOIN WorkgroupHistoryMember whm WITH (nolock) ON w.WorkgroupId = whm.WorkgroupId AND DateDiff(d, whm.EffectiveDate, ISNULL(whm.EndDate, '2099-12-31')) > 1
LEFT OUTER JOIN Resources r WITH (nolock) ON whm.ResourceId = r.ResourceId AND r.Deleted = 0
LEFT OUTER JOIN ResourcePayroll rp WITH (nolock) ON r.ResourceId = rp.ResourceId 
LEFT OUTER JOIN ResourceRate rr WITH (nolock) ON r.ResourceId = rr.ResourceId  AND rr.Active = 1
LEFT OUTER JOIN WorkgroupResourceManagers wrm ON w.workgroupid = wrm.workgroupid
LEFT OUTER JOIN resourceaddress ra on ra.resourceid = wrm.ResourceId
WHERE w.Deleted = 0 AND r.ResourceId IS NOT NULL

UNION ALL

-- Add resourcess that are assigned to a child workgroup
SELECT IIF(r.EmployeeType = 'CO', 'Contractor', 'Burwood Employee') AS ResourceType, w.WorkgroupId, w.Name AS Workgroup, NULL AS ChildWorkgroup, r.Name AS ResourceName,
		r.EmployeeType, r.ResourceId, whm.EffectiveDate AS HireDate, ISNULL(whm.EndDate, '2099-12-31') AS TerminationDate, rp.AnnualTargetHours, rr.Rate1 AS LoadedAnnualSalary,
		IIF(ISNULL(r.TerminationDate, '2099-12-31') = '2099-12-31', 0, 1) AS Terminated, r.name + CAST(whm.HistoryId AS VARCHAR(36)) AS WorkgroupResourceId, ra.EmailAddress AS WorkgroupOwnerEmail
FROM Workgroup w WITH (nolock)
LEFT OUTER JOIN Workgroup wc WITH (nolock) ON w.WorkgroupId = wc.Parent AND wc.Deleted = 0
LEFT OUTER JOIN WorkgroupHistoryMember whm WITH (nolock) ON wc.WorkgroupId = whm.WorkgroupId AND DateDiff(d, whm.EffectiveDate, ISNULL(whm.EndDate, '2099-12-31')) > 1
LEFT OUTER JOIN Resources r WITH (nolock) ON whm.ResourceId = r.ResourceId AND r.Deleted = 0
LEFT OUTER JOIN ResourcePayroll rp WITH (nolock) ON r.ResourceId = rp.ResourceId 
LEFT OUTER JOIN ResourceRate rr WITH (nolock) ON r.ResourceId = rr.ResourceId  AND rr.Active = 1
LEFT OUTER JOIN WorkgroupResourceManagers wrm ON w.workgroupid = wrm.workgroupid
LEFT OUTER JOIN resourceaddress ra on ra.resourceid = wrm.ResourceId
WHERE w.Deleted = 0 AND r.ResourceId IS NOT NULL

UNION ALL

-- Add resourcess that are assigned to a child of a child workgroup
SELECT IIF(r.EmployeeType = 'CO', 'Contractor', 'Burwood Employee') AS ResourceType, wp.WorkgroupId, wp.Name AS Workgroup, w.Name AS ChildWorkgroup, r.Name AS ResourceName,
		r.EmployeeType, r.ResourceId, whm.EffectiveDate AS HireDate, ISNULL(whm.EndDate, '2099-12-31') AS TerminationDate, rp.AnnualTargetHours, rr.Rate1 AS LoadedAnnualSalary,
		IIF(ISNULL(r.TerminationDate, '2099-12-31') = '2099-12-31', 0, 1) AS Terminated, r.name + CAST(whm.HistoryId AS VARCHAR(36)) AS WorkgroupResourceId, ra.EmailAddress AS WorkgroupOwnerEmail
FROM Workgroup w WITH (nolock)
LEFT OUTER JOIN Workgroup wc WITH (nolock) ON w.WorkgroupId = wc.Parent AND wc.Deleted = 0
LEFT OUTER JOIN WorkgroupHistoryMember whm WITH (nolock) ON wc.WorkgroupId = whm.WorkgroupId AND DateDiff(d, whm.EffectiveDate, ISNULL(whm.EndDate, '2099-12-31')) > 1
LEFT OUTER JOIN Workgroup wp WITH (nolock) ON wp.WorkgroupId = w.Parent AND w.Deleted = 0
LEFT OUTER JOIN Resources r WITH (nolock) ON whm.ResourceId = r.ResourceId AND r.Deleted = 0
LEFT OUTER JOIN ResourcePayroll rp WITH (nolock) ON r.ResourceId = rp.ResourceId 
LEFT OUTER JOIN ResourceRate rr WITH (nolock) ON r.ResourceId = rr.ResourceId  AND rr.Active = 1
LEFT OUTER JOIN WorkgroupResourceManagers wrm ON w.workgroupid = wrm.workgroupid
LEFT OUTER JOIN resourceaddress ra on ra.resourceid = wrm.ResourceId
WHERE w.Deleted = 0 AND r.ResourceId IS NOT NULL AND Wp.name IS NOT NULL

UNION ALL

--Add all workgroups and associate to a generic userid to allow non-workgroup Associates and FF contractors to be supported
SELECT 'Other' AS ResourceType, w.WorkgroupId, w.Name AS Workgroup, NULL AS ChildWorkgroup, NULL AS ResourceName, NULL AS EmployeeType, 
		'00000000-0000-0000-0000-000000000000' AS ResourceId, '2014-01-01' AS HireDate, '2099-12-31' AS TerminationDate, 0 AS AnnualTargetHours, 0 AS LoadedAnnualSalary, 0 AS Terminated,
		'00000000-0000-0000-0000-000000000000' AS WorkgroupResourceId, ra.EmailAddress AS WorkgroupOwnerEmail
FROM Workgroup w WITH (nolock)
LEFT OUTER JOIN WorkgroupResourceManagers wrm ON w.workgroupid = wrm.workgroupid
LEFT OUTER JOIN resourceaddress ra on ra.resourceid = wrm.ResourceId
WHERE w.Deleted = 0


GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Activity"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 214
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'D_ResourcesByWorkgroup'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'D_ResourcesByWorkgroup'
GO
