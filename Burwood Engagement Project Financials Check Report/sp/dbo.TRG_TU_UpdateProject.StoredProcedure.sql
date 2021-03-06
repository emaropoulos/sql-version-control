USE [Changepoint]
GO
/****** Object:  StoredProcedure [dbo].[TRG_TU_UpdateProject]    Script Date: 10/14/2019 2:31:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[TRG_TU_UpdateProject](
                @XMLInserted XML  = '',
                @XMLDeleted  XML  = '')
AS
  SET NOCOUNT  ON
  
  DECLARE  @TRG_Inserted  TABLE(
                                ProjectId    UNIQUEIDENTIFIER,
                                EngagementId UNIQUEIDENTIFIER,
                                Billable     BIT
                                )
  DECLARE  @TRG_Deleted  TABLE(
                               ProjectId UNIQUEIDENTIFIER,
                               Billable  BIT
                               )
  INSERT INTO @TRG_Inserted
             (ProjectId,
              EngagementId,
              Billable)
  SELECT doc.col.value('projectid[1]','varchar(38)') ProjectId,
         doc.col.value('engagementid[1]','varchar(38)') EngagementId,
         doc.col.value('billable[1]','bit') Billable
  FROM   @XMLInserted.nodes('/root/Project') doc(col)
  INSERT INTO @TRG_Deleted
             (ProjectId,
              Billable)
  SELECT doc.col.value('projectid[1]','varchar(38)') ProjectId,
         doc.col.value('billable[1]','bit') Billable
  FROM   @XMLDeleted.nodes('/root/Project') doc(col)
  DECLARE  @TimeId         AS UNIQUEIDENTIFIER,
           @RegularHours  NUMERIC(10,3),
           @OvertimeHours NUMERIC(10,3),
           @DiffRegHours  NUMERIC(10,3),
           @DiffOTHours   NUMERIC(10,3),
           @EngagementId   AS UNIQUEIDENTIFIER,
           @RegularDays   NUMERIC(10,3),
           @OvertimeDays  NUMERIC(10,3),
           @DiffRegDays   NUMERIC(10,3),
           @DiffOTDays    NUMERIC(10,3)
  DECLARE  @UpdatePreInvoicedTime  TABLE(
                                         CustomerId          UNIQUEIDENTIFIER,
                                         EngagementId        UNIQUEIDENTIFIER,
                                         ProjectId           UNIQUEIDENTIFIER,
                                         TimeId              UNIQUEIDENTIFIER,
                                         TimeDate            DATETIME,
                                         RegularHours        NUMERIC(10,3),
                                         OvertimeHours       NUMERIC(10,3),
                                         TaskId              UNIQUEIDENTIFIER,
                                         GlobalWorkgroupId   UNIQUEIDENTIFIER,
                                         WorkgroupId         UNIQUEIDENTIFIER,
                                         ResourceId          UNIQUEIDENTIFIER,
                                         FixedFee            BIT,
                                         InvoiceId           UNIQUEIDENTIFIER   DEFAULT NULL,
                                         InvoiceStatus       INT   DEFAULT NULL,
                                         BillingRate         MONEY,
                                         CostRate            MONEY,
                                         BillingCurrency     VARCHAR(3),
                                         CostCurrency        VARCHAR(3),
                                         RateDate            DATETIME,
                                         WorkLocationGroupId UNIQUEIDENTIFIER,
                                         WorkLocationId      UNIQUEIDENTIFIER,
                                         WorkCodeCategoryId  UNIQUEIDENTIFIER,
                                         WorkCodeId          UNIQUEIDENTIFIER,
                                         SplitEngagementId   UNIQUEIDENTIFIER,
                                         InvRegHours         NUMERIC(10,3),
                                         InvOTHours          NUMERIC(10,3),
                                         OTCostRate          MONEY,
                                         OTCostCurrency      VARCHAR(3),
                                         RegularDays         NUMERIC(8,3),
                                         OvertimeDays        NUMERIC(8,3),
                                         InvRegDays          NUMERIC(8,3),
                                         InvOTDays           NUMERIC(8,3),
                                         ConversionToDay     NUMERIC(5,3),
                                         [Description]       NVARCHAR(MAX)
                                         )
  IF (SELECT COUNT(* )
      FROM   @TRG_Inserted) = 1
    BEGIN
      IF (SELECT Billable
          FROM   @TRG_Deleted) = 0
         AND (SELECT Billable
              FROM   @TRG_Inserted) = 1
         AND (SELECT e.Billable
              FROM   Engagement e WITH (NOLOCK)
                     INNER JOIN @TRG_Inserted i
                       ON e.EngagementId = i.EngagementId) = 1
        BEGIN
          IF EXISTS (SELECT TOP 1 1
                     FROM   SplitBillingRule s WITH (NOLOCK)
                            INNER JOIN @TRG_Inserted i
                              ON s.MainEngagementId = i.EngagementId AND s.Percentage > 0)
            BEGIN
			  
			  
              INSERT INTO SplitBillExpense
              SELECT s.SplitEngagementId,
                     e.ExpenseId
              FROM   @TRG_Inserted i
                     INNER JOIN Expense e WITH (NOLOCK)
                       ON i.ProjectId = ISNULL(e.AltProjectId, e.ProjectId)
                          AND e.Billable = 1
                          AND isnull(e.ApprovalStatus,'') = 'A'
                          AND e.InvoiceStatus = 0
                     INNER JOIN SplitBillingRule s WITH (NOLOCK)
                       ON i.EngagementId = s.MainEngagementId
						  AND s.Percentage > 0
              
              SELECT @EngagementId = EngagementId
              FROM   @TRG_Inserted
              DECLARE  @TU_Time  TABLE(
                                       CustomerId        UNIQUEIDENTIFIER   NOT NULL,
                                       EngagementId      UNIQUEIDENTIFIER   NOT NULL,
                                       TaskId            UNIQUEIDENTIFIER   NOT NULL,
                                       FixedFee          BIT   DEFAULT 0   NOT NULL,
                                       ProjectId         UNIQUEIDENTIFIER   NOT NULL,
                                       TimeId            UNIQUEIDENTIFIER   NOT NULL,
                                       RegularHours      NUMERIC(10,3)   NOT NULL,
                                       OvertimeHours     NUMERIC(10,3)   NOT NULL,
                                       RegHours          NUMERIC(10,3)   NOT NULL,
                                       OTHours           NUMERIC(10,3)   NOT NULL,
                                       InvoiceStatus     BIT   DEFAULT 0   NOT NULL,
                                       SplitEngagementId UNIQUEIDENTIFIER   NOT NULL,
                                       RegularDays       NUMERIC(10,3)   NOT NULL,
                                       OvertimeDays      NUMERIC(10,3)   NOT NULL,
                                       RegDays           NUMERIC(10,3)   NOT NULL,
                                       OTDays            NUMERIC(10,3)   NOT NULL
                                       )
              INSERT INTO @TU_Time
              SELECT s.CustomerId,
                     s.MainEngagementId,
                     ts.TaskId,
                     ts.FixedFee,
                     i.ProjectId,
                     t.TimeId,
                     t.RegularHours,
                     t.OvertimeHours,
                     t.RegularHours
                       * s.Percentage
                       / 100,
                     t.OvertimeHours
                       * s.Percentage
                       / 100,
                     t.InvoiceStatus,
                     s.SplitEngagementId,
                     t.RegularDay,
                     t.OvertimeDay,
                     t.RegularDay
                       * s.Percentage
                       / 100,
                     t.OvertimeDay
                       * s.Percentage
                       / 100
              FROM   @TRG_Inserted i
                     INNER JOIN TIME t WITH (NOLOCK)
                       ON i.ProjectId = t.ProjectId
                          AND isnull(t.ApprovalStatus,'') = 'A'
                          AND t.InvoiceStatus = 0
                          AND t.TimeId IN (
                                           SELECT TIME.timeid
                                           FROM   TIME WITH (NOLOCK)
                                                  INNER JOIN taskhistory th1 WITH (NOLOCK)
                                                    ON TIME.projectid = th1.projectid
                                                       AND TIME.taskid = th1.taskid
                                                       AND th1.applieddate > TIME.timedate
                                                       AND th1.billable = 1
                                                       AND th1.taskhistoryid NOT IN (SELECT th2.taskhistoryid
                                                                                     FROM   taskhistory th3 WITH (NOLOCK),
                                                                                            taskhistory th2 WITH (NOLOCK)
                                                                                     WHERE  TIME.taskid = th3.taskid
                                                                                            AND TIME.projectid = th3.projectid
                                                                                            AND th3.applieddate > TIME.timedate
                                                                                            AND th3.projectid = th2.projectid
                                                                                            AND th3.taskid = th2.taskid
                                                                                            AND th2.applieddate >= TIME.timedate
                                                                                            AND th3.taskhistoryid <> th2.taskhistoryid
                                                                                            AND th3.applieddate < th2.applieddate)
                                           UNION 
                                           
                                           
                                           SELECT TIME.timeid
                                           FROM   TIME WITH (NOLOCK)
                                                  INNER JOIN Tasks WITH (NOLOCK)
                                                    ON TIME.taskid = Tasks.taskid
                                                       AND TIME.projectid = Tasks.projectid
                                                       AND Tasks.billable = 1
                                           WHERE  NOT EXISTS (SELECT TOP 1 1
                                                              FROM   taskhistory th WITH (NOLOCK)
                                                              WHERE  TIME.projectid = th.projectid
                                                                     AND TIME.taskid = th.taskid
                                                                     AND th.applieddate > TIME.timedate))
                     INNER JOIN Tasks ts WITH (NOLOCK)
                       ON i.ProjectId = ts.ProjectId
                          AND t.Taskid = ts.TaskId
                     INNER JOIN SplitBillingRule s WITH (NOLOCK)
                       ON ts.EngagementId = s.MainEngagementId
                          AND s.Percentage > 0
              UPDATE TIME
              SET    billable = 1, UpdatedOn = GETDATE()
              WHERE  timeid IN (SELECT DISTINCT timeid
                                FROM   @TU_Time)
                     AND billable <> 1
              DECLARE UpdateCursor CURSOR FAST_FORWARD FOR
              SELECT DISTINCT TimeId,
                              RegularHours,
                              OvertimeHours,
                              RegularDays,
                              OvertimeDays
              FROM   @TU_Time
              WHERE  InvoiceStatus = 0
              OPEN UpdateCursor
              FETCH NEXT FROM UpdateCursor
              INTO @TimeId,
                   @RegularHours,
                   @OvertimeHours,
                   @RegularDays,
                   @OvertimeDays
              WHILE @@FETCH_STATUS = 0
                BEGIN
                  SELECT @DiffRegHours = @RegularHours
                                           - sum(RegHours),
                         @DiffOTHours = @OvertimeHours
                                          - sum(OTHours),
                         @DiffRegDays = @RegularDays
                                          - sum(RegDays),
                         @DiffOTDays = @OvertimeDays
                                         - sum(OTDays)
                  FROM   @TU_Time
                  WHERE  TimeId = @TimeId
                  UPDATE @TU_Time
                  SET    RegHours = RegHours
                                      + @DiffRegHours,
                         OTHours = OTHours
                                     + @DiffOTHours,
                         RegDays = RegDays
                                     + @DiffRegDays,
                         OTDays = OTDays
                                    + @DiffOTDays
                  WHERE  SplitEngagementId = (SELECT   TOP 1 SplitEngagementId
                                              FROM     SplitBillingRule
                                              WHERE    MainEngagementId = @EngagementId
                                              ORDER BY Percentage DESC,
                                                       CustomerId)
                         AND TimeId = @TimeId
                  FETCH NEXT FROM UpdateCursor
                  INTO @TimeId,
                       @RegularHours,
                       @OvertimeHours,
                       @RegularDays,
                       @OvertimeDays
                END
              CLOSE UpdateCursor
              DEALLOCATE UpdateCursor
              INSERT INTO PreInvoicedTime
                         (CustomerId,
                          EngagementId,
                          ProjectId,
                          TimeId,
                          TimeDate,
                          RegularHours,
                          OvertimeHours,
                          TaskId,
                          GlobalWorkgroupId,
                          WorkgroupId,
                          ResourceId,
                          FixedFee,
                          InvoiceId,
                          InvoiceStatus,
                          BillingRate,
                          CostRate,
                          BillingCurrency,
                          CostCurrency,
                          RateDate,
                          WorkLocationGroupId,
                          WorkLocationId,
                          WorkCodeCategoryID,
                          WorkCodeId,
                          SplitEngagementId,
                          InvRegHours,
                          InvOTHours,
                          OTCostRate,
                          OTCostCurrency,
                          RegularDays,
                          OvertimeDays,
                          InvRegDays,
                          InvOTDays,
                          ConversionToDay,
                          [Description])
              SELECT tu.CustomerId,
                     tu.EngagementId,
                     tu.ProjectId,
                     tu.TimeId,
                     tm.TimeDate,
                     tm.RegularHours,
                     tm.OvertimeHours,
                     tu.TaskId,
                     tm.GlobalWorkgroupId,
                     tm.WorkgroupId,
                     tm.ResourceId,
                     tu.FixedFee,
                     NULL AS InvoiceId,
                     0 AS InvoiceStatus,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     tm.WorkLocationGroupid,
                     tm.WorkLocationId,
                     tm.WorkCodeCategoryid,
                     tm.WorkCodeid,
                     tu.SplitEngagementId,
                     tu.RegHours,
                     tu.OTHours,
                     NULL,
                     NULL,
                     tm.RegularDay,
                     tm.OvertimeDay,
                     tu.RegDays,
                     tu.OTDays,
                     tm.ConversionToDay,
                     REPLACE(REPLACE(tm.[Description], CHAR(13), ' '), CHAR(10), ' ')
              FROM   TIME tm WITH (NOLOCK)
                     INNER JOIN @TU_Time tu
                       ON tm.TimeId = tu.TimeId
            END
          ELSE
            BEGIN
              INSERT INTO @UpdatePreInvoicedTime
              SELECT t.CustomerId,
                     t.EngagementId,
                     i.ProjectId,
                     t.TimeId,
                     t.TimeDate,
                     t.RegularHours,
                     t.OvertimeHours,
                     ts.TaskId,
                     t.GlobalWorkgroupId,
                     t.WorkgroupId,
                     t.ResourceId,
                     ts.FixedFee,
                     NULL,
                     0,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     t.WorkLocationGroupId,
                     t.WorkLocationId,
                     t.WorkCodeCategoryId,
                     t.WorkCodeId,
                     t.EngagementId,
                     t.RegularHours,
                     t.OvertimeHours,
                     NULL,
                     NULL,
                     t.RegularDay,
                     t.OvertimeDay,
                     t.RegularDay,
                     t.OvertimeDay,
                     t.ConversionToDay,
                     REPLACE(REPLACE(t.[Description], CHAR(13), ' '), CHAR(10), ' ')
              FROM   @TRG_Inserted i
                     INNER JOIN TIME t WITH (NOLOCK)
                       ON i.ProjectId = t.ProjectId
                          AND isnull(t.ApprovalStatus,'') = 'A'
                          AND t.InvoiceStatus = 0
                          AND t.timeid IN (
                                           SELECT TIME.timeid
                                           FROM   TIME WITH (NOLOCK)
                                                  INNER JOIN taskhistory th1 WITH (NOLOCK)
                                                    ON TIME.projectid = th1.projectid
                                                       AND TIME.taskid = th1.taskid
                                                       AND th1.applieddate > TIME.timedate
                                                       AND th1.billable = 1
                                                       AND th1.taskhistoryid NOT IN (SELECT th2.taskhistoryid
                                                                                     FROM   taskhistory th3 WITH (NOLOCK),
                                                                                            taskhistory th2 WITH (NOLOCK)
                                                                                     WHERE  TIME.taskid = th3.taskid
                                                                                            AND TIME.projectid = th3.projectid
                                                                                            AND th3.applieddate > TIME.timedate
                                                                                            AND th3.projectid = th2.projectid
                                                                                            AND th3.taskid = th2.taskid
                                                                                            AND th2.applieddate >= TIME.timedate
                                                                                            AND th3.taskhistoryid <> th2.taskhistoryid
                                                                                            AND th3.applieddate < th2.applieddate)
                                           UNION 
                                           
                                           
                                           SELECT TIME.timeid
                                           FROM   TIME WITH (NOLOCK)
                                                  INNER JOIN Tasks WITH (NOLOCK)
                                                    ON TIME.taskid = Tasks.taskid
                                                       AND TIME.projectid = Tasks.projectid
                                                       AND Tasks.billable = 1
                                           WHERE  NOT EXISTS (SELECT TOP 1 1
                                                              FROM   taskhistory th WITH (NOLOCK)
                                                              WHERE  TIME.projectid = th.projectid
                                                                     AND TIME.taskid = th.taskid
                                                                     AND th.applieddate > TIME.timedate))
                     INNER JOIN Tasks ts WITH (NOLOCK)
                       ON i.ProjectId = ts.ProjectId
                          AND t.Taskid = ts.TaskId
              INSERT INTO PreInvoicedTime
                         (CustomerId,
                          EngagementId,
                          ProjectId,
                          TimeId,
                          TimeDate,
                          RegularHours,
                          OvertimeHours,
                          TaskId,
                          GlobalWorkgroupId,
                          WorkgroupId,
                          ResourceId,
                          FixedFee,
                          InvoiceId,
                          InvoiceStatus,
                          BillingRate,
                          CostRate,
                          BillingCurrency,
                          CostCurrency,
                          RateDate,
                          WorkLocationGroupId,
                          WorkLocationId,
                          WorkCodeCategoryID,
                          WorkCodeId,
                          SplitEngagementId,
                          InvRegHours,
                          InvOTHours,
                          OTCostRate,
                          OTCostCurrency,
                          RegularDays,
                          OvertimeDays,
                          InvRegDays,
                          InvOTDays,
                          ConversionToDay,
                          [Description])
              SELECT *
              FROM   @UpdatePreInvoicedTime
              UPDATE TIME
              SET    billable = 1, UpdatedOn = GETDATE()
              WHERE  timeid IN (SELECT DISTINCT timeid
                                FROM   @UpdatePreInvoicedTime)
                     AND billable <> 1
            END
        END
      ELSE
        IF (SELECT Billable
            FROM   @TRG_Deleted) = 1
           AND (SELECT Billable
                FROM   @TRG_Inserted) = 0
          BEGIN
            UPDATE TIME
            SET    billable = 0, UpdatedOn = GETDATE()
            WHERE  timeid IN (SELECT DISTINCT p.timeid
                              FROM   PreInvoicedTime p WITH (NOLOCK)
                                     INNER JOIN @TRG_Inserted i
                                       ON p.ProjectId = i.ProjectId)
                   AND billable <> 0
            DELETE PreInvoicedTime
            WHERE  ProjectId = (SELECT ProjectId
                                FROM   @TRG_Inserted)
            DELETE SplitBillExpense
            WHERE  ExpenseId IN (SELECT ExpenseId
                                 FROM   Expense e WITH (NOLOCK)
                                        INNER JOIN @TRG_Inserted i
                                          ON ISNULL(e.AltProjectId, e.ProjectId) = i.ProjectId)
          END
    END
  ELSE
    BEGIN
      DECLARE  @Project  TABLE(
                               ProjectId    UNIQUEIDENTIFIER   NOT NULL,
                               EngagementId UNIQUEIDENTIFIER   NOT NULL
                               )
      INSERT INTO @Project
      SELECT i.ProjectId,
             i.EngagementId
      FROM   @TRG_Inserted i
             INNER JOIN @TRG_Deleted d
               ON i.ProjectId = d.ProjectId
                  AND i.Billable = 1
                  AND d.Billable = 0
      IF (SELECT count(* )
          FROM   @Project) > 0
        BEGIN
		  
		  
          INSERT INTO SplitBillExpense
          SELECT s.SplitEngagementId,
                 e.ExpenseId
          FROM   @Project p
                 INNER JOIN Expense e WITH (NOLOCK)
                   ON p.ProjectId = ISNULL(e.AltProjectId, e.ProjectId)
                      AND e.Billable = 1
                      AND isnull(e.ApprovalStatus,'') = 'A'
                      AND e.InvoiceStatus = 0
                 INNER JOIN SplitBillingRule s WITH (NOLOCK)
                   ON p.EngagementId = s.MainEngagementId
                      AND s.Percentage > 0
          IF EXISTS (SELECT TOP 1 1
                     FROM   SplitBillingRule s WITH (NOLOCK)
                            INNER JOIN @Project p
                              ON s.MainEngagementId = p.EngagementId)
            BEGIN
              DECLARE  @TU_PrTime  TABLE(
                                         CustomerId        UNIQUEIDENTIFIER   NOT NULL,
                                         EngagementId      UNIQUEIDENTIFIER   NOT NULL,
                                         TaskId            UNIQUEIDENTIFIER   NOT NULL,
                                         FixedFee          BIT   DEFAULT 0   NOT NULL,
                                         ProjectId         UNIQUEIDENTIFIER   NOT NULL,
                                         TimeId            UNIQUEIDENTIFIER   NOT NULL,
                                         RegularHours      NUMERIC(10,3)   NOT NULL,
                                         OvertimeHours     NUMERIC(10,3)   NOT NULL,
                                         RegHours          NUMERIC(10,3)   NOT NULL,
                                         OTHours           NUMERIC(10,3)   NOT NULL,
                                         InvoiceStatus     BIT   DEFAULT 0   NOT NULL,
                                         SplitEngagementId UNIQUEIDENTIFIER   NOT NULL,
                                         RegularDays       NUMERIC(10,3)   NOT NULL,
                                         OvertimeDays      NUMERIC(10,3)   NOT NULL,
                                         RegDays           NUMERIC(10,3)   NOT NULL,
                                         OTDays            NUMERIC(10,3)   NOT NULL
                                         )
              INSERT INTO @TU_PrTime
              SELECT s.CustomerId,
                     s.MainEngagementId,
                     ts.TaskId,
                     ts.FixedFee,
                     i.ProjectId,
                     t.TimeId,
                     t.RegularHours,
                     t.OvertimeHours,
                     t.RegularHours
                       * s.Percentage
                       / 100,
                     t.OvertimeHours
                       * s.Percentage
                       / 100,
                     t.InvoiceStatus,
                     s.SplitEngagementId,
                     t.RegularDay,
                     t.OvertimeDay,
                     t.RegularDay
                       * s.Percentage
                       / 100,
                     t.OvertimeDay
                       * s.Percentage
                       / 100
              FROM   @Project i
                     INNER JOIN TIME t WITH (NOLOCK)
                       ON i.ProjectId = t.ProjectId
                          AND isnull(t.ApprovalStatus,'') = 'A'
                          AND t.InvoiceStatus = 0
                          AND t.TimeId IN (
                                           SELECT TIME.timeid
                                           FROM   TIME WITH (NOLOCK)
                                                  INNER JOIN taskhistory th1 WITH (NOLOCK)
                                                    ON TIME.projectid = th1.projectid
                                                       AND TIME.taskid = th1.taskid
                                                       AND th1.applieddate > TIME.timedate
                                                       AND th1.billable = 1
                                                       AND th1.taskhistoryid NOT IN (SELECT th2.taskhistoryid
                                                                                     FROM   taskhistory th3 WITH (NOLOCK),
                                                                                            taskhistory th2 WITH (NOLOCK)
                                                                                     WHERE  TIME.taskid = th3.taskid
                                                                                            AND TIME.projectid = th3.projectid
                                                                                            AND th3.applieddate > TIME.timedate
                                                                                            AND th3.projectid = th2.projectid
                                                                                            AND th3.taskid = th2.taskid
                                                                                            AND th2.applieddate >= TIME.timedate
                                                                                            AND th3.taskhistoryid <> th2.taskhistoryid
                                                                                            AND th3.applieddate < th2.applieddate)
                                           UNION 
                                           
                                           
                                           SELECT TIME.timeid
                                           FROM   TIME WITH (NOLOCK)
                                                  INNER JOIN Tasks WITH (NOLOCK)
                                                    ON TIME.projectid = Tasks.projectid
                                                       AND Tasks.billable = 1
                                                       AND TIME.taskid = Tasks.taskid
                                           WHERE  NOT EXISTS (SELECT TOP 1 1
                                                              FROM   taskhistory th WITH (NOLOCK)
                                                              WHERE  TIME.projectid = th.projectid
                                                                     AND TIME.taskid = th.taskid
                                                                     AND th.applieddate > TIME.timedate))
                     INNER JOIN Tasks ts WITH (NOLOCK)
                       ON i.ProjectId = ts.ProjectId
                          AND t.Taskid = ts.TaskId
                     INNER JOIN SplitBillingRule s WITH (NOLOCK)
                       ON ts.EngagementId = s.MainEngagementId
                          AND s.Percentage > 0
              UPDATE TIME
              SET    billable = 1, UpdatedOn = GETDATE()
              WHERE  timeid IN (SELECT DISTINCT timeid
                                FROM   @TU_PrTime)
                     AND billable <> 1
              DECLARE UpdateCursor CURSOR FAST_FORWARD FOR
              SELECT DISTINCT TimeId,
                              RegularHours,
                              OvertimeHours,
                              RegularDays,
                              OvertimeDays
              FROM   @TU_PrTime
              WHERE  InvoiceStatus = 0
              OPEN UpdateCursor
              FETCH NEXT FROM UpdateCursor
              INTO @TimeId,
                   @RegularHours,
                   @OvertimeHours,
                   @RegularDays,
                   @OvertimeDays
              WHILE @@FETCH_STATUS = 0
                BEGIN
                  SELECT @DiffRegHours = @RegularHours
                                           - sum(RegHours),
                         @DiffOTHours = @OvertimeHours
                                          - sum(OTHours),
                         @DiffRegDays = @RegularDays
                                          - sum(RegDays),
                         @DiffOTDays = @OvertimeDays
                                         - sum(OTDays)
                  FROM   @TU_PrTime
                  WHERE  TimeId = @TimeId
                  SET @EngagementId = (SELECT TOP 1 EngagementId
                                       FROM   @TU_PrTime
                                       WHERE  TimeId = @TimeId)
                  UPDATE @TU_PrTime
                  SET    RegHours = RegHours
                                      + @DiffRegHours,
                         OTHours = OTHours
                                     + @DiffOTHours,
                         RegDays = RegDays
                                     + @DiffRegDays,
                         OTDays = OTDays
                                    + @DiffOTDays
                  WHERE  SplitEngagementId = (SELECT   TOP 1 SplitEngagementId
                                              FROM     SplitBillingRule WITH (NOLOCK)
                                              WHERE    MainEngagementId = @EngagementId
                                              ORDER BY Percentage DESC,
                                                       CustomerId)
                         AND TimeId = @TimeId
                  FETCH NEXT FROM UpdateCursor
                  INTO @TimeId,
                       @RegularHours,
                       @OvertimeHours,
                       @RegularDays,
                       @OvertimeDays
                END
              CLOSE UpdateCursor
              DEALLOCATE UpdateCursor
              INSERT INTO PreInvoicedTime
                         (CustomerId,
                          EngagementId,
                          ProjectId,
                          TimeId,
                          TimeDate,
                          RegularHours,
                          OvertimeHours,
                          TaskId,
                          GlobalWorkgroupId,
                          WorkgroupId,
                          ResourceId,
                          FixedFee,
                          InvoiceId,
                          InvoiceStatus,
                          BillingRate,
                          CostRate,
                          BillingCurrency,
                          CostCurrency,
                          RateDate,
                          WorkLocationGroupId,
                          WorkLocationId,
                          WorkCodeCategoryID,
                          WorkCodeId,
                          SplitEngagementId,
                          InvRegHours,
                          InvOTHours,
                          OTCostRate,
                          OTCostCurrency,
                          RegularDays,
                          OvertimeDays,
                          InvRegDays,
                          InvOTDays,
                          ConversionToDay,
                          [Description])
              SELECT tu.CustomerId,
                     tu.EngagementId,
                     tu.ProjectId,
                     tu.TimeId,
                     tm.TimeDate,
                     tm.RegularHours,
                     tm.OvertimeHours,
                     tu.TaskId,
                     tm.GlobalWorkgroupId,
                     tm.WorkgroupId,
                     tm.ResourceId,
                     tu.FixedFee,
                     NULL AS InvoiceId,
                     0 AS InvoiceStatus,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     tm.WorkLocationGroupid,
                     tm.WorkLocationId,
                     tm.WorkCodeCategoryid,
                     tm.WorkCodeid,
                     tu.SplitEngagementId,
                     tu.RegHours,
                     tu.OTHours,
                     NULL,
                     NULL,
                     tm.RegularDay,
                     tm.OvertimeDay,
                     tu.RegDays,
                     tu.OTDays,
                     tm.ConversionToDay,
                     REPLACE(REPLACE(tm.[Description], CHAR(13), ' '), CHAR(10), ' ')
              FROM   TIME tm WITH (NOLOCK)
                     INNER JOIN @TU_PrTime tu
                       ON tm.TimeId = tu.TimeId
            END
          ELSE
            BEGIN
              INSERT INTO @UpdatePreInvoicedTime
              SELECT t.CustomerId,
                     t.EngagementId,
                     i.ProjectId,
                     t.TimeId,
                     t.TimeDate,
                     t.RegularHours,
                     t.OvertimeHours,
                     ts.TaskId,
                     t.GlobalWorkgroupId,
                     t.WorkgroupId,
                     t.ResourceId,
                     ts.FixedFee,
                     NULL,
                     0,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     t.WorkLocationGroupId,
                     t.WorkLocationId,
                     t.WorkCodeCategoryId,
                     t.WorkCodeId,
                     t.EngagementId,
                     t.RegularHours,
                     t.OvertimeHours,
                     NULL,
                     NULL,
                     t.RegularDay,
                     t.OvertimeDay,
                     t.RegularDay,
                     t.OvertimeDay,
                     t.ConversionToDay,
                     REPLACE(REPLACE(t.[Description], CHAR(13), ' '), CHAR(10), ' ')
              FROM   @Project i
                     INNER JOIN TIME t WITH (NOLOCK)
                       ON isnull(t.ApprovalStatus,'') = 'A'
                          AND t.InvoiceStatus = 0
                          AND t.timeid IN (
                                           SELECT TIME.timeid
                                           FROM   TIME WITH (NOLOCK)
                                                  INNER JOIN taskhistory th1 WITH (NOLOCK)
                                                    ON TIME.projectid = th1.projectid
                                                       AND TIME.taskid = th1.taskid
                                                       AND th1.applieddate > TIME.timedate
                                                       AND th1.billable = 1
                                                       AND th1.taskhistoryid NOT IN (SELECT th2.taskhistoryid
                                                                                     FROM   taskhistory th3 WITH (NOLOCK),
                                                                                            taskhistory th2 WITH (NOLOCK)
                                                                                     WHERE  TIME.taskid = th3.taskid
                                                                                            AND TIME.projectid = th3.projectid
                                                                                            AND th3.applieddate > TIME.timedate
                                                                                            AND th3.projectid = th2.projectid
                                                                                            AND th3.taskid = th2.taskid
                                                                                            AND th2.applieddate >= TIME.timedate
                                                                                            AND th3.taskhistoryid <> th2.taskhistoryid
                                                                                            AND th3.applieddate < th2.applieddate)
                                           UNION 
                                           
                                           
                                           SELECT TIME.timeid
                                           FROM   TIME WITH (NOLOCK)
                                                  INNER JOIN Tasks WITH (NOLOCK)
                                                    ON TIME.taskid = Tasks.taskid
                                                       AND TIME.projectid = Tasks.projectid
                                                       AND Tasks.billable = 1
                                           WHERE  NOT EXISTS (SELECT TOP 1 1
                                                              FROM   taskhistory th WITH (NOLOCK)
                                                              WHERE  TIME.projectid = th.projectid
                                                                     AND TIME.taskid = th.taskid
                                                                     AND th.applieddate > TIME.timedate))
                     INNER JOIN Tasks ts WITH (NOLOCK)
                       ON i.ProjectId = ts.ProjectId
                          AND t.Taskid = ts.TaskId
              INSERT INTO PreInvoicedTime
                         (CustomerId,
                          EngagementId,
                          ProjectId,
                          TimeId,
                          TimeDate,
                          RegularHours,
                          OvertimeHours,
                          TaskId,
                          GlobalWorkgroupId,
                          WorkgroupId,
                          ResourceId,
                          FixedFee,
                          InvoiceId,
                          InvoiceStatus,
                          BillingRate,
                          CostRate,
                          BillingCurrency,
                          CostCurrency,
                          RateDate,
                          WorkLocationGroupId,
                          WorkLocationId,
                          WorkCodeCategoryID,
                          WorkCodeId,
                          SplitEngagementId,
                          InvRegHours,
                          InvOTHours,
                          OTCostRate,
                          OTCostCurrency,
                          RegularDays,
                          OvertimeDays,
                          InvRegDays,
                          InvOTDays,
                          ConversionToDay,
                          [Description])
              SELECT *
              FROM   @UpdatePreInvoicedTime
              UPDATE TIME
              SET    billable = 1, UpdatedOn = GETDATE()
              WHERE  timeid IN (SELECT DISTINCT timeid
                                FROM   @UpdatePreInvoicedTime)
                     AND billable <> 1
              DELETE @UpdatePreInvoicedTime
            END
          DELETE @Project
        END
      INSERT INTO @Project
      SELECT i.ProjectId,
             i.EngagementId
      FROM   @TRG_Inserted i
             INNER JOIN @TRG_Deleted d
               ON i.ProjectId = d.ProjectId
                  AND i.Billable = 0
                  AND d.Billable = 1
      IF (SELECT count(* )
          FROM   @Project) > 0
        BEGIN
          UPDATE TIME
          SET    billable = 0, UpdatedOn = GETDATE()
          WHERE  billable <> 0
                 AND timeid IN (SELECT DISTINCT timeid
                                FROM   PreInvoicedTime p WITH (NOLOCK)
                                       INNER JOIN @Project i
                                         ON p.ProjectId = i.ProjectId)
          DELETE PreInvoicedTime
          WHERE  ProjectId IN (SELECT ProjectId
                               FROM   @Project)
          DELETE SplitBillExpense
          WHERE  ExpenseId IN (SELECT ExpenseId
                               FROM   Expense e WITH (NOLOCK)
                                      INNER JOIN @Project p
                                        ON ISNULL(e.AltProjectId, e.ProjectId) = p.ProjectId)
        END
    END
  SET NOCOUNT  OFF

GO
