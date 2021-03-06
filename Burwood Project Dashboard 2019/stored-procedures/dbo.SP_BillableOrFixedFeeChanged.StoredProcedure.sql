USE [Changepoint]
GO
/****** Object:  StoredProcedure [dbo].[SP_BillableOrFixedFeeChanged]    Script Date: 10/10/2019 2:41:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_BillableOrFixedFeeChanged]
AS
 BEGIN
  DECLARE  @FixedFee      BIT,
           @TaskId        UNIQUEIDENTIFIER,
           @Billable      BIT,
           @Split         BIT,
           @TimeId         AS UNIQUEIDENTIFIER,
           @RegularHours   AS NUMERIC(10,3),
           @OvertimeHours  AS NUMERIC(10,3),
           @DiffRegHours   AS NUMERIC(10,3),
           @DiffOTHours    AS NUMERIC(10,3),
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
                                         regularDays         NUMERIC(10,3),
                                         overtimeDays        NUMERIC(10,3),
                                         invregDays          NUMERIC(10,3),
                                         invotDays           NUMERIC(10,3),
                                         ConversionToDay	 NUMERIC(5,3),
										 [Description]		 NVARCHAR(MAX)
                                         )
  DECLARE  @Tlist  TABLE(
                         TimeId UNIQUEIDENTIFIER   NOT NULL
                         )
  IF (SELECT Count(* )
      FROM   #Inserted) = 1
   BEGIN
    IF (SELECT IsNULL(Billable,0)
        FROM   #Deleted) <> (SELECT IsNULL(t.Billable,0)
                             FROM   Tasks t
                                    INNER JOIN #Inserted i
                                      ON t.TaskId = i.Taskid)
       AND (SELECT p.Billable
            FROM   #Inserted i
                   JOIN Project p WITH (NOLOCK)
                     ON i.ProjectId = p.ProjectId) = 1
       AND (SELECT e.Billable
            FROM   #Inserted i
                   JOIN Engagement e WITH (NOLOCK)
                     ON i.EngagementId = e.EngagementId) = 1
     BEGIN
      SELECT @TaskId = i.TaskId,
             @Billable = i.Billable,
             @FixedFee = i.FixedFee,
             @Split = e.SplitBilling,
             @EngagementId = e.EngagementId
      FROM   #Inserted i
             JOIN Engagement e WITH (NOLOCK)
               ON i.EngagementId = e.EngagementId
      IF @Billable = 1
         AND (SELECT count(* )
              FROM   TaskHistory WITH (NOLOCK)
              WHERE  TaskId = @TaskId) = 0
       BEGIN
        IF @Split = 0
         BEGIN
          INSERT INTO @Tlist
          SELECT TimeId
          FROM   PreInvoicedTime WITH (NOLOCK)
          WHERE  TaskId = @TaskId
          
          INSERT INTO @UpdatePreInvoicedTime
                     (customerid,
                      engagementid,
                      projectid,
                      timeid,
                      timedate,
                      regularhours,
                      overtimehours,
                      taskid,
                      globalworkgroupid,
                      workgroupid,
                      resourceid,
                      fixedfee,
                      invoiceid,
                      invoicestatus,
                      billingrate,
                      costrate,
                      billingcurrency,
                      costcurrency,
                      ratedate,
                      worklocationgroupid,
                      worklocationid,
                      workcodecategoryid,
                      workcodeid,
                      splitengagementid,
                      invreghours,
                      invothours,
                      otcostrate,
                      otcostcurrency,
                      regularDays,
                      overtimeDays,
                      invregDays,
                      invotDays,
                      conversiontoday,
                      [description])
          
          SELECT tm.CustomerId,
                 tm.EngagementId,
                 tm.ProjectId,
                 tm.TimeId,
                 tm.TimeDate,
                 tm.RegularHours,
                 tm.OvertimeHours,
                 tm.TaskId,
                 tm.GlobalWorkgroupId,
                 tm.WorkgroupId,
                 tm.ResourceId,
                 i.FixedFee,
                 NULL AS InvoiceId,
                 0 AS InvoiceStatus,
                 CASE 
                   WHEN i.FixedFee = CAST(1 AS BIT)
                   THEN NULL
                   ELSE tm.BillingRate
                 END,
                 tm.CostRate,
                 tm.BillingCurrency,
                 tm.CostCurrency,
                 tm.RateDate,
                 tm.WorkLocationGroupId,
                 tm.WorkLocationId,
                 tm.WorkCodeCategoryId,
                 tm.WorkCodeId,
                 tm.EngagementId,
                 tm.RegularHours,
                 tm.OvertimeHours,
                 tm.OTCostRate,
                 tm.OTCostCurrency,
                 tm.regularDay,
                 tm.overtimeDay,
                 tm.regularDay,
                 tm.overtimeDay,
                 tm.ConversionToDay,
                 tm.[Description]
          FROM   #Inserted i,
                 TIME tm WITH (NOLOCK)
          WHERE  i.TaskId = tm.TaskId
                 AND isnull(tm.ApprovalStatus,'') = 'A'
                 AND tm.InvoiceStatus = 0
          
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
          SELECT customerid,
                 engagementid,
                 projectid,
                 timeid,
                 timedate,
                 regularhours,
                 overtimehours,
                 taskid,
                 globalworkgroupid,
                 workgroupid,
                 resourceid,
                 fixedfee,
                 invoiceid,
                 invoicestatus,
                 billingrate,
                 costrate,
                 billingcurrency,
                 costcurrency,
                 ratedate,
                 worklocationgroupid,
                 worklocationid,
                 workcodecategoryid,
                 workcodeid,
                 splitengagementid,
                 invreghours,
                 invothours,
                 otcostrate,
                 otcostcurrency,
                 regularDays,
                 overtimeDays,
                 invregDays,
                 invotDays,
                 ConversionToDay,
                 REPLACE(REPLACE([Description], CHAR(13), ' '), CHAR(10), ' ')
          FROM   @UpdatePreInvoicedTime
          WHERE  TimeId NOT IN (SELECT TimeId
                                FROM   @Tlist)
          
          UPDATE TIME
          SET    billable = 1, UpdatedOn = GETDATE()
          WHERE  timeid IN (SELECT DISTINCT timeid
                            FROM   @updatePreInvoicedTime)
                 AND billable <> 1
         END
        ELSE
          BEGIN
           SET @TimeId = NULL
           SET @RegularHours = 0
           SET @OvertimeHours = 0
           SET @DiffRegHours = 0
           SET @DiffOTHours = 0
           SET @RegularDays = 0
           SET @OvertimeDays = 0
           SET @DiffRegDays = 0
           SET @DiffOTDays = 0
           
           DELETE PreInvoicedTime
           WHERE  TaskId = @TaskId
           
           INSERT INTO @UpdatePreInvoicedTime
                      (customerid,
                       engagementid,
                       projectid,
                       timeid,
                       timedate,
                       regularhours,
                       overtimehours,
                       taskid,
                       globalworkgroupid,
                       workgroupid,
                       resourceid,
                       fixedfee,
                       invoiceid,
                       invoicestatus,
                       billingrate,
                       costrate,
                       billingcurrency,
                       costcurrency,
                       ratedate,
                       worklocationgroupid,
                       worklocationid,
                       workcodecategoryid,
                       workcodeid,
                       splitengagementid,
                       invreghours,
                       invothours,
                       otcostrate,
                       otcostcurrency,
                       regularDays,
                       overtimeDays,
                       invregDays,
                       invotDays,
                       ConversionToDay,
                       [Description])
           
           SELECT s.CustomerId,
                  s.MainEngagementId,
                  tm.ProjectId,
                  tm.TimeId,
                  tm.TimeDate,
                  tm.RegularHours,
                  tm.OvertimeHours,
                  tm.TaskId,
                  tm.GlobalWorkgroupId,
                  tm.WorkgroupId,
                  tm.ResourceId,
                  i.FixedFee,
                  NULL AS InvoiceId,
                  0 AS InvoiceStatus,
                  CASE 
                    WHEN i.FixedFee = CAST(1 AS BIT)
                    THEN NULL
                    ELSE tm.BillingRate
                  END,
                  tm.CostRate,
                  tm.BillingCurrency,
                  tm.CostCurrency,
                  tm.RateDate,
                  tm.WorkLocationGroupId,
                  tm.WorkLocationId,
                  tm.WorkCodeCategoryId,
                  tm.WorkCodeId,
                  s.SplitEngagementId,
                  tm.RegularHours * ISNULL(sp.Percentage, s.Percentage) / 100,
                  tm.OvertimeHours * ISNULL(sp.Percentage, s.Percentage) / 100,
                  tm.OTCostRate,
                  tm.OTCostCurrency,
                  tm.regularDay,
                  tm.overtimeDay,
                  tm.regularDay * ISNULL(sp.Percentage, s.Percentage) / 100,
                  tm.overtimeDay * ISNULL(sp.Percentage, s.Percentage) / 100,
                  tm.ConversionToDay,
                  tm.[Description]
           FROM   #Inserted i
                  INNER JOIN [Time] tm WITH (NOLOCK)
					ON i.TaskId = tm.TaskId
						AND isnull(tm.ApprovalStatus,'') = 'A'
						AND tm.InvoiceStatus = 0
                  INNER JOIN SplitBillingRule s WITH (NOLOCK)
					ON i.EngagementId = s.MainEngagementId
				  LEFT OUTER JOIN SplitBillProjectOverride sp
					ON sp.ProjectId = tm.ProjectId
				  WHERE ISNULL(sp.SplitEngagementId, s.SplitEngagementId) = s.SplitEngagementId
					AND ISNULL(sp.Percentage, s.Percentage) > 0
            
                  
           
           UPDATE TIME
           SET    billable = 1, UpdatedOn = GETDATE()
           WHERE  timeid IN (SELECT DISTINCT timeid
                             FROM   @updatePreInvoicedTime)
                  AND billable <> 1
           DECLARE UpdateCursor CURSOR FAST_FORWARD FOR
           SELECT DISTINCT TimeId,
                           RegularHours,
                           OvertimeHours,
                           regularDays,
                           overtimeDays
           FROM   @UpdatePreInvoicedTime
           OPEN UpdateCursor
           FETCH NEXT FROM UpdateCursor
           INTO @TimeId,
                @RegularHours,
                @OvertimeHours,
                @RegularDays,
                @OvertimeDays
           WHILE @@FETCH_STATUS = 0
            BEGIN
             SELECT @DiffRegHours = @RegularHours - sum(InvRegHours),
                    @DiffOTHours = @OvertimeHours - sum(InvOTHours),
                    @DiffRegDays = @RegularDays - SUM(invregDays),
                    @DiffOTDays = @OvertimeDays - SUM(invotDays)
             FROM   @UpdatePreInvoicedTime
             WHERE  TimeId = @TimeId
             UPDATE @UpdatePreInvoicedTime
             SET    InvRegHours = InvRegHours + @DiffRegHours,
                    InvOTHours = InvOTHours + @DiffOTHours,
                    invregDays = invregDays + @DiffRegDays,
                    invotDays = invotDays + @DiffOTDays
             WHERE  SplitEngagementId = (SELECT   TOP 1 s.SplitEngagementId
										 FROM     SplitBillingRule s WITH (NOLOCK)
										 LEFT OUTER JOIN SplitBillProjectOverride sp WITH (NOLOCK)
											ON ISNULL(sp.SplitEngagementId, s.SplitEngagementId) = s.SplitEngagementId
										 WHERE    MainEngagementId = @EngagementId
										 ORDER BY isnull(sp.Percentage, 0) DESC, s.Percentage DESC, CustomerId)
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
           SELECT customerid,
                  engagementid,
                  projectid,
                  timeid,
                  timedate,
                  regularhours,
                  overtimehours,
                  taskid,
                  globalworkgroupid,
                  workgroupid,
                  resourceid,
                  fixedfee,
                  invoiceid,
                  invoicestatus,
                  billingrate,
                  costrate,
                  billingcurrency,
                  costcurrency,
                  ratedate,
                  worklocationgroupid,
                  worklocationid,
                  workcodecategoryid,
                  workcodeid,
                  splitengagementid,
                  invreghours,
                  invothours,
                  otcostrate,
                  otcostcurrency,
                  regularDays,
                  overtimeDays,
                  invregDays,
                  invotDays,
                  ConversionToDay,
                  REPLACE(REPLACE([Description], CHAR(13), ' '), CHAR(10), ' ')
           FROM   @UpdatePreInvoicedTime
          END
       END
      IF @Billable = 0
         AND (SELECT count(* )
              FROM   TaskHistory WITH (NOLOCK)
              WHERE  TaskId = @TaskId) = 0
       BEGIN
        DELETE PreInvoicedTime
        WHERE  TaskId = @TaskId
               AND InvoiceId IS NULL
        
        UPDATE TIME
        SET    billable = 0, UpdatedOn = GETDATE()
        WHERE  TaskId = @TaskId
               AND InvoiceStatus = 0
               AND billable <> 0
       END
     END
    IF (SELECT IsNULL(FixedFee,0)
        FROM   #Deleted) <> (SELECT IsNULL(t.FixedFee,0)
                             FROM   Tasks t WITH (NOLOCK)
                                    INNER JOIN #Inserted i
                                      ON t.TaskId = i.TasKid)
     BEGIN
      SELECT @TaskId = TaskId,
             @FixedFee = FixedFee
      FROM   #Inserted
      
      
      UPDATE PreInvoicedTime
      SET    FixedFee = @FixedFee,
             BillingRate = NULL,
             RateDate = NULL
      WHERE  TaskId = @TaskId AND InvoiceId IS NULL AND InvoiceStatus = 0
     END
   END
  
  IF (SELECT Count(* )
      FROM   #Inserted) > 1
   BEGIN
    DECLARE  @tids  TABLE(
                          TaskId UNIQUEIDENTIFIER   NOT NULL
                          )
    INSERT INTO @tids
    SELECT DISTINCT i.TaskId
    FROM   #Inserted i
           INNER JOIN Tasks t
             ON i.TaskId = t.TaskId
    WHILE (SELECT Count(* )
           FROM   @tids) > 0
     BEGIN
      SET @TaskId = (SELECT TOP 1 TaskId
                     FROM   @tids)
      IF (SELECT IsNULL(Billable,0)
          FROM   #Deleted
          WHERE  TaskId = @TaskId) <> (SELECT IsNULL(Billable,0)
                                       FROM   Tasks t
                                       WHERE  TaskId = @TaskId)
         AND (SELECT isnull(p.Billable,0)
              FROM   Tasks i WITH (NOLOCK)
                     JOIN Project p WITH (NOLOCK)
                       ON i.ProjectId = p.ProjectId
                          AND i.TaskId = @TaskId) = 1
         AND (SELECT e.Billable
              FROM   Tasks i WITH (NOLOCK)
                     JOIN Engagement e WITH (NOLOCK)
                       ON i.EngagementId = e.EngagementId
                          AND i.TaskId = @TaskId) = 1
       BEGIN
        DELETE @UpdatePreInvoicedTime
        SELECT @Billable = i.Billable,
               @FixedFee = i.FixedFee,
               @Split = e.SplitBilling,
               @EngagementId = e.EngagementId
        FROM   Tasks i WITH (NOLOCK)
               JOIN Engagement e WITH (NOLOCK)
                 ON i.EngagementId = e.EngagementId
                    AND i.TaskId = @TaskId
        IF @Billable = 1
           AND (SELECT count(* )
                FROM   TaskHistory WITH (NOLOCK)
                WHERE  TaskId = @TaskId) = 0
         BEGIN
          IF @Split = 0
           BEGIN
            INSERT INTO @Tlist
            SELECT TimeId
            FROM   PreInvoicedTime WITH (NOLOCK)
            WHERE  TaskId = @TaskId
            
            INSERT INTO @UpdatePreInvoicedTime
                       (customerid,
                        engagementid,
                        projectid,
                        timeid,
                        timedate,
                        regularhours,
                        overtimehours,
                        taskid,
                        globalworkgroupid,
                        workgroupid,
                        resourceid,
                        fixedfee,
                        invoiceid,
                        invoicestatus,
                        billingrate,
                        costrate,
                        billingcurrency,
                        costcurrency,
                        ratedate,
                        worklocationgroupid,
                        worklocationid,
                        workcodecategoryid,
                        workcodeid,
                        splitengagementid,
                        invreghours,
                        invothours,
                        otcostrate,
                        otcostcurrency,
                        regularDays,
                        overtimeDays,
                        invregDays,
                        invotDays,
                        ConversionToDay,
                        [Description])
            
            SELECT tm.CustomerId,
                   tm.EngagementId,
                   tm.ProjectId,
                   tm.TimeId,
                   tm.TimeDate,
                   tm.RegularHours,
                   tm.OvertimeHours,
                   tm.TaskId,
                   tm.GlobalWorkgroupId,
                   tm.WorkgroupId,
                   tm.ResourceId,
                   i.FixedFee,
                   NULL AS InvoiceId,
                   0 AS InvoiceStatus,
                   tm.BillingRate,
                   tm.CostRate,
                   tm.BillingCurrency,
                   tm.CostCurrency,
                   tm.RateDate,
                   tm.WorkLocationGroupId,
                   tm.WorkLocationId,
                   tm.WorkCodeCategoryId,
                   tm.WorkCodeId,
                   tm.EngagementId,
                   tm.RegularHours,
                   tm.OvertimeHours,
                   tm.OTCostRate,
                   tm.OTCostCurrency,
                   tm.regularDay,
                   tm.overtimeDay,
                   tm.regularDay,
                   tm.overtimeDay,
                   tm.ConversionToDay,
                   tm.[Description]
            FROM   Tasks i WITH (NOLOCK),
                   TIME tm WITH (NOLOCK)
            WHERE  i.TaskId = @TaskId
                   AND i.TaskId = tm.TaskId
                   AND isnull(tm.ApprovalStatus,'') = 'A'
                   AND tm.InvoiceStatus = 0
            
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
            SELECT customerid,
                   engagementid,
                   projectid,
                   timeid,
                   timedate,
                   regularhours,
                   overtimehours,
                   taskid,
                   globalworkgroupid,
                   workgroupid,
                   resourceid,
                   fixedfee,
                   invoiceid,
                   invoicestatus,
                   billingrate,
                   costrate,
                   billingcurrency,
                   costcurrency,
                   ratedate,
                   worklocationgroupid,
                   worklocationid,
                   workcodecategoryid,
                   workcodeid,
                   splitengagementid,
                   invreghours,
                   invothours,
                   otcostrate,
                   otcostcurrency,
                   regularDays,
                   overtimeDays,
                   invregDays,
                   invotDays,
                   ConversionToDay,
                   REPLACE(REPLACE([Description], CHAR(13), ' '), CHAR(10), ' ')
            FROM   @UpdatePreInvoicedTime
            WHERE  TimeId NOT IN (SELECT TimeId
                                  FROM   @Tlist)
            
            UPDATE TIME
            SET    billable = 1, UpdatedOn = GETDATE()
            WHERE  timeid IN (SELECT DISTINCT timeid
                              FROM   @updatePreInvoicedTime)
                   AND billable <> 1
           END
          ELSE
            BEGIN
             SET @TimeId = NULL
             SET @RegularHours = 0
             SET @OvertimeHours = 0
             SET @DiffRegHours = 0
             SET @DiffOTHours = 0
             SET @RegularDays = 0
             SET @OvertimeDays = 0
             SET @DiffRegDays = 0
             SET @DiffOTDays = 0
             DELETE PreInvoicedTime
             WHERE  TaskId = @TaskId
             
             INSERT INTO @UpdatePreInvoicedTime
                        (customerid,
                         engagementid,
                         projectid,
                         timeid,
                         timedate,
                         regularhours,
                         overtimehours,
                         taskid,
                         globalworkgroupid,
                         workgroupid,
                         resourceid,
                         fixedfee,
                         invoiceid,
                         invoicestatus,
                         billingrate,
                         costrate,
                         billingcurrency,
                         costcurrency,
                         ratedate,
                         worklocationgroupid,
                         worklocationid,
                         workcodecategoryid,
                         workcodeid,
                         splitengagementid,
                         invreghours,
                         invothours,
                         otcostrate,
                         otcostcurrency,
                         regularDays,
                         overtimeDays,
                         invregDays,
                         invotDays,
                         ConversionToDay,
                         [Description])
             
             SELECT s.CustomerId,
                    s.MainEngagementId,
                    tm.ProjectId,
                    tm.TimeId,
                    tm.TimeDate,
                    tm.RegularHours,
                    tm.OvertimeHours,
                    tm.TaskId,
                    tm.GlobalWorkgroupId,
                    tm.WorkgroupId,
                    tm.ResourceId,
                    i.FixedFee,
                    NULL AS InvoiceId,
                    0 AS InvoiceStatus,
                    tm.BillingRate,
                    tm.CostRate,
                    tm.BillingCurrency,
                    tm.CostCurrency,
                    tm.RateDate,
                    tm.WorkLocationGroupId,
                    tm.WorkLocationId,
                    tm.WorkCodeCategoryId,
                    tm.WorkCodeId,
                    s.SplitEngagementId,
                    tm.RegularHours * ISNULL(sp.Percentage, s.Percentage) / 100,
                    tm.OvertimeHours * ISNULL(sp.Percentage, s.Percentage) / 100,
                    tm.OTCostRate,
                    tm.OTCostCurrency,
                    tm.regularDay,
                    tm.overtimeDay,
                    tm.regularDay * ISNULL(sp.Percentage, s.Percentage) / 100,
                    tm.overtimeDay * ISNULL(sp.Percentage, s.Percentage) / 100,
                    tm.ConversionToDay,
                    tm.[Description]
             FROM   Tasks i WITH (NOLOCK)
                    INNER JOIN TIME tm WITH (NOLOCK) ON i.TaskId = tm.TaskId
                    INNER JOIN SplitBillingRule s WITH (NOLOCK) ON i.EngagementId = s.MainEngagementId
                    LEFT OUTER JOIN SplitBillProjectOverride sp ON sp.ProjectId = tm.ProjectId
             WHERE  i.TaskId = @TaskId
                    AND isnull(tm.ApprovalStatus,'') = 'A'
                    AND tm.InvoiceStatus = 0
                    AND ISNULL(sp.SplitEngagementId, s.SplitEngagementId) = s.SplitEngagementId
					AND ISNULL(sp.Percentage, s.Percentage) > 0
             
             UPDATE TIME
             SET    billable = 1, UpdatedOn = GETDATE()
             WHERE  timeid IN (SELECT DISTINCT timeid
                               FROM   @updatePreInvoicedTime)
                    AND billable <> 1
             DECLARE UpdateCursor CURSOR FAST_FORWARD FOR
             SELECT DISTINCT TimeId,
                             RegularHours,
                             OvertimeHours,
                             RegularDays,
                             OvertimeDays
             FROM   @UpdatePreInvoicedTime
             OPEN UpdateCursor
             FETCH NEXT FROM UpdateCursor
             INTO @TimeId,
                  @RegularHours,
                  @OvertimeHours,
                  @RegularDays,
                  @OvertimeDays
             WHILE @@FETCH_STATUS = 0
              BEGIN
               SELECT @DiffRegHours = @RegularHours - sum(InvRegHours),
                      @DiffOTHours = @OvertimeHours - sum(InvOTHours),
                      @DiffRegDays = @RegularDays - sum(InvRegDays),
                      @DiffOTDays = @OvertimeDays - sum(InvOTDays)
               FROM   @UpdatePreInvoicedTime
               WHERE  TimeId = @TimeId
               UPDATE @UpdatePreInvoicedTime
               SET    InvRegHours = InvRegHours + @DiffRegHours,
                      InvOTHours = InvOTHours + @DiffOTHours,
                      InvRegDays = InvRegDays + @DiffRegDays,
                      InvOTDays = InvOTDays + @DiffOTDays
               WHERE  SplitEngagementId = (SELECT   TOP 1 s.SplitEngagementId
										   FROM     SplitBillingRule s WITH (NOLOCK)
										   LEFT OUTER JOIN SplitBillProjectOverride sp WITH (NOLOCK)
											  ON ISNULL(sp.SplitEngagementId, s.SplitEngagementId) = s.SplitEngagementId
										   WHERE    MainEngagementId = @EngagementId
										   ORDER BY isnull(sp.Percentage, 0) DESC, s.Percentage DESC, CustomerId)
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
             SELECT customerid,
                    engagementid,
                    projectid,
                    timeid,
                    timedate,
                    regularhours,
                    overtimehours,
                    taskid,
                    globalworkgroupid,
                    workgroupid,
                    resourceid,
                    fixedfee,
                    invoiceid,
                    invoicestatus,
                    billingrate,
                    costrate,
                    billingcurrency,
                    costcurrency,
                    ratedate,
                    worklocationgroupid,
                    worklocationid,
                    workcodecategoryid,
                    workcodeid,
                    splitengagementid,
                    invreghours,
                    invothours,
                    otcostrate,
                    otcostcurrency,
                    regularDays,
                    overtimeDays,
                    invregDays,
                    invotDays,
                    ConversionToDay,
                    REPLACE(REPLACE([Description], CHAR(13), ' '), CHAR(10), ' ')
             FROM   @UpdatePreInvoicedTime
            END
         END
        IF @Billable = 0
           AND (SELECT count(* )
                FROM   TaskHistory WITH (NOLOCK)
                WHERE  TaskId = @TaskId) = 0
         BEGIN
          DELETE PreInvoicedTime
          WHERE  TaskId = @TaskId
                 AND InvoiceId IS NULL
          
          UPDATE TIME
          SET    billable = 0, UpdatedOn = GETDATE()
          WHERE  TaskId = @TaskId
                 AND InvoiceStatus = 0
                 AND billable <> 0
         END
       END
      IF (SELECT IsNULL(FixedFee,0)
          FROM   #Deleted
          WHERE  TaskId = @TaskId) <> (SELECT IsNULL(FixedFee,0)
                                       FROM   Tasks
                                       WHERE  TaskId = @TaskId)
       BEGIN
        SELECT @FixedFee = FixedFee
        FROM   Tasks WITH (NOLOCK)
        WHERE  TaskId = @TaskId
		
        UPDATE PreInvoicedTime
        SET    FixedFee = @FixedFee,
               BillingRate = NULL,
               RateDate = NULL
        WHERE  TaskId = @TaskId AND InvoiceId IS NULL AND InvoiceStatus = 0
       END
      
      DELETE @tids
      WHERE  TaskId = @TaskId
     END
   END
 END

GO
