USE [Changepoint]
GO
/****** Object:  View [dbo].[D_ForecastTimeAndOpportunities]    Script Date: 2/11/2020 4:26:58 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE VIEW [dbo].[D_ForecastTimeAndOpportunities]
AS
SELECT		ta.ResourceId, 'Forecast Time' AS Type, w.ProjectId, e.Name AS EngagementName, p.Name AS ProjectName, t.Name AS TaskName, w.PlannedHours, w.ActualHours, 
			f.Period, f.StartDate AS PeriodStartDate, f.EndDate AS PeriodEndDate, 
			f.Period + ' (' + CONVERT(nvarchar(30),f.StartDate,101) + ' - ' + CONVERT(nvarchar(30),f.EndDate,101) + ')' AS Week,
			ebr.NegotiatedRate AS BillingRate, rr.HourlyCostRate AS CostRate, bo.[Description] AS Region
FROM		AssignmentFiscalRollup w WITH (nolock)
INNER JOIN	FiscalPeriod f WITH (nolock) ON w.FiscalPeriodId = f.FiscalPeriodId
INNER JOIN	TaskAssignment ta WITH (nolock) ON w.TaskAssignmentId = ta.TaskAssignmentId AND ta.Deleted = 0
INNER JOIN	Project p WITH (nolock) ON w.ProjectId = p.ProjectId
INNER JOIN	Tasks t WITH (nolock) ON ta.TaskId = t.TaskId
INNER JOIN	Engagement e WITH (nolock) ON t.EngagementId = e.EngagementId
INNER JOIN  BillingOffice bo WITH (nolock) ON e.BillingOfficeId = bo.BillingOfficeId
LEFT OUTER JOIN EngagementBillingRates ebr WITH (nolock) ON ta.BillingRole = ebr.BillingRoleId AND ta.EngagementId = ebr.EngagementId AND ta.Deleted = 0
OUTER APPLY (SELECT TOP 1 HourlyCostRate
                 FROM ResourceRate WITH (nolock)
             WHERE ResourceId = ta.ResourceID AND Active = 1
             ORDER BY EffectiveDate DESC) rr
WHERE (DATEDIFF(d,f.StartDate, f.EndDate) = 6) and coalesce(ta.TaskStatus, 'A')='A'
AND w.PlannedHours > 0 AND w.ActualHours = 0 AND f.EndDate > GETDATE()

UNION ALL

SELECT		os.ResourceId, 'Forecast Opportunity' AS Type, NULL AS ProjectId, 'Opportunity' AS EngagementName, o.Name AS ProjectName, ISNULL(os.Comments,'') AS TaskName, 
			CASE
				WHEN os.StartDate = f.StartDate AND os.EndDate >= f.EndDate THEN ROUND((DATEDIFF(DAY, os.StartDate,f.EndDate)-1)*(os.EstimatedTime/os.WorkingDays),1) --start on Saturday within this period, end in future period
				WHEN os.StartDate = (f.StartDate + 1) AND os.EndDate >= f.EndDate THEN ROUND((DATEDIFF(DAY, os.StartDate,f.EndDate))*(os.EstimatedTime/os.WorkingDays),1) --start on Sunday within this period, end in future period
				WHEN os.StartDate = f.StartDate AND os.EndDate < f.EndDate THEN ROUND((DATEDIFF(DAY, os.StartDate,os.EndDate)-1)*(os.EstimatedTime/os.WorkingDays),1) --start on Saturday within this period, end within this period
				WHEN os.StartDate = (f.StartDate + 1) AND os.EndDate < f.EndDate THEN ROUND((DATEDIFF(DAY, os.StartDate,os.EndDate))*(os.EstimatedTime/os.WorkingDays),1) --start on Sunday within this period, end within this period
				WHEN os.StartDate > f.StartDate AND os.EndDate >= f.EndDate THEN ROUND((DATEDIFF(DAY, os.StartDate,f.EndDate)+1)*(os.EstimatedTime/os.WorkingDays),1) --start within this period, end in future period
				WHEN os.StartDate > f.StartDate AND os.EndDate < f.EndDate THEN ROUND((DATEDIFF(DAY, os.StartDate,os.EndDate)+1)*(os.EstimatedTime/os.WorkingDays),1) --start within this period, end within this period
				WHEN os.StartDate < f.StartDate AND os.EndDate >= f.EndDate THEN ROUND(5*(os.EstimatedTime/os.WorkingDays),1) --start in prior period, end in future period (full week of hours)
				WHEN os.StartDate < f.StartDate AND os.EndDate = f.StartDate THEN 0 --start in prior period, end on Saturday within this period
				WHEN os.StartDate < f.StartDate AND os.EndDate = (f.StartDate + 1) THEN 0 --start in prior period, end on Sunday within this period
				WHEN os.StartDate < f.StartDate AND os.EndDate < f.EndDate THEN ROUND((DATEDIFF(DAY, f.StartDate,os.EndDate)-1)*(os.EstimatedTime/os.WorkingDays),1) --start in prior period, end within this period
			END AS PlannedHours, 
			os.EstimatedTime, f.Period, f.StartDate AS PeriodStartDate, f.EndDate AS PeriodEndDate, 
			f.Period + ' (' + CONVERT(nvarchar(30),f.StartDate,101) + ' - ' + CONVERT(nvarchar(30),f.EndDate,101) + ')' AS Week,
			os.NegotiatedBillingRate AS BillingRate, rr.HourlyCostRate AS CostRate, bo.[Description] AS Region
FROM		OpportunityServices os WITH (nolock)
INNER JOIN	FiscalPeriod f WITH (nolock) ON f.BillingOfficeId='A688AC3B-03DA-44C3-8A05-CBE069E1A6F2' and f.Deleted=0 and os.StartDate <= f.EndDate AND os.EndDate >= f.StartDate
INNER JOIN	Opportunity o WITH (nolock) ON os.OpportunityId = o.OpportunityId
INNER JOIN  BillingOffice bo WITH (nolock) ON o.BillingOfficeId = bo.BillingOfficeId
OUTER APPLY (SELECT TOP 1 HourlyCostRate
                 FROM ResourceRate WITH (nolock)
             WHERE ResourceId = os.ResourceID AND Active = 1
             ORDER BY EffectiveDate DESC) rr
WHERE		o.Deleted = 0 AND (DATEDIFF(d,f.StartDate, f.EndDate) = 6)
AND f.EndDate > GETDATE()

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
         Begin Table = "ActivityPriority"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 208
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'D_ForecastTimeAndOpportunities'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'D_ForecastTimeAndOpportunities'
GO
