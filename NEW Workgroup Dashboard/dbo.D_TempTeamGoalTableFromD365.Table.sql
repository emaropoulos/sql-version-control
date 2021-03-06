USE [Changepoint]
GO
/****** Object:  Table [dbo].[D_TempTeamGoalTableFromD365]    Script Date: 12/20/2019 9:04:26 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[D_TempTeamGoalTableFromD365](
	[TeamName] [nvarchar](50) NOT NULL,
	[RevenueGoal] [numeric](18, 0) NULL,
	[NetIncomeGoal] [numeric](18, 0) NULL,
 CONSTRAINT [PK_D_TempTeamGoalTableFromD365] PRIMARY KEY CLUSTERED 
(
	[TeamName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO
