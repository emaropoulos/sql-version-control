USE [Changepoint]
GO
/****** Object:  View [dbo].[BG_EngagementProjects_2018_CG]    Script Date: 10/14/2019 3:21:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Script for SelectTopNRows command from SSMS  ******/
CREATE VIEW [dbo].[BG_EngagementProjects_2018_CG] AS
SELECT Distinct EngagementID,
	Engagement,
	ProjectID,
	Project,
	NumberOfProjects
  FROM [Changepoint].[dbo].[BG_ProjectDashboard_Engagement_2018_CG]
GO
