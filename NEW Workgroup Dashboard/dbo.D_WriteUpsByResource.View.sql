USE [Changepoint]
GO
/****** Object:  View [dbo].[D_WriteUpsByResource]    Script Date: 2/11/2020 4:26:58 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE VIEW [dbo].[D_WriteUpsByResource]
AS
SELECT DISTINCT TOP 99999 dbo.RevenueDetail.RevenueDetailID, dbo.Engagement.CustomerId, dbo.RevenueDetail.EngagementID, dbo.Engagement.[Name], dbo.RevenueDetail.PostingDate, dbo.Time.ResourceId, 
				SUM(dbo.Time.RegularHours) OVER(PARTITION BY dbo.RevenueDetail.RevenueDetailID, dbo.RevenueDetail.EngagementId, dbo.Time.ResourceId) AS ResourceHours, 
				SUM(dbo.Time.RegularHours) OVER(PARTITION BY dbo.RevenueDetail.RevenueDetailID, dbo.RevenueDetail.EngagementId) AS TotalHours,
				CASE WHEN 
					SUM(dbo.Time.RegularHours) OVER(PARTITION BY dbo.RevenueDetail.RevenueDetailID, dbo.RevenueDetail.EngagementId) = 0 THEN 0 
				ELSE 
					SUM(dbo.Time.RegularHours) OVER(PARTITION BY dbo.RevenueDetail.RevenueDetailID, dbo.RevenueDetail.EngagementId, dbo.Time.ResourceId) 
					/ SUM(dbo.Time.RegularHours) OVER(PARTITION BY dbo.RevenueDetail.RevenueDetailID, dbo.RevenueDetail.EngagementId)
				END AS ResourcePercent,
				dbo.RevenueDetail.RevenueAmount AS TotalAmount,
				CASE WHEN 
					SUM(dbo.Time.RegularHours) OVER(PARTITION BY dbo.RevenueDetail.RevenueDetailID, dbo.RevenueDetail.EngagementId) * dbo.RevenueDetail.RevenueAmount = 0 THEN 0
				ELSE
					SUM(dbo.Time.RegularHours) OVER(PARTITION BY dbo.RevenueDetail.RevenueDetailID, dbo.RevenueDetail.EngagementId, dbo.Time.ResourceId) 
					/ SUM(dbo.Time.RegularHours) OVER(PARTITION BY dbo.RevenueDetail.RevenueDetailID, dbo.RevenueDetail.EngagementId) * dbo.RevenueDetail.RevenueAmount
				END AS ResourceAmount
FROM  dbo.RevenueDetail INNER JOIN
      dbo.Time ON dbo.RevenueDetail.EngagementID = dbo.Time.EngagementId
	  JOIN dbo.Engagement ON dbo.Time.EngagementId = dbo.Engagement.EngagementId
WHERE ReasonCode = 'e41156cf-35b1-49e4-868c-c1f4e8121b5a'


UNION ALL

SELECT * 
FROM dbo.D_WriteOffsByResource
WHERE TotalAmount < -1

--ORDER BY dbo.RevenueDetail.RevenueDetailID, dbo.RevenueDetail.EngagementID, dbo.Time.ResourceId

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
         Begin Table = "RevenueDetail"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 324
               Right = 247
            End
            DisplayFlags = 280
            TopColumn = 12
         End
         Begin Table = "Time_1"
            Begin Extent = 
               Top = 5
               Left = 819
               Bottom = 326
               Right = 1053
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Time"
            Begin Extent = 
               Top = 13
               Left = 397
               Bottom = 323
               Right = 631
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'D_WriteUpsByResource'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'D_WriteUpsByResource'
GO
