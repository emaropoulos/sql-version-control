USE [Changepoint]
GO
/****** Object:  View [dbo].[PBI_ResourcesByWorkgroup]    Script Date: 2/11/2020 4:26:58 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE VIEW [dbo].[PBI_ResourcesByWorkgroup]
AS
-- Add resources that are assigned directly to a workgroup  
SELECT IIF(r.employeetype = 'CO', 'Contractor', 'Burwood Employee')      AS ResourceType, 
       w.workgroupid, 
       w.NAME                                                            AS Workgroup, 
       NULL                                                              AS ChildWorkgroup, 
       r.NAME                                                            AS ResourceName, 
       r.employeetype, 
       r.resourceid, 
       whm.effectivedate                                                 AS HireDate, 
       ISNULL(whm.enddate, '2099-12-31')                                 AS TerminationDate, 
       rp.annualtargethours, 
       rr.rate1                                                          AS LoadedAnnualSalary, 
       IIF(ISNULL(r.terminationdate, '2099-12-31') = '2099-12-31', 0, 1) AS Terminated, 
       r.NAME 
       + Cast(whm.HistoryID AS VARCHAR(36))                              AS WorkgroupResourceId, 
       ra.emailaddress                                                   AS WorkgroupOwnerEmail 
FROM   workgroup w WITH (nolock) 
       LEFT OUTER JOIN workgrouphistorymember whm WITH (nolock) 
                    ON w.workgroupid = whm.workgroupid 
                       AND Datediff(d, whm.effectivedate, 
                           ISNULL(whm.enddate, '2099-12-31')) > 1
       LEFT OUTER JOIN resources r WITH (nolock) 
                    ON whm.resourceid = r.resourceid 
                       AND r.deleted = 0 
       LEFT OUTER JOIN resourcepayroll rp WITH (nolock) 
                    ON r.resourceid = rp.resourceid 
       LEFT OUTER JOIN resourcerate rr WITH (nolock) 
                    ON r.resourceid = rr.resourceid 
                       AND rr.active = 1 
       LEFT OUTER JOIN workgroupresourcemanagers wrm 
                    ON w.workgroupid = wrm.workgroupid 
       LEFT OUTER JOIN resourceaddress ra 
                    ON ra.resourceid = wrm.resourceid 
WHERE  w.deleted = 0 
       AND r.resourceid IS NOT NULL 
UNION ALL 
-- Add resourcess that are assigned to a child workgroup  
SELECT IIF(r.employeetype = 'CO', 'Contractor', 'Burwood Employee')      AS ResourceType, 
       w.workgroupid, 
       w.NAME                                                            AS Workgroup, 
       NULL                                                              AS ChildWorkgroup, 
       r.NAME                                                            AS ResourceName, 
       r.employeetype, 
       r.resourceid, 
       whm.effectivedate                                                 AS HireDate, 
       ISNULL(whm.enddate, '2099-12-31')                                 AS TerminationDate, 
       rp.annualtargethours, 
       rr.rate1                                                          AS LoadedAnnualSalary, 
       IIF(ISNULL(r.terminationdate, '2099-12-31') = '2099-12-31', 0, 1) AS Terminated, 
       r.NAME 
       + Cast(whm.HistoryID AS VARCHAR(36))                              AS WorkgroupResourceId, 
       ra.emailaddress                                                   AS WorkgroupOwnerEmail 
FROM   workgroup w WITH (nolock) 
       LEFT OUTER JOIN workgroup wc WITH (nolock) 
                    ON w.workgroupid = wc.parent 
                       AND wc.deleted = 0 
       LEFT OUTER JOIN workgrouphistorymember whm WITH (nolock) 
                    ON wc.workgroupid = whm.workgroupid 
                       AND Datediff(d, whm.effectivedate, 
                           ISNULL(whm.enddate, '2099-12-31')) > 1
       LEFT OUTER JOIN resources r WITH (nolock) 
                    ON whm.resourceid = r.resourceid 
                       AND r.deleted = 0 
       LEFT OUTER JOIN resourcepayroll rp WITH (nolock) 
                    ON r.resourceid = rp.resourceid 
       LEFT OUTER JOIN resourcerate rr WITH (nolock) 
                    ON r.resourceid = rr.resourceid 
                       AND rr.active = 1 
       LEFT OUTER JOIN workgroupresourcemanagers wrm 
                    ON w.workgroupid = wrm.workgroupid 
       LEFT OUTER JOIN resourceaddress ra 
                    ON ra.resourceid = wrm.resourceid 
WHERE  w.deleted = 0 
       AND r.resourceid IS NOT NULL 
UNION ALL 
-- Add resourcess that are assigned to a child of a child workgroup  
SELECT IIF(r.employeetype = 'CO', 'Contractor', 'Burwood Employee')      AS ResourceType, 
       wp.workgroupid, 
       wp.NAME                                                           AS Workgroup, 
       w.NAME                                                            AS ChildWorkgroup, 
       r.NAME                                                            AS ResourceName, 
       r.employeetype, 
       r.resourceid, 
       whm.effectivedate                                                 AS HireDate, 
       ISNULL(whm.enddate, '2099-12-31')                                 AS TerminationDate, 
       rp.annualtargethours, 
       rr.rate1                                                          AS LoadedAnnualSalary, 
       IIF(ISNULL(r.terminationdate, '2099-12-31') = '2099-12-31', 0, 1) AS Terminated, 
       r.NAME 
       + Cast(whm.HistoryID AS VARCHAR(36))                              AS WorkgroupResourceId, 
       ra.emailaddress                                                   AS WorkgroupOwnerEmail 
FROM   workgroup w WITH (nolock) 
       LEFT OUTER JOIN workgroup wc WITH (nolock) 
                    ON w.workgroupid = wc.parent 
                       AND wc.deleted = 0 
      LEFT OUTER JOIN workgrouphistorymember whm WITH (nolock) 
                    ON wc.workgroupid = whm.workgroupid 
                       AND Datediff(d, whm.effectivedate, 
                           ISNULL(whm.enddate, '2099-12-31')) > 1
       LEFT OUTER JOIN workgroup wp WITH (nolock) 
                    ON wp.workgroupid = w.parent 
                       AND w.deleted = 0 
       LEFT OUTER JOIN resources r WITH (nolock) 
                    ON whm.resourceid = r.resourceid 
                       AND r.deleted = 0 
       LEFT OUTER JOIN resourcepayroll rp WITH (nolock) 
                    ON r.resourceid = rp.resourceid 
       LEFT OUTER JOIN resourcerate rr WITH (nolock) 
                    ON r.resourceid = rr.resourceid 
                       AND rr.active = 1 
       LEFT OUTER JOIN workgroupresourcemanagers wrm 
                    ON w.workgroupid = wrm.workgroupid 
       LEFT OUTER JOIN resourceaddress ra 
                    ON ra.resourceid = wrm.resourceid 
WHERE  w.deleted = 0 
       AND r.resourceid IS NOT NULL 
       AND Wp.NAME IS NOT NULL 
UNION ALL 
--Add all workgroups and FF Contractor Margin to a generic userid to allow non-workgroup FF contractors to be supported  
SELECT 'Other'                                AS ResourceType, 
       w.workgroupid, 
       w.NAME                                 AS Workgroup, 
       NULL                                   AS ChildWorkgroup, 
       'FF Contractor Margin'                 AS ResourceName, 
       NULL                                   AS EmployeeType, 
       '00000000-0000-0000-0000-000000000000' AS ResourceId, 
       '2014-01-01'                           AS HireDate, 
       '2099-12-31'                           AS TerminationDate, 
       0                                      AS AnnualTargetHours, 
       0                                      AS LoadedAnnualSalary, 
       0                                      AS Terminated, 
       'FF Contractor Margin' 
       + Cast(w.workgroupid AS VARCHAR(36))   AS WorkgroupResourceId, 
       ra.emailaddress                        AS WorkgroupOwnerEmail 
FROM   workgroup w WITH (nolock) 
       LEFT OUTER JOIN workgroupresourcemanagers wrm 
                    ON w.workgroupid = wrm.workgroupid 
       LEFT OUTER JOIN resourceaddress ra 
                    ON ra.resourceid = wrm.resourceid 
WHERE  w.deleted = 0 
UNION ALL 
--Add all workgroups and associate to a generic userid to allow non-workgroup Associates to be supported  
SELECT 'Associate'                            AS ResourceType, 
       w.workgroupid, 
       w.NAME                                 AS Workgroup, 
       NULL                                   AS ChildWorkgroup, 
       'Associate'                            AS ResourceName, 
       NULL                                   AS EmployeeType, 
       '00000000-0000-0000-0000-000000000000' AS ResourceId, 
       '2014-01-01'                           AS HireDate, 
       '2099-12-31'                           AS TerminationDate, 
       0                                      AS AnnualTargetHours, 
       0                                      AS LoadedAnnualSalary, 
       0                                      AS Terminated, 
       'Associate' 
       + Cast(w.workgroupid AS VARCHAR(36))   AS WorkgroupResourceId, 
       ra.emailaddress                        AS WorkgroupOwnerEmail 
FROM   workgroup w WITH (nolock) 
       LEFT OUTER JOIN workgroupresourcemanagers wrm 
                    ON w.workgroupid = wrm.workgroupid 
       LEFT OUTER JOIN resourceaddress ra 
                    ON ra.resourceid = wrm.resourceid 
WHERE  w.deleted = 0 


GO
